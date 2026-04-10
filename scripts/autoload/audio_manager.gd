extends Node
## AudioManager - Centralized audio playback singleton.
## Handles music, SFX, UI sounds, and theme-aware ambient audio.

# --- Audio Bus Names ---
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"

# --- Base Gameplay SFX ---
var sfx_jump: AudioStream
var sfx_landing: AudioStream
var sfx_collision: AudioStream
var sfx_fail: AudioStream
var sfx_victory: AudioStream
var sfx_coin_collect: AudioStream
var sfx_coin_collect_alt: AudioStream
var sfx_slide: AudioStream
var sfx_lane_swoosh: AudioStream
var sfx_impacts: Array[AudioStream] = []
var sfx_footsteps: Array[AudioStream] = []

# --- Cyberprank Gameplay SFX ---
var cyber_sfx_jump: AudioStream
var cyber_sfx_landing: AudioStream
var cyber_sfx_collision: AudioStream
var cyber_sfx_fail: AudioStream
var cyber_sfx_coin_collect: AudioStream
var cyber_sfx_coin_collect_alt: AudioStream
var cyber_sfx_slide: AudioStream
var cyber_sfx_lane_swoosh: AudioStream
var cyber_sfx_bridge: AudioStream
var cyber_sfx_blast_fire: AudioStream
var cyber_sfx_blast_impact: AudioStream
var cyber_sfx_impacts: Array[AudioStream] = []
var cyber_sfx_footsteps: Array[AudioStream] = []

# --- Base UI Sounds ---
var ui_click: AudioStream
var ui_hover: AudioStream
var ui_switch: AudioStream
var ui_release: AudioStream

# --- Cyberprank UI Sounds ---
var cyber_ui_click: AudioStream
var cyber_ui_hover: AudioStream
var cyber_ui_switch: AudioStream
var cyber_ui_release: AudioStream
var cyber_ui_notice: AudioStream

# --- Music / Ambient ---
var music_gameplay: AudioStream
var cyber_ambient_loop: AudioStream
var _nature_ambient_loop: AudioStream

# --- Audio Players ---
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _wind_player: AudioStreamPlayer

const MAX_SFX_PLAYERS: int = 8

# --- State ---
var _music_enabled: bool = true
var _sfx_enabled: bool = true
var _wind_target_volume: float = -40.0
var _speed_milestone_last: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_create_audio_players()
	_load_audio_resources()
	_apply_saved_settings()
	_connect_game_signals()


func _process(delta: float) -> void:
	if _wind_player and _wind_player.playing:
		_wind_player.volume_db = lerp(_wind_player.volume_db, _wind_target_volume, delta * 3.0)


# --- Public API: Playback ---

func play_music(stream: AudioStream = null, from_position: float = 0.0) -> void:
	if not _music_enabled:
		return
	if stream:
		_music_player.stream = stream
	elif not _music_player.stream:
		_music_player.stream = music_gameplay
	if _music_player.stream:
		_music_player.play(from_position)


func stop_music() -> void:
	_music_player.stop()


func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> void:
	if not _sfx_enabled:
		return
	var resolved_stream: AudioStream = _resolve_sfx_stream(stream)
	if not resolved_stream:
		return
	var player: AudioStreamPlayer = _get_available_sfx_player()
	if not player:
		return
	player.stream = resolved_stream
	player.pitch_scale = 1.0
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play()


func play_ui_sound(stream: AudioStream = null) -> void:
	var resolved_stream: AudioStream = stream
	if not resolved_stream:
		resolved_stream = ui_click
	resolved_stream = _resolve_ui_stream(resolved_stream)
	if not resolved_stream:
		return
	_ui_player.stream = resolved_stream
	_ui_player.play()


func play_back_sound() -> void:
	play_ui_sound(ui_release)


func play_notice_sound() -> void:
	if _is_cyber_theme() and cyber_ui_notice:
		play_ui_sound(cyber_ui_notice)
		return
	play_ui_sound(ui_switch)


func play_footstep() -> void:
	if not _sfx_enabled:
		return
	var active_pool: Array[AudioStream] = sfx_footsteps
	if _is_cyber_theme() and not cyber_sfx_footsteps.is_empty():
		active_pool = cyber_sfx_footsteps
	if active_pool.is_empty():
		return
	var stream: AudioStream = active_pool[randi() % active_pool.size()]
	_footstep_player.stream = stream
	if _is_cyber_theme():
		_footstep_player.pitch_scale = randf_range(0.94, 1.08)
	else:
		_footstep_player.pitch_scale = randf_range(0.9, 1.1)
	_footstep_player.play()


func play_impact() -> void:
	## Play a random impact sound for obstacle collisions.
	if not _sfx_enabled:
		return
	var active_impacts: Array[AudioStream] = sfx_impacts
	if _is_cyber_theme() and not cyber_sfx_impacts.is_empty():
		active_impacts = cyber_sfx_impacts
	if active_impacts.is_empty():
		if _is_cyber_theme() and cyber_sfx_collision:
			play_sfx(cyber_sfx_collision)
		else:
			play_sfx(sfx_collision)
		return
	var stream: AudioStream = active_impacts[randi() % active_impacts.size()]
	play_sfx(stream, 0.08 if _is_cyber_theme() else 0.06)


func play_coin_sound() -> void:
	if not _sfx_enabled:
		return
	if _is_cyber_theme() and cyber_sfx_coin_collect:
		if cyber_sfx_coin_collect_alt and randi() % 3 == 0:
			play_sfx(cyber_sfx_coin_collect_alt, 0.04)
		else:
			play_sfx(cyber_sfx_coin_collect, 0.03)
		return
	if sfx_coin_collect_alt and randi() % 3 == 0:
		play_sfx(sfx_coin_collect_alt, 0.05)
	else:
		play_sfx(sfx_coin_collect, 0.05)


func play_bridge_build() -> void:
	if _is_cyber_theme() and cyber_sfx_bridge:
		play_sfx(cyber_sfx_bridge, 0.03)
		return
	play_sfx(sfx_landing, 0.3)


func play_blast_fire() -> void:
	if _is_cyber_theme() and cyber_sfx_blast_fire:
		play_sfx(cyber_sfx_blast_fire, 0.04)
		return
	play_sfx(sfx_lane_swoosh, 0.12)


func play_blast_impact() -> void:
	if _is_cyber_theme() and cyber_sfx_blast_impact:
		play_sfx(cyber_sfx_blast_impact, 0.03)
		if not cyber_sfx_impacts.is_empty():
			play_sfx(cyber_sfx_impacts[randi() % cyber_sfx_impacts.size()], 0.04)
		return
	play_impact()


func play_fail_sound() -> void:
	if _is_cyber_theme() and cyber_sfx_fail:
		play_sfx(cyber_sfx_fail, 0.02)
		return
	play_sfx(sfx_fail)


# --- Public API: Music Management ---

func start_gameplay_music() -> void:
	if not _music_enabled:
		return
	if _music_player.playing:
		return
	_music_player.stream = music_gameplay
	_music_player.volume_db = -20.0
	_music_player.pitch_scale = 1.0
	_music_player.play()
	var tween: Tween = create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, 1.5).set_ease(Tween.EASE_OUT)


func fade_out_music(duration: float = 1.0) -> void:
	if not _music_player.playing:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(_music_player.stop)


func fade_in_music(duration: float = 1.5) -> void:
	if not _music_enabled:
		return
	if not _music_player.stream:
		_music_player.stream = music_gameplay
	_music_player.volume_db = -40.0
	_music_player.pitch_scale = 1.0
	if not _music_player.playing:
		_music_player.play()
	var tween: Tween = create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, duration).set_ease(Tween.EASE_OUT)


# --- Public API: Ambient ---

func start_wind_ambient() -> void:
	if not _wind_player:
		return
	var ambient_stream: AudioStream = _get_theme_ambient_stream()
	if ambient_stream and _wind_player.stream != ambient_stream:
		_wind_player.stop()
		_wind_player.stream = ambient_stream
	if not _wind_player.playing:
		_wind_player.volume_db = -40.0
		_wind_player.pitch_scale = 0.84 if _is_cyber_theme() else 1.0
		_wind_player.play()
	_wind_target_volume = -40.0


func stop_wind_ambient() -> void:
	if _wind_player and _wind_player.playing:
		_wind_player.stop()


func update_wind_for_speed(speed_ratio: float) -> void:
	var clamped_ratio: float = clampf(speed_ratio, 0.0, 1.0)
	if _is_cyber_theme():
		_wind_target_volume = lerpf(-34.0, -12.0, clamped_ratio)
		if _wind_player:
			_wind_player.pitch_scale = lerpf(0.84, 1.18, clamped_ratio)
	else:
		_wind_target_volume = lerpf(-30.0, -8.0, clamped_ratio)
		if _wind_player:
			_wind_player.pitch_scale = 1.0


# --- Public API: Volume & Toggle ---

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		_music_player.stop()
	SaveManager.set_setting("music_enabled", enabled)


func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	SaveManager.set_setting("sfx_enabled", enabled)


func is_music_enabled() -> bool:
	return _music_enabled


func is_sfx_enabled() -> bool:
	return _sfx_enabled


func set_music_volume(linear: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(BUS_MUSIC)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear, 0.0, 1.0)))
	SaveManager.set_setting("music_volume", linear)


func set_sfx_volume(linear: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(BUS_SFX)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clampf(linear, 0.0, 1.0)))
	SaveManager.set_setting("sfx_volume", linear)


func get_music_volume() -> float:
	var bus_idx: int = AudioServer.get_bus_index(BUS_MUSIC)
	if bus_idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0


func get_sfx_volume() -> float:
	var bus_idx: int = AudioServer.get_bus_index(BUS_SFX)
	if bus_idx >= 0:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	return 1.0


# --- Private: Setup ---

func _ensure_audio_buses() -> void:
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)


func _create_audio_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.volume_db = 0.0
	add_child(_music_player)

	for i in MAX_SFX_PLAYERS:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)

	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.bus = BUS_SFX
	_footstep_player.volume_db = -6.0
	add_child(_footstep_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = BUS_UI
	add_child(_ui_player)

	_wind_player = AudioStreamPlayer.new()
	_wind_player.bus = BUS_SFX
	_wind_player.volume_db = -40.0
	add_child(_wind_player)
	_nature_ambient_loop = _generate_wind_noise()
	_wind_player.stream = _nature_ambient_loop


func _load_audio_resources() -> void:
	sfx_jump = _try_load("res://assets/Audio/jump.wav")
	sfx_landing = _try_load("res://assets/Audio/landing.wav")
	sfx_collision = _try_load("res://assets/Audio/collision.wav")
	sfx_fail = _try_load("res://assets/Audio/fail.wav")
	sfx_victory = _try_load("res://assets/Audio/victory.wav")
	sfx_coin_collect = _try_load("res://assets/Audio/Gameplay/rpg_audio/handleCoins.ogg")
	sfx_coin_collect_alt = _try_load("res://assets/Audio/Gameplay/rpg_audio/handleCoins2.ogg")

	sfx_slide = _try_load("res://assets/Audio/Gameplay/rpg_audio/cloth1.ogg")
	sfx_lane_swoosh = _try_load("res://assets/Audio/Gameplay/rpg_audio/cloth3.ogg")

	for path in [
		"res://assets/Audio/Gameplay/impact_sounds/impactSoft_heavy_000.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactSoft_heavy_001.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactSoft_heavy_002.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactWood_medium_000.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactWood_medium_001.ogg",
	]:
		var stream: AudioStream = _try_load(path)
		if stream:
			sfx_impacts.append(stream)

	for i in range(5):
		var grass_path: String = "res://assets/Audio/Gameplay/impact_sounds/footstep_grass_%03d.ogg" % i
		var grass_stream: AudioStream = _try_load(grass_path)
		if grass_stream:
			sfx_footsteps.append(grass_stream)

	for i in range(10):
		var rpg_path: String = "res://assets/Audio/Gameplay/rpg_audio/footstep%02d.ogg" % i
		var rpg_stream: AudioStream = _try_load(rpg_path)
		if rpg_stream:
			sfx_footsteps.append(rpg_stream)

	ui_click = _try_load("res://assets/Audio/UI/click1.ogg")
	ui_hover = _try_load("res://assets/Audio/UI/rollover1.ogg")
	ui_switch = _try_load("res://assets/Audio/UI/switch1.ogg")
	ui_release = _try_load("res://assets/Audio/UI/mouserelease1.ogg")

	music_gameplay = _try_load("res://assets/Audio/playing.mpeg")
	_load_cyber_audio_resources()


func _load_cyber_audio_resources() -> void:
	cyber_sfx_jump = _try_load("res://assets/Audio/cyberprank/gameplay/laserSmall_001.ogg")
	cyber_sfx_slide = _try_load("res://assets/Audio/cyberprank/gameplay/laserSmall_001.ogg")
	cyber_sfx_lane_swoosh = _try_load("res://assets/Audio/cyberprank/ui/scroll_004.ogg")
	cyber_sfx_landing = _try_load("res://assets/Audio/cyberprank/gameplay/impactMetal_002.ogg")
	cyber_sfx_collision = _try_load("res://assets/Audio/cyberprank/gameplay/impactMetal_004.ogg")
	cyber_sfx_fail = _try_load("res://assets/Audio/cyberprank/gameplay/lowFrequency_explosion_000.ogg")
	cyber_sfx_coin_collect = _try_load("res://assets/Audio/cyberprank/ui/tick_002.ogg")
	cyber_sfx_coin_collect_alt = _try_load("res://assets/Audio/cyberprank/ui/select_006.ogg")
	cyber_sfx_bridge = _try_load("res://assets/Audio/cyberprank/gameplay/forceField_001.ogg")
	cyber_sfx_blast_fire = _try_load("res://assets/Audio/cyberprank/gameplay/laserLarge_001.ogg")
	cyber_sfx_blast_impact = _try_load("res://assets/Audio/cyberprank/gameplay/explosionCrunch_003.ogg")
	cyber_ambient_loop = _make_looping_stream(_try_load("res://assets/Audio/cyberprank/gameplay/spaceEngineLow_001.ogg"))

	for path in [
		"res://assets/Audio/cyberprank/gameplay/impactMetal_000.ogg",
		"res://assets/Audio/cyberprank/gameplay/impactMetal_001.ogg",
		"res://assets/Audio/cyberprank/gameplay/impactMetal_002.ogg",
		"res://assets/Audio/cyberprank/gameplay/impactMetal_003.ogg",
		"res://assets/Audio/cyberprank/gameplay/impactMetal_004.ogg",
	]:
		var impact_stream: AudioStream = _try_load(path)
		if impact_stream:
			cyber_sfx_impacts.append(impact_stream)

	for path in [
		"res://assets/Audio/Gameplay/impact_sounds/footstep_concrete_000.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/footstep_concrete_001.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/footstep_concrete_002.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/footstep_concrete_003.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/footstep_concrete_004.ogg",
	]:
		var concrete_stream: AudioStream = _try_load(path)
		if concrete_stream:
			cyber_sfx_footsteps.append(concrete_stream)

	for path in [
		"res://assets/Audio/Gameplay/impact_sounds/impactMetal_light_000.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactMetal_light_001.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactMetal_light_002.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactMetal_light_003.ogg",
		"res://assets/Audio/Gameplay/impact_sounds/impactMetal_light_004.ogg",
	]:
		var metal_stream: AudioStream = _try_load(path)
		if metal_stream:
			cyber_sfx_footsteps.append(metal_stream)

	cyber_ui_click = _try_load("res://assets/Audio/cyberprank/ui/click_004.ogg")
	cyber_ui_hover = _try_load("res://assets/Audio/cyberprank/ui/switch_004.ogg")
	cyber_ui_switch = _try_load("res://assets/Audio/cyberprank/ui/select_005.ogg")
	cyber_ui_release = _try_load("res://assets/Audio/cyberprank/ui/back_002.ogg")
	cyber_ui_notice = _try_load("res://assets/Audio/cyberprank/ui/glitch_003.ogg")


func _apply_saved_settings() -> void:
	_music_enabled = SaveManager.get_setting("music_enabled", true)
	_sfx_enabled = SaveManager.get_setting("sfx_enabled", true)
	set_music_volume(SaveManager.get_setting("music_volume", 0.8))
	set_sfx_volume(SaveManager.get_setting("sfx_volume", 1.0))


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	return _sfx_players[0]


func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	push_warning("AudioManager: Resource not found: %s" % path)
	return null


func _resolve_sfx_stream(stream: AudioStream) -> AudioStream:
	if stream == null or not _is_cyber_theme():
		return stream
	if stream == sfx_jump and cyber_sfx_jump:
		return cyber_sfx_jump
	if stream == sfx_landing and cyber_sfx_landing:
		return cyber_sfx_landing
	if stream == sfx_collision and cyber_sfx_collision:
		return cyber_sfx_collision
	if stream == sfx_fail and cyber_sfx_fail:
		return cyber_sfx_fail
	if stream == sfx_coin_collect and cyber_sfx_coin_collect:
		return cyber_sfx_coin_collect
	if stream == sfx_coin_collect_alt and cyber_sfx_coin_collect_alt:
		return cyber_sfx_coin_collect_alt
	if stream == sfx_slide and cyber_sfx_slide:
		return cyber_sfx_slide
	if stream == sfx_lane_swoosh and cyber_sfx_lane_swoosh:
		return cyber_sfx_lane_swoosh
	return stream


func _resolve_ui_stream(stream: AudioStream) -> AudioStream:
	if stream == null or not _is_cyber_theme():
		return stream
	if stream == ui_click and cyber_ui_click:
		return cyber_ui_click
	if stream == ui_hover and cyber_ui_hover:
		return cyber_ui_hover
	if stream == ui_switch and cyber_ui_switch:
		return cyber_ui_switch
	if stream == ui_release and cyber_ui_release:
		return cyber_ui_release
	return stream


func _get_theme_ambient_stream() -> AudioStream:
	if _is_cyber_theme() and cyber_ambient_loop:
		return cyber_ambient_loop
	return _nature_ambient_loop


func _make_looping_stream(stream: AudioStream) -> AudioStream:
	if stream == null:
		return null
	var duplicated: Resource = stream.duplicate()
	if duplicated is AudioStreamOggVorbis:
		var ogg_stream: AudioStreamOggVorbis = duplicated as AudioStreamOggVorbis
		ogg_stream.loop = true
		return ogg_stream
	if duplicated is AudioStreamWAV:
		var wav_stream: AudioStreamWAV = duplicated as AudioStreamWAV
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav_stream
	return stream


func _is_cyber_theme() -> bool:
	return GameManager != null and GameManager.is_cyberprank_theme()


# --- Private: Game Signal Connections ---

func _connect_game_signals() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	GameManager.speed_changed.connect(_on_speed_changed)


func _on_game_started() -> void:
	_speed_milestone_last = 0
	start_gameplay_music()
	start_wind_ambient()


func _on_game_over() -> void:
	fade_out_music(1.5)
	stop_wind_ambient()


func _on_game_paused() -> void:
	if _music_player.playing:
		var tween: Tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_music_player, "volume_db", -12.0, 0.3)


func _on_game_resumed() -> void:
	if _music_player.playing:
		var tween: Tween = create_tween()
		tween.tween_property(_music_player, "volume_db", 0.0, 0.3)


func _on_speed_changed(new_speed: float) -> void:
	var ratio: float = GameManager.get_speed_ratio()
	update_wind_for_speed(ratio)

	var milestone: int = int(ratio * 4.0)
	if milestone > _speed_milestone_last and milestone > 0:
		_speed_milestone_last = milestone
		if sfx_lane_swoosh:
			play_sfx(sfx_lane_swoosh, 0.0)

	if _music_player.playing:
		_music_player.pitch_scale = lerpf(1.0, 1.08, ratio)


# --- Private: Wind Noise Generation ---

func _generate_wind_noise() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 2.0
	var num_samples: int = int(sample_rate * duration)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = num_samples

	var data: PackedByteArray = PackedByteArray()
	data.resize(num_samples * 2)

	var brown_value: float = 0.0
	for i in range(num_samples):
		brown_value += randf_range(-1.0, 1.0)
		brown_value *= 0.998
		var sample_val: int = clampi(int(brown_value * 800.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF

	wav.data = data
	return wav

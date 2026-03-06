extends Node
## AudioManager - Centralized audio playback singleton.
## Handles music, SFX, UI sounds, and ambient audio routed to separate audio buses.

# --- Audio Bus Names ---
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_UI: StringName = &"UI"

# --- Preloaded Audio Resources ---
# Gameplay SFX
var sfx_jump: AudioStream
var sfx_landing: AudioStream
var sfx_collision: AudioStream
var sfx_fail: AudioStream
var sfx_victory: AudioStream
var sfx_coin_collect: AudioStream
var sfx_coin_collect_alt: AudioStream

# Movement SFX
var sfx_slide: AudioStream
var sfx_lane_swoosh: AudioStream

# Impact variants (randomized on collision)
var sfx_impacts: Array[AudioStream] = []

# Footstep pool
var sfx_footsteps: Array[AudioStream] = []

# UI Sounds
var ui_click: AudioStream
var ui_hover: AudioStream
var ui_switch: AudioStream
var ui_release: AudioStream

# Music
var music_gameplay: AudioStream

# --- Audio Players ---
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer
var _footstep_player: AudioStreamPlayer
var _wind_player: AudioStreamPlayer

const MAX_SFX_PLAYERS: int = 8  # Polyphony for overlapping SFX

# --- State ---
var _music_enabled: bool = true
var _sfx_enabled: bool = true
var _wind_target_volume: float = -40.0  # dB, driven by speed
var _speed_milestone_last: int = 0  # Track which speed tier was last announced


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_create_audio_players()
	_load_audio_resources()
	_apply_saved_settings()
	_connect_game_signals()


func _process(delta: float) -> void:
	# Smoothly adjust wind volume toward target
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
	if not _sfx_enabled or not stream:
		return
	var player: AudioStreamPlayer = _get_available_sfx_player()
	if not player:
		return
	player.stream = stream
	player.pitch_scale = 1.0
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	player.play()


func play_ui_sound(stream: AudioStream = null) -> void:
	if not stream:
		stream = ui_click
	if not stream:
		return
	_ui_player.stream = stream
	_ui_player.play()


func play_footstep() -> void:
	if not _sfx_enabled or sfx_footsteps.is_empty():
		return
	var stream: AudioStream = sfx_footsteps[randi() % sfx_footsteps.size()]
	_footstep_player.stream = stream
	_footstep_player.pitch_scale = randf_range(0.9, 1.1)
	_footstep_player.play()


func play_impact() -> void:
	## Play a random impact sound (for obstacle collisions) — richer than single sfx_collision.
	if not _sfx_enabled:
		return
	if sfx_impacts.is_empty():
		play_sfx(sfx_collision)
		return
	var stream: AudioStream = sfx_impacts[randi() % sfx_impacts.size()]
	play_sfx(stream, 0.08)


func play_coin_sound() -> void:
	## Alternates between coin collect variants for variety.
	if not _sfx_enabled:
		return
	if sfx_coin_collect_alt and randi() % 3 == 0:
		play_sfx(sfx_coin_collect_alt, 0.05)
	else:
		play_sfx(sfx_coin_collect, 0.05)


# --- Public API: Music Management ---

func start_gameplay_music() -> void:
	## Start or resume gameplay music. Fades in smoothly.
	if not _music_enabled:
		return
	if _music_player.playing:
		return  # Already playing
	_music_player.stream = music_gameplay
	_music_player.volume_db = -20.0
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, 1.5).set_ease(Tween.EASE_OUT)


func fade_out_music(duration: float = 1.0) -> void:
	## Fade music out over duration seconds.
	if not _music_player.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(_music_player.stop)


func fade_in_music(duration: float = 1.5) -> void:
	## Fade music in from silent.
	if not _music_enabled:
		return
	if not _music_player.stream:
		_music_player.stream = music_gameplay
	_music_player.volume_db = -40.0
	if not _music_player.playing:
		_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, duration).set_ease(Tween.EASE_OUT)


# --- Public API: Ambient ---

func start_wind_ambient() -> void:
	## Start wind ambient loop (volume driven by game speed).
	if _wind_player and not _wind_player.playing:
		_wind_player.volume_db = -40.0
		_wind_player.play()
	_wind_target_volume = -40.0


func stop_wind_ambient() -> void:
	if _wind_player and _wind_player.playing:
		_wind_player.stop()


func update_wind_for_speed(speed_ratio: float) -> void:
	## speed_ratio: 0.0 (base) to 1.0 (max speed). Wind gets louder with speed.
	# Map 0.0-1.0 to -30dB to -8dB
	_wind_target_volume = lerpf(-30.0, -8.0, clampf(speed_ratio, 0.0, 1.0))


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
	# Create buses if they don't exist (fallback if default_bus_layout.tres is missing)
	for bus_name: StringName in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)


func _create_audio_players() -> void:
	# Music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	_music_player.volume_db = 0.0
	add_child(_music_player)

	# SFX player pool
	for i in MAX_SFX_PLAYERS:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

	# Footstep player (dedicated to avoid cutting off SFX pool)
	_footstep_player = AudioStreamPlayer.new()
	_footstep_player.bus = BUS_SFX
	_footstep_player.volume_db = -6.0  # Slightly quieter
	add_child(_footstep_player)

	# UI player
	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = BUS_UI
	add_child(_ui_player)

	# Wind ambient player (pre-generated brown noise loop for wind feel)
	_wind_player = AudioStreamPlayer.new()
	_wind_player.bus = BUS_SFX
	_wind_player.volume_db = -40.0
	add_child(_wind_player)
	_wind_player.stream = _generate_wind_noise()


func _load_audio_resources() -> void:
	# Gameplay SFX
	sfx_jump = _try_load("res://assets/Audio/jump.wav")
	sfx_landing = _try_load("res://assets/Audio/landing.wav")
	sfx_collision = _try_load("res://assets/Audio/collision.wav")
	sfx_fail = _try_load("res://assets/Audio/fail.wav")
	sfx_victory = _try_load("res://assets/Audio/victory.wav")
	sfx_coin_collect = _try_load("res://assets/Audio/Gameplay/rpg_audio/handleCoins.ogg")
	sfx_coin_collect_alt = _try_load("res://assets/Audio/Gameplay/rpg_audio/handleCoins2.ogg")

	# Movement SFX
	sfx_slide = _try_load("res://assets/Audio/Gameplay/rpg_audio/cloth1.ogg")
	sfx_lane_swoosh = _try_load("res://assets/Audio/Gameplay/rpg_audio/cloth3.ogg")

	# Impact variants for obstacle collisions (randomized for variety)
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

	# Footsteps — grass variants (primary surface)
	for i in range(5):
		var path: String = "res://assets/Audio/Gameplay/impact_sounds/footstep_grass_%03d.ogg" % i
		var stream: AudioStream = _try_load(path)
		if stream:
			sfx_footsteps.append(stream)

	# Also add RPG footstep variants for more variety
	for i in range(10):
		var path: String = "res://assets/Audio/Gameplay/rpg_audio/footstep%02d.ogg" % i
		var stream: AudioStream = _try_load(path)
		if stream:
			sfx_footsteps.append(stream)

	# UI
	ui_click = _try_load("res://assets/Audio/UI/click1.ogg")
	ui_hover = _try_load("res://assets/Audio/UI/rollover1.ogg")
	ui_switch = _try_load("res://assets/Audio/UI/switch1.ogg")
	ui_release = _try_load("res://assets/Audio/UI/mouserelease1.ogg")

	# Music
	music_gameplay = _try_load("res://assets/Audio/playing.mpeg")


func _apply_saved_settings() -> void:
	_music_enabled = SaveManager.get_setting("music_enabled", true)
	_sfx_enabled = SaveManager.get_setting("sfx_enabled", true)
	set_music_volume(SaveManager.get_setting("music_volume", 0.8))
	set_sfx_volume(SaveManager.get_setting("sfx_volume", 1.0))


func _get_available_sfx_player() -> AudioStreamPlayer:
	for p: AudioStreamPlayer in _sfx_players:
		if not p.playing:
			return p
	# All busy — return the oldest one (will cut it off)
	return _sfx_players[0]


func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	push_warning("AudioManager: Resource not found: %s" % path)
	return null


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
	# Note: sfx_fail is played by game_over.gd after the 1.2s delay


func _on_game_paused() -> void:
	# Duck music volume while paused
	if _music_player.playing:
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_music_player, "volume_db", -12.0, 0.3)


func _on_game_resumed() -> void:
	# Restore music volume
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", 0.0, 0.3)


func _on_speed_changed(new_speed: float) -> void:
	var ratio: float = GameManager.get_speed_ratio()
	update_wind_for_speed(ratio)

	# Speed milestone — play a subtle whoosh at each 25% speed increment
	var milestone: int = int(ratio * 4.0)  # 0, 1, 2, 3, 4
	if milestone > _speed_milestone_last and milestone > 0:
		_speed_milestone_last = milestone
		# Use a swoosh/cloth sound pitched up for urgency
		if sfx_lane_swoosh:
			play_sfx(sfx_lane_swoosh, 0.0)

	# Gradually pitch up music with speed for excitement
	if _music_player.playing:
		_music_player.pitch_scale = lerpf(1.0, 1.08, ratio)


# --- Private: Wind Noise Generation ---

func _generate_wind_noise() -> AudioStreamWAV:
	## Create a 2-second looping brown noise buffer that sounds like wind.
	var sample_rate: int = 22050
	var duration: float = 2.0
	var num_samples: int = int(sample_rate * duration)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = num_samples

	var data := PackedByteArray()
	data.resize(num_samples * 2)  # 16-bit = 2 bytes per sample

	var brown_value: float = 0.0
	for i in range(num_samples):
		# Brown noise = accumulated random walk (low frequency rumble)
		brown_value += randf_range(-1.0, 1.0)
		brown_value *= 0.998  # Slight decay to prevent drift
		var sample_val: int = clampi(int(brown_value * 800.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF

	wav.data = data
	return wav

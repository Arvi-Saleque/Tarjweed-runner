extends Node
## PlayerAnimation — Manages animation states for the player character.
## Works with AnimationPlayer found on the imported GLB model.
## If no AnimationPlayer is found, falls back to code-driven transforms.

# --- Animation Names (mapped from Kenney Rig_Medium GLBs) ---
# Actual names extracted from GLB files:
# MovementBasic: Running_A, Running_B, Walking_A/B/C, Jump_Start, Jump_Idle, Jump_Land, Jump_Full_Long/Short
# General: Idle_A, Idle_B, Death_A/B, Hit_A/B, Spawn_Air/Ground
# MovementAdvanced: Crouching, Crawling, Dodge_*, Sneaking
const ANIM_IDLE: String = "Idle_A"
const ANIM_RUN: String = "Running_A"
const ANIM_RUN_B: String = "Running_B"
const ANIM_JUMP_UP: String = "Jump_Start"
const ANIM_JUMP_FALL: String = "Jump_Idle"
const ANIM_JUMP_LAND: String = "Jump_Land"
const ANIM_SLIDE: String = "Crouching"
const ANIM_DEATH: String = "Death_A"
const ANIM_STUMBLE: String = "Hit_A"

# Crossfade duration
const XFADE: float = 0.15
const XFADE_FAST: float = 0.08

# --- State ---
enum AnimState { IDLE, RUN, JUMP_UP, JUMP_FALL, SLIDE, LAND, DEATH, STUMBLE }
var current_anim_state: AnimState = AnimState.IDLE

var _anim_player: AnimationPlayer = null
var _has_animations: bool = false
var _player: CharacterBody3D = null
var _model: Node3D = null
var _land_timer: float = 0.0

# Fallback procedural animation
var _run_bob_time: float = 0.0


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_model = _player.get_node_or_null("PlayerModel")

	# Delay finding AnimationPlayer to allow _ensure_player_visible() to load GLB first
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_find_animation_player()

	# Connect to player signals
	if _player.has_signal("landed"):
		_player.landed.connect(_on_player_landed)
	if _player.has_signal("started_slide"):
		_player.started_slide.connect(_on_player_started_slide)
	if _player.has_signal("ended_slide"):
		_player.ended_slide.connect(_on_player_ended_slide)
	if _player.has_signal("hit_obstacle"):
		_player.hit_obstacle.connect(_on_player_hit)


func _process(delta: float) -> void:
	if not GameManager.is_playing() and _player.current_state != _player.PlayerState.DEAD:
		return

	_update_land_timer(delta)

	if _has_animations:
		_update_animation_state()
	else:
		_update_procedural_animation(delta)


# --- Animation State Machine ---

func _update_animation_state() -> void:
	if not _anim_player:
		return

	var new_state: AnimState = _determine_state()
	if new_state == current_anim_state:
		return

	current_anim_state = new_state

	match current_anim_state:
		AnimState.IDLE:
			_play_if_exists(ANIM_IDLE, XFADE)
		AnimState.RUN:
			_play_if_exists(ANIM_RUN, XFADE)
			_sync_run_speed()
		AnimState.JUMP_UP:
			_play_if_exists(ANIM_JUMP_UP, XFADE_FAST)
		AnimState.JUMP_FALL:
			_play_if_exists(ANIM_JUMP_FALL, XFADE)
		AnimState.SLIDE:
			_play_if_exists(ANIM_SLIDE, XFADE_FAST)
		AnimState.LAND:
			_play_if_exists(ANIM_JUMP_LAND, XFADE_FAST)
		AnimState.DEATH:
			_play_if_exists(ANIM_DEATH, XFADE_FAST)
		AnimState.STUMBLE:
			_play_if_exists(ANIM_STUMBLE, XFADE_FAST)


func _determine_state() -> AnimState:
	match _player.current_state:
		_player.PlayerState.DEAD:
			return AnimState.DEATH
		_player.PlayerState.STUMBLE:
			return AnimState.STUMBLE
		_player.PlayerState.SLIDING:
			return AnimState.SLIDE
		_player.PlayerState.JUMPING:
			if _player.vertical_velocity > 0:
				return AnimState.JUMP_UP
			else:
				return AnimState.JUMP_FALL
		_:
			if _land_timer > 0:
				return AnimState.LAND
			return AnimState.RUN


func _sync_run_speed() -> void:
	if _anim_player and _has_animations:
		# Speed up run animation based on game speed
		var speed_ratio: float = GameManager.get_speed_ratio()
		_anim_player.speed_scale = lerpf(1.0, 1.6, speed_ratio)


# --- Procedural (Fallback) Animation ---
## Used when imported GLB animations aren't available yet.
## Provides basic visual feedback so the player isn't static.

func _update_procedural_animation(delta: float) -> void:
	if not _model:
		return

	match _player.current_state:
		_player.PlayerState.RUNNING:
			_run_bob_time += delta * lerpf(8.0, 14.0, GameManager.get_speed_ratio())
			# Bob up/down
			_model.position.y = sin(_run_bob_time) * 0.04
			# Slight sway
			_model.rotation.z = sin(_run_bob_time * 0.5) * 0.02
			# Reset X rotation from slide
			_model.rotation.x = lerp(_model.rotation.x, 0.0, delta * 8.0)

		_player.PlayerState.JUMPING:
			_model.position.y = 0.0
			# Tuck legs feel — slight forward lean
			var target_rot: float = 0.0
			if _player.vertical_velocity > 0:
				target_rot = deg_to_rad(-15)
			else:
				target_rot = deg_to_rad(10)
			_model.rotation.x = lerp(_model.rotation.x, target_rot, delta * 5.0)

		_player.PlayerState.SLIDING:
			_model.position.y = 0.0
			# Forward lean is handled by player_controller

		_player.PlayerState.DEAD:
			pass  # Death tween is handled by player_controller


# --- Signal Callbacks ---

func _on_player_landed() -> void:
	_land_timer = 0.2


func _on_player_started_slide() -> void:
	current_anim_state = AnimState.SLIDE
	if _has_animations:
		_play_if_exists(ANIM_SLIDE, XFADE_FAST)


func _on_player_ended_slide() -> void:
	pass  # Will auto-transition to RUN in _determine_state


func _on_player_hit() -> void:
	current_anim_state = AnimState.DEATH
	if _has_animations:
		_play_if_exists(ANIM_DEATH, XFADE_FAST)


# --- Helpers ---

func _update_land_timer(delta: float) -> void:
	if _land_timer > 0:
		_land_timer -= delta


func _find_animation_player() -> void:
	# Search for AnimationPlayer in the model hierarchy
	if not _model:
		print("PlayerAnimation: No model node found!")
		return

	_anim_player = _find_anim_player_recursive(_model)
	if _anim_player:
		_has_animations = _anim_player.get_animation_list().size() > 0
		if _has_animations:
			_set_loop_modes()
			print("PlayerAnimation: Found AnimationPlayer with %d animations: %s" % [
				_anim_player.get_animation_list().size(),
				", ".join(_anim_player.get_animation_list())
			])
		else:
			print("PlayerAnimation: AnimationPlayer found but has no animations.")
	else:
		print("PlayerAnimation: No AnimationPlayer found in model tree.")


func _find_anim_player_recursive(node: Node) -> AnimationPlayer:
	# Use 'is' type check which is more reliable than get_class() string comparison
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_anim_player_recursive(child)
		if result:
			return result
	return null


func _play_if_exists(anim_name: String, crossfade: float = XFADE) -> void:
	if not _anim_player:
		return
	if _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name, crossfade)
		return
	# Try common alternative naming patterns (Kenney uses _A/_B suffixes)
	var alternatives: Array[String] = [
		anim_name + "_A",
		anim_name + "_B",
		anim_name.to_lower(),
		anim_name.replace("_", ""),
		anim_name.to_pascal_case(),
	]
	for alt in alternatives:
		if _anim_player.has_animation(alt):
			_anim_player.play(alt, crossfade)
			return


## Set loop mode on animations that should play continuously
func _set_loop_modes() -> void:
	var looping_anims: Array[String] = [
		ANIM_RUN, ANIM_RUN_B, ANIM_IDLE, "Idle_B",
		ANIM_SLIDE, ANIM_JUMP_FALL,
		"Walking_A", "Walking_B", "Walking_C",
		"Crawling", "Sneaking",
	]
	for anim_name in looping_anims:
		if _anim_player.has_animation(anim_name):
			var anim: Animation = _anim_player.get_animation(anim_name)
			if anim.loop_mode == Animation.LOOP_NONE:
				anim.loop_mode = Animation.LOOP_LINEAR

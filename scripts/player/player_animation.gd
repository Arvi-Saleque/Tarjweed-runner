extends Node
## PlayerAnimation - Manages animation states for the player character.
## Prefers the curated UAL2 clip set on the Quaternius runner rig.
## If no AnimationPlayer is found, falls back to code-driven transforms.

const ANIM_IDLE_OPTIONS: Array[String] = ["Idle_No_Loop", "Idle_Rail_Loop", "Idle_A"]
const ANIM_RUN_OPTIONS: Array[String] = ["Running_A", "Running_B", "Walk_Carry_Loop", "Zombie_Walk_Fwd_Loop"]
const ANIM_JUMP_UP_OPTIONS: Array[String] = ["Jump_Start", "NinjaJump_Start"]
const ANIM_JUMP_FALL_OPTIONS: Array[String] = ["Jump_Idle", "NinjaJump_Idle_Loop"]
const ANIM_JUMP_LAND_OPTIONS: Array[String] = ["Jump_Land", "NinjaJump_Land"]
const ANIM_SLIDE_OPTIONS: Array[String] = ["Crouching", "Slide_Loop"]
const ANIM_DEATH_OPTIONS: Array[String] = ["Death_A", "Hit_Knockback"]
const ANIM_STUMBLE_OPTIONS: Array[String] = ["Hit_A", "Hit_Knockback"]

const XFADE: float = 0.15
const XFADE_FAST: float = 0.08

enum AnimState { IDLE, RUN, JUMP_UP, JUMP_FALL, SLIDE, LAND, DEATH, STUMBLE }

var current_anim_state: AnimState = AnimState.IDLE

var _anim_player: AnimationPlayer = null
var _has_animations: bool = false
var _player: CharacterBody3D = null
var _model: Node3D = null
var _land_timer: float = 0.0
var _run_bob_time: float = 0.0


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_model = _player.get_node_or_null("PlayerModel")
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_find_animation_player()

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


func _update_animation_state() -> void:
	if not _anim_player:
		return

	var new_state: AnimState = _determine_state()
	if new_state == current_anim_state:
		return

	current_anim_state = new_state

	match current_anim_state:
		AnimState.IDLE:
			_play_first_available(ANIM_IDLE_OPTIONS, XFADE)
		AnimState.RUN:
			_play_first_available(ANIM_RUN_OPTIONS, XFADE)
			_sync_run_speed()
		AnimState.JUMP_UP:
			_play_first_available(ANIM_JUMP_UP_OPTIONS, XFADE_FAST)
		AnimState.JUMP_FALL:
			_play_first_available(ANIM_JUMP_FALL_OPTIONS, XFADE)
		AnimState.SLIDE:
			_play_first_available(ANIM_SLIDE_OPTIONS, XFADE_FAST)
		AnimState.LAND:
			_play_first_available(ANIM_JUMP_LAND_OPTIONS, XFADE_FAST)
		AnimState.DEATH:
			_play_first_available(ANIM_DEATH_OPTIONS, XFADE_FAST)
		AnimState.STUMBLE:
			_play_first_available(ANIM_STUMBLE_OPTIONS, XFADE_FAST)


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
			return AnimState.JUMP_FALL
		_:
			if _land_timer > 0:
				return AnimState.LAND
			return AnimState.RUN


func _sync_run_speed() -> void:
	if _anim_player and _has_animations:
		var speed_ratio: float = GameManager.get_speed_ratio()
		_anim_player.speed_scale = lerpf(1.0, 1.6, speed_ratio)


func _update_procedural_animation(delta: float) -> void:
	if not _model:
		return

	match _player.current_state:
		_player.PlayerState.RUNNING:
			_run_bob_time += delta * lerpf(8.0, 14.0, GameManager.get_speed_ratio())
			_model.position.y = sin(_run_bob_time) * 0.04
			_model.rotation.z = sin(_run_bob_time * 0.5) * 0.02
			_model.rotation.x = lerp(_model.rotation.x, 0.0, delta * 8.0)
		_player.PlayerState.JUMPING:
			_model.position.y = 0.0
			var target_rot: float = 0.0
			if _player.vertical_velocity > 0:
				target_rot = deg_to_rad(-15)
			else:
				target_rot = deg_to_rad(10)
			_model.rotation.x = lerp(_model.rotation.x, target_rot, delta * 5.0)
		_player.PlayerState.SLIDING:
			_model.position.y = 0.0
		_player.PlayerState.DEAD:
			pass


func _on_player_landed() -> void:
	_land_timer = 0.2


func _on_player_started_slide() -> void:
	current_anim_state = AnimState.SLIDE
	if _has_animations:
		_play_first_available(ANIM_SLIDE_OPTIONS, XFADE_FAST)


func _on_player_ended_slide() -> void:
	pass


func _on_player_hit() -> void:
	current_anim_state = AnimState.DEATH
	if _has_animations:
		_play_first_available(ANIM_DEATH_OPTIONS, XFADE_FAST)


func _update_land_timer(delta: float) -> void:
	if _land_timer > 0:
		_land_timer -= delta


func _find_animation_player() -> void:
	if not _model:
		print("PlayerAnimation: No model node found!")
		return

	_anim_player = _find_anim_player_recursive(_model)
	if _anim_player:
		_has_animations = _anim_player.get_animation_list().size() > 0
		if _has_animations:
			_set_loop_modes()
			current_anim_state = AnimState.RUN
			_play_first_available(ANIM_RUN_OPTIONS, 0.0)
			_sync_run_speed()
			print("PlayerAnimation: Found AnimationPlayer with %d animations: %s" % [
				_anim_player.get_animation_list().size(),
				", ".join(_anim_player.get_animation_list())
			])
		else:
			print("PlayerAnimation: AnimationPlayer found but has no animations.")
	else:
		print("PlayerAnimation: No AnimationPlayer found in model tree.")


func _find_anim_player_recursive(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_anim_player_recursive(child)
		if result:
			return result
	return null


func _play_first_available(anim_names: Array[String], crossfade: float = XFADE) -> void:
	if not _anim_player:
		return

	for anim_name in anim_names:
		if _anim_player.has_animation(anim_name):
			_anim_player.play(anim_name, crossfade)
			return

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


func _set_loop_modes() -> void:
	var looping_anims: Array[String] = [
		"Idle_No_Loop", "Idle_Rail_Loop", "Idle_A", "Idle_B",
		"Zombie_Walk_Fwd_Loop", "Walk_Carry_Loop", "Running_A", "Running_B",
		"Slide_Loop", "Crouching",
		"NinjaJump_Idle_Loop", "Jump_Idle",
		"Walking_A", "Walking_B", "Walking_C",
		"Crawling", "Sneaking",
	]
	for anim_name in looping_anims:
		if _anim_player.has_animation(anim_name):
			var anim: Animation = _anim_player.get_animation(anim_name)
			if anim.loop_mode == Animation.LOOP_NONE:
				anim.loop_mode = Animation.LOOP_LINEAR

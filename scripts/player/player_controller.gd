extends CharacterBody3D
## Player Controller — Handles lane switching, jumping, sliding, and collision.
## The player stays at Z=0; the world moves toward them.

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")
const ControlsManager = preload("res://scripts/input/controls_manager.gd")

# --- Signals ---
signal hit_obstacle
signal landed
signal started_slide
signal ended_slide
signal lane_changed(new_lane: int)

# --- Constants ---
const GRAVITY: float = 35.0
const JUMP_FORCE: float = 13.0
const LANE_SWITCH_SPEED: float = 10.0
const SLIDE_DURATION: float = 0.8

# Collision shape sizes
const STAND_HEIGHT: float = 1.8
const STAND_RADIUS: float = 0.35
const SLIDE_HEIGHT: float = 0.6
const SLIDE_RADIUS: float = 0.45
const HIT_AREA_FORWARD_BIAS: float = -0.18
const PLAYER_VISUAL_SCALE: float = 0.58
const PLAYER_BASE_SCENE_PATH: String = "res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb"
const PLAYER_EXTRA_ANIM_SCENE_PATHS: Array[String] = [
	"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementAdvanced.glb",
	"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_General.glb",
	"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_CombatMelee.glb",
]
const PLAYER_IDLE_ANIM_OPTIONS: Array[String] = [
	"Idle_No_Loop", "Idle_Rail_Loop", "Idle_A", "Idle", "Idle_Neutral",
	"Idle_Gun_Pointing", "Idle_Gun_Shoot",
]
const PLAYER_RUN_ANIM_OPTIONS: Array[String] = [
	"Running_A", "Running_B", "Run", "Walk_Carry_Loop", "Zombie_Walk_Fwd_Loop",
	"Walk", "Run_Holding", "Run_Tall",
]
const PLAYER_JUMP_ANIM_OPTIONS: Array[String] = [
	"Jump_Start", "NinjaJump_Start", "Jump", "Jump_Idle", "NinjaJump_Idle_Loop",
]

# --- State ---
enum PlayerState { RUNNING, JUMPING, SLIDING, STUMBLE, DEAD }

var current_state: PlayerState = PlayerState.RUNNING
var current_lane: int = 1  # 0=left, 1=center, 2=right
var target_x: float = 0.0
var vertical_velocity: float = 0.0
var is_grounded: bool = true
var _was_grounded: bool = true
var _slide_timer: float = 0.0
var _stumble_timer: float = 0.0
var _is_invincible: bool = false
var _invincible_timer: float = 0.0
var _input_buffer_jump: bool = false
var _input_buffer_slide: bool = false
var _buffer_timer: float = 0.0

# --- Touch / Swipe ---
const SWIPE_MIN_DISTANCE: float = 50.0  # minimum pixels to register a swipe
var _touch_start: Vector2 = Vector2.ZERO
var _touch_active: bool = false
var _touch_start_time: float = 0.0        # When touch began (for hold detection)
var _touch_hold_building: bool = false     # True while touch-holding to build bridge
const TOUCH_HOLD_THRESHOLD: float = 0.3   # Seconds before touch counts as hold

# --- Giant Rock / Double-Tap Blast ---
const DOUBLE_TAP_WINDOW: float = 0.6   # window for double-tap detection
const GIANT_ROCK_DETECT_RANGE: float = 45.0  # show hint at this distance
const GIANT_ROCK_BLAST_RANGE: float = 35.0   # can blast within this range
const GIANT_ROCK_IMPACT_Z: float = -2.15     # force a clean hit before visual clipping
var _last_space_time: float = -1.0
var _nearby_giant_rock: Node = null

# --- River / Bridge ---
const RIVER_DETECT_RANGE: float = 40.0     # Start detecting river at this distance
const RIVER_BRIDGE_RANGE: float = 30.0     # Can build bridge within this range
const RIVER_NO_JUMP_RANGE: float = 20.0    # No jumping within this range of a river
const BRIDGE_HOLD_TIME: float = 0.8        # Seconds of holding spacebar to build
const BRIDGE_PREVIEW_DEPTH: float = 3.6    # Must match the stylized bridge visual depth
const NATURE_BRIDGE_SCENE_PATH: String = "res://assets/Obstacles/bridges/Nature/Bridge.glb"
const NATURE_BRIDGE_MODEL_SCALE: Vector3 = Vector3(0.30, 0.058, 0.070)
const NATURE_BRIDGE_SOURCE_CENTER: Vector3 = Vector3(72.2364, 11.0247, -3.0039)
const NATURE_BRIDGE_SOURCE_MIN_Y: float = -3.0746
const NATURE_BRIDGE_MODEL_OFFSET: Vector3 = Vector3(0.0, -0.62, 0.0)
const NATURE_BRIDGE_ARC_HEIGHT: float = 0.42
const NATURE_BRIDGE_ARC_FORWARD_SHIFT: float = 0.04
const NATURE_BRIDGE_ARC_PITCH_DEGREES: float = 8.0
var _nearby_river: Node = null
var _space_hold_time: float = 0.0
var _bridge_built_for_river: Node = null    # Track which river we already built a bridge for
var _near_river_no_jump: bool = false       # True when within 20m of a river (suppress jump)
var _bridge_preview_river: Node = null
var _bridge_preview_node: Node3D = null
var _bridge_preview_lane: int = -1

# --- Node References ---
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var player_model: Node3D = $PlayerModel
@onready var hit_area: Area3D = $HitArea
@onready var hit_shape: CollisionShape3D = $HitArea/HitShape
@onready var footstep_timer: Timer = $FootstepTimer
@onready var coyote_timer: Timer = $CoyoteTimer

# Collision shape resource (shared between main body and hit area)
var _stand_shape: CapsuleShape3D
var _slide_shape: CapsuleShape3D
var _lane_lean_impulse: float = 0.0
var _jump_anticipation_timer: float = 0.0
var _land_impact_timer: float = 0.0
var _runner_shadow: MeshInstance3D = null
var _runner_shadow_material: StandardMaterial3D = null
var _movement_dust: GPUParticles3D = null
var _cyber_trail: GPUParticles3D = null


func _ready() -> void:
	ControlsManager.ensure_controls_ready()
	add_to_group("player")

	# Create collision shapes
	_stand_shape = CapsuleShape3D.new()
	_stand_shape.radius = STAND_RADIUS
	_stand_shape.height = STAND_HEIGHT

	_slide_shape = CapsuleShape3D.new()
	_slide_shape.radius = SLIDE_RADIUS
	_slide_shape.height = SLIDE_HEIGHT

	# Apply standing shape
	collision_shape.shape = _stand_shape
	collision_shape.position.y = STAND_HEIGHT / 2.0
	hit_shape.shape = _stand_shape.duplicate()
	hit_shape.position = Vector3(0.0, STAND_HEIGHT / 2.0, HIT_AREA_FORWARD_BIAS)

	# Set initial lane position
	target_x = GameManager.LANE_POSITIONS[current_lane]
	position.x = target_x
	position.y = 0.0
	position.z = 0.0

	# Create visible player mesh if PlayerModel is empty
	_ensure_player_visible()
	_setup_runner_fx()

	# Connect signals
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	hit_area.area_entered.connect(_on_hit_area_area_entered)
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)
	footstep_timer.start()

	GameManager.game_over_triggered.connect(_on_game_over)


func _physics_process(delta: float) -> void:
	if current_state == PlayerState.DEAD:
		return

	if not GameManager.is_playing():
		return

	_handle_input()
	_process_input_buffer(delta)
	_apply_gravity(delta)
	_update_lane_position(delta)
	_update_slide(delta)
	_update_stumble(delta)
	_update_invincibility(delta)

	# Move via Godot physics
	velocity = Vector3(0, vertical_velocity, 0)
	move_and_slide()

	# Ground check — use the physics result
	_was_grounded = is_grounded
	is_grounded = is_on_floor()

	# Landing detection
	if is_grounded and not _was_grounded:
		_on_land()

	# Leaving ground without jumping (walked off edge) — start coyote time
	if not is_grounded and _was_grounded and current_state == PlayerState.RUNNING:
		coyote_timer.start()

	# Keep player at Z=0 (world moves, not player)
	position.z = 0.0

	# Detect nearby giant rocks for hint display
	_scan_for_giant_rocks()

	# Detect nearby rivers and handle bridge building
	_scan_for_rivers()
	_update_bridge_hold(delta)
	_update_river_support_state()
	_update_runner_presentation(delta)


# --- Input ---

func _input(event: InputEvent) -> void:
	if current_state == PlayerState.DEAD or not GameManager.is_playing():
		return

	# Touch input — detect swipe gestures, taps, and holds
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_start_time = Time.get_ticks_msec() / 1000.0
			_touch_active = true
			_touch_hold_building = false
		else:
			if _touch_active:
				var delta_v: Vector2 = event.position - _touch_start
				var hold_duration: float = (Time.get_ticks_msec() / 1000.0) - _touch_start_time
				if _touch_hold_building:
					# Was holding to build bridge — already handled in _process
					pass
				elif delta_v.length() < SWIPE_MIN_DISTANCE:
					# Short tap (not a hold) — double tap for blast
					if hold_duration < TOUCH_HOLD_THRESHOLD:
						if GameManager.is_normal_mode():
							var blast_result := _try_giant_rock_blast()
							if blast_result == 1:
								pass  # Blast fired via double tap
					else:
						_process_swipe(event.position)
				_touch_active = false
				_touch_hold_building = false


func _process_swipe(end_pos: Vector2) -> void:
	var delta_v: Vector2 = end_pos - _touch_start
	if delta_v.length() < SWIPE_MIN_DISTANCE:
		return

	# Determine primary direction
	if absf(delta_v.x) > absf(delta_v.y):
		# Horizontal swipe — lane change (works in both modes)
		if delta_v.x < 0:
			_switch_lane(-1)
		else:
			_switch_lane(1)
	else:
		# Vertical swipe — jump / slide (natural mode only, quiz/pronunciation uses answer buttons)
		if GameManager.is_normal_mode():
			if delta_v.y < 0:
				# Swipe up — jump (blocked near river)
				if not _near_river_no_jump:
					if is_grounded or not coyote_timer.is_stopped():
						_jump()
					else:
						_input_buffer_jump = true
						_buffer_timer = 0.15
			else:
				# Swipe down — slide
				if is_grounded:
					_start_slide()
				else:
					_input_buffer_slide = true
					_buffer_timer = 0.15


func _handle_input() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.STUMBLE:
		return

	# Keyboard lane switching (PC)
	if Input.is_action_just_pressed("move_left"):
		_switch_lane(-1)
	elif Input.is_action_just_pressed("move_right"):
		_switch_lane(1)

	# In Quiz/Pronunciation mode, spacebar jump is disabled — use quiz_jump() from manager
	if GameManager.is_normal_mode():
		if Input.is_action_just_pressed("jump"):
			if is_grounded or not coyote_timer.is_stopped():
				_jump()
			else:
				_input_buffer_jump = true
				_buffer_timer = 0.15

		if Input.is_action_just_pressed("slide"):
			if is_grounded:
				_start_slide()
			else:
				_input_buffer_slide = true
				_buffer_timer = 0.15

		if Input.is_action_just_pressed("blast"):
			_try_giant_rock_blast()


func _process_input_buffer(delta: float) -> void:
	if _buffer_timer > 0.0:
		_buffer_timer -= delta
		if _buffer_timer <= 0.0:
			_input_buffer_jump = false
			_input_buffer_slide = false
			return

	if is_grounded:
		if _input_buffer_jump:
			_input_buffer_jump = false
			_input_buffer_slide = false
			_jump()
		elif _input_buffer_slide:
			_input_buffer_slide = false
			_input_buffer_jump = false
			_start_slide()


# --- Movement Actions ---

func _switch_lane(direction: int) -> void:
	var new_lane: int = clampi(current_lane + direction, 0, GameManager.LANE_COUNT - 1)
	if new_lane == current_lane:
		return
	current_lane = new_lane
	target_x = GameManager.LANE_POSITIONS[current_lane]
	_lane_lean_impulse = clampf(_lane_lean_impulse + float(direction) * -0.26, -0.32, 0.32)
	lane_changed.emit(current_lane)
	AudioManager.play_sfx(AudioManager.sfx_lane_swoosh, 0.0 if GameManager.is_cyberprank_theme() else 0.15)


func _jump() -> void:
	if current_state == PlayerState.SLIDING:
		_end_slide()
	current_state = PlayerState.JUMPING
	vertical_velocity = JUMP_FORCE
	is_grounded = false
	_jump_anticipation_timer = 0.12
	coyote_timer.stop()
	AudioManager.play_sfx(AudioManager.sfx_jump)


## Called by QuizManager when player answers correctly — triggers jump
func quiz_jump() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.STUMBLE:
		return
	if is_grounded or not coyote_timer.is_stopped():
		_jump()


## Called by QuizManager when player answers subtraction correctly — triggers slide
func quiz_slide() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.STUMBLE:
		return
	_start_slide()


## Called by QuizManager when player answers multiplication correctly — triggers blast
func quiz_blast() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.STUMBLE:
		return
	# In quiz mode, find the nearest approaching giant rock with extended range
	var target_rock: Node = _find_nearest_ahead("giant_rocks", 120.0)
	if target_rock and is_instance_valid(target_rock):
		_fire_blast_projectile(target_rock)


## Called by QuizManager when player answers division correctly — builds bridge
func quiz_bridge() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.STUMBLE:
		return
	# In quiz mode, find the nearest approaching river with extended range
	var target_river: Node = _find_nearest_ahead("river_crossings", 120.0)
	if target_river and is_instance_valid(target_river):
		_build_bridge(target_river)


func _find_nearest_ahead(group_name: String, max_range: float) -> Node:
	## Find the nearest node in a group that is AHEAD of the player (negative global Z).
	var nodes := get_tree().get_nodes_in_group(group_name)
	var best: Node = null
	var best_z: float = -99999.0
	for node in nodes:
		var z: float = node.global_position.z
		if z > 2.0:
			continue  # Already passed
		if absf(z) > max_range:
			continue  # Too far
		if z > best_z:
			best_z = z
			best = node
	return best


func _start_slide() -> void:
	if current_state == PlayerState.JUMPING:
		# Fast fall — slam down instantly when sliding mid-air
		vertical_velocity = -JUMP_FORCE * 1.5
		return

	current_state = PlayerState.SLIDING
	_slide_timer = SLIDE_DURATION
	if GameManager.is_cyberprank_theme():
		AudioManager.play_sfx(AudioManager.sfx_jump)
	else:
		AudioManager.play_sfx(AudioManager.sfx_slide, 0.1)

	# Shrink collision
	collision_shape.shape = _slide_shape
	collision_shape.position.y = SLIDE_HEIGHT / 2.0
	hit_shape.shape = _slide_shape.duplicate()
	hit_shape.position = Vector3(0.0, SLIDE_HEIGHT / 2.0, HIT_AREA_FORWARD_BIAS)

	# Tilt model forward
	player_model.rotation.x = deg_to_rad(-60)

	started_slide.emit()


func _end_slide() -> void:
	if current_state != PlayerState.SLIDING:
		return
	current_state = PlayerState.RUNNING
	_slide_timer = 0.0

	# Restore standing collision
	collision_shape.shape = _stand_shape
	collision_shape.position.y = STAND_HEIGHT / 2.0
	hit_shape.shape = _stand_shape.duplicate()
	hit_shape.position = Vector3(0.0, STAND_HEIGHT / 2.0, HIT_AREA_FORWARD_BIAS)

	# Reset model tilt
	player_model.rotation.x = 0.0

	ended_slide.emit()


func _on_land() -> void:
	if current_state == PlayerState.JUMPING:
		current_state = PlayerState.RUNNING
	vertical_velocity = 0.0
	_land_impact_timer = 0.18
	landed.emit()
	AudioManager.play_sfx(AudioManager.sfx_landing, 0.1)
	_spawn_landing_pulse()

	# Check buffered input
	if _input_buffer_slide:
		_input_buffer_slide = false
		_start_slide()


# --- Physics ---

func _apply_gravity(delta: float) -> void:
	if not is_grounded:
		vertical_velocity -= GRAVITY * delta
		# Terminal velocity
		vertical_velocity = maxf(vertical_velocity, -50.0)
	else:
		if vertical_velocity < 0.0:
			vertical_velocity = 0.0


func _update_lane_position(delta: float) -> void:
	# Smoothly interpolate X position to target lane
	var current_x: float = position.x
	position.x = lerp(current_x, target_x, LANE_SWITCH_SPEED * delta)

	# Snap when very close
	if absf(position.x - target_x) < 0.01:
		position.x = target_x


func _update_slide(delta: float) -> void:
	if current_state != PlayerState.SLIDING:
		return
	_slide_timer -= delta
	if _slide_timer <= 0.0:
		_end_slide()


func _update_stumble(delta: float) -> void:
	if current_state != PlayerState.STUMBLE:
		return
	_stumble_timer -= delta
	if _stumble_timer <= 0.0:
		current_state = PlayerState.RUNNING
		_is_invincible = false


func _update_invincibility(delta: float) -> void:
	if not _is_invincible:
		return
	_invincible_timer -= delta

	# Flash effect: toggle model visibility
	if player_model:
		player_model.visible = int(_invincible_timer * 10.0) % 2 == 0

	if _invincible_timer <= 0.0:
		_is_invincible = false
		if player_model:
			player_model.visible = true


func _update_runner_presentation(delta: float) -> void:
	if player_model == null:
		return

	if _jump_anticipation_timer > 0.0:
		_jump_anticipation_timer = maxf(0.0, _jump_anticipation_timer - delta)
	if _land_impact_timer > 0.0:
		_land_impact_timer = maxf(0.0, _land_impact_timer - delta)

	_lane_lean_impulse = lerpf(_lane_lean_impulse, 0.0, delta * 8.5)
	var lane_diff: float = target_x - position.x
	var target_roll: float = clampf(-lane_diff * 0.18, -0.24, 0.24) + _lane_lean_impulse
	var target_pitch: float = deg_to_rad(-4.0) if current_state == PlayerState.RUNNING else 0.0
	var target_visual_pos := Vector3.ZERO

	if current_state == PlayerState.SLIDING:
		target_pitch = deg_to_rad(-60.0)
	elif current_state == PlayerState.JUMPING:
		target_pitch = deg_to_rad(-12.0 if vertical_velocity > 0.0 else 10.0)
	elif _land_impact_timer > 0.0:
		target_pitch = deg_to_rad(6.0 * (_land_impact_timer / 0.18))

	if GameManager.is_nature_theme() and current_state == PlayerState.RUNNING:
		var bridge_normalized_z: float = _get_active_nature_bridge_normalized_z()
		if bridge_normalized_z > -9.0:
			var arch_ratio: float = cos(bridge_normalized_z * PI * 0.5)
			target_visual_pos.y += arch_ratio * NATURE_BRIDGE_ARC_HEIGHT
			target_visual_pos.z += arch_ratio * NATURE_BRIDGE_ARC_FORWARD_SHIFT
			target_pitch += deg_to_rad(-bridge_normalized_z * NATURE_BRIDGE_ARC_PITCH_DEGREES)

	player_model.rotation.x = lerpf(player_model.rotation.x, target_pitch, delta * 10.0)
	player_model.rotation.z = lerpf(player_model.rotation.z, target_roll, delta * 10.0)
	player_model.position = player_model.position.lerp(target_visual_pos, delta * 9.0)

	var target_scale := Vector3.ONE
	if _jump_anticipation_timer > 0.0:
		target_scale = Vector3(1.08, 0.90, 1.08)
	elif _land_impact_timer > 0.0:
		var land_ratio: float = _land_impact_timer / 0.18
		target_scale = Vector3(1.06 + 0.05 * land_ratio, 0.86 + 0.08 * (1.0 - land_ratio), 1.06 + 0.05 * land_ratio)
	player_model.scale = player_model.scale.lerp(target_scale, delta * 12.0)

	_update_runner_shadow()
	_update_runner_fx()


# --- Collision ---

func _on_hit_area_body_entered(body: Node3D) -> void:
	_handle_collision(body)


func _on_hit_area_area_entered(area: Area3D) -> void:
	# Collectibles use Area3D with coin.gd script
	if area.is_in_group("coins"):
		if area.has_method("collect"):
			area.collect()
		else:
			# Fallback for coins without script
			var coin_type: String = area.get_meta("coin_type", "gold")
			GameManager.collect_coin(coin_type)
			area.queue_free()
		return

	_handle_collision(area)


func _handle_collision(node: Node) -> void:
	if _is_invincible or current_state == PlayerState.DEAD:
		return

	# River kill zones — skip if bridge was built on this lane
	if node.is_in_group("river_kill_zones"):
		if _is_supported_on_river_zone(node):
			return
		# No bridge — die
		hit_obstacle.emit()
		AudioManager.play_impact()
		GameManager.trigger_game_over()
		_die(node)
		return

	if node.is_in_group("obstacles") and not node.is_in_group("river_kill_zones"):
		hit_obstacle.emit()
		AudioManager.play_impact()
		GameManager.trigger_game_over()
		_die(node)


func _die(hit_node: Node = null) -> void:
	current_state = PlayerState.DEAD
	vertical_velocity = 0.0
	velocity = Vector3.ZERO
	footstep_timer.stop()
	coyote_timer.stop()
	_slide_timer = 0.0
	_stumble_timer = 0.0
	_jump_anticipation_timer = 0.0
	_land_impact_timer = 0.0
	_lane_lean_impulse = 0.0

	# Restore the standing collider so the collapsed body reads cleanly on the road.
	collision_shape.shape = _stand_shape
	collision_shape.position.y = STAND_HEIGHT / 2.0
	hit_shape.shape = _stand_shape.duplicate()
	hit_shape.position = Vector3(0.0, STAND_HEIGHT / 2.0, HIT_AREA_FORWARD_BIAS)

	# Collapse sideways onto the road instead of flipping out of frame.
	var side_dir: float = 0.65
	if current_lane == 0:
		side_dir = 1.0
	elif current_lane == 2:
		side_dir = -1.0
	var fallen_position := player_model.position + Vector3(0.16 * side_dir, 0.08, 0.18)
	var fallen_rotation := Vector3(deg_to_rad(6.0), 0.0, deg_to_rad(86.0 * side_dir))
	if hit_node != null and hit_node.is_in_group("giant_rocks"):
		# Giant rocks fill the whole front space, so collapse backward onto the road
		# instead of sideways into the blocker volume.
		fallen_position = player_model.position + Vector3(0.05 * side_dir, 0.05, 0.52)
		fallen_rotation = Vector3(deg_to_rad(-10.0), 0.0, deg_to_rad(62.0 * side_dir))
	var tween: Tween = create_tween()
	tween.tween_property(player_model, "rotation", fallen_rotation, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(player_model, "position", fallen_position, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(player_model, "scale", Vector3.ONE, 0.2)


func _on_game_over() -> void:
	if current_state != PlayerState.DEAD:
		_die()


func _on_footstep_timer_timeout() -> void:
	if current_state == PlayerState.RUNNING and is_grounded and GameManager.is_playing():
		AudioManager.play_footstep()
		# Adjust footstep speed based on game speed
		var speed_ratio: float = GameManager.get_speed_ratio()
		footstep_timer.wait_time = lerpf(0.35, 0.2, speed_ratio)


# --- Giant Rock / Double-Tap Blast ---

func _scan_for_giant_rocks() -> void:
	## Check for nearby giant rocks and show/hide hint labels.
	_nearby_giant_rock = null
	var rocks := get_tree().get_nodes_in_group("giant_rocks")
	for rock in rocks:
		# World moves +Z toward player (at Z=0). Rocks ahead have negative global Z.
		# As they approach, global Z increases toward 0.
		var rock_z: float = rock.global_position.z
		if rock_z > 2.0:
			continue  # Rock already passed behind us
		var rock_state = rock.get("state")
		if rock_state != null and rock_state < 1 and rock_z >= GIANT_ROCK_IMPACT_Z:
			_handle_collision(rock)
			return
		var abs_dist: float = absf(rock_z)
		if abs_dist < GIANT_ROCK_DETECT_RANGE:
			if rock.has_method("show_hint"):
				rock.show_hint()
			if abs_dist < GIANT_ROCK_BLAST_RANGE:
				_nearby_giant_rock = rock
		else:
			if rock.has_method("hide_hint"):
				rock.hide_hint()


func _try_giant_rock_blast() -> int:
	## Returns: 1 = blast fired, -1 = first tap recorded, 0 = no giant rock nearby
	if _nearby_giant_rock == null or not is_instance_valid(_nearby_giant_rock):
		_last_space_time = -1.0
		return 0

	var rock_state = _nearby_giant_rock.get("state")
	if rock_state == null or rock_state >= 1:
		_last_space_time = -1.0
		return 0

	var now: float = Time.get_ticks_msec() / 1000.0
	if _last_space_time > 0.0 and (now - _last_space_time) < DOUBLE_TAP_WINDOW:
		# Double-tap detected — fire blast!
		_last_space_time = -1.0
		_fire_blast_projectile(_nearby_giant_rock)
		return 1
	else:
		# First tap — record time (jump still happens)
		_last_space_time = now
		return -1


func _fire_blast_projectile(target_rock: Node) -> void:
	if GameManager.is_cyberprank_theme():
		_fire_cyber_laser(target_rock)
		return

	## Spawn a glowing energy ball that flies from the player to the rock.
	var projectile := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	var blast_color := Color(0.84, 0.72, 0.42, 0.92)
	var emission_color := Color(0.46, 0.82, 0.36)
	var light_color := Color(0.88, 0.78, 0.42)
	if GameManager.is_cyberprank_theme():
		blast_color = Color(0.72, 0.26, 1.0, 0.92)
		emission_color = Color(0.18, 0.95, 1.0)
		light_color = Color(0.42, 0.92, 1.0)
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.12
		capsule.height = 0.66
		projectile.mesh = capsule
		projectile.rotation.z = deg_to_rad(90.0)
		var halo := MeshInstance3D.new()
		var halo_torus := TorusMesh.new()
		halo_torus.inner_radius = 0.18
		halo_torus.outer_radius = 0.28
		var halo_mat := StandardMaterial3D.new()
		halo_mat.albedo_color = Color(0.70, 1.0, 0.62, 0.42)
		halo_mat.emission_enabled = true
		halo_mat.emission = Color(0.44, 0.92, 0.30)
		halo_mat.emission_energy_multiplier = 2.6
		halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		halo_torus.material = halo_mat
		halo.mesh = halo_torus
		halo.rotation.x = deg_to_rad(90.0)
		projectile.add_child(halo)
	if projectile.mesh == null:
		var sphere := SphereMesh.new()
		sphere.radius = 0.25
		sphere.height = 0.5
		projectile.mesh = sphere
	mat.albedo_color = blast_color
	mat.emission_enabled = true
	mat.emission = emission_color
	mat.emission_energy_multiplier = 4.0 if GameManager.is_nature_theme() else 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.18 if GameManager.is_nature_theme() else 0.02
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if GameManager.is_cyberprank_theme() else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if projectile.mesh is PrimitiveMesh:
		(projectile.mesh as PrimitiveMesh).material = mat

	# Add a point light to the projectile for glow
	var light := OmniLight3D.new()
	light.light_color = light_color
	light.light_energy = 3.0 if GameManager.is_nature_theme() else 4.0
	light.omni_range = 5.0
	projectile.add_child(light)

	# Start position: in front of player (global space)
	projectile.position = Vector3(global_position.x, 1.2, global_position.z - 0.5)
	# Add projectile to the scene root so it's not affected by chunk movement
	get_tree().current_scene.add_child(projectile)

	# Target: the rock's global position (center mass)
	var target_pos := Vector3(target_rock.global_position.x, 1.5, target_rock.global_position.z)

	# Animate the projectile flying to the rock
	var dist: float = projectile.position.distance_to(target_pos)
	var travel_time: float = clampf(dist / 50.0, 0.1, 0.4)  # Fast projectile

	var tween := get_tree().create_tween()
	tween.tween_property(projectile, "position", target_pos, travel_time).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(projectile, "scale", Vector3(1.3, 1.3, 1.3) if GameManager.is_nature_theme() else Vector3(1.5, 1.5, 1.5), travel_time)
	if GameManager.is_nature_theme():
		tween.parallel().tween_property(projectile, "rotation:y", projectile.rotation.y + deg_to_rad(220.0), travel_time)
	AudioManager.play_blast_fire()

	# On hit: instantly destroy the rock
	tween.tween_callback(func():
		# Screen flash
		if light:
			light.light_energy = 10.0

		if is_instance_valid(target_rock):
			if target_rock.has_method("trigger_blast"):
				target_rock.trigger_blast()
			AudioManager.play_blast_impact()

		# Fade and remove projectile
		var fade_tween := get_tree().create_tween()
		fade_tween.tween_property(projectile, "scale", Vector3(2.2, 2.2, 2.2) if GameManager.is_nature_theme() else Vector3(3.0, 3.0, 3.0), 0.2)
		fade_tween.parallel().tween_callback(func(): mat.albedo_color.a = 0.0)
		fade_tween.tween_callback(projectile.queue_free)
	)


func _fire_cyber_laser(target_rock: Node) -> void:
	var start_pos := Vector3(global_position.x, 1.24, global_position.z - 0.35)
	var target_pos := Vector3(target_rock.global_position.x, 1.5, target_rock.global_position.z)
	var beam_length: float = start_pos.distance_to(target_pos)
	var plasma_core := Color(1.0, 0.82, 0.26, 0.98)
	var plasma_glow := Color(1.0, 0.36, 0.08, 0.44)
	var core_emission := Color(1.0, 0.42, 0.06, 1.0)
	var glow_emission := Color(1.0, 0.18, 0.04, 1.0)

	var laser_root := Node3D.new()
	laser_root.position = start_pos.lerp(target_pos, 0.5)
	laser_root.look_at(target_pos, Vector3.UP, true)
	get_tree().current_scene.add_child(laser_root)

	var core_material := StandardMaterial3D.new()
	core_material.albedo_color = plasma_core
	core_material.roughness = 0.02
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.emission_enabled = true
	core_material.emission = core_emission
	core_material.emission_energy_multiplier = 6.0
	core_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_material.no_depth_test = true

	var beam_core := MeshInstance3D.new()
	var core_box := BoxMesh.new()
	core_box.size = Vector3(0.10, 0.10, beam_length)
	core_box.material = core_material
	beam_core.mesh = core_box
	beam_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	laser_root.add_child(beam_core)

	var glow_material := StandardMaterial3D.new()
	glow_material.albedo_color = plasma_glow
	glow_material.roughness = 0.01
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.emission_enabled = true
	glow_material.emission = glow_emission
	glow_material.emission_energy_multiplier = 4.1
	glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_material.no_depth_test = true

	var beam_glow := MeshInstance3D.new()
	var glow_box := BoxMesh.new()
	glow_box.size = Vector3(0.26, 0.26, beam_length)
	glow_box.material = glow_material
	beam_glow.mesh = glow_box
	beam_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	laser_root.add_child(beam_glow)

	var muzzle := _create_laser_flash(Color(1.0, 0.86, 0.38, 0.88), Color(1.0, 0.36, 0.08, 1.0), 1.3)
	muzzle.position = Vector3(0.0, 0.0, beam_length * 0.5)
	laser_root.add_child(muzzle)

	var impact := _create_laser_flash(Color(1.0, 0.78, 0.28, 0.84), Color(1.0, 0.18, 0.04, 1.0), 1.8)
	impact.position = Vector3(0.0, 0.0, -beam_length * 0.5)
	laser_root.add_child(impact)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.54, 0.16)
	light.light_energy = 4.4
	light.omni_range = 7.0
	laser_root.add_child(light)

	AudioManager.play_blast_fire()

	var fade_tween := get_tree().create_tween()
	fade_tween.tween_method(func(alpha: float):
		core_material.albedo_color.a = alpha
		glow_material.albedo_color.a = alpha * 0.50
		light.light_energy = 4.4 * alpha
	, 1.0, 0.0, 0.12)
	fade_tween.parallel().tween_property(laser_root, "scale", Vector3(1.0, 1.55, 1.0), 0.12)
	fade_tween.tween_callback(func():
		if is_instance_valid(target_rock):
			if target_rock.has_method("trigger_blast"):
				target_rock.trigger_blast()
			AudioManager.play_blast_impact()
		laser_root.queue_free()
	)


func _create_laser_flash(color: Color, emission: Color, scale_value: float) -> MeshInstance3D:
	var flash := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34 * scale_value, 0.34 * scale_value)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = 3.4
	quad.material = material
	flash.mesh = quad
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return flash


# --- River Detection & Bridge Building ---

func _scan_for_rivers() -> void:
	## Check for nearby rivers and update _nearby_river.
	_nearby_river = null
	_near_river_no_jump = false
	var rivers := get_tree().get_nodes_in_group("river_crossings")
	for river in rivers:
		var river_z: float = river.global_position.z
		if river_z > 2.0:
			continue  # Already passed
		var abs_dist: float = absf(river_z)
		if abs_dist < RIVER_DETECT_RANGE:
			# Don't target rivers we already built a bridge for on our lane
			if river == _bridge_built_for_river and river.has_meta("bridge_lane_%d" % current_lane):
				continue
			# Within 20m — suppress jumping
			if abs_dist < RIVER_NO_JUMP_RANGE:
				_near_river_no_jump = true
			if abs_dist < RIVER_BRIDGE_RANGE:
				_nearby_river = river


func _update_bridge_hold(delta: float) -> void:
	## Track bridge-action/touch hold to build bridge over river.
	if _nearby_river == null or not is_instance_valid(_nearby_river):
		_space_hold_time = 0.0
		_touch_hold_building = false
		_clear_bridge_preview()
		return

	# Already built bridge for this river on this lane
	if _nearby_river.has_meta("bridge_lane_%d" % current_lane):
		_clear_bridge_preview()
		return

	# Check keyboard hold OR touch hold
	var is_holding: bool = Input.is_action_pressed("bridge")

	# Touch hold detection: finger is down, hasn't swiped, held long enough
	if _touch_active and not _touch_hold_building:
		var touch_dur: float = (Time.get_ticks_msec() / 1000.0) - _touch_start_time
		if touch_dur >= TOUCH_HOLD_THRESHOLD:
			_touch_hold_building = true
	if _touch_hold_building:
		is_holding = true

	if is_holding:
		_space_hold_time += delta
		_update_bridge_preview(_nearby_river, clampf(_space_hold_time / BRIDGE_HOLD_TIME, 0.0, 1.0))
		if _space_hold_time >= BRIDGE_HOLD_TIME:
			_build_bridge(_nearby_river)
			_space_hold_time = 0.0
	else:
		_clear_bridge_preview()
		_space_hold_time = 0.0


func _update_river_support_state() -> void:
	if current_state == PlayerState.DEAD:
		return
	for river_zone in get_tree().get_nodes_in_group("river_kill_zones"):
		if not is_instance_valid(river_zone):
			continue
		if not _is_player_inside_river_zone(river_zone):
			continue
		if _is_supported_on_river_zone(river_zone):
			continue
		hit_obstacle.emit()
		AudioManager.play_impact()
		GameManager.trigger_game_over()
		_die()
		return


func _build_bridge(river: Node) -> void:
	# Spawn the stylized full-width bridge for the current river crossing.
	_build_bridge_stylized_impl(river)


func _build_bridge_stylized_impl(river: Node) -> void:
	_clear_bridge_preview()

	for l in 3:
		river.set_meta("bridge_lane_%d" % l, true)
	_bridge_built_for_river = river

	for child in river.get_children():
		if child.is_in_group("river_kill_zones"):
			child.remove_from_group("obstacles")
			child.remove_from_group("river_kill_zones")
			for sub in child.get_children():
				if sub is CollisionShape3D:
					sub.set_deferred("disabled", true)

	var bridge_node := Node3D.new()
	bridge_node.name = "Bridge_Lane%d" % current_lane
	bridge_node.position = Vector3(0.0, 0.16, 0.0)
	_build_stylized_bridge(bridge_node)
	river.add_child(bridge_node)

	AudioManager.play_bridge_build()
	print("[Bridge] Built on lane %d for river at Z=%.1f" % [current_lane, river.global_position.z])


func _update_bridge_preview(river: Node, progress: float) -> void:
	if _bridge_preview_river != river or _bridge_preview_node == null or not is_instance_valid(_bridge_preview_node):
		_clear_bridge_preview()
		_bridge_preview_river = river
		_bridge_preview_lane = current_lane
		_bridge_preview_node = Node3D.new()
		_bridge_preview_node.name = "BridgePreview"
		_bridge_preview_node.position = Vector3(0.0, 0.16, 0.0)
		river.add_child(_bridge_preview_node)
		_build_stylized_bridge(_bridge_preview_node)
		_apply_bridge_preview_look(_bridge_preview_node)

	if _bridge_preview_node == null:
		return

	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	river.set_meta("bridge_preview_lane_%d" % _bridge_preview_lane, clamped_progress)
	if GameManager.is_nature_theme():
		var z_scale: float = lerpf(0.22, 1.0, clamped_progress)
		var center_z: float = lerpf(1.18, 0.0, clamped_progress)
		var uniform_xy: float = lerpf(0.94, 1.0, clamped_progress)
		_bridge_preview_node.scale = Vector3(uniform_xy, uniform_xy, z_scale)
		_bridge_preview_node.position.z = center_z
		_bridge_preview_node.position.y = 0.16 + sin(Time.get_ticks_msec() / 120.0) * 0.015
	else:
		var z_scale: float = lerpf(0.08, 1.0, clamped_progress)
		var center_z: float = lerpf(1.42, 0.0, clamped_progress)
		_bridge_preview_node.scale = Vector3(1.0, lerpf(0.82, 1.0, clamped_progress), z_scale)
		_bridge_preview_node.position.z = center_z
		_bridge_preview_node.position.y = 0.14 + sin(Time.get_ticks_msec() / 120.0) * 0.02


func _clear_bridge_preview() -> void:
	if _bridge_preview_river and is_instance_valid(_bridge_preview_river):
		if _bridge_preview_lane >= 0:
			_bridge_preview_river.remove_meta("bridge_preview_lane_%d" % _bridge_preview_lane)
	if _bridge_preview_node and is_instance_valid(_bridge_preview_node):
		_bridge_preview_node.queue_free()
	_bridge_preview_node = null
	_bridge_preview_river = null
	_bridge_preview_lane = -1


func _is_supported_on_river_zone(river_zone: Node) -> bool:
	var lane_idx: int = river_zone.get_meta("lane_index", -1)
	if lane_idx != current_lane:
		return false
	var river_parent: Node = river_zone.get_parent()
	return river_parent != null and _is_river_lane_supported(river_parent, lane_idx)


func _is_river_lane_supported(river: Node, lane_idx: int) -> bool:
	if river.has_meta("bridge_lane_%d" % lane_idx):
		return true
	if river != _bridge_preview_river or lane_idx != _bridge_preview_lane:
		return false
	if _bridge_preview_node == null or not is_instance_valid(_bridge_preview_node):
		return false
	var preview_local_player: Vector3 = _bridge_preview_node.to_local(global_position)
	return absf(preview_local_player.z) <= (BRIDGE_PREVIEW_DEPTH * 0.5) + 0.12


func _is_player_inside_river_zone(river_zone: Node) -> bool:
	if river_zone.get_meta("lane_index", -1) != current_lane:
		return false
	var collision_shape := river_zone.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision_shape == null or not (collision_shape.shape is BoxShape3D):
		return false
	var box := collision_shape.shape as BoxShape3D
	var local_player: Vector3 = river_zone.to_local(global_position)
	var center: Vector3 = collision_shape.position
	return (
		absf(local_player.x - center.x) <= (box.size.x * 0.5) + 0.18 and
		absf(local_player.z - center.z) <= (box.size.z * 0.5) + 0.12
	)


func _get_active_nature_bridge_normalized_z() -> float:
	for river_zone in get_tree().get_nodes_in_group("river_kill_zones"):
		if not is_instance_valid(river_zone):
			continue
		if river_zone.get_meta("lane_index", -1) != current_lane:
			continue
		if not _is_player_inside_river_zone(river_zone):
			continue
		if not _is_supported_on_river_zone(river_zone):
			continue

		var river := river_zone.get_parent()
		if river == null:
			continue

		var reference_node: Node3D = null
		if river == _bridge_preview_river and _bridge_preview_lane == current_lane and _bridge_preview_node and is_instance_valid(_bridge_preview_node):
			reference_node = _bridge_preview_node
		else:
			reference_node = river.get_node_or_null("Bridge_Lane%d" % current_lane) as Node3D
		if reference_node == null:
			continue

		var local_player: Vector3 = reference_node.to_local(global_position)
		return clampf(local_player.z / (BRIDGE_PREVIEW_DEPTH * 0.5), -1.0, 1.0)

	return -10.0


func _apply_bridge_preview_look(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			for surface_idx in mesh_instance.mesh.get_surface_count():
				var active_material := mesh_instance.get_active_material(surface_idx)
				if active_material is StandardMaterial3D:
					var preview_material: StandardMaterial3D = (active_material as StandardMaterial3D).duplicate()
					preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					preview_material.albedo_color.a *= 0.52 if GameManager.is_cyberprank_theme() else 0.68
					if GameManager.is_cyberprank_theme():
						preview_material.emission_enabled = true
						preview_material.emission_energy_multiplier *= 1.25
					mesh_instance.set_surface_override_material(surface_idx, preview_material)
	for child in node.get_children():
		_apply_bridge_preview_look(child)


func _build_stylized_bridge(parent: Node3D) -> void:
	if GameManager.is_cyberprank_theme():
		_build_hologram_bridge(parent)
		return
	if _build_nature_bridge_model(parent):
		return

	var bridge_width: float = GameManager.LANE_WIDTH * GameManager.LANE_COUNT + 1.0
	var bridge_depth: float = BRIDGE_PREVIEW_DEPTH

	var deck := _create_bridge_box(
		Vector3(bridge_width, 0.22, bridge_depth),
		Color(0.79, 0.71, 0.56, 1.0),
		0.92
	)
	parent.add_child(deck)

	var deck_inset := _create_bridge_box(
		Vector3(bridge_width - 0.7, 0.08, bridge_depth - 0.35),
		Color(0.87, 0.83, 0.72, 1.0),
		0.84
	)
	deck_inset.position = Vector3(0.0, 0.15, 0.0)
	parent.add_child(deck_inset)

	var left_rail := _create_bridge_box(
		Vector3(0.18, 0.52, bridge_depth),
		Color(0.60, 0.46, 0.31, 1.0),
		0.95
	)
	left_rail.position = Vector3(-(bridge_width * 0.5) + 0.22, 0.36, 0.0)
	parent.add_child(left_rail)

	var right_rail := _create_bridge_box(
		Vector3(0.18, 0.52, bridge_depth),
		Color(0.60, 0.46, 0.31, 1.0),
		0.95
	)
	right_rail.position = Vector3((bridge_width * 0.5) - 0.22, 0.36, 0.0)
	parent.add_child(right_rail)

	var left_cap := _create_bridge_box(
		Vector3(0.28, 0.10, bridge_depth),
		Color(0.49, 0.38, 0.25, 1.0),
		0.98
	)
	left_cap.position = Vector3(-(bridge_width * 0.5) + 0.22, 0.63, 0.0)
	parent.add_child(left_cap)

	var right_cap := _create_bridge_box(
		Vector3(0.28, 0.10, bridge_depth),
		Color(0.49, 0.38, 0.25, 1.0),
		0.98
	)
	right_cap.position = Vector3((bridge_width * 0.5) - 0.22, 0.63, 0.0)
	parent.add_child(right_cap)

	for z_sign in [-1.0, 1.0]:
		var threshold := _create_bridge_box(
			Vector3(bridge_width + 0.25, 0.12, 0.28),
			Color(0.58, 0.46, 0.32, 1.0),
			0.97
		)
		threshold.position = Vector3(0.0, 0.05, z_sign * ((bridge_depth * 0.5) - 0.18))
		parent.add_child(threshold)

	for x_sign in [-1.0, 1.0]:
		for z_offset in [-1.8, -0.6, 0.6, 1.8]:
			var post := _create_bridge_box(
				Vector3(0.18, 0.56, 0.18),
				Color(0.56, 0.43, 0.29, 1.0),
				0.96
			)
			post.position = Vector3(x_sign * ((bridge_width * 0.5) - 0.22), 0.31, z_offset)
			parent.add_child(post)

	var support_left := _create_bridge_box(
		Vector3(0.35, 0.24, bridge_depth - 0.45),
		Color(0.40, 0.31, 0.22, 1.0),
		0.98
	)
	support_left.position = Vector3(-1.45, -0.14, 0.0)
	parent.add_child(support_left)

	var support_right := _create_bridge_box(
		Vector3(0.35, 0.24, bridge_depth - 0.45),
		Color(0.40, 0.31, 0.22, 1.0),
		0.98
	)
	support_right.position = Vector3(1.45, -0.14, 0.0)
	parent.add_child(support_right)


func _build_nature_bridge_model(parent: Node3D) -> bool:
	if not ResourceLoader.exists(NATURE_BRIDGE_SCENE_PATH):
		return false
	var scene := load(NATURE_BRIDGE_SCENE_PATH) as PackedScene
	if scene == null:
		return false
	var bridge_model := scene.instantiate() as Node3D
	if bridge_model == null:
		return false
	var bridge_root := Node3D.new()
	bridge_root.name = "NatureBridgeModel"
	bridge_root.scale = NATURE_BRIDGE_MODEL_SCALE
	bridge_root.position = NATURE_BRIDGE_MODEL_OFFSET
	parent.add_child(bridge_root)
	bridge_model.position = Vector3(
		-NATURE_BRIDGE_SOURCE_CENTER.x,
		-NATURE_BRIDGE_SOURCE_MIN_Y,
		-NATURE_BRIDGE_SOURCE_CENTER.z
	)
	bridge_root.add_child(bridge_model)
	return true


func _build_hologram_bridge(parent: Node3D) -> void:
	var bridge_width: float = GameManager.LANE_WIDTH * GameManager.LANE_COUNT + 1.05
	var bridge_depth: float = BRIDGE_PREVIEW_DEPTH

	var deck := _create_holo_bridge_part(
		Vector3(bridge_width, 0.18, bridge_depth),
		Color(0.12, 0.86, 1.0, 0.30),
		Color(0.14, 0.78, 1.0, 1.0),
		3.4
	)
	parent.add_child(deck)

	var deck_core := _create_holo_bridge_part(
		Vector3(bridge_width - 0.7, 0.06, bridge_depth - 0.25),
		Color(0.86, 0.24, 1.0, 0.22),
		Color(0.86, 0.24, 1.0, 1.0),
		2.4
	)
	deck_core.position = Vector3(0.0, 0.05, 0.0)
	parent.add_child(deck_core)

	for lane_x in GameManager.LANE_POSITIONS:
		var guide_line := _create_holo_bridge_part(
			Vector3(0.10, 0.04, bridge_depth - 0.35),
			Color(0.10, 0.18, 0.24, 0.35),
			Color(0.14, 0.92, 1.0, 1.0),
			2.1
		)
		guide_line.position = Vector3(lane_x, 0.11, 0.0)
		parent.add_child(guide_line)

	for side in [-1.0, 1.0]:
		var rail := _create_holo_bridge_part(
			Vector3(0.12, 0.60, bridge_depth),
			Color(0.10, 0.22, 0.30, 0.82),
			Color(0.12, 0.90, 1.0, 1.0),
			2.2
		)
		rail.position = Vector3(side * (bridge_width * 0.5 - 0.16), 0.34, 0.0)
		parent.add_child(rail)

	for z_sign in [-1.0, 1.0]:
		var gate := _create_holo_bridge_part(
			Vector3(bridge_width + 0.12, 0.10, 0.16),
			Color(0.12, 0.24, 0.34, 0.86),
			Color(0.18, 0.98, 1.0, 1.0),
			2.6
		)
		gate.position = Vector3(0.0, 0.05, z_sign * ((bridge_depth * 0.5) - 0.12))
		parent.add_child(gate)

	for x_sign in [-1.0, 1.0]:
		for z_offset in [-1.6, -0.55, 0.55, 1.6]:
			var post := _create_holo_bridge_part(
				Vector3(0.14, 0.44, 0.14),
				Color(0.10, 0.18, 0.24, 0.92),
				Color(0.82, 0.30, 1.0, 1.0),
				1.8
			)
			post.position = Vector3(x_sign * ((bridge_width * 0.5) - 0.16), 0.23, z_offset)
			parent.add_child(post)

	for x_sign in [-1.0, 1.0]:
		for z_sign in [-1.0, 1.0]:
			parent.add_child(_create_bridge_beacon(
				Vector3(
					x_sign * ((bridge_width * 0.5) - 0.20),
					0.18,
					z_sign * ((bridge_depth * 0.5) - 0.24)
				),
				x_sign < 0.0
			))


func _create_bridge_box(size: Vector3, color: Color, roughness: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	box.material = material
	mesh_instance.mesh = box
	return mesh_instance


func _create_holo_bridge_part(size: Vector3, color: Color, emission: Color, energy: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.08
	material.metallic = 0.18
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance


func _create_bridge_beacon(pos: Vector3, use_magenta: bool) -> Node3D:
	var beacon := Node3D.new()
	beacon.position = pos

	var base := _create_holo_bridge_part(
		Vector3(0.16, 0.16, 0.16),
		Color(0.08, 0.14, 0.20, 0.92),
		Color(0.12, 0.84, 1.0, 1.0),
		1.8
	)
	beacon.add_child(base)

	var pillar := _create_holo_bridge_part(
		Vector3(0.07, 0.56, 0.07),
		Color(0.14, 0.20, 0.28, 0.68),
		Color(0.86, 0.24, 1.0, 1.0) if use_magenta else Color(0.12, 0.94, 1.0, 1.0),
		2.4
	)
	pillar.position.y = 0.30
	beacon.add_child(pillar)

	var light := OmniLight3D.new()
	light.light_color = Color(0.86, 0.24, 1.0, 1.0) if use_magenta else Color(0.12, 0.94, 1.0, 1.0)
	light.light_energy = 1.1
	light.omni_range = 3.8
	light.position.y = 0.42
	beacon.add_child(light)

	return beacon


func _ensure_player_visible() -> void:
	# If PlayerModel already has children (e.g. GLB model dragged in), skip
	if player_model.get_child_count() > 0:
		return

	var visual_scale: float = _get_player_visual_scale()
	var runner_visual := _build_runner_visual()
	if runner_visual:
		player_model.add_child(runner_visual)
		runner_visual.rotation.y = PI
		runner_visual.scale = Vector3.ONE * visual_scale
		return

	# Last fallback: simple capsule
	var body_mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.0
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.25, 0.55, 0.85)
	body_mat.roughness = 0.6
	capsule.material = body_mat
	body_mesh.mesh = capsule
	body_mesh.position.y = 0.6
	player_model.add_child(body_mesh)

	var head_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.92, 0.78, 0.65)
	head_mat.roughness = 0.5
	sphere.material = head_mat
	head_mesh.mesh = sphere
	head_mesh.position.y = 1.25
	player_model.add_child(head_mesh)


func _setup_runner_fx() -> void:
	if _runner_shadow == null:
		_runner_shadow = MeshInstance3D.new()
		_runner_shadow.name = "RunnerShadow"
		var shadow_mesh := CylinderMesh.new()
		shadow_mesh.top_radius = 0.34
		shadow_mesh.bottom_radius = 0.44
		shadow_mesh.height = 0.03
		_runner_shadow_material = StandardMaterial3D.new()
		_runner_shadow_material.albedo_color = Color(0.01, 0.03, 0.05, 0.28) if GameManager.is_cyberprank_theme() else Color(0.0, 0.0, 0.0, 0.22)
		_runner_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_runner_shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_runner_shadow_material.no_depth_test = false
		shadow_mesh.material = _runner_shadow_material
		_runner_shadow.mesh = shadow_mesh
		_runner_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_runner_shadow)

	if _movement_dust == null and ResourceLoader.exists("res://scripts/vfx/dust_vfx.gd"):
		var dust := GPUParticles3D.new()
		dust.name = "MovementDust"
		dust.set_script(load("res://scripts/vfx/dust_vfx.gd"))
		add_child(dust)
		_movement_dust = dust
		call_deferred("_tune_runner_dust")

	if GameManager.is_cyberprank_theme() and _cyber_trail == null:
		_cyber_trail = _create_cyber_trail_fx()
		player_model.add_child(_cyber_trail)


func _tune_runner_dust() -> void:
	if _movement_dust == null or not is_instance_valid(_movement_dust):
		return
	var process := _movement_dust.process_material as ParticleProcessMaterial
	if process == null:
		return
	if GameManager.is_cyberprank_theme():
		process.color = Color(0.18, 0.92, 1.0, 0.28)
		if process.color_ramp:
			process.color_ramp.gradient = _make_runner_gradient_texture(Color(0.88, 0.26, 1.0, 0.55), Color(0.12, 0.90, 1.0, 0.0)).gradient
	else:
		process.color = Color(0.65, 0.55, 0.40, 0.35)


func _create_cyber_trail_fx() -> GPUParticles3D:
	var trail := GPUParticles3D.new()
	trail.name = "CyberTrail"
	trail.amount = 10
	trail.lifetime = 0.34
	trail.one_shot = false
	trail.explosiveness = 0.0
	trail.randomness = 0.24
	trail.fixed_fps = 30
	trail.position = Vector3(0.0, 0.48, 0.42)
	trail.emitting = false

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.04, 1.0)
	process.spread = 16.0
	process.initial_velocity_min = 0.35
	process.initial_velocity_max = 0.95
	process.gravity = Vector3(0.0, 0.0, 0.0)
	process.damping_min = 3.0
	process.damping_max = 4.5
	process.scale_min = 0.35
	process.scale_max = 0.72
	process.color = Color(0.16, 0.92, 1.0, 0.34)
	process.color_ramp = _make_runner_gradient_texture(Color(0.88, 0.24, 1.0, 0.55), Color(0.14, 0.92, 1.0, 0.0))
	trail.process_material = process

	var quad := QuadMesh.new()
	quad.size = Vector2(0.10, 0.24)
	var draw_material := StandardMaterial3D.new()
	draw_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_material.vertex_color_use_as_albedo = true
	draw_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_material.no_depth_test = false
	quad.material = draw_material
	trail.draw_pass_1 = quad

	return trail


func _make_runner_gradient_texture(start_color: Color, end_color: Color) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.set_color(0, start_color)
	gradient.add_point(0.45, Color(
		lerpf(start_color.r, end_color.r, 0.4),
		lerpf(start_color.g, end_color.g, 0.4),
		lerpf(start_color.b, end_color.b, 0.4),
		lerpf(start_color.a, end_color.a, 0.4)
	))
	gradient.set_color(gradient.get_point_count() - 1, end_color)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


func _update_runner_shadow() -> void:
	if _runner_shadow == null or not is_instance_valid(_runner_shadow):
		return
	var height_ratio: float = clampf(global_position.y / 2.4, 0.0, 1.0)
	_runner_shadow.position = Vector3(0.0, -global_position.y + 0.025, 0.12)
	var shadow_scale: float = lerpf(1.0, 0.62, height_ratio)
	_runner_shadow.scale = Vector3(shadow_scale, 1.0, shadow_scale)
	if _runner_shadow_material:
		var base_alpha: float = 0.34 if GameManager.is_cyberprank_theme() else 0.22
		_runner_shadow_material.albedo_color.a = lerpf(base_alpha, 0.07, height_ratio)


func _update_runner_fx() -> void:
	if _movement_dust and is_instance_valid(_movement_dust):
		_movement_dust.visible = current_state != PlayerState.DEAD

	if _cyber_trail and is_instance_valid(_cyber_trail):
		var should_emit: bool = GameManager.is_playing() and current_state in [PlayerState.RUNNING, PlayerState.JUMPING, PlayerState.SLIDING]
		_cyber_trail.emitting = should_emit
		_cyber_trail.speed_scale = lerpf(0.85, 1.4, GameManager.get_speed_ratio())
		_cyber_trail.visible = current_state != PlayerState.DEAD


func _spawn_landing_pulse() -> void:
	var pulse := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 0.18
	ring.bottom_radius = 0.22
	ring.height = 0.018
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.18, 0.92, 1.0, 0.42) if GameManager.is_cyberprank_theme() else Color(0.78, 0.64, 0.42, 0.30)
	material.emission_enabled = GameManager.is_cyberprank_theme()
	material.emission = Color(0.86, 0.26, 1.0, 1.0)
	material.emission_energy_multiplier = 1.4
	ring.material = material
	pulse.mesh = ring
	pulse.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pulse.position = Vector3(0.0, -global_position.y + 0.03, 0.04)
	add_child(pulse)

	var tween := create_tween()
	tween.tween_property(pulse, "scale", Vector3(4.4, 1.0, 4.4), 0.26).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(pulse, "position:y", pulse.position.y + 0.04, 0.26)
	tween.parallel().tween_property(pulse, "modulate:a", 0.0, 0.26)
	tween.tween_callback(pulse.queue_free)


func _build_runner_visual() -> Node3D:
	var player_profile: Dictionary = ThemeRegistryScript.get_profile().get("player", {})
	var scene_paths: Array[String] = [player_profile.get("base_scene_path", PLAYER_BASE_SCENE_PATH)]
	for fallback_path in _to_string_array(player_profile.get("fallback_scene_paths", [])):
		scene_paths.append(fallback_path)

	for scene_path in scene_paths:
		if not ResourceLoader.exists(scene_path):
			continue

		var base_scene := load(scene_path) as PackedScene
		if base_scene == null:
			continue

		var visual_root := base_scene.instantiate() as Node3D
		if visual_root == null:
			continue
		visual_root.name = "VisualRig"

		var extra_paths: Array[String] = _to_string_array(player_profile.get("extra_anim_scene_paths", PLAYER_EXTRA_ANIM_SCENE_PATHS))
		if scene_path == PLAYER_BASE_SCENE_PATH and extra_paths.is_empty():
			extra_paths = PLAYER_EXTRA_ANIM_SCENE_PATHS
		_merge_extra_animations(visual_root, extra_paths)

		if not _candidate_supports_gameplay_animation(visual_root):
			visual_root.queue_free()
			continue

		_apply_runner_palette(visual_root, player_profile.get("style", "nature_gradient"))
		return visual_root

	return null


func _merge_extra_animations(model: Node3D, extra_paths: Array = PLAYER_EXTRA_ANIM_SCENE_PATHS) -> void:
	var dest_player := _find_anim_player(model)
	if dest_player == null:
		return

	if not dest_player.has_animation_library(""):
		dest_player.add_animation_library("", AnimationLibrary.new())
	var dest_lib := dest_player.get_animation_library("")

	for path in extra_paths:
		if not ResourceLoader.exists(path):
			continue
		var anim_scene := load(path) as PackedScene
		if anim_scene == null:
			continue
		var anim_root := anim_scene.instantiate()
		var src_player := _find_anim_player(anim_root)
		if src_player:
			for lib_name in src_player.get_animation_library_list():
				var src_lib := src_player.get_animation_library(lib_name)
				if src_lib == null:
					continue
				for anim_name in src_lib.get_animation_list():
					if not dest_lib.has_animation(anim_name):
						dest_lib.add_animation(anim_name, src_lib.get_animation(anim_name))
		anim_root.queue_free()


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_anim_player(child)
		if result:
			return result
	return null


func _candidate_supports_gameplay_animation(node: Node3D) -> bool:
	var anim_player := _find_anim_player(node)
	if anim_player == null:
		return false
	if anim_player.get_animation_list().is_empty():
		return false

	return (
		_animation_list_has_any(anim_player, PLAYER_IDLE_ANIM_OPTIONS)
		and _animation_list_has_any(anim_player, PLAYER_RUN_ANIM_OPTIONS)
		and _animation_list_has_any(anim_player, PLAYER_JUMP_ANIM_OPTIONS)
	)


func _animation_list_has_any(anim_player: AnimationPlayer, anim_names: Array[String]) -> bool:
	for anim_name in anim_names:
		if anim_player.has_animation(anim_name):
			return true
	return false


func _to_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


func _find_node_recursive(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := _find_node_recursive(child, node_name)
		if found:
			return found
	return null


func _apply_runner_palette(node: Node, style: String = "nature_gradient") -> void:
	if style == "nature_passthrough":
		return
	var cyber_palette: Dictionary = {}
	if style == "cyber_mech":
		cyber_palette = _get_cyber_runner_palette()
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh:
			var mesh_name := mesh_instance.name.to_lower()
			for surface_idx in mesh_instance.mesh.get_surface_count():
				var active_material := mesh_instance.get_active_material(surface_idx)
				var tinted_material: StandardMaterial3D = null
				if active_material is StandardMaterial3D:
					tinted_material = (active_material as StandardMaterial3D).duplicate()
				else:
					tinted_material = StandardMaterial3D.new()

				match style:
					"cyber_mech":
						if mesh_name.contains("mannequin"):
							mesh_instance.set_surface_override_material(surface_idx, _create_cyber_gradient_material(tinted_material, cyber_palette))
							continue
						_apply_cyber_material_tint(tinted_material, mesh_name, cyber_palette)
					_:
						if mesh_name.contains("hair") or mesh_name.contains("eyebrow"):
							tinted_material.albedo_color = Color(0.22, 0.15, 0.10, 1.0)
							tinted_material.roughness = 0.95
						elif mesh_name.contains("eyes"):
							tinted_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
						elif mesh_name.contains("mannequin"):
							mesh_instance.set_surface_override_material(surface_idx, _create_nature_gradient_material(tinted_material))
							continue
						else:
							tinted_material.albedo_color = Color(0.86, 0.89, 0.82, 1.0)
							tinted_material.roughness = maxf(tinted_material.roughness, 0.9)

				mesh_instance.set_surface_override_material(surface_idx, tinted_material)
	for child in node.get_children():
		_apply_runner_palette(child, style)


func _apply_cyber_material_tint(material: StandardMaterial3D, mesh_name: String, cyber_palette: Dictionary = {}) -> void:
	var accent: Color = cyber_palette.get("accent", Color(0.72, 0.26, 1.0, 1.0))
	var glow: Color = cyber_palette.get("glow", Color(0.16, 0.96, 1.0, 1.0))
	var metal_light: Color = cyber_palette.get("metal_light", Color(0.82, 0.95, 1.0, 1.0))
	var metal_mid: Color = cyber_palette.get("metal_mid", Color(0.34, 0.54, 0.68, 1.0))
	var metal_dark: Color = cyber_palette.get("metal_dark", Color(0.08, 0.12, 0.18, 1.0))
	var has_albedo_texture: bool = material.albedo_texture != null

	material.roughness = minf(material.roughness if material.roughness > 0.0 else 0.42, 0.34)
	material.metallic = maxf(material.metallic, 0.62)

	if mesh_name.contains("eye") or mesh_name.contains("visor") or mesh_name.contains("glass"):
		material.albedo_color = accent.lightened(0.15)
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = 3.6
		return

	if mesh_name.contains("weapon") or mesh_name.contains("blade") or mesh_name.contains("gun"):
		material.albedo_color = accent.darkened(0.15)
		material.emission_enabled = true
		material.emission = glow
		material.emission_energy_multiplier = 0.95
		return

	if mesh_name.contains("joint") or mesh_name.contains("wheel") or mesh_name.contains("hinge") or mesh_name.contains("engine"):
		material.albedo_color = metal_dark.lightened(0.10)
		material.emission_enabled = true
		material.emission = glow.darkened(0.35)
		material.emission_energy_multiplier = 0.18
		return

	if has_albedo_texture:
		material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	else:
		var body_color := metal_light
		if mesh_name.contains("arm") or mesh_name.contains("leg") or mesh_name.contains("body") or mesh_name.contains("torso") or mesh_name.contains("shoulder") or mesh_name.contains("chest"):
			body_color = metal_mid.lerp(metal_light, 0.45)
		material.albedo_color = body_color

	material.emission_enabled = true
	material.emission = glow.lerp(accent, 0.25)
	material.emission_energy_multiplier = 0.34 if has_albedo_texture else 0.56


func _create_nature_gradient_material(source_material: StandardMaterial3D) -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 bottom_color : source_color = vec4(0.26, 0.33, 0.18, 1.0);
uniform vec4 mid_color : source_color = vec4(0.42, 0.56, 0.28, 1.0);
uniform vec4 top_color : source_color = vec4(0.74, 0.82, 0.52, 1.0);
uniform float gradient_height = 1.8;
uniform float roughness_value = 0.9;

void fragment() {
	float h = clamp((VERTEX.y + 0.35) / gradient_height, 0.0, 1.0);
	vec3 low_mid = mix(bottom_color.rgb, mid_color.rgb, smoothstep(0.0, 0.55, h));
	vec3 final_color = mix(low_mid, top_color.rgb, smoothstep(0.45, 1.0, h));
	ALBEDO = final_color;
	ROUGHNESS = roughness_value;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("roughness_value", maxf(source_material.roughness, 0.88))
	return material


func _create_cyber_gradient_material(source_material: StandardMaterial3D, cyber_palette: Dictionary = {}) -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 bottom_color : source_color = vec4(0.05, 0.10, 0.18, 1.0);
uniform vec4 mid_color : source_color = vec4(0.10, 0.55, 0.72, 1.0);
uniform vec4 top_color : source_color = vec4(0.78, 0.24, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.18, 0.94, 1.0, 1.0);
uniform float gradient_height = 1.8;
uniform float roughness_value = 0.24;
uniform float metallic_value = 0.65;
uniform float glow_energy = 1.7;

void fragment() {
	float h = clamp((VERTEX.y + 0.35) / gradient_height, 0.0, 1.0);
	vec3 low_mid = mix(bottom_color.rgb, mid_color.rgb, smoothstep(0.0, 0.55, h));
	vec3 final_color = mix(low_mid, top_color.rgb, smoothstep(0.45, 1.0, h));
	ALBEDO = final_color;
	ROUGHNESS = roughness_value;
	METALLIC = metallic_value;
	EMISSION = mix(mid_color.rgb, glow_color.rgb, smoothstep(0.35, 1.0, h)) * glow_energy;
}
"""

	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("bottom_color", cyber_palette.get("metal_dark", Color(0.05, 0.10, 0.18, 1.0)))
	material.set_shader_parameter("mid_color", cyber_palette.get("metal_mid", Color(0.10, 0.55, 0.72, 1.0)))
	material.set_shader_parameter("top_color", cyber_palette.get("accent", Color(0.78, 0.24, 1.0, 1.0)))
	material.set_shader_parameter("glow_color", cyber_palette.get("glow", Color(0.18, 0.94, 1.0, 1.0)))
	material.set_shader_parameter("roughness_value", minf(source_material.roughness, 0.28))
	return material


func _get_cyber_runner_palette() -> Dictionary:
	var player_profile: Dictionary = ThemeRegistryScript.get_profile().get("player", {})
	var accent: Color = player_profile.get("color", Color(0.72, 0.26, 1.0, 1.0))
	var glow: Color = accent.lerp(Color(0.12, 0.96, 1.0, 1.0), 0.58)
	return {
		"accent": accent,
		"glow": glow,
		"metal_light": Color(0.86, 0.94, 1.0, 1.0),
		"metal_mid": Color(0.20, 0.34, 0.46, 1.0).lerp(accent, 0.18),
		"metal_dark": Color(0.04, 0.08, 0.12, 1.0).lerp(accent, 0.06),
	}


func _get_player_visual_scale() -> float:
	var player_profile: Dictionary = ThemeRegistryScript.get_profile().get("player", {})
	return player_profile.get("visual_scale", PLAYER_VISUAL_SCALE)

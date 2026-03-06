extends CharacterBody3D
## Player Controller — Handles lane switching, jumping, sliding, and collision.
## The player stays at Z=0; the world moves toward them.

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

# --- Giant Rock / Double-Tap Blast ---
const DOUBLE_TAP_WINDOW: float = 0.6   # window for double-tap detection
const GIANT_ROCK_DETECT_RANGE: float = 45.0  # show hint at this distance
const GIANT_ROCK_BLAST_RANGE: float = 35.0   # can blast within this range
var _last_space_time: float = -1.0
var _nearby_giant_rock: Node = null

# --- River / Bridge ---
const RIVER_DETECT_RANGE: float = 40.0     # Start detecting river at this distance
const RIVER_BRIDGE_RANGE: float = 30.0     # Can build bridge within this range
const RIVER_NO_JUMP_RANGE: float = 20.0    # No jumping within this range of a river
const BRIDGE_HOLD_TIME: float = 0.4        # Seconds of holding spacebar to build
var _nearby_river: Node = null
var _space_hold_time: float = 0.0
var _bridge_built_for_river: Node = null    # Track which river we already built a bridge for
var _near_river_no_jump: bool = false       # True when within 20m of a river (suppress jump)

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


func _ready() -> void:
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
	hit_shape.position.y = STAND_HEIGHT / 2.0

	# Set initial lane position
	target_x = GameManager.LANE_POSITIONS[current_lane]
	position.x = target_x
	position.y = 0.0
	position.z = 0.0

	# Create visible player mesh if PlayerModel is empty
	_ensure_player_visible()

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

	# Sync model tilt for lane changes
	var lane_diff: float = target_x - position.x
	player_model.rotation.z = lerp(player_model.rotation.z, clampf(-lane_diff * 0.15, -0.2, 0.2), delta * 10.0)


# --- Input ---

func _input(event: InputEvent) -> void:
	if current_state == PlayerState.DEAD or not GameManager.is_playing():
		return

	# Touch input — detect swipe gestures and taps
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_active = true
		else:
			if _touch_active:
				var delta_v: Vector2 = event.position - _touch_start
				if delta_v.length() < SWIPE_MIN_DISTANCE:
					# Short tap — treat like spacebar for giant rock blast
					if GameManager.current_theme != "quiz":
						# Near river — no jump, spacebar reserved for bridge
						if not _near_river_no_jump:
							var blast_result := _try_giant_rock_blast()
							if blast_result == 1:
								pass  # Blast fired
							# Always jump on tap
							if is_grounded or not coyote_timer.is_stopped():
								_jump()
				else:
					_process_swipe(event.position)
				_touch_active = false


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
		# Vertical swipe — jump / slide (natural mode only, quiz uses answer buttons)
		if GameManager.current_theme != "quiz":
			if delta_v.y < 0:
				# Swipe up — jump
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

	# In Quiz mode, spacebar jump is disabled — use quiz_jump() from QuizManager
	if GameManager.current_theme != "quiz":
		if Input.is_action_just_pressed("jump"):
			# Near a river — spacebar is reserved for bridge building, no jump
			if _near_river_no_jump:
				return
			# Check for giant rock double-tap blast
			var blast_result := _try_giant_rock_blast()
			if blast_result == 1:
				pass  # Blast fired, jump already happened on first tap
			# Always jump regardless of blast state
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
	lane_changed.emit(current_lane)
	AudioManager.play_sfx(AudioManager.sfx_lane_swoosh, 0.15)


func _jump() -> void:
	if current_state == PlayerState.SLIDING:
		_end_slide()
	current_state = PlayerState.JUMPING
	vertical_velocity = JUMP_FORCE
	is_grounded = false
	coyote_timer.stop()
	AudioManager.play_sfx(AudioManager.sfx_jump)


## Called by QuizManager when player answers correctly — triggers jump
func quiz_jump() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.STUMBLE:
		return
	if is_grounded or not coyote_timer.is_stopped():
		_jump()


func _start_slide() -> void:
	if current_state == PlayerState.JUMPING:
		# Fast fall — slam down instantly when sliding mid-air
		vertical_velocity = -JUMP_FORCE * 1.5
		return

	current_state = PlayerState.SLIDING
	_slide_timer = SLIDE_DURATION
	AudioManager.play_sfx(AudioManager.sfx_slide, 0.1)

	# Shrink collision
	collision_shape.shape = _slide_shape
	collision_shape.position.y = SLIDE_HEIGHT / 2.0
	hit_shape.shape = _slide_shape.duplicate()
	hit_shape.position.y = SLIDE_HEIGHT / 2.0

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
	hit_shape.position.y = STAND_HEIGHT / 2.0

	# Reset model tilt
	player_model.rotation.x = 0.0

	ended_slide.emit()


func _on_land() -> void:
	if current_state == PlayerState.JUMPING:
		current_state = PlayerState.RUNNING
	vertical_velocity = 0.0
	landed.emit()
	AudioManager.play_sfx(AudioManager.sfx_landing, 0.1)

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
		var lane_idx: int = node.get_meta("lane_index", -1)
		if lane_idx == current_lane:
			# Check if this river has a bridge on our lane
			var river_parent: Node = node.get_parent()
			if river_parent and river_parent.has_meta("bridge_lane_%d" % lane_idx):
				return  # Bridge exists, safe to pass
		# No bridge — die
		hit_obstacle.emit()
		AudioManager.play_impact()
		GameManager.trigger_game_over()
		_die()
		return

	if node.is_in_group("obstacles") and not node.is_in_group("river_kill_zones"):
		hit_obstacle.emit()
		AudioManager.play_impact()
		GameManager.trigger_game_over()
		_die()


func _die() -> void:
	current_state = PlayerState.DEAD
	vertical_velocity = 0.0
	footstep_timer.stop()

	# Death stumble animation placeholder
	var tween: Tween = create_tween()
	tween.tween_property(player_model, "rotation:x", deg_to_rad(-90), 0.4).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(player_model, "position:y", 0.0, 0.4)


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
	## Spawn a glowing energy ball that flies from the player to the rock.
	var projectile := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.6, 1.0)
	mat.emission_energy_multiplier = 5.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material = mat
	projectile.mesh = sphere

	# Add a point light to the projectile for glow
	var light := OmniLight3D.new()
	light.light_color = Color(0.2, 0.7, 1.0)
	light.light_energy = 4.0
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
	tween.parallel().tween_property(projectile, "scale", Vector3(1.5, 1.5, 1.5), travel_time)

	# On hit: instantly destroy the rock
	tween.tween_callback(func():
		# Screen flash
		if light:
			light.light_energy = 10.0

		if is_instance_valid(target_rock):
			if target_rock.has_method("trigger_blast"):
				target_rock.trigger_blast()
			AudioManager.play_impact()

		# Fade and remove projectile
		var fade_tween := get_tree().create_tween()
		fade_tween.tween_property(projectile, "scale", Vector3(3.0, 3.0, 3.0), 0.2)
		fade_tween.parallel().tween_callback(func(): mat.albedo_color.a = 0.0)
		fade_tween.tween_callback(projectile.queue_free)
	)


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
	## Track spacebar hold to build bridge over river.
	if _nearby_river == null or not is_instance_valid(_nearby_river):
		_space_hold_time = 0.0
		return

	# Already built bridge for this river on this lane
	if _nearby_river.has_meta("bridge_lane_%d" % current_lane):
		return

	if Input.is_action_pressed("jump"):
		_space_hold_time += delta
		if _space_hold_time >= BRIDGE_HOLD_TIME:
			_build_bridge(_nearby_river)
			_space_hold_time = 0.0
	else:
		_space_hold_time = 0.0


func _build_bridge(river: Node) -> void:
	## Spawn a bridge on the player's current lane over the river.
	var lane_x: float = GameManager.LANE_POSITIONS[current_lane]

	# Find the world generator to get a bridge model
	var generator: Node = null
	var generators := get_tree().get_nodes_in_group("world_generator")
	if generators.size() > 0:
		generator = generators[0]

	# Mark this river as bridged (all lanes covered)
	for l in 3:
		river.set_meta("bridge_lane_%d" % l, true)
	_bridge_built_for_river = river

	# Remove ALL kill zones since bridge covers the full river
	for child in river.get_children():
		if child.is_in_group("river_kill_zones"):
			child.remove_from_group("obstacles")
			child.remove_from_group("river_kill_zones")
			for sub in child.get_children():
				if sub is CollisionShape3D:
					sub.set_deferred("disabled", true)

	# Spawn bridge model — covers the entire river
	var bridge_node := Node3D.new()
	bridge_node.name = "Bridge_Lane%d" % current_lane
	bridge_node.position = Vector3(lane_x, 0.15, 0.0)  # On the player's current lane

	var bridge_model: Node3D = null
	if generator and generator.has_method("get_random_bridge_scene"):
		var scene: PackedScene = generator.get_random_bridge_scene()
		if scene:
			bridge_model = scene.instantiate()

	if bridge_model:
		# Scale bridge to cover the full river
		bridge_model.scale = Vector3(3.0, 1.5, 2.5)
		bridge_model.rotation.y = PI * 0.5  # Rotate to span across the river
		bridge_node.add_child(bridge_model)
	else:
		# Fallback: procedural wood plank bridge
		var plank := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(10.0, 0.2, 5.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.35, 0.15)
		mat.roughness = 0.9
		box.material = mat
		plank.mesh = box
		bridge_node.add_child(plank)

	river.add_child(bridge_node)

	# Play a sound effect
	AudioManager.play_sfx(AudioManager.sfx_landing, 0.3)
	print("[Bridge] Built on lane %d for river at Z=%.1f" % [current_lane, river.global_position.z])


func _ensure_player_visible() -> void:
	# If PlayerModel already has children (e.g. GLB model dragged in), skip
	if player_model.get_child_count() > 0:
		return

	# APPROACH: Load the animation GLB directly as the character model.
	# Kenney animation GLBs contain the SAME mesh + skeleton + built-in AnimationPlayer.
	# This avoids all track-path mismatches from copying animations between GLBs.
	var primary_glb := "res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb"
	if ResourceLoader.exists(primary_glb):
		var scene: PackedScene = load(primary_glb)
		if scene:
			var model := scene.instantiate()
			player_model.add_child(model)
			model.rotation.y = PI
			model.scale = Vector3(0.55, 0.55, 0.55)
			print("=== Loaded character from animation GLB ===")
			_debug_print_tree(model, "  ")
			_merge_extra_animations(model)
			_apply_nature_tint(model)

			# Force-play Run
			var ap := _find_anim_player(model)
			if ap:
				print("=== AnimationPlayer found: %d anims ===" % ap.get_animation_list().size())
				print("    Animations: %s" % ", ".join(ap.get_animation_list()))
				if ap.has_animation("Running_A"):
					ap.play("Running_A")
					print("=== Force-playing 'Running_A' ===")
			return

	# Fallback: mannequin without animations
	var mannequin_path := "res://assets/Characters/RunnerMannequin/Mannequin_Medium.glb"
	if ResourceLoader.exists(mannequin_path):
		var scene: PackedScene = load(mannequin_path)
		if scene:
			var model := scene.instantiate()
			player_model.add_child(model)
			model.rotation.y = PI
			model.scale = Vector3(0.55, 0.55, 0.55)
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


func _merge_extra_animations(model: Node3D) -> void:
	# Merge additional animation packs into the model's existing AnimationPlayer
	var extra_glbs: Array[String] = [
		"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementAdvanced.glb",
		"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_General.glb",
		"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_CombatMelee.glb",
	]

	var dest_player := _find_anim_player(model)
	if not dest_player:
		return

	# Get or create default library on destination
	if not dest_player.has_animation_library(""):
		dest_player.add_animation_library("", AnimationLibrary.new())
	var dest_lib := dest_player.get_animation_library("")

	for path in extra_glbs:
		if not ResourceLoader.exists(path):
			continue
		var anim_scene: PackedScene = load(path)
		if not anim_scene:
			continue
		var anim_instance := anim_scene.instantiate()
		var src_player := _find_anim_player(anim_instance)
		if src_player:
			for lib_name in src_player.get_animation_library_list():
				var src_lib := src_player.get_animation_library(lib_name)
				if not src_lib:
					continue
				for anim_name in src_lib.get_animation_list():
					if not dest_lib.has_animation(anim_name):
						dest_lib.add_animation(anim_name, src_lib.get_animation(anim_name))
						print("    + Merged: %s" % anim_name)
		anim_instance.queue_free()


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var result := _find_anim_player(child)
		if result:
			return result
	return null


func _apply_nature_tint(node: Node) -> void:
	## Apply a green nature-themed color to the player character mesh
	var green_mat := StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.28, 0.62, 0.26)  # forest green
	green_mat.roughness = 0.7
	green_mat.metallic = 0.05
	_override_meshes(node, green_mat)


func _override_meshes(node: Node, mat: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_override_meshes(child, mat)


func _debug_print_tree(node: Node, indent: String = "") -> void:
	print("%s%s [%s]" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_debug_print_tree(child, indent + "  ")

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

	# Sync model tilt for lane changes
	var lane_diff: float = target_x - position.x
	player_model.rotation.z = lerp(player_model.rotation.z, clampf(-lane_diff * 0.15, -0.2, 0.2), delta * 10.0)


# --- Input ---

func _input(event: InputEvent) -> void:
	if current_state == PlayerState.DEAD or not GameManager.is_playing():
		return

	# Touch input — detect swipe gestures
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_touch_active = true
		else:
			if _touch_active:
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

	if node.is_in_group("obstacles"):
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

			# Force-play Run
			var ap := _find_anim_player(model)
			if ap:
				print("=== AnimationPlayer found: %d anims ===" % ap.get_animation_list().size())
				print("    Animations: %s" % ", ".join(ap.get_animation_list()))
				if ap.has_animation("Run"):
					ap.play("Run")
					print("=== Force-playing 'Run' ===")
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


func _debug_print_tree(node: Node, indent: String = "") -> void:
	print("%s%s [%s]" % [indent, node.name, node.get_class()])
	for child in node.get_children():
		_debug_print_tree(child, indent + "  ")

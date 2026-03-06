extends Node3D
## CameraRig — Smooth 3rd-person follow camera for the runner.
## Placed as a child of Player but set to top_level=true so it moves independently.

# --- Camera Offset ---
@export var offset: Vector3 = Vector3(0.0, 3.0, 5.5)
@export var look_ahead: Vector3 = Vector3(0.0, 1.0, -5.0)  # Point the camera looks at (relative to player)

# --- Smoothing ---
@export var follow_speed: float = 8.0
@export var look_speed: float = 10.0
@export var lane_tilt_amount: float = 2.0  # Degrees to tilt on lane change
@export var lane_tilt_speed: float = 6.0

# --- FOV ---
@export var base_fov: float = 65.0
@export var max_fov: float = 80.0
@export var fov_speed: float = 3.0

# --- Shake ---
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0
var _shake_offset: Vector3 = Vector3.ZERO

# --- References ---
var _camera: Camera3D
var _player: CharacterBody3D
var _target_position: Vector3
var _target_fov: float


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	_camera = $Camera3D as Camera3D

	if not _camera:
		push_error("CameraRig: No Camera3D child found!")
		return

	# Initialize position immediately (no lerp on first frame)
	if _player:
		var player_pos: Vector3 = _player.global_position
		global_position = player_pos + offset
		_target_position = global_position

	_target_fov = base_fov
	_camera.fov = base_fov

	# Connect game signals
	GameManager.game_over_triggered.connect(_on_game_over)
	if _player.has_signal("hit_obstacle"):
		_player.hit_obstacle.connect(_on_player_hit)


func _process(delta: float) -> void:
	if not _player or not _camera:
		return

	_update_follow(delta)
	_update_fov(delta)
	_update_shake(delta)
	_apply_camera_transform(delta)


func _update_follow(delta: float) -> void:
	var player_pos: Vector3 = _player.global_position

	# Target position: behind and above the player
	# X follows player lanes, Y/Z stay at offset
	_target_position = Vector3(
		player_pos.x * 0.6,   # Partially follow X (smoother lane tracking)
		player_pos.y + offset.y,
		player_pos.z + offset.z
	)

	# Smooth follow
	global_position = global_position.lerp(_target_position, follow_speed * delta)


func _update_fov(delta: float) -> void:
	# FOV increases with speed for a sense of acceleration
	var speed_ratio: float = GameManager.get_speed_ratio()
	_target_fov = lerpf(base_fov, max_fov, speed_ratio)
	_camera.fov = lerpf(_camera.fov, _target_fov, fov_speed * delta)


func _update_shake(delta: float) -> void:
	if _shake_intensity > 0.01:
		_shake_offset = Vector3(
			randf_range(-1, 1) * _shake_intensity,
			randf_range(-1, 1) * _shake_intensity,
			randf_range(-1, 1) * _shake_intensity * 0.3
		)
		_shake_intensity = lerpf(_shake_intensity, 0.0, _shake_decay * delta)
	else:
		_shake_offset = Vector3.ZERO
		_shake_intensity = 0.0


func _apply_camera_transform(delta: float) -> void:
	# Look at point ahead of player
	var look_target: Vector3 = _player.global_position + look_ahead

	# Apply shake offset to look target
	_camera.global_position = global_position + _shake_offset

	# Smooth look
	var current_basis: Basis = _camera.global_transform.basis
	_camera.look_at(look_target, Vector3.UP)
	var target_basis: Basis = _camera.global_transform.basis
	_camera.global_transform.basis = current_basis.slerp(target_basis, look_speed * delta)

	# Lane tilt — slight roll when player changes lanes
	var lane_offset: float = _player.position.x - _player.target_x
	var tilt_angle: float = deg_to_rad(lane_offset * lane_tilt_amount)
	_camera.rotation.z = lerpf(_camera.rotation.z, tilt_angle, lane_tilt_speed * delta)


# --- Public API ---

func shake(intensity: float = 0.3, decay: float = 5.0) -> void:
	_shake_intensity = intensity
	_shake_decay = decay


func set_offset(new_offset: Vector3, lerp_speed: float = 3.0) -> void:
	offset = new_offset


# --- Signal Callbacks ---

func _on_player_hit() -> void:
	shake(0.4, 4.0)


func _on_game_over() -> void:
	shake(0.5, 3.0)
	# Dramatic zoom on death
	var tween: Tween = create_tween()
	tween.tween_property(self, "offset", Vector3(0.0, 2.0, 3.5), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

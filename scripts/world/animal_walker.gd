extends Node3D
## AnimalWalker — Gives animals realistic procedural walking animation.
## Attached to animal instances by DecorationSpawner.

var walk_speed: float = 1.5
var walk_direction: Vector3 = Vector3.ZERO
var _base_y: float = 0.0
var _base_scale: Vector3 = Vector3.ONE
var _time: float = 0.0
var _step_phase: float = 0.0
var _turn_timer: float = 0.0
var _turn_interval: float = 4.0

# Walk cycle parameters
var step_frequency: float = 1.5        # Steps per second
var bob_height: float = 0.03           # Up/down bounce per step
var rock_amount: float = 0.03          # Side-to-side weight shift (radians)
var pitch_amount: float = 0.02         # Forward/back tilt per step (radians)
var squash_amount: float = 0.015       # Squash/stretch intensity
var forward_lean: float = 0.04         # Lean forward while moving (radians)

# Boundaries — don't wander onto the road or too far away
var x_min: float = 6.0
var x_max: float = 24.0
var z_range: float = 20.0
var _start_z: float = 0.0


func _ready() -> void:
	_base_y = position.y
	_base_scale = scale
	_start_z = position.z
	_time = randf() * TAU  # Random phase so animals don't sync
	_step_phase = randf() * TAU
	_turn_interval = randf_range(3.0, 7.0)
	# Slight per-animal variation in walk style
	step_frequency = randf_range(1.2, 1.8)
	rock_amount = randf_range(0.02, 0.04)
	pitch_amount = randf_range(0.015, 0.03)
	_pick_new_direction()


func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	_time += delta
	_turn_timer += delta

	# Periodic direction change
	if _turn_timer >= _turn_interval:
		_turn_timer = 0.0
		_turn_interval = randf_range(3.0, 7.0)
		_pick_new_direction()

	# Move in walk direction
	position += walk_direction * walk_speed * delta

	# --- Walk cycle animation ---
	var step_rate: float = step_frequency * TAU
	_step_phase += delta * step_rate

	# 1) Stepping bounce — two bounces per full cycle (left foot, right foot)
	#    abs(sin) gives a double-bounce per cycle, like real quadruped footfalls
	var bounce: float = absf(sin(_step_phase)) * bob_height
	position.y = _base_y + bounce

	# 2) Side-to-side weight shift — body rocks left/right each step
	rotation.z = sin(_step_phase) * rock_amount

	# 3) Forward/back pitch — body tilts forward on push-off, back on landing
	rotation.x = -forward_lean + sin(_step_phase * 2.0) * pitch_amount

	# 4) Squash and stretch — body compresses on landing, extends at peak
	var squash: float = sin(_step_phase * 2.0) * squash_amount
	scale.y = _base_scale.y * (1.0 - squash)
	scale.x = _base_scale.x * (1.0 + squash * 0.5)
	scale.z = _base_scale.z * (1.0 + squash * 0.5)

	# --- Boundary clamping ---
	var side_sign: float = signf(position.x) if position.x != 0.0 else 1.0
	var abs_x: float = absf(position.x)
	if abs_x < x_min:
		position.x = side_sign * x_min
		walk_direction.x = absf(walk_direction.x) * side_sign
	elif abs_x > x_max:
		position.x = side_sign * x_max
		walk_direction.x = -absf(walk_direction.x) * side_sign

	# Keep Z within chunk range
	if position.z > _start_z + z_range * 0.5:
		walk_direction.z = -absf(walk_direction.z)
	elif position.z < _start_z - z_range * 0.5:
		walk_direction.z = absf(walk_direction.z)

	# Face walk direction (smooth rotation)
	if walk_direction.length() > 0.01:
		var target_angle: float = atan2(walk_direction.x, walk_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 3.0)


func _pick_new_direction() -> void:
	var angle: float = randf_range(0, TAU)
	walk_direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()
	# Randomize speed slightly each turn
	walk_speed = randf_range(0.8, 2.0)

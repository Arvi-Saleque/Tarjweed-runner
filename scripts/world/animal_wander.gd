extends Node3D
## AnimalWander — Simple procedural walking animation for roadside animals.
## Attached at runtime by DecorationSpawner.

var _walk_speed: float
var _walk_dir: Vector3
var _bob_speed: float
var _bob_amount: float
var _time: float = 0.0
var _turn_timer: float = 0.0
var _turn_interval: float
var _base_y: float = 0.0
var _start_x: float = 0.0
var _max_wander: float = 5.0  # Don't wander too far from spawn

func _ready() -> void:
	_walk_speed = randf_range(0.3, 0.8)
	_bob_speed = randf_range(3.0, 5.0)
	_bob_amount = randf_range(0.02, 0.06)
	_turn_interval = randf_range(2.0, 5.0)
	_base_y = position.y
	_start_x = position.x
	_pick_new_direction()

func _pick_new_direction() -> void:
	var angle: float = randf_range(0, TAU)
	_walk_dir = Vector3(cos(angle), 0, sin(angle))
	rotation.y = angle

func _process(delta: float) -> void:
	_time += delta
	_turn_timer += delta

	# Walk slowly
	position += _walk_dir * _walk_speed * delta

	# Gentle body bob (simulates walking)
	position.y = _base_y + sin(_time * _bob_speed) * _bob_amount

	# If wandered too far from spawn X, turn back
	if absf(position.x - _start_x) > _max_wander:
		_walk_dir.x = -_walk_dir.x
		rotation.y = atan2(_walk_dir.x, _walk_dir.z)

	# Change direction periodically
	if _turn_timer >= _turn_interval:
		_turn_timer = 0.0
		_turn_interval = randf_range(2.0, 5.0)
		_pick_new_direction()

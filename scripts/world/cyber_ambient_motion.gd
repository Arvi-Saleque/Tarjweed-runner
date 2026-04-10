extends Node
## Lightweight helper that gives cyber scenic props a bit of life without
## affecting gameplay or physics. It animates the parent Node3D and can add a
## small pulsing accent light for signs, scanners, and overhead set dressing.

var _config: Dictionary = {}
var _target: Node3D = null
var _base_position: Vector3 = Vector3.ZERO
var _base_rotation: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _accent_light: OmniLight3D = null


func configure(config: Dictionary) -> void:
	_config = config.duplicate(true)
	if is_inside_tree():
		_capture_target()
		_setup_accent_light()


func _ready() -> void:
	_capture_target()
	_setup_accent_light()
	set_process(true)


func _capture_target() -> void:
	if _target != null:
		return
	_target = get_parent() as Node3D
	if _target == null:
		return
	_base_position = _target.position
	_base_rotation = _target.rotation
	_time = float(_config.get("phase", 0.0))


func _setup_accent_light() -> void:
	if _target == null:
		return
	var light_range: float = float(_config.get("light_range", 0.0))
	if light_range <= 0.0:
		return
	if _accent_light == null:
		_accent_light = OmniLight3D.new()
		_accent_light.name = "AccentLight"
		_accent_light.shadow_enabled = false
		add_child(_accent_light)

	_accent_light.position = _config.get("light_offset", Vector3.ZERO)
	_accent_light.omni_range = light_range
	_accent_light.light_color = _config.get("light_color", Color(0.12, 0.90, 1.0, 1.0))
	_accent_light.light_energy = float(_config.get("light_min", 0.0))


func _process(delta: float) -> void:
	if _target == null:
		return
	_time += delta

	var bob_height: float = float(_config.get("bob_height", 0.0))
	var bob_speed: float = float(_config.get("bob_speed", 1.0))
	var sway_angle: float = float(_config.get("sway_angle", 0.0))
	var sway_speed: float = float(_config.get("sway_speed", 1.0))
	var yaw_speed: float = float(_config.get("yaw_speed", 0.0))
	var roll_angle: float = float(_config.get("roll_angle", 0.0))

	_target.position = _base_position + Vector3(
		0.0,
		sin(_time * bob_speed) * bob_height,
		cos(_time * sway_speed * 0.5) * float(_config.get("z_sway", 0.0))
	)
	_target.rotation = Vector3(
		_base_rotation.x + sin(_time * sway_speed) * sway_angle,
		_base_rotation.y + (_time * yaw_speed),
		_base_rotation.z + sin(_time * (sway_speed * 0.8)) * roll_angle
	)

	if _accent_light:
		var light_min: float = float(_config.get("light_min", 0.0))
		var light_max: float = float(_config.get("light_max", light_min))
		var light_speed: float = float(_config.get("light_speed", 1.0))
		var pulse: float = 0.5 + sin(_time * light_speed) * 0.5
		_accent_light.light_energy = lerpf(light_min, light_max, pulse)

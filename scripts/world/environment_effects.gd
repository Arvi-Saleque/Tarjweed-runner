extends Node3D
## EnvironmentEffects — Dynamic environment adjustments based on gameplay speed.
## Smoothly ramps fog density and glow intensity as the player accelerates.

var _environment: Environment
var _base_fog_density: float = 0.003
var _max_fog_density: float = 0.007
var _base_glow_intensity: float = 0.4
var _max_glow_intensity: float = 0.7
var _target_fog: float = 0.003
var _target_glow: float = 0.4


func _ready() -> void:
	var world_env: WorldEnvironment = get_parent().get_node_or_null("WorldEnvironment")
	if world_env and world_env.environment:
		_environment = world_env.environment
		_base_fog_density = _environment.fog_density
		_base_glow_intensity = _environment.glow_intensity
		_target_fog = _base_fog_density
		_target_glow = _base_glow_intensity

	GameManager.speed_changed.connect(_on_speed_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


func _process(delta: float) -> void:
	if not _environment:
		return
	_environment.fog_density = lerpf(_environment.fog_density, _target_fog, delta * 2.0)
	_environment.glow_intensity = lerpf(_environment.glow_intensity, _target_glow, delta * 2.0)


func _on_speed_changed(_speed: float) -> void:
	var ratio: float = GameManager.get_speed_ratio()
	_target_fog = lerpf(_base_fog_density, _max_fog_density, ratio)
	_target_glow = lerpf(_base_glow_intensity, _max_glow_intensity, ratio)


func _on_game_started() -> void:
	_target_fog = _base_fog_density
	_target_glow = _base_glow_intensity
	if _environment:
		_environment.fog_density = _base_fog_density
		_environment.glow_intensity = _base_glow_intensity


func _on_game_over() -> void:
	_target_fog = _max_fog_density * 0.8
	_target_glow = _base_glow_intensity * 0.5

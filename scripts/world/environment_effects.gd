extends Node3D
## EnvironmentEffects — Dynamic environment adjustments based on gameplay speed.
## Smoothly ramps fog density and glow intensity as the player accelerates.

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

var _environment: Environment
var _sun_light: DirectionalLight3D
var _road_fill_light: OmniLight3D
var _rim_light: OmniLight3D
var _theme_id: String = "nature"
var _atmosphere: Dictionary = {}
var _base_fog_density: float = 0.003
var _max_fog_density: float = 0.007
var _base_glow_intensity: float = 0.4
var _max_glow_intensity: float = 0.7
var _target_fog: float = 0.003
var _target_glow: float = 0.4
var _light_pulse_time: float = 0.0


func _ready() -> void:
	var world_env: WorldEnvironment = get_parent().get_node_or_null("WorldEnvironment")
	_sun_light = get_parent().get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	_theme_id = GameManager.current_visual_theme
	_atmosphere = ThemeRegistryScript.get_profile(_theme_id).get("atmosphere", {})
	if world_env and world_env.environment:
		_environment = world_env.environment
		_apply_theme_environment()
		_target_fog = _base_fog_density
		_target_glow = _base_glow_intensity
		_create_theme_lights()

	GameManager.speed_changed.connect(_on_speed_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


func _process(delta: float) -> void:
	if not _environment:
		return
	_environment.fog_density = lerpf(_environment.fog_density, _target_fog, delta * 2.0)
	_environment.glow_intensity = lerpf(_environment.glow_intensity, _target_glow, delta * 2.0)
	_update_theme_lights(delta)


func _apply_theme_environment() -> void:
	if _environment == null:
		return

	var background_mode: String = _atmosphere.get("background_mode", "sky")
	if background_mode == "color":
		_environment.background_mode = Environment.BG_COLOR
		_environment.background_color = _atmosphere.get("background_color", Color(0.02, 0.03, 0.05, 1.0))
	else:
		_environment.background_mode = Environment.BG_SKY

	var ambient_source: String = _atmosphere.get("ambient_source", "sky")
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if ambient_source == "color" else Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_color = _atmosphere.get("ambient_color", _environment.ambient_light_color)
	_environment.ambient_light_energy = _atmosphere.get("ambient_energy", _environment.ambient_light_energy)
	_environment.tonemap_exposure = _atmosphere.get("exposure", _environment.tonemap_exposure)
	_environment.tonemap_white = _atmosphere.get("white", _environment.tonemap_white)
	_environment.glow_enabled = true
	_environment.glow_strength = _atmosphere.get("glow_strength", _environment.glow_strength)
	_environment.glow_bloom = _atmosphere.get("glow_bloom", _environment.glow_bloom)
	_environment.fog_enabled = true
	_environment.fog_light_color = _atmosphere.get("fog_color", _environment.fog_light_color)
	_environment.fog_light_energy = _atmosphere.get("fog_light_energy", _environment.fog_light_energy)
	_environment.fog_aerial_perspective = _atmosphere.get("fog_aerial", _environment.fog_aerial_perspective)
	_environment.fog_sky_affect = _atmosphere.get("fog_sky_affect", _environment.fog_sky_affect)
	_environment.adjustment_enabled = true
	_environment.adjustment_brightness = _atmosphere.get("adjustment_brightness", _environment.adjustment_brightness)
	_environment.adjustment_contrast = _atmosphere.get("adjustment_contrast", _environment.adjustment_contrast)
	_environment.adjustment_saturation = _atmosphere.get("adjustment_saturation", _environment.adjustment_saturation)

	_base_fog_density = _atmosphere.get("fog_density_base", _environment.fog_density)
	_max_fog_density = _atmosphere.get("fog_density_max", _base_fog_density)
	_base_glow_intensity = _atmosphere.get("glow_base", _environment.glow_intensity)
	_max_glow_intensity = _atmosphere.get("glow_max", _base_glow_intensity)
	_environment.fog_density = _base_fog_density
	_environment.glow_intensity = _base_glow_intensity

	if _sun_light:
		_sun_light.light_color = _atmosphere.get("sun_color", _sun_light.light_color)
		_sun_light.light_energy = _atmosphere.get("sun_energy", _sun_light.light_energy)
		_sun_light.light_indirect_energy = _atmosphere.get("sun_indirect_energy", _sun_light.light_indirect_energy)
		_sun_light.directional_shadow_max_distance = _atmosphere.get("shadow_max_distance", _sun_light.directional_shadow_max_distance)


func _create_theme_lights() -> void:
	if _theme_id != "cyberprank":
		return
	if _road_fill_light == null:
		_road_fill_light = OmniLight3D.new()
		_road_fill_light.name = "RoadFillLight"
		_road_fill_light.position = Vector3(0.0, 2.2, -0.6)
		_road_fill_light.omni_range = 10.5
		_road_fill_light.shadow_enabled = false
		add_child(_road_fill_light)
	if _rim_light == null:
		_rim_light = OmniLight3D.new()
		_rim_light.name = "RimLight"
		_rim_light.position = Vector3(0.0, 3.1, 3.8)
		_rim_light.omni_range = 8.0
		_rim_light.shadow_enabled = false
		add_child(_rim_light)

	_road_fill_light.light_color = _atmosphere.get("road_fill_color", Color(0.12, 0.90, 1.0, 1.0))
	_road_fill_light.light_energy = _atmosphere.get("road_fill_energy", 0.72)
	_rim_light.light_color = _atmosphere.get("rim_color", Color(0.92, 0.22, 1.0, 1.0))
	_rim_light.light_energy = _atmosphere.get("rim_energy", 0.34)


func _update_theme_lights(delta: float) -> void:
	if _theme_id != "cyberprank":
		return
	_light_pulse_time += delta
	var pulse: float = 0.92 + sin(_light_pulse_time * 2.1) * 0.08
	if _road_fill_light:
		var base_energy: float = _atmosphere.get("road_fill_energy", 0.72)
		_road_fill_light.light_energy = base_energy * pulse
	if _rim_light:
		var rim_energy: float = _atmosphere.get("rim_energy", 0.34)
		_rim_light.light_energy = rim_energy * (0.95 + sin(_light_pulse_time * 1.6 + 0.8) * 0.05)


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
	_apply_theme_environment()
	_create_theme_lights()


func _on_game_over() -> void:
	_target_fog = _max_fog_density * 0.8
	_target_glow = _base_glow_intensity * 0.5

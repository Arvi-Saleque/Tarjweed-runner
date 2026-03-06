extends CanvasLayer
## SpeedLines — Screen-space streaking lines that intensify with speed.
## Add as a child node in the game scene with this script.

const MIN_SPEED_RATIO: float = 0.3  # Don't show below 30% speed
const MAX_ALPHA: float = 0.35

var _container: Control
var _lines: Array[TextureRect] = []
var _line_data: Array[Dictionary] = []  # {speed, y_pos, x_offset}
var _trace_texture: Texture2D
var _active: bool = false
var _current_alpha: float = 0.0

const LINE_COUNT: int = 12


func _ready() -> void:
	layer = 5
	_load_texture()
	_create_container()
	_spawn_lines()
	visible = false

	GameManager.game_started.connect(func(): _active = true; visible = true)
	GameManager.game_over_triggered.connect(_on_game_over)


func _process(delta: float) -> void:
	if not _active:
		return

	var ratio: float = GameManager.get_speed_ratio()

	# Fade in/out based on speed threshold
	var target_alpha: float = 0.0
	if ratio > MIN_SPEED_RATIO:
		target_alpha = remap(ratio, MIN_SPEED_RATIO, 1.0, 0.0, MAX_ALPHA)
	_current_alpha = lerpf(_current_alpha, target_alpha, delta * 4.0)

	if _current_alpha < 0.01:
		_container.visible = false
		return
	_container.visible = true

	# Animate each line
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	for i in range(LINE_COUNT):
		var line: TextureRect = _lines[i]
		var data: Dictionary = _line_data[i]

		# Move line from right to left
		data["x_offset"] -= data["speed"] * delta * (1.0 + ratio * 2.0)

		# Reset when off-screen
		if data["x_offset"] < -line.size.x:
			data["x_offset"] = viewport_size.x + randf_range(0, 200)
			data["y_pos"] = randf_range(50, viewport_size.y - 50)
			data["speed"] = randf_range(800, 2000)

		line.position = Vector2(data["x_offset"], data["y_pos"])
		line.modulate.a = _current_alpha * randf_range(0.5, 1.0)

		# Scale length with speed
		var stretch: float = remap(ratio, 0.3, 1.0, 0.5, 1.0)
		line.scale.x = stretch


func _load_texture() -> void:
	# Use trace textures (elongated streaks)
	if ResourceLoader.exists("res://assets/vfx/kenney_particle_pack/trace_01.png"):
		_trace_texture = load("res://assets/vfx/kenney_particle_pack/trace_01.png")


func _create_container() -> void:
	_container = Control.new()
	_container.anchors_preset = Control.PRESET_FULL_RECT
	_container.anchor_right = 1.0
	_container.anchor_bottom = 1.0
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.visible = false
	add_child(_container)


func _spawn_lines() -> void:
	var viewport_size: Vector2 = Vector2(1920, 1080)  # Default, updated at runtime

	for i in range(LINE_COUNT):
		var line := TextureRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if _trace_texture:
			line.texture = _trace_texture
		else:
			# Fallback: white rectangle
			var img := Image.create(128, 4, false, Image.FORMAT_RGBA8)
			img.fill(Color.WHITE)
			line.texture = ImageTexture.create_from_image(img)

		line.stretch_mode = TextureRect.STRETCH_SCALE
		line.custom_minimum_size = Vector2(200, 3)
		line.size = Vector2(randf_range(150, 350), randf_range(2, 5))
		line.modulate = Color(1, 1, 1, 0)

		_container.add_child(line)
		_lines.append(line)

		_line_data.append({
			"speed": randf_range(800, 2000),
			"y_pos": randf_range(50, viewport_size.y - 50),
			"x_offset": randf_range(0, viewport_size.x),
		})
		line.position = Vector2(_line_data[i]["x_offset"], _line_data[i]["y_pos"])


func _on_game_over() -> void:
	_active = false
	# Fade out
	var tween := create_tween()
	tween.tween_property(_container, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): visible = false)

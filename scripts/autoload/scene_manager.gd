extends Node
## SceneManager - Handles scene transitions with a professional fade effect.
## Call SceneManager.change_scene("res://scenes/some_scene.tscn") from anywhere.

signal transition_started
signal transition_midpoint   # Emitted at the darkest point (old scene gone, new loading)
signal transition_finished

const FADE_DURATION: float = 0.3

var _overlay: ColorRect
var _tween: Tween
var _is_transitioning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay()


# --- Public API ---

func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_started.emit()

	# Fade OUT (to black)
	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during transition

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # Run even when tree is paused
	_tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_IN)
	await _tween.finished

	transition_midpoint.emit()

	# Actually switch scene
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneManager: Failed to change scene to %s: %s" % [scene_path, error_string(err)])
		_is_transitioning = false
		_overlay.visible = false
		return

	# Wait one frame for the new scene to initialize
	await get_tree().process_frame

	# Fade IN (from black)
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	await _tween.finished

	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	transition_finished.emit()


func change_scene_to_packed(scene: PackedScene) -> void:
	if _is_transitioning or not scene:
		return
	_is_transitioning = true
	transition_started.emit()

	_overlay.visible = true
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_IN)
	await _tween.finished

	transition_midpoint.emit()

	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_overlay, "color:a", 0.0, FADE_DURATION).set_ease(Tween.EASE_OUT)
	await _tween.finished

	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	transition_finished.emit()


func is_transitioning() -> bool:
	return _is_transitioning


# --- Private ---

func _create_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 100  # Always on top
	canvas.name = "TransitionLayer"
	add_child(canvas)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	canvas.add_child(_overlay)

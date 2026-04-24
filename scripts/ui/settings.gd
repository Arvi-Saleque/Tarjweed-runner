extends Control
## Settings - Audio settings popup with control rebinding.

const ControlsManager = preload("res://scripts/input/controls_manager.gd")
const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")
const SETTINGS_SKIN := UISkinIds.NATURE
const SETTINGS_FRAME_PATH := "res://assets/UI/mainmenu/settings.png"
const SETTINGS_FRAME_SIZE := Vector2(1120.0, 1348.0)

var _overlay: ColorRect
var _panel: Control
var _music_toggle: Button
var _sfx_toggle: Button
var _music_slider: HSlider
var _sfx_slider: HSlider
var _close_btn: Button
var _binding_buttons: Dictionary = {}
var _listening_action: String = ""
var _listening_hint: Label

var _music_enabled: bool = true
var _sfx_enabled: bool = true


func _ready() -> void:
	ControlsManager.ensure_controls_ready()
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_enabled = SaveManager.get_setting("music_enabled", true)
	_sfx_enabled = SaveManager.get_setting("sfx_enabled", true)

	_create_popup()
	_animate_in()


func _create_popup() -> void:
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = UITheme.get_color("overlay", SETTINGS_SKIN)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_overlay.add_child(center)

	var target_size := _get_frame_target_size()
	_panel = Control.new()
	_panel.custom_minimum_size = target_size
	center.add_child(_panel)

	var frame := TextureRect.new()
	frame.anchors_preset = Control.PRESET_FULL_RECT
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.texture = load(SETTINGS_FRAME_PATH) as Texture2D
	_panel.add_child(frame)

	var title := UITheme.make_label("Settings", int(clampf(target_size.y * 0.043, UITheme.FONT_HEADING + 4, UITheme.FONT_TITLE + 4)), UITheme.get_color("text_ink", SETTINGS_SKIN), SETTINGS_SKIN)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(title, Rect2(0.34, 0.037, 0.32, 0.09))
	_panel.add_child(title)

	_close_btn = _make_image_slot_button("", UITheme.FONT_SMALL, false, true)
	_close_btn.tooltip_text = "Close"
	_close_btn.pressed.connect(_on_close_pressed)
	_place_control(_close_btn, Rect2(0.858, 0.012, 0.116, 0.103))
	_panel.add_child(_close_btn)

	_create_audio_row(_panel, "MUSIC",
		UITheme.icon_music_on if _music_enabled else UITheme.icon_music_off,
		_music_enabled,
		SaveManager.get_setting("music_volume", 0.8),
		func(toggled: bool): _on_music_toggled(toggled),
		func(val: float): _on_music_volume_changed(val)
	)

	_create_audio_row(_panel, "SOUND FX",
		UITheme.icon_audio_on if _sfx_enabled else UITheme.icon_audio_off,
		_sfx_enabled,
		SaveManager.get_setting("sfx_volume", 0.8),
		func(toggled: bool): _on_sfx_toggled(toggled),
		func(val: float): _on_sfx_volume_changed(val)
	)

	_create_controls_section(_panel)


func _get_frame_target_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var frame_ratio := SETTINGS_FRAME_SIZE.y / SETTINGS_FRAME_SIZE.x
	var target_height := minf(viewport_size.y * 0.92, 980.0)
	var target_width := target_height / frame_ratio
	if target_width > viewport_size.x * 0.78:
		target_width = viewport_size.x * 0.78
		target_height = target_width * frame_ratio
	return Vector2(target_width, target_height)


func _place_control(control: Control, rect: Rect2) -> void:
	var panel_size := _panel.custom_minimum_size
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = panel_size.x * rect.position.x
	control.offset_top = panel_size.y * rect.position.y
	control.offset_right = panel_size.x * (rect.position.x + rect.size.x)
	control.offset_bottom = panel_size.y * (rect.position.y + rect.size.y)


func _make_slot_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _make_image_slot_button(text: String, font_size: int, primary: bool = false, round_slot: bool = false) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var radius := 34 if round_slot else 24
	btn.add_theme_stylebox_override("normal", _make_slot_style(Color(1, 1, 1, 0.0), radius))
	btn.add_theme_stylebox_override("hover", _make_slot_style(Color(1, 1, 1, 0.16), radius))
	btn.add_theme_stylebox_override("pressed", _make_slot_style(Color(0.18, 0.10, 0.02, 0.14), radius))
	btn.add_theme_stylebox_override("focus", _make_slot_style(Color(0.97, 0.77, 0.26, 0.12), radius))
	var text_color := Color("FFF5DB") if primary else UITheme.get_color("text_ink", SETTINGS_SKIN)
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_color.lightened(0.08))
	btn.add_theme_color_override("font_pressed_color", text_color.darkened(0.08))
	btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	if not text.is_empty():
		var label := UITheme.make_label(text, max(font_size, UITheme.FONT_SMALL), text_color, SETTINGS_SKIN)
		label.name = "SlotLabel"
		label.anchors_preset = Control.PRESET_FULL_RECT
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(label)
	return btn


func _set_slot_button_text(button: Button, text: String) -> void:
	var label := button.get_node_or_null("SlotLabel") as Label
	if label:
		label.text = text
	else:
		button.text = text


func _create_audio_row(parent: Control, label_text: String, icon: Texture2D,
		enabled: bool, volume: float,
		toggle_callback: Callable, slider_callback: Callable) -> void:
	var is_music := label_text == "MUSIC"
	var row_y := 0.184 if is_music else 0.263

	var toggle := Button.new()
	toggle.icon = null
	toggle.toggle_mode = true
	toggle.button_pressed = enabled
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.add_theme_stylebox_override("normal", _make_slot_style(Color(1, 1, 1, 0.0), 12))
	toggle.add_theme_stylebox_override("hover", _make_slot_style(Color(1, 1, 1, 0.16), 12))
	toggle.add_theme_stylebox_override("pressed", _make_slot_style(Color("6DBE57", 0.22), 12))
	toggle.add_theme_stylebox_override("focus", _make_slot_style(Color(0.97, 0.77, 0.26, 0.12), 12))
	toggle.toggled.connect(toggle_callback)
	toggle.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_place_control(toggle, Rect2(0.129, row_y + 0.007, 0.074, 0.059))
	parent.add_child(toggle)

	var icon_rect := TextureRect.new()
	icon_rect.name = "ToggleIcon"
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.modulate = Color("FFF8E8")
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.anchors_preset = Control.PRESET_FULL_RECT
	icon_rect.anchor_right = 1.0
	icon_rect.anchor_bottom = 1.0
	icon_rect.offset_left = 12
	icon_rect.offset_right = -12
	icon_rect.offset_top = 21
	icon_rect.offset_bottom = -3
	toggle.add_child(icon_rect)

	var lbl := UITheme.make_label(label_text, UITheme.FONT_BODY, UITheme.get_color("text_ink", SETTINGS_SKIN), SETTINGS_SKIN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(lbl, Rect2(0.236, row_y + 0.012, 0.22, 0.040))
	parent.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = volume
	_style_slider(slider)
	slider.value_changed.connect(slider_callback)
	_place_control(slider, Rect2(0.236, row_y + 0.047, 0.43, 0.026))
	parent.add_child(slider)

	if is_music:
		_music_toggle = toggle
		_music_slider = slider
	else:
		_sfx_toggle = toggle
		_sfx_slider = slider


func _style_slider(slider: HSlider) -> void:
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = UITheme.get_color("primary", SETTINGS_SKIN)
	grabber.corner_radius_top_left = 10
	grabber.corner_radius_top_right = 10
	grabber.corner_radius_bottom_left = 10
	grabber.corner_radius_bottom_right = 10
	grabber.content_margin_left = 10.0
	grabber.content_margin_right = 10.0
	grabber.content_margin_top = 10.0
	grabber.content_margin_bottom = 10.0
	slider.add_theme_stylebox_override("grabber_area", grabber)

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.24, 0.18, 0.12, 0.34)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bg.content_margin_top = 4.0
	bg.content_margin_bottom = 4.0
	slider.add_theme_stylebox_override("slider", bg)


func _create_controls_section(parent: Control) -> void:
	var title := UITheme.make_label("CONTROLS", UITheme.FONT_BODY, UITheme.get_color("text_ink", SETTINGS_SKIN), SETTINGS_SKIN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(title, Rect2(0.388, 0.386, 0.22, 0.033))
	parent.add_child(title)

	_listening_hint = UITheme.make_label("", UITheme.FONT_SMALL - 2, UITheme.get_color("text_ink_soft", SETTINGS_SKIN), SETTINGS_SKIN)
	_listening_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_listening_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(_listening_hint, Rect2(0.248, 0.416, 0.50, 0.028))
	parent.add_child(_listening_hint)

	var row_index := 0
	for action_info in ControlsManager.get_actions():
		_create_binding_row(parent, action_info, row_index)
		row_index += 1

	var reset_btn := _make_image_slot_button("RESET CONTROLS", UITheme.FONT_BODY, true)
	reset_btn.pressed.connect(_on_reset_controls_pressed)
	_place_control(reset_btn, Rect2(0.281, 0.894, 0.438, 0.070))
	parent.add_child(reset_btn)


func _create_binding_row(parent: Control, action_info: Dictionary, row_index: int) -> void:
	var row_y := 0.405 + float(row_index) * 0.0656

	var label := UITheme.make_label(String(action_info.get("label", "")), UITheme.FONT_SMALL, UITheme.get_color("text_ink", SETTINGS_SKIN), SETTINGS_SKIN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(label, Rect2(0.219, row_y + 0.002, 0.36, 0.03))
	parent.add_child(label)

	var hint_text: String = String(action_info.get("hint", ""))
	var hint := UITheme.make_label(hint_text, UITheme.FONT_SMALL - 4, UITheme.get_color("text_ink_soft", SETTINGS_SKIN), SETTINGS_SKIN)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(hint, Rect2(0.219, row_y + 0.030, 0.36, 0.024))
	parent.add_child(hint)

	var action_name: String = String(action_info.get("action", ""))
	var button := _make_image_slot_button(ControlsManager.get_binding_display(action_name), UITheme.FONT_SMALL, false)
	button.pressed.connect(func(): _begin_rebind(action_name))
	_place_control(button, Rect2(0.686, row_y, 0.188, 0.056))
	parent.add_child(button)

	_binding_buttons[action_name] = button


func _begin_rebind(action: String) -> void:
	if _listening_action == action:
		_listening_action = ""
		_listening_hint.text = ""
		_refresh_binding_buttons()
		return

	_listening_action = action
	_listening_hint.text = "Press a key for %s..." % action.replace("_", " ").to_upper()
	_refresh_binding_buttons()
	AudioManager.play_ui_sound(AudioManager.ui_click)


func _refresh_binding_buttons() -> void:
	for action in _binding_buttons.keys():
		var button := _binding_buttons[action] as Button
		if button == null:
			continue
		if action == _listening_action:
			_set_slot_button_text(button, "PRESS KEY...")
		else:
			_set_slot_button_text(button, ControlsManager.get_binding_display(String(action)))


func _on_reset_controls_pressed() -> void:
	ControlsManager.reset_to_defaults()
	_listening_action = ""
	_listening_hint.text = "Controls reset to defaults."
	_refresh_binding_buttons()
	AudioManager.play_ui_sound(AudioManager.ui_click)


func _animate_in() -> void:
	_overlay.color.a = 0.0
	_panel.scale = Vector2(0.85, 0.85)
	_panel.modulate.a = 0.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_overlay, "color:a", 0.5, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.2)


func _animate_out() -> void:
	_listening_action = ""
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.15)
	tween.parallel().tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_overlay, "color:a", 0.0, 0.15)
	tween.tween_callback(queue_free)


func _on_close_pressed() -> void:
	SaveManager.save_now()
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_animate_out()


func _on_music_toggled(enabled: bool) -> void:
	_music_enabled = enabled
	AudioManager.set_music_enabled(enabled)
	if _music_toggle:
		_set_toggle_icon(_music_toggle, UITheme.icon_music_on if enabled else UITheme.icon_music_off)
	AudioManager.play_ui_sound(AudioManager.ui_click)


func _on_sfx_toggled(enabled: bool) -> void:
	_sfx_enabled = enabled
	AudioManager.set_sfx_enabled(enabled)
	if _sfx_toggle:
		_set_toggle_icon(_sfx_toggle, UITheme.icon_audio_on if enabled else UITheme.icon_audio_off)
	AudioManager.play_ui_sound(AudioManager.ui_click)


func _set_toggle_icon(button: Button, icon: Texture2D) -> void:
	var icon_rect := button.get_node_or_null("ToggleIcon") as TextureRect
	if icon_rect:
		icon_rect.texture = icon


func _on_music_volume_changed(val: float) -> void:
	AudioManager.set_music_volume(val)


func _on_sfx_volume_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val)


func _input(event: InputEvent) -> void:
	if _listening_action == "":
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var keycode: int = int(key_event.physical_keycode) if int(key_event.physical_keycode) != 0 else int(key_event.keycode)
		if keycode == 0:
			return
		ControlsManager.set_binding(_listening_action, keycode)
		_listening_hint.text = "%s bound to %s." % [
			_listening_action.replace("_", " ").to_upper(),
			ControlsManager.get_binding_display(_listening_action),
		]
		_listening_action = ""
		_refresh_binding_buttons()
		AudioManager.play_ui_sound(AudioManager.ui_click)
		get_viewport().set_input_as_handled()

extends Control
## Settings — Audio settings popup with toggle buttons and volume sliders.

var _overlay: ColorRect
var _panel: PanelContainer
var _music_toggle: Button
var _sfx_toggle: Button
var _music_slider: HSlider
var _sfx_slider: HSlider
var _close_btn: Button

var _music_enabled: bool = true
var _sfx_enabled: bool = true


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_enabled = SaveManager.get_setting("music_enabled", true)
	_sfx_enabled = SaveManager.get_setting("sfx_enabled", true)

	_create_popup()
	_animate_in()


func _create_popup() -> void:
	# Overlay
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0, 0, 0, 0.5)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Center
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_overlay.add_child(center)

	# Panel
	_panel = UITheme.make_panel()
	_panel.custom_minimum_size = Vector2(400, 0)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)

	# Header with title + close button
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := UITheme.make_label("SETTINGS", UITheme.FONT_HEADING, UITheme.COLOR_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(title)

	_close_btn = UITheme.make_icon_button(UITheme.icon_cross, "Close")
	_close_btn.custom_minimum_size = Vector2(44, 44)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Separator
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(1, 1, 1, 0.1)
	sep_style.content_margin_top = 1.0
	sep_style.content_margin_bottom = 4.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Music section
	_create_audio_row(vbox, "MUSIC",
		UITheme.icon_music_on if _music_enabled else UITheme.icon_music_off,
		_music_enabled,
		SaveManager.get_setting("music_volume", 0.8),
		func(toggled: bool): _on_music_toggled(toggled),
		func(val: float): _on_music_volume_changed(val)
	)

	# SFX section
	_create_audio_row(vbox, "SOUND FX",
		UITheme.icon_audio_on if _sfx_enabled else UITheme.icon_audio_off,
		_sfx_enabled,
		SaveManager.get_setting("sfx_volume", 0.8),
		func(toggled: bool): _on_sfx_toggled(toggled),
		func(val: float): _on_sfx_volume_changed(val)
	)


func _create_audio_row(parent: VBoxContainer, label_text: String, icon: Texture2D,
		enabled: bool, volume: float,
		toggle_callback: Callable, slider_callback: Callable) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	row.add_child(hbox)

	# Toggle button
	var toggle := Button.new()
	toggle.icon = icon
	toggle.expand_icon = true
	toggle.toggle_mode = true
	toggle.button_pressed = enabled
	toggle.custom_minimum_size = Vector2(48, 48)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.3, 0.3, 0.35)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	toggle.add_theme_stylebox_override("normal", normal)

	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = UITheme.COLOR_PRIMARY
	toggle.add_theme_stylebox_override("pressed", pressed_style)

	var hover_style := normal.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.4, 0.4, 0.45)
	toggle.add_theme_stylebox_override("hover", hover_style)

	toggle.toggled.connect(toggle_callback)
	hbox.add_child(toggle)

	# Label
	var lbl := UITheme.make_label(label_text, UITheme.FONT_BODY, UITheme.COLOR_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	# Slider
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = volume
	slider.custom_minimum_size = Vector2(180, 24)
	_style_slider(slider)
	slider.value_changed.connect(slider_callback)
	hbox.add_child(slider)

	# Store refs
	if label_text == "MUSIC":
		_music_toggle = toggle
		_music_slider = slider
	else:
		_sfx_toggle = toggle
		_sfx_slider = slider


func _style_slider(slider: HSlider) -> void:
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = UITheme.COLOR_PRIMARY
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
	bg.bg_color = Color(0.2, 0.2, 0.25)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	bg.content_margin_top = 4.0
	bg.content_margin_bottom = 4.0
	slider.add_theme_stylebox_override("slider", bg)


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
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.15)
	tween.parallel().tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_overlay, "color:a", 0.0, 0.15)
	tween.tween_callback(queue_free)


func _on_close_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_animate_out()


func _on_music_toggled(enabled: bool) -> void:
	_music_enabled = enabled
	AudioManager.set_music_enabled(enabled)
	if _music_toggle:
		_music_toggle.icon = UITheme.icon_music_on if enabled else UITheme.icon_music_off
	AudioManager.play_ui_sound(AudioManager.ui_click)


func _on_sfx_toggled(enabled: bool) -> void:
	_sfx_enabled = enabled
	AudioManager.set_sfx_enabled(enabled)
	if _sfx_toggle:
		_sfx_toggle.icon = UITheme.icon_audio_on if enabled else UITheme.icon_audio_off
	AudioManager.play_ui_sound(AudioManager.ui_click)


func _on_music_volume_changed(val: float) -> void:
	AudioManager.set_music_volume(val)


func _on_sfx_volume_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val)

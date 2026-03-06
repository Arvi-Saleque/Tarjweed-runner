extends CanvasLayer
## PauseMenu — Overlay shown when game is paused.
## Dim background, centered panel with Resume/Settings/Main Menu buttons.

var _overlay: ColorRect
var _panel: PanelContainer
var _resume_btn: Button
var _settings_btn: Button
var _menu_btn: Button
var _settings_popup: Control = null


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_create_overlay()
	_connect_signals()


func _create_overlay() -> void:
	# Dim background
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = UITheme.COLOR_OVERLAY
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks
	add_child(_overlay)

	# Center container
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_overlay.add_child(center)

	# Panel
	_panel = UITheme.make_panel()
	_panel.custom_minimum_size = Vector2(360, 0)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# Title
	var title := UITheme.make_label("PAUSED", UITheme.FONT_HEADING, UITheme.COLOR_TEXT)
	vbox.add_child(title)

	# Separator
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxFlat.new())
	var sep_style := sep.get_theme_stylebox("separator") as StyleBoxFlat
	if sep_style:
		sep_style.bg_color = Color(1, 1, 1, 0.1)
		sep_style.content_margin_top = 1.0
		sep_style.content_margin_bottom = 8.0
	vbox.add_child(sep)

	# Resume button
	_resume_btn = UITheme.make_button("  RESUME", UITheme.icon_play)
	_resume_btn.pressed.connect(_on_resume_pressed)
	_resume_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	vbox.add_child(_resume_btn)

	# Settings button
	_settings_btn = UITheme.make_button("  SETTINGS", UITheme.icon_gear)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_settings_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	vbox.add_child(_settings_btn)

	# Main menu button
	_menu_btn = UITheme.make_button("  MAIN MENU", UITheme.icon_home)
	_menu_btn.pressed.connect(_on_menu_pressed)
	_menu_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	vbox.add_child(_menu_btn)

	# Make the danger button red
	var menu_normal := _menu_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	menu_normal.bg_color = UITheme.COLOR_DANGER
	_menu_btn.add_theme_stylebox_override("normal", menu_normal)
	var menu_hover := _menu_btn.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	menu_hover.bg_color = UITheme.COLOR_DANGER.lightened(0.15)
	_menu_btn.add_theme_stylebox_override("hover", menu_hover)


func _connect_signals() -> void:
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()


func _on_game_paused() -> void:
	visible = true
	# Slide in animation
	_panel.scale = Vector2(0.8, 0.8)
	_panel.modulate.a = 0.0
	_overlay.color.a = 0.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_overlay, "color:a", UITheme.COLOR_OVERLAY.a, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.3)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.2)


func _on_game_resumed() -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.15)
	tween.parallel().tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.parallel().tween_property(_overlay, "color:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)


func _on_resume_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	GameManager.resume_game()


func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _settings_popup and is_instance_valid(_settings_popup):
		return
	var SettingsScript: GDScript = load("res://scripts/ui/settings.gd") as GDScript
	if SettingsScript:
		_settings_popup = Control.new()
		_settings_popup.set_script(SettingsScript)
		add_child(_settings_popup)


func _on_menu_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	GameManager.resume_game()  # Unpause tree first
	GameManager.go_to_menu()
	SceneManager.change_scene("res://scenes/main_menu.tscn")

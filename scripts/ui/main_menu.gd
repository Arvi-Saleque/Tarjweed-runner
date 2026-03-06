extends Control
## MainMenu — Professional main menu with animated entrance, background, and navigation.

var _title_label: Label
var _subtitle_label: Label
var _play_btn: Button
var _settings_btn: Button
var _high_score_label: Label
var _coins_label: Label
var _vbox: VBoxContainer
var _bg_gradient: ColorRect
var _settings_popup: Control = null


func _ready() -> void:
	# Full screen
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	_create_background()
	_create_layout()
	_animate_entrance()

	# Start menu music
	AudioManager.fade_in_music(2.0)


func _create_background() -> void:
	# Gradient background
	_bg_gradient = ColorRect.new()
	_bg_gradient.anchors_preset = Control.PRESET_FULL_RECT
	_bg_gradient.anchor_right = 1.0
	_bg_gradient.anchor_bottom = 1.0
	_bg_gradient.color = Color(0.06, 0.08, 0.12, 1.0)
	add_child(_bg_gradient)

	# Decorative top accent bar
	var accent := ColorRect.new()
	accent.anchors_preset = Control.PRESET_TOP_WIDE
	accent.anchor_right = 1.0
	accent.offset_bottom = 4.0
	accent.color = UITheme.COLOR_PRIMARY
	add_child(accent)

	# Subtle pattern overlay
	var pattern := ColorRect.new()
	pattern.anchors_preset = Control.PRESET_FULL_RECT
	pattern.anchor_right = 1.0
	pattern.anchor_bottom = 1.0
	pattern.color = Color(1, 1, 1, 0.02)
	pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pattern)


func _create_layout() -> void:
	# Center container
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	# Main VBox
	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 16)
	center.add_child(_vbox)

	# Spacer top
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 40)
	_vbox.add_child(spacer_top)

	# Title
	_title_label = UITheme.make_label("NATURE RUNNER", UITheme.FONT_TITLE, UITheme.COLOR_TEXT)
	_title_label.modulate.a = 0.0  # Start invisible for animation
	_vbox.add_child(_title_label)

	# Subtitle
	_subtitle_label = UITheme.make_label("Endless Runner", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	_subtitle_label.modulate.a = 0.0
	_vbox.add_child(_subtitle_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	_vbox.add_child(spacer)

	# Play button
	_play_btn = UITheme.make_button("  PLAY", UITheme.icon_play, UITheme.FONT_HEADING)
	_play_btn.custom_minimum_size = Vector2(320, 72)
	_play_btn.modulate.a = 0.0
	_play_btn.pressed.connect(_on_play_pressed)
	_play_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_play_btn)

	# Settings button
	_settings_btn = UITheme.make_button("  SETTINGS", UITheme.icon_gear)
	_settings_btn.modulate.a = 0.0
	_settings_btn.pressed.connect(_on_settings_pressed)
	_settings_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_settings_btn)

	# Quit button
	var quit_btn := UITheme.make_button("  QUIT", UITheme.icon_cross)
	quit_btn.modulate.a = 0.0
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(quit_btn)
	_vbox.set_meta("quit_btn", quit_btn)

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	_vbox.add_child(spacer2)

	# Stats panel
	var stats_panel := UITheme.make_panel()
	stats_panel.modulate.a = 0.0
	stats_panel.custom_minimum_size = Vector2(320, 0)
	_vbox.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)

	# High score
	var hs_val: int = SaveManager.get_high_score()
	_high_score_label = UITheme.make_label("BEST: %d" % hs_val, UITheme.FONT_BODY, UITheme.COLOR_ACCENT)
	stats_vbox.add_child(_high_score_label)

	# Total coins
	var coins_val: int = SaveManager.get_total_coins()
	_coins_label = UITheme.make_label("COINS: %d" % coins_val, UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	stats_vbox.add_child(_coins_label)

	# Version / footer
	var footer := UITheme.make_label("v0.5 — Phase 5", UITheme.FONT_SMALL - 4, UITheme.COLOR_TEXT_DIM)
	footer.modulate.a = 0.0
	_vbox.add_child(footer)

	# Store stats panel and footer refs for animation
	_vbox.set_meta("stats_panel", stats_panel)
	_vbox.set_meta("footer", footer)


func _animate_entrance() -> void:
	# Use separate tweens to avoid sequential chain issues in VBoxContainer
	# Only animate modulate (alpha) — position offsets fight with container layout
	var items: Array[Control] = [
		_title_label,
		_subtitle_label,
		_play_btn,
		_settings_btn,
		_vbox.get_meta("quit_btn"),
		_vbox.get_meta("stats_panel"),
		_vbox.get_meta("footer"),
	]
	var delays: Array[float] = [0.0, 0.2, 0.4, 0.55, 0.65, 0.75, 0.9]
	var targets: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.5]

	for i in items.size():
		var item: Control = items[i]
		var t := create_tween()
		t.set_ease(Tween.EASE_OUT)
		t.set_trans(Tween.TRANS_CUBIC)
		t.tween_property(item, "modulate:a", targets[i], 0.35).set_delay(delays[i])


func _on_play_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_play_btn.disabled = true
	_settings_btn.disabled = true
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	get_tree().quit()


func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _settings_popup and is_instance_valid(_settings_popup):
		return
	var SettingsScript: GDScript = load("res://scripts/ui/settings.gd") as GDScript
	if SettingsScript:
		_settings_popup = Control.new()
		_settings_popup.set_script(SettingsScript)
		add_child(_settings_popup)

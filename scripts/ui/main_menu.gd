extends Control
## MainMenu — Professional main menu with animated entrance, background, and navigation.

var _title_label: Control
var _subtitle_label: Label
var _play_btn: Button
var _settings_btn: Button
var _high_score_label: Label
var _coins_label: Label
var _vbox: VBoxContainer
var _hero_panel: PanelContainer
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
	_bg_gradient = ColorRect.new()
	_bg_gradient.anchors_preset = Control.PRESET_FULL_RECT
	_bg_gradient.anchor_right = 1.0
	_bg_gradient.anchor_bottom = 1.0
	_bg_gradient.color = Color(0.10, 0.12, 0.09, 1.0)
	add_child(_bg_gradient)

	var sun_glow := ColorRect.new()
	sun_glow.anchor_left = 0.5
	sun_glow.anchor_top = 0.0
	sun_glow.anchor_right = 0.5
	sun_glow.anchor_bottom = 0.0
	sun_glow.offset_left = -240.0
	sun_glow.offset_top = 40.0
	sun_glow.offset_right = 240.0
	sun_glow.offset_bottom = 300.0
	sun_glow.color = Color(0.84, 0.62, 0.24, 0.14)
	sun_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sun_glow)

	var horizon := ColorRect.new()
	horizon.anchors_preset = Control.PRESET_BOTTOM_WIDE
	horizon.anchor_top = 1.0
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.offset_top = -170.0
	horizon.color = Color(0.17, 0.20, 0.13, 0.92)
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	for i in 4:
		var tree_strip := ColorRect.new()
		tree_strip.anchor_left = 0.0
		tree_strip.anchor_top = 1.0
		tree_strip.anchor_right = 1.0
		tree_strip.anchor_bottom = 1.0
		tree_strip.offset_top = -float(150 + i * 18)
		tree_strip.offset_bottom = -float(125 + i * 18)
		tree_strip.color = Color(0.10 + i * 0.02, 0.12 + i * 0.02, 0.08 + i * 0.01, 0.55)
		tree_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tree_strip)


func _create_layout() -> void:
	# Center container
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_hero_panel = UITheme.make_panel("dark")
	_hero_panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(_hero_panel)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 16)
	_hero_panel.add_child(_vbox)

	# Spacer top
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 40)
	_vbox.add_child(spacer_top)

	_title_label = UITheme.make_banner("RUNNER REALMS", UITheme.FONT_BODY, UITheme.COLOR_TEXT_INK)
	_title_label.modulate.a = 0.0
	_vbox.add_child(_title_label)

	# Subtitle
	_subtitle_label = UITheme.make_label("Choose a mode, then launch into Nature or Cyberprank", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
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
	_settings_btn = UITheme.make_button("  SETTINGS", UITheme.icon_gear, UITheme.FONT_BODY, "secondary")
	_settings_btn.modulate.a = 0.0
	_settings_btn.pressed.connect(_on_settings_pressed)
	_settings_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_settings_btn)

	# Quit button
	var quit_btn := UITheme.make_button("  QUIT", UITheme.icon_cross, UITheme.FONT_BODY, "danger")
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
	var stats_panel := UITheme.make_panel("light")
	stats_panel.modulate.a = 0.0
	stats_panel.custom_minimum_size = Vector2(320, 0)
	_vbox.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)

	# High score
	var hs_val: int = SaveManager.get_high_score()
	_high_score_label = UITheme.make_label("BEST: %d" % hs_val, UITheme.FONT_BODY, UITheme.COLOR_TEXT_INK)
	stats_vbox.add_child(_high_score_label)

	# Total coins
	var coins_val: int = SaveManager.get_total_coins()
	_coins_label = UITheme.make_label("COINS: %d" % coins_val, UITheme.FONT_SMALL, UITheme.COLOR_TEXT_INK_SOFT)
	stats_vbox.add_child(_coins_label)

	# Version / footer
	var footer := UITheme.make_label("v0.5 — Phase 8", UITheme.FONT_SMALL - 4, UITheme.COLOR_TEXT_DIM)
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

	# Show theme selection screen
	var ThemeSelectScript: GDScript = load("res://scripts/ui/theme_select.gd") as GDScript
	if ThemeSelectScript:
		var theme_screen := Control.new()
		theme_screen.set_script(ThemeSelectScript)
		theme_screen.back_pressed.connect(_on_theme_back)
		add_child(theme_screen)


func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	get_tree().quit()


func _on_theme_back() -> void:
	_play_btn.disabled = false
	_settings_btn.disabled = false


func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _settings_popup and is_instance_valid(_settings_popup):
		return
	var SettingsScript: GDScript = load("res://scripts/ui/settings.gd") as GDScript
	if SettingsScript:
		_settings_popup = Control.new()
		_settings_popup.set_script(SettingsScript)
		add_child(_settings_popup)

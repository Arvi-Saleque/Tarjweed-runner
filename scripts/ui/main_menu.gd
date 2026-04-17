extends Control
## MainMenu - Entry flow into the active nature-first play path.

const MENU_SKIN := "nature"
const SKY_COLOR := Color(0.86, 0.92, 0.80, 1.0)
const SUN_GLOW_COLOR := Color(0.99, 0.94, 0.78, 0.26)
const FOLIAGE_COLOR := Color(0.37, 0.55, 0.26, 0.18)
const HORIZON_COLOR := Color(0.24, 0.30, 0.16, 0.94)
const PATH_GLOW_COLOR := Color(0.79, 0.68, 0.42, 0.22)

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
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	_create_background()
	_create_layout()
	_animate_entrance()

	AudioManager.fade_in_music(2.0)


func _create_background() -> void:
	_bg_gradient = ColorRect.new()
	_bg_gradient.anchors_preset = Control.PRESET_FULL_RECT
	_bg_gradient.anchor_right = 1.0
	_bg_gradient.anchor_bottom = 1.0
	_bg_gradient.color = SKY_COLOR
	add_child(_bg_gradient)

	var top_glow := ColorRect.new()
	top_glow.anchor_left = 0.5
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 0.5
	top_glow.anchor_bottom = 0.0
	top_glow.offset_left = -340.0
	top_glow.offset_top = 30.0
	top_glow.offset_right = 340.0
	top_glow.offset_bottom = 290.0
	top_glow.color = SUN_GLOW_COLOR
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_glow)

	var side_glow_left := ColorRect.new()
	side_glow_left.anchor_left = 0.0
	side_glow_left.anchor_top = 0.18
	side_glow_left.anchor_right = 0.0
	side_glow_left.anchor_bottom = 0.92
	side_glow_left.offset_right = 220.0
	side_glow_left.color = FOLIAGE_COLOR
	side_glow_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(side_glow_left)

	var side_glow_right := ColorRect.new()
	side_glow_right.anchor_left = 1.0
	side_glow_right.anchor_top = 0.12
	side_glow_right.anchor_right = 1.0
	side_glow_right.anchor_bottom = 0.88
	side_glow_right.offset_left = -260.0
	side_glow_right.color = FOLIAGE_COLOR.darkened(0.12)
	side_glow_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(side_glow_right)

	var horizon := ColorRect.new()
	horizon.anchors_preset = Control.PRESET_BOTTOM_WIDE
	horizon.anchor_top = 1.0
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.offset_top = -190.0
	horizon.color = HORIZON_COLOR
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	for i in 5:
		var skyline_band := ColorRect.new()
		skyline_band.anchor_left = 0.0
		skyline_band.anchor_top = 1.0
		skyline_band.anchor_right = 1.0
		skyline_band.anchor_bottom = 1.0
		skyline_band.offset_top = -float(188 + i * 20)
		skyline_band.offset_bottom = -float(166 + i * 20)
		skyline_band.color = Color(0.15 + i * 0.02, 0.22 + i * 0.02, 0.10 + i * 0.01, 0.52 - i * 0.06)
		skyline_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(skyline_band)

	for i in 7:
		var lane_strip := ColorRect.new()
		lane_strip.anchor_left = 0.08 + i * 0.12
		lane_strip.anchor_top = 1.0
		lane_strip.anchor_right = 0.10 + i * 0.12
		lane_strip.anchor_bottom = 1.0
		lane_strip.offset_top = -150.0
		lane_strip.offset_bottom = -120.0
		lane_strip.color = PATH_GLOW_COLOR if i % 2 == 0 else PATH_GLOW_COLOR * Color(1, 1, 1, 0.72)
		lane_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lane_strip)

	for i in 4:
		var mist_band := ColorRect.new()
		mist_band.anchor_left = 0.0
		mist_band.anchor_top = 0.18 + i * 0.14
		mist_band.anchor_right = 1.0
		mist_band.anchor_bottom = 0.18 + i * 0.14
		mist_band.offset_bottom = 28.0
		mist_band.color = Color(0.96, 0.94, 0.84, 0.04 if i % 2 == 0 else 0.02)
		mist_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mist_band)


func _create_layout() -> void:
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_hero_panel = UITheme.make_panel("dark", MENU_SKIN)
	_hero_panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(_hero_panel)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 20)
	_hero_panel.add_child(_vbox)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 52)
	_vbox.add_child(spacer_top)

	_title_label = UITheme.make_banner("Runner Realms", UITheme.FONT_TITLE, UITheme.get_color("text_ink", MENU_SKIN), MENU_SKIN)
	_title_label.custom_minimum_size = Vector2(500, 108)
	_title_label.modulate.a = 0.0
	_vbox.add_child(_title_label)

	_subtitle_label = UITheme.make_label(
		"Choose a mode, pick a runner, and start the journey",
		UITheme.FONT_BODY,
		UITheme.get_color("text_dim", MENU_SKIN),
		MENU_SKIN
	)
	_subtitle_label.modulate.a = 0.0
	_subtitle_label.custom_minimum_size = Vector2(420, 0)
	_vbox.add_child(_subtitle_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	_vbox.add_child(spacer)

	_play_btn = UITheme.make_button("  Play", UITheme.icon_play, UITheme.FONT_BODY, "primary", MENU_SKIN)
	_play_btn.custom_minimum_size = Vector2(320, 72)
	_play_btn.modulate.a = 0.0
	_play_btn.pressed.connect(_on_play_pressed)
	_play_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_play_btn)

	_settings_btn = UITheme.make_button("  Settings", UITheme.icon_gear, UITheme.FONT_BODY, "secondary", MENU_SKIN)
	_settings_btn.custom_minimum_size = Vector2(320, 72)
	_settings_btn.modulate.a = 0.0
	_settings_btn.pressed.connect(_on_settings_pressed)
	_settings_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_settings_btn)

	var quit_btn := UITheme.make_button("  Exit", UITheme.icon_cross, UITheme.FONT_BODY, "danger", MENU_SKIN)
	quit_btn.custom_minimum_size = Vector2(320, 72)
	quit_btn.modulate.a = 0.0
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(quit_btn)
	_vbox.set_meta("quit_btn", quit_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 18)
	_vbox.add_child(spacer2)

	var stats_panel := UITheme.make_panel("light", MENU_SKIN)
	stats_panel.modulate.a = 0.0
	stats_panel.custom_minimum_size = Vector2(320, 0)
	_vbox.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)

	var hs_val: int = SaveManager.get_high_score()
	_high_score_label = UITheme.make_label("Best Score: %d" % hs_val, UITheme.FONT_BODY, UITheme.get_color("text_ink", MENU_SKIN), MENU_SKIN)
	stats_vbox.add_child(_high_score_label)

	var coins_val: int = SaveManager.get_total_coins()
	_coins_label = UITheme.make_label("Coins: %d" % coins_val, UITheme.FONT_BODY, UITheme.get_color("accent", MENU_SKIN), MENU_SKIN)
	stats_vbox.add_child(_coins_label)

	var footer := UITheme.make_label("v0.5 - Nature Journey", UITheme.FONT_SMALL - 4, UITheme.get_color("text_dim", MENU_SKIN), MENU_SKIN)
	footer.modulate.a = 0.0
	_vbox.add_child(footer)

	_vbox.set_meta("stats_panel", stats_panel)
	_vbox.set_meta("footer", footer)


func _animate_entrance() -> void:
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

extends Control
## MainMenu - Entry flow into the active nature-first play path.

const MainMenuTokens = preload("res://scripts/ui/main_menu_tokens.gd")
const MainMenuCopy = preload("res://scripts/ui/main_menu_copy.gd")

var _title_label: Control
var _subtitle_label: Label
var _play_btn: Button
var _settings_btn: Button
var _high_score_label: Label
var _coins_label: Label
var _vbox: VBoxContainer
var _hero_panel: PanelContainer
var _hero_inner_panel: PanelContainer
var _bg_gradient: ColorRect
var _settings_popup: Control = null
var _name_popup: Control = null


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
	_bg_gradient.color = MainMenuTokens.SKY_COLOR
	add_child(_bg_gradient)

	var sky_glow := ColorRect.new()
	sky_glow.anchor_left = 0.0
	sky_glow.anchor_top = 0.0
	sky_glow.anchor_right = 1.0
	sky_glow.anchor_bottom = 0.55
	sky_glow.color = Color(0.98, 0.97, 0.86, 0.32)
	sky_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky_glow)

	var top_glow := ColorRect.new()
	top_glow.anchor_left = 0.5
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 0.5
	top_glow.anchor_bottom = 0.0
	top_glow.offset_left = -340.0
	top_glow.offset_top = 30.0
	top_glow.offset_right = 340.0
	top_glow.offset_bottom = 290.0
	top_glow.color = MainMenuTokens.SUN_GLOW_COLOR
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_glow)

	var horizon := ColorRect.new()
	horizon.anchors_preset = Control.PRESET_BOTTOM_WIDE
	horizon.anchor_top = 1.0
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.offset_top = -240.0
	horizon.color = MainMenuTokens.HORIZON_COLOR
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(horizon)

	for tree in [
		{"x": 0.08, "w": 110.0, "h": 300.0, "color": Color(0.46, 0.66, 0.35, 0.20)},
		{"x": 0.18, "w": 86.0, "h": 260.0, "color": Color(0.52, 0.71, 0.40, 0.18)},
		{"x": 0.74, "w": 98.0, "h": 290.0, "color": Color(0.44, 0.64, 0.33, 0.18)},
		{"x": 0.88, "w": 120.0, "h": 320.0, "color": Color(0.40, 0.58, 0.28, 0.22)},
	]:
		var trunk := ColorRect.new()
		trunk.anchor_left = tree["x"]
		trunk.anchor_top = 1.0
		trunk.anchor_right = tree["x"]
		trunk.anchor_bottom = 1.0
		trunk.offset_left = -8.0
		trunk.offset_top = -tree["h"]
		trunk.offset_right = 8.0
		trunk.offset_bottom = 0.0
		trunk.color = Color(0.47, 0.29, 0.13, 0.35)
		trunk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(trunk)

		var canopy := ColorRect.new()
		canopy.anchor_left = tree["x"]
		canopy.anchor_top = 1.0
		canopy.anchor_right = tree["x"]
		canopy.anchor_bottom = 1.0
		canopy.offset_left = -tree["w"] * 0.5
		canopy.offset_top = -tree["h"] - 12.0
		canopy.offset_right = tree["w"] * 0.5
		canopy.offset_bottom = -tree["h"] + 92.0
		canopy.color = tree["color"]
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(canopy)

	var grass_band := ColorRect.new()
	grass_band.anchors_preset = Control.PRESET_BOTTOM_WIDE
	grass_band.anchor_top = 1.0
	grass_band.anchor_right = 1.0
	grass_band.anchor_bottom = 1.0
	grass_band.offset_top = -126.0
	grass_band.color = Color(0.66, 0.84, 0.48, 0.92)
	grass_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grass_band)

	for i in 8:
		var tuft := ColorRect.new()
		tuft.anchor_left = 0.04 + i * 0.12
		tuft.anchor_top = 1.0
		tuft.anchor_right = 0.04 + i * 0.12
		tuft.anchor_bottom = 1.0
		tuft.offset_left = -12.0
		tuft.offset_top = -126.0 + float(i % 2) * 8.0
		tuft.offset_right = 14.0
		tuft.offset_bottom = -84.0
		tuft.color = Color(0.44, 0.72, 0.30, 0.65)
		tuft.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tuft)

	for i in 4:
		var mist_band := ColorRect.new()
		mist_band.anchor_left = 0.0
		mist_band.anchor_top = 0.22 + i * 0.15
		mist_band.anchor_right = 1.0
		mist_band.anchor_bottom = 0.22 + i * 0.15
		mist_band.offset_bottom = 32.0
		mist_band.color = Color(0.97, 0.95, 0.87, 0.06 if i % 2 == 0 else 0.03)
		mist_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mist_band)


func _create_layout() -> void:
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_hero_panel = UITheme.make_panel("dark", MainMenuTokens.MENU_SKIN)
	_hero_panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(_hero_panel)

	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 14)
	hero_margin.add_theme_constant_override("margin_right", 14)
	hero_margin.add_theme_constant_override("margin_top", 14)
	hero_margin.add_theme_constant_override("margin_bottom", 14)
	_hero_panel.add_child(hero_margin)

	_hero_inner_panel = UITheme.make_panel("light", MainMenuTokens.MENU_SKIN)
	hero_margin.add_child(_hero_inner_panel)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.add_theme_constant_override("separation", 18)
	_hero_inner_panel.add_child(_vbox)

	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 34)
	_vbox.add_child(spacer_top)

	_title_label = UITheme.make_banner(MainMenuCopy.TITLE, UITheme.FONT_TITLE, UITheme.get_color("text_ink", MainMenuTokens.MENU_SKIN), MainMenuTokens.MENU_SKIN)
	_title_label.custom_minimum_size = Vector2(500, 108)
	_title_label.modulate.a = 0.0
	_vbox.add_child(_title_label)

	_subtitle_label = UITheme.make_label(
		MainMenuCopy.SUBTITLE,
		UITheme.FONT_BODY,
		UITheme.get_color("text_dim", MainMenuTokens.MENU_SKIN),
		MainMenuTokens.MENU_SKIN
	)
	_subtitle_label.modulate.a = 0.0
	_subtitle_label.custom_minimum_size = Vector2(420, 0)
	_vbox.add_child(_subtitle_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_vbox.add_child(spacer)

	_play_btn = UITheme.make_button(MainMenuCopy.PLAY_LABEL, UITheme.icon_play, UITheme.FONT_BODY, "primary", MainMenuTokens.MENU_SKIN)
	_play_btn.custom_minimum_size = Vector2(320, 72)
	_play_btn.modulate.a = 0.0
	_play_btn.pressed.connect(_on_play_pressed)
	_play_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_play_btn)

	_settings_btn = UITheme.make_button(MainMenuCopy.SETTINGS_LABEL, UITheme.icon_gear, UITheme.FONT_BODY, "secondary", MainMenuTokens.MENU_SKIN)
	_settings_btn.custom_minimum_size = Vector2(320, 72)
	_settings_btn.modulate.a = 0.0
	_settings_btn.pressed.connect(_on_settings_pressed)
	_settings_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(_settings_btn)

	var quit_btn := UITheme.make_button(MainMenuCopy.EXIT_LABEL, UITheme.icon_cross, UITheme.FONT_BODY, "danger", MainMenuTokens.MENU_SKIN)
	quit_btn.custom_minimum_size = Vector2(320, 72)
	quit_btn.modulate.a = 0.0
	quit_btn.pressed.connect(_on_quit_pressed)
	quit_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_vbox.add_child(quit_btn)
	_vbox.set_meta("quit_btn", quit_btn)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	_vbox.add_child(spacer2)

	var stats_panel := UITheme.make_panel("light", MainMenuTokens.MENU_SKIN)
	stats_panel.modulate.a = 0.0
	stats_panel.custom_minimum_size = Vector2(340, 0)
	_vbox.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)

	var hs_val: int = SaveManager.get_high_score()
	_high_score_label = UITheme.make_label(MainMenuCopy.BEST_SCORE_LABEL % hs_val, UITheme.FONT_BODY, UITheme.get_color("text_ink", MainMenuTokens.MENU_SKIN), MainMenuTokens.MENU_SKIN)
	stats_vbox.add_child(_high_score_label)

	var coins_val: int = SaveManager.get_total_coins()
	_coins_label = UITheme.make_label(MainMenuCopy.COINS_LABEL % coins_val, UITheme.FONT_BODY, UITheme.get_color("accent", MainMenuTokens.MENU_SKIN), MainMenuTokens.MENU_SKIN)
	stats_vbox.add_child(_coins_label)

	var footer := UITheme.make_label(MainMenuCopy.FOOTER_LABEL, UITheme.FONT_SMALL - 4, UITheme.get_color("text_dim", MainMenuTokens.MENU_SKIN), MainMenuTokens.MENU_SKIN)
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
	if _name_popup and is_instance_valid(_name_popup):
		return
	var NamePopupScript: GDScript = load("res://scripts/ui/name_entry_popup.gd") as GDScript
	if NamePopupScript:
		_name_popup = Control.new()
		_name_popup.set_script(NamePopupScript)
		_name_popup.confirmed.connect(func(_player_name: String): _open_theme_select())
		_name_popup.cancelled.connect(_on_theme_back)
		add_child(_name_popup)


func _on_quit_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	get_tree().quit()


func _on_theme_back() -> void:
	_play_btn.disabled = false
	_settings_btn.disabled = false


func _open_theme_select() -> void:
	var ThemeSelectScript: GDScript = load("res://scripts/ui/theme_select.gd") as GDScript
	if ThemeSelectScript:
		var theme_screen := Control.new()
		theme_screen.set_script(ThemeSelectScript)
		theme_screen.back_pressed.connect(_on_theme_back)
		add_child(theme_screen)


func _on_settings_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _settings_popup and is_instance_valid(_settings_popup):
		return
	var SettingsScript: GDScript = load("res://scripts/ui/settings.gd") as GDScript
	if SettingsScript:
		_settings_popup = Control.new()
		_settings_popup.set_script(SettingsScript)
		add_child(_settings_popup)

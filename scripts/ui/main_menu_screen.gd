extends Control

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const ChooseRunnerScene = preload("res://scenes/ui/ChooseRunner.tscn")
const LeaderboardScene = preload("res://scenes/ui/Leaderboard.tscn")
const PlaySetupPopupScene = preload("res://scenes/ui/PlaySetupPopup.tscn")
const SettingsScript = preload("res://scripts/ui/settings.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

var _summary_preview: TextureRect
var _summary_runner: Label
var _summary_player: Label
var _summary_difficulty: Label
var _summary_region: Label
var _summary_wallet: Label
var _summary_best: Label
var _wallet_badge_value: Label
var _overlay_host: Control
var _settings_popup: Control
var _play_popup: Control
var _voice_loading_overlay: Control
var _start_in_progress: bool = false


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_build_layout()
	_refresh_summary()
	AudioManager.fade_in_music(2.0)


func _build_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var ui_scale := clampf(viewport_size.y / 900.0, 0.72, 1.0)
	var side_margin := int(clampf(120.0 * ui_scale, 52.0, 120.0))
	var top_margin := int(clampf(12.0 * ui_scale, 6.0, 12.0))
	var bottom_margin := int(clampf(34.0 * ui_scale, 14.0, 34.0))
	var heading_width := clampf(viewport_size.x * 0.58, 680.0, 900.0)
	var heading_height := heading_width * (724.0 / 2172.0)
	var title_height := int(clampf(heading_height, 140.0, 300.0))
	var root_spacing := int(clampf(4.0 * ui_scale, 2.0, 4.0))
	var available_panel_height := int(maxf(480.0, viewport_size.y - top_margin - bottom_margin - title_height - root_spacing * 20))
	var panel_bottom_gap := int(clampf(10.0 * ui_scale, 6.0, 10.0))
	available_panel_height -= panel_bottom_gap
	var panel_height := int(clampf(float(available_panel_height), 500.0, float(available_panel_height)))

	var root_margin := MarginContainer.new()
	root_margin.anchors_preset = Control.PRESET_FULL_RECT
	root_margin.anchor_right = 1.0
	root_margin.anchor_bottom = 1.0
	root_margin.add_theme_constant_override("margin_left", side_margin)
	root_margin.add_theme_constant_override("margin_right", side_margin)
	root_margin.add_theme_constant_override("margin_top", top_margin)
	root_margin.add_theme_constant_override("margin_bottom", bottom_margin)
	add_child(root_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", root_spacing)
	root_margin.add_child(root_vbox)

	var title_center := CenterContainer.new()
	title_center.custom_minimum_size = Vector2(0, title_height)
	root_vbox.add_child(title_center)

	var title_wrap := VBoxContainer.new()
	title_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	title_wrap.add_theme_constant_override("separation", int(clampf(8.0 * ui_scale, 4.0, 8.0)))
	title_center.add_child(title_wrap)

	var title_banner := _make_title_banner("Runner Realms", ui_scale, viewport_size.x)
	title_wrap.add_child(title_banner)

	var panels_row := HBoxContainer.new()
	panels_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panels_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panels_row.alignment = BoxContainer.ALIGNMENT_CENTER
	panels_row.add_theme_constant_override("separation", int(clampf(34.0 * ui_scale, 16.0, 34.0)))
	root_vbox.add_child(panels_row)

	var menu_panel := _build_menu_panel(ui_scale, panel_height)
	panels_row.add_child(menu_panel)

	var bottom_space := Control.new()
	bottom_space.custom_minimum_size = Vector2(0, panel_bottom_gap)
	root_vbox.add_child(bottom_space)

	_overlay_host = Control.new()
	_overlay_host.name = "OverlayHost"
	_overlay_host.anchors_preset = Control.PRESET_FULL_RECT
	_overlay_host.anchor_right = 1.0
	_overlay_host.anchor_bottom = 1.0
	_overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_host)

	_build_wallet_badge()


func _make_title_banner(text: String, ui_scale: float, viewport_width: float) -> Control:
	var banner := Control.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading_width := clampf(viewport_width * 0.58, 680.0, 900.0)
	var heading_height := heading_width * (724.0 / 2172.0)
	banner.custom_minimum_size = Vector2(heading_width, heading_height)

	var frame := TextureRect.new()
	frame.anchors_preset = Control.PRESET_FULL_RECT
	frame.anchor_right = 1.0
	frame.anchor_bottom = 1.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture = load("res://assets/UI/mainmenu/heading.png") as Texture2D
	banner.add_child(frame)

	return banner


func _build_summary_panel(ui_scale: float, panel_height: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(clampf(560.0 * ui_scale, 420.0, 560.0), panel_height)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_parchment_panel_style())

	var compact_ratio := clampf((620.0 - float(panel_height)) / 180.0, 0.0, 1.0)
	var compact_scale := lerpf(1.0, 0.72, compact_ratio)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(clampf(26.0 * ui_scale * compact_scale, 10.0, 26.0)))
	margin.add_theme_constant_override("margin_right", int(clampf(26.0 * ui_scale * compact_scale, 10.0, 26.0)))
	margin.add_theme_constant_override("margin_top", int(clampf(22.0 * ui_scale * compact_scale, 8.0, 22.0)))
	margin.add_theme_constant_override("margin_bottom", int(clampf(22.0 * ui_scale * compact_scale, 8.0, 22.0)))
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", int(clampf(10.0 * ui_scale * compact_scale, 3.0, 10.0)))
	margin.add_child(body)

	var title := UITheme.make_label("Adventure Summary", int(clampf((UITheme.FONT_HEADING + 4) * ui_scale * compact_scale, UITheme.FONT_SMALL, UITheme.FONT_HEADING + 4)), Color("234126"), NatureMenuStyle.SKIN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)

	var preview_frame := PanelContainer.new()
	var preview_h := clampf(float(panel_height) * (0.27 - compact_ratio * 0.08), 90.0, 230.0)
	preview_frame.custom_minimum_size = Vector2(0, preview_h)
	preview_frame.add_theme_stylebox_override("panel", _make_preview_frame_style())
	body.add_child(preview_frame)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", int(clampf(10.0 * ui_scale * compact_scale, 4.0, 10.0)))
	preview_margin.add_theme_constant_override("margin_right", int(clampf(10.0 * ui_scale * compact_scale, 4.0, 10.0)))
	preview_margin.add_theme_constant_override("margin_top", int(clampf(10.0 * ui_scale * compact_scale, 4.0, 10.0)))
	preview_margin.add_theme_constant_override("margin_bottom", int(clampf(10.0 * ui_scale * compact_scale, 4.0, 10.0)))
	preview_frame.add_child(preview_margin)

	_summary_preview = NatureMenuStyle.make_preview("", Vector2(clampf(470.0 * ui_scale * compact_scale, 210.0, 470.0), clampf(preview_h - 12.0, 78.0, 220.0)))
	_summary_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_margin.add_child(_summary_preview)

	var stat_font_size := int(clampf((UITheme.FONT_BODY + 1) * ui_scale * compact_scale, UITheme.FONT_SMALL - 2, UITheme.FONT_BODY + 1))
	_summary_runner = _build_stat_line(body, UITheme.icon_trophy, "Runner: -", stat_font_size)
	_summary_player = _build_stat_line(body, UITheme.icon_home, "Player: -", stat_font_size)
	_summary_difficulty = _build_stat_line(body, UITheme.icon_warning, "Difficulty: -", stat_font_size)
	_summary_region = _build_stat_line(body, UITheme.icon_star, "Region: Forest Trail", stat_font_size, false)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(spacer)

	return panel


func _build_menu_panel(ui_scale: float, panel_height: int) -> Control:
	var panel := Control.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var card_tex := load("res://assets/UI/mainmenu/main_menu_card.png") as Texture2D
	var card_ratio := 1.625
	if card_tex and card_tex.get_width() > 0:
		card_ratio = float(card_tex.get_height()) / float(card_tex.get_width())

	var target_width := clampf(740.0 * ui_scale, 580.0, 740.0)
	var target_height := target_width * card_ratio
	if target_height > panel_height:
		target_height = float(panel_height)
		target_width = target_height / card_ratio
	panel.custom_minimum_size = Vector2(target_width, target_height)

	var card_bg := TextureRect.new()
	card_bg.anchors_preset = Control.PRESET_FULL_RECT
	card_bg.anchor_right = 1.0
	card_bg.anchor_bottom = 1.0
	card_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_bg.texture = card_tex
	panel.add_child(card_bg)

	var title_wrap := CenterContainer.new()
	title_wrap.anchors_preset = Control.PRESET_FULL_RECT
	title_wrap.anchor_right = 1.0
	title_wrap.anchor_bottom = 1.0
	title_wrap.offset_top = target_height * 0.066
	title_wrap.offset_bottom = -target_height * 0.802
	title_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_wrap)

	var title := UITheme.make_label("Main Menu", int(clampf(target_height * 0.046, UITheme.FONT_HEADING + 2, UITheme.FONT_TITLE)), Color("1C4A1F"), NatureMenuStyle.SKIN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_wrap.add_child(title)

	var button_font_size := int(clampf(target_height * 0.034, UITheme.FONT_BODY + 1, UITheme.FONT_HEADING + 2))
	var slot_specs := [
		{"top": 0.222, "bottom": 0.325, "text": "Play", "icon": UITheme.icon_play, "variant": "primary", "callback": func(): _open_play_setup()},
		{"top": 0.359, "bottom": 0.462, "text": "Choose Runner", "icon": UITheme.icon_home, "variant": "secondary", "callback": func(): _open_choose_runner()},
		{"top": 0.492, "bottom": 0.594, "text": "Leaderboard", "icon": UITheme.icon_trophy, "variant": "secondary", "callback": func(): _open_leaderboard()},
		{"top": 0.624, "bottom": 0.727, "text": "Settings", "icon": UITheme.icon_gear, "variant": "secondary", "callback": func(): _open_settings()},
		{"top": 0.756, "bottom": 0.859, "text": "Exit", "icon": UITheme.icon_cross, "variant": "danger", "callback": func(): _exit_game()},
	]

	for spec in slot_specs:
		var btn_height := int(clampf(target_height * (float(spec["bottom"]) - float(spec["top"])), 78.0, 132.0))
		var btn := _make_menu_button(str(spec["text"]), spec["icon"] as Texture2D, str(spec["variant"]), btn_height, button_font_size, spec["callback"] as Callable)
		btn.anchor_left = 0.0
		btn.anchor_right = 1.0
		btn.anchor_top = 0.0
		btn.anchor_bottom = 0.0
		btn.offset_left = target_width * 0.182
		btn.offset_right = -target_width * 0.182
		btn.offset_top = target_height * float(spec["top"])
		btn.offset_bottom = target_height * float(spec["bottom"])
		panel.add_child(btn)

	return panel


func _make_menu_button(text: String, icon: Texture2D, variant: String, button_height: int, button_font_size: int, pressed_callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.icon = null
	btn.custom_minimum_size = Vector2(0, button_height)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	btn.add_theme_stylebox_override("normal", _make_menu_button_overlay_style(Color(1, 1, 1, 0.0), button_height))
	btn.add_theme_stylebox_override("hover", _make_menu_button_overlay_style(Color(1, 1, 1, 0.16), button_height))
	btn.add_theme_stylebox_override("pressed", _make_menu_button_overlay_style(Color(0.18, 0.10, 0.02, 0.16), button_height))
	btn.add_theme_stylebox_override("focus", _make_menu_button_overlay_style(Color("F7C542", 0.12), button_height))

	var text_color := Color("214E22")
	if variant == "primary" or variant == "danger":
		text_color = Color("FFF5DB")

	_add_menu_button_content(btn, text, icon, text_color, button_height, button_font_size)

	if pressed_callback.is_valid():
		btn.pressed.connect(pressed_callback)
	return btn


func _make_menu_button_overlay_style(color: Color, button_height: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var radius := int(clampf(float(button_height) * 0.26, 18.0, 28.0))
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _add_menu_button_content(btn: Button, text: String, icon: Texture2D, text_color: Color, button_height: int, button_font_size: int) -> void:
	var content := Control.new()
	content.anchors_preset = Control.PRESET_FULL_RECT
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(content)

	if icon:
		var icon_size := int(clampf(float(button_height) * 0.56, 32.0, 44.0))
		if text == "Play":
			icon_size = int(clampf(float(button_height) * 0.46, 28.0, 36.0))
		# x-center aligns icon to the circular decoration on the left
		var icon_cx := int(clampf(float(button_height) * 0.64, 38.0, 48.0))
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.modulate = text_color
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.anchor_left = 0.0
		icon_rect.anchor_right = 0.0
		icon_rect.anchor_top = 0.5
		icon_rect.anchor_bottom = 0.5
		icon_rect.offset_left = icon_cx - icon_size / 2
		icon_rect.offset_right = icon_cx + icon_size / 2
		icon_rect.offset_top = -icon_size / 2
		icon_rect.offset_bottom = icon_size / 2
		content.add_child(icon_rect)

	var label := UITheme.make_label(text, button_font_size, text_color, NatureMenuStyle.SKIN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.offset_left = 0
	label.offset_right = 0
	label.offset_top = 0
	label.offset_bottom = 0
	content.add_child(label)

	btn.mouse_entered.connect(func(): content.modulate = Color(1.12, 1.12, 1.12, 1.0))
	btn.mouse_exited.connect(func(): content.modulate = Color.WHITE)


func _exit_game() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	get_tree().quit()


func _build_stat_line(parent: VBoxContainer, icon: Texture2D, text: String, font_size: int = UITheme.FONT_BODY + 2, with_separator: bool = true) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var icon_rect := TextureRect.new()
	var icon_size := int(clampf(float(font_size) + 6.0, 16.0, 26.0))
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture = icon if icon else UITheme.icon_star
	icon_rect.modulate = Color("2F6B3B")
	row.add_child(icon_rect)

	var label := UITheme.make_label(text, font_size, Color("234126"), NatureMenuStyle.SKIN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	if with_separator:
		var separator := HSeparator.new()
		separator.add_theme_stylebox_override("separator", _make_line_style())
		parent.add_child(separator)
	return label


func _make_parchment_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("F8EFD8")
	style.border_color = Color("6C5B2B")
	style.border_width_left = 5
	style.border_width_top = 5
	style.border_width_right = 5
	style.border_width_bottom = 5
	style.corner_radius_top_left = 26
	style.corner_radius_top_right = 26
	style.corner_radius_bottom_left = 26
	style.corner_radius_bottom_right = 26
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	style.shadow_color = Color(0.21, 0.17, 0.08, 0.18)
	return style


func _make_preview_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("EFE5C8")
	style.border_color = Color("7A6734")
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	return style


func _make_saved_progress_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("F1E7CB")
	style.border_color = Color("7D6933")
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	return style


func _make_subtitle_pill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2F6B3B")
	style.border_color = Color("6DBE57")
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 21
	style.corner_radius_top_right = 21
	style.corner_radius_bottom_left = 21
	style.corner_radius_bottom_right = 21
	return style


func _make_line_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.39, 0.33, 0.20, 0.28)
	style.content_margin_left = 1
	style.content_margin_right = 1
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


func _build_wallet_badge() -> void:
	var wallet_badge := Control.new()
	wallet_badge.name = "WalletBadge"
	wallet_badge.anchor_left = 0.0
	wallet_badge.anchor_top = 0.0
	wallet_badge.anchor_right = 0.0
	wallet_badge.anchor_bottom = 0.0
	wallet_badge.offset_left = 24.0
	wallet_badge.offset_top = 20.0
	wallet_badge.offset_right = 294.0
	wallet_badge.offset_bottom = 92.0
	wallet_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_badge.z_index = 100
	add_child(wallet_badge)

	var card_bg := TextureRect.new()
	card_bg.anchors_preset = Control.PRESET_FULL_RECT
	card_bg.anchor_right = 1.0
	card_bg.anchor_bottom = 1.0
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_bg.texture = load("res://assets/UI/mainmenu/coin_card.png") as Texture2D
	wallet_badge.add_child(card_bg)

	var badge_margin := MarginContainer.new()
	badge_margin.anchors_preset = Control.PRESET_FULL_RECT
	badge_margin.anchor_right = 1.0
	badge_margin.anchor_bottom = 1.0
	badge_margin.add_theme_constant_override("margin_left", 20)
	badge_margin.add_theme_constant_override("margin_top", 9)
	badge_margin.add_theme_constant_override("margin_right", 20)
	badge_margin.add_theme_constant_override("margin_bottom", 9)
	badge_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_badge.add_child(badge_margin)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 12)
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_margin.add_child(badge_row)

	var badge_icon := TextureRect.new()
	badge_icon.texture = UITheme.icon_coin if UITheme.icon_coin else UITheme.icon_trophy
	badge_icon.custom_minimum_size = Vector2(27, 27)
	badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge_icon)

	_wallet_badge_value = UITheme.make_label("Wallet: 0", UITheme.FONT_BODY, Color("33280E"), NatureMenuStyle.SKIN)
	_wallet_badge_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	badge_row.add_child(_wallet_badge_value)


func _refresh_summary() -> void:
	var runner_id: String = str(GameManager.current_player_variant)
	if runner_id.is_empty() or runner_id == "nature_default":
		runner_id = "elf"
	var runner: Dictionary = ThemeRegistryScript.get_player_profile("nature", runner_id)
	var preview_path: String = str(runner.get("preview_image_path", ""))
	if _summary_preview:
		_summary_preview.texture = load(preview_path) as Texture2D if ResourceLoader.exists(preview_path) else null
	if _summary_runner:
		_summary_runner.text = "Runner: %s" % runner.get("title", "Runner")
	if _summary_player:
		_summary_player.text = "Player: %s" % (GameManager.current_player_name if not GameManager.current_player_name.is_empty() else SaveManager.get_player_name())
	if _summary_difficulty:
		_summary_difficulty.text = "Difficulty: %s" % GameManager.current_difficulty_id.capitalize()
	if _summary_region:
		_summary_region.text = "Region: Forest Trail"
	var wallet_coins: int = SaveManager.get_wallet_coins()
	if _wallet_badge_value:
		_wallet_badge_value.text = "Wallet: %d" % wallet_coins


func _open_play_setup() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _play_popup and is_instance_valid(_play_popup):
		return
	_play_popup = PlaySetupPopupScene.instantiate()
	_play_popup.closed.connect(_on_overlay_closed)
	_play_popup.choose_runner_requested.connect(func():
		if _play_popup and is_instance_valid(_play_popup):
			_open_choose_runner()
	)
	_play_popup.start_requested.connect(_start_game_from_setup)
	_overlay_host.add_child(_play_popup)


func _open_choose_runner() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	var screen := ChooseRunnerScene.instantiate()
	screen.back_pressed.connect(func():
		screen.queue_free()
		_refresh_summary()
		if _play_popup and is_instance_valid(_play_popup) and _play_popup.has_method("refresh_selected_runner"):
			_play_popup.call("refresh_selected_runner")
	)
	screen.runner_changed.connect(func(_runner_id: String):
		_refresh_summary()
		if _play_popup and is_instance_valid(_play_popup):
			if _play_popup.has_method("refresh_selected_runner"):
				_play_popup.call("refresh_selected_runner")
			elif _play_popup.has_method("refresh_summary"):
				_play_popup.call("refresh_summary")
	)
	_overlay_host.add_child(screen)


func _open_leaderboard() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	var screen := LeaderboardScene.instantiate()
	screen.back_pressed.connect(func(): screen.queue_free())
	_overlay_host.add_child(screen)


func _open_settings() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _settings_popup and is_instance_valid(_settings_popup):
		return
	_settings_popup = Control.new()
	_settings_popup.set_script(SettingsScript)
	_overlay_host.add_child(_settings_popup)


func _start_game_from_setup(player_name: String, difficulty_id: String, mode_id: String, quiz_style_id: String) -> void:
	if _start_in_progress:
		return
	_start_in_progress = true
	GameManager.current_mode = mode_id
	GameManager.current_quiz_style = quiz_style_id
	GameManager.current_visual_theme = "nature"
	GameManager.apply_menu_setup(player_name, difficulty_id, GameManager.current_player_variant)
	_refresh_summary()
	if _play_popup and is_instance_valid(_play_popup):
		_play_popup.queue_free()
		_play_popup = null
	if mode_id == "pronunciation":
		_show_voice_loading_overlay()
		var reached := await PronunciationManager.warmup_backend_before_gameplay(1.5)
		_hide_voice_loading_overlay()
		if not reached:
			if OS.get_name() == "Android":
				_start_in_progress = false
				_show_server_error_popup()
				return
		PronunciationManager.startup_warning_message = ""
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_overlay_closed() -> void:
	_play_popup = null
	_refresh_summary()


func _show_server_error_popup() -> void:
	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 300
	add_child(overlay)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("2A1F14")
	card_style.corner_radius_top_left = 20
	card_style.corner_radius_top_right = 20
	card_style.corner_radius_bottom_left = 20
	card_style.corner_radius_bottom_right = 20
	card_style.content_margin_left = 32.0
	card_style.content_margin_right = 32.0
	card_style.content_margin_top = 28.0
	card_style.content_margin_bottom = 28.0
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	var title := UITheme.make_label("Cannot Reach Server", UITheme.FONT_HEADING, Color("FF8A80"), NatureMenuStyle.SKIN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var body := UITheme.make_label(
		"The pronunciation server is not reachable.\n\nMake sure your backend is running, then set your PC's IP address in Settings.",
		UITheme.FONT_BODY, Color("FFFAE8"), NatureMenuStyle.SKIN)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)

	var ip_note := UITheme.make_label(
		"Current server: %s" % PronunciationManager.ws_url,
		UITheme.FONT_SMALL, Color("A0A0A0"), NatureMenuStyle.SKIN)
	ip_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ip_note)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var settings_btn := UITheme.make_button("Open Settings", null, UITheme.FONT_BODY, "primary", NatureMenuStyle.SKIN)
	settings_btn.custom_minimum_size = Vector2(180, 56)
	settings_btn.pressed.connect(func():
		overlay.queue_free()
		_open_settings()
	)
	btn_row.add_child(settings_btn)

	var cancel_btn := UITheme.make_button("Cancel", null, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	cancel_btn.custom_minimum_size = Vector2(120, 56)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(cancel_btn)


func _show_voice_loading_overlay() -> void:
	_hide_voice_loading_overlay()
	_voice_loading_overlay = Control.new()
	_voice_loading_overlay.name = "VoiceLoadingOverlay"
	_voice_loading_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_voice_loading_overlay.anchor_right = 1.0
	_voice_loading_overlay.anchor_bottom = 1.0
	_voice_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_voice_loading_overlay.z_index = 200
	add_child(_voice_loading_overlay)

	var shade := ColorRect.new()
	shade.anchors_preset = Control.PRESET_FULL_RECT
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.color = Color(0.06, 0.08, 0.06, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_voice_loading_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_voice_loading_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 220)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = NatureMenuStyle.CREAM_SURFACE
	panel_style.border_color = NatureMenuStyle.PANEL_BORDER
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.18)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := UITheme.make_label("Preparing voice mode...", UITheme.FONT_HEADING, UITheme.get_color("text_ink", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var subtitle := UITheme.make_label("Connecting to pronunciation server...", UITheme.FONT_BODY, UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	var note := UITheme.make_label("This may take a few seconds on first launch.", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(note)


func _hide_voice_loading_overlay() -> void:
	if _voice_loading_overlay and is_instance_valid(_voice_loading_overlay):
		_voice_loading_overlay.queue_free()
	_voice_loading_overlay = null

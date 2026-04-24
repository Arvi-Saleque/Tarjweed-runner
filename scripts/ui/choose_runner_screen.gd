extends Control

signal back_pressed
signal runner_changed(runner_id: String)

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

const PANEL_CREAM := Color("FFF5D8")
const PANEL_CREAM_SOFT := Color("FFF9E8")
const PANEL_STROKE := Color("8A5A35")
const LEAF_GREEN := Color("2F6B3B")
const LEAF_GREEN_LIGHT := Color("6DBE57")
const TEXT_DARK := Color("234126")
const TEXT_SOFT := Color("60705D")
const COIN_YELLOW := Color("F7C542")

var _featured_preview: TextureRect
var _featured_title: Label
var _featured_subtitle: Label
var _wallet_label: Label
var _featured_status: Label
var _grid: GridContainer
var _selected_runner_id: String = ""
var _focused_runner_id: String = ""
var _card_map: Dictionary = {}
var _action_button: Button


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_selected_runner_id = GameManager.current_player_variant
	if _selected_runner_id.is_empty() or _selected_runner_id == "nature_default":
		_selected_runner_id = "elf"
	_focused_runner_id = _selected_runner_id
	_build_layout()
	_rebuild_roster()
	_refresh_featured()


func _build_layout() -> void:
	var shell := NatureMenuStyle.make_shell(self, "", "", 1240.0, 760.0)
	var shell_vbox := shell["shell"] as VBoxContainer
	for child in shell_vbox.get_children():
		shell_vbox.remove_child(child)
		child.queue_free()
	shell_vbox.add_theme_constant_override("separation", 16)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 92)
	header.add_theme_constant_override("separation", 18)
	shell_vbox.add_child(header)

	var title_row := HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 16)
	header.add_child(title_row)

	var leaf_badge := _make_round_icon_badge(UITheme.icon_star, Vector2(64, 64), LEAF_GREEN_LIGHT, LEAF_GREEN)
	title_row.add_child(leaf_badge)

	var title_copy := VBoxContainer.new()
	title_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_copy.add_theme_constant_override("separation", 2)
	title_row.add_child(title_copy)

	var title := UITheme.make_label("Choose Runner", UITheme.FONT_TITLE, TEXT_DARK, NatureMenuStyle.SKIN)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_copy.add_child(title)

	var subtitle := UITheme.make_label("Unlock with coins and choose your favorite runner.", UITheme.FONT_SMALL, TEXT_SOFT, NatureMenuStyle.SKIN)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_copy.add_child(subtitle)

	var wallet_pill := _build_wallet_pill()
	header.add_child(wallet_pill)

	var divider := HSeparator.new()
	divider.add_theme_stylebox_override("separator", _make_line_style(Color(0.52, 0.42, 0.20, 0.28)))
	shell_vbox.add_child(divider)

	var main_row := HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 22)
	shell_vbox.add_child(main_row)

	var featured := _make_featured_panel()
	main_row.add_child(featured)

	var vertical_divider := VSeparator.new()
	vertical_divider.add_theme_stylebox_override("separator", _make_line_style(Color(0.52, 0.42, 0.20, 0.28)))
	main_row.add_child(vertical_divider)

	var roster_area := VBoxContainer.new()
	roster_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_area.add_theme_constant_override("separation", 8)
	main_row.add_child(roster_area)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_area.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)

	var footer_divider := HSeparator.new()
	footer_divider.add_theme_stylebox_override("separator", _make_line_style(Color(0.52, 0.42, 0.20, 0.36)))
	shell_vbox.add_child(footer_divider)

	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 72)
	footer.add_theme_constant_override("separation", 18)
	shell_vbox.add_child(footer)

	var back_btn := UITheme.make_button("  Back", UITheme.icon_cross, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	back_btn.custom_minimum_size = Vector2(178, 58)
	UITheme.align_text_button_left(back_btn)
	back_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		back_pressed.emit()
	)
	footer.add_child(back_btn)

	var helper := UITheme.make_label("Earn coins by playing and completing runs!", UITheme.FONT_SMALL, TEXT_SOFT, NatureMenuStyle.SKIN)
	helper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	helper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(helper)

	_action_button = UITheme.make_button("  Confirm Selection", UITheme.icon_check, UITheme.FONT_BODY, "primary", NatureMenuStyle.SKIN)
	_action_button.custom_minimum_size = Vector2(280, 58)
	UITheme.align_text_button_left(_action_button)
	_action_button.pressed.connect(_on_action_pressed)
	footer.add_child(_action_button)


func _build_wallet_pill() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(200, 64)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_END
	pill.add_theme_stylebox_override("panel", _make_panel_style(Color("FFF8E6"), Color("7E8A36"), 3, 28, true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	pill.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var coin := _make_round_icon_badge(UITheme.icon_coin, Vector2(42, 42), COIN_YELLOW, Color("C98A18"))
	row.add_child(coin)

	_wallet_label = UITheme.make_label("0", UITheme.FONT_BODY, TEXT_DARK, NatureMenuStyle.SKIN)
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_wallet_label)

	var plus_badge := PanelContainer.new()
	plus_badge.custom_minimum_size = Vector2(34, 34)
	plus_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus_badge.add_theme_stylebox_override("panel", _make_panel_style(LEAF_GREEN_LIGHT, LEAF_GREEN, 2, 17, false))
	row.add_child(plus_badge)

	var plus_center := CenterContainer.new()
	plus_badge.add_child(plus_center)

	var plus := UITheme.make_label("+", UITheme.FONT_BODY, Color.WHITE, NatureMenuStyle.SKIN)
	plus_center.add_child(plus)

	return pill


func _make_featured_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_CREAM_SOFT, PANEL_STROKE, 3, 24, true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	margin.add_child(body)

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(320, 330)
	preview_frame.add_theme_stylebox_override("panel", _make_panel_style(Color("F8EFCF"), PANEL_STROKE, 3, 18, true))
	body.add_child(preview_frame)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 10)
	preview_margin.add_theme_constant_override("margin_right", 10)
	preview_margin.add_theme_constant_override("margin_top", 10)
	preview_margin.add_theme_constant_override("margin_bottom", 10)
	preview_frame.add_child(preview_margin)

	_featured_preview = NatureMenuStyle.make_preview("", Vector2(300, 310))
	_featured_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_margin.add_child(_featured_preview)

	_featured_title = UITheme.make_label("", UITheme.FONT_HEADING, TEXT_DARK, NatureMenuStyle.SKIN)
	body.add_child(_featured_title)

	_featured_subtitle = UITheme.make_label("", UITheme.FONT_SMALL, TEXT_SOFT, NatureMenuStyle.SKIN)
	body.add_child(_featured_subtitle)

	var status_center := CenterContainer.new()
	body.add_child(status_center)

	var status_pill := PanelContainer.new()
	status_pill.add_theme_stylebox_override("panel", _make_panel_style(Color("BFE6A5"), LEAF_GREEN_LIGHT, 2, 16, false))
	status_center.add_child(status_pill)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 14)
	status_margin.add_theme_constant_override("margin_right", 14)
	status_margin.add_theme_constant_override("margin_top", 4)
	status_margin.add_theme_constant_override("margin_bottom", 4)
	status_pill.add_child(status_margin)

	_featured_status = UITheme.make_label("", UITheme.FONT_SMALL, LEAF_GREEN, NatureMenuStyle.SKIN)
	status_margin.add_child(_featured_status)

	return panel


func _rebuild_roster() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_card_map.clear()

	for runner in ThemeRegistryScript.get_player_options("nature"):
		var runner_id: String = str(runner.get("id", ""))
		var card: PanelContainer = _build_runner_card(runner)
		_grid.add_child(card)
		_card_map[runner_id] = card

	_refresh_wallet()


func _build_runner_card(runner: Dictionary) -> PanelContainer:
	var runner_id: String = str(runner.get("id", ""))
	var is_unlocked: bool = SaveManager.is_runner_unlocked(runner_id)
	var price: int = int(MenuFlowCatalog.get_runner_price(runner_id))
	var is_selected: bool = runner_id == _selected_runner_id
	var is_focused: bool = runner_id == _focused_runner_id
	var title: String = str(runner.get("title", ""))
	var preview_path: String = str(runner.get("preview_image_path", ""))

	var border_color := LEAF_GREEN if is_selected or is_focused else Color("B8A879")
	var border_width := 4 if is_selected or is_focused else 2
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(198, 248)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_CREAM_SOFT, border_color, border_width, 16, true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)

	var preview_stack := Control.new()
	preview_stack.custom_minimum_size = Vector2(164, 130)
	preview_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview_stack)

	var preview_bg := ColorRect.new()
	preview_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_bg.anchor_right = 1.0
	preview_bg.anchor_bottom = 1.0
	preview_bg.color = Color("EFE4C4")
	preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(preview_bg)

	var preview := NatureMenuStyle.make_preview(preview_path, Vector2(164, 130))
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.anchor_right = 1.0
	preview.anchor_bottom = 1.0
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_stack.add_child(preview)

	var corner_badge := _make_corner_badge(is_selected, is_unlocked)
	preview_stack.add_child(corner_badge)

	var name_label := UITheme.make_label(title, UITheme.FONT_SMALL, TEXT_DARK, NatureMenuStyle.SKIN)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(name_label)

	if is_selected:
		var selected_label := UITheme.make_label("Selected", UITheme.FONT_SMALL - 2, LEAF_GREEN, NatureMenuStyle.SKIN)
		body.add_child(selected_label)
	elif is_unlocked:
		var owned_label := UITheme.make_label("Owned", UITheme.FONT_SMALL - 2, TEXT_SOFT, NatureMenuStyle.SKIN)
		body.add_child(owned_label)
	else:
		body.add_child(_make_price_pill(price))

	var click_button := Button.new()
	click_button.anchors_preset = Control.PRESET_FULL_RECT
	click_button.anchor_right = 1.0
	click_button.anchor_bottom = 1.0
	click_button.mouse_filter = Control.MOUSE_FILTER_STOP
	click_button.focus_mode = Control.FOCUS_NONE
	var empty_style := StyleBoxEmpty.new()
	click_button.add_theme_stylebox_override("normal", empty_style)
	click_button.add_theme_stylebox_override("hover", empty_style)
	click_button.add_theme_stylebox_override("pressed", empty_style)
	click_button.add_theme_stylebox_override("focus", empty_style)
	click_button.add_theme_stylebox_override("disabled", empty_style)
	click_button.pressed.connect(func(): _focus_runner(runner_id))
	card.add_child(click_button)

	return card


func _make_corner_badge(is_selected: bool, is_unlocked: bool) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -38.0
	badge.offset_top = 0.0
	badge.offset_right = -2.0
	badge.offset_bottom = 36.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _make_panel_style(LEAF_GREEN, LEAF_GREEN, 0, 18, false))

	var center := CenterContainer.new()
	badge.add_child(center)

	if is_selected:
		var check_icon := TextureRect.new()
		check_icon.texture = UITheme.icon_check
		check_icon.custom_minimum_size = Vector2(22, 22)
		check_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		check_icon.modulate = Color.WHITE
		check_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(check_icon)
	elif not is_unlocked:
		var lock_text := UITheme.make_label("LOCK", UITheme.FONT_SMALL - 8, Color.WHITE, NatureMenuStyle.SKIN)
		center.add_child(lock_text)
	else:
		badge.visible = false

	return badge


func _make_price_pill(price: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _make_panel_style(LEAF_GREEN, LEAF_GREEN, 0, 14, false))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	pill.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)

	var coin_icon := TextureRect.new()
	coin_icon.texture = UITheme.icon_coin
	coin_icon.custom_minimum_size = Vector2(18, 18)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(coin_icon)

	var price_label := UITheme.make_label(str(price), UITheme.FONT_SMALL - 2, Color.WHITE, NatureMenuStyle.SKIN)
	row.add_child(price_label)

	return pill


func _focus_runner(runner_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_focused_runner_id = runner_id
	_rebuild_roster()
	_refresh_featured()


func _select_runner(runner_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_selected_runner_id = runner_id
	_focused_runner_id = runner_id
	GameManager.current_player_variant = runner_id
	SaveManager.set_selected_runner_id(runner_id)
	_rebuild_roster()
	_refresh_featured()
	runner_changed.emit(runner_id)


func _buy_runner(runner_id: String, price: int) -> void:
	if not SaveManager.spend_wallet_coins(price):
		AudioManager.play_fail_sound()
		return

	AudioManager.play_ui_sound(AudioManager.ui_click)
	SaveManager.unlock_runner(runner_id)
	_select_runner(runner_id)


func _refresh_featured() -> void:
	var focused: Dictionary = ThemeRegistryScript.get_player_profile("nature", _focused_runner_id)
	var preview_path: String = str(focused.get("preview_image_path", ""))
	var is_selected: bool = _focused_runner_id == _selected_runner_id
	var is_unlocked: bool = SaveManager.is_runner_unlocked(_focused_runner_id)
	var price: int = int(MenuFlowCatalog.get_runner_price(_focused_runner_id))
	_featured_preview.texture = load(preview_path) as Texture2D if ResourceLoader.exists(preview_path) else null
	_featured_title.text = str(focused.get("title", ""))
	_featured_subtitle.text = str(focused.get("subtitle", ""))
	_featured_status.text = "Selected" if is_selected else "Owned" if is_unlocked else "Locked"
	_refresh_wallet()

	UITheme._apply_button_variant(_action_button, "primary" if is_unlocked else "secondary", NatureMenuStyle.SKIN)
	_action_button.icon = UITheme.icon_check if is_unlocked else UITheme.icon_coin
	_action_button.text = "  Selected" if is_selected else "  Confirm Selection" if is_unlocked else "  Buy %d" % price
	_action_button.disabled = is_selected
	UITheme.align_text_button_left(_action_button)


func _refresh_wallet() -> void:
	if _wallet_label:
		_wallet_label.text = str(SaveManager.get_wallet_coins())


func _on_action_pressed() -> void:
	var is_unlocked: bool = SaveManager.is_runner_unlocked(_focused_runner_id)
	var price: int = int(MenuFlowCatalog.get_runner_price(_focused_runner_id))
	if is_unlocked:
		_select_runner(_focused_runner_id)
	else:
		_buy_runner(_focused_runner_id, price)


func _make_round_icon_badge(icon: Texture2D, min_size: Vector2, bg_color: Color, border_color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = min_size
	badge.add_theme_stylebox_override("panel", _make_panel_style(bg_color, border_color, 2, int(min_size.x * 0.5), true))

	var center := CenterContainer.new()
	badge.add_child(center)

	if icon:
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = min_size * 0.56
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(icon_rect)

	return badge


func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if shadow:
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 4)
		style.shadow_color = Color(0.22, 0.15, 0.05, 0.18)
	return style


func _make_line_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 1.0
	style.content_margin_right = 1.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	return style

extends Control

signal back_pressed
signal runner_changed(runner_id: String)

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

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
	var shell := NatureMenuStyle.make_shell(
		self,
		"Choose Runner",
		"Unlock with coins",
		1240.0,
		760.0
	)
	var shell_vbox := shell["shell"] as VBoxContainer
	var content := shell["content"] as HBoxContainer

	var featured := NatureMenuStyle.make_card("", "", Vector2(420, 560), true)
	featured.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(featured)

	var featured_body := featured.get_meta("body") as VBoxContainer
	featured_body.add_theme_constant_override("separation", 14)

	_featured_preview = NatureMenuStyle.make_preview("", Vector2(340, 300))
	featured_body.add_child(_featured_preview)

	_featured_title = UITheme.make_label("", UITheme.FONT_HEADING, UITheme.get_color("text", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_featured_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	featured_body.add_child(_featured_title)

	_featured_subtitle = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_featured_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	featured_body.add_child(_featured_subtitle)

	_featured_status = UITheme.make_label("", UITheme.FONT_BODY, UITheme.get_color("primary_dark", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_featured_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	featured_body.add_child(_featured_status)

	var roster := NatureMenuStyle.make_card("", "", Vector2(760, 560), true)
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(roster)

	var roster_body := roster.get_meta("body") as VBoxContainer
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_body.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 20)
	_grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(_grid)

	var action_bar := NatureMenuStyle.make_card("", "", Vector2(0, 110), true)
	shell_vbox.add_child(action_bar)
	var action_body := action_bar.get_meta("body") as VBoxContainer
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 18)
	action_body.add_child(action_row)

	var back_btn := UITheme.make_button("Back", null, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	back_btn.custom_minimum_size = Vector2(220, 64)
	UITheme.align_text_button_left(back_btn, false)
	back_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		back_pressed.emit()
	)
	action_row.add_child(back_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(spacer)

	_wallet_label = NatureMenuStyle.make_coin_label("")
	action_row.add_child(_wallet_label)

	_action_button = UITheme.make_button("  Select", UITheme.icon_check, UITheme.FONT_BODY, "primary", NatureMenuStyle.SKIN)
	_action_button.custom_minimum_size = Vector2(190, 64)
	UITheme.align_text_button_left(_action_button)
	_action_button.pressed.connect(_on_action_pressed)
	action_row.add_child(_action_button)


func _rebuild_roster() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_card_map.clear()

	for runner in ThemeRegistryScript.get_player_options("nature"):
		var runner_id: String = str(runner.get("id", ""))
		var card: PanelContainer = _build_runner_card(runner)
		_grid.add_child(card)
		_card_map[runner_id] = card

	_wallet_label.text = "Available coins: %d" % SaveManager.get_wallet_coins()


func _build_runner_card(runner: Dictionary) -> PanelContainer:
	var runner_id: String = str(runner.get("id", ""))
	var is_unlocked: bool = SaveManager.is_runner_unlocked(runner_id)
	var price: int = int(MenuFlowCatalog.get_runner_price(runner_id))
	var is_selected: bool = runner_id == _selected_runner_id
	var is_focused: bool = runner_id == _focused_runner_id

	var title: String = str(runner.get("title", ""))
	var preview_path: String = str(runner.get("preview_image_path", ""))
	var card: PanelContainer = NatureMenuStyle.make_card("", "", Vector2(0, 240), true)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := card.get_meta("body") as VBoxContainer
	body.add_theme_constant_override("separation", 8)

	# Preview + optional lock overlay inside a stack container
	var preview_stack := Control.new()
	preview_stack.custom_minimum_size = Vector2(280, 150)
	preview_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview_stack)

	var preview := NatureMenuStyle.make_preview(preview_path, Vector2(280, 150))
	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview.anchor_right = 1.0
	preview.anchor_bottom = 1.0
	preview_stack.add_child(preview)

	if not is_unlocked:
		# Dark wash over the preview
		var lock_wash := ColorRect.new()
		lock_wash.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_wash.anchor_right = 1.0
		lock_wash.anchor_bottom = 1.0
		lock_wash.color = Color(0.10, 0.07, 0.04, 0.72)
		lock_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_stack.add_child(lock_wash)

		# Coin-price badge centered on the overlay
		var badge_center := CenterContainer.new()
		badge_center.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge_center.anchor_right = 1.0
		badge_center.anchor_bottom = 1.0
		badge_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_stack.add_child(badge_center)

		var badge_pill := PanelContainer.new()
		badge_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pill_style := StyleBoxFlat.new()
		pill_style.bg_color = Color("1E5128")
		pill_style.corner_radius_top_left = 18
		pill_style.corner_radius_top_right = 18
		pill_style.corner_radius_bottom_left = 18
		pill_style.corner_radius_bottom_right = 18
		pill_style.shadow_color = Color(0, 0, 0, 0.35)
		pill_style.shadow_size = 6
		pill_style.shadow_offset = Vector2(0, 3)
		badge_pill.add_theme_stylebox_override("panel", pill_style)
		badge_center.add_child(badge_pill)

		var pill_margin := MarginContainer.new()
		pill_margin.add_theme_constant_override("margin_left", 14)
		pill_margin.add_theme_constant_override("margin_right", 14)
		pill_margin.add_theme_constant_override("margin_top", 6)
		pill_margin.add_theme_constant_override("margin_bottom", 6)
		pill_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_pill.add_child(pill_margin)

		var badge_row := HBoxContainer.new()
		badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
		badge_row.add_theme_constant_override("separation", 6)
		badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill_margin.add_child(badge_row)

		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if UITheme.font_display:
			lock_lbl.add_theme_font_override("font", UITheme.font_display)
		lock_lbl.add_theme_font_size_override("font_size", 22)
		badge_row.add_child(lock_lbl)

		var price_lbl := Label.new()
		price_lbl.text = "%d 🪙" % price
		price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if UITheme.font_display:
			price_lbl.add_theme_font_override("font", UITheme.font_display)
		price_lbl.add_theme_font_size_override("font_size", 22)
		price_lbl.add_theme_color_override("font_color", Color("F7C542"))
		badge_row.add_child(price_lbl)

	var name_label := UITheme.make_label(title, UITheme.FONT_BODY, UITheme.get_color("text_ink", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(name_label)

	var state_text := "Selected" if is_selected else "Owned" if is_unlocked else "Locked"
	var state_color := (
		UITheme.get_color("primary_dark", NatureMenuStyle.SKIN)
		if is_selected or is_unlocked
		else UITheme.get_color("danger", NatureMenuStyle.SKIN)
	)
	var state_label := UITheme.make_label(
		state_text,
		UITheme.FONT_SMALL,
		state_color,
		NatureMenuStyle.SKIN
	)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(state_label)

	if is_selected or is_focused:
		var outline := Panel.new()
		outline.anchors_preset = Control.PRESET_FULL_RECT
		outline.anchor_right = 1.0
		outline.anchor_bottom = 1.0
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var outline_style := StyleBoxFlat.new()
		outline_style.bg_color = Color(0, 0, 0, 0)
		outline_style.border_color = UITheme.get_color("primary", NatureMenuStyle.SKIN) if is_focused else UITheme.get_color("panel_stroke", NatureMenuStyle.SKIN)
		outline_style.border_width_left = 3 if is_focused else 2
		outline_style.border_width_right = 3 if is_focused else 2
		outline_style.border_width_top = 3 if is_focused else 2
		outline_style.border_width_bottom = 3 if is_focused else 2
		outline_style.corner_radius_top_left = 18
		outline_style.corner_radius_top_right = 18
		outline_style.corner_radius_bottom_left = 18
		outline_style.corner_radius_bottom_right = 18
		outline.add_theme_stylebox_override("panel", outline_style)
		card.add_child(outline)

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
	_wallet_label.text = "Available coins: %d" % SaveManager.get_wallet_coins()
	UITheme._apply_button_variant(_action_button, "primary" if is_unlocked else "secondary", NatureMenuStyle.SKIN)
	_action_button.icon = UITheme.icon_check if is_selected else UITheme.icon_play if is_unlocked else UITheme.icon_coin
	_action_button.text = "  Selected" if is_selected else "  Select" if is_unlocked else "  Buy %d" % price
	_action_button.disabled = is_selected
	UITheme.align_text_button_left(_action_button)


func _on_action_pressed() -> void:
	var is_unlocked: bool = SaveManager.is_runner_unlocked(_focused_runner_id)
	var price: int = int(MenuFlowCatalog.get_runner_price(_focused_runner_id))
	if is_unlocked:
		_select_runner(_focused_runner_id)
	else:
		_buy_runner(_focused_runner_id, price)

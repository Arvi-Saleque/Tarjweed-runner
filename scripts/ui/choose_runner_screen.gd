extends Control

signal back_pressed
signal runner_changed(runner_id: String)

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

const LEADER_ASSET_ROOT := "res://assets/UI/leaderboard/"
const BASE_SIZE := Vector2(1672.0, 941.0)

const PANEL_CREAM := Color("FFF5D8")
const PANEL_CREAM_SOFT := Color("FFF9E8")
const PANEL_STROKE := Color("8A5A35")
const PANEL_STROKE_SOFT := Color("B79861")
const LEAF_GREEN := Color("2F6B3B")
const LEAF_GREEN_LIGHT := Color("66AA45")
const TEXT_DARK := Color("143D1E")
const TEXT_SOFT := Color("5F6C57")
const TEXT_BROWN := Color("4C321E")
const COIN_YELLOW := Color("F0B82E")
const LOCKED_WASH := Color(0.18, 0.14, 0.09, 0.46)

var _stage: Control
var _featured_avatar: Control
var _featured_title: Label
var _featured_subtitle: Label
var _wallet_label: Label
var _featured_status: Label
var _grid: GridContainer
var _selected_runner_id: String = ""
var _focused_runner_id: String = ""
var _card_map: Dictionary = {}
var _action_button: Button
var _action_label: Label
var _action_icon: TextureRect


func _ready() -> void:
	NatureMenuStyle.decorate_root(self, LEADER_ASSET_ROOT + "bg.png")
	_selected_runner_id = GameManager.current_player_variant
	if _selected_runner_id.is_empty() or _selected_runner_id == "nature_default":
		_selected_runner_id = "elf"
	_focused_runner_id = _selected_runner_id
	_build_layout()
	_layout_stage()
	_rebuild_roster()
	_refresh_featured()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_stage()


func _build_layout() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var wash := ColorRect.new()
	wash.name = "ChooseRunnerWash"
	wash.anchors_preset = Control.PRESET_FULL_RECT
	wash.anchor_right = 1.0
	wash.anchor_bottom = 1.0
	wash.color = Color(0.08, 0.12, 0.04, 0.20)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	_stage = Control.new()
	_stage.name = "ChooseRunnerStage"
	_stage.size = BASE_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_build_board_panel()
	_build_header()
	_build_featured_panel()
	_build_roster_panel()
	_build_footer()


func _layout_stage() -> void:
	if _stage == null:
		return
	var viewport_size := get_viewport_rect().size
	var stage_scale := minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	_stage.size = BASE_SIZE
	_stage.scale = Vector2(stage_scale, stage_scale)
	_stage.position = (viewport_size - BASE_SIZE * stage_scale) * 0.5


func _build_board_panel() -> void:
	var shadow := ColorRect.new()
	shadow.position = Vector2(236, 98)
	shadow.size = Vector2(1200, 780)
	shadow.color = Color(0.07, 0.04, 0.02, 0.28)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(shadow)

	var board := Panel.new()
	board.name = "ChooseRunnerBoard"
	board.position = Vector2(218, 78)
	board.size = Vector2(1236, 786)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_theme_stylebox_override("panel", _make_panel_style(Color("FFF3D3"), PANEL_STROKE, 5, 30, true))
	_stage.add_child(board)

	var inner := Panel.new()
	inner.position = Vector2(22, 22)
	inner.size = Vector2(1192, 742)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", _make_panel_style(Color("FFF8E5"), Color("D6BC82"), 2, 22, false))
	board.add_child(inner)

	_add_texture(_stage, "BoardLeafLeft", LEADER_ASSET_ROOT + "left-leaf.png", Rect2(250, 92, 70, 42))
	_add_texture(_stage, "BoardLeafRight", LEADER_ASSET_ROOT + "right-leaf.png", Rect2(1360, 92, 70, 42))


func _build_header() -> void:
	var title := _make_label("Choose Runner", 58, TEXT_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector2(314, 112)
	title.size = Vector2(420, 70)
	_stage.add_child(title)

	var subtitle := _make_label("Pick a runner, unlock new styles, and keep your forest runs feeling fresh.", 22, TEXT_SOFT)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.position = Vector2(318, 178)
	subtitle.size = Vector2(610, 34)
	_stage.add_child(subtitle)

	var wallet_panel := PanelContainer.new()
	wallet_panel.position = Vector2(1116, 116)
	wallet_panel.size = Vector2(236, 72)
	wallet_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("FFF7DF"), PANEL_STROKE, 4, 28, true))
	_stage.add_child(wallet_panel)

	var wallet_row := HBoxContainer.new()
	wallet_row.anchors_preset = Control.PRESET_FULL_RECT
	wallet_row.anchor_right = 1.0
	wallet_row.anchor_bottom = 1.0
	wallet_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wallet_row.add_theme_constant_override("separation", 12)
	wallet_panel.add_child(wallet_row)

	wallet_row.add_child(_add_coin_badge(null, Vector2.ZERO, 42.0))
	_wallet_label = _make_label("0", 26, TEXT_DARK)
	_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_wallet_label.custom_minimum_size = Vector2(88, 48)
	wallet_row.add_child(_wallet_label)


func _build_featured_panel() -> void:
	var panel := Panel.new()
	panel.name = "FeaturedRunnerPanel"
	panel.position = Vector2(300, 250)
	panel.size = Vector2(410, 514)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(PANEL_CREAM_SOFT, PANEL_STROKE, 4, 22, true))
	_stage.add_child(panel)

	var inner := Panel.new()
	inner.position = Vector2(35, 28)
	inner.size = Vector2(340, 300)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", _make_panel_style(Color("F4E7C4"), PANEL_STROKE_SOFT, 3, 18, false))
	panel.add_child(inner)

	_featured_avatar = Control.new()
	_featured_avatar.position = Vector2(55, 44)
	_featured_avatar.size = Vector2(300, 260)
	_featured_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_featured_avatar)

	_featured_title = _make_label("", 36, TEXT_DARK)
	_featured_title.position = Vector2(28, 356)
	_featured_title.size = Vector2(354, 44)
	panel.add_child(_featured_title)

	_featured_subtitle = _make_label("", 19, TEXT_SOFT)
	_featured_subtitle.position = Vector2(34, 401)
	_featured_subtitle.size = Vector2(342, 50)
	_featured_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_featured_subtitle)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(112, 462)
	status_panel.size = Vector2(186, 38)
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("DDEFC2"), LEAF_GREEN_LIGHT, 2, 19, false))
	panel.add_child(status_panel)

	_featured_status = _make_label("", 17, LEAF_GREEN)
	_featured_status.anchors_preset = Control.PRESET_FULL_RECT
	_featured_status.anchor_right = 1.0
	_featured_status.anchor_bottom = 1.0
	status_panel.add_child(_featured_status)


func _build_roster_panel() -> void:
	var title := _make_label("Runner Roster", 32, TEXT_DARK)
	title.position = Vector2(805, 244)
	title.size = Vector2(290, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(title)

	var hint := _make_label("Tap a card to preview. Locked runners can be bought with wallet coins.", 18, TEXT_SOFT)
	hint.position = Vector2(808, 287)
	hint.size = Vector2(548, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.name = "RunnerScroll"
	scroll.position = Vector2(794, 330)
	scroll.size = Vector2(590, 434)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.custom_minimum_size = Vector2(560, 0)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)


func _build_footer() -> void:
	var back := _add_image_button(_stage, "BackButton", LEADER_ASSET_ROOT + "back-button.png", Rect2(304, 754, 220, 70))
	back.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		back_pressed.emit()
	)
	_add_button_label(back, "Back", 27, TEXT_DARK)

	_action_button = _add_image_button(_stage, "ActionButton", LEADER_ASSET_ROOT + "green-button.png", Rect2(1070, 754, 282, 70))
	_action_button.pressed.connect(_on_action_pressed)

	_action_icon = TextureRect.new()
	_action_icon.position = Vector2(28, 20)
	_action_icon.size = Vector2(30, 30)
	_action_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_action_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_action_icon.modulate = Color("FFF8DD")
	_action_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_action_button.add_child(_action_icon)

	_action_label = _make_label("", 25, Color("FFF8DD"))
	_action_label.position = Vector2(56, 0)
	_action_label.size = Vector2(210, 70)
	_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_action_button.add_child(_action_label)


func _rebuild_roster() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_card_map.clear()

	for runner in ThemeRegistryScript.get_player_options("nature"):
		var runner_id: String = str(runner.get("id", ""))
		var card := _build_runner_card(runner)
		_grid.add_child(card)
		_card_map[runner_id] = card

	_refresh_wallet()


func _build_runner_card(runner: Dictionary) -> Control:
	var runner_id: String = str(runner.get("id", ""))
	var is_unlocked := SaveManager.is_runner_unlocked(runner_id)
	var price := int(MenuFlowCatalog.get_runner_price(runner_id))
	var is_selected := runner_id == _selected_runner_id
	var is_focused := runner_id == _focused_runner_id
	var title := str(runner.get("title", ""))

	var card := Panel.new()
	card.custom_minimum_size = Vector2(176, 204)
	card.size = Vector2(176, 204)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border := LEAF_GREEN if is_selected or is_focused else PANEL_STROKE_SOFT
	var border_width := 4 if is_selected or is_focused else 2
	card.add_theme_stylebox_override("panel", _make_panel_style(PANEL_CREAM_SOFT, border, border_width, 16, true))

	var preview_frame := Panel.new()
	preview_frame.position = Vector2(12, 12)
	preview_frame.size = Vector2(152, 116)
	preview_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_theme_stylebox_override("panel", _make_panel_style(Color("F1E5C4"), Color("C3A878"), 2, 13, false))
	card.add_child(preview_frame)

	card.add_child(_make_runner_avatar(runner_id, title, Rect2(20, 22, 136, 92), false))

	if not is_unlocked:
		var locked := ColorRect.new()
		locked.position = Vector2(12, 12)
		locked.size = Vector2(152, 116)
		locked.color = LOCKED_WASH
		locked.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(locked)

	var badge := _make_card_badge(is_selected, is_unlocked)
	badge.position = Vector2(122, 10)
	card.add_child(badge)

	var name_label := _make_label(title, 17, TEXT_DARK)
	name_label.position = Vector2(12, 137)
	name_label.size = Vector2(152, 26)
	name_label.clip_text = true
	card.add_child(name_label)

	var state := _make_card_state(is_selected, is_unlocked, price)
	state.position = Vector2(16, 166)
	card.add_child(state)

	var click_button := Button.new()
	click_button.anchors_preset = Control.PRESET_FULL_RECT
	click_button.anchor_right = 1.0
	click_button.anchor_bottom = 1.0
	click_button.focus_mode = Control.FOCUS_NONE
	click_button.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty := StyleBoxEmpty.new()
	click_button.add_theme_stylebox_override("normal", empty)
	click_button.add_theme_stylebox_override("hover", empty)
	click_button.add_theme_stylebox_override("pressed", empty)
	click_button.add_theme_stylebox_override("focus", empty)
	click_button.pressed.connect(func(): _focus_runner(runner_id))
	card.add_child(click_button)

	click_button.mouse_entered.connect(func():
		var tween := card.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2(1.025, 1.025), 0.10)
	)
	click_button.mouse_exited.connect(func():
		var tween := card.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "scale", Vector2.ONE, 0.10)
	)

	return card


func _make_card_badge(is_selected: bool, is_unlocked: bool) -> Control:
	var badge := PanelContainer.new()
	badge.size = Vector2(42, 30)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _make_panel_style(LEAF_GREEN if is_unlocked else Color("8A5A35"), LEAF_GREEN if is_unlocked else Color("8A5A35"), 0, 15, false))

	var label := _make_label("OK" if is_selected else "OWN" if is_unlocked else "LOCK", 12, Color.WHITE)
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	badge.add_child(label)
	return badge


func _make_card_state(is_selected: bool, is_unlocked: bool, price: int) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(144, 28)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)

	if is_selected:
		row.add_child(_make_chip_label("Selected", Color("DFF0C3"), LEAF_GREEN, LEAF_GREEN))
	elif is_unlocked:
		row.add_child(_make_chip_label("Owned", Color("F7EFD6"), PANEL_STROKE_SOFT, TEXT_SOFT))
	else:
		row.add_child(_add_coin_badge(null, Vector2.ZERO, 22.0))
		var price_label := _make_label(str(price), 16, TEXT_BROWN)
		price_label.custom_minimum_size = Vector2(56, 24)
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(price_label)

	return row


func _make_chip_label(text: String, bg: Color, border: Color, text_color: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(104, 28)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _make_panel_style(bg, border, 2, 14, false))

	var label := _make_label(text, 15, text_color)
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	chip.add_child(label)
	return chip


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
	var focused := ThemeRegistryScript.get_player_profile("nature", _focused_runner_id)
	var is_selected := _focused_runner_id == _selected_runner_id
	var is_unlocked := SaveManager.is_runner_unlocked(_focused_runner_id)
	var price := int(MenuFlowCatalog.get_runner_price(_focused_runner_id))

	for child in _featured_avatar.get_children():
		child.queue_free()
	_featured_avatar.add_child(_make_runner_avatar(_focused_runner_id, str(focused.get("title", "")), Rect2(Vector2.ZERO, _featured_avatar.size), true))
	_featured_title.text = str(focused.get("title", ""))
	_featured_subtitle.text = str(focused.get("subtitle", ""))
	_featured_status.text = "Selected Runner" if is_selected else "Unlocked" if is_unlocked else "Locked"
	_refresh_wallet()

	if is_selected:
		_set_action_button("Selected", UITheme.icon_check, LEADER_ASSET_ROOT + "global-butotn.png", TEXT_DARK, true)
	elif is_unlocked:
		_set_action_button("Confirm", UITheme.icon_check, LEADER_ASSET_ROOT + "green-button.png", Color("FFF8DD"), false)
	else:
		_set_action_button("Buy %d" % price, UITheme.icon_coin, LEADER_ASSET_ROOT + "green-button.png", Color("FFF8DD"), false)


func _refresh_wallet() -> void:
	if _wallet_label:
		_wallet_label.text = str(SaveManager.get_wallet_coins())


func _on_action_pressed() -> void:
	var is_unlocked := SaveManager.is_runner_unlocked(_focused_runner_id)
	var price := int(MenuFlowCatalog.get_runner_price(_focused_runner_id))
	if is_unlocked:
		_select_runner(_focused_runner_id)
	else:
		_buy_runner(_focused_runner_id, price)


func _set_action_button(text: String, icon: Texture2D, texture_path: String, color: Color, disabled: bool) -> void:
	_action_button.disabled = disabled
	_set_button_texture(_action_button, texture_path)
	_action_label.text = text
	_action_label.add_theme_color_override("font_color", color)
	_action_icon.texture = icon
	_action_icon.modulate = color


func _add_image_button(parent: Control, node_name: String, texture_path: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _transparent_style())
	button.add_theme_stylebox_override("hover", _transparent_style())
	button.add_theme_stylebox_override("pressed", _transparent_style())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", _transparent_style())
	parent.add_child(button)

	var art := _add_texture(button, "Art", texture_path, Rect2(Vector2.ZERO, rect.size))
	art.stretch_mode = TextureRect.STRETCH_SCALE

	button.mouse_entered.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_hover)
		var tween := button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.025, 1.025), 0.10)
	)
	button.mouse_exited.connect(func():
		var tween := button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.10)
	)
	return button


func _add_button_label(button: Button, text: String, size: int, color: Color) -> Label:
	var label := _make_label(text, size, color)
	label.name = "Label"
	label.position = Vector2.ZERO
	label.size = button.size
	button.add_child(label)
	return label


func _set_button_texture(button: Button, texture_path: String) -> void:
	var art := button.get_node_or_null("Art") as TextureRect
	if art:
		art.texture = _load_texture(texture_path)


func _add_texture(parent: Control, node_name: String, texture_path: String, rect: Rect2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.texture = _load_texture(texture_path)
	parent.add_child(texture_rect)
	return texture_rect


func _add_coin_badge(parent: Control, pos: Vector2, diameter: float) -> Control:
	var badge := Control.new()
	badge.position = pos
	badge.custom_minimum_size = Vector2(diameter, diameter)
	badge.size = Vector2(diameter, diameter)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent:
		parent.add_child(badge)

	var coin := Panel.new()
	coin.anchors_preset = Control.PRESET_FULL_RECT
	coin.anchor_right = 1.0
	coin.anchor_bottom = 1.0
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.add_theme_stylebox_override("panel", _make_panel_style(COIN_YELLOW, Color("A76B13"), int(maxf(1.0, diameter * 0.08)), int(diameter * 0.5), true))
	badge.add_child(coin)

	var glyph := _make_label("$", int(maxf(12.0, diameter * 0.45)), Color("FFF4AC"))
	glyph.anchors_preset = Control.PRESET_FULL_RECT
	glyph.anchor_right = 1.0
	glyph.anchor_bottom = 1.0
	badge.add_child(glyph)
	return badge


func _make_runner_avatar(runner_id: String, title: String, rect: Rect2, large: bool) -> Control:
	var avatar := Control.new()
	avatar.position = rect.position
	avatar.size = rect.size
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var accent := _runner_color(runner_id)
	var bg := Panel.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _make_panel_style(accent.lightened(0.55), accent.darkened(0.25), 2 if not large else 3, 18 if not large else 30, false))
	avatar.add_child(bg)

	var floor := Panel.new()
	floor.position = Vector2(rect.size.x * 0.18, rect.size.y * 0.75)
	floor.size = Vector2(rect.size.x * 0.64, rect.size.y * 0.13)
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor.add_theme_stylebox_override("panel", _make_panel_style(Color(0.20, 0.30, 0.16, 0.22), Color(0, 0, 0, 0), 0, int(rect.size.y * 0.08), false))
	avatar.add_child(floor)

	var body := Panel.new()
	body.position = Vector2(rect.size.x * 0.36, rect.size.y * 0.40)
	body.size = Vector2(rect.size.x * 0.28, rect.size.y * 0.36)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", _make_panel_style(accent, accent.darkened(0.26), 2, int(rect.size.x * 0.08), true))
	avatar.add_child(body)

	var head := Panel.new()
	head.position = Vector2(rect.size.x * 0.37, rect.size.y * 0.16)
	head.size = Vector2(rect.size.x * 0.26, rect.size.x * 0.26)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_stylebox_override("panel", _make_panel_style(Color("2A2A25"), Color("161612"), 2, int(rect.size.x * 0.13), true))
	avatar.add_child(head)

	var trim := Panel.new()
	trim.position = Vector2(rect.size.x * 0.29, rect.size.y * 0.36)
	trim.size = Vector2(rect.size.x * 0.42, rect.size.y * 0.08)
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trim.add_theme_stylebox_override("panel", _make_panel_style(Color("FFF1CA"), accent.darkened(0.18), 1, int(rect.size.y * 0.04), false))
	avatar.add_child(trim)

	var initial := title.substr(0, 1)
	var mark := _make_label(initial, 54 if large else 26, Color("FFF8DD"))
	mark.position = Vector2.ZERO
	mark.size = rect.size
	mark.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.02, 0.35))
	avatar.add_child(mark)

	if large:
		var nameplate := _make_label(title.capitalize(), 22, accent.darkened(0.30))
		nameplate.position = Vector2(0, rect.size.y - 48)
		nameplate.size = Vector2(rect.size.x, 36)
		avatar.add_child(nameplate)

	return avatar


func _runner_color(runner_id: String) -> Color:
	match runner_id:
		"elf":
			return Color("38A36F")
		"goblin_male":
			return Color("7DB44B")
		"soldier_male":
			return Color("55785A")
		"cowboy_male":
			return Color("B98541")
		"kimono_male":
			return Color("C05B7B")
		"knight_male":
			return Color("6B7896")
		"ninja_male":
			return Color("444B5E")
		"pirate_male":
			return Color("A53E32")
		"witch":
			return Color("7E4AA3")
		"wizard":
			return Color("3E77B7")
	return LEAF_GREEN


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := UITheme.make_label(text, font_size, color, NatureMenuStyle.SKIN)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if UITheme.font_display and font_size >= UITheme.FONT_HEADING:
		label.add_theme_font_override("font", UITheme.font_display)
	label.add_theme_color_override("font_shadow_color", Color(0.10, 0.06, 0.02, 0.16))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


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
		style.shadow_color = Color(0.18, 0.11, 0.04, 0.20)
	return style


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	return style


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D

	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)

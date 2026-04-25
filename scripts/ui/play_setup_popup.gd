extends Control

signal closed
signal choose_runner_requested
signal start_requested(player_name: String, difficulty_id: String, mode_id: String, quiz_style_id: String)

const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

const ASSET_ROOT := "res://assets/UI/play_setup/"
const MAINMENU_ASSET_ROOT := "res://assets/UI/mainmenu/"
const BASE_SIZE := Vector2(1672.0, 941.0)

const TEXT_DARK := Color("173F1F")
const TEXT_SOFT := Color("5F604F")
const TEXT_BROWN := Color("4B3822")
const PANEL_LINE := Color("9B7445")
const GREEN := Color("2F6B3B")
const CREAM := Color("FFF2D2")
const GOLD := Color("E3A41E")
const FIELD_LEAF_OFFSET := Vector2(-28, 3)
const FIELD_LEAF_SIZE := Vector2(18, 22)

var _stage: Control
var _name_input: LineEdit
var _mode_buttons: Dictionary = {}
var _difficulty_buttons: Dictionary = {}
var _quiz_style_buttons: Dictionary = {}
var _quiz_style_label: Label
var _quiz_style_leaf: TextureRect
var _quiz_style_row: Control
var _difficulty_field_label: Label
var _runner_preview_label: Label
var _runner_panel: TextureRect
var _runner_avatar: Control
var _runner_title: Label
var _runner_subtitle: Label
var _choose_runner_button: Button
var _summary_wallet: Label
var _summary_wallet_value: Label
var _summary_mode: Label
var _summary_mode_value: Label
var _summary_difficulty: Label
var _summary_difficulty_value: Label
var _selected_mode: String = "normal"
var _selected_difficulty: String = MenuFlowCatalog.DEFAULT_DIFFICULTY
var _selected_quiz_style: String = MenuFlowCatalog.DEFAULT_QUIZ_STYLE


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	_selected_mode = GameManager.current_mode if not GameManager.current_mode.is_empty() else "normal"
	_selected_difficulty = GameManager.current_difficulty_id if not GameManager.current_difficulty_id.is_empty() else MenuFlowCatalog.DEFAULT_DIFFICULTY
	_selected_quiz_style = GameManager.current_quiz_style if not GameManager.current_quiz_style.is_empty() else MenuFlowCatalog.DEFAULT_QUIZ_STYLE
	_build_popup()
	_layout_stage()
	_refresh_runner_preview()
	_refresh_mode_buttons()
	_refresh_difficulty_buttons()
	_refresh_quiz_style_buttons()
	_refresh_summary()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_stage()


func _build_popup() -> void:
	var bg := TextureRect.new()
	bg.name = "PlaySetupBackground"
	bg.texture = _load_texture(ASSET_ROOT + "bg.png")
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var wash := ColorRect.new()
	wash.anchors_preset = Control.PRESET_FULL_RECT
	wash.anchor_right = 1.0
	wash.anchor_bottom = 1.0
	wash.color = Color(0.03, 0.06, 0.02, 0.12)
	wash.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(wash)

	_stage = Control.new()
	_stage.name = "PlaySetupStage"
	_stage.size = BASE_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_add_texture(_stage, "MainCard", ASSET_ROOT + "card.png", Rect2(202, -10, 1268, 960))
	_build_left_panel()
	_build_right_panel()


func _layout_stage() -> void:
	if _stage == null:
		return
	var viewport_size := get_viewport_rect().size
	var scale_value := minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	_stage.size = BASE_SIZE
	_stage.scale = Vector2(scale_value, scale_value)
	_stage.position = (viewport_size - BASE_SIZE * scale_value) * 0.5


func _build_left_panel() -> void:
	_add_panel(Rect2(330, 205, 575, 640), 24)
	_add_ribbon("Run Details", Vector2(360, 188), Vector2(250, 56))

	_add_field_label("Player Name", Vector2(382, 252))
	_add_texture(_stage, "NameField", ASSET_ROOT + "name-feild.png", Rect2(356, 280, 520, 48))
	_name_input = LineEdit.new()
	_name_input.position = Vector2(378, 281)
	_name_input.size = Vector2(480, 48)
	_name_input.text = GameManager.current_player_name if not GameManager.current_player_name.is_empty() else SaveManager.get_player_name()
	_name_input.placeholder_text = MenuFlowCatalog.DEFAULT_PLAYER_NAME
	_name_input.add_theme_font_size_override("font_size", 28)
	_name_input.add_theme_color_override("font_color", TEXT_DARK)
	_name_input.add_theme_color_override("font_placeholder_color", TEXT_SOFT)
	_name_input.add_theme_color_override("caret_color", GREEN)
	_name_input.add_theme_stylebox_override("normal", _transparent_style())
	_name_input.add_theme_stylebox_override("focus", _transparent_style())
	_name_input.add_theme_stylebox_override("read_only", _transparent_style())
	_stage.add_child(_name_input)

	_add_field_label("Mode", Vector2(382, 342))
	var mode_x := 356.0
	for mode in MenuFlowCatalog.MODES:
		var mode_id := str(mode.get("id", "normal"))
		var width := 150.0 if mode_id != "pronunciation" else 190.0
		var button := _make_selector_button(str(mode.get("title", "")).capitalize(), Rect2(mode_x, 372, width, 54), mode_id == _selected_mode)
		button.pressed.connect(func(): _set_mode(mode_id))
		_mode_buttons[mode_id] = button
		mode_x += width + 18.0

	_quiz_style_label = _make_label("Quiz Style", 18, TEXT_DARK)
	_quiz_style_label.position = Vector2(382, 430)
	_quiz_style_label.size = Vector2(160, 26)
	_quiz_style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_quiz_style_label.visible = false
	_stage.add_child(_quiz_style_label)
	_quiz_style_leaf = _add_texture(_stage, "QuizStyleLeaf", ASSET_ROOT + "leaf.png", Rect2(_quiz_style_label.position + FIELD_LEAF_OFFSET, FIELD_LEAF_SIZE))
	_quiz_style_leaf.z_index = 5
	_quiz_style_leaf.visible = false

	_quiz_style_row = Control.new()
	_quiz_style_row.position = Vector2(356, 458)
	_quiz_style_row.size = Vector2(520, 54)
	_quiz_style_row.visible = false
	_stage.add_child(_quiz_style_row)
	var quiz_x := 0.0
	for qs in MenuFlowCatalog.QUIZ_STYLES:
		var qs_id := str(qs.get("id", "math"))
		var button := _make_selector_button(_quiz_style_display(qs_id, str(qs.get("title", ""))), Rect2(quiz_x, 0, 118, 50), qs_id == _selected_quiz_style, _quiz_style_row, 16)
		button.pressed.connect(func(): _set_quiz_style(qs_id))
		_quiz_style_buttons[qs_id] = button
		quiz_x += 128.0

	_difficulty_field_label = _add_field_label("Difficulty", Vector2(382, 442))
	var difficulty_x := 356.0
	for difficulty in MenuFlowCatalog.DIFFICULTIES:
		var difficulty_id := str(difficulty.get("id", ""))
		var button := _make_selector_button(str(difficulty.get("title", "")).capitalize(), Rect2(difficulty_x, 472, 160, 54), difficulty_id == _selected_difficulty)
		button.pressed.connect(func(): _set_difficulty(difficulty_id))
		_difficulty_buttons[difficulty_id] = button
		difficulty_x += 175.0

	_runner_preview_label = _add_field_label("Runner Preview", Vector2(382, 544))
	_runner_panel = _add_texture(_stage, "RunnerPanel", ASSET_ROOT + "runner-panel.png", Rect2(356, 572, 520, 204))

	_runner_avatar = Control.new()
	_runner_avatar.position = Vector2(376, 590)
	_runner_avatar.size = Vector2(200, 168)
	_runner_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_runner_avatar)

	_runner_title = _make_label("", 34, TEXT_DARK)
	_runner_title.position = Vector2(625, 604)
	_runner_title.size = Vector2(180, 46)
	_stage.add_child(_runner_title)

	_runner_subtitle = _make_label("", 18, TEXT_BROWN)
	_runner_subtitle.position = Vector2(610, 651)
	_runner_subtitle.size = Vector2(220, 30)
	_stage.add_child(_runner_subtitle)

	_choose_runner_button = _make_image_button("ChooseRunnerButton", ASSET_ROOT + "choose-runner-btn.png", Rect2(610, 698, 240, 58))
	_choose_runner_button.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		choose_runner_requested.emit()
	)
	_add_button_label(_choose_runner_button, "Choose Runner", 22, Color("FFF8DD"), Vector2(22, 0), Vector2(198, 58))
	_apply_quiz_style_layout()


func _build_right_panel() -> void:
	_add_panel(Rect2(926, 205, 420, 640), 24)
	_add_ribbon("Start Run", Vector2(960, 188), Vector2(230, 56))

	var copy := _make_label("The game launches with the current\nrunner and saved setup.\nMode and difficulty now change how\nthe run plays, so you can pick a\ncalmer or tougher challenge here.", 18, TEXT_BROWN)
	copy.position = Vector2(972, 262)
	copy.size = Vector2(310, 122)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	copy.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_stage.add_child(copy)

	_add_texture(_stage, "SummaryPanel", ASSET_ROOT + "summery-panel.png", Rect2(950, 418, 360, 176))
	var summary_title := _make_label("Current Summary", 24, TEXT_DARK)
	summary_title.position = Vector2(1014, 430)
	summary_title.size = Vector2(220, 32)
	_stage.add_child(summary_title)

	_add_texture(_stage, "SummaryCoin", ASSET_ROOT + "coin.png", Rect2(972, 471, 28, 28))

	_summary_wallet = _make_label("Wallet coins", 18, TEXT_BROWN)
	_summary_wallet.position = Vector2(1022, 471)
	_summary_wallet.size = Vector2(140, 28)
	_summary_wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(_summary_wallet)
	_summary_wallet_value = _make_label("", 18, TEXT_BROWN)
	_summary_wallet_value.position = Vector2(1180, 471)
	_summary_wallet_value.size = Vector2(106, 28)
	_summary_wallet_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stage.add_child(_summary_wallet_value)

	_add_summary_line(494)

	_summary_mode = _make_label("Mode", 18, TEXT_BROWN)
	_summary_mode.position = Vector2(1022, 506)
	_summary_mode.size = Vector2(120, 28)
	_summary_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(_summary_mode)
	_summary_mode_value = _make_label("", 18, TEXT_BROWN)
	_summary_mode_value.position = Vector2(1132, 506)
	_summary_mode_value.size = Vector2(154, 28)
	_summary_mode_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_summary_mode_value.clip_text = true
	_stage.add_child(_summary_mode_value)

	_add_summary_line(538)

	_summary_difficulty = _make_label("Difficulty", 18, TEXT_BROWN)
	_summary_difficulty.position = Vector2(1022, 550)
	_summary_difficulty.size = Vector2(120, 28)
	_summary_difficulty.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(_summary_difficulty)
	_summary_difficulty_value = _make_label("", 18, TEXT_BROWN)
	_summary_difficulty_value.position = Vector2(1132, 550)
	_summary_difficulty_value.size = Vector2(154, 28)
	_summary_difficulty_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stage.add_child(_summary_difficulty_value)

	var start_btn := _make_image_button_region("StartButton", ASSET_ROOT + "start-btn.png", Rect2(962, 642, 345, 78), Rect2(0, 260, 1536, 560))
	start_btn.pressed.connect(_on_start_pressed)
	_add_play_icon(start_btn, Vector2(72, 10), 42)
	_add_button_label(start_btn, "Start", 38, Color("FFF8DD"), Vector2(116, -8), Vector2(170, 78))

	var cancel_btn := _make_image_button("CancelButton", ASSET_ROOT + "cancel-btn.png", Rect2(962, 735, 345, 70))
	cancel_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		closed.emit()
		queue_free()
	)
	_add_x_icon(cancel_btn, Vector2(76, 20), 34)
	_add_button_label(cancel_btn, "Cancel", 30, TEXT_BROWN, Vector2(118, 0), Vector2(160, 70))


func _set_difficulty(difficulty_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_selected_difficulty = difficulty_id
	_refresh_difficulty_buttons()
	_refresh_summary()


func _set_quiz_style(style_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_selected_quiz_style = style_id
	_refresh_quiz_style_buttons()
	_refresh_summary()


func _set_mode(mode_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_selected_mode = mode_id
	_refresh_mode_buttons()
	_refresh_summary()
	_apply_quiz_style_layout()


func _refresh_mode_buttons() -> void:
	for mode in MenuFlowCatalog.MODES:
		var mode_id := str(mode.get("id", ""))
		var btn := _mode_buttons.get(mode_id) as Button
		if btn:
			_set_selector_selected(btn, mode_id == _selected_mode)


func _refresh_difficulty_buttons() -> void:
	for difficulty in MenuFlowCatalog.DIFFICULTIES:
		var difficulty_id := str(difficulty.get("id", ""))
		var btn := _difficulty_buttons.get(difficulty_id) as Button
		if btn:
			_set_selector_selected(btn, difficulty_id == _selected_difficulty)


func _refresh_quiz_style_buttons() -> void:
	for qs in MenuFlowCatalog.QUIZ_STYLES:
		var qs_id := str(qs.get("id", ""))
		var btn := _quiz_style_buttons.get(qs_id) as Button
		if btn:
			_set_selector_selected(btn, qs_id == _selected_quiz_style)


func _refresh_summary() -> void:
	if _summary_wallet_value:
		_summary_wallet_value.text = str(SaveManager.get_wallet_coins())
	if _summary_mode_value:
		var mode_text := _selected_mode.capitalize()
		if _selected_mode == "quiz":
			mode_text = "Quiz: %s" % _quiz_style_display(_selected_quiz_style, _selected_quiz_style)
		_summary_mode_value.text = mode_text
	if _summary_difficulty_value:
		_summary_difficulty_value.text = _selected_difficulty.capitalize()


func _refresh_runner_preview() -> void:
	var runner_id := str(GameManager.current_player_variant)
	if runner_id.is_empty() or runner_id == "nature_default":
		runner_id = "elf"
	var runner := ThemeRegistryScript.get_player_profile("nature", runner_id)
	for child in _runner_avatar.get_children():
		child.queue_free()
	_runner_avatar.add_child(_make_runner_avatar(runner_id, str(runner.get("title", "")), Rect2(Vector2.ZERO, _runner_avatar.size)))
	_runner_title.text = str(runner.get("title", ""))
	_runner_subtitle.text = str(runner.get("subtitle", ""))


func refresh_selected_runner() -> void:
	_refresh_runner_preview()
	_refresh_summary()


func refresh_summary() -> void:
	_refresh_summary()


func _on_start_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	var player_name := _name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = MenuFlowCatalog.DEFAULT_PLAYER_NAME
	var quiz_style := _selected_quiz_style if _selected_mode == "quiz" else MenuFlowCatalog.DEFAULT_QUIZ_STYLE
	start_requested.emit(player_name, _selected_difficulty, _selected_mode, quiz_style)


func _apply_quiz_style_layout() -> void:
	var show_quiz_styles := _selected_mode == "quiz"
	if _quiz_style_label:
		_quiz_style_label.visible = show_quiz_styles
	if _quiz_style_leaf:
		_quiz_style_leaf.visible = show_quiz_styles
	if _quiz_style_row:
		_quiz_style_row.visible = show_quiz_styles

	var difficulty_label_y := 514.0 if show_quiz_styles else 442.0
	var difficulty_button_y := 544.0 if show_quiz_styles else 472.0
	var runner_label_y := 612.0 if show_quiz_styles else 544.0
	var runner_panel_y := 638.0 if show_quiz_styles else 572.0

	_move_field_label(_difficulty_field_label, "DifficultyLeaf", Vector2(382, difficulty_label_y))
	for button in _difficulty_buttons.values():
		if button is Button:
			(button as Button).position.y = difficulty_button_y

	_move_field_label(_runner_preview_label, "RunnerPreviewLeaf", Vector2(382, runner_label_y))
	if _runner_panel:
		_runner_panel.position.y = runner_panel_y
	if _runner_avatar:
		_runner_avatar.position.y = runner_panel_y + 18.0
	if _runner_title:
		_runner_title.position.y = runner_panel_y + 32.0
	if _runner_subtitle:
		_runner_subtitle.position.y = runner_panel_y + 79.0
	if _choose_runner_button:
		_choose_runner_button.position.y = runner_panel_y + 126.0


func _move_field_label(label: Label, leaf_name: String, pos: Vector2) -> void:
	if label:
		label.position = pos
	var leaf := _stage.get_node_or_null(leaf_name) as TextureRect
	if leaf:
		leaf.position = pos + FIELD_LEAF_OFFSET


func _add_panel(rect: Rect2, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.95, 0.82, 0.16), Color(0.56, 0.40, 0.21, 0.58), 2, radius, false))
	_stage.add_child(panel)
	return panel


func _add_ribbon(text: String, pos: Vector2, size: Vector2) -> void:
	_add_texture(_stage, "%sRibbon" % text.replace(" ", ""), ASSET_ROOT + "green-board.png", Rect2(pos, size))
	var label := _make_label(text, 24, Color("FFF8DD"))
	label.position = pos + Vector2(46, 0)
	label.size = Vector2(size.x - 70, size.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(label)
	_add_texture(_stage, "%sLeaf" % text.replace(" ", ""), ASSET_ROOT + "leaf.png", Rect2(pos + Vector2(24, 15), Vector2(22, 26)))


func _add_field_label(text: String, pos: Vector2) -> Label:
	var label := _make_label(text, 18, TEXT_DARK)
	label.position = pos
	label.size = Vector2(180, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_stage.add_child(label)
	_add_texture(_stage, "%sLeaf" % text.replace(" ", ""), ASSET_ROOT + "leaf.png", Rect2(pos + FIELD_LEAF_OFFSET, FIELD_LEAF_SIZE))
	return label


func _add_summary_line(y: float) -> void:
	var line := ColorRect.new()
	line.position = Vector2(1008, y)
	line.size = Vector2(262, 1.5)
	line.color = Color(0.52, 0.40, 0.24, 0.22)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(line)


func _make_selector_button(text: String, rect: Rect2, selected: bool, parent: Control = null, font_size: int = 20) -> Button:
	var host := parent if parent else _stage
	var button := _make_image_button("Selector_%s" % text, ASSET_ROOT + ("green-selector.png" if selected else "nomral-selector.png"), rect, host)
	button.set_meta("selected", selected)
	_add_button_label(button, text, font_size, Color("FFF8DD") if selected else TEXT_BROWN, Vector2(18, 0), Vector2(rect.size.x - 26, rect.size.y))
	return button


func _set_selector_selected(button: Button, selected: bool) -> void:
	button.set_meta("selected", selected)
	_set_button_texture(button, ASSET_ROOT + ("green-selector.png" if selected else "nomral-selector.png"))
	var label := button.get_node_or_null("Label") as Label
	if label:
		label.add_theme_color_override("font_color", Color("FFF8DD") if selected else TEXT_BROWN)


func _make_image_button(node_name: String, texture_path: String, rect: Rect2, parent: Control = null) -> Button:
	var host := parent if parent else _stage
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _transparent_style())
	button.add_theme_stylebox_override("hover", _transparent_style())
	button.add_theme_stylebox_override("pressed", _transparent_style())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host.add_child(button)

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


func _make_image_button_region(node_name: String, texture_path: String, rect: Rect2, region: Rect2, parent: Control = null) -> Button:
	var button := _make_image_button(node_name, texture_path, rect, parent)
	var art := button.get_node_or_null("Art") as TextureRect
	if art:
		art.texture = _load_region_texture(texture_path, region)
	return button


func _add_button_label(button: Button, text: String, size: int, color: Color, pos: Vector2, label_size: Vector2) -> Label:
	var label := _make_label(text, size, color)
	label.name = "Label"
	label.position = pos
	label.size = label_size
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
	badge.size = Vector2(diameter, diameter)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(badge)

	var coin := Panel.new()
	coin.anchors_preset = Control.PRESET_FULL_RECT
	coin.anchor_right = 1.0
	coin.anchor_bottom = 1.0
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.add_theme_stylebox_override("panel", _panel_style(GOLD, Color("A66A11"), 2, int(diameter * 0.5), true))
	badge.add_child(coin)

	var glyph := _make_label("$", int(maxf(11.0, diameter * 0.45)), Color("FFF1A8"))
	glyph.anchors_preset = Control.PRESET_FULL_RECT
	glyph.anchor_right = 1.0
	glyph.anchor_bottom = 1.0
	badge.add_child(glyph)
	return badge


func _add_play_icon(parent: Control, pos: Vector2, size: float) -> void:
	var circle := Panel.new()
	circle.position = pos
	circle.size = Vector2(size, size)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", _panel_style(Color("FFF7E2"), Color("295127"), 2, int(size * 0.5), false))
	parent.add_child(circle)

	var tri := Polygon2D.new()
	tri.position = pos + Vector2(size * 0.40, size * 0.29)
	tri.polygon = PackedVector2Array([Vector2(0, 0), Vector2(0, size * 0.42), Vector2(size * 0.35, size * 0.21)])
	tri.color = GREEN
	parent.add_child(tri)


func _add_x_icon(parent: Control, pos: Vector2, size: float) -> void:
	var circle := Panel.new()
	circle.position = pos
	circle.size = Vector2(size, size)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", _panel_style(Color("5B4024"), Color("5B4024"), 0, int(size * 0.5), false))
	parent.add_child(circle)

	var label := _make_label("X", int(size * 0.62), Color("FFF7E2"))
	label.position = pos
	label.size = Vector2(size, size)
	parent.add_child(label)


func _make_runner_avatar(runner_id: String, title: String, rect: Rect2) -> Control:
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
	bg.add_theme_stylebox_override("panel", _panel_style(accent.lightened(0.56), accent.darkened(0.25), 3, 18, false))
	avatar.add_child(bg)

	var body := Panel.new()
	body.position = Vector2(rect.size.x * 0.38, rect.size.y * 0.38)
	body.size = Vector2(rect.size.x * 0.24, rect.size.y * 0.34)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_stylebox_override("panel", _panel_style(accent, accent.darkened(0.25), 2, 14, true))
	avatar.add_child(body)

	var head := Panel.new()
	head.position = Vector2(rect.size.x * 0.40, rect.size.y * 0.16)
	head.size = Vector2(rect.size.x * 0.20, rect.size.x * 0.20)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_stylebox_override("panel", _panel_style(Color("282A24"), Color("151611"), 2, int(rect.size.x * 0.10), true))
	avatar.add_child(head)

	var brim := Panel.new()
	brim.position = Vector2(rect.size.x * 0.31, rect.size.y * 0.34)
	brim.size = Vector2(rect.size.x * 0.38, rect.size.y * 0.07)
	brim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brim.add_theme_stylebox_override("panel", _panel_style(Color("FFF1CA"), accent.darkened(0.15), 1, 8, false))
	avatar.add_child(brim)

	var initial := title.substr(0, 1)
	var mark := _make_label(initial, 42, Color("FFF8DD"))
	mark.position = Vector2.ZERO
	mark.size = rect.size
	avatar.add_child(mark)
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
	return GREEN


func _quiz_style_display(style_id: String, fallback: String) -> String:
	match style_id:
		"math":
			return "Math"
		"arabic_huroof":
			return "Arabic"
		"bangla_english":
			return "BN->EN"
		"english_bangla":
			return "EN->BN"
	return fallback.capitalize().replace("_", " ")


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := UITheme.make_label(text, font_size, color, "nature")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if UITheme.font_display and font_size >= UITheme.FONT_HEADING:
		label.add_theme_font_override("font", UITheme.font_display)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.02, 0.16))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _panel_style(bg: Color, border: Color, border_width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if shadow:
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 4)
		style.shadow_color = Color(0.16, 0.10, 0.04, 0.22)
	return style


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	return style


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)


func _load_region_texture(path: String, region: Rect2) -> Texture2D:
	var base := _load_texture(path)
	if base == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = base
	atlas.region = region
	return atlas

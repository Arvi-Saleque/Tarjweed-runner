extends Control

signal back_pressed

const ASSET_ROOT := "res://assets/UI/leaderboard/"
const BASE_SIZE := Vector2(1672.0, 941.0)

const _COL_TEXT := Color("143D1E")
const _COL_SOFT := Color("56644F")
const _COL_GOLD := Color("D9911E")
const _COL_EASY := Color("24A647")
const _COL_MEDIUM := Color("E89019")
const _COL_HARD := Color("D92727")

const _MODE_LABELS := {
	"normal": "Normal",
	"quiz": "Quiz",
	# "pronunciation": "Pronun.",  # Pronunciation UI hidden
}

const _MODE_CHOICES := [
	{"label": "ALL MODES", "value": ""},
	{"label": "NORMAL", "value": "normal"},
	{"label": "QUIZ", "value": "quiz"},
	# {"label": "PRONUN.", "value": "pronunciation"},  # Pronunciation UI hidden
]

const _DIFF_CHOICES := [
	{"label": "ALL LEVELS", "value": ""},
	{"label": "EASY", "value": "easy"},
	{"label": "MEDIUM", "value": "medium"},
	{"label": "HARD", "value": "hard"},
]

var _stage: Control
var _table_body: VBoxContainer
var _loading_label: Label
var _local_btn: Button
var _global_btn: Button
var _mode_btn: Button
var _diff_btn: Button
var _cursor: Node2D

var _active_tab := "local"
var _mode_index := 0
var _diff_index := 0
var _filter_mode := ""
var _filter_diff := ""
var _global_entries: Array[Dictionary] = []


func _ready() -> void:
	theme = preload("res://ui/theme/nature_theme.tres")
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_layout()
	_build_cursor()
	_layout_stage()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_refresh_rows()


func _process(_delta: float) -> void:
	if _cursor:
		_cursor.position = get_local_mouse_position() + Vector2(4.0, 4.0)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_stage()


func _build_layout() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := TextureRect.new()
	bg.name = "LeaderboardBackground"
	bg.texture = _load_texture(ASSET_ROOT + "bg.png")
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_stage = Control.new()
	_stage.name = "LeaderboardStage"
	_stage.size = BASE_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_add_texture(_stage, "MainCard", ASSET_ROOT + "leader-card.png", Rect2(185, 30, 1300, 875))
	_build_left_column()
	_build_board()


func _layout_stage() -> void:
	if _stage == null:
		return
	var viewport_size := get_viewport_rect().size
	var stage_scale := minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	_stage.size = BASE_SIZE
	_stage.scale = Vector2(stage_scale, stage_scale)
	_stage.position = (viewport_size - BASE_SIZE * stage_scale) * 0.5


func _build_left_column() -> void:
	_add_texture(_stage, "SummaryPanel", ASSET_ROOT + "left-panel.png", Rect2(292, 292, 352, 520))

	var summary := _make_label("Summary", 34, _COL_TEXT)
	summary.position = Vector2(382, 326)
	summary.size = Vector2(170, 42)
	_stage.add_child(summary)
	_add_texture(_stage, "SummaryLeafLeft", ASSET_ROOT + "left-leaf.png", Rect2(352, 333, 42, 24))
	_add_texture(_stage, "SummaryLeafRight", ASSET_ROOT + "right-leaf.png", Rect2(548, 333, 42, 24))

	_add_texture(_stage, "CoinPanel", ASSET_ROOT + "coin-panel.png", Rect2(324, 382, 294, 110))
	_add_coin_badge(_stage, Vector2(352, 409), 52.0)

	var wallet_title := _make_label("Coin Wallet", 27, _COL_TEXT)
	wallet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	wallet_title.position = Vector2(424, 401)
	wallet_title.size = Vector2(170, 34)
	_stage.add_child(wallet_title)

	var wallet_value := _make_label("Saved coins: %d" % SaveManager.get_wallet_coins(), 18, Color("3F321F"))
	wallet_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	wallet_value.position = Vector2(426, 438)
	wallet_value.size = Vector2(170, 28)
	_stage.add_child(wallet_value)

	var back := _add_image_button("BackButton", ASSET_ROOT + "back-button.png", Rect2(360, 560, 230, 72))
	back.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		back_pressed.emit()
	)
	var back_label := _make_label("Back", 28, _COL_TEXT)
	back_label.position = Vector2(0, 0)
	back_label.size = back.size
	back.add_child(back_label)


func _build_board() -> void:
	var title := _make_label("Top Runs", 31, _COL_TEXT)
	title.position = Vector2(928, 122)
	title.size = Vector2(190, 44)
	_stage.add_child(title)
	_add_texture(_stage, "TopLeafLeft", ASSET_ROOT + "left-leaf.png", Rect2(884, 133, 38, 22))
	_add_texture(_stage, "TopLeafRight", ASSET_ROOT + "right-leaf.png", Rect2(1110, 133, 38, 22))

	_local_btn = _add_image_button("LocalTab", ASSET_ROOT + "green-button.png", Rect2(735, 170, 220, 62))
	_local_btn.pressed.connect(_on_tab_local)
	_add_button_label(_local_btn, "My Runs", 25, Color("FFF8DD"))

	_global_btn = _add_image_button("GlobalTab", ASSET_ROOT + "global-butotn.png", Rect2(975, 170, 220, 62))
	_global_btn.pressed.connect(_on_tab_global)
	_add_button_label(_global_btn, "Global", 24, _COL_TEXT)

	var mode_lbl := _make_label("Mode:", 18, Color("2C3624"))
	mode_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mode_lbl.position = Vector2(738, 261)
	mode_lbl.size = Vector2(60, 28)
	_stage.add_child(mode_lbl)

	_mode_btn = _add_dropdown_button("ModeDropdown", Rect2(795, 246, 215, 50), "ALL MODES")
	_mode_btn.pressed.connect(_cycle_mode_filter)

	var diff_lbl := _make_label("Difficulty:", 18, Color("2C3624"))
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	diff_lbl.position = Vector2(1040, 261)
	diff_lbl.size = Vector2(96, 28)
	_stage.add_child(diff_lbl)

	_diff_btn = _add_dropdown_button("DifficultyDropdown", Rect2(1132, 246, 206, 50), "ALL LEVELS")
	_diff_btn.pressed.connect(_cycle_diff_filter)

	_build_header()

	_loading_label = _make_label("", 21, _COL_SOFT)
	_loading_label.position = Vector2(706, 466)
	_loading_label.size = Vector2(660, 90)
	_loading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_loading_label.visible = false
	_stage.add_child(_loading_label)

	var scroll := ScrollContainer.new()
	scroll.name = "LeaderboardRows"
	scroll.position = Vector2(694, 374)
	scroll.size = Vector2(692, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_stage.add_child(scroll)

	_table_body = VBoxContainer.new()
	_table_body.custom_minimum_size = Vector2(670, 0)
	_table_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_table_body)

	_add_arrow_shape(_stage, Vector2(1385, 360), 18.0, false)
	_add_arrow_shape(_stage, Vector2(1385, 775), 18.0, true)
	_update_tab_visuals()


func _build_cursor() -> void:
	_cursor = Node2D.new()
	_cursor.name = "LeaderboardCursor"
	_cursor.z_index = 1000
	add_child(_cursor)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, 24),
		Vector2(6, 18),
		Vector2(10, 28),
		Vector2(15, 26),
		Vector2(11, 16),
		Vector2(20, 16),
	])
	body.color = Color("FFF7E2")
	_cursor.add_child(body)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(0, 24),
		Vector2(6, 18),
		Vector2(10, 28),
		Vector2(15, 26),
		Vector2(11, 16),
		Vector2(20, 16),
		Vector2(0, 0),
	])
	outline.width = 2.0
	outline.default_color = Color("244124")
	_cursor.add_child(outline)


func _build_header() -> void:
	var columns := [
		{"text": "Rank", "x": 718, "w": 80},
		{"text": "Name", "x": 810, "w": 145},
		{"text": "Mode", "x": 950, "w": 110},
		{"text": "Difficulty", "x": 1052, "w": 120},
		{"text": "Distance", "x": 1168, "w": 115},
		{"text": "Coins", "x": 1288, "w": 80},
	]

	for column in columns:
		var label := _make_label(str(column["text"]), 18, Color("244124"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.position = Vector2(float(column["x"]), 315)
		label.size = Vector2(float(column["w"]), 30)
		_stage.add_child(label)

	var line := ColorRect.new()
	line.position = Vector2(704, 352)
	line.size = Vector2(660, 2)
	line.color = Color(0.55, 0.40, 0.24, 0.34)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(line)


func _on_tab_local() -> void:
	if _active_tab == "local":
		return
	_active_tab = "local"
	_update_tab_visuals()
	_refresh_rows()


func _on_tab_global() -> void:
	if _active_tab == "global":
		return
	_active_tab = "global"
	_update_tab_visuals()
	_refresh_rows()


func _cycle_mode_filter() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_mode_index = (_mode_index + 1) % _MODE_CHOICES.size()
	_filter_mode = str((_MODE_CHOICES[_mode_index] as Dictionary).get("value", ""))
	_set_dropdown_label(_mode_btn, str((_MODE_CHOICES[_mode_index] as Dictionary).get("label", "ALL MODES")))
	_refresh_rows()


func _cycle_diff_filter() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_diff_index = (_diff_index + 1) % _DIFF_CHOICES.size()
	_filter_diff = str((_DIFF_CHOICES[_diff_index] as Dictionary).get("value", ""))
	_set_dropdown_label(_diff_btn, str((_DIFF_CHOICES[_diff_index] as Dictionary).get("label", "ALL LEVELS")))
	_refresh_rows()


func _update_tab_visuals() -> void:
	if _local_btn == null or _global_btn == null:
		return
	_set_button_texture(_local_btn, ASSET_ROOT + ("green-button.png" if _active_tab == "local" else "global-butotn.png"))
	_set_button_texture(_global_btn, ASSET_ROOT + ("green-button.png" if _active_tab == "global" else "global-butotn.png"))
	_set_button_label_color(_local_btn, Color("FFF8DD") if _active_tab == "local" else _COL_TEXT)
	_set_button_label_color(_global_btn, Color("FFF8DD") if _active_tab == "global" else _COL_TEXT)


func _refresh_rows() -> void:
	if _active_tab == "local":
		_loading_label.visible = false
		_populate_rows(SaveManager.get_leaderboard_entries_filtered(_filter_mode, _filter_diff))
		return

	_clear_table()
	_loading_label.text = "Loading global leaderboard..."
	_loading_label.visible = true
	LeaderboardService.fetch_global(func(entries: Array, success: bool):
		if not is_instance_valid(self):
			return
		_loading_label.visible = false
		if not success:
			_loading_label.text = "Could not reach the global leaderboard."
			_loading_label.visible = true
			return
		_global_entries.clear()
		for entry in entries:
			if entry is Dictionary:
				_global_entries.append(entry as Dictionary)
		_populate_rows(_apply_filter_to(_global_entries))
	)


func _apply_filter_to(entries: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in entries:
		if not entry is Dictionary:
			continue
		var typed := entry as Dictionary
		var mode := str(typed.get("mode", "normal"))
		var diff := str(typed.get("difficulty", "medium"))
		if not _filter_mode.is_empty() and mode != _filter_mode:
			continue
		if not _filter_diff.is_empty() and diff != _filter_diff:
			continue
		out.append(typed)
	return out


func _populate_rows(entries: Array) -> void:
	_clear_table()
	if entries.is_empty():
		var msg := "No runs recorded yet for this filter." if _active_tab == "local" else "No global entries match this filter."
		var empty := _make_label(msg, 22, _COL_SOFT)
		empty.custom_minimum_size = Vector2(650, 120)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_table_body.add_child(empty)
		return

	var limit := mini(entries.size(), 30)
	for i in limit:
		if entries[i] is Dictionary:
			_table_body.add_child(_make_entry_row(i + 1, entries[i] as Dictionary))


func _clear_table() -> void:
	if _table_body == null:
		return
	for child in _table_body.get_children():
		child.queue_free()


func _make_entry_row(rank: int, entry: Dictionary) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(670, 72)
	row.size = Vector2(670, 72)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_add_texture(row, "RowArt", ASSET_ROOT + "leader-row.png", Rect2(0, 0, 660, 72))

	var rank_label := _make_label("#%d" % rank, 23, _COL_GOLD)
	rank_label.position = Vector2(20, 16)
	rank_label.size = Vector2(78, 36)
	row.add_child(rank_label)

	var name := str(entry.get("name", "Explorer"))
	_add_cell(row, name, 110, 16, 145, _COL_TEXT, 20)

	var raw_mode := str(entry.get("mode", "normal"))
	_add_cell(row, _MODE_LABELS.get(raw_mode, raw_mode.capitalize()), 258, 16, 98, _COL_TEXT, 18)

	var raw_diff := str(entry.get("difficulty", "medium"))
	_add_cell(row, raw_diff.capitalize(), 366, 16, 110, _diff_color(raw_diff), 18)

	_add_cell(row, "%dm" % int(entry.get("distance", 0)), 480, 16, 105, _COL_TEXT, 18)

	_add_coin_badge(row, Vector2(582, 24), 22.0)
	_add_cell(row, str(entry.get("coins", 0)), 608, 16, 58, Color("4A3110"), 18)

	return row


func _add_cell(parent: Control, text: String, x: float, y: float, width: float, color: Color, size: int) -> void:
	var label := _make_label(text, size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.position = Vector2(x, y)
	label.size = Vector2(width, 40)
	label.clip_text = true
	parent.add_child(label)


func _diff_color(diff: String) -> Color:
	match diff:
		"easy":
			return _COL_EASY
		"medium":
			return _COL_MEDIUM
		"hard":
			return _COL_HARD
	return _COL_SOFT


func _add_dropdown_button(node_name: String, rect: Rect2, text: String) -> Button:
	var button := _add_image_button(node_name, ASSET_ROOT + "dropdown.png", rect)
	var label := _make_label(text, 20, _COL_TEXT)
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(18, 0)
	label.size = Vector2(rect.size.x - 52, rect.size.y)
	button.add_child(label)

	_add_arrow_shape(button, Vector2(rect.size.x - 38, 17), 17.0, true)
	return button


func _set_dropdown_label(button: Button, text: String) -> void:
	var label := button.get_node_or_null("Label") as Label
	if label:
		label.text = text


func _add_button_label(button: Button, text: String, size: int, color: Color) -> void:
	var label := _make_label(text, size, color)
	label.name = "Label"
	label.position = Vector2.ZERO
	label.size = button.size
	button.add_child(label)


func _set_button_label_color(button: Button, color: Color) -> void:
	var label := button.get_node_or_null("Label") as Label
	if label:
		label.add_theme_color_override("font_color", color)


func _set_button_texture(button: Button, texture_path: String) -> void:
	var art := button.get_node_or_null("Art") as TextureRect
	if art:
		art.texture = _load_texture(texture_path)


func _add_image_button(node_name: String, texture_path: String, rect: Rect2) -> Button:
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
	_stage.add_child(button)

	var art := _add_texture(button, "Art", texture_path, Rect2(Vector2.ZERO, rect.size))
	art.stretch_mode = TextureRect.STRETCH_SCALE

	button.mouse_entered.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_hover)
		var tween := button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.02, 1.02), 0.10)
	)
	button.mouse_exited.connect(func():
		var tween := button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.10)
	)
	return button


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
	coin.add_theme_stylebox_override("panel", _round_style(Color("E9B32F"), Color("A76B13"), diameter * 0.5, maxf(1.0, diameter * 0.08)))
	badge.add_child(coin)

	var inner := Panel.new()
	inner.position = Vector2(diameter * 0.18, diameter * 0.18)
	inner.size = Vector2(diameter * 0.64, diameter * 0.64)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", _round_style(Color("F8D35A"), Color("C58317"), diameter * 0.32, maxf(1.0, diameter * 0.05)))
	badge.add_child(inner)

	var glyph := _make_label("$", int(maxf(11.0, diameter * 0.46)), Color("FFF5B6"))
	glyph.position = Vector2.ZERO
	glyph.size = badge.size
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(glyph)
	return badge


func _add_arrow_shape(parent: Control, pos: Vector2, size: float, points_down: bool) -> Node2D:
	var arrow := Node2D.new()
	arrow.position = pos
	arrow.z_index = 2
	parent.add_child(arrow)

	var points := PackedVector2Array()
	if points_down:
		points = PackedVector2Array([
			Vector2(0, 0),
			Vector2(size, 0),
			Vector2(size * 0.5, size * 0.68),
		])
	else:
		points = PackedVector2Array([
			Vector2(size * 0.5, 0),
			Vector2(0, size * 0.68),
			Vector2(size, size * 0.68),
		])

	var fill := Polygon2D.new()
	fill.polygon = points
	fill.color = Color("2F6B3B")
	arrow.add_child(fill)

	var outline_points := PackedVector2Array()
	for point in points:
		outline_points.append(point)
	outline_points.append(points[0])

	var outline := Line2D.new()
	outline.points = outline_points
	outline.width = maxf(1.5, size * 0.10)
	outline.default_color = Color("1D4728")
	arrow.add_child(outline)
	return arrow


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := UITheme.make_label(text, font_size, color, "nature")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if UITheme.font_display:
		label.add_theme_font_override("font", UITheme.font_display)
	label.add_theme_color_override("font_shadow_color", Color(0.10, 0.06, 0.02, 0.18))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	return style


func _round_style(bg: Color, border: Color, radius: float, border_width: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	var radius_i := int(radius)
	style.corner_radius_top_left = radius_i
	style.corner_radius_top_right = radius_i
	style.corner_radius_bottom_left = radius_i
	style.corner_radius_bottom_right = radius_i
	var border_i := int(border_width)
	style.border_width_left = border_i
	style.border_width_right = border_i
	style.border_width_top = border_i
	style.border_width_bottom = border_i
	style.shadow_color = Color(0.16, 0.09, 0.02, 0.22)
	style.shadow_size = int(maxf(1.0, radius * 0.12))
	return style


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D

	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)

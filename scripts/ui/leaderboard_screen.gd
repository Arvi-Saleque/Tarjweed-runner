extends Control

signal back_pressed

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")

# Column widths
const _W_RANK  := 70.0
const _W_NAME  := 170.0
const _W_MODE  := 110.0
const _W_DIFF  := 110.0
const _W_DIST  := 130.0
const _W_COINS := 100.0

# Difficulty badge colours
const _COL_EASY        := Color("4CAF50")
const _COL_MEDIUM      := Color("FF9800")
const _COL_HARD        := Color("F44336")
const _COL_DEFAULT_DIFF := Color("888888")

# Mode short labels
const _MODE_LABELS := {
	"normal":        "Normal",
	"quiz":          "Quiz",
	"pronunciation": "Pronun.",
}

# Filter / tab state
var _filter_mode := ""
var _filter_diff := ""
var _active_tab  := "local"   # "local" | "global"

# Cached global entries (re-fetched each time Global tab opens)
var _global_entries: Array[Dictionary] = []
var _global_loading := false

# UI node refs
var _table_body: VBoxContainer
var _loading_label: Label
var _tab_local_btn: Button
var _tab_global_btn: Button
var _mode_option: OptionButton
var _diff_option: OptionButton


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_build_layout()
	_refresh_rows()


func _build_layout() -> void:
	var shell := NatureMenuStyle.make_shell(
		self,
		"Leaderboard",
		"Track your personal bests and compete with players worldwide.",
		1240.0,
		760.0
	)
	var content := shell["content"] as HBoxContainer

	# ── Left sidebar ────────────────────────────────────────────────────────
	var left := NatureMenuStyle.make_card("Summary", "", Vector2(280, 620))
	content.add_child(left)
	var left_body := left.get_meta("body") as VBoxContainer

	var wallet := NatureMenuStyle.make_card("Coin Wallet", "", Vector2(0, 120), true)
	left_body.add_child(wallet)
	var wallet_body := wallet.get_meta("body") as VBoxContainer
	var wallet_label := NatureMenuStyle.make_coin_label("Saved coins: %d" % SaveManager.get_wallet_coins())
	wallet_body.add_child(wallet_label)

	var back_btn := UITheme.make_button("Back", null, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	back_btn.custom_minimum_size = Vector2(150, 64)
	UITheme.align_text_button_left(back_btn, false)
	back_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		back_pressed.emit()
	)
	left_body.add_child(back_btn)

	var board := NatureMenuStyle.make_card("Top Runs", "", Vector2(860, 620))
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(board)
	var board_body := board.get_meta("body") as VBoxContainer
	board_body.add_theme_constant_override("separation", 10)

	# ── Tab toggle ──────────────────────────────────────────────────────────
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	board_body.add_child(tab_row)

	_tab_local_btn = _make_tab_button("My Runs", true)
	_tab_local_btn.pressed.connect(_on_tab_local)
	tab_row.add_child(_tab_local_btn)

	_tab_global_btn = _make_tab_button("Global", false)
	_tab_global_btn.pressed.connect(_on_tab_global)
	tab_row.add_child(_tab_global_btn)

	# ── Filter bar ──────────────────────────────────────────────────────────
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 10)
	board_body.add_child(filter_row)

	var mode_lbl := UITheme.make_label("Mode:", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	filter_row.add_child(mode_lbl)

	_mode_option = OptionButton.new()
	_mode_option.custom_minimum_size = Vector2(148, 36)
	_mode_option.add_item("All Modes", 0)
	_mode_option.add_item("Normal",    1)
	_mode_option.add_item("Quiz",      2)
	_mode_option.add_item("Pronun.",   3)
	_mode_option.select(0)
	_mode_option.item_selected.connect(_on_mode_filter_changed)
	filter_row.add_child(_mode_option)

	var diff_lbl := UITheme.make_label("Difficulty:", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	filter_row.add_child(diff_lbl)

	_diff_option = OptionButton.new()
	_diff_option.custom_minimum_size = Vector2(148, 36)
	_diff_option.add_item("All Levels", 0)
	_diff_option.add_item("Easy",       1)
	_diff_option.add_item("Medium",     2)
	_diff_option.add_item("Hard",       3)
	_diff_option.select(0)
	_diff_option.item_selected.connect(_on_diff_filter_changed)
	filter_row.add_child(_diff_option)

	# ── Column header ───────────────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	board_body.add_child(header)
	header.add_child(_make_column_label("Rank",       _W_RANK))
	header.add_child(_make_column_label("Name",       _W_NAME))
	header.add_child(_make_column_label("Mode",       _W_MODE))
	header.add_child(_make_column_label("Difficulty", _W_DIFF))
	header.add_child(_make_column_label("Distance",   _W_DIST))
	header.add_child(_make_column_label("Coins",      _W_COINS))

	var divider := HSeparator.new()
	board_body.add_child(divider)

	# Loading indicator (visible only during Global fetch)
	_loading_label = UITheme.make_label(
		"",
		UITheme.FONT_BODY,
		UITheme.get_color("text_dim", NatureMenuStyle.SKIN),
		NatureMenuStyle.SKIN
	)
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.visible = false
	board_body.add_child(_loading_label)

	# Scrollable table body
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_body.add_child(scroll)

	_table_body = VBoxContainer.new()
	_table_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_table_body)


# ---------------------------------------------------------------------------
# Tab callbacks
# ---------------------------------------------------------------------------

func _on_tab_local() -> void:
	if _active_tab == "local":
		return
	_active_tab = "local"
	_update_tab_visuals()
	_refresh_rows()


func _on_tab_global() -> void:
	_active_tab = "global"
	_update_tab_visuals()
	_refresh_rows()


func _update_tab_visuals() -> void:
	var is_local := _active_tab == "local"
	_tab_local_btn.modulate = Color.WHITE if is_local else Color(1, 1, 1, 0.55)
	_tab_global_btn.modulate = Color.WHITE if not is_local else Color(1, 1, 1, 0.55)


# ---------------------------------------------------------------------------
# Filter callbacks
# ---------------------------------------------------------------------------

func _on_mode_filter_changed(index: int) -> void:
	match index:
		0: _filter_mode = ""
		1: _filter_mode = "normal"
		2: _filter_mode = "quiz"
		3: _filter_mode = "pronunciation"
	_refresh_rows()


func _on_diff_filter_changed(index: int) -> void:
	match index:
		0: _filter_diff = ""
		1: _filter_diff = "easy"
		2: _filter_diff = "medium"
		3: _filter_diff = "hard"
	_refresh_rows()


# ---------------------------------------------------------------------------
# Row population
# ---------------------------------------------------------------------------

func _refresh_rows() -> void:
	if _active_tab == "local":
		_loading_label.visible = false
		var entries := SaveManager.get_leaderboard_entries_filtered(_filter_mode, _filter_diff)
		_populate_rows(entries)
	else:
		_clear_table()
		_loading_label.text = "Loading global leaderboard..."
		_loading_label.visible = true
		_global_loading = true
		LeaderboardService.fetch_global(func(entries: Array, success: bool):
			_global_loading = false
			if not is_instance_valid(self):
				return
			_loading_label.visible = false
			if not success:
				_loading_label.text = "Could not reach the global leaderboard. Check your connection."
				_loading_label.visible = true
				return
			if entries.is_empty():
				_loading_label.text = "No global entries yet — complete a run to be the first!"
				_loading_label.visible = true
				return
			_global_entries.clear()
			for e in entries:
				if e is Dictionary:
					_global_entries.append(e as Dictionary)
			_populate_rows(_apply_filter_to(_global_entries))
		)


func _apply_filter_to(entries: Array) -> Array[Dictionary]:
	if _filter_mode.is_empty() and _filter_diff.is_empty():
		var typed: Array[Dictionary] = []
		for e in entries:
			if e is Dictionary:
				typed.append(e as Dictionary)
		return typed
	var out: Array[Dictionary] = []
	for e in entries:
		if not e is Dictionary:
			continue
		var m: String = str((e as Dictionary).get("mode", "normal"))
		var d: String = str((e as Dictionary).get("difficulty", "medium"))
		if not _filter_mode.is_empty() and m != _filter_mode:
			continue
		if not _filter_diff.is_empty() and d != _filter_diff:
			continue
		out.append(e as Dictionary)
	return out


func _populate_rows(entries: Array) -> void:
	_clear_table()
	if entries.is_empty():
		var msg: String = "No runs recorded yet for this filter." if _active_tab == "local" \
			else "No global entries match this filter."
		var empty_label := UITheme.make_label(
			msg,
			UITheme.FONT_BODY,
			UITheme.get_color("text_dim", NatureMenuStyle.SKIN),
			NatureMenuStyle.SKIN
		)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_table_body.add_child(empty_label)
		return

	for i in entries.size():
		if entries[i] is Dictionary:
			_table_body.add_child(_make_entry_row(i + 1, entries[i] as Dictionary))


func _clear_table() -> void:
	for child in _table_body.get_children():
		child.queue_free()


# ---------------------------------------------------------------------------
# Row / cell builders
# ---------------------------------------------------------------------------

func _make_entry_row(rank: int, entry: Dictionary) -> PanelContainer:
	var row := NatureMenuStyle.make_card("", "", Vector2(0, 80), true)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := row.get_meta("body") as VBoxContainer
	body.add_theme_constant_override("separation", 0)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	body.add_child(hbox)

	hbox.add_child(_make_value_label("#%d" % rank, _W_RANK, UITheme.get_color("accent", NatureMenuStyle.SKIN)))
	hbox.add_child(_make_value_label(str(entry.get("name", "Explorer")), _W_NAME, UITheme.get_color("text_ink", NatureMenuStyle.SKIN)))

	var raw_mode: String = str(entry.get("mode", "normal"))
	var mode_display: String = _MODE_LABELS.get(raw_mode, raw_mode.capitalize())
	hbox.add_child(_make_value_label(mode_display, _W_MODE, UITheme.get_color("text_ink", NatureMenuStyle.SKIN)))

	var raw_diff: String = str(entry.get("difficulty", "medium"))
	hbox.add_child(_make_value_label(raw_diff.capitalize(), _W_DIFF, _diff_color(raw_diff)))

	hbox.add_child(_make_value_label("%dm" % int(entry.get("distance", 0)), _W_DIST, UITheme.get_color("text_ink", NatureMenuStyle.SKIN)))
	hbox.add_child(_make_value_label(str(entry.get("coins", 0)), _W_COINS, NatureMenuStyle.COIN_GLOW))

	return row


func _diff_color(diff: String) -> Color:
	match diff:
		"easy":   return _COL_EASY
		"medium": return _COL_MEDIUM
		"hard":   return _COL_HARD
	return _COL_DEFAULT_DIFF


func _make_tab_button(label: String, active: bool) -> Button:
	var btn := UITheme.make_button(label, null, UITheme.FONT_SMALL, "secondary", NatureMenuStyle.SKIN)
	btn.custom_minimum_size = Vector2(120, 40)
	btn.modulate = Color.WHITE if active else Color(1, 1, 1, 0.55)
	return btn


func _make_column_label(text: String, width: float) -> Control:
	var label := UITheme.make_label(text, UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	label.custom_minimum_size = Vector2(width, 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _make_value_label(text: String, width: float, color: Color) -> Control:
	var label := UITheme.make_label(text, UITheme.FONT_BODY, color, NatureMenuStyle.SKIN)
	label.custom_minimum_size = Vector2(width, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

extends Control

signal back_pressed

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")

var _table_body: VBoxContainer


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_build_layout()
	_refresh_rows()


func _build_layout() -> void:
	var shell := NatureMenuStyle.make_shell(
		self,
		"Leaderboard",
		"Top nature runs saved from the current menu flow. Entries are ranked by distance, then coins.",
		1180.0,
		760.0
	)
	var content := shell["content"] as HBoxContainer

	var left := NatureMenuStyle.make_card("Trail Records", "The current board tracks player name, distance, and collected coins.", Vector2(320, 620))
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

	var board := NatureMenuStyle.make_card("Top Runs", "Ranked by distance. Keep running to climb the board!", Vector2(780, 620))
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(board)
	var board_body := board.get_meta("body") as VBoxContainer

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	board_body.add_child(header)

	header.add_child(_make_column_label("Rank", 80))
	header.add_child(_make_column_label("Name", 220))
	header.add_child(_make_column_label("Distance", 160))
	header.add_child(_make_column_label("Coins", 120))

	var divider := HSeparator.new()
	board_body.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board_body.add_child(scroll)

	_table_body = VBoxContainer.new()
	_table_body.add_theme_constant_override("separation", 10)
	scroll.add_child(_table_body)


func _refresh_rows() -> void:
	for child in _table_body.get_children():
		child.queue_free()

	var entries := SaveManager.get_leaderboard_entries()
	if entries.is_empty():
		var empty_label := UITheme.make_label(
			"No runs recorded yet. Start a game from the new setup flow and your results will appear here.",
			UITheme.FONT_BODY,
			UITheme.get_color("text_dim", NatureMenuStyle.SKIN),
			NatureMenuStyle.SKIN
		)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_table_body.add_child(empty_label)
		return

	for index in entries.size():
		var entry := entries[index]
		_table_body.add_child(_make_entry_row(index + 1, entry))


func _make_entry_row(rank: int, entry: Dictionary) -> PanelContainer:
	var row := NatureMenuStyle.make_card("", "", Vector2(0, 92), true)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := row.get_meta("body") as VBoxContainer
	body.add_theme_constant_override("separation", 0)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	body.add_child(hbox)

	hbox.add_child(_make_value_label("#%d" % rank, 80, UITheme.get_color("accent", NatureMenuStyle.SKIN)))
	hbox.add_child(_make_value_label(str(entry.get("name", "Explorer")), 220, UITheme.get_color("text_ink", NatureMenuStyle.SKIN)))
	hbox.add_child(_make_value_label("%dm" % int(entry.get("distance", 0)), 160, UITheme.get_color("text_ink", NatureMenuStyle.SKIN)))
	hbox.add_child(_make_value_label(str(entry.get("coins", 0)), 120, NatureMenuStyle.COIN_GLOW))

	return row


func _make_column_label(text: String, width: float) -> Control:
	var label := UITheme.make_label(text, UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	label.custom_minimum_size = Vector2(width, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _make_value_label(text: String, width: float, color: Color) -> Control:
	var label := UITheme.make_label(text, UITheme.FONT_BODY, color, NatureMenuStyle.SKIN)
	label.custom_minimum_size = Vector2(width, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

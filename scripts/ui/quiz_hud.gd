extends Control

# Stable quiz HUD layout for gameplay screen
# - Top centered question panel
# - Bottom centered instruction pill
# - Bottom row of 4 answer cards

const _COL_DARK_GREEN  := Color("1E5128")
const _COL_MID_GREEN   := Color("2D7A3D")
const _COL_CREAM       := Color("FFFAE8")
const _COL_CREAM_HOVER := Color("F4F0DE")
const _COL_WHITE       := Color.WHITE
const _COL_SUCCESS     := Color("A8E063")
const _COL_ERROR       := Color("FF8A80")
const _COL_ERROR_FILL  := Color(1.0, 0.91, 0.91, 1.0)
const _COL_SELECTED    := Color("FFF1BF")
const _COL_SELECTED_BORDER := Color("D6A33C")

enum ChoiceVisualState { IDLE, HOVER, SELECTED, CORRECT, WRONG, DISABLED }

var _question_label: Label
var _choice_buttons: Array[Button] = []
var _choice_labels: Array[Label] = []
var _choice_panels: Array[PanelContainer] = []
var _choice_states: Array[int] = []
var _instructions_label: Label
var _question_panel: PanelContainer
var _hovered_choice_index: int = -1
var _highlighted_wrong_index: int = -1
var _answer_locked: bool = false


func _ready() -> void:
	if not GameManager.is_quiz_mode():
		visible = false
		return

	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_question_panel()
	_create_answer_area()

	QuizManager.question_changed.connect(_on_question_changed)
	QuizManager.answer_result.connect(_on_answer_result)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)


func _create_question_panel() -> void:
	var top_strip := Control.new()
	top_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_strip.anchor_right = 1.0
	top_strip.offset_top = 10.0
	top_strip.offset_bottom = 140.0
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_strip)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_strip.add_child(center)

	_question_panel = PanelContainer.new()
	_question_panel.custom_minimum_size = Vector2(720, 110)
	_question_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_question_panel.add_theme_stylebox_override("panel", _make_panel_style(_COL_CREAM, _COL_DARK_GREEN, 6, 28, 10))
	center.add_child(_question_panel)

	var q_center := CenterContainer.new()
	q_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	q_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_question_panel.add_child(q_center)

	_question_label = Label.new()
	_question_label.text = ""
	_question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_display:
		_question_label.add_theme_font_override("font", UITheme.font_display)
	_question_label.add_theme_font_size_override("font_size", 40)
	_question_label.add_theme_color_override("font_color", _COL_DARK_GREEN)
	q_center.add_child(_question_label)


func _create_answer_area() -> void:
	# This container sits directly below the top question panel
	var area := Control.new()
	area.set_anchors_preset(Control.PRESET_TOP_WIDE)
	area.anchor_right = 1.0
	area.offset_top = 150.0
	area.offset_bottom = 300.0
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(area)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)

	# Instruction pill
	var pill_center := CenterContainer.new()
	pill_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(pill_center)

	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", _make_panel_style(_COL_DARK_GREEN, _COL_DARK_GREEN, 0, 22, 0))
	pill_center.add_child(pill)

	var pill_margin := MarginContainer.new()
	pill_margin.add_theme_constant_override("margin_left", 24)
	pill_margin.add_theme_constant_override("margin_right", 24)
	pill_margin.add_theme_constant_override("margin_top", 8)
	pill_margin.add_theme_constant_override("margin_bottom", 8)
	pill_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(pill_margin)

	_instructions_label = Label.new()
	_instructions_label.text = "Choose the correct answer"
	_instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_instructions_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_button:
		_instructions_label.add_theme_font_override("font", UITheme.font_button)
	_instructions_label.add_theme_font_size_override("font_size", 21)
	_instructions_label.add_theme_color_override("font_color", _COL_WHITE)
	pill_margin.add_child(_instructions_label)

	# Compact answer row directly below the question
	var answers_center := CenterContainer.new()
	answers_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answers_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(answers_center)

	# same visual width zone as the question box
	var row_shell := HBoxContainer.new()
	row_shell.custom_minimum_size = Vector2(820, 0) # adjust later if needed
	row_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answers_center.add_child(row_shell)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_shell.add_child(left_spacer)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_shell.add_child(btn_row)

	for i in 4:
		var card := _create_answer_card(i)
		btn_row.add_child(card)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_shell.add_child(right_spacer)


func _create_answer_card(index: int) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(150, 84)
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.mouse_filter = Control.MOUSE_FILTER_PASS

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(_COL_CREAM, _COL_DARK_GREEN, 3, 22, 4))
	root.add_child(panel)
	_choice_panels.append(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(56, 56)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = _COL_DARK_GREEN
	badge_style.corner_radius_top_left = 28
	badge_style.corner_radius_top_right = 28
	badge_style.corner_radius_bottom_left = 28
	badge_style.corner_radius_bottom_right = 28
	badge.add_theme_stylebox_override("panel", badge_style)

	row.add_child(badge)

	var badge_center := CenterContainer.new()
	badge_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badge_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	badge_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(badge_center)

	var badge_label := Label.new()
	badge_label.text = str(index + 1)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_display:
		badge_label.add_theme_font_override("font", UITheme.font_display)
	badge_label.add_theme_font_size_override("font_size", 22)
	badge_label.add_theme_color_override("font_color", _COL_WHITE)
	badge_center.add_child(badge_label)

	var answer_lbl := Label.new()
	answer_lbl.text = "--"
	answer_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	answer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	answer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_display:
		answer_lbl.add_theme_font_override("font", UITheme.font_display)
	answer_lbl.add_theme_font_size_override("font_size", 28)
	answer_lbl.add_theme_color_override("font_color", _COL_DARK_GREEN)
	row.add_child(answer_lbl)
	_choice_labels.append(answer_lbl)

	var click_overlay := Button.new()
	click_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_overlay.anchor_right = 1.0
	click_overlay.anchor_bottom = 1.0
	click_overlay.focus_mode = Control.FOCUS_NONE
	click_overlay.text = ""
	click_overlay.flat = true
	click_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var empty_style := StyleBoxEmpty.new()
	click_overlay.add_theme_stylebox_override("normal", empty_style)
	click_overlay.add_theme_stylebox_override("hover", empty_style)
	click_overlay.add_theme_stylebox_override("pressed", empty_style)
	click_overlay.add_theme_stylebox_override("focus", empty_style)

	var idx := index
	click_overlay.pressed.connect(func(): _on_choice_pressed(idx))
	click_overlay.mouse_entered.connect(func():
		if _answer_locked:
			return
		_hovered_choice_index = idx
		_refresh_choice_styles()
	)
	click_overlay.mouse_exited.connect(func():
		if _hovered_choice_index == idx:
			_hovered_choice_index = -1
		_refresh_choice_styles()
	)

	root.add_child(click_overlay)
	_choice_buttons.append(click_overlay)
	_choice_states.append(ChoiceVisualState.IDLE)

	return root


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int, shadow_size: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_width
	s.border_width_right = border_width
	s.border_width_top = border_width
	s.border_width_bottom = border_width
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0, 0, 0, 0.14)
	s.shadow_size = shadow_size
	s.shadow_offset = Vector2(0, 3)
	return s


func _refresh_choice_styles() -> void:
	for i in range(_choice_panels.size()):
		var bg := _COL_CREAM
		var border := _COL_DARK_GREEN
		var shadow := 4
		var state: int = _choice_states[i] if i < _choice_states.size() else ChoiceVisualState.IDLE
		match state:
			ChoiceVisualState.SELECTED:
				bg = _COL_SELECTED
				border = _COL_SELECTED_BORDER
				shadow = 7
			ChoiceVisualState.DISABLED:
				bg = _COL_CREAM_HOVER
				border = _COL_MID_GREEN
				shadow = 3
			_:
				if i == _highlighted_wrong_index:
					bg = _COL_ERROR_FILL
					border = _COL_ERROR
					shadow = 6
				elif not _answer_locked and i == _hovered_choice_index:
					bg = _COL_CREAM_HOVER
					border = _COL_MID_GREEN
					shadow = 6
		_choice_panels[i].add_theme_stylebox_override("panel", _make_panel_style(bg, border, 3, 22, shadow))


func _set_choice_interactable(enabled: bool) -> void:
	for button in _choice_buttons:
		button.disabled = not enabled


func _on_choice_pressed(index: int) -> void:
	if _answer_locked:
		return
	_answer_locked = true
	_set_choice_interactable(false)
	_set_choice_state(index, ChoiceVisualState.SELECTED)
	QuizManager.call_deferred("_check_answer", index)


func _on_question_changed(question: Dictionary) -> void:
	_answer_locked = false
	_hovered_choice_index = -1
	_highlighted_wrong_index = -1
	_reset_choice_states()
	_set_choice_interactable(true)
	_refresh_choice_styles()

	if question.is_empty():
		_question_label.text = ""
		for lbl in _choice_labels:
			lbl.text = "--"
		_instructions_label.text = "Choose the correct answer"
		_instructions_label.add_theme_color_override("font_color", _COL_WHITE)
		return

	# Apply font + text direction based on script
	var q_font_id: String = question.get("question_font", "latin")
	var a_font_id: String = question.get("answer_font", "latin")
	_apply_script_font(_question_label, q_font_id, true)
	for lbl in _choice_labels:
		_apply_script_font(lbl, a_font_id, false)

	_question_label.text = question.get("text", "?")

	var choices: Array = question.get("choices", [])
	for i in range(_choice_labels.size()):
		if i < choices.size():
			_choice_labels[i].text = str(choices[i])
		else:
			_choice_labels[i].text = "--"

	_instructions_label.text = "Choose the correct answer"
	_instructions_label.add_theme_color_override("font_color", _COL_WHITE)

	_question_panel.pivot_offset = _question_panel.size * 0.5
	_question_panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_question_panel, "scale", Vector2.ONE, 0.20)


## Apply the correct font and direction to a label based on script id.
## font_id: "arabic" | "bangla" | "latin"
func _apply_script_font(lbl: Label, font_id: String, is_question: bool) -> void:
	match font_id:
		"arabic":
			if UITheme.font_arabic:
				lbl.add_theme_font_override("font", UITheme.font_arabic)
			lbl.add_theme_font_size_override("font_size", 52 if is_question else 30)
			lbl.text_direction = Control.TEXT_DIRECTION_RTL
		"bangla":
			if UITheme.font_bangla:
				lbl.add_theme_font_override("font", UITheme.font_bangla)
			lbl.add_theme_font_size_override("font_size", 44 if is_question else 26)
			lbl.text_direction = Control.TEXT_DIRECTION_LTR
		_:  # latin / math
			if UITheme.font_display:
				lbl.add_theme_font_override("font", UITheme.font_display)
			lbl.add_theme_font_size_override("font_size", 40 if is_question else 28)
			lbl.text_direction = Control.TEXT_DIRECTION_LTR


func _on_answer_result(correct: bool, choice_index: int, _correct_index: int) -> void:
	_answer_locked = true
	_set_choice_interactable(false)
	if correct:
		_instructions_label.text = "Correct!"
		_instructions_label.add_theme_color_override("font_color", _COL_SUCCESS)
		_highlighted_wrong_index = -1
	else:
		_instructions_label.text = "Try again!"
		_instructions_label.add_theme_color_override("font_color", _COL_ERROR)
		_highlighted_wrong_index = choice_index
	_refresh_choice_styles()


func _reset_choice_states() -> void:
	for i in range(_choice_states.size()):
		_choice_states[i] = ChoiceVisualState.IDLE


func _set_choice_state(selected_index: int, selected_state: int) -> void:
	for i in range(_choice_states.size()):
		_choice_states[i] = selected_state if i == selected_index else ChoiceVisualState.DISABLED
	_refresh_choice_styles()


func _on_game_paused() -> void:
	visible = false


func _on_game_resumed() -> void:
	if GameManager.is_quiz_mode():
		visible = true

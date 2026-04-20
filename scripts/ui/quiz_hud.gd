extends Control

const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")
const QUIZ_SKIN := UISkinIds.NATURE

var _question_label: Label
var _choices_container: GridContainer
var _choice_buttons: Array[Button] = []
var _feedback_label: Label
var _panel: PanelContainer
var _choices_panel: PanelContainer
var _instructions: Label


func _ready() -> void:
	if not GameManager.is_quiz_mode():
		visible = false
		return

	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_ui()

	QuizManager.question_changed.connect(_on_question_changed)
	QuizManager.answer_result.connect(_on_answer_result)


func _create_ui() -> void:
	var question_center := CenterContainer.new()
	question_center.anchors_preset = Control.PRESET_TOP_WIDE
	question_center.anchor_right = 1.0
	question_center.offset_top = 128
	question_center.offset_bottom = 236
	question_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(question_center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(380, 88)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.95, 0.88, 0.90)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	style.border_color = Color("8A5A35").darkened(0.08)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.20, 0.12, 0.04, 0.10)
	style.shadow_size = 5
	_panel.add_theme_stylebox_override("panel", style)
	question_center.add_child(_panel)

	var question_box := VBoxContainer.new()
	question_box.alignment = BoxContainer.ALIGNMENT_CENTER
	question_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(question_box)

	_question_label = UITheme.make_label("", UITheme.FONT_HEADING - 2, UITheme.get_color("text_ink", QUIZ_SKIN), QUIZ_SKIN)
	_question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	question_box.add_child(_question_label)

	var answer_center := CenterContainer.new()
	answer_center.anchors_preset = Control.PRESET_BOTTOM_WIDE
	answer_center.anchor_top = 1.0
	answer_center.anchor_right = 1.0
	answer_center.anchor_bottom = 1.0
	answer_center.offset_top = -250
	answer_center.offset_bottom = -56
	answer_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(answer_center)

	_choices_panel = PanelContainer.new()
	_choices_panel.custom_minimum_size = Vector2(360, 170)
	_choices_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var answers_style := style.duplicate() as StyleBoxFlat
	answers_style.bg_color = Color(0.97, 0.95, 0.88, 0.76)
	answers_style.content_margin_left = 18.0
	answers_style.content_margin_right = 18.0
	answers_style.content_margin_top = 16.0
	answers_style.content_margin_bottom = 14.0
	_choices_panel.add_theme_stylebox_override("panel", answers_style)
	answer_center.add_child(_choices_panel)

	var answers_vbox := VBoxContainer.new()
	answers_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	answers_vbox.add_theme_constant_override("separation", 10)
	answers_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choices_panel.add_child(answers_vbox)

	_choices_container = GridContainer.new()
	_choices_container.columns = 2
	_choices_container.add_theme_constant_override("h_separation", 16)
	_choices_container.add_theme_constant_override("v_separation", 12)
	_choices_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answers_vbox.add_child(_choices_container)

	for i in 4:
		var choice_btn := _create_choice_button(i)
		_choices_container.add_child(choice_btn)
		_choice_buttons.append(choice_btn)

	_feedback_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.get_color("primary_dark", QUIZ_SKIN), QUIZ_SKIN)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.modulate.a = 0.0
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answers_vbox.add_child(_feedback_label)

	var is_mobile: bool = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	var hint_text := "Answer correctly: Jump | Slide | Blast | Bridge" if is_mobile else "Press 1-4: Jump | Slide | Blast | Bridge"
	_instructions = UITheme.make_label(hint_text, UITheme.FONT_SMALL, UITheme.get_color("text_dim", QUIZ_SKIN), QUIZ_SKIN)
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	answers_vbox.add_child(_instructions)


func _create_choice_button(index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(150, 56)
	btn.text = "--"
	btn.flat = false

	if UITheme.font_primary:
		btn.add_theme_font_override("font", UITheme.font_primary)
	btn.add_theme_font_size_override("font_size", UITheme.FONT_HEADING)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.31, 0.22, 0.13, 0.96)
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.content_margin_left = 20.0
	normal.content_margin_right = 20.0
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	normal.bg_color = UITheme.get_color("panel_light", QUIZ_SKIN)
	normal.border_color = Color("8A5A35")
	normal.border_width_left = 3
	normal.border_width_right = 3
	normal.border_width_top = 3
	normal.border_width_bottom = 3
	normal.shadow_color = Color(0.30, 0.18, 0.08, 0.12)
	normal.shadow_size = 4
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("FFF8E6")
	hover.border_color = UITheme.get_color("primary", QUIZ_SKIN)
	hover.shadow_size = 6
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = UITheme.get_color("primary", QUIZ_SKIN)
	pressed.border_color = UITheme.get_color("primary_dark", QUIZ_SKIN)
	pressed.shadow_size = 2
	btn.add_theme_stylebox_override("pressed", pressed)

	btn.add_theme_color_override("font_color", UITheme.get_color("text_ink", QUIZ_SKIN))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	var idx := index
	btn.pressed.connect(func(): _on_choice_pressed(idx))
	return btn


func _on_choice_pressed(index: int) -> void:
	QuizManager._check_answer(index)


func _on_question_changed(question: Dictionary) -> void:
	if question.is_empty():
		_question_label.text = ""
		for btn in _choice_buttons:
			btn.text = "--"
		_instructions.text = ""
		return

	_question_label.text = question.get("text", "?")
	var choices: Array = question.get("choices", [])
	for i in mini(choices.size(), _choice_buttons.size()):
		_choice_buttons[i].text = str(choices[i])

	_instructions.text = "Answer correctly to pass the obstacle!"

	_panel.scale = Vector2(0.95, 0.95)
	_choices_panel.scale = Vector2(0.97, 0.97)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.2)
	tw.parallel().tween_property(_choices_panel, "scale", Vector2.ONE, 0.2)


func _on_answer_result(correct: bool) -> void:
	if correct:
		_feedback_label.text = "CORRECT!"
		_feedback_label.add_theme_color_override("font_color", Color(0.42, 0.82, 0.34))
	else:
		_feedback_label.text = "WRONG!"
		_feedback_label.add_theme_color_override("font_color", UITheme.get_color("danger", QUIZ_SKIN))

	_feedback_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_feedback_label, "modulate:a", 0.0, 0.6).set_delay(0.3)

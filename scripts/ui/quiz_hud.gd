extends Control

const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")
const QUIZ_SKIN := UISkinIds.NATURE

var _question_label: Label
var _choices_container: HBoxContainer
var _choice_buttons: Array[Button] = []
var _feedback_label: Label
var _panel: PanelContainer
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
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_TOP_WIDE
	center.anchor_right = 1.0
	center.offset_top = 100
	center.offset_bottom = 320
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(750, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var style := StyleBoxFlat.new()
	style.bg_color = UITheme.get_color("panel_light", QUIZ_SKIN)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.content_margin_left = 40.0
	style.content_margin_right = 40.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	style.border_color = Color("8A5A35")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.shadow_color = Color(0.28, 0.18, 0.08, 0.15)
	style.shadow_size = 8
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)

	_question_label = UITheme.make_label("", UITheme.FONT_HEADING, UITheme.get_color("text_ink", QUIZ_SKIN), QUIZ_SKIN)
	_question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_question_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_question_label)

	_choices_container = HBoxContainer.new()
	_choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices_container.add_theme_constant_override("separation", 20)
	_choices_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_choices_container)

	for i in 4:
		var choice_btn := _create_choice_button(i)
		_choices_container.add_child(choice_btn)
		_choice_buttons.append(choice_btn)

	_feedback_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.get_color("primary_dark", QUIZ_SKIN), QUIZ_SKIN)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.modulate.a = 0.0
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_feedback_label)

	var is_mobile: bool = OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")
	var hint_text := "Answer correctly: Jump | Slide | Blast | Bridge" if is_mobile else "Press 1-4: Jump | Slide | Blast | Bridge"
	_instructions = UITheme.make_label(hint_text, UITheme.FONT_SMALL, UITheme.get_color("text_dim", QUIZ_SKIN), QUIZ_SKIN)
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_instructions)


func _create_choice_button(index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(140, 90)
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
	normal.content_margin_top = 16.0
	normal.content_margin_bottom = 16.0
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
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.2)


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

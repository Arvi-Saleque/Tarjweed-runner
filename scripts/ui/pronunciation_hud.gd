extends Control

const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")
const PRONUNCIATION_SKIN := UISkinIds.NATURE

var _word_label: Label
var _hint_label: Label
var _mic_icon_label: Label
var _volume_bar: ProgressBar
var _status_label: Label
var _feedback_label: Label
var _recognized_label: Label
var _panel: PanelContainer
var _listen_panel: PanelContainer
var _instructions: Label


func _ready() -> void:
	if not GameManager.is_pronunciation_mode():
		visible = false
		return

	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_create_ui()

	PronunciationManager.question_changed.connect(_on_question_changed)
	PronunciationManager.answer_result.connect(_on_answer_result)
	PronunciationManager.mic_status_changed.connect(_on_mic_status_changed)
	PronunciationManager.volume_updated.connect(_on_volume_updated)
	PronunciationManager.recognized_text_changed.connect(_on_recognized_text_changed)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)


func _create_ui() -> void:
	var prompt_strip := HBoxContainer.new()
	prompt_strip.anchors_preset = Control.PRESET_TOP_WIDE
	prompt_strip.anchor_right = 1.0
	prompt_strip.offset_left = 240
	prompt_strip.offset_right = -380
	prompt_strip.offset_top = 136
	prompt_strip.offset_bottom = 258
	prompt_strip.add_theme_constant_override("separation", 0)
	prompt_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt_strip)

	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_strip.add_child(left_spacer)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 112)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97, 0.95, 0.88, 0.90)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	style.border_color = Color("8A5A35")
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.20, 0.12, 0.04, 0.10)
	style.shadow_size = 5
	_panel.add_theme_stylebox_override("panel", style)
	prompt_strip.add_child(_panel)

	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_spacer.size_flags_stretch_ratio = 2.1
	right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_strip.add_child(right_spacer)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)

	var prompt_label := UITheme.make_label("Say this word:", UITheme.FONT_BODY, UITheme.get_color("text_dim", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(prompt_label)

	_word_label = UITheme.make_label("", UITheme.FONT_TITLE, UITheme.get_color("text_ink", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_word_label)

	_hint_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_dim", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_hint_label)

	var listen_center := CenterContainer.new()
	listen_center.anchors_preset = Control.PRESET_BOTTOM_WIDE
	listen_center.anchor_top = 1.0
	listen_center.anchor_right = 1.0
	listen_center.anchor_bottom = 1.0
	listen_center.offset_top = -222
	listen_center.offset_bottom = -54
	listen_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(listen_center)

	_listen_panel = PanelContainer.new()
	_listen_panel.custom_minimum_size = Vector2(460, 150)
	_listen_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var listen_style := style.duplicate() as StyleBoxFlat
	listen_style.bg_color = Color(0.97, 0.95, 0.88, 0.76)
	listen_style.content_margin_left = 18.0
	listen_style.content_margin_right = 18.0
	listen_style.content_margin_top = 16.0
	listen_style.content_margin_bottom = 16.0
	_listen_panel.add_theme_stylebox_override("panel", listen_style)
	listen_center.add_child(_listen_panel)

	var listen_vbox := VBoxContainer.new()
	listen_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	listen_vbox.add_theme_constant_override("separation", 8)
	listen_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_panel.add_child(listen_vbox)

	var mic_row := HBoxContainer.new()
	mic_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mic_row.add_theme_constant_override("separation", 12)
	mic_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_vbox.add_child(mic_row)

	_mic_icon_label = Label.new()
	_mic_icon_label.text = "MIC"
	if UITheme.font_button:
		_mic_icon_label.add_theme_font_override("font", UITheme.font_button)
	_mic_icon_label.add_theme_font_size_override("font_size", 32)
	_mic_icon_label.add_theme_color_override("font_color", UITheme.get_color("primary_dark", PRONUNCIATION_SKIN))
	_mic_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_row.add_child(_mic_icon_label)

	_volume_bar = ProgressBar.new()
	_volume_bar.custom_minimum_size = Vector2(300, 24)
	_volume_bar.min_value = 0.0
	_volume_bar.max_value = 1.0
	_volume_bar.value = 0.0
	_volume_bar.show_percentage = false
	_volume_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("FFF4D8")
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_left = 6
	bar_bg.corner_radius_bottom_right = 6
	bar_bg.border_width_left = 2
	bar_bg.border_width_right = 2
	bar_bg.border_width_top = 2
	bar_bg.border_width_bottom = 2
	bar_bg.border_color = Color("8A5A35")
	_volume_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = UITheme.get_color("primary", PRONUNCIATION_SKIN)
	bar_fill.corner_radius_top_left = 6
	bar_fill.corner_radius_top_right = 6
	bar_fill.corner_radius_bottom_left = 6
	bar_fill.corner_radius_bottom_right = 6
	_volume_bar.add_theme_stylebox_override("fill", bar_fill)
	mic_row.add_child(_volume_bar)

	_status_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("primary_dark", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_vbox.add_child(_status_label)

	_recognized_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.get_color("text_dim", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	_recognized_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recognized_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_vbox.add_child(_recognized_label)

	_feedback_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.get_color("primary_dark", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.modulate.a = 0.0
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_vbox.add_child(_feedback_label)

	_instructions = UITheme.make_label("Speak the word into your microphone!", UITheme.FONT_SMALL, UITheme.get_color("text_dim", PRONUNCIATION_SKIN), PRONUNCIATION_SKIN)
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listen_vbox.add_child(_instructions)


func _on_question_changed(question: Dictionary) -> void:
	if question.is_empty():
		_word_label.text = ""
		_hint_label.text = ""
		_status_label.text = ""
		_volume_bar.value = 0.0
		return

	_word_label.text = question.get("text", "?")
	_hint_label.text = "(%s)" % question.get("hint", "")

	_panel.scale = Vector2(0.95, 0.95)
	_listen_panel.scale = Vector2(0.97, 0.97)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.2)
	tw.parallel().tween_property(_listen_panel, "scale", Vector2.ONE, 0.2)


func _on_answer_result(correct: bool) -> void:
	if correct:
		_feedback_label.text = "CORRECT!"
		_feedback_label.add_theme_color_override("font_color", Color(0.42, 0.82, 0.34))
	else:
		_feedback_label.text = "TRY AGAIN"
		_feedback_label.add_theme_color_override("font_color", UITheme.get_color("danger", PRONUNCIATION_SKIN))
	_feedback_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_feedback_label, "modulate:a", 0.0, 0.6).set_delay(0.3)


func _on_mic_status_changed(listening: bool) -> void:
	if listening:
		_status_label.text = "Listening..."
		_mic_icon_label.modulate = UITheme.get_color("primary", PRONUNCIATION_SKIN)
	else:
		_status_label.text = ""
		_mic_icon_label.modulate = UITheme.get_color("text_dim", PRONUNCIATION_SKIN)
		_volume_bar.value = 0.0


func _on_recognized_text_changed(text: String) -> void:
	if text.is_empty():
		_recognized_label.text = ""
	else:
		_recognized_label.text = "Heard: \"%s\"" % text


func _on_volume_updated(level: float) -> void:
	_volume_bar.value = level
	var bar_fill := _volume_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if bar_fill:
		if level < 0.5:
			bar_fill.bg_color = UITheme.get_color("primary", PRONUNCIATION_SKIN)
		elif level < 0.75:
			bar_fill.bg_color = UITheme.get_color("accent", PRONUNCIATION_SKIN)
		else:
			bar_fill.bg_color = UITheme.get_color("danger", PRONUNCIATION_SKIN)


func _on_game_paused() -> void:
	visible = false


func _on_game_resumed() -> void:
	if GameManager.is_pronunciation_mode():
		visible = true

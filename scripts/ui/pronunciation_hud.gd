extends Control
## PronunciationHUD — Displays the current word, mic/volume indicator, and
## recognized text from Vosk speech recognition.

var _word_label: Label
var _hint_label: Label
var _mic_icon_label: Label
var _volume_bar: ProgressBar
var _status_label: Label
var _feedback_label: Label
var _recognized_label: Label
var _panel: PanelContainer
var _instructions: Label


func _ready() -> void:
	print("PronunciationHUD: _ready() called, theme = ", GameManager.current_theme)
	if GameManager.current_theme != "pronunciation":
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


func _create_ui() -> void:
	# Main panel at top center
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_TOP_WIDE
	center.anchor_right = 1.0
	center.offset_top = 80
	center.offset_bottom = 400
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(700, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.08, 0.18, 0.92)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 40.0
	style.content_margin_right = 40.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	style.border_color = Color(0.7, 0.4, 0.9, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)

	# "Say this word:" label
	var prompt_label := UITheme.make_label("Say this word:", UITheme.FONT_BODY, UITheme.COLOR_TEXT_DIM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(prompt_label)

	# The word to pronounce (large)
	_word_label = UITheme.make_label("", UITheme.FONT_TITLE, UITheme.COLOR_TEXT)
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_word_label)

	# Phonetic hint (smaller, dimmed)
	_hint_label = UITheme.make_label("", UITheme.FONT_SMALL, Color(0.7, 0.5, 0.9, 0.8))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_hint_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Mic row: icon + volume bar
	var mic_row := HBoxContainer.new()
	mic_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mic_row.add_theme_constant_override("separation", 12)
	mic_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(mic_row)

	# Mic icon (unicode microphone)
	_mic_icon_label = Label.new()
	_mic_icon_label.text = "🎤"
	_mic_icon_label.add_theme_font_size_override("font_size", 32)
	_mic_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_row.add_child(_mic_icon_label)

	# Volume bar
	_volume_bar = ProgressBar.new()
	_volume_bar.custom_minimum_size = Vector2(300, 24)
	_volume_bar.min_value = 0.0
	_volume_bar.max_value = 1.0
	_volume_bar.value = 0.0
	_volume_bar.show_percentage = false
	_volume_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the volume bar
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.1, 0.2, 0.8)
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_left = 6
	bar_bg.corner_radius_bottom_right = 6
	_volume_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.4, 0.8, 0.3, 0.9)
	bar_fill.corner_radius_top_left = 6
	bar_fill.corner_radius_top_right = 6
	bar_fill.corner_radius_bottom_left = 6
	bar_fill.corner_radius_bottom_right = 6
	_volume_bar.add_theme_stylebox_override("fill", bar_fill)

	mic_row.add_child(_volume_bar)

	# Status label (Listening... / Waiting...)
	_status_label = UITheme.make_label("", UITheme.FONT_SMALL, Color(0.6, 0.9, 0.6, 0.9))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_status_label)

	# Recognized text (shows what Vosk is hearing)
	_recognized_label = UITheme.make_label("", UITheme.FONT_BODY, Color(0.5, 0.8, 1.0, 0.9))
	_recognized_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recognized_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_recognized_label)

	# Feedback label (Correct! / Wrong flash)
	_feedback_label = UITheme.make_label("", UITheme.FONT_BODY, UITheme.COLOR_ACCENT)
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.modulate.a = 0.0
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_feedback_label)

	# Instructions
	_instructions = UITheme.make_label("Speak the word into your microphone!", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_instructions)


func _on_question_changed(question: Dictionary) -> void:
	print("PronunciationHUD: question_changed received: ", question)
	if question.is_empty():
		_word_label.text = ""
		_hint_label.text = ""
		_status_label.text = ""
		_volume_bar.value = 0.0
		return

	_word_label.text = question.get("text", "?")
	_hint_label.text = "(%s)" % question.get("hint", "")

	# Animate panel entrance
	_panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.2)


func _on_answer_result(correct: bool) -> void:
	if correct:
		_feedback_label.text = "✓ CORRECT!"
		_feedback_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.35))
	else:
		_feedback_label.text = "✗ Try again"
		_feedback_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.2))
	_feedback_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_feedback_label, "modulate:a", 0.0, 0.6).set_delay(0.3)


func _on_mic_status_changed(listening: bool) -> void:
	if listening:
		_status_label.text = "🔴 Listening..."
		_mic_icon_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		_status_label.text = ""
		_mic_icon_label.modulate = Color(0.5, 0.5, 0.5)
		_volume_bar.value = 0.0


func _on_recognized_text_changed(text: String) -> void:
	if text.is_empty():
		_recognized_label.text = ""
	else:
		_recognized_label.text = "Heard: \"%s\"" % text


func _on_volume_updated(level: float) -> void:
	_volume_bar.value = level
	# Color shift: green → yellow → red based on level
	var bar_fill := _volume_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if bar_fill:
		if level < 0.5:
			bar_fill.bg_color = Color(0.4, 0.8, 0.3, 0.9)
		elif level < 0.75:
			bar_fill.bg_color = Color(0.9, 0.8, 0.2, 0.9)
		else:
			bar_fill.bg_color = Color(0.9, 0.3, 0.2, 0.9)

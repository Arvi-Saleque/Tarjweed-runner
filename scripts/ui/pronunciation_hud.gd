extends Control

const _COL_DARK_GREEN := Color("1E5128")
const _COL_MID_GREEN  := Color("2D7A3D")
const _COL_CREAM      := Color("FFFAE8")
const _COL_WHITE      := Color.WHITE
const _COL_SUCCESS    := Color("A8E063")
const _COL_ERROR      := Color("FF8A80")

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
	# ── Top: Word prompt panel (same layout as quiz question panel) ──────────
	var top_strip := Control.new()
	top_strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_strip.anchor_right = 1.0
	top_strip.offset_top = 10.0
	top_strip.offset_bottom = 150.0
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_strip)

	var top_center := CenterContainer.new()
	top_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_center.anchor_right = 1.0
	top_center.anchor_bottom = 1.0
	top_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_strip.add_child(top_center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(720, 120)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _make_panel_style(_COL_CREAM, _COL_DARK_GREEN, 6, 28, 10))
	top_center.add_child(_panel)

	var word_center := CenterContainer.new()
	word_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	word_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	word_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(word_center)

	var word_vbox := VBoxContainer.new()
	word_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	word_vbox.add_theme_constant_override("separation", 2)
	word_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word_center.add_child(word_vbox)

	var prompt_label := Label.new()
	prompt_label.text = "Say this word:"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_button:
		prompt_label.add_theme_font_override("font", UITheme.font_button)
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_color", _COL_DARK_GREEN.lightened(0.35))
	word_vbox.add_child(prompt_label)

	_word_label = Label.new()
	_word_label.text = ""
	_word_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_display:
		_word_label.add_theme_font_override("font", UITheme.font_display)
	_word_label.add_theme_font_size_override("font_size", 40)
	_word_label.add_theme_color_override("font_color", _COL_DARK_GREEN)
	word_vbox.add_child(_word_label)

	_hint_label = Label.new()
	_hint_label.text = ""
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_button:
		_hint_label.add_theme_font_override("font", UITheme.font_button)
	_hint_label.add_theme_font_size_override("font_size", 15)
	_hint_label.add_theme_color_override("font_color", _COL_DARK_GREEN.lightened(0.45))
	word_vbox.add_child(_hint_label)

	# ── Below: Instruction pill + Mic card ──────────────────────────────────
	var mid_area := Control.new()
	mid_area.set_anchors_preset(Control.PRESET_TOP_WIDE)
	mid_area.anchor_right = 1.0
	mid_area.offset_top = 160.0
	mid_area.offset_bottom = 390.0
	mid_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mid_area)

	var mid_center := CenterContainer.new()
	mid_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	mid_center.anchor_right = 1.0
	mid_center.anchor_bottom = 1.0
	mid_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid_area.add_child(mid_center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid_center.add_child(vbox)

	# Instruction pill — same dark-green pill as quiz HUD
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

	_instructions = Label.new()
	_instructions.text = "Speak the word into your microphone!"
	_instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_button:
		_instructions.add_theme_font_override("font", UITheme.font_button)
	_instructions.add_theme_font_size_override("font_size", 21)
	_instructions.add_theme_color_override("font_color", _COL_WHITE)
	pill_margin.add_child(_instructions)

	# Mic + volume card — same cream/green style as quiz answer cards
	var mic_center := CenterContainer.new()
	mic_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mic_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(mic_center)

	_listen_panel = PanelContainer.new()
	_listen_panel.custom_minimum_size = Vector2(540, 80)
	_listen_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_listen_panel.add_theme_stylebox_override("panel", _make_panel_style(_COL_CREAM, _COL_DARK_GREEN, 3, 22, 4))
	mic_center.add_child(_listen_panel)

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
	_mic_icon_label.add_theme_font_size_override("font_size", 22)
	_mic_icon_label.add_theme_color_override("font_color", _COL_DARK_GREEN)
	_mic_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_row.add_child(_mic_icon_label)

	_volume_bar = ProgressBar.new()
	_volume_bar.custom_minimum_size = Vector2(340, 20)
	_volume_bar.min_value = 0.0
	_volume_bar.max_value = 1.0
	_volume_bar.value = 0.0
	_volume_bar.show_percentage = false
	_volume_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("E8E0CC")
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_left = 6
	bar_bg.corner_radius_bottom_right = 6
	_volume_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = _COL_MID_GREEN
	bar_fill.corner_radius_top_left = 6
	bar_fill.corner_radius_top_right = 6
	bar_fill.corner_radius_bottom_left = 6
	bar_fill.corner_radius_bottom_right = 6
	_volume_bar.add_theme_stylebox_override("fill", bar_fill)
	mic_row.add_child(_volume_bar)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_button:
		_status_label.add_theme_font_override("font", UITheme.font_button)
	_status_label.add_theme_font_size_override("font_size", 18)
	_status_label.add_theme_color_override("font_color", _COL_MID_GREEN)
	listen_vbox.add_child(_status_label)

	_recognized_label = Label.new()
	_recognized_label.text = ""
	_recognized_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_recognized_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_button:
		_recognized_label.add_theme_font_override("font", UITheme.font_button)
	_recognized_label.add_theme_font_size_override("font_size", 16)
	_recognized_label.add_theme_color_override("font_color", _COL_DARK_GREEN.lightened(0.3))
	listen_vbox.add_child(_recognized_label)

	_feedback_label = Label.new()
	_feedback_label.text = ""
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.modulate.a = 0.0
	_feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_display:
		_feedback_label.add_theme_font_override("font", UITheme.font_display)
	_feedback_label.add_theme_font_size_override("font_size", 24)
	listen_vbox.add_child(_feedback_label)


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
		_feedback_label.add_theme_color_override("font_color", _COL_SUCCESS)
	else:
		_feedback_label.text = "TRY AGAIN"
		_feedback_label.add_theme_color_override("font_color", _COL_ERROR)
	_feedback_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_feedback_label, "modulate:a", 0.0, 0.6).set_delay(0.3)


func _on_mic_status_changed(listening: bool) -> void:
	if listening:
		if PronunciationManager._vosk_available:
			_status_label.text = "Listening..."
		else:
			_status_label.text = "Listening... (speak to accept)"
		_mic_icon_label.add_theme_color_override("font_color", _COL_MID_GREEN)
	else:
		_status_label.text = ""
		_mic_icon_label.add_theme_color_override("font_color", _COL_DARK_GREEN)
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
			bar_fill.bg_color = _COL_MID_GREEN
		elif level < 0.75:
			bar_fill.bg_color = Color("E8A030")
		else:
			bar_fill.bg_color = _COL_ERROR


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
	return s


func _on_game_paused() -> void:
	visible = false


func _on_game_resumed() -> void:
	if GameManager.is_pronunciation_mode():
		visible = true

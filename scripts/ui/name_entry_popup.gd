extends Control
## NameEntryPopup - Child-friendly name prompt shown before theme selection.

signal confirmed(player_name: String)
signal cancelled

const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")
const POPUP_SKIN := UISkinIds.NATURE

var _overlay: ColorRect
var _panel: PanelContainer
var _line_edit: LineEdit
var _continue_btn: Button
var _back_btn: Button


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	_create_ui()
	_animate_in()


func _create_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = UITheme.get_color("overlay", POPUP_SKIN)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_panel = UITheme.make_panel("dark", POPUP_SKIN)
	_panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(_panel)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 14)
	outer_margin.add_theme_constant_override("margin_right", 14)
	outer_margin.add_theme_constant_override("margin_top", 14)
	outer_margin.add_theme_constant_override("margin_bottom", 14)
	_panel.add_child(outer_margin)

	var inner_panel := UITheme.make_panel("light", POPUP_SKIN)
	outer_margin.add_child(inner_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	inner_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title := UITheme.make_label("WHAT IS YOUR NAME?", UITheme.FONT_HEADING, UITheme.get_color("text_ink", POPUP_SKIN), POPUP_SKIN)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var subtitle := UITheme.make_label("Type a short name to start the adventure.", UITheme.FONT_BODY, UITheme.get_color("text_dim", POPUP_SKIN), POPUP_SKIN)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(subtitle)

	_line_edit = UITheme.make_line_edit("Enter your name", str(SaveManager.get_setting("player_name", "Explorer")), POPUP_SKIN)
	_line_edit.text_submitted.connect(func(_submitted: String): _confirm())
	vbox.add_child(_line_edit)

	var hint := UITheme.make_label("You can change it later.", UITheme.FONT_SMALL, UITheme.get_color("text_dim", POPUP_SKIN), POPUP_SKIN)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	vbox.add_child(buttons)

	_back_btn = UITheme.make_button("  BACK", UITheme.icon_cross, UITheme.FONT_SMALL, "secondary", POPUP_SKIN)
	_back_btn.custom_minimum_size = Vector2(220, 66)
	_back_btn.pressed.connect(_cancel)
	buttons.add_child(_back_btn)

	_continue_btn = UITheme.make_button("  CONTINUE", UITheme.icon_play, UITheme.FONT_BODY, "primary", POPUP_SKIN)
	_continue_btn.custom_minimum_size = Vector2(260, 74)
	_continue_btn.pressed.connect(_confirm)
	buttons.add_child(_continue_btn)


func _animate_in() -> void:
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.22)
	call_deferred("_focus_line_edit")


func _focus_line_edit() -> void:
	if _line_edit and is_instance_valid(_line_edit):
		_line_edit.grab_focus()
		_line_edit.select_all()


func _confirm() -> void:
	var player_name := _line_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Explorer"
	SaveManager.set_setting("player_name", player_name)
	AudioManager.play_ui_sound(AudioManager.ui_click)
	confirmed.emit(player_name)
	queue_free()


func _cancel() -> void:
	AudioManager.play_back_sound()
	cancelled.emit()
	queue_free()

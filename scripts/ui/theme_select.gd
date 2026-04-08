extends Control
## ThemeSelect - Two-step mode and theme selection screen shown after pressing PLAY.
## Step 1: choose gameplay mode. Step 2: choose visual theme for normal mode.

signal selection_confirmed(mode_id: String, theme_id: String)
signal back_pressed

const MODES: Array[Dictionary] = [
	{
		"id": "normal",
		"title": "NORMAL",
		"subtitle": "Classic endless run",
		"color": Color(0.2, 0.72, 0.33),
		"icon_text": "RUN",
	},
	{
		"id": "quiz",
		"title": "QUIZ",
		"subtitle": "Math challenges",
		"color": Color(0.3, 0.55, 0.95),
		"icon_text": "123",
	},
	{
		"id": "pronunciation",
		"title": "PRONUNCIATION",
		"subtitle": "Word pronunciation",
		"color": Color(0.7, 0.35, 0.9),
		"icon_text": "MIC",
	},
]

const VISUAL_THEMES: Array[Dictionary] = [
	{
		"id": "nature",
		"title": "NATURE",
		"subtitle": "Forest trail adventure",
		"color": Color(0.28, 0.70, 0.37),
		"icon_text": "LEAF",
		"available_modes": ["normal", "quiz", "pronunciation"],
	},
	{
		"id": "cyberprank",
		"title": "CYBERPRANK",
		"subtitle": "Neon urban sprint",
		"color": Color(0.18, 0.84, 0.98),
		"icon_text": "CYBR",
		"available_modes": ["normal"],
	},
]

var _overlay: ColorRect
var _container: VBoxContainer
var _cards_row: HBoxContainer
var _cards: Array[PanelContainer] = []
var _back_btn: Button
var _header: Control
var _sub: Label
var _notice: Label
var _selection_step: String = "mode"
var _selected_mode: String = "normal"


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_create_overlay()
	_create_layout()
	_refresh_cards()
	_animate_in()


func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.03, 0.04, 0.07, 0.92)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)


func _create_layout() -> void:
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_container = VBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 24)
	center.add_child(_container)

	_header = UITheme.make_banner("CHOOSE MODE", UITheme.FONT_BODY, UITheme.COLOR_TEXT_INK)
	_header.modulate.a = 0.0
	_container.add_child(_header)

	_sub = UITheme.make_label("Select a game mode to play", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	_sub.modulate.a = 0.0
	_container.add_child(_sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_container.add_child(spacer)

	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", 32)
	_container.add_child(_cards_row)

	_notice = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.COLOR_ACCENT)
	_notice.visible = false
	_notice.modulate.a = 0.0
	_container.add_child(_notice)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	_container.add_child(spacer2)

	_back_btn = UITheme.make_button("  BACK", UITheme.icon_cross, UITheme.FONT_BODY, "secondary")
	_back_btn.custom_minimum_size = Vector2(200, 56)
	_back_btn.modulate.a = 0.0
	_back_btn.pressed.connect(_on_back)
	_back_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_container.add_child(_back_btn)


func _clear_cards() -> void:
	for card in _cards:
		if is_instance_valid(card):
			if card.get_parent():
				card.get_parent().remove_child(card)
			card.queue_free()
	_cards.clear()


func _get_entries_for_step() -> Array[Dictionary]:
	return MODES if _selection_step == "mode" else VISUAL_THEMES


func _refresh_cards() -> void:
	_clear_cards()

	var header_label := _header.get_child(1) as Label
	if _selection_step == "mode":
		header_label.text = "CHOOSE MODE"
		_sub.text = "Select a game mode to play"
	else:
		header_label.text = "CHOOSE THEME"
		_sub.text = "Pick the visual theme for %s mode" % _selected_mode.capitalize()

	_notice.visible = false
	_notice.modulate.a = 0.0

	for data in _get_entries_for_step():
		var is_disabled := false
		var button_text := "  PLAY"
		if _selection_step == "theme":
			var available_modes: Array = data.get("available_modes", [])
			is_disabled = _selected_mode not in available_modes
			button_text = "  START" if not is_disabled else "  SOON"

		var card := _create_card(data, button_text, is_disabled)
		_cards_row.add_child(card)
		_cards.append(card)


func _create_card(data: Dictionary, button_text: String, is_disabled: bool) -> PanelContainer:
	var card := UITheme.make_panel("dark")
	card.custom_minimum_size = Vector2(300, 360)
	card.modulate.a = 0.0

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	var icon_bg := ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(100, 100)
	icon_bg.color = (data["color"] as Color).darkened(0.4)
	icon_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_bg)

	var icon_label := Label.new()
	icon_label.text = data.get("icon_text", "?")
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.anchors_preset = Control.PRESET_FULL_RECT
	icon_label.anchor_right = 1.0
	icon_label.anchor_bottom = 1.0
	icon_label.add_theme_font_size_override("font_size", 32)
	if UITheme.font_primary:
		icon_label.add_theme_font_override("font", UITheme.font_primary)
	icon_bg.add_child(icon_label)

	var title := UITheme.make_label(data["title"], UITheme.FONT_HEADING, UITheme.COLOR_TEXT)
	vbox.add_child(title)

	var subtitle := UITheme.make_label(data["subtitle"], UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	if is_disabled:
		var soon_badge := UITheme.make_label("CYBERPRANK COMING SOON", UITheme.FONT_SMALL, Color(0.95, 0.76, 0.30))
		vbox.add_child(soon_badge)

	var play_btn := Button.new()
	play_btn.text = button_text
	play_btn.custom_minimum_size = Vector2(220, 56)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.disabled = is_disabled
	if UITheme.font_primary:
		play_btn.add_theme_font_override("font", UITheme.font_primary)
	play_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = data["color"]
	btn_normal.corner_radius_top_left = 12
	btn_normal.corner_radius_top_right = 12
	btn_normal.corner_radius_bottom_left = 12
	btn_normal.corner_radius_bottom_right = 12
	btn_normal.content_margin_left = 20.0
	btn_normal.content_margin_right = 20.0
	btn_normal.content_margin_top = 10.0
	btn_normal.content_margin_bottom = 10.0
	btn_normal.shadow_color = Color(0, 0, 0, 0.3)
	btn_normal.shadow_size = 4
	btn_normal.shadow_offset = Vector2(0, 3)
	play_btn.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = (data["color"] as Color).lightened(0.15)
	btn_hover.shadow_size = 6
	play_btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = (data["color"] as Color).darkened(0.2)
	btn_pressed.shadow_size = 2
	play_btn.add_theme_stylebox_override("pressed", btn_pressed)

	var btn_disabled := btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = Color(0.30, 0.34, 0.40, 0.65)
	btn_disabled.shadow_size = 0
	play_btn.add_theme_stylebox_override("disabled", btn_disabled)

	play_btn.add_theme_color_override("font_color", UITheme.COLOR_TEXT_INK if not is_disabled else UITheme.COLOR_TEXT_DIM)
	play_btn.add_theme_color_override("font_hover_color", UITheme.COLOR_TEXT_INK)
	play_btn.add_theme_color_override("font_pressed_color", UITheme.COLOR_TEXT_INK_SOFT)
	play_btn.add_theme_color_override("font_disabled_color", UITheme.COLOR_TEXT_DIM)

	var entry_id: String = data["id"]
	if not is_disabled:
		play_btn.pressed.connect(func(): _on_entry_selected(entry_id))
		play_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	vbox.add_child(play_btn)

	card.mouse_entered.connect(func():
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(card, "scale", Vector2(1.03, 1.03), 0.15)
	)
	card.mouse_exited.connect(func():
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	)
	card.mouse_filter = Control.MOUSE_FILTER_PASS

	return card


func _animate_in() -> void:
	var items: Array[Control] = [_header, _sub]
	for card in _cards:
		items.append(card)
	if _notice.visible:
		items.append(_notice)
	items.append(_back_btn)

	for i in items.size():
		var item := items[i]
		item.modulate.a = 0.0 if item != _notice else item.modulate.a
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(item, "modulate:a", 1.0, 0.3).set_delay(i * 0.08)


func _on_entry_selected(entry_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _selection_step == "mode":
		_selected_mode = entry_id
		GameManager.current_mode = entry_id
		if entry_id == "normal":
			_selection_step = "theme"
			_refresh_cards()
			_animate_in()
		else:
			_start_mode_with_nature_notice(entry_id)
		return

	GameManager.current_visual_theme = entry_id
	selection_confirmed.emit(GameManager.current_mode, entry_id)
	SceneManager.change_scene("res://scenes/game.tscn")


func _start_mode_with_nature_notice(mode_id: String) -> void:
	GameManager.current_mode = mode_id
	GameManager.current_visual_theme = "nature"
	_notice.text = "Cyberprank for %s mode is coming soon. Starting in Nature." % mode_id.capitalize()
	_notice.visible = true
	_notice.modulate.a = 1.0
	selection_confirmed.emit(GameManager.current_mode, GameManager.current_visual_theme)
	await get_tree().create_timer(0.8).timeout
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_back() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _selection_step == "theme":
		_selection_step = "mode"
		_refresh_cards()
		_animate_in()
		return

	back_pressed.emit()
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

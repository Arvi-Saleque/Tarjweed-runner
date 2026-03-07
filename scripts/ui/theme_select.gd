extends Control
## ThemeSelect — Theme/mode selection screen shown after pressing PLAY.
## Displays theme cards the player can pick. Currently: Natural and Quiz.

signal theme_chosen(theme_id: String)
signal back_pressed

# Theme definitions
const THEMES: Array[Dictionary] = [
	{
		"id": "natural",
		"title": "NATURAL",
		"subtitle": "Endless forest run",
		"color": Color(0.2, 0.72, 0.33),         # Green
		"bg_color": Color(0.12, 0.22, 0.14, 0.95),
		"icon_color": Color(0.35, 0.85, 0.45),
	},
	{
		"id": "quiz",
		"title": "QUIZ",
		"subtitle": "Math challenges",
		"color": Color(0.3, 0.55, 0.95),          # Blue
		"bg_color": Color(0.12, 0.16, 0.28, 0.95),
		"icon_color": Color(0.45, 0.65, 1.0),
	},
	{
		"id": "pronunciation",
		"title": "PRONUNCIATION",
		"subtitle": "Word pronunciation",
		"color": Color(0.7, 0.35, 0.9),           # Purple
		"bg_color": Color(0.2, 0.12, 0.28, 0.95),
		"icon_color": Color(0.8, 0.5, 1.0),
	},
]

var _overlay: ColorRect
var _container: VBoxContainer
var _cards: Array[PanelContainer] = []
var _back_btn: Button


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_create_overlay()
	_create_layout()
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
	# Full-screen centering
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_container = VBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 24)
	center.add_child(_container)

	# Header
	var header := UITheme.make_label("CHOOSE MODE", UITheme.FONT_TITLE, UITheme.COLOR_TEXT)
	header.modulate.a = 0.0
	_container.add_child(header)
	_container.set_meta("header", header)

	# Subtitle
	var sub := UITheme.make_label("Select a game mode to play", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	sub.modulate.a = 0.0
	_container.add_child(sub)
	_container.set_meta("sub", sub)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_container.add_child(spacer)

	# Cards row
	var cards_row := HBoxContainer.new()
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 32)
	_container.add_child(cards_row)

	for theme_data in THEMES:
		var card := _create_theme_card(theme_data)
		cards_row.add_child(card)
		_cards.append(card)

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	_container.add_child(spacer2)

	# Back button
	_back_btn = UITheme.make_button("  BACK", UITheme.icon_cross)
	_back_btn.custom_minimum_size = Vector2(200, 56)
	_back_btn.modulate.a = 0.0
	_back_btn.pressed.connect(_on_back)
	_back_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_container.add_child(_back_btn)


func _create_theme_card(data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 360)
	card.modulate.a = 0.0

	# Card style
	var style := StyleBoxFlat.new()
	style.bg_color = data["bg_color"]
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.content_margin_left = 28.0
	style.content_margin_right = 28.0
	style.content_margin_top = 28.0
	style.content_margin_bottom = 28.0
	style.border_color = data["color"].darkened(0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	card.add_theme_stylebox_override("panel", style)

	# Card content
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	# Large icon/emblem area
	var icon_bg := ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(100, 100)
	icon_bg.color = data["color"].darkened(0.4)
	icon_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_bg)

	# Icon symbol (emoji-like text for now)
	var icon_label := Label.new()
	icon_label.text = "🌿" if data["id"] == "natural" else "❓"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.anchors_preset = Control.PRESET_FULL_RECT
	icon_label.anchor_right = 1.0
	icon_label.anchor_bottom = 1.0
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_bg.add_child(icon_label)

	# Theme title
	var title := UITheme.make_label(data["title"], UITheme.FONT_HEADING, data["color"])
	vbox.add_child(title)

	# Theme subtitle
	var subtitle := UITheme.make_label(data["subtitle"], UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Play button for this theme
	var play_btn := Button.new()
	play_btn.text = "  PLAY"
	play_btn.custom_minimum_size = Vector2(200, 56)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if UITheme.font_primary:
		play_btn.add_theme_font_override("font", UITheme.font_primary)
	play_btn.add_theme_font_size_override("font_size", UITheme.FONT_BODY)

	# Style the button with the theme color
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
	btn_hover.bg_color = data["color"].lightened(0.15)
	btn_hover.shadow_size = 6
	play_btn.add_theme_stylebox_override("hover", btn_hover)

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = data["color"].darkened(0.2)
	btn_pressed.shadow_size = 2
	play_btn.add_theme_stylebox_override("pressed", btn_pressed)

	play_btn.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
	play_btn.add_theme_color_override("font_hover_color", Color.WHITE)

	# Capture theme_id for the lambda
	var theme_id: String = data["id"]
	play_btn.pressed.connect(func(): _on_theme_selected(theme_id))
	play_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	vbox.add_child(play_btn)

	# Hover effect on card
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
	var header: Label = _container.get_meta("header")
	var sub: Label = _container.get_meta("sub")

	var items: Array[Control] = [header, sub]
	for c in _cards:
		items.append(c)
	items.append(_back_btn)

	for i in items.size():
		var item := items[i]
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(item, "modulate:a", 1.0, 0.3).set_delay(i * 0.1)


func _on_theme_selected(theme_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	GameManager.current_theme = theme_id
	theme_chosen.emit(theme_id)
	# Transition to game
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_back() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	back_pressed.emit()
	# Animate out then remove
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

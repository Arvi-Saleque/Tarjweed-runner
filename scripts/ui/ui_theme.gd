extends Node
## UITheme — Centralized UI theme and font management.
## Provides consistent fonts, colors, and styling across all UI screens.

# --- Fonts ---
var font_primary: FontFile
var font_narrow: FontFile

# --- Colors ---
const COLOR_PRIMARY := Color(0.2, 0.72, 0.33)       # Green
const COLOR_PRIMARY_DARK := Color(0.14, 0.52, 0.24)
const COLOR_ACCENT := Color(1.0, 0.85, 0.1)          # Gold
const COLOR_DANGER := Color(0.85, 0.2, 0.15)         # Red
const COLOR_TEXT := Color(0.95, 0.95, 0.95)           # White text
const COLOR_TEXT_DIM := Color(0.65, 0.65, 0.65)       # Grey text
const COLOR_PANEL_BG := Color(0.08, 0.1, 0.14, 0.92) # Dark panel
const COLOR_PANEL_LIGHT := Color(0.12, 0.15, 0.2, 0.88)
const COLOR_OVERLAY := Color(0.0, 0.0, 0.0, 0.55)    # Dim overlay

# --- Font Sizes ---
const FONT_TITLE: int = 52
const FONT_HEADING: int = 36
const FONT_BODY: int = 24
const FONT_SMALL: int = 18
const FONT_HUD: int = 28

# --- Button Textures ---
var btn_rect_texture: Texture2D
var btn_round_texture: Texture2D

# Icon textures
var icon_play: Texture2D
var icon_pause: Texture2D
var icon_home: Texture2D
var icon_gear: Texture2D
var icon_trophy: Texture2D
var icon_cross: Texture2D
var icon_check: Texture2D
var icon_audio_on: Texture2D
var icon_audio_off: Texture2D
var icon_music_on: Texture2D
var icon_music_off: Texture2D


func _ready() -> void:
	_load_fonts()
	_load_textures()


func _load_fonts() -> void:
	font_primary = _try_load_font("res://assets/UI/Fonts/Kenney Future.ttf")
	font_narrow = _try_load_font("res://assets/UI/Fonts/Kenney Future Narrow.ttf")


func _load_textures() -> void:
	btn_rect_texture = _try_load_tex("res://assets/UI/Buttons/button_rectangle_depth_gloss.png")
	btn_round_texture = _try_load_tex("res://assets/UI/Buttons/button_round_depth_gloss.png")
	icon_play = _try_load_tex("res://assets/UI/Icons/icon_play_light.png")
	icon_pause = _try_load_tex("res://assets/UI/Icons/pause.png")
	icon_home = _try_load_tex("res://assets/UI/Icons/home.png")
	icon_gear = _try_load_tex("res://assets/UI/Icons/gear.png")
	icon_trophy = _try_load_tex("res://assets/UI/Icons/trophy.png")
	icon_cross = _try_load_tex("res://assets/UI/Icons/icon_cross.png")
	icon_check = _try_load_tex("res://assets/UI/Icons/icon_checkmark.png")
	icon_audio_on = _try_load_tex("res://assets/UI/Icons/audioOn.png")
	icon_audio_off = _try_load_tex("res://assets/UI/Icons/audioOff.png")
	icon_music_on = _try_load_tex("res://assets/UI/Icons/musicOn.png")
	icon_music_off = _try_load_tex("res://assets/UI/Icons/musicOff.png")


func _try_load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		return load(path) as FontFile
	return null


func _try_load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# --- Theme Helpers ---

func make_label(text: String, size: int = FONT_BODY, color: Color = COLOR_TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_primary:
		label.add_theme_font_override("font", font_primary)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func make_button(text: String, icon: Texture2D = null, size: int = FONT_BODY) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 64)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if font_primary:
		btn.add_theme_font_override("font", font_primary)
	btn.add_theme_font_size_override("font_size", size)
	if icon:
		btn.icon = icon
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.expand_icon = true

	# Style
	_style_button(btn)
	return btn


func _style_button(btn: Button) -> void:
	# Normal state
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_PRIMARY
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_left = 24.0
	normal.content_margin_right = 24.0
	normal.content_margin_top = 12.0
	normal.content_margin_bottom = 12.0
	normal.shadow_color = Color(0, 0, 0, 0.3)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", normal)

	# Hover
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_PRIMARY.lightened(0.15)
	hover.shadow_size = 6
	btn.add_theme_stylebox_override("hover", hover)

	# Pressed
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = COLOR_PRIMARY_DARK
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 1)
	btn.add_theme_stylebox_override("pressed", pressed)

	# Focus
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = COLOR_ACCENT
	focus.border_width_left = 2
	focus.border_width_right = 2
	focus.border_width_top = 2
	focus.border_width_bottom = 2
	focus.corner_radius_top_left = 12
	focus.corner_radius_top_right = 12
	focus.corner_radius_bottom_left = 12
	focus.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("focus", focus)

	# Text colors
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", COLOR_TEXT_DIM)


func make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_BG
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 32.0
	style.content_margin_right = 32.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	style.border_color = Color(1, 1, 1, 0.08)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func make_icon_button(icon: Texture2D, tooltip: String = "") -> Button:
	var btn := Button.new()
	btn.icon = icon
	btn.expand_icon = true
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(56, 56)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.3)
	normal.corner_radius_top_left = 28
	normal.corner_radius_top_right = 28
	normal.corner_radius_bottom_left = 28
	normal.corner_radius_bottom_right = 28
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1, 1, 1, 0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0, 0, 0, 0.5)
	btn.add_theme_stylebox_override("pressed", pressed)

	var focus := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", focus)

	return btn

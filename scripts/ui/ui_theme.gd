extends Node

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")
## UITheme — Centralized UI theme and font management.
## Provides consistent fonts, colors, and styling across all UI screens.

# --- Fonts ---
var font_primary: FontFile
var font_narrow: FontFile

# --- Colors ---
const COLOR_PRIMARY := Color(0.58, 0.39, 0.18)         # Warm brown
const COLOR_PRIMARY_DARK := Color(0.42, 0.27, 0.10)
const COLOR_ACCENT := Color(0.98, 0.85, 0.33)          # Gold
const COLOR_DANGER := Color(0.78, 0.25, 0.18)          # Clay red
const COLOR_TEXT := Color(0.97, 0.95, 0.89)            # Parchment white
const COLOR_TEXT_DIM := Color(0.76, 0.72, 0.63)        # Warm dim text
const COLOR_TEXT_INK := Color(0.18, 0.12, 0.07)        # Dark readable text on light UI
const COLOR_TEXT_INK_SOFT := Color(0.28, 0.19, 0.11)
const COLOR_PANEL_BG := Color(0.18, 0.14, 0.09, 0.96) # Dark wood panel
const COLOR_PANEL_LIGHT := Color(0.34, 0.25, 0.16, 0.92)
const COLOR_OVERLAY := Color(0.05, 0.03, 0.02, 0.62)  # Dim overlay

# --- Font Sizes ---
const FONT_TITLE: int = 52
const FONT_HEADING: int = 36
const FONT_BODY: int = 24
const FONT_SMALL: int = 18
const FONT_HUD: int = 28

# --- Button and Panel Textures ---
var btn_primary_texture: Texture2D
var btn_secondary_texture: Texture2D
var btn_danger_texture: Texture2D
var btn_round_texture: Texture2D
var btn_round_dark_texture: Texture2D
var panel_texture: Texture2D
var panel_dark_texture: Texture2D
var banner_texture: Texture2D
var progress_green_texture: Texture2D
var progress_red_texture: Texture2D
var progress_white_texture: Texture2D
var cyber_btn_primary_texture: Texture2D
var cyber_btn_secondary_texture: Texture2D
var cyber_btn_danger_texture: Texture2D
var cyber_btn_round_texture: Texture2D
var cyber_btn_round_dark_texture: Texture2D
var cyber_panel_texture: Texture2D
var cyber_panel_dark_texture: Texture2D
var cyber_banner_texture: Texture2D
var cyber_progress_fill_texture: Texture2D
var cyber_progress_alert_texture: Texture2D
var cyber_progress_back_texture: Texture2D

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
var icon_coin: Texture2D
var icon_star: Texture2D
var icon_warning: Texture2D


func _ready() -> void:
	_load_fonts()
	_load_textures()


func _load_fonts() -> void:
	font_primary = _try_load_font("res://assets/UI/Fonts/Kenney Future.ttf")
	font_narrow = _try_load_font("res://assets/UI/Fonts/Kenney Future Narrow.ttf")


func _load_textures() -> void:
	btn_primary_texture = _try_load_tex("res://assets/UI/kenney_adventure/button_brown.png")
	btn_secondary_texture = _try_load_tex("res://assets/UI/kenney_adventure/button_grey.png")
	btn_danger_texture = _try_load_tex("res://assets/UI/kenney_adventure/button_red.png")
	btn_round_texture = _try_load_tex("res://assets/UI/kenney_adventure/round_brown.png")
	btn_round_dark_texture = _try_load_tex("res://assets/UI/kenney_adventure/round_brown_dark.png")
	panel_texture = _try_load_tex("res://assets/UI/kenney_adventure/panel_brown.png")
	panel_dark_texture = _try_load_tex("res://assets/UI/kenney_adventure/panel_brown_dark.png")
	banner_texture = _try_load_tex("res://assets/UI/kenney_adventure/banner_modern.png")
	progress_green_texture = _try_load_tex("res://assets/UI/kenney_adventure/progress_green.png")
	progress_red_texture = _try_load_tex("res://assets/UI/kenney_adventure/progress_red.png")
	progress_white_texture = _try_load_tex("res://assets/UI/kenney_adventure/progress_white.png")
	cyber_btn_primary_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/button_square_header_large_rectangle_screws.png")
	cyber_btn_secondary_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/button_square_header_notch_rectangle_screws.png")
	cyber_btn_danger_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/extra/button_rectangle_depth.png")
	cyber_btn_round_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/button_square_header_large_square_screws.png")
	cyber_btn_round_dark_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/button_square_header_blade_square_screws.png")
	cyber_panel_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/extra/panel_rectangle_screws.png")
	cyber_panel_dark_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/extra/panel_glass_screws.png")
	cyber_banner_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/button_square_header_blade_rectangle_screws.png")
	cyber_progress_fill_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/bar_round_gloss_large.png")
	cyber_progress_alert_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/blue/bar_square_gloss_large.png")
	cyber_progress_back_texture = _try_load_tex("res://assets/UI/cyberprank/space_expansion/extra/bar_shadow_round_outline_large.png")

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
	icon_coin = _try_load_tex("res://assets/UI/kenney_adventure/minimap_icon_jewel_yellow.png")
	icon_star = _try_load_tex("res://assets/UI/kenney_adventure/minimap_icon_star_yellow.png")
	icon_warning = _try_load_tex("res://assets/UI/kenney_adventure/minimap_icon_exclamation_yellow.png")


func _try_load_font(path: String) -> FontFile:
	if ResourceLoader.exists(path):
		return load(path) as FontFile
	return null


func _try_load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


# --- Theme Helpers ---

func get_gameplay_skin() -> String:
	return ThemeRegistryScript.get_profile().get("ui", {}).get("skin", "nature")


func get_color(color_id: String, skin_override: String = "") -> Color:
	var colors := _get_skin_colors(_resolve_skin(skin_override))
	return colors.get(color_id, COLOR_TEXT)


func make_label(text: String, size: int = FONT_BODY, color: Color = COLOR_TEXT, skin_override: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_primary:
		label.add_theme_font_override("font", font_primary)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func make_button(text: String, icon: Texture2D = null, size: int = FONT_BODY, variant: String = "primary", skin_override: String = "") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 72)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if font_primary:
		btn.add_theme_font_override("font", font_primary)
	btn.add_theme_font_size_override("font_size", size)
	if icon:
		btn.icon = icon
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.expand_icon = true

	_apply_button_variant(btn, variant, skin_override)
	return btn


func _apply_button_variant(btn: Button, variant: String, skin_override: String = "") -> void:
	var skin_id := _resolve_skin(skin_override)
	var colors := _get_skin_colors(skin_id)
	var source_texture: Texture2D = btn_primary_texture
	var base_modulate := Color(1, 1, 1, 1)
	var hover_modulate := Color(1.08, 1.08, 1.08, 1)
	var pressed_modulate := Color(0.92, 0.92, 0.92, 1)

	if skin_id == "cyberprank":
		match variant:
			"secondary":
				source_texture = cyber_btn_secondary_texture
				base_modulate = Color(0.44, 0.86, 1.0, 0.95)
				hover_modulate = Color(0.54, 0.94, 1.0, 1.0)
				pressed_modulate = Color(0.26, 0.62, 0.82, 0.98)
			"danger":
				source_texture = cyber_btn_danger_texture
				base_modulate = Color(0.95, 0.32, 1.0, 0.92)
				hover_modulate = Color(1.0, 0.44, 1.0, 1.0)
				pressed_modulate = Color(0.74, 0.18, 0.82, 0.98)
			_:
				source_texture = cyber_btn_primary_texture
				base_modulate = Color(0.18, 0.92, 1.0, 0.96)
				hover_modulate = Color(0.34, 0.98, 1.0, 1.0)
				pressed_modulate = Color(0.10, 0.62, 0.82, 0.98)
	else:
		match variant:
			"secondary":
				source_texture = btn_secondary_texture
				base_modulate = Color(0.94, 0.94, 0.94, 1)
				hover_modulate = Color(1.02, 1.02, 1.02, 1)
				pressed_modulate = Color(0.88, 0.88, 0.88, 1)
			"danger":
				source_texture = btn_danger_texture
				base_modulate = Color(1, 0.96, 0.96, 1)
				hover_modulate = Color(1.06, 1.0, 1.0, 1)
				pressed_modulate = Color(0.92, 0.88, 0.88, 1)
			_:
				source_texture = btn_primary_texture

	btn.add_theme_stylebox_override("normal", _make_texture_stylebox(source_texture, base_modulate, 24.0, 20.0))
	btn.add_theme_stylebox_override("hover", _make_texture_stylebox(source_texture, hover_modulate, 24.0, 20.0))
	btn.add_theme_stylebox_override("pressed", _make_texture_stylebox(source_texture, pressed_modulate, 24.0, 20.0))

	var focus := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_color_override("font_color", colors["text_ink"])
	btn.add_theme_color_override("font_hover_color", colors["text_ink"])
	btn.add_theme_color_override("font_pressed_color", colors["text_ink_soft"])


func make_panel(variant: String = "dark", skin_override: String = "") -> PanelContainer:
	var panel := PanelContainer.new()
	var skin_id := _resolve_skin(skin_override)
	var colors := _get_skin_colors(skin_id)
	var tex := panel_dark_texture if variant == "dark" else panel_texture
	if skin_id == "cyberprank":
		tex = cyber_panel_dark_texture if variant == "dark" else cyber_panel_texture
	var tint := colors["panel_bg"] if variant == "dark" else colors["panel_light"]
	var style := _make_texture_stylebox(tex, tint, 28.0, 26.0)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func make_icon_button(icon: Texture2D, tooltip: String = "", variant: String = "dark", skin_override: String = "") -> Button:
	var btn := Button.new()
	btn.icon = icon
	btn.expand_icon = true
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(64, 64)
	var skin_id := _resolve_skin(skin_override)
	var colors := _get_skin_colors(skin_id)
	var tex := btn_round_dark_texture if variant == "dark" else btn_round_texture
	if skin_id == "cyberprank":
		tex = cyber_btn_round_dark_texture if variant == "dark" else cyber_btn_round_texture
	btn.add_theme_stylebox_override("normal", _make_texture_stylebox(tex, Color(1, 1, 1, 0.96), 18.0, 18.0))
	btn.add_theme_stylebox_override("hover", _make_texture_stylebox(tex, Color(1.06, 1.06, 1.06, 1), 18.0, 18.0))
	btn.add_theme_stylebox_override("pressed", _make_texture_stylebox(tex, Color(0.92, 0.92, 0.92, 1), 18.0, 18.0))

	var focus := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("focus", focus)
	btn.add_theme_color_override("icon_normal_color", colors["text_ink"])
	btn.add_theme_color_override("icon_hover_color", colors["text_ink"])
	btn.add_theme_color_override("icon_pressed_color", colors["text_ink_soft"])

	return btn


func make_banner(text: String, size: int = FONT_HEADING, color: Color = COLOR_TEXT, skin_override: String = "") -> Control:
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(320, 84)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texture_rect := TextureRect.new()
	texture_rect.anchors_preset = Control.PRESET_FULL_RECT
	texture_rect.anchor_right = 1.0
	texture_rect.anchor_bottom = 1.0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = cyber_banner_texture if _resolve_skin(skin_override) == "cyberprank" else banner_texture
	banner.add_child(texture_rect)

	var label := make_label(text, size, color, skin_override)
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.position.y = -4.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(label)
	return banner


func make_progress_stylebox(part: String = "fill", skin_override: String = "") -> StyleBox:
	var skin_id := _resolve_skin(skin_override)
	if skin_id == "cyberprank":
		match part:
			"background":
				return _make_texture_stylebox(cyber_progress_back_texture, Color(0.04, 0.10, 0.16, 0.96), 0.0, 0.0)
			"alert_fill":
				return _make_texture_stylebox(cyber_progress_alert_texture, Color(0.88, 0.24, 1.0, 0.98), 0.0, 0.0)
			_:
				return _make_texture_stylebox(cyber_progress_fill_texture, Color(0.10, 0.90, 1.0, 0.98), 0.0, 0.0)

	match part:
		"background":
			return _make_texture_stylebox(panel_dark_texture, Color(1, 1, 1, 0.9), 0.0, 0.0)
		"alert_fill":
			return _make_texture_stylebox(progress_red_texture, Color(1, 1, 1, 1.0), 0.0, 0.0)
		_:
			return _make_texture_stylebox(progress_green_texture, Color(1, 1, 1, 1.0), 0.0, 0.0)


func _make_texture_stylebox(texture: Texture2D, modulate_color: Color, horizontal_margin: float, vertical_margin: float) -> StyleBox:
	if texture == null:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = modulate_color
		fallback.corner_radius_top_left = 14
		fallback.corner_radius_top_right = 14
		fallback.corner_radius_bottom_left = 14
		fallback.corner_radius_bottom_right = 14
		fallback.content_margin_left = horizontal_margin
		fallback.content_margin_right = horizontal_margin
		fallback.content_margin_top = vertical_margin
		fallback.content_margin_bottom = vertical_margin
		return fallback

	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = modulate_color
	style.texture_margin_left = 18.0
	style.texture_margin_right = 18.0
	style.texture_margin_top = 18.0
	style.texture_margin_bottom = 18.0
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style


func _resolve_skin(skin_override: String = "") -> String:
	if not skin_override.is_empty():
		return skin_override
	return "nature"


func _get_skin_colors(skin_id: String) -> Dictionary:
	if skin_id == "cyberprank":
		return {
			"primary": Color(0.14, 0.86, 1.0),
			"primary_dark": Color(0.08, 0.28, 0.38),
			"accent": Color(0.95, 0.28, 1.0),
			"danger": Color(1.0, 0.32, 0.52),
			"text": Color(0.89, 0.98, 1.0),
			"text_dim": Color(0.56, 0.78, 0.90),
			"text_ink": Color(0.03, 0.10, 0.14),
			"text_ink_soft": Color(0.07, 0.16, 0.22),
			"panel_bg": Color(0.03, 0.08, 0.12, 0.94),
			"panel_light": Color(0.06, 0.14, 0.22, 0.90),
			"overlay": Color(0.01, 0.04, 0.08, 0.74),
			"panel_line": Color(0.12, 0.82, 1.0, 0.24),
		}

	return {
		"primary": COLOR_PRIMARY,
		"primary_dark": COLOR_PRIMARY_DARK,
		"accent": COLOR_ACCENT,
		"danger": COLOR_DANGER,
		"text": COLOR_TEXT,
		"text_dim": COLOR_TEXT_DIM,
		"text_ink": COLOR_TEXT_INK,
		"text_ink_soft": COLOR_TEXT_INK_SOFT,
		"panel_bg": COLOR_PANEL_BG,
		"panel_light": COLOR_PANEL_LIGHT,
		"overlay": COLOR_OVERLAY,
		"panel_line": Color(1, 1, 1, 0.1),
	}

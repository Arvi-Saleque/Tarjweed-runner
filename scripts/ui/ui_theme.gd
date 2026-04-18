extends Node

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")
const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")
const UIThemeAssets = preload("res://scripts/ui/ui_theme_assets.gd")
const UIThemeTokens = preload("res://scripts/ui/ui_theme_tokens.gd")
## UITheme — Centralized UI theme and font management.
## Provides consistent fonts, colors, and styling across all UI screens.

# --- Fonts ---
var font_primary: Font
var font_narrow: Font
var font_display: Font
var font_button: Font

# --- Colors ---
const COLOR_PRIMARY := UIThemeTokens.COLOR_PRIMARY         # Warm brown
const COLOR_PRIMARY_DARK := UIThemeTokens.COLOR_PRIMARY_DARK
const COLOR_ACCENT := UIThemeTokens.COLOR_ACCENT          # Gold
const COLOR_DANGER := UIThemeTokens.COLOR_DANGER          # Clay red
const COLOR_TEXT := UIThemeTokens.COLOR_TEXT              # Parchment white
const COLOR_TEXT_DIM := UIThemeTokens.COLOR_TEXT_DIM      # Warm dim text
const COLOR_TEXT_INK := UIThemeTokens.COLOR_TEXT_INK      # Dark readable text on light UI
const COLOR_TEXT_INK_SOFT := UIThemeTokens.COLOR_TEXT_INK_SOFT
const COLOR_PANEL_BG := UIThemeTokens.COLOR_PANEL_BG      # Dark wood panel
const COLOR_PANEL_LIGHT := UIThemeTokens.COLOR_PANEL_LIGHT
const COLOR_OVERLAY := UIThemeTokens.COLOR_OVERLAY        # Dim overlay

# --- Font Sizes ---
const FONT_TITLE: int = UIThemeTokens.FONT_TITLE
const FONT_HEADING: int = UIThemeTokens.FONT_HEADING
const FONT_BODY: int = UIThemeTokens.FONT_BODY
const FONT_SMALL: int = UIThemeTokens.FONT_SMALL
const FONT_HUD: int = UIThemeTokens.FONT_HUD

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
	font_primary = _try_load_font(UIThemeAssets.FONT_PRIMARY)
	font_narrow = _try_load_font(UIThemeAssets.FONT_NARROW)
	font_display = _try_load_font(UIThemeAssets.FONT_DISPLAY)
	font_button = _try_load_font(UIThemeAssets.FONT_BUTTON)
	if font_primary == null and ThemeDB.fallback_font != null:
		font_primary = ThemeDB.fallback_font
	if font_button == null:
		font_button = font_display if font_display != null else font_primary


func _load_textures() -> void:
	btn_primary_texture = _try_load_tex(UIThemeAssets.BTN_PRIMARY)
	btn_secondary_texture = _try_load_tex(UIThemeAssets.BTN_SECONDARY)
	btn_danger_texture = _try_load_tex(UIThemeAssets.BTN_DANGER)
	btn_round_texture = _try_load_tex(UIThemeAssets.BTN_ROUND)
	btn_round_dark_texture = _try_load_tex(UIThemeAssets.BTN_ROUND_DARK)
	panel_texture = _try_load_tex(UIThemeAssets.PANEL)
	panel_dark_texture = _try_load_tex(UIThemeAssets.PANEL_DARK)
	banner_texture = _try_load_tex(UIThemeAssets.BANNER)
	progress_green_texture = _try_load_tex(UIThemeAssets.PROGRESS_GREEN)
	progress_red_texture = _try_load_tex(UIThemeAssets.PROGRESS_RED)
	progress_white_texture = _try_load_tex(UIThemeAssets.PROGRESS_WHITE)
	cyber_btn_primary_texture = _try_load_tex(UIThemeAssets.CYBER_BTN_PRIMARY)
	cyber_btn_secondary_texture = _try_load_tex(UIThemeAssets.CYBER_BTN_SECONDARY)
	cyber_btn_danger_texture = _try_load_tex(UIThemeAssets.CYBER_BTN_DANGER)
	cyber_btn_round_texture = _try_load_tex(UIThemeAssets.CYBER_BTN_ROUND)
	cyber_btn_round_dark_texture = _try_load_tex(UIThemeAssets.CYBER_BTN_ROUND_DARK)
	cyber_panel_texture = _try_load_tex(UIThemeAssets.CYBER_PANEL)
	cyber_panel_dark_texture = _try_load_tex(UIThemeAssets.CYBER_PANEL_DARK)
	cyber_banner_texture = _try_load_tex(UIThemeAssets.CYBER_BANNER)
	cyber_progress_fill_texture = _try_load_tex(UIThemeAssets.CYBER_PROGRESS_FILL)
	cyber_progress_alert_texture = _try_load_tex(UIThemeAssets.CYBER_PROGRESS_ALERT)
	cyber_progress_back_texture = _try_load_tex(UIThemeAssets.CYBER_PROGRESS_BACK)

	icon_play = _try_load_tex(UIThemeAssets.ICON_PLAY)
	icon_pause = _try_load_tex(UIThemeAssets.ICON_PAUSE)
	icon_home = _try_load_tex(UIThemeAssets.ICON_HOME)
	icon_gear = _try_load_tex(UIThemeAssets.ICON_GEAR)
	icon_trophy = _try_load_tex(UIThemeAssets.ICON_TROPHY)
	icon_cross = _try_load_tex(UIThemeAssets.ICON_CROSS)
	icon_check = _try_load_tex(UIThemeAssets.ICON_CHECK)
	icon_audio_on = _try_load_tex(UIThemeAssets.ICON_AUDIO_ON)
	icon_audio_off = _try_load_tex(UIThemeAssets.ICON_AUDIO_OFF)
	icon_music_on = _try_load_tex(UIThemeAssets.ICON_MUSIC_ON)
	icon_music_off = _try_load_tex(UIThemeAssets.ICON_MUSIC_OFF)
	icon_coin = _try_load_tex(UIThemeAssets.ICON_COIN)
	icon_star = _try_load_tex(UIThemeAssets.ICON_STAR)
	icon_warning = _try_load_tex(UIThemeAssets.ICON_WARNING)


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
	return ThemeRegistryScript.get_profile().get("ui", {}).get("skin", UISkinIds.NATURE)


func get_color(color_id: String, skin_override: String = "") -> Color:
	var colors := _get_skin_colors(_resolve_skin(skin_override))
	return colors.get(color_id, COLOR_TEXT)


func make_label(text: String, size: int = FONT_BODY, color: Color = COLOR_TEXT, skin_override: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if size >= FONT_HEADING and font_display:
		label.add_theme_font_override("font", font_display)
	elif font_primary:
		label.add_theme_font_override("font", font_primary)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func make_button(text: String, icon: Texture2D = null, size: int = FONT_BODY, variant: String = "primary", skin_override: String = "") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 74)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if font_button:
		btn.add_theme_font_override("font", font_button)
	btn.add_theme_font_size_override("font_size", size + 4)
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
				base_modulate = Color(0.99, 0.96, 0.86, 1.0)
				hover_modulate = Color(1.0, 0.99, 0.92, 1.0)
				pressed_modulate = Color(0.92, 0.86, 0.74, 1.0)
			"danger":
				source_texture = btn_danger_texture
				base_modulate = Color(0.98, 0.78, 0.78, 1.0)
				hover_modulate = Color(1.0, 0.84, 0.84, 1.0)
				pressed_modulate = Color(0.87, 0.65, 0.65, 1.0)
			_:
				source_texture = btn_primary_texture
				base_modulate = Color(0.86, 0.96, 0.78, 1.0)
				hover_modulate = Color(0.93, 1.0, 0.86, 1.0)
				pressed_modulate = Color(0.72, 0.87, 0.62, 1.0)

	btn.add_theme_stylebox_override("normal", _make_texture_stylebox(source_texture, base_modulate, 28.0, 22.0))
	btn.add_theme_stylebox_override("hover", _make_texture_stylebox(source_texture, hover_modulate, 28.0, 22.0))
	btn.add_theme_stylebox_override("pressed", _make_texture_stylebox(source_texture, pressed_modulate, 28.0, 22.0))

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
	var tint: Color = colors["panel_bg"] if variant == "dark" else colors["panel_light"]
	var style := _make_texture_stylebox(tex, tint, 28.0, 26.0)
	if skin_id != "cyberprank" and style is StyleBoxTexture:
		var boxed := style as StyleBoxTexture
		boxed.expand_margin_left = 2.0
		boxed.expand_margin_right = 2.0
		boxed.expand_margin_top = 2.0
		boxed.expand_margin_bottom = 2.0
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


func make_line_edit(placeholder: String = "", text: String = "", skin_override: String = "") -> LineEdit:
	var line := LineEdit.new()
	line.placeholder_text = placeholder
	line.text = text
	line.custom_minimum_size = Vector2(320, 66)
	line.max_length = 20
	var skin_id := _resolve_skin(skin_override)
	var colors := _get_skin_colors(skin_id)
	if font_primary:
		line.add_theme_font_override("font", font_primary)
	line.add_theme_font_size_override("font_size", FONT_BODY)
	line.add_theme_color_override("font_color", colors["text_ink"])
	line.add_theme_color_override("font_placeholder_color", colors["text_dim"])
	line.add_theme_color_override("caret_color", colors["primary_dark"])
	var normal := StyleBoxFlat.new()
	normal.bg_color = colors["panel_light"]
	normal.border_color = Color(0.718, 0.522, 0.306, 1.0)
	normal.border_width_left = 3
	normal.border_width_top = 3
	normal.border_width_right = 3
	normal.border_width_bottom = 3
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 16
	normal.content_margin_bottom = 16
	line.add_theme_stylebox_override("normal", normal)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = colors["primary"]
	focus.shadow_color = colors["primary"].darkened(0.15)
	focus.shadow_size = 8
	line.add_theme_stylebox_override("focus", focus)
	var read_only := normal.duplicate() as StyleBoxFlat
	read_only.bg_color = colors["panel_bg"].darkened(0.04)
	line.add_theme_stylebox_override("read_only", read_only)
	return line


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
	if font_display:
		label.add_theme_font_override("font", font_display)
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
	return get_gameplay_skin()


func _get_skin_colors(skin_id: String) -> Dictionary:
	if skin_id == UISkinIds.CYBERPRANK:
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
		"panel_line": Color(0.718, 0.522, 0.306, 0.45),
	}

extends RefCounted

const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")

const THEME: Theme = preload("res://ui/theme/nature_theme.tres")
const SKIN: String = UISkinIds.NATURE

const BACKDROP_SKY := Color(0.84, 0.91, 0.79, 1.0)
const BACKDROP_SUN := Color(0.98, 0.94, 0.78, 0.24)
const BACKDROP_FOLIAGE := Color(0.28, 0.43, 0.20, 0.18)
const BACKDROP_MIST := Color(0.96, 0.93, 0.84, 0.05)
const BACKDROP_HORIZON := Color(0.18, 0.24, 0.12, 0.92)
const PANEL_BORDER := Color(0.58, 0.77, 0.45, 0.26)
const PANEL_SHADOW := Color(0.08, 0.05, 0.02, 0.26)
const CREAM_SURFACE := Color(0.95, 0.90, 0.80, 0.98)
const COIN_GLOW := Color(0.93, 0.78, 0.28, 0.98)
const LOCKED_WASH := Color(0.22, 0.19, 0.14, 0.78)


static func decorate_root(root: Control) -> void:
	root.theme = THEME
	root.anchors_preset = Control.PRESET_FULL_RECT
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0

	if root.has_node("NatureBackdrop"):
		return

	var backdrop := Control.new()
	backdrop.name = "NatureBackdrop"
	backdrop.anchors_preset = Control.PRESET_FULL_RECT
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	root.move_child(backdrop, 0)

	var base := ColorRect.new()
	base.anchors_preset = Control.PRESET_FULL_RECT
	base.anchor_right = 1.0
	base.anchor_bottom = 1.0
	base.color = BACKDROP_SKY
	backdrop.add_child(base)

	var sun := ColorRect.new()
	sun.anchor_left = 0.5
	sun.anchor_right = 0.5
	sun.offset_left = -320.0
	sun.offset_right = 320.0
	sun.offset_top = 30.0
	sun.offset_bottom = 250.0
	sun.color = BACKDROP_SUN
	sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(sun)

	var left_glow := ColorRect.new()
	left_glow.anchor_top = 0.14
	left_glow.anchor_bottom = 0.92
	left_glow.offset_right = 240.0
	left_glow.color = BACKDROP_FOLIAGE
	left_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(left_glow)

	var right_glow := ColorRect.new()
	right_glow.anchor_left = 1.0
	right_glow.anchor_right = 1.0
	right_glow.anchor_top = 0.10
	right_glow.anchor_bottom = 0.88
	right_glow.offset_left = -280.0
	right_glow.color = BACKDROP_FOLIAGE.darkened(0.14)
	right_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(right_glow)

	var horizon := ColorRect.new()
	horizon.anchor_top = 1.0
	horizon.anchor_right = 1.0
	horizon.anchor_bottom = 1.0
	horizon.offset_top = -210.0
	horizon.color = BACKDROP_HORIZON
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_child(horizon)

	for band_index in 5:
		var band := ColorRect.new()
		band.anchor_top = 1.0
		band.anchor_right = 1.0
		band.anchor_bottom = 1.0
		band.offset_top = -float(190 + band_index * 24)
		band.offset_bottom = -float(162 + band_index * 24)
		band.color = Color(0.14 + band_index * 0.018, 0.20 + band_index * 0.015, 0.10 + band_index * 0.010, 0.50 - band_index * 0.06)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(band)

	for mist_index in 4:
		var mist := ColorRect.new()
		mist.anchor_top = 0.16 + mist_index * 0.16
		mist.anchor_right = 1.0
		mist.anchor_bottom = 0.16 + mist_index * 0.16
		mist.offset_bottom = 30.0
		mist.color = BACKDROP_MIST
		mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.add_child(mist)


static func make_shell(root: Control, title: String, subtitle: String = "", width: float = 1240.0, height: float = 760.0) -> Dictionary:
	decorate_root(root)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	root.add_child(center)

	var frame := UITheme.make_panel("dark", SKIN)
	frame.custom_minimum_size = Vector2(width, height)
	center.add_child(frame)

	var frame_style := frame.get_theme_stylebox("panel", "PanelContainer")
	if frame_style is StyleBoxTexture:
		var stylebox := frame_style.duplicate() as StyleBoxTexture
		stylebox.modulate_color = UITheme.get_color("panel_bg", SKIN)
		frame.add_theme_stylebox_override("panel", stylebox)

	var shadow := ColorRect.new()
	shadow.anchors_preset = Control.PRESET_FULL_RECT
	shadow.anchor_right = 1.0
	shadow.anchor_bottom = 1.0
	shadow.offset_left = 14.0
	shadow.offset_top = 14.0
	shadow.color = PANEL_SHADOW
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(shadow)
	frame.move_child(shadow, 0)

	var outline := Panel.new()
	outline.anchors_preset = Control.PRESET_FULL_RECT
	outline.anchor_right = 1.0
	outline.anchor_bottom = 1.0
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color(0, 0, 0, 0)
	outline_style.border_color = PANEL_BORDER
	outline_style.border_width_left = 2
	outline_style.border_width_right = 2
	outline_style.border_width_top = 2
	outline_style.border_width_bottom = 2
	outline_style.corner_radius_top_left = 24
	outline_style.corner_radius_top_right = 24
	outline_style.corner_radius_bottom_left = 24
	outline_style.corner_radius_bottom_right = 24
	outline.add_theme_stylebox_override("panel", outline_style)
	frame.add_child(outline)

	var margin := MarginContainer.new()
	margin.anchors_preset = Control.PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 32)
	frame.add_child(margin)

	var shell_vbox := VBoxContainer.new()
	shell_vbox.add_theme_constant_override("separation", 24)
	margin.add_child(shell_vbox)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	shell_vbox.add_child(header)

	var title_label := UITheme.make_label(title, UITheme.FONT_TITLE, UITheme.get_color("text", SKIN), SKIN)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if UITheme.font_display:
		title_label.add_theme_font_override("font", UITheme.font_display)
	header.add_child(title_label)

	if not subtitle.is_empty():
		var subtitle_label := UITheme.make_label(subtitle, UITheme.FONT_SMALL, UITheme.get_color("text_dim", SKIN), SKIN)
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		header.add_child(subtitle_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	shell_vbox.add_child(content)

	return {
		"frame": frame,
		"margin": margin,
		"shell": shell_vbox,
		"content": content,
	}


static func make_card(title: String = "", subtitle: String = "", min_size: Vector2 = Vector2(320, 240), light: bool = false) -> PanelContainer:
	var card := UITheme.make_panel("light" if light else "dark", SKIN)
	card.custom_minimum_size = min_size
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	if not title.is_empty():
		var title_label := UITheme.make_label(title, UITheme.FONT_HEADING, UITheme.get_color("text", SKIN) if not light else UITheme.get_color("text_ink", SKIN), SKIN)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		vbox.add_child(title_label)

	if not subtitle.is_empty():
		var subtitle_label := UITheme.make_label(subtitle, UITheme.FONT_SMALL, UITheme.get_color("text_dim", SKIN) if not light else UITheme.get_color("text_ink_soft", SKIN), SKIN)
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(subtitle_label)

	card.set_meta("body", vbox)
	return card


static func make_value_chip(text: String, selected: bool = false) -> Button:
	var variant := "primary" if selected else "secondary"
	var chip := UITheme.make_button(text, null, UITheme.FONT_SMALL, variant, SKIN)
	chip.custom_minimum_size = Vector2(140, 58)
	return chip


static func make_preview(image_path: String, size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(image_path):
		texture_rect.texture = load(image_path) as Texture2D
	return texture_rect


static func make_coin_label(text: String) -> Label:
	var label := UITheme.make_label(text, UITheme.FONT_SMALL, COIN_GLOW, SKIN)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label

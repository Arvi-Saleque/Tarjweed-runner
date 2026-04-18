extends Control
## ThemeSelect - Mode and runner selection shown after pressing PLAY.

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")
const ThemeSelectConfig = preload("res://scripts/ui/theme_select_config.gd")

signal selection_confirmed(mode_id: String, theme_id: String)
signal back_pressed

var _overlay: ColorRect
var _container: VBoxContainer
var _cards_scroll: ScrollContainer
var _cards_grid: GridContainer
var _cards: Array[PanelContainer] = []
var _back_btn: Button
var _header: Control
var _header_label: Label
var _sub: Label
var _notice: Label
var _selection_step: String = "mode"
var _selected_mode: String = "normal"
var _selected_theme: String = "nature"
var _selected_runner_id: String = ""
var _preview_pivots: Array[Node3D] = []

var _runner_stage: HBoxContainer
var _runner_showcase: PanelContainer
var _runner_preview_host: MarginContainer
var _runner_title: Label
var _runner_subtitle: Label
var _runner_meta: Label
var _runner_confirm_btn: Button
var _runner_roster_scroll: ScrollContainer
var _runner_roster_grid: GridContainer
var _runner_tiles: Dictionary = {}
var _runner_options: Array[Dictionary] = []


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_create_overlay()
	_create_layout()
	_refresh_cards()
	_animate_in()


func _process(delta: float) -> void:
	for pivot in _preview_pivots:
		if is_instance_valid(pivot):
			pivot.rotation.y += delta * 0.52


func _create_overlay() -> void:
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.89, 0.95, 0.88, 0.98)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	var sky := ColorRect.new()
	sky.anchor_left = 0.0
	sky.anchor_top = 0.0
	sky.anchor_right = 1.0
	sky.anchor_bottom = 0.56
	sky.color = Color(0.98, 0.97, 0.89, 0.24)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	for tree in [
		{"x": 0.08, "w": 110.0, "h": 280.0, "color": Color(0.50, 0.72, 0.38, 0.18)},
		{"x": 0.20, "w": 90.0, "h": 240.0, "color": Color(0.46, 0.66, 0.34, 0.16)},
		{"x": 0.76, "w": 110.0, "h": 300.0, "color": Color(0.44, 0.64, 0.32, 0.18)},
		{"x": 0.90, "w": 132.0, "h": 330.0, "color": Color(0.40, 0.58, 0.28, 0.20)},
	]:
		var canopy := ColorRect.new()
		canopy.anchor_left = tree["x"]
		canopy.anchor_top = 1.0
		canopy.anchor_right = tree["x"]
		canopy.anchor_bottom = 1.0
		canopy.offset_left = -tree["w"] * 0.5
		canopy.offset_top = -tree["h"]
		canopy.offset_right = tree["w"] * 0.5
		canopy.offset_bottom = -tree["h"] + 120.0
		canopy.color = tree["color"]
		canopy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(canopy)

	var grass := ColorRect.new()
	grass.anchors_preset = Control.PRESET_BOTTOM_WIDE
	grass.anchor_top = 1.0
	grass.anchor_right = 1.0
	grass.anchor_bottom = 1.0
	grass.offset_top = -124.0
	grass.color = Color(0.67, 0.85, 0.50, 0.78)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grass)


func _create_layout() -> void:
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	add_child(center)

	_container = VBoxContainer.new()
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 18)
	_container.custom_minimum_size = Vector2(1180, 0)
	center.add_child(_container)

	_header = UITheme.make_banner("CHOOSE MODE", UITheme.FONT_HEADING, UITheme.get_color("text_ink", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	_header_label = _header.get_child(_header.get_child_count() - 1) as Label
	_header.modulate.a = 0.0
	_container.add_child(_header)

	_sub = UITheme.make_label("Choose a mode, then pick a friendly runner.", UITheme.FONT_SMALL, UITheme.get_color("text_dim", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	_sub.modulate.a = 0.0
	_container.add_child(_sub)

	_cards_scroll = ScrollContainer.new()
	_cards_scroll.custom_minimum_size = Vector2(1120, 650)
	_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_cards_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_container.add_child(_cards_scroll)

	_cards_grid = GridContainer.new()
	_cards_grid.columns = 3
	_cards_grid.add_theme_constant_override("h_separation", 24)
	_cards_grid.add_theme_constant_override("v_separation", 24)
	_cards_scroll.add_child(_cards_grid)

	_runner_stage = HBoxContainer.new()
	_runner_stage.custom_minimum_size = Vector2(1160, 650)
	_runner_stage.add_theme_constant_override("separation", 24)
	_runner_stage.visible = false
	_container.add_child(_runner_stage)

	_create_runner_stage()

	_notice = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("accent", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	_notice.visible = false
	_notice.modulate.a = 0.0
	_container.add_child(_notice)

	_back_btn = UITheme.make_button("  BACK", UITheme.icon_cross, UITheme.FONT_BODY, "secondary", ThemeSelectConfig.ACTIVE_UI_SKIN)
	_back_btn.custom_minimum_size = Vector2(220, 60)
	_back_btn.modulate.a = 0.0
	_back_btn.pressed.connect(_on_back)
	_back_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_container.add_child(_back_btn)


func _create_runner_stage() -> void:
	_runner_showcase = UITheme.make_panel("dark", ThemeSelectConfig.ACTIVE_UI_SKIN)
	_runner_showcase.custom_minimum_size = Vector2(460, 650)
	_runner_showcase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_runner_stage.add_child(_runner_showcase)

	var showcase_margin := MarginContainer.new()
	showcase_margin.add_theme_constant_override("margin_left", 14)
	showcase_margin.add_theme_constant_override("margin_right", 14)
	showcase_margin.add_theme_constant_override("margin_top", 14)
	showcase_margin.add_theme_constant_override("margin_bottom", 14)
	_runner_showcase.add_child(showcase_margin)

	var showcase_inner := UITheme.make_panel("light", ThemeSelectConfig.ACTIVE_UI_SKIN)
	showcase_margin.add_child(showcase_inner)

	var showcase_padding := MarginContainer.new()
	showcase_padding.add_theme_constant_override("margin_left", 20)
	showcase_padding.add_theme_constant_override("margin_right", 20)
	showcase_padding.add_theme_constant_override("margin_top", 18)
	showcase_padding.add_theme_constant_override("margin_bottom", 18)
	showcase_inner.add_child(showcase_padding)

	var showcase_vbox := VBoxContainer.new()
	showcase_vbox.add_theme_constant_override("separation", 12)
	showcase_padding.add_child(showcase_vbox)

	var feature_label := UITheme.make_label("FEATURED RUNNER", UITheme.FONT_SMALL, UITheme.get_color("primary_dark", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	feature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	showcase_vbox.add_child(feature_label)

	_runner_preview_host = MarginContainer.new()
	_runner_preview_host.custom_minimum_size = Vector2(400, 330)
	showcase_vbox.add_child(_runner_preview_host)

	_runner_title = UITheme.make_label("", UITheme.FONT_HEADING, UITheme.get_color("text_ink", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	_runner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	showcase_vbox.add_child(_runner_title)

	_runner_subtitle = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("accent", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	_runner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	showcase_vbox.add_child(_runner_subtitle)

	_runner_meta = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_ink_soft", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	_runner_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_runner_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	showcase_vbox.add_child(_runner_meta)

	var meta_spacer := Control.new()
	meta_spacer.custom_minimum_size = Vector2(0, 8)
	showcase_vbox.add_child(meta_spacer)

	_runner_confirm_btn = UITheme.make_button("  SELECT RUNNER", UITheme.icon_play, UITheme.FONT_BODY, "primary", ThemeSelectConfig.ACTIVE_UI_SKIN)
	_runner_confirm_btn.custom_minimum_size = Vector2(300, 72)
	_runner_confirm_btn.pressed.connect(_confirm_selected_runner)
	_runner_confirm_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	showcase_vbox.add_child(_runner_confirm_btn)

	var roster_outer := UITheme.make_panel("dark", ThemeSelectConfig.ACTIVE_UI_SKIN)
	roster_outer.custom_minimum_size = Vector2(660, 650)
	roster_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_runner_stage.add_child(roster_outer)

	var roster_outer_margin := MarginContainer.new()
	roster_outer_margin.add_theme_constant_override("margin_left", 14)
	roster_outer_margin.add_theme_constant_override("margin_right", 14)
	roster_outer_margin.add_theme_constant_override("margin_top", 14)
	roster_outer_margin.add_theme_constant_override("margin_bottom", 14)
	roster_outer.add_child(roster_outer_margin)

	var roster_panel := UITheme.make_panel("light", ThemeSelectConfig.ACTIVE_UI_SKIN)
	roster_outer_margin.add_child(roster_panel)

	var roster_margin := MarginContainer.new()
	roster_margin.add_theme_constant_override("margin_left", 20)
	roster_margin.add_theme_constant_override("margin_right", 20)
	roster_margin.add_theme_constant_override("margin_top", 18)
	roster_margin.add_theme_constant_override("margin_bottom", 18)
	roster_panel.add_child(roster_margin)

	var roster_vbox := VBoxContainer.new()
	roster_vbox.add_theme_constant_override("separation", 12)
	roster_margin.add_child(roster_vbox)

	var roster_header := UITheme.make_label("RUNNER ROSTER", UITheme.FONT_SMALL, UITheme.get_color("text_ink", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	roster_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	roster_vbox.add_child(roster_header)

	var roster_sub := UITheme.make_label("Pick the one that looks easiest to spot while running.", UITheme.FONT_SMALL - 2, UITheme.get_color("text_ink_soft", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	roster_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	roster_vbox.add_child(roster_sub)

	_runner_roster_scroll = ScrollContainer.new()
	_runner_roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_runner_roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_runner_roster_scroll.custom_minimum_size = Vector2(0, 540)
	roster_vbox.add_child(_runner_roster_scroll)

	_runner_roster_grid = GridContainer.new()
	_runner_roster_grid.columns = 2
	_runner_roster_grid.add_theme_constant_override("h_separation", 18)
	_runner_roster_grid.add_theme_constant_override("v_separation", 18)
	_runner_roster_scroll.add_child(_runner_roster_grid)


func _clear_cards() -> void:
	_preview_pivots.clear()
	_runner_tiles.clear()
	for child in _cards_grid.get_children():
		child.queue_free()
	for child in _runner_roster_grid.get_children():
		child.queue_free()
	for child in _runner_preview_host.get_children():
		child.queue_free()
	_cards.clear()


func _refresh_cards() -> void:
	_clear_cards()
	_cards_scroll.scroll_vertical = 0
	_notice.visible = false
	_notice.modulate.a = 0.0
	_runner_stage.visible = false
	_cards_scroll.visible = true

	match _selection_step:
		"mode":
			_header_label.text = "CHOOSE MODE"
			_sub.text = "Choose a mode, then pick a friendly runner."
			_cards_grid.columns = 3
			for data in ThemeSelectConfig.MODES:
				var card := _create_card(data, "  PLAY", false)
				_cards_grid.add_child(card)
				_cards.append(card)
		"runner":
			_header_label.text = "CHOOSE RUNNER"
			_sub.text = "Pick a runner for %s mode." % _selected_mode.capitalize()
			_cards_scroll.visible = false
			_runner_stage.visible = true
			_runner_options = ThemeRegistryScript.get_player_options(_selected_theme)
			if _runner_options.is_empty():
				return
			if _selected_runner_id.is_empty():
				_selected_runner_id = GameManager.current_player_variant
			if _get_runner_option(_selected_runner_id).is_empty():
				_selected_runner_id = _runner_options[0].get("id", "")
			_build_runner_roster()
			_refresh_featured_runner()


func _create_card(data: Dictionary, button_text: String, is_disabled: bool) -> PanelContainer:
	var card := UITheme.make_panel("light", ThemeSelectConfig.ACTIVE_UI_SKIN)
	card.custom_minimum_size = Vector2(320, 376)
	card.modulate.a = 0.0

	var accent_color: Color = data.get("color", UITheme.get_color("primary", ThemeSelectConfig.ACTIVE_UI_SKIN))
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var icon_panel := PanelContainer.new()
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color(0.98, 0.95, 0.86, 1.0)
	icon_style.border_color = accent_color
	icon_style.border_width_left = 3
	icon_style.border_width_top = 3
	icon_style.border_width_right = 3
	icon_style.border_width_bottom = 3
	icon_style.corner_radius_top_left = 30
	icon_style.corner_radius_top_right = 30
	icon_style.corner_radius_bottom_left = 30
	icon_style.corner_radius_bottom_right = 30
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	icon_panel.custom_minimum_size = Vector2(116, 116)
	icon_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon_panel)

	var icon_vbox := VBoxContainer.new()
	icon_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	icon_vbox.anchors_preset = Control.PRESET_FULL_RECT
	icon_vbox.anchor_right = 1.0
	icon_vbox.anchor_bottom = 1.0
	icon_panel.add_child(icon_vbox)

	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(42, 42)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = _get_mode_icon(data.get("id", ""))
	texture_rect.modulate = accent_color
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_vbox.add_child(texture_rect)

	var icon_label := UITheme.make_label(data.get("icon_text", "?"), UITheme.FONT_SMALL, accent_color, ThemeSelectConfig.ACTIVE_UI_SKIN)
	icon_vbox.add_child(icon_label)

	var title := UITheme.make_label(data["title"], UITheme.FONT_HEADING, UITheme.get_color("text_ink", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	vbox.add_child(title)

	var subtitle := UITheme.make_label(data["subtitle"], UITheme.FONT_SMALL, UITheme.get_color("text_ink_soft", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	vbox.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var variant := "secondary" if is_disabled else "primary"
	var play_btn := UITheme.make_button(button_text, null, UITheme.FONT_BODY, variant, ThemeSelectConfig.ACTIVE_UI_SKIN)
	play_btn.custom_minimum_size = Vector2(220, 56)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.disabled = is_disabled
	if not is_disabled:
		var entry_id: String = data["id"]
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


func _build_runner_roster() -> void:
	_runner_roster_scroll.scroll_vertical = 0
	for data in _runner_options:
		var tile := _create_runner_tile(data)
		_runner_roster_grid.add_child(tile)
		_runner_tiles[data.get("id", "")] = tile


func _create_runner_tile(data: Dictionary) -> PanelContainer:
	var accent_color: Color = data.get("color", UITheme.get_color("primary", ThemeSelectConfig.ACTIVE_UI_SKIN))
	var tile := UITheme.make_panel("light", ThemeSelectConfig.ACTIVE_UI_SKIN)
	tile.custom_minimum_size = Vector2(280, 260)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	tile.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(_create_runner_preview(data, Vector2(248, 150), true))

	var title := UITheme.make_label(data.get("title", ""), UITheme.FONT_SMALL, UITheme.get_color("text_ink", ThemeSelectConfig.ACTIVE_UI_SKIN), ThemeSelectConfig.ACTIVE_UI_SKIN)
	vbox.add_child(title)

	var subtitle := UITheme.make_label(data.get("subtitle", ""), UITheme.FONT_SMALL - 2, accent_color, ThemeSelectConfig.ACTIVE_UI_SKIN)
	vbox.add_child(subtitle)

	var focus_btn := UITheme.make_button("  VIEW", null, UITheme.FONT_SMALL, "secondary", ThemeSelectConfig.ACTIVE_UI_SKIN)
	focus_btn.custom_minimum_size = Vector2(180, 46)
	focus_btn.pressed.connect(func(): _set_selected_runner(data.get("id", "")))
	focus_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	vbox.add_child(focus_btn)

	tile.set_meta("accent_color", accent_color)
	tile.set_meta("focus_btn", focus_btn)
	return tile


func _create_runner_preview(data: Dictionary, size: Vector2, use_3d_fallback: bool = true) -> Control:
	var accent_color: Color = data.get("color", UITheme.get_color("primary", ThemeSelectConfig.ACTIVE_UI_SKIN))
	var frame := PanelContainer.new()
	frame.custom_minimum_size = size
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.98, 0.95, 0.88, 0.98)
	frame_style.border_width_left = 3
	frame_style.border_width_top = 3
	frame_style.border_width_right = 3
	frame_style.border_width_bottom = 3
	frame_style.border_color = accent_color
	frame_style.corner_radius_top_left = 24
	frame_style.corner_radius_top_right = 24
	frame_style.corner_radius_bottom_left = 24
	frame_style.corner_radius_bottom_right = 24
	frame.add_theme_stylebox_override("panel", frame_style)

	var preview_image_path: String = data.get("preview_image_path", "")
	if ResourceLoader.exists(preview_image_path):
		var preview_tex := load(preview_image_path) as Texture2D
		if preview_tex:
			var tex_rect := TextureRect.new()
			tex_rect.custom_minimum_size = size
			tex_rect.texture = preview_tex
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.add_child(tex_rect)
			return frame

	if not use_3d_fallback:
		return frame

	var viewport_container := SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.custom_minimum_size = size
	frame.add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(int(size.x * 2.0), int(size.y * 2.0))
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)

	var root := Node3D.new()
	viewport.add_child(root)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.98, 0.96, 0.88, 1.0)
	environment.ambient_light_energy = 1.25
	env.environment = environment
	root.add_child(env)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.45, 4.6)
	camera.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	root.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(0.98, 0.93, 0.79)
	key_light.light_energy = 2.0
	key_light.rotation_degrees = Vector3(-42.0, 18.0, 0.0)
	root.add_child(key_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-1.6, 1.6, 1.8)
	rim_light.light_color = accent_color.lerp(Color(1.0, 0.92, 0.72), 0.25)
	rim_light.light_energy = 1.1
	rim_light.omni_range = 7.0
	root.add_child(rim_light)

	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.35
	floor_mesh.bottom_radius = 1.45
	floor_mesh.height = 0.08
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.97, 0.93, 0.80, 0.98)
	floor_mat.roughness = 0.92
	floor_mesh.material = floor_mat
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -1.0, 0.0)
	root.add_child(floor)

	var preview_pivot := Node3D.new()
	preview_pivot.rotation_degrees.y = -22.0
	root.add_child(preview_pivot)
	_preview_pivots.append(preview_pivot)

	var scene_path: String = data.get("base_scene_path", "")
	if ResourceLoader.exists(scene_path):
		var packed := load(scene_path) as PackedScene
		if packed:
			var model := packed.instantiate() as Node3D
			if model:
				model.scale = Vector3.ONE * float(data.get("preview_scale", 1.0))
				model.position.y = float(data.get("preview_height", -0.95))
				preview_pivot.add_child(model)
				_play_preview_animation(model)

	return frame


func _refresh_featured_runner() -> void:
	var data := _get_runner_option(_selected_runner_id)
	if data.is_empty():
		return

	for child in _runner_preview_host.get_children():
		child.queue_free()
	_runner_preview_host.add_child(_create_runner_preview(data, Vector2(400, 320), true))

	_runner_title.text = data.get("title", "")
	_runner_subtitle.text = data.get("subtitle", "").to_upper()
	_runner_meta.text = "%s mode runner\nClear shape. Easy to read. Good for quick play." % _selected_mode.capitalize()
	_runner_confirm_btn.text = "  SELECT %s" % data.get("title", "")

	for runner_id in _runner_tiles.keys():
		var tile := _runner_tiles[runner_id] as PanelContainer
		if tile == null:
			continue
		var focus_btn := tile.get_meta("focus_btn", null) as Button
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.98, 0.95, 0.88, 0.98)
		style.corner_radius_top_left = 24
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_left = 24
		style.corner_radius_bottom_right = 24
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		if runner_id == _selected_runner_id:
			style.border_color = UITheme.get_color("primary", ThemeSelectConfig.ACTIVE_UI_SKIN)
			style.shadow_color = UITheme.get_color("primary", ThemeSelectConfig.ACTIVE_UI_SKIN).darkened(0.18)
			style.shadow_size = 14
			tile.scale = Vector2(1.02, 1.02)
			if focus_btn:
				focus_btn.text = "  READY"
				focus_btn.disabled = true
		else:
			style.border_color = Color(0.72, 0.52, 0.30, 0.82)
			style.shadow_color = Color(0.36, 0.28, 0.14, 0.08)
			style.shadow_size = 0
			tile.scale = Vector2.ONE
			if focus_btn:
				focus_btn.text = "  VIEW"
				focus_btn.disabled = false
		tile.add_theme_stylebox_override("panel", style)


func _set_selected_runner(runner_id: String) -> void:
	if runner_id.is_empty() or runner_id == _selected_runner_id:
		return
	_selected_runner_id = runner_id
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_refresh_featured_runner()


func _confirm_selected_runner() -> void:
	if _selected_runner_id.is_empty():
		return
	AudioManager.play_ui_sound(AudioManager.ui_click)
	GameManager.current_player_variant = _selected_runner_id
	selection_confirmed.emit(GameManager.current_mode, _selected_theme)
	SceneManager.change_scene("res://scenes/game.tscn")


func _get_runner_option(runner_id: String) -> Dictionary:
	for option in _runner_options:
		if option.get("id", "") == runner_id:
			return option
	return {}


func _play_preview_animation(node: Node) -> void:
	var anim_player := _find_anim_player(node)
	if anim_player == null:
		return
	for anim_name in ThemeSelectConfig.PREVIEW_IDLE_ANIMS:
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
			return


func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_anim_player(child)
		if found:
			return found
	return null


func _animate_in() -> void:
	var items: Array[Control] = [_header, _sub]
	if _selection_step == "runner":
		items.append(_runner_stage)
	else:
		for card in _cards:
			items.append(card)
	if _notice.visible:
		items.append(_notice)
	items.append(_back_btn)

	for i in items.size():
		var item := items[i]
		item.modulate.a = 0.0 if item != _notice else item.modulate.a
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(item, "modulate:a", 1.0, 0.28).set_delay(i * 0.04)


func _on_entry_selected(entry_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)

	match _selection_step:
		"mode":
			_selected_mode = entry_id
			GameManager.current_mode = entry_id
			_selected_theme = "nature"
			GameManager.current_visual_theme = "nature"
			_selected_runner_id = ""
			if not ThemeRegistryScript.get_player_options(_selected_theme).is_empty():
				_selection_step = "runner"
				_refresh_cards()
				_animate_in()
				return
			GameManager.current_player_variant = "nature_default"
			selection_confirmed.emit(GameManager.current_mode, _selected_theme)
			SceneManager.change_scene("res://scenes/game.tscn")


func _on_back() -> void:
	AudioManager.play_back_sound()
	match _selection_step:
		"runner":
			_selection_step = "mode"
			_refresh_cards()
			_animate_in()
		_:
			back_pressed.emit()
			queue_free()


func _get_mode_icon(mode_id: String) -> Texture2D:
	match mode_id:
		"quiz":
			return UITheme.icon_star if UITheme.icon_star else UITheme.icon_coin
		"pronunciation":
			return UITheme.icon_audio_on if UITheme.icon_audio_on else UITheme.icon_gear
		_:
			return UITheme.icon_play

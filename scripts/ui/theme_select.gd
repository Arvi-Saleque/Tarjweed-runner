extends Control
## ThemeSelect - Multi-step mode/theme/player selection shown after pressing PLAY.
## Step 1: choose gameplay mode. Step 2: choose theme for normal mode.
## Step 3: if Cyberprank, choose the runner variant.

const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

signal selection_confirmed(mode_id: String, theme_id: String)
signal back_pressed

const PREVIEW_IDLE_ANIMS: Array[String] = [
	"Idle", "Idle_Neutral", "Idle_No_Loop", "Idle_A", "Idle_Gun_Pointing",
	"Running_A", "Run", "Walk",
]

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
var _cards_scroll: ScrollContainer
var _cards_grid: GridContainer
var _cards: Array[PanelContainer] = []
var _back_btn: Button
var _header: Control
var _sub: Label
var _notice: Label
var _selection_step: String = "mode"
var _selected_mode: String = "normal"
var _selected_theme: String = "nature"
var _preview_pivots: Array[Node3D] = []


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
			pivot.rotation.y += delta * 0.65


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
	_container.add_theme_constant_override("separation", 18)
	_container.custom_minimum_size = Vector2(1100, 0)
	center.add_child(_container)

	_header = UITheme.make_banner("CHOOSE MODE", UITheme.FONT_BODY, UITheme.COLOR_TEXT_INK)
	_header.modulate.a = 0.0
	_container.add_child(_header)

	_sub = UITheme.make_label("Select a game mode to play", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	_sub.modulate.a = 0.0
	_container.add_child(_sub)

	_cards_scroll = ScrollContainer.new()
	_cards_scroll.custom_minimum_size = Vector2(1140, 650)
	_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_cards_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_container.add_child(_cards_scroll)

	_cards_grid = GridContainer.new()
	_cards_grid.columns = 3
	_cards_grid.add_theme_constant_override("h_separation", 24)
	_cards_grid.add_theme_constant_override("v_separation", 24)
	_cards_scroll.add_child(_cards_grid)

	_notice = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.COLOR_ACCENT)
	_notice.visible = false
	_notice.modulate.a = 0.0
	_container.add_child(_notice)

	_back_btn = UITheme.make_button("  BACK", UITheme.icon_cross, UITheme.FONT_BODY, "secondary")
	_back_btn.custom_minimum_size = Vector2(200, 56)
	_back_btn.modulate.a = 0.0
	_back_btn.pressed.connect(_on_back)
	_back_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	_container.add_child(_back_btn)


func _clear_cards() -> void:
	_preview_pivots.clear()
	for card in _cards:
		if is_instance_valid(card):
			if card.get_parent():
				card.get_parent().remove_child(card)
			card.queue_free()
	_cards.clear()


func _get_entries_for_step() -> Array[Dictionary]:
	match _selection_step:
		"mode":
			return MODES
		"runner":
			return ThemeRegistryScript.get_player_options("cyberprank")
		_:
			return VISUAL_THEMES


func _refresh_cards() -> void:
	_clear_cards()
	_cards_scroll.scroll_vertical = 0
	_notice.visible = false
	_notice.modulate.a = 0.0

	var header_label := _header.get_child(1) as Label
	match _selection_step:
		"mode":
			header_label.text = "CHOOSE MODE"
			_sub.text = "Select a game mode to play"
			_cards_grid.columns = 3
		"theme":
			header_label.text = "CHOOSE THEME"
			_sub.text = "Pick the visual theme for %s mode" % _selected_mode.capitalize()
			_cards_grid.columns = 2
		"runner":
			header_label.text = "CHOOSE RUNNER"
			_sub.text = "Pick your Cyberprank player"
			_cards_grid.columns = 3

	for data in _get_entries_for_step():
		var is_disabled := false
		var button_text := "  PLAY"

		if _selection_step == "theme":
			var available_modes: Array = data.get("available_modes", [])
			is_disabled = _selected_mode not in available_modes
			button_text = "  START" if not is_disabled else "  SOON"
		elif _selection_step == "runner":
			button_text = "  SELECT"

		var card := _create_card(data, button_text, is_disabled)
		_cards_grid.add_child(card)
		_cards.append(card)


func _create_card(data: Dictionary, button_text: String, is_disabled: bool) -> PanelContainer:
	var is_runner_card: bool = _selection_step == "runner"
	var card := UITheme.make_panel("dark")
	card.custom_minimum_size = Vector2(320, 390) if is_runner_card else Vector2(300, 360)
	card.modulate.a = 0.0

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10 if is_runner_card else 16)
	card.add_child(vbox)

	if is_runner_card:
		vbox.add_child(_create_runner_preview(data))
	else:
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

	var title_font_size: int = UITheme.FONT_SMALL if is_runner_card else UITheme.FONT_HEADING
	var title := UITheme.make_label(data["title"], title_font_size, UITheme.COLOR_TEXT)
	vbox.add_child(title)

	if not is_runner_card:
		var subtitle := UITheme.make_label(data["subtitle"], UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
		vbox.add_child(subtitle)

	if is_disabled:
		var soon_badge := UITheme.make_label("CYBERPRANK COMING SOON", UITheme.FONT_SMALL, Color(0.95, 0.76, 0.30))
		vbox.add_child(soon_badge)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4 if is_runner_card else 12)
	vbox.add_child(spacer)

	var play_btn := Button.new()
	play_btn.text = button_text
	play_btn.custom_minimum_size = Vector2(220, 52)
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


func _create_runner_preview(data: Dictionary) -> Control:
	var accent_color: Color = data.get("color", Color(0.18, 0.84, 0.98))
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(250, 220)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.04, 0.08, 0.12, 0.94)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.border_color = accent_color.lightened(0.18)
	frame_style.corner_radius_top_left = 16
	frame_style.corner_radius_top_right = 16
	frame_style.corner_radius_bottom_left = 16
	frame_style.corner_radius_bottom_right = 16
	frame.add_theme_stylebox_override("panel", frame_style)

	var viewport_container := SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.custom_minimum_size = Vector2(250, 220)
	frame.add_child(viewport_container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(500, 440)
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
	environment.ambient_light_color = Color(0.58, 0.76, 0.92, 1.0)
	environment.ambient_light_energy = 1.6
	env.environment = environment
	root.add_child(env)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.45, 4.6)
	camera.look_at(Vector3(0.0, 1.05, 0.0), Vector3.UP)
	root.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.light_color = Color(0.72, 0.92, 1.0)
	key_light.light_energy = 2.3
	key_light.rotation_degrees = Vector3(-38.0, 24.0, 0.0)
	root.add_child(key_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(-1.6, 1.6, 1.8)
	rim_light.light_color = accent_color
	rim_light.light_energy = 1.5
	rim_light.omni_range = 7.0
	root.add_child(rim_light)

	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.35
	floor_mesh.bottom_radius = 1.45
	floor_mesh.height = 0.08
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.06, 0.10, 0.16, 0.94)
	floor_mat.emission_enabled = true
	floor_mat.emission = accent_color.darkened(0.15)
	floor_mat.emission_energy_multiplier = 0.45
	floor_mesh.material = floor_mat
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -1.0, 0.0)
	root.add_child(floor)

	var preview_pivot := Node3D.new()
	preview_pivot.rotation_degrees.y = -24.0
	root.add_child(preview_pivot)
	_preview_pivots.append(preview_pivot)

	var scene_path: String = data.get("base_scene_path", "")
	if ResourceLoader.exists(scene_path):
		var packed := load(scene_path) as PackedScene
		if packed:
			var model := packed.instantiate() as Node3D
			if model:
				var preview_scale: float = float(data.get("preview_scale", 1.0))
				var preview_height: float = float(data.get("preview_height", -0.95))
				model.scale = Vector3.ONE * preview_scale
				model.position.y = preview_height
				preview_pivot.add_child(model)
				_play_preview_animation(model)

	return frame


func _play_preview_animation(node: Node) -> void:
	var anim_player := _find_anim_player(node)
	if anim_player == null:
		return
	for anim_name in PREVIEW_IDLE_ANIMS:
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
			if entry_id == "normal":
				_selection_step = "theme"
				_refresh_cards()
				_animate_in()
			else:
				_start_mode_with_nature_notice(entry_id)
			return
		"theme":
			_selected_theme = entry_id
			GameManager.current_visual_theme = entry_id
			if entry_id == "cyberprank":
				_selection_step = "runner"
				_refresh_cards()
				_animate_in()
				return
			GameManager.current_player_variant = "nature_default"
			selection_confirmed.emit(GameManager.current_mode, entry_id)
			SceneManager.change_scene("res://scenes/game.tscn")
			return
		"runner":
			GameManager.current_player_variant = entry_id
			selection_confirmed.emit(GameManager.current_mode, _selected_theme)
			SceneManager.change_scene("res://scenes/game.tscn")
			return


func _start_mode_with_nature_notice(mode_id: String) -> void:
	GameManager.current_mode = mode_id
	GameManager.current_visual_theme = "nature"
	GameManager.current_player_variant = "nature_default"
	_notice.text = "Cyberprank for %s mode is coming soon. Starting in Nature." % mode_id.capitalize()
	_notice.visible = true
	_notice.modulate.a = 1.0
	selection_confirmed.emit(GameManager.current_mode, GameManager.current_visual_theme)
	await get_tree().create_timer(0.8).timeout
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_back() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	match _selection_step:
		"runner":
			_selection_step = "theme"
			_refresh_cards()
			_animate_in()
			return
		"theme":
			_selection_step = "mode"
			_refresh_cards()
			_animate_in()
			return

	back_pressed.emit()
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)

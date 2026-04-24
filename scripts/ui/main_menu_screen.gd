extends Control

const ChooseRunnerScene = preload("res://scenes/ui/ChooseRunner.tscn")
const LeaderboardScene = preload("res://scenes/ui/Leaderboard.tscn")
const PlaySetupPopupScene = preload("res://scenes/ui/PlaySetupPopup.tscn")
const SettingsScript = preload("res://scripts/ui/settings.gd")

const BASE_SIZE := Vector2(1600.0, 900.0)
const ASSET_ROOT := "res://assets/UI/mainmenu/"

var _stage: Control
var _wallet_value: Label
var _overlay_host: Control
var _settings_popup: Control
var _play_popup: Control
var _voice_loading_overlay: Control
var _start_in_progress := false


func _ready() -> void:
	theme = preload("res://ui/theme/nature_theme.tres")
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	_build_background()
	_build_stage()
	_build_overlay_host()
	_layout_stage()
	_refresh_wallet()
	AudioManager.fade_in_music(2.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_stage()


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.name = "MenuBackground"
	bg.texture = load(ASSET_ROOT + "menu-bg.png") as Texture2D
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_stage() -> void:
	_stage = Control.new()
	_stage.name = "MainMenuStage"
	_stage.size = BASE_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	_add_texture(_stage, "WalletBadgeArt", ASSET_ROOT + "coin_card.png", Rect2(36, 34, 292, 69))
	_wallet_value = _make_label("Wallet: 0", 25, Color("273411"))
	_wallet_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_wallet_value.position = Vector2(124, 41)
	_wallet_value.size = Vector2(170, 55)
	_stage.add_child(_wallet_value)

	_add_texture(_stage, "HeadingArt", ASSET_ROOT + "head-part.png", Rect2(384, 24, 836, 173))
	_add_texture(_stage, "MenuCardArt", ASSET_ROOT + "menu-card.png", Rect2(520, 198, 560, 651))

	_add_menu_button(
		Rect2(592, 316, 432, 89),
		"play.png",
		"green-circle.png",
		UITheme.icon_play,
		"Play",
		Color("FFF5DB"),
		42,
		func(): _open_play_setup()
	)
	_add_menu_button(
		Rect2(592, 435, 432, 74),
		"default.png",
		"green-circle.png",
		UITheme.icon_home,
		"Choose Runner",
		Color("214E22"),
		28,
		func(): _open_choose_runner()
	)
	_add_menu_button(
		Rect2(592, 520, 432, 74),
		"default.png",
		"green-circle.png",
		UITheme.icon_trophy,
		"Leaderboard",
		Color("214E22"),
		28,
		func(): _open_leaderboard()
	)
	_add_menu_button(
		Rect2(592, 605, 432, 74),
		"default.png",
		"green-circle.png",
		UITheme.icon_gear,
		"Settings",
		Color("214E22"),
		28,
		func(): _open_settings()
	)
	_add_menu_button(
		Rect2(592, 700, 432, 84),
		"exit.png",
		"red-circle.png",
		load(ASSET_ROOT + "exitic.png") as Texture2D,
		"Exit",
		Color("FFF5DB"),
		32,
		func(): _exit_game()
	)


func _build_overlay_host() -> void:
	_overlay_host = Control.new()
	_overlay_host.name = "OverlayHost"
	_overlay_host.anchors_preset = Control.PRESET_FULL_RECT
	_overlay_host.anchor_right = 1.0
	_overlay_host.anchor_bottom = 1.0
	_overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_host)


func _layout_stage() -> void:
	if _stage == null:
		return
	var viewport_size := get_viewport_rect().size
	var stage_scale := minf(viewport_size.x / BASE_SIZE.x, viewport_size.y / BASE_SIZE.y)
	_stage.size = BASE_SIZE
	_stage.scale = Vector2(stage_scale, stage_scale)
	_stage.position = (viewport_size - BASE_SIZE * stage_scale) * 0.5


func _add_texture(parent: Control, node_name: String, texture_path: String, rect: Rect2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.name = node_name
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.position = rect.position
	texture_rect.size = rect.size
	texture_rect.custom_minimum_size = Vector2.ZERO
	texture_rect.texture = load(texture_path) as Texture2D
	texture_rect.set_deferred("size", rect.size)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _add_menu_button(
	rect: Rect2,
	button_art: String,
	_circle_art: String,
	icon_texture: Texture2D,
	text: String,
	text_color: Color,
	font_size: int,
	pressed_callback: Callable
) -> void:
	var button := Button.new()
	button.name = text.replace(" ", "") + "Button"
	button.text = ""
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _transparent_style())
	button.add_theme_stylebox_override("hover", _transparent_style())
	button.add_theme_stylebox_override("pressed", _transparent_style())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_stage.add_child(button)

	var art := _add_texture(button, "Art", ASSET_ROOT + button_art, Rect2(Vector2.ZERO, rect.size))
	art.stretch_mode = TextureRect.STRETCH_SCALE

	var circle_size := rect.size.y * (0.78 if text == "Play" else 0.70)
	var circle_center_x := rect.size.y * (0.70 if text == "Play" else 0.66)
	var circle := Panel.new()
	circle.name = "IconBadge"
	circle.position = Vector2(circle_center_x - circle_size * 0.5, (rect.size.y - circle_size) * 0.5)
	circle.size = Vector2(circle_size, circle_size)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", _circle_style(text == "Exit", circle_size))
	button.add_child(circle)

	var icon_size := rect.size.y * (0.43 if text == "Play" else 0.45)
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(circle_center_x - icon_size * 0.5, (rect.size.y - icon_size) * 0.5)
	icon.size = Vector2(icon_size, icon_size)
	icon.custom_minimum_size = Vector2.ZERO
	icon.texture = icon_texture
	icon.modulate = Color("FFF5DB")
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)

	var label := _make_label(text, font_size, text_color)
	label.position = Vector2(0, 0)
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_shadow_color", Color(0.12, 0.06, 0.01, 0.42))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	button.add_child(label)

	button.pressed.connect(pressed_callback)
	button.mouse_entered.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_hover)
		var tween := button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.025, 1.025), 0.10)
	)
	button.mouse_exited.connect(func():
		var tween := button.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2.ONE, 0.10)
	)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := UITheme.make_label(text, font_size, color, "nature")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if UITheme.font_display:
		label.add_theme_font_override("font", UITheme.font_display)
	return label


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	return style


func _circle_style(is_danger: bool, diameter: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("B9542C") if is_danger else Color("6AAE2F")
	style.border_color = Color("6B2A18") if is_danger else Color("2D651C")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	var radius := int(diameter * 0.5)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.16, 0.09, 0.02, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1, 2)
	return style


func _refresh_wallet() -> void:
	if _wallet_value:
		_wallet_value.text = "Wallet: %d" % SaveManager.get_wallet_coins()


func _exit_game() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	get_tree().quit()


func _open_play_setup() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _play_popup and is_instance_valid(_play_popup):
		return
	_play_popup = PlaySetupPopupScene.instantiate()
	_play_popup.closed.connect(_on_play_popup_closed)
	_play_popup.choose_runner_requested.connect(func():
		if _play_popup and is_instance_valid(_play_popup):
			_open_choose_runner()
	)
	_play_popup.start_requested.connect(_start_game_from_setup)
	_overlay_host.add_child(_play_popup)


func _open_choose_runner() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	var screen := ChooseRunnerScene.instantiate()
	screen.back_pressed.connect(func():
		screen.queue_free()
		_refresh_after_overlay_change()
	)
	screen.runner_changed.connect(func(_runner_id: String):
		_refresh_after_overlay_change()
	)
	_overlay_host.add_child(screen)


func _open_leaderboard() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	var screen := LeaderboardScene.instantiate()
	screen.back_pressed.connect(func(): screen.queue_free())
	_overlay_host.add_child(screen)


func _open_settings() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _settings_popup and is_instance_valid(_settings_popup):
		return
	_settings_popup = Control.new()
	_settings_popup.set_script(SettingsScript)
	_overlay_host.add_child(_settings_popup)


func _refresh_after_overlay_change() -> void:
	_refresh_wallet()
	if _play_popup and is_instance_valid(_play_popup):
		if _play_popup.has_method("refresh_selected_runner"):
			_play_popup.call("refresh_selected_runner")
		elif _play_popup.has_method("refresh_summary"):
			_play_popup.call("refresh_summary")


func _on_play_popup_closed() -> void:
	_play_popup = null
	_refresh_wallet()


func _start_game_from_setup(player_name: String, difficulty_id: String, mode_id: String, quiz_style_id: String) -> void:
	if _start_in_progress:
		return
	_start_in_progress = true
	GameManager.current_mode = mode_id
	GameManager.current_quiz_style = quiz_style_id
	GameManager.current_visual_theme = "nature"
	GameManager.apply_menu_setup(player_name, difficulty_id, GameManager.current_player_variant)
	_refresh_wallet()
	if _play_popup and is_instance_valid(_play_popup):
		_play_popup.queue_free()
		_play_popup = null
	if mode_id == "pronunciation":
		_show_voice_loading_overlay()
		var reached := await PronunciationManager.warmup_backend_before_gameplay(1.5)
		_hide_voice_loading_overlay()
		if not reached and OS.get_name() == "Android":
			_start_in_progress = false
			_show_server_error_popup()
			return
		PronunciationManager.startup_warning_message = ""
	SceneManager.change_scene("res://scenes/game.tscn")


func _show_server_error_popup() -> void:
	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 300
	add_child(overlay)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 0)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("2A1F14")
	card_style.corner_radius_top_left = 20
	card_style.corner_radius_top_right = 20
	card_style.corner_radius_bottom_left = 20
	card_style.corner_radius_bottom_right = 20
	card_style.content_margin_left = 32.0
	card_style.content_margin_right = 32.0
	card_style.content_margin_top = 28.0
	card_style.content_margin_bottom = 28.0
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	var title := _make_label("Cannot Reach Server", UITheme.FONT_HEADING, Color("FF8A80"))
	vbox.add_child(title)

	var body := _make_label(
		"The pronunciation server is not reachable.\n\nMake sure your backend is running, then set your PC's IP address in Settings.",
		UITheme.FONT_BODY,
		Color("FFFAE8")
	)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(body)

	var ip_note := _make_label("Current server: %s" % PronunciationManager.ws_url, UITheme.FONT_SMALL, Color("A0A0A0"))
	ip_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ip_note)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var settings_btn := UITheme.make_button("Open Settings", null, UITheme.FONT_BODY, "primary", "nature")
	settings_btn.custom_minimum_size = Vector2(180, 56)
	settings_btn.pressed.connect(func():
		overlay.queue_free()
		_open_settings()
	)
	btn_row.add_child(settings_btn)

	var cancel_btn := UITheme.make_button("Cancel", null, UITheme.FONT_BODY, "secondary", "nature")
	cancel_btn.custom_minimum_size = Vector2(120, 56)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	btn_row.add_child(cancel_btn)


func _show_voice_loading_overlay() -> void:
	_hide_voice_loading_overlay()
	_voice_loading_overlay = Control.new()
	_voice_loading_overlay.name = "VoiceLoadingOverlay"
	_voice_loading_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_voice_loading_overlay.anchor_right = 1.0
	_voice_loading_overlay.anchor_bottom = 1.0
	_voice_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_voice_loading_overlay.z_index = 200
	add_child(_voice_loading_overlay)

	var shade := ColorRect.new()
	shade.anchors_preset = Control.PRESET_FULL_RECT
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.color = Color(0.06, 0.08, 0.06, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_voice_loading_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_voice_loading_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 220)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("F7F2E7")
	panel_style.border_color = Color("8A5A35")
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.18)
	panel_style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := _make_label("Preparing voice mode...", UITheme.FONT_HEADING, Color("234126"))
	box.add_child(title)

	var subtitle := _make_label("Connecting to pronunciation server...", UITheme.FONT_BODY, Color("364E36"))
	box.add_child(subtitle)

	var note := _make_label("This may take a few seconds on first launch.", UITheme.FONT_SMALL, Color("695F4A"))
	box.add_child(note)


func _hide_voice_loading_overlay() -> void:
	if _voice_loading_overlay and is_instance_valid(_voice_loading_overlay):
		_voice_loading_overlay.queue_free()
	_voice_loading_overlay = null

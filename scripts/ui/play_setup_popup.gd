extends Control

signal closed
signal choose_runner_requested
signal start_requested(player_name: String, difficulty_id: String)

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

var _name_input: LineEdit
var _difficulty_buttons: Dictionary = {}
var _preview: TextureRect
var _runner_title: Label
var _runner_subtitle: Label
var _selected_difficulty: String = MenuFlowCatalog.DEFAULT_DIFFICULTY


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_selected_difficulty = GameManager.current_difficulty_id if not GameManager.current_difficulty_id.is_empty() else MenuFlowCatalog.DEFAULT_DIFFICULTY
	_build_popup()
	_refresh_runner_preview()
	_refresh_difficulty_buttons()


func _build_popup() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	var overlay := ColorRect.new()
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = UITheme.get_color("overlay", NatureMenuStyle.SKIN)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shell := NatureMenuStyle.make_shell(
		self,
		"Play Setup",
		"Confirm your name, difficulty, and runner preview before starting the next run.",
		960.0,
		620.0
	)
	var frame := shell["frame"] as PanelContainer
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var content := shell["content"] as HBoxContainer

	var setup := NatureMenuStyle.make_card("Run Details", "This information will carry into the next Game Over leaderboard entry.", Vector2(420, 430), true)
	content.add_child(setup)
	var setup_body := setup.get_meta("body") as VBoxContainer

	var name_label := UITheme.make_label("Player Name", UITheme.FONT_SMALL, UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	setup_body.add_child(name_label)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = MenuFlowCatalog.DEFAULT_PLAYER_NAME
	_name_input.text = GameManager.current_player_name if not GameManager.current_player_name.is_empty() else SaveManager.get_player_name()
	_name_input.custom_minimum_size = Vector2(0, 56)
	_name_input.add_theme_color_override("font_color", UITheme.get_color("text_ink", NatureMenuStyle.SKIN))
	_name_input.add_theme_color_override("font_placeholder_color", UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN))
	_name_input.add_theme_color_override("caret_color", UITheme.get_color("primary_dark", NatureMenuStyle.SKIN))
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = NatureMenuStyle.CREAM_SURFACE
	input_style.border_color = NatureMenuStyle.PANEL_BORDER
	input_style.border_width_left = 2
	input_style.border_width_right = 2
	input_style.border_width_top = 2
	input_style.border_width_bottom = 2
	input_style.corner_radius_top_left = 12
	input_style.corner_radius_top_right = 12
	input_style.corner_radius_bottom_left = 12
	input_style.corner_radius_bottom_right = 12
	setup_body.add_child(_name_input)
	_name_input.add_theme_stylebox_override("normal", input_style)
	_name_input.add_theme_stylebox_override("focus", input_style)

	var difficulty_label := UITheme.make_label("Difficulty", UITheme.FONT_SMALL, UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	setup_body.add_child(difficulty_label)

	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_theme_constant_override("separation", 12)
	setup_body.add_child(difficulty_row)

	for difficulty in MenuFlowCatalog.DIFFICULTIES:
		var difficulty_id := difficulty.get("id", "")
		var btn := NatureMenuStyle.make_value_chip(difficulty.get("title", ""), difficulty_id == _selected_difficulty)
		btn.custom_minimum_size = Vector2(120, 56)
		btn.pressed.connect(func(): _set_difficulty(difficulty_id))
		difficulty_row.add_child(btn)
		_difficulty_buttons[difficulty_id] = btn

	var runner_hint := UITheme.make_label("Runner Preview", UITheme.FONT_SMALL, UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	runner_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	setup_body.add_child(runner_hint)

	var preview_card := NatureMenuStyle.make_card("", "", Vector2(0, 220), true)
	setup_body.add_child(preview_card)
	var preview_body := preview_card.get_meta("body") as VBoxContainer

	_preview = NatureMenuStyle.make_preview("", Vector2(260, 140))
	preview_body.add_child(_preview)

	_runner_title = UITheme.make_label("", UITheme.FONT_HEADING, UITheme.get_color("text_ink", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_runner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_body.add_child(_runner_title)

	_runner_subtitle = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_runner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_body.add_child(_runner_subtitle)

	var choose_runner_btn := UITheme.make_button("  Choose Runner", UITheme.icon_trophy, UITheme.FONT_SMALL, "secondary", NatureMenuStyle.SKIN)
	choose_runner_btn.custom_minimum_size = Vector2(220, 54)
	choose_runner_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		choose_runner_requested.emit()
	)
	preview_body.add_child(choose_runner_btn)

	var actions := NatureMenuStyle.make_card("Start Run", "The game launches with the current runner and saved setup.", Vector2(360, 430))
	content.add_child(actions)
	var actions_body := actions.get_meta("body") as VBoxContainer

	var difficulty_summary := UITheme.make_label("Selected difficulty changes leaderboard metadata first, and gameplay tuning can expand next.", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	difficulty_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	difficulty_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions_body.add_child(difficulty_summary)

	var summary_card := NatureMenuStyle.make_card("Current Summary", "", Vector2(0, 220), true)
	actions_body.add_child(summary_card)
	var summary_body := summary_card.get_meta("body") as VBoxContainer
	summary_body.add_child(NatureMenuStyle.make_coin_label("Wallet coins: %d" % SaveManager.get_wallet_coins()))

	var start_btn := UITheme.make_button("  Start", UITheme.icon_play, UITheme.FONT_BODY, "primary", NatureMenuStyle.SKIN)
	start_btn.custom_minimum_size = Vector2(240, 64)
	start_btn.pressed.connect(_on_start_pressed)
	actions_body.add_child(start_btn)

	var cancel_btn := UITheme.make_button("  Cancel", UITheme.icon_cross, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	cancel_btn.custom_minimum_size = Vector2(240, 64)
	cancel_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		closed.emit()
		queue_free()
	)
	actions_body.add_child(cancel_btn)


func _set_difficulty(difficulty_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_selected_difficulty = difficulty_id
	_refresh_difficulty_buttons()


func _refresh_difficulty_buttons() -> void:
	for difficulty in MenuFlowCatalog.DIFFICULTIES:
		var difficulty_id := difficulty.get("id", "")
		var btn := _difficulty_buttons.get(difficulty_id) as Button
		if btn == null:
			continue
		var is_selected := difficulty_id == _selected_difficulty
		UITheme._apply_button_variant(btn, "primary" if is_selected else "secondary", NatureMenuStyle.SKIN)


func _refresh_runner_preview() -> void:
	var runner_id := GameManager.current_player_variant
	if runner_id.is_empty() or runner_id == "nature_default":
		runner_id = "elf"
	var runner := ThemeRegistryScript.get_player_profile("nature", runner_id)
	var preview_path := runner.get("preview_image_path", "")
	_preview.texture = load(preview_path) as Texture2D if ResourceLoader.exists(preview_path) else null
	_runner_title.text = runner.get("title", "")
	_runner_subtitle.text = runner.get("subtitle", "")


func _on_start_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	var player_name := _name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = MenuFlowCatalog.DEFAULT_PLAYER_NAME
	start_requested.emit(player_name, _selected_difficulty)

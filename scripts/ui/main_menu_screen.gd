extends Control

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const ChooseRunnerScene = preload("res://scenes/ui/ChooseRunner.tscn")
const LeaderboardScene = preload("res://scenes/ui/Leaderboard.tscn")
const PlaySetupPopupScene = preload("res://scenes/ui/PlaySetupPopup.tscn")
const SettingsScript = preload("res://scripts/ui/settings.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

var _summary_preview: TextureRect
var _summary_runner: Label
var _summary_details: Label
var _summary_wallet: Label
var _summary_best: Label
var _wallet_badge_value: Label
var _overlay_host: Control
var _settings_popup: Control
var _play_popup: Control


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_build_layout()
	_refresh_summary()
	AudioManager.fade_in_music(2.0)


func _build_layout() -> void:
	var shell := NatureMenuStyle.make_shell(
		self,
		"Runner Realms",
		"A unified nature-themed front end for play setup, runner browsing, leaderboard viewing, and settings.",
		1260.0,
		760.0
	)
	var content := shell["content"] as HBoxContainer

	var status := NatureMenuStyle.make_card("Adventure Summary", "The active runner, difficulty, and saved stats stay visible from the main menu.", Vector2(430, 620))
	content.add_child(status)
	var status_body := status.get_meta("body") as VBoxContainer

	_summary_preview = NatureMenuStyle.make_preview("", Vector2(360, 220))
	status_body.add_child(_summary_preview)

	_summary_runner = UITheme.make_label("", UITheme.FONT_HEADING, UITheme.get_color("text", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_summary_runner.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	status_body.add_child(_summary_runner)

	_summary_details = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_summary_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_summary_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_body.add_child(_summary_details)

	var stat_card := NatureMenuStyle.make_card("Saved Progress", "", Vector2(0, 180), true)
	status_body.add_child(stat_card)
	var stat_body := stat_card.get_meta("body") as VBoxContainer

	_summary_wallet = NatureMenuStyle.make_coin_label("")
	stat_body.add_child(_summary_wallet)

	_summary_best = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_ink", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_summary_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stat_body.add_child(_summary_best)

	var actions := NatureMenuStyle.make_card("Main Menu", "Use Play to open the setup popup. Choose Runner and Leaderboard are available as full screens from here.", Vector2(700, 620))
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(actions)
	var actions_body := actions.get_meta("body") as VBoxContainer

	var play_btn := UITheme.make_button("  Play", UITheme.icon_play, UITheme.FONT_BODY, "primary", NatureMenuStyle.SKIN)
	play_btn.custom_minimum_size = Vector2(320, 68)
	UITheme.align_text_button_left(play_btn)
	play_btn.pressed.connect(_open_play_setup)
	actions_body.add_child(play_btn)

	var choose_runner_btn := UITheme.make_button("  Choose Runner", UITheme.icon_trophy, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	choose_runner_btn.custom_minimum_size = Vector2(320, 68)
	UITheme.align_text_button_left(choose_runner_btn)
	choose_runner_btn.pressed.connect(_open_choose_runner)
	actions_body.add_child(choose_runner_btn)

	var leaderboard_btn := UITheme.make_button("  Leaderboard", UITheme.icon_coin, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	leaderboard_btn.custom_minimum_size = Vector2(320, 68)
	UITheme.align_text_button_left(leaderboard_btn)
	leaderboard_btn.pressed.connect(_open_leaderboard)
	actions_body.add_child(leaderboard_btn)

	var settings_btn := UITheme.make_button("  Settings", UITheme.icon_gear, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	settings_btn.custom_minimum_size = Vector2(320, 68)
	UITheme.align_text_button_left(settings_btn)
	settings_btn.pressed.connect(_open_settings)
	actions_body.add_child(settings_btn)

	var exit_btn := UITheme.make_button("  Exit", UITheme.icon_cross, UITheme.FONT_BODY, "danger", NatureMenuStyle.SKIN)
	exit_btn.custom_minimum_size = Vector2(320, 68)
	UITheme.align_text_button_left(exit_btn)
	exit_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		get_tree().quit()
	)
	actions_body.add_child(exit_btn)

	_overlay_host = Control.new()
	_overlay_host.name = "OverlayHost"
	_overlay_host.anchors_preset = Control.PRESET_FULL_RECT
	_overlay_host.anchor_right = 1.0
	_overlay_host.anchor_bottom = 1.0
	_overlay_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_host)

	_build_wallet_badge()


func _build_wallet_badge() -> void:
	var wallet_badge := UITheme.make_panel("light", NatureMenuStyle.SKIN)
	wallet_badge.name = "WalletBadge"
	wallet_badge.anchor_left = 0.0
	wallet_badge.anchor_top = 0.0
	wallet_badge.anchor_right = 0.0
	wallet_badge.anchor_bottom = 0.0
	wallet_badge.offset_left = 24.0
	wallet_badge.offset_top = 20.0
	wallet_badge.offset_right = 246.0
	wallet_badge.offset_bottom = 92.0
	wallet_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_badge.z_index = 100
	add_child(wallet_badge)

	var badge_margin := MarginContainer.new()
	badge_margin.add_theme_constant_override("margin_left", 14)
	badge_margin.add_theme_constant_override("margin_top", 12)
	badge_margin.add_theme_constant_override("margin_right", 14)
	badge_margin.add_theme_constant_override("margin_bottom", 12)
	badge_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_badge.add_child(badge_margin)

	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 12)
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_margin.add_child(badge_row)

	var badge_icon := TextureRect.new()
	badge_icon.texture = UITheme.icon_coin if UITheme.icon_coin else UITheme.icon_trophy
	badge_icon.custom_minimum_size = Vector2(38, 38)
	badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge_icon)

	var badge_text := VBoxContainer.new()
	badge_text.add_theme_constant_override("separation", 2)
	badge_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_child(badge_text)

	var badge_caption := UITheme.make_label("Wallet coins", UITheme.FONT_SMALL - 4, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	badge_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	badge_text.add_child(badge_caption)

	_wallet_badge_value = UITheme.make_label("0", UITheme.FONT_HEADING, NatureMenuStyle.COIN_GLOW, NatureMenuStyle.SKIN)
	_wallet_badge_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	badge_text.add_child(_wallet_badge_value)


func _refresh_summary() -> void:
	var runner_id: String = str(GameManager.current_player_variant)
	if runner_id.is_empty() or runner_id == "nature_default":
		runner_id = "elf"
	var runner: Dictionary = ThemeRegistryScript.get_player_profile("nature", runner_id)
	var preview_path: String = str(runner.get("preview_image_path", ""))
	_summary_preview.texture = load(preview_path) as Texture2D if ResourceLoader.exists(preview_path) else null
	_summary_runner.text = "%s ready" % runner.get("title", "Runner")
	_summary_details.text = "Player: %s\nDifficulty: %s\nSubtitle: %s" % [
		GameManager.current_player_name if not GameManager.current_player_name.is_empty() else SaveManager.get_player_name(),
		"%s | %s" % [GameManager.current_mode.capitalize(), GameManager.current_difficulty_id.capitalize()],
		runner.get("subtitle", ""),
	]
	var wallet_coins: int = SaveManager.get_wallet_coins()
	_summary_wallet.text = "Wallet coins: %d" % wallet_coins
	_wallet_badge_value.text = str(wallet_coins)
	_summary_best.text = "Best score: %d" % SaveManager.get_high_score()


func _open_play_setup() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	if _play_popup and is_instance_valid(_play_popup):
		return
	_play_popup = PlaySetupPopupScene.instantiate()
	_play_popup.closed.connect(_on_overlay_closed)
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
		_refresh_summary()
		if _play_popup and is_instance_valid(_play_popup) and _play_popup.has_method("refresh_selected_runner"):
			_play_popup.call("refresh_selected_runner")
	)
	screen.runner_changed.connect(func(_runner_id: String):
		_refresh_summary()
		if _play_popup and is_instance_valid(_play_popup):
			if _play_popup.has_method("refresh_selected_runner"):
				_play_popup.call("refresh_selected_runner")
			elif _play_popup.has_method("refresh_summary"):
				_play_popup.call("refresh_summary")
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


func _start_game_from_setup(player_name: String, difficulty_id: String, mode_id: String, quiz_style_id: String) -> void:
	GameManager.current_mode = mode_id
	GameManager.current_quiz_style = quiz_style_id
	GameManager.current_visual_theme = "nature"
	GameManager.apply_menu_setup(player_name, difficulty_id, GameManager.current_player_variant)
	_refresh_summary()
	if _play_popup and is_instance_valid(_play_popup):
		_play_popup.queue_free()
		_play_popup = null
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_overlay_closed() -> void:
	_play_popup = null
	_refresh_summary()

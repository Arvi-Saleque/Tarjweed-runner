extends Control

signal back_pressed
signal runner_changed(runner_id: String)

const NatureMenuStyle = preload("res://scripts/ui/nature_menu_style.gd")
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")
const ThemeRegistryScript = preload("res://scripts/theme/theme_registry.gd")

var _featured_preview: TextureRect
var _featured_title: Label
var _featured_subtitle: Label
var _featured_meta: Label
var _wallet_label: Label
var _grid: GridContainer
var _selected_runner_id: String = ""
var _card_map: Dictionary = {}


func _ready() -> void:
	NatureMenuStyle.decorate_root(self)
	_selected_runner_id = GameManager.current_player_variant
	if _selected_runner_id.is_empty() or _selected_runner_id == "nature_default":
		_selected_runner_id = "elf"
	_build_layout()
	_rebuild_roster()
	_refresh_featured()


func _build_layout() -> void:
	var shell := NatureMenuStyle.make_shell(
		self,
		"Choose Runner",
		"Browse every nature runner. Unlocked runners can be selected now, while locked runners show their coin price.",
		1280.0,
		780.0
	)
	var content := shell["content"] as HBoxContainer

	var featured := NatureMenuStyle.make_card("Current Runner", "This selection is used in the Play setup popup and the upcoming run.", Vector2(400, 640))
	featured.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(featured)

	var featured_body := featured.get_meta("body") as VBoxContainer

	_featured_preview = NatureMenuStyle.make_preview("", Vector2(340, 280))
	featured_body.add_child(_featured_preview)

	_featured_title = UITheme.make_label("", UITheme.FONT_HEADING, UITheme.get_color("text", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_featured_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	featured_body.add_child(_featured_title)

	_featured_subtitle = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("accent", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_featured_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	featured_body.add_child(_featured_subtitle)

	_featured_meta = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("text_dim", NatureMenuStyle.SKIN), NatureMenuStyle.SKIN)
	_featured_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_featured_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	featured_body.add_child(_featured_meta)

	var wallet_card := NatureMenuStyle.make_card("Coin Wallet", "Unlocked runners stay available after purchase.", Vector2(0, 140), true)
	featured_body.add_child(wallet_card)
	var wallet_body := wallet_card.get_meta("body") as VBoxContainer
	_wallet_label = NatureMenuStyle.make_coin_label("")
	wallet_body.add_child(_wallet_label)

	var back_btn := UITheme.make_button("  Back", UITheme.icon_home, UITheme.FONT_BODY, "secondary", NatureMenuStyle.SKIN)
	back_btn.custom_minimum_size = Vector2(240, 64)
	back_btn.pressed.connect(func():
		AudioManager.play_ui_sound(AudioManager.ui_click)
		back_pressed.emit()
	)
	featured_body.add_child(back_btn)

	var roster := NatureMenuStyle.make_card("Runner Roster", "Select an unlocked runner or buy a locked one with saved coins.", Vector2(800, 640))
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(roster)

	var roster_body := roster.get_meta("body") as VBoxContainer
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_body.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(_grid)


func _rebuild_roster() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_card_map.clear()

	for runner in ThemeRegistryScript.get_player_options("nature"):
		var runner_id := runner.get("id", "")
		var card := _build_runner_card(runner)
		_grid.add_child(card)
		_card_map[runner_id] = card

	_wallet_label.text = "Available coins: %d" % SaveManager.get_wallet_coins()


func _build_runner_card(runner: Dictionary) -> PanelContainer:
	var runner_id := runner.get("id", "")
	var is_unlocked := SaveManager.is_runner_unlocked(runner_id)
	var price := MenuFlowCatalog.get_runner_price(runner_id)
	var is_selected := runner_id == _selected_runner_id

	var card := NatureMenuStyle.make_card(runner.get("title", ""), runner.get("subtitle", ""), Vector2(0, 300), true)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := card.get_meta("body") as VBoxContainer

	var preview := NatureMenuStyle.make_preview(runner.get("preview_image_path", ""), Vector2(280, 150))
	body.add_child(preview)

	var tag := UITheme.make_label(
		"Selected" if is_selected else "Unlocked" if is_unlocked else "Locked",
		UITheme.FONT_SMALL - 2,
		UITheme.get_color("primary_dark", NatureMenuStyle.SKIN) if is_unlocked else UITheme.get_color("danger", NatureMenuStyle.SKIN),
		NatureMenuStyle.SKIN
	)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.add_child(tag)

	var meta := UITheme.make_label(
		"Runner style: %s" % runner.get("icon_text", ""),
		UITheme.FONT_SMALL - 2,
		UITheme.get_color("text_ink_soft", NatureMenuStyle.SKIN),
		NatureMenuStyle.SKIN
	)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.add_child(meta)

	if not is_unlocked:
		var price_label := NatureMenuStyle.make_coin_label("Unlock for %d coins" % price)
		body.add_child(price_label)

	var action_btn := UITheme.make_button(
		"Selected" if is_selected else "Choose" if is_unlocked else "Buy %d" % price,
		UITheme.icon_check if is_selected else UITheme.icon_play if is_unlocked else UITheme.icon_coin,
		UITheme.FONT_SMALL,
		"primary" if is_selected or is_unlocked else "secondary",
		NatureMenuStyle.SKIN
	)
	action_btn.custom_minimum_size = Vector2(220, 54)
	action_btn.disabled = is_selected
	body.add_child(action_btn)

	if is_unlocked:
		action_btn.pressed.connect(func(): _select_runner(runner_id))
	else:
		action_btn.pressed.connect(func(): _buy_runner(runner_id, price))

	return card


func _select_runner(runner_id: String) -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_selected_runner_id = runner_id
	GameManager.current_player_variant = runner_id
	SaveManager.set_selected_runner_id(runner_id)
	_rebuild_roster()
	_refresh_featured()
	runner_changed.emit(runner_id)


func _buy_runner(runner_id: String, price: int) -> void:
	if not SaveManager.spend_wallet_coins(price):
		AudioManager.play_fail_sound()
		return

	AudioManager.play_ui_sound(AudioManager.ui_click)
	SaveManager.unlock_runner(runner_id)
	_select_runner(runner_id)


func _refresh_featured() -> void:
	var selected := ThemeRegistryScript.get_player_profile("nature", _selected_runner_id)
	_featured_preview.texture = load(selected.get("preview_image_path", "")) as Texture2D if ResourceLoader.exists(selected.get("preview_image_path", "")) else null
	_featured_title.text = selected.get("title", "")
	_featured_subtitle.text = selected.get("subtitle", "")
	_featured_meta.text = "Prepared for the play setup flow. This runner preview will be shown next to the name and difficulty options before the run begins."
	_wallet_label.text = "Available coins: %d" % SaveManager.get_wallet_coins()

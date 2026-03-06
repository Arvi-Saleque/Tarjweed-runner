extends CanvasLayer
## GameOver — End-of-run screen with score display, high score comparison, and navigation.

var _overlay: ColorRect
var _panel: PanelContainer
var _score_value: Label
var _high_score_label: Label
var _new_best_label: Label
var _coins_label: Label
var _distance_label: Label
var _retry_btn: Button
var _menu_btn: Button


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_create_screen()
	GameManager.game_over_triggered.connect(_on_game_over)


func _create_screen() -> void:
	# Dim overlay
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Center
	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	_overlay.add_child(center)

	# Main panel
	_panel = UITheme.make_panel()
	_panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	# "GAME OVER" title
	var title := UITheme.make_label("GAME OVER", UITheme.FONT_HEADING, UITheme.COLOR_DANGER)
	vbox.add_child(title)

	# Separator
	var sep := HSeparator.new()
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(1, 1, 1, 0.1)
	sep_style.content_margin_top = 1.0
	sep_style.content_margin_bottom = 8.0
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Score section
	var score_label := UITheme.make_label("SCORE", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	vbox.add_child(score_label)

	_score_value = UITheme.make_label("0", UITheme.FONT_TITLE, UITheme.COLOR_TEXT)
	vbox.add_child(_score_value)

	# NEW BEST label (hidden by default)
	_new_best_label = UITheme.make_label("NEW BEST!", UITheme.FONT_BODY, UITheme.COLOR_ACCENT)
	_new_best_label.visible = false
	vbox.add_child(_new_best_label)

	# High score
	_high_score_label = UITheme.make_label("BEST: 0", UITheme.FONT_SMALL, UITheme.COLOR_TEXT_DIM)
	vbox.add_child(_high_score_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Stats row
	var stats_hbox := HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 40)
	stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stats_hbox)

	# Coins earned
	var coins_vbox := VBoxContainer.new()
	coins_vbox.add_theme_constant_override("separation", 4)
	stats_hbox.add_child(coins_vbox)
	var coins_title := UITheme.make_label("COINS", UITheme.FONT_SMALL - 4, UITheme.COLOR_TEXT_DIM)
	coins_vbox.add_child(coins_title)
	_coins_label = UITheme.make_label("0", UITheme.FONT_HUD, UITheme.COLOR_ACCENT)
	coins_vbox.add_child(_coins_label)

	# Distance
	var dist_vbox := VBoxContainer.new()
	dist_vbox.add_theme_constant_override("separation", 4)
	stats_hbox.add_child(dist_vbox)
	var dist_title := UITheme.make_label("DISTANCE", UITheme.FONT_SMALL - 4, UITheme.COLOR_TEXT_DIM)
	dist_vbox.add_child(dist_title)
	_distance_label = UITheme.make_label("0m", UITheme.FONT_HUD, UITheme.COLOR_TEXT)
	dist_vbox.add_child(_distance_label)

	# Separator
	var sep2 := HSeparator.new()
	var sep2_style := StyleBoxFlat.new()
	sep2_style.bg_color = Color(1, 1, 1, 0.1)
	sep2_style.content_margin_top = 8.0
	sep2_style.content_margin_bottom = 4.0
	sep2.add_theme_stylebox_override("separator", sep2_style)
	vbox.add_child(sep2)

	# Buttons
	var btn_hbox := HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 16)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	_retry_btn = UITheme.make_button("  RETRY", UITheme.icon_play)
	_retry_btn.custom_minimum_size = Vector2(180, 60)
	_retry_btn.pressed.connect(_on_retry_pressed)
	_retry_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	btn_hbox.add_child(_retry_btn)

	_menu_btn = UITheme.make_button("  HOME", UITheme.icon_home)
	_menu_btn.custom_minimum_size = Vector2(180, 60)
	_menu_btn.pressed.connect(_on_menu_pressed)
	_menu_btn.mouse_entered.connect(func(): AudioManager.play_ui_sound(AudioManager.ui_hover))
	btn_hbox.add_child(_menu_btn)

	# Style home button darker
	var menu_normal := _menu_btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	menu_normal.bg_color = Color(0.3, 0.3, 0.35)
	_menu_btn.add_theme_stylebox_override("normal", menu_normal)
	var menu_hover := _menu_btn.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	menu_hover.bg_color = Color(0.4, 0.4, 0.45)
	_menu_btn.add_theme_stylebox_override("hover", menu_hover)


func _on_game_over() -> void:
	# Wait a moment for the death animation
	await get_tree().create_timer(1.2).timeout

	visible = true

	var final_score: int = GameManager.score
	var final_coins: int = GameManager.coins
	var final_dist: float = GameManager.distance
	var high_score: int = SaveManager.get_high_score()
	var is_new_best: bool = final_score >= high_score and final_score > 0

	_high_score_label.text = "BEST: %d" % high_score
	_coins_label.text = str(final_coins)
	_distance_label.text = "%dm" % int(final_dist)
	_new_best_label.visible = is_new_best

	# Entrance animation
	_overlay.color.a = 0.0
	_panel.scale = Vector2(0.7, 0.7)
	_panel.modulate.a = 0.0

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_overlay, "color:a", 0.7, 0.3)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.4)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.3)

	# Score counting animation
	_score_value.text = "0"
	await tween.finished
	_animate_score_count(final_score)

	# Flash NEW BEST
	if is_new_best:
		_animate_new_best()

	AudioManager.play_sfx(AudioManager.sfx_fail)


func _animate_score_count(target: int) -> void:
	var duration: float = clampf(float(target) / 500.0, 0.5, 2.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(val: float):
		_score_value.text = str(int(val))
	, 0.0, float(target), duration)


func _animate_new_best() -> void:
	_new_best_label.scale = Vector2(0.5, 0.5)
	_new_best_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_new_best_label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.parallel().tween_property(_new_best_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(_new_best_label, "scale", Vector2.ONE, 0.2)


func _on_retry_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_retry_btn.disabled = true
	_menu_btn.disabled = true
	visible = false
	# Reload the game scene
	SceneManager.change_scene("res://scenes/game.tscn")


func _on_menu_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	_retry_btn.disabled = true
	_menu_btn.disabled = true
	visible = false
	GameManager.go_to_menu()
	SceneManager.change_scene("res://scenes/main_menu.tscn")

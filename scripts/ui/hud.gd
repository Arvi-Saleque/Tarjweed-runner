extends CanvasLayer
## HUD — In-game heads-up display showing score, coins, distance, and pause button.

var _score_label: Label
var _coins_label: Label
var _distance_label: Label
var _speed_bar: ProgressBar
var _coin_icon: TextureRect
var _pause_btn: Button
var _root: Control
var _skin: String = "nature"
var _speed_label: Label

# Coin collect flash
var _coin_flash_tween: Tween


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_skin = UITheme.get_gameplay_skin()

	_create_hud()
	_connect_signals()
	visible = false  # Hidden until game starts


func _create_hud() -> void:
	_root = Control.new()
	_root.anchors_preset = Control.PRESET_FULL_RECT
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_create_top_bar()
	_create_speed_indicator()


func _create_top_bar() -> void:
	if _skin == "cyberprank":
		var top_glass := ColorRect.new()
		top_glass.anchors_preset = Control.PRESET_TOP_WIDE
		top_glass.anchor_right = 1.0
		top_glass.offset_top = 0.0
		top_glass.offset_bottom = 104.0
		top_glass.color = Color(0.01, 0.05, 0.09, 0.56)
		top_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(top_glass)

		var top_line := ColorRect.new()
		top_line.anchors_preset = Control.PRESET_TOP_WIDE
		top_line.anchor_right = 1.0
		top_line.offset_top = 100.0
		top_line.offset_bottom = 104.0
		top_line.color = Color(0.18, 0.90, 1.0, 0.72)
		top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(top_line)
	else:
		var top_wash := ColorRect.new()
		top_wash.anchors_preset = Control.PRESET_TOP_WIDE
		top_wash.anchor_right = 1.0
		top_wash.offset_top = 0.0
		top_wash.offset_bottom = 112.0
		top_wash.color = Color(0.98, 0.96, 0.88, 0.24)
		top_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(top_wash)

	var top_margin := MarginContainer.new()
	top_margin.anchors_preset = Control.PRESET_TOP_WIDE
	top_margin.anchor_right = 1.0
	top_margin.offset_top = 12.0
	top_margin.offset_bottom = 108.0
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(top_margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(hbox)

	# --- Left: Coins ---
	var coin_outer := UITheme.make_panel("dark", _skin)
	coin_outer.custom_minimum_size = Vector2(200, 84)
	hbox.add_child(coin_outer)

	var coin_outer_margin := MarginContainer.new()
	coin_outer_margin.add_theme_constant_override("margin_left", 10)
	coin_outer_margin.add_theme_constant_override("margin_right", 10)
	coin_outer_margin.add_theme_constant_override("margin_top", 10)
	coin_outer_margin.add_theme_constant_override("margin_bottom", 10)
	coin_outer.add_child(coin_outer_margin)

	var coin_panel := UITheme.make_panel("light", _skin)
	coin_outer_margin.add_child(coin_panel)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 8)
	coin_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_panel.add_child(coin_hbox)

	_coin_icon = TextureRect.new()
	if UITheme.icon_coin:
		_coin_icon.texture = UITheme.icon_coin
	elif UITheme.icon_trophy:
		_coin_icon.texture = UITheme.icon_trophy
	_coin_icon.custom_minimum_size = Vector2(36, 36)
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_hbox.add_child(_coin_icon)

	_coins_label = UITheme.make_label("0", UITheme.FONT_HUD, UITheme.get_color("accent", _skin), _skin)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_coins_label.custom_minimum_size = Vector2(80, 0)
	coin_hbox.add_child(_coins_label)

	# --- Center spacer + Score ---
	var center_spacer := Control.new()
	center_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(center_spacer)

	var score_panel := UITheme.make_panel("dark", _skin)
	score_panel.custom_minimum_size = Vector2(260, 104)
	hbox.add_child(score_panel)

	var score_margin := MarginContainer.new()
	score_margin.add_theme_constant_override("margin_left", 10)
	score_margin.add_theme_constant_override("margin_right", 10)
	score_margin.add_theme_constant_override("margin_top", 10)
	score_margin.add_theme_constant_override("margin_bottom", 10)
	score_panel.add_child(score_margin)

	var score_inner := UITheme.make_panel("light", _skin)
	score_margin.add_child(score_inner)

	var score_vbox := VBoxContainer.new()
	score_vbox.add_theme_constant_override("separation", 0)
	score_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_inner.add_child(score_vbox)

	_score_label = UITheme.make_label("0", UITheme.FONT_TITLE - 4, UITheme.get_color("text_ink", _skin), _skin)
	score_vbox.add_child(_score_label)

	_distance_label = UITheme.make_label("0m", UITheme.FONT_SMALL, UITheme.get_color("text_dim", _skin), _skin)
	score_vbox.add_child(_distance_label)

	# --- Right spacer + Pause ---
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right_spacer)

	_pause_btn = UITheme.make_icon_button(UITheme.icon_pause, "Pause", "light", _skin)
	_pause_btn.custom_minimum_size = Vector2(68, 68)
	_pause_btn.pressed.connect(_on_pause_pressed)
	hbox.add_child(_pause_btn)


func _create_speed_indicator() -> void:
	_speed_label = UITheme.make_label("", UITheme.FONT_SMALL, UITheme.get_color("accent", _skin), _skin)
	_speed_label.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_speed_label.anchor_top = 1.0
	_speed_label.anchor_right = 1.0
	_speed_label.anchor_bottom = 1.0
	_speed_label.offset_top = -34.0
	_speed_label.offset_bottom = -8.0
	_speed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_speed_label)

	# Speed bar at bottom of screen
	_speed_bar = ProgressBar.new()
	_speed_bar.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_speed_bar.anchor_top = 1.0
	_speed_bar.anchor_right = 1.0
	_speed_bar.anchor_bottom = 1.0
	_speed_bar.offset_top = -4.0
	_speed_bar.min_value = 0.0
	_speed_bar.max_value = 1.0
	_speed_bar.value = 0.0
	_speed_bar.show_percentage = false
	_speed_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Style the speed bar
	_speed_bar.add_theme_stylebox_override("background", UITheme.make_progress_stylebox("background", _skin))
	_speed_bar.add_theme_stylebox_override("fill", UITheme.make_progress_stylebox("fill", _skin))

	_root.add_child(_speed_bar)


func _connect_signals() -> void:
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.distance_updated.connect(_on_distance_updated)
	GameManager.speed_changed.connect(_on_speed_changed)


func _on_game_started() -> void:
	visible = true
	_coins_label.text = "0"
	_score_label.text = "0"
	_distance_label.text = "0m"
	_speed_bar.value = 0.0
	if _speed_label:
		_speed_label.text = "NEON DRIVE 0%" if _skin == "cyberprank" else "TRAIL PACE 0%"

	# Slide in animation
	_root.modulate.a = 0.0
	_root.position.y = -20.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_root, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(_root, "position:y", 0.0, 0.3)


func _on_game_over() -> void:
	# Fade out HUD
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): visible = false)


func _on_score_updated(new_score: int) -> void:
	_score_label.text = _format_number(new_score)


func _on_coin_collected(value: int) -> void:
	_coins_label.text = str(GameManager.coins)

	# Flash the coin icon gold
	if _coin_flash_tween and _coin_flash_tween.is_valid():
		_coin_flash_tween.kill()
	_coin_icon.modulate = UITheme.get_color("accent", _skin) * 2.0
	_coin_flash_tween = create_tween()
	_coin_flash_tween.tween_property(_coin_icon, "modulate", Color.WHITE, 0.3)

	# Scale pop on coins label
	_coins_label.scale = Vector2(1.3, 1.3)
	var pop_tween := create_tween()
	pop_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	pop_tween.tween_property(_coins_label, "scale", Vector2.ONE, 0.4)


func _on_distance_updated(new_distance: float) -> void:
	_distance_label.text = "%dm" % int(new_distance)


func _on_speed_changed(new_speed: float) -> void:
	_speed_bar.value = GameManager.get_speed_ratio()

	# Color shift from green to red as speed increases
	var ratio: float = GameManager.get_speed_ratio()
	if _speed_label:
		_speed_label.text = ("NEON DRIVE %d%%" if _skin == "cyberprank" else "TRAIL PACE %d%%") % int(ratio * 100.0)
		_speed_label.modulate = UITheme.get_color("accent" if ratio < 0.65 else "danger", _skin)
	_speed_bar.add_theme_stylebox_override(
		"fill",
			UITheme.make_progress_stylebox("fill" if ratio < 0.6 else "alert_fill", _skin)
	)


func _on_pause_pressed() -> void:
	AudioManager.play_ui_sound(AudioManager.ui_click)
	GameManager.pause_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and GameManager.is_playing():
		_on_pause_pressed()
		get_viewport().set_input_as_handled()


func _format_number(n: int) -> String:
	var s: String = str(n)
	if n < 1000:
		return s
	# Add comma separators
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

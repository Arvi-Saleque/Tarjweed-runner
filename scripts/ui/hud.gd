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
var _life_labels: Array[Label] = []

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
	_create_lives_panel()

	if not GameManager.is_quiz_mode() and not GameManager.is_pronunciation_mode():
		_create_speed_indicator()


func _create_top_bar() -> void:
	# IMPORTANT:
	# In quiz/pronunciation mode, do not draw the old top wash strip.
	if _skin != "cyberprank" and (GameManager.is_quiz_mode() or GameManager.is_pronunciation_mode()):
		_create_learning_mode_top_bar()
		return

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
	_coin_icon.custom_minimum_size = Vector2(44, 44)
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


func _create_learning_mode_top_bar() -> void:
	# --- Left: Coins ---
	var coin_outer := UITheme.make_panel("dark", _skin)
	coin_outer.custom_minimum_size = Vector2(200, 84)
	coin_outer.anchor_left = 0.0
	coin_outer.anchor_top = 0.0
	coin_outer.anchor_right = 0.0
	coin_outer.anchor_bottom = 0.0
	coin_outer.offset_left = 20.0
	coin_outer.offset_top = 12.0
	coin_outer.offset_right = 220.0
	coin_outer.offset_bottom = 96.0
	_root.add_child(coin_outer)

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
	_coin_icon.custom_minimum_size = Vector2(44, 44)
	_coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_hbox.add_child(_coin_icon)

	_coins_label = UITheme.make_label("0", UITheme.FONT_HUD, UITheme.get_color("accent", _skin), _skin)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_coins_label.custom_minimum_size = Vector2(80, 0)
	coin_hbox.add_child(_coins_label)

		# --- Right: Stats panel ---
	var stats_outer := UITheme.make_panel("dark", _skin)
	stats_outer.custom_minimum_size = Vector2(270, 120)
	stats_outer.anchor_left = 1.0
	stats_outer.anchor_top = 0.0
	stats_outer.anchor_right = 1.0
	stats_outer.anchor_bottom = 0.0
	stats_outer.offset_left = -350.0
	stats_outer.offset_top = 8.0
	stats_outer.offset_right = -100.0
	stats_outer.offset_bottom = 128.0
	_root.add_child(stats_outer)

	var stats_margin := MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 10)
	stats_margin.add_theme_constant_override("margin_right", 10)
	stats_margin.add_theme_constant_override("margin_top", 10)
	stats_margin.add_theme_constant_override("margin_bottom", 10)
	stats_outer.add_child(stats_margin)

	var stats_inner := UITheme.make_panel("light", _skin)
	stats_margin.add_child(stats_inner)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_inner.add_child(stats_vbox)

	# Score row
	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 8)
	score_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_vbox.add_child(score_row)

	var score_title := UITheme.make_label("Score", UITheme.FONT_SMALL, UITheme.get_color("text_ink", _skin), _skin)
	score_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(score_title)

	var score_pill := PanelContainer.new()
	score_pill.custom_minimum_size = Vector2(78, 34)
	score_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var score_pill_style := StyleBoxFlat.new()
	score_pill_style.bg_color = Color("2D7A3D")
	score_pill_style.corner_radius_top_left = 14
	score_pill_style.corner_radius_top_right = 14
	score_pill_style.corner_radius_bottom_left = 14
	score_pill_style.corner_radius_bottom_right = 14
	score_pill.add_theme_stylebox_override("panel", score_pill_style)
	score_row.add_child(score_pill)

	var score_pill_center := CenterContainer.new()
	score_pill_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_pill_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	score_pill_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_pill.add_child(score_pill_center)

	_score_label = UITheme.make_label("0", UITheme.FONT_BODY, Color.WHITE, _skin)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_pill_center.add_child(_score_label)

	# Divider
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = Color(0.55, 0.40, 0.24, 0.28)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_vbox.add_child(divider)

	# Distance row
	var distance_row := HBoxContainer.new()
	distance_row.add_theme_constant_override("separation", 8)
	distance_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_vbox.add_child(distance_row)

	var distance_title := UITheme.make_label("Distance", UITheme.FONT_SMALL, UITheme.get_color("text_ink", _skin), _skin)
	distance_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	distance_row.add_child(distance_title)

	var distance_pill := PanelContainer.new()
	distance_pill.custom_minimum_size = Vector2(90, 34)
	distance_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var distance_pill_style := StyleBoxFlat.new()
	distance_pill_style.bg_color = Color("2D7A3D")
	distance_pill_style.corner_radius_top_left = 14
	distance_pill_style.corner_radius_top_right = 14
	distance_pill_style.corner_radius_bottom_left = 14
	distance_pill_style.corner_radius_bottom_right = 14
	distance_pill.add_theme_stylebox_override("panel", distance_pill_style)
	distance_row.add_child(distance_pill)

	var distance_pill_center := CenterContainer.new()
	distance_pill_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	distance_pill_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	distance_pill_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	distance_pill.add_child(distance_pill_center)

	_distance_label = UITheme.make_label("0m", UITheme.FONT_BODY - 2, Color.WHITE, _skin)
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_pill_center.add_child(_distance_label)

	# --- Far right: Pause ---
	_pause_btn = UITheme.make_icon_button(UITheme.icon_pause, "Pause", "light", _skin)
	_pause_btn.custom_minimum_size = Vector2(68, 68)
	_pause_btn.anchor_left = 1.0
	_pause_btn.anchor_top = 0.0
	_pause_btn.anchor_right = 1.0
	_pause_btn.anchor_bottom = 0.0
	_pause_btn.offset_left = -88.0
	_pause_btn.offset_top = 16.0
	_pause_btn.offset_right = -20.0
	_pause_btn.offset_bottom = 84.0
	_pause_btn.pressed.connect(_on_pause_pressed)
	_root.add_child(_pause_btn)


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
	GameManager.coin_delta_feedback.connect(_on_coin_delta_feedback)
	GameManager.distance_updated.connect(_on_distance_updated)
	GameManager.speed_changed.connect(_on_speed_changed)
	GameManager.lives_changed.connect(_on_lives_changed)


func _on_game_started() -> void:
	for child in _root.get_children():
		child.queue_free()

	_create_top_bar()
	_create_lives_panel()

	if not GameManager.is_quiz_mode() and not GameManager.is_pronunciation_mode():
		_create_speed_indicator()

	visible = true
	_coins_label.text = "0"
	_score_label.text = "0"
	_distance_label.text = "0m"
	_refresh_lives(GameManager.current_lives, GameManager.get_max_lives())

	if _speed_bar:
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
	if value == 0:
		return

	# Flash the coin icon gold
	if _coin_flash_tween and _coin_flash_tween.is_valid():
		_coin_flash_tween.kill()
	var flash_color := UITheme.get_color("accent", _skin) * 2.0 if value > 0 else UITheme.get_color("danger", _skin) * 1.5
	_coin_icon.modulate = flash_color
	_coin_flash_tween = create_tween()
	_coin_flash_tween.tween_property(_coin_icon, "modulate", Color.WHITE, 0.3)

	# Scale pop on coins label
	_coins_label.scale = Vector2(1.3, 1.3)
	var pop_tween := create_tween()
	pop_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	pop_tween.tween_property(_coins_label, "scale", Vector2.ONE, 0.4)


func _on_coin_delta_feedback(delta: int) -> void:
	if delta == 0:
		return
	_spawn_coin_delta_popup(delta)


func _on_lives_changed(current_lives: int, max_lives: int) -> void:
	_refresh_lives(current_lives, max_lives)


func _on_distance_updated(new_distance: float) -> void:
	_distance_label.text = "%dm" % int(new_distance)


func _on_speed_changed(new_speed: float) -> void:
	var ratio: float = GameManager.get_speed_ratio()

	if _speed_bar:
		_speed_bar.value = ratio
		_speed_bar.add_theme_stylebox_override(
			"fill",
			UITheme.make_progress_stylebox("fill" if ratio < 0.6 else "alert_fill", _skin)
		)

	if _speed_label:
		_speed_label.text = ("NEON DRIVE %d%%" if _skin == "cyberprank" else "TRAIL PACE %d%%") % int(ratio * 100.0)
		_speed_label.modulate = UITheme.get_color("accent" if ratio < 0.65 else "danger", _skin)


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


func _create_lives_panel() -> void:
	_life_labels.clear()

	var lives_outer := UITheme.make_panel("dark", _skin)
	lives_outer.custom_minimum_size = Vector2(170, 58)
	lives_outer.anchor_left = 0.0
	lives_outer.anchor_top = 0.0
	lives_outer.anchor_right = 0.0
	lives_outer.anchor_bottom = 0.0
	lives_outer.offset_left = 20.0
	lives_outer.offset_top = 104.0
	lives_outer.offset_right = 190.0
	lives_outer.offset_bottom = 162.0
	lives_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(lives_outer)

	var lives_margin := MarginContainer.new()
	lives_margin.add_theme_constant_override("margin_left", 10)
	lives_margin.add_theme_constant_override("margin_right", 10)
	lives_margin.add_theme_constant_override("margin_top", 6)
	lives_margin.add_theme_constant_override("margin_bottom", 6)
	lives_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives_outer.add_child(lives_margin)

	var lives_panel := UITheme.make_panel("light", _skin)
	lives_margin.add_child(lives_panel)

	var lives_row := HBoxContainer.new()
	lives_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lives_row.add_theme_constant_override("separation", 10)
	lives_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives_panel.add_child(lives_row)

	for i in GameManager.get_max_lives():
		var heart := Label.new()
		heart.text = "♥"
		heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ThemeDB.fallback_font:
			heart.add_theme_font_override("font", ThemeDB.fallback_font)
		heart.add_theme_font_size_override("font_size", 28)
		lives_row.add_child(heart)
		_life_labels.append(heart)

	_refresh_lives(GameManager.current_lives, GameManager.get_max_lives())


func _refresh_lives(current_lives: int, max_lives: int) -> void:
	var full_color := Color("E34B4B")
	var empty_color := Color(0.52, 0.30, 0.34, 0.35)
	for i in range(_life_labels.size()):
		var heart := _life_labels[i]
		if heart == null:
			continue
		heart.add_theme_color_override("font_color", full_color if i < current_lives else empty_color)
		heart.scale = Vector2.ONE if i < current_lives else Vector2(0.90, 0.90)


func _spawn_coin_delta_popup(delta: int) -> void:
	if _root == null or _coin_icon == null:
		return

	var popup := HBoxContainer.new()
	popup.add_theme_constant_override("separation", 4)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(popup)

	var amount_color := Color("7ED957") if delta > 0 else Color("FF6B6B")
	var amount_label := UITheme.make_label("%+d" % delta, UITheme.FONT_BODY, amount_color, _skin)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	popup.add_child(amount_label)

	var popup_icon := TextureRect.new()
	popup_icon.texture = _coin_icon.texture if _coin_icon.texture != null else UITheme.icon_coin
	popup_icon.custom_minimum_size = Vector2(22, 22)
	popup_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	popup_icon.modulate = UITheme.get_color("accent", _skin)
	popup_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_child(popup_icon)

	var root_origin := _root.get_global_rect().position
	var coin_origin := _coin_icon.get_global_rect().position - root_origin
	popup.position = coin_origin + Vector2(50.0, 6.0)
	popup.modulate.a = 0.0

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(popup, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(popup, "position:y", popup.position.y - 24.0, 0.52)
	tween.tween_interval(0.06)
	tween.tween_property(popup, "modulate:a", 0.0, 0.22)
	tween.tween_callback(popup.queue_free)

extends Node
## GameManager - Global game state singleton.
## Manages score, coins, distance, speed, difficulty, and game state transitions.

const ControlsManager = preload("res://scripts/input/controls_manager.gd")
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")

# --- Signals ---
signal game_started
signal game_over_triggered
signal game_paused
signal game_resumed
signal coin_collected(value: int)
signal coin_delta_feedback(delta: int)
signal score_updated(new_score: int)
signal distance_updated(new_distance: float)
signal speed_changed(new_speed: float)
signal lives_changed(current_lives: int, max_lives: int)

# --- Enums ---
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

# --- Constants ---
const BASE_SPEED: float = 12.0
const MAX_SPEED: float = 28.0
const PRONUNCIATION_SPEED: float = 15.0
const SPEED_INCREMENT: float = 0.15        # Speed increase per second of play
const MAX_LIVES: int = 3
const LANE_WIDTH: float = 2.0
const LANE_COUNT: int = 3
const LANE_POSITIONS: Array[float] = [-2.0, 0.0, 2.0]
const QUIZ_CORRECT_COIN_REWARD: int = 50
const QUIZ_WRONG_COIN_PENALTY: int = -20

const COIN_VALUES: Dictionary = {
	"gold": 1,
}

const DIFFICULTY_PROFILES: Dictionary = {
	"easy": {
		"base_speed_scale": 0.92,
		"speed_ramp_scale": 0.78,
		"max_speed_scale": 0.88,
		"difficulty_min": 0.90,
		"difficulty_max": 1.70,
		"obstacle_base": 0.24,
		"obstacle_max": 0.52,
		"obstacle_scale": 0.80,
		"special_chance_scale": 0.72,
		"special_spacing_scale": 1.25,
		"quiz_number_scale": 0.80,
	},
	"medium": {
		# Starts at the same slow speed as Easy, but ramps faster and
		# reaches a higher max — so it escalates sooner.
		"base_speed_scale": 0.92,
		"speed_ramp_scale": 1.20,
		"max_speed_scale": 1.00,
		"difficulty_min": 1.00,
		"difficulty_max": 2.50,
		"obstacle_base": 0.30,
		"obstacle_max": 0.75,
		"obstacle_scale": 1.00,
		"special_chance_scale": 1.00,
		"special_spacing_scale": 1.00,
		"quiz_number_scale": 1.00,
	},
	"hard": {
		"base_speed_scale": 1.25,
		"speed_ramp_scale": 1.55,
		"max_speed_scale": 1.30,
		"difficulty_min": 1.12,
		"difficulty_max": 3.20,
		"obstacle_base": 0.36,
		"obstacle_max": 0.86,
		"obstacle_scale": 1.18,
		"special_chance_scale": 1.22,
		"special_spacing_scale": 0.82,
		"quiz_number_scale": 1.25,
	},
}

# --- State ---
var current_state: GameState = GameState.MENU
var score: int = 0
var score_bonus: int = 0
var coins: int = 0
var current_lives: int = MAX_LIVES
var distance: float = 0.0
var current_speed: float = BASE_SPEED
var difficulty_multiplier: float = 1.0
var play_time: float = 0.0   # Seconds since game_started
var current_mode: String = "normal"
var current_quiz_style: String = "math"
var current_visual_theme: String = "nature"
var current_player_variant: String = "nature_default"
var current_player_name: String = MenuFlowCatalog.DEFAULT_PLAYER_NAME
var current_difficulty_id: String = MenuFlowCatalog.DEFAULT_DIFFICULTY
var previous_high_score: int = 0

# --- Obstacle Difficulty ---
var obstacle_frequency: float = 0.3        # Base chance per chunk slot
var max_obstacle_frequency: float = 0.75


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep processing even when paused
	ControlsManager.ensure_controls_ready()
	current_player_name = SaveManager.get_player_name()
	current_difficulty_id = SaveManager.get_selected_difficulty()
	current_player_variant = SaveManager.get_selected_runner_id()


func apply_menu_setup(player_name: String, difficulty_id: String, runner_id: String = "") -> void:
	current_player_name = player_name.strip_edges()
	if current_player_name.is_empty():
		current_player_name = MenuFlowCatalog.DEFAULT_PLAYER_NAME
	SaveManager.set_player_name(current_player_name)

	current_difficulty_id = difficulty_id if not difficulty_id.is_empty() else MenuFlowCatalog.DEFAULT_DIFFICULTY
	SaveManager.set_selected_difficulty(current_difficulty_id)

	if not runner_id.is_empty():
		current_player_variant = runner_id
		SaveManager.set_selected_runner_id(current_player_variant)


func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	play_time += delta
	var profile: Dictionary = get_difficulty_profile()
	var effective_base_speed: float = get_effective_base_speed()
	var effective_max_speed: float = get_effective_max_speed()

	# Distance scoring
	var distance_delta: float = current_speed * delta
	distance += distance_delta
	score = int(distance) + score_bonus
	score_updated.emit(score)
	distance_updated.emit(distance)

	# Speed ramp
	# Pronunciation mode must keep constant start speed for stable voice timing.
	if is_pronunciation_mode():
		if not is_equal_approx(current_speed, effective_base_speed):
			current_speed = effective_base_speed
			speed_changed.emit(current_speed)
	else:
		var ramp_scale: float = float(profile.get("speed_ramp_scale", 1.0))
		var new_speed: float = clampf(
			effective_base_speed + play_time * SPEED_INCREMENT * ramp_scale,
			effective_base_speed,
			effective_max_speed
		)
		if not is_equal_approx(new_speed, current_speed):
			current_speed = new_speed
			speed_changed.emit(current_speed)

	# Difficulty scaling
	var diff_min: float = float(profile.get("difficulty_min", 1.0))
	var diff_max: float = float(profile.get("difficulty_max", 2.5))
	difficulty_multiplier = remap(current_speed, effective_base_speed, effective_max_speed, diff_min, diff_max)
	var obstacle_base: float = float(profile.get("obstacle_base", 0.3))
	var obstacle_scale: float = float(profile.get("obstacle_scale", 1.0))
	var obstacle_cap: float = minf(float(profile.get("obstacle_max", max_obstacle_frequency)), max_obstacle_frequency + 0.12)
	obstacle_frequency = clampf(
		obstacle_base + (difficulty_multiplier - diff_min) * 0.18 * obstacle_scale,
		obstacle_base,
		obstacle_cap
	)


# --- Public API ---
func start_game() -> void:
	_reset_run()
	# Reset quiz/pronunciation mode tracking
	if has_meta("_quiz_last_obs_z"):
		remove_meta("_quiz_last_obs_z")
	if has_meta("_quiz_obstacle_seq"):
		remove_meta("_quiz_obstacle_seq")
	if has_meta("_quiz_row_seq_id"):
		remove_meta("_quiz_row_seq_id")
	if has_meta("_pronun_last_obs_z"):
		remove_meta("_pronun_last_obs_z")
	if has_meta("_pronun_obstacle_seq"):
		remove_meta("_pronun_obstacle_seq")
	if has_meta("_pronun_row_seq_id"):
		remove_meta("_pronun_row_seq_id")
	# Reset giant rock tracking
	if has_meta("_last_giant_rock_dist"):
		remove_meta("_last_giant_rock_dist")
	if has_meta("_giant_rock_positions"):
		remove_meta("_giant_rock_positions")
	# Reset river tracking
	if has_meta("_last_river_dist"):
		remove_meta("_last_river_dist")
	current_state = GameState.PLAYING
	get_tree().paused = false
	game_started.emit()
	lives_changed.emit(current_lives, MAX_LIVES)


func trigger_game_over() -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.GAME_OVER

	# Save high score
	previous_high_score = SaveManager.get_high_score()
	if score > previous_high_score:
		SaveManager.set_high_score(score)

	# Save total coins
	SaveManager.add_coins(coins)
	var _entry := {
		"name": current_player_name if not current_player_name.is_empty() else SaveManager.get_player_name(),
		"distance": int(distance),
		"coins": coins,
		"mode": current_mode,
		"difficulty": current_difficulty_id,
		"runner_id": current_player_variant,
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	SaveManager.add_leaderboard_entry(_entry)
	LeaderboardService.submit_entry(_entry)

	game_over_triggered.emit()


func pause_game() -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.PAUSED
	get_tree().paused = true
	game_paused.emit()


func resume_game() -> void:
	if current_state != GameState.PAUSED:
		return
	current_state = GameState.PLAYING
	get_tree().paused = false
	game_resumed.emit()


func collect_coin(type: String = "gold") -> void:
	var resolved_type: String = "gold"
	var value: int = COIN_VALUES.get(resolved_type, 1)
	_apply_coin_delta(value, value, false)


func apply_quiz_answer_coin_delta(is_correct: bool) -> int:
	var popup_delta: int = QUIZ_CORRECT_COIN_REWARD if is_correct else QUIZ_WRONG_COIN_PENALTY
	_apply_coin_delta(popup_delta, popup_delta, true)
	return popup_delta


func consume_life() -> bool:
	if current_state != GameState.PLAYING:
		return false
	current_lives = maxi(current_lives - 1, 0)
	lives_changed.emit(current_lives, MAX_LIVES)
	if current_lives <= 0:
		trigger_game_over()
		return false
	return true


func get_max_lives() -> int:
	return MAX_LIVES


func go_to_menu() -> void:
	current_state = GameState.MENU
	get_tree().paused = false


func get_speed_ratio() -> float:
	## Returns 0.0 at base speed, 1.0 at max speed.
	var effective_base_speed: float = get_effective_base_speed()
	var effective_max_speed: float = get_effective_max_speed()
	return clampf((current_speed - effective_base_speed) / maxf(effective_max_speed - effective_base_speed, 0.001), 0.0, 1.0)


func get_difficulty_profile() -> Dictionary:
	# Quiz mode runs at Easy speed/obstacle profile.
	if is_quiz_mode():
		return DIFFICULTY_PROFILES["easy"] as Dictionary
	return DIFFICULTY_PROFILES.get(current_difficulty_id, DIFFICULTY_PROFILES[MenuFlowCatalog.DEFAULT_DIFFICULTY]) as Dictionary


func get_effective_max_speed() -> float:
	var profile: Dictionary = get_difficulty_profile()
	return MAX_SPEED * float(profile.get("max_speed_scale", 1.0))


func get_effective_base_speed() -> float:
	if is_pronunciation_mode():
		return PRONUNCIATION_SPEED
	var profile: Dictionary = get_difficulty_profile()
	return BASE_SPEED * float(profile.get("base_speed_scale", 1.0))


func get_special_obstacle_chance_scale() -> float:
	var profile: Dictionary = get_difficulty_profile()
	return float(profile.get("special_chance_scale", 1.0))


func get_special_obstacle_spacing_scale() -> float:
	var profile: Dictionary = get_difficulty_profile()
	return float(profile.get("special_spacing_scale", 1.0))


func get_quiz_number_scale() -> float:
	var profile: Dictionary = get_difficulty_profile()
	return float(profile.get("quiz_number_scale", 1.0))


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_normal_mode() -> bool:
	return current_mode == "normal"


func is_quiz_mode() -> bool:
	return current_mode == "quiz"


func is_pronunciation_mode() -> bool:
	return current_mode == "pronunciation"


func is_nature_theme() -> bool:
	return current_visual_theme == "nature"


func is_cyberprank_theme() -> bool:
	return current_visual_theme == "cyberprank"


# --- Private ---
func _reset_run() -> void:
	var profile: Dictionary = get_difficulty_profile()
	score = 0
	score_bonus = 0
	coins = 0
	current_lives = MAX_LIVES
	distance = 0.0
	current_speed = get_effective_base_speed()
	difficulty_multiplier = float(profile.get("difficulty_min", 1.0))
	obstacle_frequency = float(profile.get("obstacle_base", 0.3))
	play_time = 0.0
	previous_high_score = 0


func _apply_coin_delta(score_delta: int, coin_delta: int, emit_feedback: bool) -> void:
	var applied_coin_delta: int = coin_delta
	if applied_coin_delta < 0:
		applied_coin_delta = maxi(applied_coin_delta, -coins)
	coins += applied_coin_delta
	score_bonus += score_delta
	score = int(distance) + score_bonus
	coin_collected.emit(applied_coin_delta)
	score_updated.emit(score)
	if emit_feedback:
		coin_delta_feedback.emit(score_delta)

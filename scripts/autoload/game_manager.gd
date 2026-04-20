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
signal score_updated(new_score: int)
signal distance_updated(new_distance: float)
signal speed_changed(new_speed: float)

# --- Enums ---
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }

# --- Constants ---
const BASE_SPEED: float = 12.0
const MAX_SPEED: float = 28.0
const SPEED_INCREMENT: float = 0.15        # Speed increase per second of play
const LANE_WIDTH: float = 2.0
const LANE_COUNT: int = 3
const LANE_POSITIONS: Array[float] = [-2.0, 0.0, 2.0]

const COIN_VALUES: Dictionary = {
	"gold": 1,
}

const DIFFICULTY_PROFILES: Dictionary = {
	"easy": {
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
		"speed_ramp_scale": 1.00,
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
		"speed_ramp_scale": 1.18,
		"max_speed_scale": 1.12,
		"difficulty_min": 1.12,
		"difficulty_max": 3.00,
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
var distance: float = 0.0
var current_speed: float = BASE_SPEED
var difficulty_multiplier: float = 1.0
var play_time: float = 0.0   # Seconds since game_started
var current_mode: String = "normal"
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
	var effective_max_speed: float = get_effective_max_speed()

	# Distance scoring
	var distance_delta: float = current_speed * delta
	distance += distance_delta
	score = int(distance) + score_bonus
	score_updated.emit(score)
	distance_updated.emit(distance)

	# Speed ramp
	var ramp_scale: float = float(profile.get("speed_ramp_scale", 1.0))
	var new_speed: float = clampf(BASE_SPEED + play_time * SPEED_INCREMENT * ramp_scale, BASE_SPEED, effective_max_speed)
	if new_speed != current_speed:
		current_speed = new_speed
		speed_changed.emit(current_speed)

	# Difficulty scaling
	var diff_min: float = float(profile.get("difficulty_min", 1.0))
	var diff_max: float = float(profile.get("difficulty_max", 2.5))
	difficulty_multiplier = remap(current_speed, BASE_SPEED, effective_max_speed, diff_min, diff_max)
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
	if has_meta("_pronun_last_obs_z"):
		remove_meta("_pronun_last_obs_z")
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
	SaveManager.add_leaderboard_entry({
		"name": current_player_name if not current_player_name.is_empty() else SaveManager.get_player_name(),
		"distance": int(distance),
		"coins": coins,
		"difficulty": current_difficulty_id,
		"runner_id": current_player_variant,
	})

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
	coins += value
	score_bonus += value
	score = int(distance) + score_bonus
	coin_collected.emit(value)
	score_updated.emit(score)


func go_to_menu() -> void:
	current_state = GameState.MENU
	get_tree().paused = false


func get_speed_ratio() -> float:
	## Returns 0.0 at base speed, 1.0 at max speed.
	var effective_max_speed: float = get_effective_max_speed()
	return clampf((current_speed - BASE_SPEED) / maxf(effective_max_speed - BASE_SPEED, 0.001), 0.0, 1.0)


func get_difficulty_profile() -> Dictionary:
	return DIFFICULTY_PROFILES.get(current_difficulty_id, DIFFICULTY_PROFILES[MenuFlowCatalog.DEFAULT_DIFFICULTY]) as Dictionary


func get_effective_max_speed() -> float:
	var profile: Dictionary = get_difficulty_profile()
	return MAX_SPEED * float(profile.get("max_speed_scale", 1.0))


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
	score = 0
	score_bonus = 0
	coins = 0
	distance = 0.0
	current_speed = BASE_SPEED
	difficulty_multiplier = 1.0
	obstacle_frequency = 0.3
	play_time = 0.0
	previous_high_score = 0

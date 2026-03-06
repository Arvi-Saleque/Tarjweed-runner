extends Node
## GameManager - Global game state singleton.
## Manages score, coins, distance, speed, difficulty, and game state transitions.

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
	"gold": 3,
	"silver": 2,
	"bronze": 1,
}

# --- State ---
var current_state: GameState = GameState.MENU
var score: int = 0
var coins: int = 0
var distance: float = 0.0
var current_speed: float = BASE_SPEED
var difficulty_multiplier: float = 1.0
var play_time: float = 0.0   # Seconds since game_started

# --- Obstacle Difficulty ---
var obstacle_frequency: float = 0.3        # Base chance per chunk slot
var max_obstacle_frequency: float = 0.75


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep processing even when paused


func _process(delta: float) -> void:
	if current_state != GameState.PLAYING:
		return

	play_time += delta

	# Distance scoring
	var distance_delta: float = current_speed * delta
	distance += distance_delta
	score = int(distance)
	score_updated.emit(score)
	distance_updated.emit(distance)

	# Speed ramp
	var new_speed: float = clampf(BASE_SPEED + play_time * SPEED_INCREMENT, BASE_SPEED, MAX_SPEED)
	if new_speed != current_speed:
		current_speed = new_speed
		speed_changed.emit(current_speed)

	# Difficulty scaling
	difficulty_multiplier = remap(current_speed, BASE_SPEED, MAX_SPEED, 1.0, 2.5)
	obstacle_frequency = clampf(0.3 + (difficulty_multiplier - 1.0) * 0.2, 0.3, max_obstacle_frequency)


# --- Public API ---
func start_game() -> void:
	_reset_run()
	current_state = GameState.PLAYING
	get_tree().paused = false
	game_started.emit()


func trigger_game_over() -> void:
	if current_state != GameState.PLAYING:
		return
	current_state = GameState.GAME_OVER

	# Save high score
	var high_score: int = SaveManager.get_high_score()
	if score > high_score:
		SaveManager.set_high_score(score)

	# Save total coins
	SaveManager.add_coins(coins)

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
	var value: int = COIN_VALUES.get(type, 1)
	coins += value
	score += value * 10
	coin_collected.emit(value)
	score_updated.emit(score)


func go_to_menu() -> void:
	current_state = GameState.MENU
	get_tree().paused = false


func get_speed_ratio() -> float:
	## Returns 0.0 at base speed, 1.0 at max speed.
	return clampf((current_speed - BASE_SPEED) / (MAX_SPEED - BASE_SPEED), 0.0, 1.0)


func is_playing() -> bool:
	return current_state == GameState.PLAYING


# --- Private ---
func _reset_run() -> void:
	score = 0
	coins = 0
	distance = 0.0
	current_speed = BASE_SPEED
	difficulty_multiplier = 1.0
	obstacle_frequency = 0.3
	play_time = 0.0

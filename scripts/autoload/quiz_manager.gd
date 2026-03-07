extends Node
## QuizManager — Generates and tracks quiz questions for Quiz mode.
## 4 question types tied to 4 obstacle types:
##   Addition → Jump | Subtraction → Slide | Multiplication → Blast | Division → Bridge

signal question_changed(question: Dictionary)
signal answer_result(correct: bool)

# Question types mapped to obstacle types
enum QuestionType { ADDITION, SUBTRACTION, MULTIPLICATION, DIVISION }

# Maps obstacle type index to question type
const OBS_TYPE_TO_QUESTION: Dictionary = {
	0: QuestionType.ADDITION,       # Jump
	1: QuestionType.SUBTRACTION,    # Slide
	2: QuestionType.MULTIPLICATION, # Blast
	3: QuestionType.DIVISION,       # Bridge
}

# Current question data
var current_question: Dictionary = {}
var _is_active: bool = false
var _player: CharacterBody3D = null

# Answer key mapping (1, 2, 3, 4 keys)
var _answer_actions: Array[String] = ["quiz_answer_1", "quiz_answer_2", "quiz_answer_3", "quiz_answer_4"]


func _ready() -> void:
	_register_input_actions()
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


func _register_input_actions() -> void:
	for i in 4:
		var action_name := "quiz_answer_%d" % (i + 1)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var key_event := InputEventKey.new()
			key_event.keycode = KEY_1 + i
			InputMap.action_add_event(action_name, key_event)


func _process(_delta: float) -> void:
	if not _is_active:
		return
	if GameManager.current_theme != "quiz":
		return
	_handle_answer_input()


func _handle_answer_input() -> void:
	if current_question.is_empty():
		return
	for i in 4:
		var action := _answer_actions[i]
		if Input.is_action_just_pressed(action):
			_check_answer(i)
			break


func _check_answer(choice_index: int) -> void:
	if current_question.is_empty():
		return

	var correct_index: int = current_question.get("correct_index", -1)
	var is_correct: bool = (choice_index == correct_index)

	if is_correct:
		answer_result.emit(true)
		_trigger_player_action()
	else:
		answer_result.emit(false)

	# Either way, move to the next question — one chance per question
	_generate_question()


func _trigger_player_action() -> void:
	## If near an obstacle, perform the action matching that obstacle.
	## If NOT near any obstacle, default to jump.
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not _player:
		return

	var obs_type: int = _detect_nearby_obstacle_type()
	match obs_type:
		0:  # Jump obstacle (or no obstacle nearby)
			if _player.has_method("quiz_jump"):
				_player.call("quiz_jump")
		1:  # Slide obstacle
			if _player.has_method("quiz_slide"):
				_player.call("quiz_slide")
		2:  # Giant rock — blast
			if _player.has_method("quiz_blast"):
				_player.call("quiz_blast")
		3:  # River — bridge
			if _player.has_method("quiz_bridge"):
				_player.call("quiz_bridge")


func _on_game_started() -> void:
	if GameManager.current_theme == "quiz":
		_is_active = true
		_player = null
		await get_tree().create_timer(0.5).timeout
		_generate_question()
	else:
		_is_active = false
		current_question = {}


func _on_game_over() -> void:
	_is_active = false
	current_question = {}
	question_changed.emit({})


func _generate_question() -> void:
	## Generate a RANDOM quiz question — not tied to obstacle type.
	var q_type: QuestionType = [QuestionType.ADDITION, QuestionType.SUBTRACTION,
		QuestionType.MULTIPLICATION, QuestionType.DIVISION].pick_random()

	var max_num: int = 10 + int(GameManager.difficulty_multiplier * 5)
	max_num = mini(max_num, 50)

	var a: int = 0
	var b: int = 0
	var correct_answer: int = 0
	var question_text: String = ""

	match q_type:
		QuestionType.ADDITION:
			a = randi_range(1, max_num)
			b = randi_range(1, max_num)
			correct_answer = a + b
			question_text = "%d + %d = ?" % [a, b]
		QuestionType.SUBTRACTION:
			a = randi_range(1, max_num)
			b = randi_range(1, max_num)
			if a < b:
				var temp := a
				a = b
				b = temp
			correct_answer = a - b
			question_text = "%d - %d = ?" % [a, b]
		QuestionType.MULTIPLICATION:
			a = randi_range(1, 12)
			b = randi_range(1, 12)
			correct_answer = a * b
			question_text = "%d × %d = ?" % [a, b]
		QuestionType.DIVISION:
			# Generate clean division (no remainder)
			b = randi_range(1, 12)
			correct_answer = randi_range(1, 12)
			a = b * correct_answer
			question_text = "%d ÷ %d = ?" % [a, b]

	# Generate 4 choices (1 correct, 3 wrong)
	var choices: Array[int] = [correct_answer]
	while choices.size() < 4:
		var wrong: int = correct_answer + randi_range(-10, 10)
		if wrong != correct_answer and wrong > 0 and wrong not in choices:
			choices.append(wrong)

	choices.shuffle()
	var correct_index: int = choices.find(correct_answer)

	current_question = {
		"text": question_text,
		"choices": choices,
		"correct_index": correct_index,
		"correct_answer": correct_answer,
		"question_type": q_type,
	}

	question_changed.emit(current_question)


# How close the player must be to an obstacle for it to trigger its specific action
const NEAR_OBSTACLE_RANGE: float = 40.0


func _detect_nearby_obstacle_type() -> int:
	## Find the nearest UPCOMING quiz obstacle marker within NEAR_OBSTACLE_RANGE.
	## Returns the obstacle type (0-3) if one is close, or 0 (jump) if none nearby.
	var markers := get_tree().get_nodes_in_group("quiz_obstacles")
	var best_marker: Node = null
	var best_z: float = -99999.0

	for marker in markers:
		if marker.get_meta("quiz_used", false):
			continue
		var z: float = marker.global_position.z
		if z > -2.0:
			continue  # Already at or past the player
		if z > best_z:
			best_z = z
			best_marker = marker

	# Check if the nearest obstacle is within range
	if best_marker and absf(best_z) <= NEAR_OBSTACLE_RANGE:
		best_marker.set_meta("quiz_used", true)
		return best_marker.get_meta("quiz_obstacle_type", 0) as int

	# No obstacle nearby — default to jump
	return 0

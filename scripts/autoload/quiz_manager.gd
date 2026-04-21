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
	if not GameManager.is_quiz_mode():
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
	## Perform the action tied to the current question's obstacle type.
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not _player:
		return

	var obs_type: int = current_question.get("obstacle_type", 0) as int
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
	if GameManager.is_quiz_mode():
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
	var obs_type: int = _detect_nearby_obstacle_type(true)
	var q_type: QuestionType = OBS_TYPE_TO_QUESTION.get(obs_type, QuestionType.ADDITION) as QuestionType

	# Tier-aware question generation:
	#   tier 0 = before threshold | tier 1 = after threshold
	#
	# Easy   tier 0: 1-digit + / −
	# Easy   tier 1: 2-digit + / −
	# Medium tier 0: 2-digit + / −  or  1-digit × / ÷
	# Medium tier 1: 2-digit + / −  or  2-digit ÷ (e.g. 50 ÷ 5)
	# Hard   tier 0: same as Medium tier 0
	# Hard   tier 1: 2-digit × (e.g. 12 × 8)  plus Medium tier 1 options
	var tier: int = _get_quiz_tier()
	var diff: String = GameManager.current_difficulty_id

	var a: int = 0
	var b: int = 0
	var correct_answer: int = 0
	var question_text: String = ""

	match diff:
		"easy":
			# Force only + and − regardless of obstacle type
			q_type = QuestionType.ADDITION if randi() % 2 == 0 else QuestionType.SUBTRACTION
			if tier == 0:
				# 1-digit operands (1–9)
				a = randi_range(1, 9)
				b = randi_range(1, 9)
			else:
				# 2-digit operands (10–30)
				a = randi_range(10, 30)
				b = randi_range(1, 20)
		"medium":
			if q_type == QuestionType.MULTIPLICATION or q_type == QuestionType.DIVISION:
				# Mult/div obstacle encountered
				if tier == 0:
					# 1-digit × or ÷
					if q_type == QuestionType.MULTIPLICATION:
						a = randi_range(1, 9)
						b = randi_range(1, 9)
					else:
						b = randi_range(1, 9)
						correct_answer = randi_range(1, 9)
						a = b * correct_answer
				else:
					# tier 1: 2-digit ÷ (e.g. 50 ÷ 5)
					q_type = QuestionType.DIVISION
					b = randi_range(2, 10)
					correct_answer = randi_range(2, 10)
					a = b * correct_answer   # a can reach 100
			else:
				# + and − always use 2-digit operands in medium
				a = randi_range(10, 40)
				b = randi_range(1, 30)
		"hard":
			if q_type == QuestionType.MULTIPLICATION:
				if tier == 0:
					# 1-digit ×
					a = randi_range(1, 9)
					b = randi_range(1, 9)
				else:
					# 2-digit × (e.g. 12 × 8)
					a = randi_range(10, 20)
					b = randi_range(2, 12)
			elif q_type == QuestionType.DIVISION:
				if tier == 0:
					b = randi_range(1, 9)
					correct_answer = randi_range(1, 9)
					a = b * correct_answer
				else:
					b = randi_range(2, 10)
					correct_answer = randi_range(2, 10)
					a = b * correct_answer
			else:
				# + and − — 2-digit
				a = randi_range(10, 50)
				b = randi_range(1, 40)
		_:
			# Fallback (pronunciation mode or unknown — simple 1-digit)
			q_type = QuestionType.ADDITION
			a = randi_range(1, 9)
			b = randi_range(1, 9)

	# Build question text and correct answer for each type
	match q_type:
		QuestionType.ADDITION:
			correct_answer = a + b
			question_text = "%d + %d = ?" % [a, b]
		QuestionType.SUBTRACTION:
			if a < b:
				var tmp := a; a = b; b = tmp
			correct_answer = a - b
			question_text = "%d - %d = ?" % [a, b]
		QuestionType.MULTIPLICATION:
			correct_answer = a * b
			question_text = "%d × %d = ?" % [a, b]
		QuestionType.DIVISION:
			# a and correct_answer already set above for div; re-confirm text
			question_text = "%d ÷ %d = ?" % [a, b]

	# Generate 4 answer choices: 1 correct + 3 plausible wrong answers
	var spread: int = maxi(3, int(correct_answer * 0.3))
	var choices: Array[int] = [correct_answer]
	var attempts: int = 0
	while choices.size() < 4 and attempts < 60:
		attempts += 1
		var wrong: int = correct_answer + randi_range(-spread, spread)
		if wrong <= 0 or wrong == correct_answer or wrong in choices:
			continue
		choices.append(wrong)

	# Fill any remaining slots if spread was too narrow
	var filler: int = 1
	while choices.size() < 4:
		if filler != correct_answer and filler not in choices:
			choices.append(filler)
		filler += 1

	choices.shuffle()
	var correct_index: int = choices.find(correct_answer)

	current_question = {
		"text": question_text,
		"choices": choices,
		"correct_index": correct_index,
		"correct_answer": correct_answer,
		"question_type": q_type,
		"obstacle_type": obs_type,
		"tier": tier,
	}

	question_changed.emit(current_question)


## Returns 0 (before threshold) or 1 (after threshold) based on difficulty.
## Threshold distance is 1000 m for all difficulties.
func _get_quiz_tier() -> int:
	const THRESHOLD: float = 1000.0
	return 1 if GameManager.distance >= THRESHOLD else 0


func _detect_nearby_obstacle_type(mark_used: bool = false) -> int:
	## Find the nearest UPCOMING quiz obstacle marker.
	## Returns the obstacle type (0-3), or 0 (jump) if none remain.
	var markers := get_tree().get_nodes_in_group("quiz_obstacles")
	var best_marker: Node = null
	var best_z: float = -99999.0

	for marker in markers:
		if marker.get_meta("quiz_used", false):
			continue
		var z: float = marker.global_position.z
		if z > 2.0:
			continue  # Already passed the player
		if z > best_z:
			best_z = z
			best_marker = marker

	# Check if the nearest obstacle is within range
	if best_marker:
		if mark_used:
			best_marker.set_meta("quiz_used", true)
		return best_marker.get_meta("quiz_obstacle_type", 0) as int

	# No obstacle nearby — default to jump
	return 0

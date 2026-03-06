extends Node
## QuizManager — Generates and tracks quiz questions for Quiz mode.
## Questions appear continuously during gameplay. Correct answer = jump.

signal question_changed(question: Dictionary)
signal answer_result(correct: bool)

# Question types
enum QuestionType { ADDITION, SUBTRACTION, MULTIPLICATION }

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
	# Register number keys 1-4 for quiz answers
	for i in 4:
		var action_name := "quiz_answer_%d" % (i + 1)
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var key_event := InputEventKey.new()
			key_event.keycode = KEY_1 + i  # KEY_1, KEY_2, KEY_3, KEY_4
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
		_trigger_player_jump()
		# Generate next question immediately
		_generate_question()
	# Wrong answer: do nothing — player keeps running, may hit obstacle


func _trigger_player_jump() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player and _player.has_method("quiz_jump"):
		_player.call("quiz_jump")


func _on_game_started() -> void:
	if GameManager.current_theme == "quiz":
		_is_active = true
		_player = null
		# Small delay before first question
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
	# Pick random question type (for now, just addition)
	var q_type: QuestionType = QuestionType.ADDITION
	
	# Vary difficulty based on game progress
	var max_num: int = 10 + int(GameManager.difficulty_multiplier * 5)
	max_num = mini(max_num, 50)

	var a: int = randi_range(1, max_num)
	var b: int = randi_range(1, max_num)
	var correct_answer: int = 0
	var question_text: String = ""

	match q_type:
		QuestionType.ADDITION:
			correct_answer = a + b
			question_text = "%d + %d = ?" % [a, b]
		QuestionType.SUBTRACTION:
			# Ensure positive result
			if a < b:
				var temp := a
				a = b
				b = temp
			correct_answer = a - b
			question_text = "%d - %d = ?" % [a, b]
		QuestionType.MULTIPLICATION:
			# Keep numbers smaller for multiplication
			a = randi_range(1, 12)
			b = randi_range(1, 12)
			correct_answer = a * b
			question_text = "%d × %d = ?" % [a, b]

	# Generate 4 choices (1 correct, 3 wrong)
	var choices: Array[int] = [correct_answer]
	while choices.size() < 4:
		var wrong: int = correct_answer + randi_range(-10, 10)
		if wrong != correct_answer and wrong > 0 and wrong not in choices:
			choices.append(wrong)
	
	# Shuffle choices
	choices.shuffle()
	var correct_index: int = choices.find(correct_answer)

	current_question = {
		"text": question_text,
		"choices": choices,
		"correct_index": correct_index,
		"correct_answer": correct_answer,
	}

	question_changed.emit(current_question)

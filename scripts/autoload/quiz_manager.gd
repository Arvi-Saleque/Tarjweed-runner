extends Node
## QuizManager — Generates and tracks quiz questions for Quiz mode.
## Supports 4 quiz styles: math, arabic_huroof, bangla_english, english_bangla.
## Math: 4 question types tied to 4 obstacle types (Addition/Subtraction/Multiplication/Division).

signal question_changed(question: Dictionary)
signal answer_result(correct: bool, choice_index: int, correct_index: int)
signal action_confirmation(action_type: int)

# Question types mapped to obstacle types (math only)
enum QuestionType { ADDITION, SUBTRACTION, MULTIPLICATION, DIVISION }
enum QuizTargetState { UPCOMING, IN_RANGE, ACTIVE_QUIZ_TARGET, ACTION_LOCKED, CLEARED, FAILED }
enum QuizActionType { JUMP, SLIDE, BLAST, BRIDGE }

const OBS_TYPE_TO_QUESTION: Dictionary = {
	0: QuestionType.ADDITION,
	1: QuestionType.SUBTRACTION,
	2: QuestionType.MULTIPLICATION,
	3: QuestionType.DIVISION,
}
const TARGET_CAPTURE_TTI_MAX: float = 3.0
const TARGET_CAPTURE_TTI_MIN: float = 2.0
const VALIDATION_WINDOW_SECONDS: float = 0.45
const POST_FEEDBACK_GAP_SECONDS: float = 0.20
const JUMP_ACTION_TTI_SECONDS: float = 0.45
const SLIDE_ACTION_TTI_SECONDS: float = 0.40
const QUIZ_PASS_Z: float = 2.0

# --- Arabic Letters (Huroof) — letter shown as question, Bangla name as answer ---
const ARABIC_HUROOF: Array[Dictionary] = [
	{"letter": "ا", "bangla": "আলিফ"},
	{"letter": "ب", "bangla": "বা"},
	{"letter": "ت", "bangla": "তা"},
	{"letter": "ث", "bangla": "ছা"},
	{"letter": "ج", "bangla": "জিম"},
	{"letter": "ح", "bangla": "হা"},
	{"letter": "خ", "bangla": "খা"},
	{"letter": "د", "bangla": "দাল"},
	{"letter": "ذ", "bangla": "জাল"},
	{"letter": "ر", "bangla": "রা"},
	{"letter": "ز", "bangla": "যাই"},
	{"letter": "س", "bangla": "সিন"},
	{"letter": "ش", "bangla": "শিন"},
	{"letter": "ص", "bangla": "সোয়াদ"},
	{"letter": "ض", "bangla": "দোয়াদ"},
	{"letter": "ط", "bangla": "তোয়া"},
	{"letter": "ظ", "bangla": "জোয়া"},
	{"letter": "ع", "bangla": "আইন"},
	{"letter": "غ", "bangla": "গাইন"},
	{"letter": "ف", "bangla": "ফা"},
	{"letter": "ق", "bangla": "ক্বাফ"},
	{"letter": "ك", "bangla": "কাফ"},
	{"letter": "ل", "bangla": "লাম"},
	{"letter": "م", "bangla": "মিম"},
	{"letter": "ن", "bangla": "নুন"},
	{"letter": "و", "bangla": "ওয়াও"},
	{"letter": "ه", "bangla": "হা"},
	{"letter": "ي", "bangla": "ইয়া"},
]

# --- Arabic Letters + Harakat — letter+harakat as question, Bangla sound as answer ---
const ARABIC_HARAKAT: Array[Dictionary] = [
	{"text": "بَ", "bangla": "বা"},
	{"text": "بِ", "bangla": "বি"},
	{"text": "بُ", "bangla": "বু"},
	{"text": "تَ", "bangla": "তা"},
	{"text": "تِ", "bangla": "তি"},
	{"text": "تُ", "bangla": "তু"},
	{"text": "سَ", "bangla": "সা"},
	{"text": "سِ", "bangla": "সি"},
	{"text": "سُ", "bangla": "সু"},
	{"text": "مَ", "bangla": "মা"},
	{"text": "مِ", "bangla": "মি"},
	{"text": "مُ", "bangla": "মু"},
	{"text": "نَ", "bangla": "না"},
	{"text": "نِ", "bangla": "নি"},
	{"text": "نُ", "bangla": "নু"},
	{"text": "رَ", "bangla": "রা"},
	{"text": "رِ", "bangla": "রি"},
	{"text": "رُ", "bangla": "রু"},
	{"text": "لَ", "bangla": "লা"},
	{"text": "لِ", "bangla": "লি"},
	{"text": "لُ", "bangla": "লু"},
	{"text": "كَ", "bangla": "কা"},
	{"text": "كِ", "bangla": "কি"},
	{"text": "كُ", "bangla": "কু"},
]

# --- Short Arabic Words — Arabic word as question, Bangla meaning as answer ---
const ARABIC_WORDS: Array[Dictionary] = [
	{"arabic": "كِتَاب", "bangla": "বই"},
	{"arabic": "بَيْت", "bangla": "ঘর"},
	{"arabic": "مَاء", "bangla": "পানি"},
	{"arabic": "نَار", "bangla": "আগুন"},
	{"arabic": "أُمّ", "bangla": "মা"},
	{"arabic": "أَب", "bangla": "বাবা"},
	{"arabic": "قَلَم", "bangla": "কলম"},
	{"arabic": "بَاب", "bangla": "দরজা"},
	{"arabic": "شَمْس", "bangla": "সূর্য"},
	{"arabic": "قَمَر", "bangla": "চাঁদ"},
	{"arabic": "نَجْم", "bangla": "তারা"},
	{"arabic": "كَلْب", "bangla": "কুকুর"},
]

# --- Word Bank — Bangla/English pairs for translation quizzes ---
const WORD_BANK: Array[Dictionary] = [
	{"bangla": "বিড়াল", "english": "Cat"},
	{"bangla": "কুকুর", "english": "Dog"},
	{"bangla": "মাছ", "english": "Fish"},
	{"bangla": "পাখি", "english": "Bird"},
	{"bangla": "গরু", "english": "Cow"},
	{"bangla": "ঘোড়া", "english": "Horse"},
	{"bangla": "হাতি", "english": "Elephant"},
	{"bangla": "বাঘ", "english": "Tiger"},
	{"bangla": "সিংহ", "english": "Lion"},
	{"bangla": "বানর", "english": "Monkey"},
	{"bangla": "খরগোশ", "english": "Rabbit"},
	{"bangla": "ব্যাঙ", "english": "Frog"},
	{"bangla": "সাপ", "english": "Snake"},
	{"bangla": "আপেল", "english": "Apple"},
	{"bangla": "কলা", "english": "Banana"},
	{"bangla": "আম", "english": "Mango"},
	{"bangla": "গাছ", "english": "Tree"},
	{"bangla": "ফুল", "english": "Flower"},
	{"bangla": "পানি", "english": "Water"},
	{"bangla": "আগুন", "english": "Fire"},
	{"bangla": "সূর্য", "english": "Sun"},
	{"bangla": "চাঁদ", "english": "Moon"},
	{"bangla": "তারা", "english": "Star"},
	{"bangla": "বই", "english": "Book"},
	{"bangla": "কলম", "english": "Pen"},
	{"bangla": "ঘর", "english": "House"},
	{"bangla": "রাস্তা", "english": "Road"},
	{"bangla": "নদী", "english": "River"},
	{"bangla": "পাহাড়", "english": "Mountain"},
	{"bangla": "আকাশ", "english": "Sky"},
]

# Current question data
var current_question: Dictionary = {}
var _is_active: bool = false
var _player: CharacterBody3D = null
var _current_obstacle_marker: Node3D = null
var _awaiting_next_question_after_success: bool = false
var _question_locked: bool = false
var _active_target: Dictionary = {}
var _resolved_row_ids: Dictionary = {}
var _next_question_id: int = 1

# Answer key mapping (1, 2, 3, 4 keys)
var _answer_actions: Array[String] = ["quiz_answer_1", "quiz_answer_2", "quiz_answer_3", "quiz_answer_4"]
const WRONG_ANSWER_DELAY: float = 0.5


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
	_capture_upcoming_target()
	_spawn_first_question_for_active_target()
	_update_success_progression()
	_handle_answer_input()


func _handle_answer_input() -> void:
	if current_question.is_empty() or _question_locked:
		return
	for i in 4:
		var action := _answer_actions[i]
		if Input.is_action_just_pressed(action):
			_check_answer(i)
			break


func _check_answer(choice_index: int) -> void:
	if current_question.is_empty() or _question_locked:
		return

	_question_locked = true
	var correct_index: int = current_question.get("correct_index", -1)
	var is_correct: bool = (choice_index == correct_index)

	if is_correct:
		answer_result.emit(true, choice_index, correct_index)
		_trigger_player_action()
		_awaiting_next_question_after_success = true
	else:
		answer_result.emit(false, choice_index, correct_index)
		_awaiting_next_question_after_success = false
		_current_obstacle_marker = null
		await get_tree().create_timer(WRONG_ANSWER_DELAY).timeout
		if _is_active and GameManager.is_quiz_mode():
			_unlock_and_generate_next_question()


func _trigger_player_action() -> void:
	## Perform the action tied to the current question's obstacle type.
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not _player:
		return

	var obs_type: int = _resolve_current_obstacle_type()
	match obs_type:
		0:  # Jump obstacle (or no obstacle nearby)
			if _player.has_method("quiz_jump"):
				_player.call("quiz_jump")
		1:  # Slide obstacle
			if _player.has_method("quiz_slide"):
				_player.call("quiz_slide")
		2:  # Giant rock — blast
			var rock_target := _find_matching_marker_obstacle("giant_rocks")
			if rock_target and _player.has_method("quiz_blast_target"):
				_player.call("quiz_blast_target", rock_target)
			elif _player.has_method("quiz_blast"):
				_player.call("quiz_blast")
		3:  # River — bridge
			var river_target := _find_matching_marker_obstacle("river_crossings")
			if river_target and _player.has_method("quiz_bridge_target"):
				_player.call("quiz_bridge_target", river_target)
			elif _player.has_method("quiz_bridge"):
				_player.call("quiz_bridge")


func _on_game_started() -> void:
	if GameManager.is_quiz_mode():
		_is_active = true
		_player = null
		_reset_quiz_runtime_state()
	else:
		_is_active = false
		_reset_quiz_runtime_state()


func _on_game_over() -> void:
	_is_active = false
	_reset_quiz_runtime_state()
	question_changed.emit({})


func _generate_question() -> void:
	var style: String = GameManager.current_quiz_style
	match style:
		"arabic_huroof":
			_generate_arabic_huroof_question()
		"bangla_english":
			_generate_word_meaning_question("bangla_english")
		"english_bangla":
			_generate_word_meaning_question("english_bangla")
		_:
			_generate_math_question()


func _generate_arabic_huroof_question() -> void:
	var diff: String = GameManager.current_difficulty_id
	var pool: Array[Dictionary]
	var question_key: String
	var answer_key: String
	var marker := _claim_next_obstacle_marker()
	var obstacle_type: int = _set_current_obstacle_marker(marker)

	match diff:
		"hard":
			pool = ARABIC_WORDS
			question_key = "arabic"
			answer_key = "bangla"
		"medium":
			pool = ARABIC_HARAKAT
			question_key = "text"
			answer_key = "bangla"
		_:  # easy (and any unknown)
			pool = ARABIC_HUROOF
			question_key = "letter"
			answer_key = "bangla"

	var idx: int = randi() % pool.size()
	var correct_entry: Dictionary = pool[idx]
	var correct_answer: String = correct_entry[answer_key]

	# Pick 3 distinct wrong answers from the same pool
	var choices: Array = [correct_answer]
	var attempts: int = 0
	while choices.size() < 4 and attempts < 80:
		attempts += 1
		var wrong_entry: Dictionary = pool[randi() % pool.size()]
		var wrong: String = wrong_entry[answer_key]
		if wrong != correct_answer and not (wrong in choices):
			choices.append(wrong)

	# Filler from pool if not enough variety
	for entry in pool:
		if choices.size() >= 4:
			break
		var val: String = entry[answer_key]
		if not (val in choices):
			choices.append(val)

	choices.shuffle()
	var correct_index: int = choices.find(correct_answer)

	current_question = {
		"text": correct_entry[question_key],
		"choices": choices,
		"correct_index": correct_index,
		"correct_answer": correct_answer,
		"question_type": -1,
		"obstacle_type": obstacle_type,
		"tier": _get_quiz_tier(),
		"question_font": "arabic",
		"answer_font": "bangla",
	}
	question_changed.emit(current_question)


func _generate_word_meaning_question(style: String) -> void:
	var marker := _claim_next_obstacle_marker()
	var obstacle_type: int = _set_current_obstacle_marker(marker)
	var idx: int = randi() % WORD_BANK.size()
	var correct_entry: Dictionary = WORD_BANK[idx]

	var question_text: String
	var correct_answer: String
	var q_font: String
	var a_font: String

	if style == "bangla_english":
		question_text = correct_entry["bangla"]
		correct_answer = correct_entry["english"]
		q_font = "bangla"
		a_font = "latin"
	else:  # english_bangla
		question_text = correct_entry["english"]
		correct_answer = correct_entry["bangla"]
		q_font = "latin"
		a_font = "bangla"

	var choices: Array = [correct_answer]
	var attempts: int = 0
	while choices.size() < 4 and attempts < 80:
		attempts += 1
		var wrong_entry: Dictionary = WORD_BANK[randi() % WORD_BANK.size()]
		var wrong: String = wrong_entry["english"] if style == "bangla_english" else wrong_entry["bangla"]
		if wrong != correct_answer and not (wrong in choices):
			choices.append(wrong)

	for entry in WORD_BANK:
		if choices.size() >= 4:
			break
		var val: String = entry["english"] if style == "bangla_english" else entry["bangla"]
		if not (val in choices):
			choices.append(val)

	choices.shuffle()
	var correct_index: int = choices.find(correct_answer)

	current_question = {
		"text": question_text,
		"choices": choices,
		"correct_index": correct_index,
		"correct_answer": correct_answer,
		"question_type": -1,
		"obstacle_type": obstacle_type,
		"tier": _get_quiz_tier(),
		"question_font": q_font,
		"answer_font": a_font,
	}
	question_changed.emit(current_question)


func _generate_math_question() -> void:
	var marker := _claim_next_obstacle_marker()
	var obs_type: int = _set_current_obstacle_marker(marker)
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
		"question_font": "latin",
		"answer_font": "latin",
	}

	question_changed.emit(current_question)


func _claim_next_obstacle_marker() -> Node3D:
	if _has_active_target():
		return _active_target.get("marker") as Node3D

	var next_row := _find_nearest_quiz_row()
	if next_row.is_empty():
		return null
	_set_active_target_from_row(next_row)
	var marker := _active_target.get("marker") as Node3D
	if marker:
		marker.set_meta("quiz_used", true)
	return marker


func _set_current_obstacle_marker(marker: Node3D) -> int:
	_current_obstacle_marker = marker
	if _current_obstacle_marker:
		return _current_obstacle_marker.get_meta("quiz_obstacle_type", 0) as int
	return 0


func _resolve_current_obstacle_type() -> int:
	var active_row := _active_target.get("row_root") as Node
	if active_row and is_instance_valid(active_row):
		return _active_target.get("obstacle_type", QuizActionType.JUMP) as int
	if _current_obstacle_marker and is_instance_valid(_current_obstacle_marker):
		return _current_obstacle_marker.get_meta("quiz_obstacle_type", 0) as int
	return current_question.get("obstacle_type", 0) as int


func _find_matching_marker_obstacle(group_name: String, max_z_delta: float = 1.0) -> Node:
	var row_root := _active_target.get("row_root") as Node
	if row_root and is_instance_valid(row_root) and row_root.is_in_group(group_name):
		return row_root

	if _current_obstacle_marker == null or not is_instance_valid(_current_obstacle_marker):
		return null

	var marker_parent := _current_obstacle_marker.get_parent()
	var marker_z: float = _current_obstacle_marker.global_position.z
	var best_match: Node = null
	var best_delta: float = INF

	for candidate in get_tree().get_nodes_in_group(group_name):
		if not (candidate is Node3D):
			continue
		if candidate.get_parent() != marker_parent:
			continue
		var z_delta: float = absf((candidate as Node3D).global_position.z - marker_z)
		if z_delta > max_z_delta or z_delta >= best_delta:
			continue
		best_delta = z_delta
		best_match = candidate

	return best_match


func _find_next_obstacle_marker() -> Node3D:
	## Find the nearest UPCOMING quiz obstacle marker.
	var markers := get_tree().get_nodes_in_group("quiz_obstacles")
	var best_marker: Node3D = null
	var best_z: float = -99999.0

	for marker in markers:
		if not (marker is Node3D):
			continue
		if marker.get_meta("quiz_used", false):
			continue
		var z: float = (marker as Node3D).global_position.z
		if z > 2.0:
			continue  # Already passed the player
		if z > best_z:
			best_z = z
			best_marker = marker as Node3D

	return best_marker


func _update_success_progression() -> void:
	if not _awaiting_next_question_after_success:
		return
	if not _is_current_obstacle_marker_cleared():
		return

	_awaiting_next_question_after_success = false
	_current_obstacle_marker = null
	_unlock_and_generate_next_question()


func _is_current_obstacle_marker_cleared() -> bool:
	if _current_obstacle_marker == null or not is_instance_valid(_current_obstacle_marker):
		return true
	return _current_obstacle_marker.global_position.z > 2.0


func _unlock_and_generate_next_question() -> void:
	_question_locked = false
	_generate_question()


func _make_empty_target() -> Dictionary:
	return {
		"marker": null,
		"row_root": null,
		"quiz_row_id": -1,
		"obstacle_type": QuizActionType.JUMP,
		"state": QuizTargetState.UPCOMING,
		"question_id": -1,
		"feedback_until_ms": 0,
		"next_question_at_ms": 0,
		"action_armed": false,
		"action_fired": false,
		"failed": false,
	}


func _reset_quiz_runtime_state() -> void:
	current_question = {}
	_current_obstacle_marker = null
	_awaiting_next_question_after_success = false
	_question_locked = false
	_active_target = _make_empty_target()
	_resolved_row_ids.clear()
	_next_question_id = 1


func _set_active_target_from_row(row_data: Dictionary) -> void:
	_active_target = _make_empty_target()
	_active_target["marker"] = row_data.get("marker")
	_active_target["row_root"] = row_data.get("row_root")
	_active_target["quiz_row_id"] = row_data.get("quiz_row_id", -1)
	_active_target["obstacle_type"] = row_data.get("obstacle_type", QuizActionType.JUMP)
	_active_target["state"] = QuizTargetState.UPCOMING
	_current_obstacle_marker = _active_target.get("marker") as Node3D


func _find_nearest_quiz_row() -> Dictionary:
	var best_row: Node3D = null
	var best_z: float = -99999.0

	for candidate in get_tree().get_nodes_in_group("quiz_target_rows"):
		if not (candidate is Node3D):
			continue
		var row_root := candidate as Node3D
		var row_id: int = row_root.get_meta("quiz_row_id", -1) as int
		if _resolved_row_ids.has(row_id):
			continue
		var z: float = row_root.global_position.z
		if z > QUIZ_PASS_Z:
			continue
		if z > best_z:
			best_z = z
			best_row = row_root

	if best_row == null:
		return {}

	return {
		"marker": _find_marker_for_row(best_row.get_meta("quiz_row_id", -1) as int),
		"row_root": best_row,
		"quiz_row_id": best_row.get_meta("quiz_row_id", -1),
		"obstacle_type": best_row.get_meta("quiz_obstacle_type", QuizActionType.JUMP),
	}


func _find_marker_for_row(row_id: int) -> Node3D:
	for marker in get_tree().get_nodes_in_group("quiz_obstacles"):
		if not (marker is Node3D):
			continue
		if marker.get_meta("quiz_row_id", -1) == row_id:
			return marker as Node3D
	return null


func _capture_upcoming_target() -> void:
	if _has_active_target():
		return

	var next_row := _find_nearest_quiz_row()
	if next_row.is_empty():
		return

	var time_to_impact_s: float = _get_row_time_to_impact(next_row.get("row_root") as Node3D)
	if time_to_impact_s > _get_capture_window_seconds():
		return

	_set_active_target_from_row(next_row)
	_active_target["state"] = QuizTargetState.IN_RANGE


func _spawn_first_question_for_active_target() -> void:
	if not _has_active_target():
		return
	if not current_question.is_empty() or _question_locked:
		return
	if _active_target.get("state", QuizTargetState.UPCOMING) != QuizTargetState.IN_RANGE:
		return

	_active_target["state"] = QuizTargetState.ACTIVE_QUIZ_TARGET
	_generate_question()


func _has_active_target() -> bool:
	var row_root := _active_target.get("row_root") as Node
	return row_root != null and is_instance_valid(row_root)


func _get_capture_window_seconds() -> float:
	return lerpf(TARGET_CAPTURE_TTI_MAX, TARGET_CAPTURE_TTI_MIN, GameManager.get_speed_ratio())


func _get_row_time_to_impact(row_root: Node3D) -> float:
	if row_root == null or not is_instance_valid(row_root):
		return INF
	return absf(row_root.global_position.z) / maxf(GameManager.current_speed, 0.001)


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

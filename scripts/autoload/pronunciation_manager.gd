extends Node
## PronunciationManager - placeholder for the next pronunciation assessment backend.

signal question_changed(question: Dictionary)
signal answer_result(correct: bool)
signal mic_status_changed(listening: bool)
signal volume_updated(level: float)
signal recognized_text_changed(text: String)

var _word_bank: Array[Dictionary] = []
var current_question: Dictionary = {}
var _is_active: bool = false
var _player: CharacterBody3D = null


func _ready() -> void:
	_build_word_bank()
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


func submit_assessment_result(correct: bool, recognized_text: String = "") -> void:
	if not _is_active or not GameManager.is_pronunciation_mode():
		return

	recognized_text_changed.emit(recognized_text)
	answer_result.emit(correct)

	if correct:
		_do_player_jump()

	await get_tree().create_timer(0.5).timeout
	if _is_active:
		_generate_question()


func _on_game_started() -> void:
	if GameManager.is_pronunciation_mode():
		_is_active = true
		_player = null
		await get_tree().create_timer(0.5).timeout
		_generate_question()
	else:
		_is_active = false
		current_question = {}
		_reset_hud_state()


func _on_game_over() -> void:
	_is_active = false
	current_question = {}
	_reset_hud_state()
	question_changed.emit({})


func _generate_question() -> void:
	if _word_bank.is_empty():
		push_error("PronunciationManager: word bank is empty!")
		return

	var entry: Dictionary = _word_bank.pick_random()
	current_question = {
		"text": entry.get("word", ""),
		"hint": entry.get("correct", ""),
		"accepted": entry.get("accepted", []),
	}

	question_changed.emit(current_question)
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	recognized_text_changed.emit("")


func _reset_hud_state() -> void:
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	recognized_text_changed.emit("")


func _do_player_jump() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player and _player.has_method("quiz_jump"):
		_player.call("quiz_jump")


func _build_word_bank() -> void:
	_word_bank = [
		{"word": "Cat", "correct": "KAT"},
		{"word": "Dog", "correct": "DOG"},
		{"word": "Bus", "correct": "BUS"},
		{"word": "Eat", "correct": "EET"},
		{"word": "Run", "correct": "RUN"},
		{"word": "Hat", "correct": "HAT"},
		{"word": "Sun", "correct": "SUN"},
		{"word": "Cup", "correct": "KUP"},
		{"word": "Red", "correct": "RED"},
		{"word": "Big", "correct": "BIG"},
		{"word": "Sit", "correct": "SIT"},
		{"word": "Top", "correct": "TOP"},
		{"word": "Bed", "correct": "BED"},
		{"word": "Box", "correct": "BOKS"},
		{"word": "Fish", "correct": "FISH"},
		{"word": "Milk", "correct": "MILK"},
		{"word": "Ball", "correct": "BAWL", "accepted": ["bawl"]},
		{"word": "Tree", "correct": "TREE"},
		{"word": "Book", "correct": "BUUK"},
		{"word": "Jump", "correct": "JUMP"},
		{"word": "Stop", "correct": "STOP"},
		{"word": "Go", "correct": "GOH"},
		{"word": "Play", "correct": "PLAY"},
		{"word": "Help", "correct": "HELP"},
		{"word": "Blue", "correct": "BLOO", "accepted": ["blew"]},
		{"word": "Green", "correct": "GREEN"},
		{"word": "Car", "correct": "KAR"},
		{"word": "Hand", "correct": "HAND"},
		{"word": "Leg", "correct": "LEG"},
		{"word": "Egg", "correct": "EG"},
		{"word": "Bag", "correct": "BAG"},
		{"word": "Pen", "correct": "PEN"},
		{"word": "Map", "correct": "MAP"},
		{"word": "Fox", "correct": "FOKS"},
		{"word": "Frog", "correct": "FROG"},
		{"word": "Duck", "correct": "DUK"},
		{"word": "Pig", "correct": "PIG"},
		{"word": "Hen", "correct": "HEN"},
		{"word": "Cow", "correct": "KOW"},
		{"word": "Bee", "correct": "BEE", "accepted": ["be"]},
	]

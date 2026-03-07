extends Node
## PronunciationManager — Vosk-based speech recognition for pronunciation mode.
## Connects to a local Vosk WebSocket server for real-time word recognition.
## Falls back to VAD-only if the server is unavailable.

signal question_changed(question: Dictionary)
signal answer_result(correct: bool)
signal mic_status_changed(listening: bool)
signal volume_updated(level: float)  # 0.0-1.0 normalized for HUD meter
signal recognized_text_changed(text: String)  # partial/final recognized text

# Word bank
var _word_bank: Array[Dictionary] = []

# Current state
var current_question: Dictionary = {}
var _is_active: bool = false
var _player: CharacterBody3D = null

# Microphone
var _mic_player: AudioStreamPlayer
var _capture_effect: AudioEffectCapture
var _is_listening: bool = false

# Vosk WebSocket
var _ws: WebSocketPeer
var _ws_connected: bool = false
var _ws_url: String = "ws://127.0.0.1:8765"
var _vosk_available: bool = false
var _vocabulary_sent: bool = false

# Timing
const LISTEN_TIMEOUT: float = 2.5   # max seconds to listen per word
const COOLDOWN_TIME: float = 0.5    # delay between words
var _listen_timer: float = 0.0
var _cooldown_timer: float = 0.0

# Audio conversion
var _mix_rate: float = 44100.0
const TARGET_RATE: float = 16000.0
const MIC_BUS := &"MicCapture"

# Send audio every N frames to avoid flooding WebSocket
const SEND_INTERVAL: float = 0.02  # 20ms chunks for faster response
var _send_timer: float = 0.0



func _ready() -> void:
	_mix_rate = AudioServer.get_mix_rate()
	_build_word_bank()
	_setup_mic()
	_connect_vosk()
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


# ── Mic Setup ────────────────────────────────────────────────────────────────

func _setup_mic() -> void:
	var input_devices := AudioServer.get_input_device_list()
	print("PronunciationManager: Input devices: ", input_devices)

	var bus_idx := AudioServer.get_bus_index(MIC_BUS)
	if bus_idx == -1:
		push_error("PronunciationManager: MicCapture bus not found!")
		return
	_capture_effect = AudioServer.get_bus_effect(bus_idx, 0) as AudioEffectCapture
	if not _capture_effect:
		push_error("PronunciationManager: Capture effect not found!")
		return

	_mic_player = AudioStreamPlayer.new()
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = MIC_BUS
	add_child(_mic_player)
	print("PronunciationManager: Mic setup complete.")


# ── Vosk WebSocket ───────────────────────────────────────────────────────────

func _connect_vosk() -> void:
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url(_ws_url)
	if err != OK:
		print("PronunciationManager: Could not initiate WebSocket connection (error %d)" % err)
		_vosk_available = false
	else:
		print("PronunciationManager: Connecting to Vosk server at %s ..." % _ws_url)


func _send_vocabulary() -> void:
	if not _ws_connected or _vocabulary_sent:
		return
	var vocab: Array[String] = []
	for entry in _word_bank:
		var w: String = entry.get("word", "").to_lower()
		if w and w not in vocab:
			vocab.append(w)
	var msg := JSON.stringify({"type": "config", "vocabulary": vocab})
	_ws.send_text(msg)
	_vocabulary_sent = true
	print("PronunciationManager: Sent vocabulary (%d words) to Vosk." % vocab.size())


func _send_stop() -> void:
	if _ws_connected:
		_ws.send_text(JSON.stringify({"type": "stop"}))


func _send_reset() -> void:
	## Reset the Vosk recognizer for the next word (clears leftover audio state).
	if _ws_connected:
		_ws.send_text(JSON.stringify({"type": "reset"}))


# ── Process Loop ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_poll_websocket()

	if not _is_active or GameManager.current_theme != "pronunciation":
		return

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		return

	if not _is_listening:
		return

	_listen_timer += delta
	if _listen_timer >= LISTEN_TIMEOUT:
		print("PronunciationManager: Listen timeout — wrong/no answer.")
		_on_pronunciation_result(false)
		return

	_poll_mic_and_send(delta)


func _poll_websocket() -> void:
	if _ws == null:
		return
	_ws.poll()
	var state := _ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _ws_connected:
			_ws_connected = true
			_vosk_available = true
			print("PronunciationManager: Connected to Vosk server!")
			_send_vocabulary()
		while _ws.get_available_packet_count() > 0:
			var packet := _ws.get_packet()
			var text := packet.get_string_from_utf8()
			_handle_vosk_message(text)

	elif state == WebSocketPeer.STATE_CLOSED:
		if _ws_connected:
			print("PronunciationManager: Vosk server disconnected.")
			_ws_connected = false
			_vosk_available = false
		if Engine.get_frames_drawn() % 300 == 0:
			_connect_vosk()

	elif state == WebSocketPeer.STATE_CLOSING:
		pass


func _handle_vosk_message(text: String) -> void:
	var data: Dictionary = JSON.parse_string(text)
	if data == null:
		return

	var msg_type: String = data.get("type", "")
	var recognized: String = ""

	if msg_type == "partial":
		recognized = data.get("text", "")
		recognized_text_changed.emit(recognized)
		# Accept on partial match too — much faster response
		if _is_listening and not current_question.is_empty():
			var target: String = current_question.get("text", "").to_lower().strip_edges()
			var heard: String = recognized.to_lower().strip_edges()
			if heard == target:
				print("PronunciationManager: PARTIAL MATCH '%s'!" % heard)
				_on_pronunciation_result(true)

	elif msg_type == "result" or msg_type == "final":
		recognized = data.get("text", "")
		recognized_text_changed.emit(recognized)
		if _is_listening and not current_question.is_empty():
			var target: String = current_question.get("text", "").to_lower().strip_edges()
			var heard: String = recognized.to_lower().strip_edges()
			print("PronunciationManager: Vosk heard '%s', target '%s'" % [heard, target])
			if heard == target:
				_on_pronunciation_result(true)


# ── Mic Capture & Audio Streaming ────────────────────────────────────────────

func _poll_mic_and_send(delta: float) -> void:
	if _capture_effect == null:
		return
	var frames_available := _capture_effect.get_frames_available()
	if frames_available <= 0:
		return

	var buffer: PackedVector2Array = _capture_effect.get_buffer(frames_available)
	if buffer.is_empty():
		return

	var sum_sq: float = 0.0
	for frame in buffer:
		var mono: float = (frame.x + frame.y) * 0.5
		sum_sq += mono * mono
	var rms: float = sqrt(sum_sq / buffer.size())
	var db: float = -80.0
	if rms > 0.0:
		db = 20.0 * log(rms) / log(10.0)
	var normalized: float = clampf((db + 60.0) / 60.0, 0.0, 1.0)
	volume_updated.emit(normalized)

	_send_timer += delta
	if _send_timer >= SEND_INTERVAL and _ws_connected:
		_send_timer = 0.0
		var pcm := _convert_to_pcm16(buffer)
		if pcm.size() > 0:
			_ws.send(pcm, WebSocketPeer.WRITE_MODE_BINARY)


func _convert_to_pcm16(buffer: PackedVector2Array) -> PackedByteArray:
	var ratio: float = _mix_rate / TARGET_RATE
	var out := PackedByteArray()
	var estimated_size: int = int(buffer.size() / ratio) * 2
	out.resize(estimated_size)

	var write_idx: int = 0
	var i: float = 0.0
	while int(i) < buffer.size():
		var idx := int(i)
		var frame := buffer[idx]
		var mono: float = clampf((frame.x + frame.y) * 0.5, -1.0, 1.0)
		var sample: int = int(mono * 32767.0)
		if write_idx + 1 < out.size():
			out[write_idx] = sample & 0xFF
			out[write_idx + 1] = (sample >> 8) & 0xFF
			write_idx += 2
		i += ratio

	out.resize(write_idx)
	return out


# ── Recognition Result ───────────────────────────────────────────────────────

func _on_pronunciation_result(correct: bool) -> void:
	_stop_listening()
	_send_stop()
	answer_result.emit(correct)

	if correct:
		print("PronunciationManager: CORRECT! Jump!")
		_do_player_jump()
	else:
		print("PronunciationManager: Wrong or timeout.")

	_cooldown_timer = COOLDOWN_TIME
	await get_tree().create_timer(COOLDOWN_TIME).timeout
	if _is_active:
		_generate_question()


func _start_listening() -> void:
	_send_reset()  # Fresh recognizer state for new word
	if _capture_effect:
		_capture_effect.clear_buffer()
	if _mic_player:
		_mic_player.play()
	_is_listening = true
	_listen_timer = 0.0
	_send_timer = 0.0
	recognized_text_changed.emit("")
	mic_status_changed.emit(true)
	print("PronunciationManager: Listening for '%s'..." % current_question.get("text", ""))


func _stop_listening() -> void:
	if _mic_player:
		_mic_player.stop()
	_is_listening = false
	mic_status_changed.emit(false)


# ── Player Action ────────────────────────────────────────────────────────────

func _do_player_jump() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player and _player.has_method("quiz_jump"):
		_player.call("quiz_jump")


func _on_game_started() -> void:
	print("PronunciationManager: game_started, theme = ", GameManager.current_theme)
	if GameManager.current_theme == "pronunciation":
		_is_active = true
		_player = null
		_cooldown_timer = 0.0
		_vocabulary_sent = false
		if _ws_connected:
			_send_vocabulary()
		await get_tree().create_timer(0.5).timeout
		_generate_question()
	else:
		_is_active = false
		current_question = {}


func _on_game_over() -> void:
	_is_active = false
	_stop_listening()
	_send_stop()
	current_question = {}
	question_changed.emit({})


func _generate_question() -> void:
	if _word_bank.is_empty():
		push_error("PronunciationManager: word bank is empty!")
		return

	var entry: Dictionary = _word_bank.pick_random()
	current_question = {
		"text": entry.get("word", ""),
		"hint": entry.get("correct", ""),
	}

	print("PronunciationManager: New word = '%s'" % current_question.get("text", ""))
	question_changed.emit(current_question)
	_start_listening()


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
		{"word": "Ball", "correct": "BAWL"},
		{"word": "Tree", "correct": "TREE"},
		{"word": "Book", "correct": "BUUK"},
		{"word": "Jump", "correct": "JUMP"},
		{"word": "Stop", "correct": "STOP"},
		{"word": "Go", "correct": "GOH"},
		{"word": "Play", "correct": "PLAY"},
		{"word": "Help", "correct": "HELP"},
		{"word": "Blue", "correct": "BLOO"},
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
		{"word": "Bee", "correct": "BEE"},
	]

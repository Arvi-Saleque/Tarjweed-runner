extends Node
## PronunciationManager - cloud validated pronunciation flow for pronunciation mode.

signal question_changed(question: Dictionary)
signal answer_result(correct: bool)
signal mic_status_changed(listening: bool)
signal volume_updated(level: float)
signal recognized_text_changed(text: String)
signal status_changed(text: String)

@export var backend_url: String = "http://127.0.0.1:8000/assess"
@export var ws_url: String = "ws://127.0.0.1:8000/ws/pronunciation"

@export var language: String = "en-US"
@export var max_record_duration: float = 1.25
@export var audio_chunk_interval: float = 0.03
@export var pronunciation_threshold: float = 65.0
@export var valid_action_window_before: float = 0.4
@export var valid_action_window_after: float = 0.3
@export var capture_bus_name: String = "MicCapture"
@export var preferred_input_device: String = ""
@export var request_timeout: float = 90.0
@export var record_monitor_volume_db: float = -80.0
@export var warmup_timeout: float = 10.0
@export var preparation_distance_max: float = 115.0
@export var preparation_distance_min: float = 45.0
@export var preparation_tti_max: float = 8.0
@export var preparation_tti_min: float = 6.0

const QUESTION_START_DELAY: float = 0.25
const PRONUNCIATION_PASS_Z: float = 2.0

var pronunciation_state := "idle"
var current_expected_word := ""
var current_required_action := ""
var validated_action := ""
var pronunciation_action_ready := false
var pronunciation_request_pending := false
var last_pronunciation_result := {}
var startup_warning_message := ""

var _word_bank: Array[Dictionary] = []
var current_question: Dictionary = {}
var _is_active: bool = false
var _player: CharacterBody3D = null
var _capture_effect: AudioEffectCapture = null
var _mic_player: AudioStreamPlayer = null
var _warmup_request: HTTPRequest = null
var _websocket: WebSocketPeer = null
var _is_recording: bool = false
var _question_token: int = 0
var _request_started_msec: int = 0
var _recording_started_msec: int = 0
var _audio_chunk_elapsed: float = 0.0
var _last_audio_chunk_log_msec: int = 0
var _last_ws_state: int = -1
var _ws_session_started: bool = false
var _active_target: Dictionary = {}
var _registered_targets: Array[Dictionary] = []
var _resolved_row_ids: Dictionary = {}
var _next_question_id: int = 1
var _request_row_id: int = -1
var _gameplay_started_msec: int = 0
var _last_target_debug_msec: int = 0
var _no_target_error_printed: bool = false
var _no_challenge_error_printed: bool = false


func _ready() -> void:
	_build_word_bank()
	_setup_recording_backend()
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over_triggered.connect(_on_game_over)


func _process(_delta: float) -> void:
	if not _is_active or not GameManager.is_pronunciation_mode():
		return
	_poll_websocket()
	_stream_audio_if_recording(_delta)
	_capture_upcoming_target()
	_start_challenge_for_active_target()
	_update_action_execution()
	_release_target_after_pass()
	_run_watchdogs()


func get_random_target_word_data() -> Dictionary:
	if _word_bank.is_empty():
		_build_word_bank()
	if _word_bank.is_empty():
		return {"word": "Cat", "correct": "KAT"}
	return (_word_bank.pick_random() as Dictionary).duplicate(true)


func register_target(row_node: Node3D, data: Dictionary) -> void:
	if row_node == null or not is_instance_valid(row_node):
		push_error("PronunciationManager: Cannot register invalid pronunciation target.")
		return

	var row_id := int(data.get("row_id", row_node.get_meta("pronunciation_row_id", -1)))
	var action := str(data.get("required_action", row_node.get_meta("pronunciation_required_action", "jump")))
	var expected_word := str(data.get("expected_word", row_node.get_meta("pronunciation_expected_word", "")))
	if expected_word.is_empty():
		var word_data := get_random_target_word_data()
		expected_word = str(word_data.get("word", "Cat"))

	row_node.set_meta("pronunciation_row_id", row_id)
	row_node.set_meta("pronunciation_required_action", action)
	row_node.set_meta("pronunciation_expected_word", expected_word)

	_registered_targets.append({
		"row_root": row_node,
		"row_id": row_id,
		"required_action": action,
		"expected_word": expected_word,
	})
	print("PronunciationManager: Registered pronunciation target: action=%s, word=%s, z=%.2f, row=%d" % [
		action,
		expected_word,
		row_node.global_position.z,
		row_id,
	])
	print("PronunciationManager: Target count: %d" % _registered_targets.size())


func _setup_recording_backend() -> void:
	_select_input_device()

	var bus_idx := AudioServer.get_bus_index(capture_bus_name)
	if bus_idx == -1:
		_fail_setup("Audio bus '%s' not found." % capture_bus_name)
		return
	AudioServer.set_bus_volume_db(bus_idx, record_monitor_volume_db)

	for effect_idx in AudioServer.get_bus_effect_count(bus_idx):
		var effect := AudioServer.get_bus_effect(bus_idx, effect_idx)
		if effect is AudioEffectCapture:
			_capture_effect = effect as AudioEffectCapture
			break

	if _capture_effect == null:
		_fail_setup("AudioEffectCapture not found on '%s' bus." % capture_bus_name)
		return

	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "PronunciationMicPlayer"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = capture_bus_name
	add_child(_mic_player)
	_mic_player.play()

	_warmup_request = HTTPRequest.new()
	_warmup_request.name = "PronunciationWarmupHTTPRequest"
	_warmup_request.timeout = request_timeout
	_warmup_request.use_threads = true
	add_child(_warmup_request)

	_websocket = WebSocketPeer.new()


func _select_input_device() -> void:
	var input_devices := AudioServer.get_input_device_list()
	print("PronunciationManager: Input devices: ", input_devices)

	if not preferred_input_device.is_empty() and preferred_input_device in input_devices:
		AudioServer.input_device = preferred_input_device
		print("PronunciationManager: Using preferred input device: ", preferred_input_device)
		return

	var skip_keywords := ["virtual", "droidcam", "audiorelay", "vb-audio", "cable"]
	for device in input_devices:
		var device_name := str(device)
		var lowered := device_name.to_lower()
		var is_virtual := false
		for keyword in skip_keywords:
			if keyword in lowered:
				is_virtual = true
				break
		if not is_virtual and device_name != "Default":
			AudioServer.input_device = device_name
			print("PronunciationManager: Using input device: ", device_name)
			return

	print("PronunciationManager: Using default input device: ", AudioServer.input_device)


func _fail_setup(message: String) -> void:
	var full_message := "PronunciationManager: %s" % message
	push_error(full_message)
	status_changed.emit(message)


func _on_game_started() -> void:
	if GameManager.is_pronunciation_mode():
		_is_active = true
		_player = null
		_reset_pronunciation_runtime_state()
		_gameplay_started_msec = Time.get_ticks_msec()
		if startup_warning_message.is_empty():
			status_changed.emit("Get ready...")
		else:
			status_changed.emit(startup_warning_message)
			_clear_startup_warning_later()
		question_changed.emit({})
		print("PronunciationManager: Pronunciation mode started")
		print("PronunciationManager: Voice mode gameplay started")
	else:
		_is_active = false
		_reset_pronunciation_runtime_state()
		_reset_hud_state()


func _on_game_over() -> void:
	_is_active = false
	_question_token += 1
	_stop_recording_if_needed()
	_close_websocket()
	_reset_pronunciation_runtime_state()
	_reset_hud_state()
	question_changed.emit({})


func _capture_upcoming_target() -> void:
	if _has_active_target() or pronunciation_request_pending or _is_recording:
		return

	var next_row := _find_nearest_registered_target()
	if next_row.is_empty():
		return

	var row_root := next_row.get("row_root") as Node3D
	var distance_to_target := _get_row_distance(row_root)
	var time_to_impact_s := _get_row_time_to_impact(row_root)
	_debug_nearest_target(distance_to_target, time_to_impact_s)
	if distance_to_target > preparation_distance_max:
		return

	_set_active_target_from_row(next_row)
	pronunciation_state = "idle"
	status_changed.emit("Get ready...")


func _start_challenge_for_active_target() -> void:
	if not _has_active_target():
		return
	if not current_question.is_empty():
		return
	if pronunciation_state != "idle":
		return

	_generate_question_for_active_target()


func _generate_question_for_active_target() -> void:
	if _word_bank.is_empty():
		push_error("PronunciationManager: word bank is empty!")
		return

	_question_token += 1
	var token := _question_token
	var entry: Dictionary = {
		"word": str(_active_target.get("expected_word", "")),
		"correct": str(_active_target.get("expected_word", "")).to_upper(),
	}
	if str(entry.get("word", "")).is_empty():
		entry = get_random_target_word_data()
	current_expected_word = str(entry.get("word", ""))
	current_required_action = str(_active_target.get("required_action", "jump"))
	validated_action = ""
	pronunciation_action_ready = false
	last_pronunciation_result = {}

	current_question = {
		"text": current_expected_word,
		"hint": entry.get("correct", ""),
		"accepted": entry.get("accepted", []),
		"required_action": current_required_action,
		"question_id": _next_question_id,
		"pronunciation_row_id": _active_target.get("row_id", -1),
		"time_to_impact_s": _get_active_target_time_to_impact(),
	}
	_next_question_id += 1

	question_changed.emit(current_question)
	recognized_text_changed.emit("")
	volume_updated.emit(0.0)
	status_changed.emit("Get ready...")
	mic_status_changed.emit(false)
	_ensure_websocket_connected()
	print("PronunciationManager: Prepared '%s' for %s row %d." % [
		current_expected_word,
		current_required_action,
		_active_target.get("row_id", -1),
	])
	print("PronunciationManager: Prepared word: %s" % current_expected_word)

	await get_tree().create_timer(QUESTION_START_DELAY).timeout
	if _is_active and token == _question_token and _has_active_target():
		_start_recording_for_current_question(token)


func _start_recording_for_current_question(token: int) -> void:
	if _capture_effect == null:
		_mark_pronunciation_failed("Audio capture is not ready.")
		return
	if pronunciation_request_pending:
		return

	_stop_recording_if_needed()
	if _mic_player and not _mic_player.playing:
		_mic_player.play()

	var connected := await _wait_for_websocket_open(0.75)
	if not connected:
		_mark_pronunciation_failed("Voice server is not connected.")
		return

	_capture_effect.clear_buffer()
	_send_start_message()
	_is_recording = true
	_ws_session_started = true
	pronunciation_request_pending = true
	_request_row_id = int(_active_target.get("row_id", -1))
	_request_started_msec = Time.get_ticks_msec()
	_recording_started_msec = Time.get_ticks_msec()
	_audio_chunk_elapsed = 0.0
	pronunciation_state = "recording"
	mic_status_changed.emit(true)
	volume_updated.emit(0.8)
	status_changed.emit("Listening...")
	print("PronunciationManager: Recording started for '%s'." % current_expected_word)

	await get_tree().create_timer(max_record_duration).timeout
	if _is_active and token == _question_token and _has_active_target():
		_stop_recording_and_wait_for_result()


func _stop_recording_and_wait_for_result() -> void:
	if not _is_recording:
		return
	_send_pending_audio_chunk()
	_is_recording = false
	_ws_session_started = false
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	pronunciation_state = "checking"
	status_changed.emit("Checking pronunciation...")
	print("PronunciationManager: Recording stopped.")
	_send_text_message({"type": "stop"})
	print("PronunciationManager: Stop message sent")


func _ensure_websocket_connected() -> void:
	if _websocket == null:
		_websocket = WebSocketPeer.new()
	var state := _websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN or state == WebSocketPeer.STATE_CONNECTING:
		return
	if state == WebSocketPeer.STATE_CLOSING:
		return

	_websocket = WebSocketPeer.new()
	var error := _websocket.connect_to_url(ws_url)
	if error != OK:
		push_error("PronunciationManager: WebSocket connect failed: %s" % error_string(error))
		return
	_last_ws_state = WebSocketPeer.STATE_CONNECTING
	print("PronunciationManager: WebSocket connecting: %s" % ws_url)


func _wait_for_websocket_open(timeout_seconds: float) -> bool:
	_ensure_websocket_connected()
	var start_msec := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_msec < int(timeout_seconds * 1000.0):
		_poll_websocket()
		if _is_websocket_open():
			return true
		await get_tree().process_frame
	return _is_websocket_open()


func _poll_websocket() -> void:
	if _websocket == null:
		return
	_websocket.poll()
	var state := _websocket.get_ready_state()
	if state != _last_ws_state:
		_last_ws_state = state
		match state:
			WebSocketPeer.STATE_OPEN:
				print("PronunciationManager: WebSocket connected")
			WebSocketPeer.STATE_CLOSED:
				print("PronunciationManager: WebSocket closed")
			WebSocketPeer.STATE_CLOSING:
				print("PronunciationManager: WebSocket closing")

	while _websocket.get_available_packet_count() > 0:
		var packet := _websocket.get_packet()
		if _websocket.was_string_packet():
			var text := packet.get_string_from_utf8()
			var data: Variant = JSON.parse_string(text)
			if data is Dictionary:
				_handle_websocket_message(data as Dictionary)
			else:
				print("PronunciationManager: Invalid WebSocket JSON: %s" % text)


func _handle_websocket_message(message: Dictionary) -> void:
	var message_type := str(message.get("type", ""))
	match message_type:
		"started":
			print("PronunciationManager: WebSocket backend started stream")
		"result":
			_handle_streaming_result(message)
		"error":
			pronunciation_request_pending = false
			_mark_pronunciation_failed(str(message.get("message", "Voice server error")))
		_:
			print("PronunciationManager: WebSocket message: %s" % JSON.stringify(message))


func _handle_streaming_result(response: Dictionary) -> void:
	pronunciation_request_pending = false
	var elapsed_ms := Time.get_ticks_msec() - _request_started_msec
	print("PronunciationManager: Result received")
	print("PronunciationManager: backend_elapsed_ms = %d" % elapsed_ms)

	if not _is_active or not GameManager.is_pronunciation_mode():
		return

	if not bool(response.get("success", false)):
		_mark_pronunciation_failed(str(response.get("message", "Pronunciation check failed.")))
		return

	var recognized_text := str(response.get("recognized_text", ""))
	var scores: Dictionary = response.get("scores", {}) as Dictionary
	var correct := bool(response.get("correct", false))
	var expected_text := str(response.get("expected_text", current_expected_word))

	last_pronunciation_result = response
	recognized_text_changed.emit(recognized_text)
	_print_debug_result(expected_text, recognized_text, correct, scores)
	print("PronunciationManager: correct=%s" % str(correct))

	if not _has_active_target() or int(_active_target.get("row_id", -1)) != _request_row_id:
		print("PronunciationManager: Ignoring late result for row %d." % _request_row_id)
		_clear_current_challenge()
		return

	if correct:
		pronunciation_state = "correct_ready"
		validated_action = str(response.get("required_action", current_required_action))
		pronunciation_action_ready = true
		status_changed.emit(str(response.get("message", "Ready!")))
		answer_result.emit(true)
		print("PronunciationManager: Cloud validated action '%s' for row %d." % [
			validated_action,
			_active_target.get("row_id", -1),
		])
		if _is_inside_valid_action_window():
			_fire_validated_action()
		elif _is_action_window_late():
			_active_target["action_window_missed"] = true
			pronunciation_action_ready = false
			answer_result.emit(false)
			print("PronunciationManager: action missed")
	else:
		_mark_pronunciation_failed(str(response.get("message", "Try again")))


func _send_start_message() -> void:
	var sample_rate := AudioServer.get_mix_rate()
	_send_text_message({
		"type": "start",
		"expected_text": current_expected_word,
		"language": language,
		"required_action": current_required_action,
		"sample_rate": sample_rate,
		"threshold": pronunciation_threshold,
	})
	print("PronunciationManager: Start message sent")


func _send_text_message(message: Dictionary) -> void:
	if not _is_websocket_open():
		push_error("PronunciationManager: Cannot send WebSocket text while disconnected.")
		return
	var error := _websocket.send_text(JSON.stringify(message))
	if error != OK:
		push_error("PronunciationManager: WebSocket text send failed: %s" % error_string(error))


func _stream_audio_if_recording(delta: float) -> void:
	if not _is_recording or not _ws_session_started:
		return
	_audio_chunk_elapsed += delta
	if _audio_chunk_elapsed < audio_chunk_interval:
		return
	_audio_chunk_elapsed = 0.0
	_send_pending_audio_chunk()


func _send_pending_audio_chunk() -> void:
	if _capture_effect == null or not _is_websocket_open():
		return
	var frames_available := _capture_effect.get_frames_available()
	if frames_available <= 0:
		return
	var frames := _capture_effect.get_buffer(frames_available)
	var audio_bytes := _frames_to_pcm16_mono(frames)
	if audio_bytes.is_empty():
		return
	var error := _websocket.put_packet(audio_bytes)
	if error != OK:
		push_error("PronunciationManager: WebSocket audio send failed: %s" % error_string(error))
		return
	var now := Time.get_ticks_msec()
	if now - _last_audio_chunk_log_msec > 250:
		_last_audio_chunk_log_msec = now
		print("PronunciationManager: Audio chunk sent size=%d" % audio_bytes.size())


func _frames_to_pcm16_mono(frames: PackedVector2Array) -> PackedByteArray:
	var audio_bytes := PackedByteArray()
	audio_bytes.resize(frames.size() * 2)
	var byte_index := 0
	for frame in frames:
		var mono := clampf((frame.x + frame.y) * 0.5, -1.0, 1.0)
		var sample := int(mono * 32767.0)
		if sample < 0:
			sample += 65536
		audio_bytes[byte_index] = sample & 0xff
		audio_bytes[byte_index + 1] = (sample >> 8) & 0xff
		byte_index += 2
	return audio_bytes


func _is_websocket_open() -> bool:
	return _websocket != null and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN


func _close_websocket() -> void:
	if _websocket:
		_websocket.close()
	_ws_session_started = false


func _update_action_execution() -> void:
	if not _has_active_target():
		return
	if bool(_active_target.get("action_fired", false)):
		return
	if bool(_active_target.get("action_window_missed", false)):
		return
	if _is_action_window_late():
		_active_target["action_window_missed"] = true
		if pronunciation_state == "checking":
			pronunciation_state = "pending"
			status_changed.emit("Voice result not ready")
		else:
			pronunciation_state = "wrong"
		answer_result.emit(false)
		print("PronunciationManager: No validated pronunciation ready at obstacle row %d." % _active_target.get("row_id", -1))
		print("PronunciationManager: action missed")
		return

	if pronunciation_action_ready and validated_action == str(_active_target.get("required_action", "jump")):
		if _is_inside_valid_action_window():
			_fire_validated_action()
		return


func _fire_validated_action() -> void:
	if not _player:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if _player and _player.has_method("quiz_jump"):
		_player.call("quiz_jump")
	_active_target["action_fired"] = true
	pronunciation_action_ready = false
	pronunciation_state = "idle"
	status_changed.emit("Jump!")
	print("PronunciationManager: Fired validated action '%s' for row %d." % [
		validated_action,
		_active_target.get("row_id", -1),
	])


func _is_inside_valid_action_window() -> bool:
	var row_root := _get_active_target_row()
	if row_root == null:
		return false
	var speed := maxf(GameManager.current_speed, 0.001)
	var z := row_root.global_position.z
	return z >= -valid_action_window_before * speed and z <= valid_action_window_after * speed


func _is_action_window_late() -> bool:
	var row_root := _get_active_target_row()
	if row_root == null:
		return true
	return row_root.global_position.z > valid_action_window_after * maxf(GameManager.current_speed, 0.001)


func _mark_pronunciation_failed(message: String) -> void:
	print("PronunciationManager: %s" % message)
	pronunciation_state = "wrong"
	pronunciation_action_ready = false
	validated_action = ""
	status_changed.emit(message)
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	answer_result.emit(false)


func _find_nearest_pronunciation_row() -> Dictionary:
	var best_row: Node3D = null
	var best_z: float = -99999.0

	for candidate in get_tree().get_nodes_in_group("pronunciation_target_rows"):
		if not (candidate is Node3D):
			continue
		var row_root := candidate as Node3D
		var row_id: int = row_root.get_meta("pronunciation_row_id", -1) as int
		if _resolved_row_ids.has(row_id):
			continue
		var z := row_root.global_position.z
		if z > PRONUNCIATION_PASS_Z:
			continue
		if z > best_z:
			best_z = z
			best_row = row_root

	if best_row == null:
		return {}

	return {
		"row_root": best_row,
		"row_id": best_row.get_meta("pronunciation_row_id", -1),
		"required_action": best_row.get_meta("pronunciation_required_action", "jump"),
		"expected_word": best_row.get_meta("pronunciation_expected_word", ""),
	}


func _find_nearest_registered_target() -> Dictionary:
	_prune_registered_targets()
	var best_target: Dictionary = {}
	var best_distance := INF

	for target in _registered_targets:
		var row_root := target.get("row_root") as Node3D
		if row_root == null or not is_instance_valid(row_root):
			continue
		var row_id := int(target.get("row_id", -1))
		if _resolved_row_ids.has(row_id):
			continue
		if row_root.global_position.z > PRONUNCIATION_PASS_Z:
			continue
		var distance := _get_row_distance(row_root)
		if distance < best_distance:
			best_distance = distance
			best_target = target

	if best_target.is_empty():
		return _find_nearest_pronunciation_row()
	return best_target


func _prune_registered_targets() -> void:
	for i in range(_registered_targets.size() - 1, -1, -1):
		var target := _registered_targets[i]
		var row_root := target.get("row_root") as Node3D
		var row_id := int(target.get("row_id", -1))
		if row_root == null or not is_instance_valid(row_root) or _resolved_row_ids.has(row_id):
			_registered_targets.remove_at(i)


func _set_active_target_from_row(row_data: Dictionary) -> void:
	_active_target = _make_empty_target()
	_active_target["row_root"] = row_data.get("row_root")
	_active_target["row_id"] = row_data.get("row_id", -1)
	_active_target["required_action"] = row_data.get("required_action", "jump")
	_active_target["expected_word"] = row_data.get("expected_word", "")
	_active_target["state"] = "in_range"


func _release_target_after_pass() -> void:
	if not _has_active_target():
		return
	if not _is_action_window_late():
		return

	var row_id := int(_active_target.get("row_id", -1))
	if row_id >= 0:
		_resolved_row_ids[row_id] = true
	_active_target = _make_empty_target()
	_question_token += 1
	current_question = {}
	current_expected_word = ""
	current_required_action = ""
	validated_action = ""
	pronunciation_action_ready = false
	last_pronunciation_result = {}
	if not pronunciation_request_pending:
		_clear_current_challenge()
	else:
		recognized_text_changed.emit("")
		question_changed.emit({})


func _clear_current_challenge() -> void:
	pronunciation_state = "idle"
	current_question = {}
	current_expected_word = ""
	current_required_action = ""
	validated_action = ""
	pronunciation_action_ready = false
	last_pronunciation_result = {}
	recognized_text_changed.emit("")
	status_changed.emit("")
	question_changed.emit({})


func _has_active_target() -> bool:
	return _get_active_target_row() != null


func _get_active_target_row() -> Node3D:
	var row_root = _active_target.get("row_root")
	if row_root == null or not is_instance_valid(row_root):
		return null
	if row_root is Node3D:
		return row_root as Node3D
	return null


func _get_active_target_time_to_impact() -> float:
	return _get_row_time_to_impact(_get_active_target_row())


func _get_row_time_to_impact(row_root: Node3D) -> float:
	if row_root == null or not is_instance_valid(row_root):
		return INF
	return absf(row_root.global_position.z) / maxf(GameManager.current_speed, 0.001)


func _get_row_distance(row_root: Node3D) -> float:
	if row_root == null or not is_instance_valid(row_root):
		return INF
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	var player_z := _player.global_position.z if _player else 0.0
	return absf(row_root.global_position.z - player_z)


func _get_preparation_window_seconds() -> float:
	return lerpf(preparation_tti_max, preparation_tti_min, GameManager.get_speed_ratio())


func _make_empty_target() -> Dictionary:
	return {
		"row_root": null,
		"row_id": -1,
		"required_action": "jump",
		"expected_word": "",
		"state": "idle",
		"action_fired": false,
		"action_window_missed": false,
	}


func _reset_pronunciation_runtime_state() -> void:
	pronunciation_state = "idle"
	current_expected_word = ""
	current_required_action = ""
	validated_action = ""
	pronunciation_action_ready = false
	pronunciation_request_pending = false
	last_pronunciation_result = {}
	_is_recording = false
	_ws_session_started = false
	_audio_chunk_elapsed = 0.0
	_last_audio_chunk_log_msec = 0
	current_question = {}
	_active_target = _make_empty_target()
	_registered_targets.clear()
	_resolved_row_ids.clear()
	_next_question_id = 1
	_request_row_id = -1
	_gameplay_started_msec = Time.get_ticks_msec()
	_last_target_debug_msec = 0
	_no_target_error_printed = false
	_no_challenge_error_printed = false


func _clear_startup_warning_later() -> void:
	await get_tree().create_timer(3.0).timeout
	if _is_active and current_question.is_empty() and not startup_warning_message.is_empty():
		startup_warning_message = ""
		status_changed.emit("Get ready...")


func _debug_nearest_target(distance_to_target: float, time_to_impact_s: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_target_debug_msec < 1000:
		return
	_last_target_debug_msec = now
	print("PronunciationManager: Nearest target distance=%.2f tti=%.2f target_count=%d" % [
		distance_to_target,
		time_to_impact_s,
		_registered_targets.size(),
	])


func _run_watchdogs() -> void:
	if _gameplay_started_msec <= 0:
		return
	var elapsed_sec := float(Time.get_ticks_msec() - _gameplay_started_msec) / 1000.0
	if elapsed_sec >= 5.0 and not _no_target_error_printed:
		_prune_registered_targets()
		if _registered_targets.is_empty():
			_no_target_error_printed = true
			push_error("PronunciationManager: ERROR: No pronunciation targets registered. Check obstacle spawning/metadata.")
	if elapsed_sec >= 10.0 and not _no_challenge_error_printed:
		if current_question.is_empty():
			_no_challenge_error_printed = true
			push_error("PronunciationManager: ERROR: No pronunciation challenge prepared. Check distance/TTI window.")


func warmup_backend_before_gameplay(timeout_seconds: float = -1.0) -> bool:
	print("PronunciationManager: Voice mode loading started")
	var warmup_url := _get_backend_origin_url()
	if warmup_url.is_empty():
		print("PronunciationManager: Warmup failed with empty backend URL")
		return false

	if timeout_seconds <= 0.0:
		timeout_seconds = warmup_timeout

	if _warmup_request == null:
		_warmup_request = HTTPRequest.new()
		_warmup_request.name = "PronunciationWarmupHTTPRequest"
		_warmup_request.timeout = timeout_seconds
		_warmup_request.use_threads = true
		add_child(_warmup_request)

	if _warmup_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_warmup_request.cancel_request()

	var done := false
	var success := false
	var response := 0
	var completed := func(_result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
		response = response_code
		success = (_result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300)
		done = true

	if not _warmup_request.request_completed.is_connected(completed):
		_warmup_request.request_completed.connect(completed)

	_warmup_request.timeout = timeout_seconds
	var error := _warmup_request.request(warmup_url)
	print("PronunciationManager: Warmup GET request sent: %s" % warmup_url)
	if error != OK:
		_warmup_request.request_completed.disconnect(completed)
		print("PronunciationManager: Warmup failed to start: %s" % error_string(error))
		return false

	var timeout_timer := get_tree().create_timer(timeout_seconds)
	while not done and timeout_timer.time_left > 0.0:
		await get_tree().process_frame

	if _warmup_request.request_completed.is_connected(completed):
		_warmup_request.request_completed.disconnect(completed)

	if not done:
		_warmup_request.cancel_request()
		print("PronunciationManager: Warmup timeout, starting gameplay anyway")
		return false

	if success:
		print("PronunciationManager: Warmup success")
	else:
		print("PronunciationManager: Warmup failed with response code %d" % response)
	return success


func _get_backend_origin_url() -> String:
	if not ws_url.is_empty():
		var http_url := ws_url.replace("ws://", "http://").replace("wss://", "https://")
		return _get_origin_from_url(http_url)
	return _get_origin_from_url(backend_url)


func _get_origin_from_url(url: String) -> String:
	var marker := "://"
	var marker_idx := url.find(marker)
	if marker_idx == -1:
		return ""
	var path_start := url.find("/", marker_idx + marker.length())
	if path_start == -1:
		return url
	return url.substr(0, path_start + 1)


func _print_debug_result(expected_text: String, recognized_text: String, correct: bool, scores: Dictionary) -> void:
	print("PronunciationManager: expected_text = %s" % expected_text)
	print("PronunciationManager: recognized_text = %s" % recognized_text)
	print("PronunciationManager: correct = %s" % str(correct))
	print("PronunciationManager: accuracy = %s" % str(scores.get("accuracy", "")))
	print("PronunciationManager: fluency = %s" % str(scores.get("fluency", "")))
	print("PronunciationManager: completeness = %s" % str(scores.get("completeness", "")))
	print("PronunciationManager: pronunciation = %s" % str(scores.get("pronunciation", "")))


func _stop_recording_if_needed() -> void:
	if _is_recording:
		_send_pending_audio_chunk()
		if _is_websocket_open():
			_send_text_message({"type": "stop"})
	_is_recording = false
	_ws_session_started = false


func _reset_hud_state() -> void:
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	recognized_text_changed.emit("")
	status_changed.emit("")


func _build_word_bank() -> void:
	# Stable demo words only. Very short/noisy words like Go, Cup, Bag, Eat
	# caused occasional empty/low-score Azure results in local tests.
	# Keep this list clean for classroom/campus demo reliability.
	_word_bank = [
		{"word": "Big", "correct": "BIG"},
		{"word": "Sun", "correct": "SUN"},
		{"word": "Dog", "correct": "DOG"},
		{"word": "Frog", "correct": "FROG"},
		{"word": "Duck", "correct": "DUK"},
		{"word": "Hat", "correct": "HAT"},
		{"word": "Ball", "correct": "BAWL", "accepted": ["bawl"]},
		{"word": "Play", "correct": "PLAY"},
		{"word": "Pen", "correct": "PEN"},
		{"word": "Car", "correct": "KAR"},
		{"word": "Blue", "correct": "BLOO", "accepted": ["blew"]},
		{"word": "Box", "correct": "BOKS"},
		{"word": "Jump", "correct": "JUMP"},
		{"word": "Leg", "correct": "LEG"},
		{"word": "Hand", "correct": "HAND"},
		{"word": "Book", "correct": "BUUK"},
		{"word": "Egg", "correct": "EG"},
	]

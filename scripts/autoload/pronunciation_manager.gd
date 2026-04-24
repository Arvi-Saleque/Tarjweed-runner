extends Node
## PronunciationManager - cloud validated pronunciation flow for pronunciation mode.

signal question_changed(question: Dictionary)
signal answer_result(correct: bool)
signal mic_status_changed(listening: bool)
signal volume_updated(level: float)
signal recognized_text_changed(text: String)
signal status_changed(text: String)

@export var backend_url: String = "https://tajweed-pronunciation-backend.onrender.com/assess"
@export var language: String = "en-US"
@export var record_duration: float = 1.25
@export var record_bus_name: String = "Record"
@export var recording_path: String = "user://pronunciation_input.wav"
@export var preferred_input_device: String = ""
@export var request_timeout: float = 90.0
@export var record_monitor_volume_db: float = -80.0
@export var warmup_timeout: float = 10.0
@export var preparation_distance_max: float = 80.0
@export var preparation_distance_min: float = 45.0
@export var preparation_tti_max: float = 6.5
@export var preparation_tti_min: float = 5.0

const QUESTION_START_DELAY: float = 0.25
const JUMP_ACTION_TTI_SECONDS: float = 0.45
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
var _record_effect: AudioEffectRecord = null
var _mic_player: AudioStreamPlayer = null
var _http_request: HTTPRequest = null
var _warmup_request: HTTPRequest = null
var _is_recording: bool = false
var _question_token: int = 0
var _request_started_msec: int = 0
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

	var bus_idx := AudioServer.get_bus_index(record_bus_name)
	if bus_idx == -1:
		_fail_setup("Audio bus '%s' not found." % record_bus_name)
		return
	AudioServer.set_bus_volume_db(bus_idx, record_monitor_volume_db)

	for effect_idx in AudioServer.get_bus_effect_count(bus_idx):
		var effect := AudioServer.get_bus_effect(bus_idx, effect_idx)
		if effect is AudioEffectRecord:
			_record_effect = effect as AudioEffectRecord
			break

	if _record_effect == null:
		_fail_setup("AudioEffectRecord not found on '%s' bus." % record_bus_name)
		return

	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "PronunciationMicPlayer"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = record_bus_name
	add_child(_mic_player)
	_mic_player.play()

	_http_request = HTTPRequest.new()
	_http_request.name = "PronunciationHTTPRequest"
	_http_request.timeout = request_timeout
	_http_request.use_threads = true
	add_child(_http_request)
	_http_request.request_completed.connect(_on_http_request_completed)

	_warmup_request = HTTPRequest.new()
	_warmup_request.name = "PronunciationWarmupHTTPRequest"
	_warmup_request.timeout = request_timeout
	_warmup_request.use_threads = true
	add_child(_warmup_request)


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
	if _http_request and pronunciation_request_pending:
		_http_request.cancel_request()
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
	if _record_effect == null:
		_mark_pronunciation_failed("Recorder is not ready.")
		return
	if pronunciation_request_pending:
		return

	_stop_recording_if_needed()
	if _mic_player and not _mic_player.playing:
		_mic_player.play()

	_record_effect.set_recording_active(true)
	_is_recording = true
	pronunciation_state = "recording"
	mic_status_changed.emit(true)
	volume_updated.emit(0.8)
	status_changed.emit("Recording...")
	print("PronunciationManager: Recording started for '%s'." % current_expected_word)

	await get_tree().create_timer(record_duration).timeout
	if _is_active and token == _question_token and _has_active_target():
		_stop_recording_and_send()


func _stop_recording_and_send() -> void:
	if _record_effect == null:
		_mark_pronunciation_failed("Recorder is not ready.")
		return

	if _is_recording:
		_record_effect.set_recording_active(false)
	_is_recording = false
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	pronunciation_state = "checking"
	status_changed.emit("Checking pronunciation...")
	print("PronunciationManager: Recording stopped.")

	var recording := _record_effect.get_recording()
	if recording == null:
		_mark_pronunciation_failed("No recording found.")
		return

	var io_start_msec := Time.get_ticks_msec()
	var save_error := recording.save_to_wav(recording_path)
	if save_error != OK:
		_mark_pronunciation_failed("Failed to save recording.")
		return

	var audio_bytes := FileAccess.get_file_as_bytes(recording_path)
	if audio_bytes.is_empty():
		_mark_pronunciation_failed("Recorded audio file is empty.")
		return

	var peak := _get_recording_peak_16bit(recording)
	print("PronunciationManager: recording_io_elapsed_ms = %d" % (Time.get_ticks_msec() - io_start_msec))
	_print_recording_debug(recording, audio_bytes.size(), peak)
	_send_audio_to_backend(audio_bytes)


func _send_audio_to_backend(audio_bytes: PackedByteArray) -> void:
	if _http_request == null:
		_mark_pronunciation_failed("HTTP client is not ready.")
		return
	if current_expected_word.is_empty():
		_mark_pronunciation_failed("No pronunciation word is active.")
		return

	var url := backend_url + "?expected_text=" + current_expected_word.uri_encode() + "&language=" + language.uri_encode()
	var headers := PackedStringArray(["Content-Type: audio/wav"])
	var error := _http_request.request_raw(url, headers, HTTPClient.METHOD_POST, audio_bytes)
	if error != OK:
		_mark_pronunciation_failed("Failed to send audio to backend.")
		return

	pronunciation_request_pending = true
	_request_row_id = int(_active_target.get("row_id", -1))
	_request_started_msec = Time.get_ticks_msec()
	print("PronunciationManager: Sent recording to backend: %s" % url)


func _on_http_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	pronunciation_request_pending = false
	var elapsed_ms := Time.get_ticks_msec() - _request_started_msec
	print("PronunciationManager: backend_elapsed_ms = %d" % elapsed_ms)

	if not _is_active or not GameManager.is_pronunciation_mode():
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		_mark_pronunciation_failed("Backend request failed.")
		return

	if response_code < 200 or response_code >= 300:
		_mark_pronunciation_failed("Backend error: %d" % response_code)
		return

	var response_text := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(response_text)
	if not (data is Dictionary):
		_mark_pronunciation_failed("Invalid JSON response from backend.")
		return

	var response := data as Dictionary
	if not bool(response.get("success", false)):
		_mark_pronunciation_failed(str(response.get("message", response.get("error", "Pronunciation check failed."))))
		return

	var recognized_text := str(response.get("recognized_text", ""))
	var scores: Dictionary = response.get("scores", {}) as Dictionary
	var correct := bool(response.get("correct", false))
	var expected_text := str(response.get("expected_text", current_expected_word))

	last_pronunciation_result = response
	recognized_text_changed.emit(recognized_text)
	_print_debug_result(expected_text, recognized_text, correct, scores)

	if not _has_active_target() or int(_active_target.get("row_id", -1)) != _request_row_id:
		print("PronunciationManager: Ignoring late result for row %d." % _request_row_id)
		_clear_current_challenge()
		return

	if bool(_active_target.get("action_window_missed", false)):
		pronunciation_state = "wrong"
		status_changed.emit("Too late")
		answer_result.emit(false)
		print("PronunciationManager: Cloud result arrived after action window.")
		return

	if correct:
		pronunciation_state = "correct_ready"
		validated_action = current_required_action
		pronunciation_action_ready = true
		status_changed.emit(str(response.get("message", "Ready!")))
		answer_result.emit(true)
		print("PronunciationManager: Cloud validated action '%s' for row %d." % [
			validated_action,
			_active_target.get("row_id", -1),
		])
	else:
		_mark_pronunciation_failed(str(response.get("message", "Try again")))


func _update_action_execution() -> void:
	if not _has_active_target():
		return
	if bool(_active_target.get("action_fired", false)):
		return
	if bool(_active_target.get("action_window_missed", false)):
		return
	if _get_active_target_time_to_impact() > JUMP_ACTION_TTI_SECONDS:
		return

	if pronunciation_action_ready and validated_action == str(_active_target.get("required_action", "jump")):
		_fire_validated_action()
		return

	_active_target["action_window_missed"] = true
	if pronunciation_state == "checking":
		pronunciation_state = "pending"
		status_changed.emit("Voice result not ready")
	else:
		pronunciation_state = "wrong"
	answer_result.emit(false)
	print("PronunciationManager: No validated pronunciation ready at obstacle row %d." % _active_target.get("row_id", -1))


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
	var row_root := _get_active_target_row()
	if row_root != null and is_instance_valid(row_root) and row_root.global_position.z <= PRONUNCIATION_PASS_Z:
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
	var marker := "://"
	var marker_idx := backend_url.find(marker)
	if marker_idx == -1:
		return ""
	var path_start := backend_url.find("/", marker_idx + marker.length())
	if path_start == -1:
		return backend_url
	return backend_url.substr(0, path_start + 1)


func _print_debug_result(expected_text: String, recognized_text: String, correct: bool, scores: Dictionary) -> void:
	print("PronunciationManager: expected_text = %s" % expected_text)
	print("PronunciationManager: recognized_text = %s" % recognized_text)
	print("PronunciationManager: correct = %s" % str(correct))
	print("PronunciationManager: accuracy = %s" % str(scores.get("accuracy", "")))
	print("PronunciationManager: fluency = %s" % str(scores.get("fluency", "")))
	print("PronunciationManager: completeness = %s" % str(scores.get("completeness", "")))
	print("PronunciationManager: pronunciation = %s" % str(scores.get("pronunciation", "")))


func _get_recording_peak_16bit(recording: AudioStreamWAV) -> int:
	var data_size := recording.data.size()
	var peak := 0
	if recording.format == AudioStreamWAV.FORMAT_16_BITS:
		var i := 0
		while i + 1 < data_size:
			var sample := int(recording.data[i]) | (int(recording.data[i + 1]) << 8)
			if sample >= 32768:
				sample -= 65536
			peak = maxi(peak, absi(sample))
			i += 2
	return peak


func _print_recording_debug(recording: AudioStreamWAV, wav_file_size: int, peak: int) -> void:
	var data_size := recording.data.size()
	print("PronunciationManager: wav_file_size = %d bytes" % wav_file_size)
	print("PronunciationManager: wav_data_size = %d bytes" % data_size)
	print("PronunciationManager: wav_mix_rate = %d" % recording.mix_rate)
	print("PronunciationManager: wav_stereo = %s" % str(recording.stereo))
	print("PronunciationManager: wav_format = %d" % recording.format)
	print("PronunciationManager: wav_peak_16bit = %d" % peak)


func _stop_recording_if_needed() -> void:
	if _record_effect and _is_recording:
		_record_effect.set_recording_active(false)
	_is_recording = false


func _reset_hud_state() -> void:
	mic_status_changed.emit(false)
	volume_updated.emit(0.0)
	recognized_text_changed.emit("")
	status_changed.emit("")


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

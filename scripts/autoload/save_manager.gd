extends Node
## SaveManager - Persistent storage singleton.
## Saves/loads high scores, total coins, and settings to a JSON file.

const SAVE_PATH: String = "user://save_data.json"

var _data: Dictionary = {}
var _dirty: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_from_disk()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_to_disk()


# --- High Score ---

func get_high_score() -> int:
	return int(_data.get("high_score", 0))


func set_high_score(value: int) -> void:
	_data["high_score"] = value
	_mark_dirty()


# --- Total Coins (lifetime) ---

func get_total_coins() -> int:
	return int(_data.get("total_coins", 0))


func add_coins(amount: int) -> void:
	_data["total_coins"] = get_total_coins() + amount
	_mark_dirty()


# --- Settings ---

func get_setting(key: String, default_value: Variant = null) -> Variant:
	var settings: Dictionary = _data.get("settings", {})
	return settings.get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	if not _data.has("settings"):
		_data["settings"] = {}
	_data["settings"][key] = value
	_mark_dirty()


# --- Disk I/O ---

func save_now() -> void:
	_save_to_disk()


func _mark_dirty() -> void:
	if not _dirty:
		_dirty = true
		# Defer save to batch multiple writes in the same frame
		_save_to_disk.call_deferred()


func _save_to_disk() -> void:
	if not _dirty:
		return
	_dirty = false

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Failed to open %s for writing: %s" % [SAVE_PATH, error_string(FileAccess.get_open_error())])
		return

	var json_string: String = JSON.stringify(_data, "\t")
	file.store_string(json_string)
	file.close()


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = {
			"high_score": 0,
			"total_coins": 0,
			"settings": {
				"music_enabled": true,
				"sfx_enabled": true,
				"music_volume": 0.8,
				"sfx_volume": 1.0,
			}
		}
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open %s for reading." % SAVE_PATH)
		_data = {}
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result: Error = json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		_data = {}
		return

	if json.data is Dictionary:
		_data = json.data
	else:
		push_error("SaveManager: Save data is not a Dictionary.")
		_data = {}

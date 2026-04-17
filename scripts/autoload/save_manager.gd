extends Node
## SaveManager - Persistent storage singleton.
## Saves/loads high scores, total coins, and settings to a JSON file.

const SAVE_PATH: String = "user://save_data.json"
const MenuFlowCatalog = preload("res://scripts/ui/menu_flow_catalog.gd")

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


func get_wallet_coins() -> int:
	return int(_data.get("wallet_coins", 0))


func add_coins(amount: int) -> void:
	_data["total_coins"] = get_total_coins() + amount
	_data["wallet_coins"] = get_wallet_coins() + amount
	_mark_dirty()


func spend_wallet_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if get_wallet_coins() < amount:
		return false
	_data["wallet_coins"] = get_wallet_coins() - amount
	_mark_dirty()
	return true


# --- Menu Flow Data ---

func get_player_name() -> String:
	return str(_data.get("player_name", MenuFlowCatalog.DEFAULT_PLAYER_NAME))


func set_player_name(value: String) -> void:
	_data["player_name"] = value.strip_edges()
	_mark_dirty()


func get_selected_difficulty() -> String:
	return str(_data.get("selected_difficulty", MenuFlowCatalog.DEFAULT_DIFFICULTY))


func set_selected_difficulty(value: String) -> void:
	_data["selected_difficulty"] = value
	_mark_dirty()


func get_selected_runner_id() -> String:
	return str(_data.get("selected_runner_id", "elf"))


func set_selected_runner_id(value: String) -> void:
	_data["selected_runner_id"] = value
	_mark_dirty()


func get_unlocked_runners() -> Array[String]:
	var stored: Variant = _data.get("unlocked_runners", MenuFlowCatalog.DEFAULT_UNLOCKED_RUNNERS.duplicate())
	var unlocked: Array[String] = []
	if stored is Array:
		for runner_id in stored:
			unlocked.append(str(runner_id))
	return unlocked


func is_runner_unlocked(runner_id: String) -> bool:
	return get_unlocked_runners().has(runner_id)


func unlock_runner(runner_id: String) -> void:
	var unlocked := get_unlocked_runners()
	if unlocked.has(runner_id):
		return
	unlocked.append(runner_id)
	_data["unlocked_runners"] = unlocked
	_mark_dirty()


func get_leaderboard_entries() -> Array[Dictionary]:
	var stored: Variant = _data.get("leaderboard", [])
	var entries: Array[Dictionary] = []
	if stored is Array:
		for entry in stored:
			if entry is Dictionary:
				entries.append((entry as Dictionary).duplicate(true))
	return entries


func add_leaderboard_entry(entry: Dictionary) -> void:
	var entries := get_leaderboard_entries()
	entries.append(entry.duplicate(true))
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var distance_a: int = int(a.get("distance", 0))
		var distance_b: int = int(b.get("distance", 0))
		if distance_a == distance_b:
			return int(a.get("coins", 0)) > int(b.get("coins", 0))
		return distance_a > distance_b
	)
	if entries.size() > MenuFlowCatalog.LEADERBOARD_LIMIT:
		entries.resize(MenuFlowCatalog.LEADERBOARD_LIMIT)
	_data["leaderboard"] = entries
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
			"wallet_coins": 0,
			"player_name": MenuFlowCatalog.DEFAULT_PLAYER_NAME,
			"selected_difficulty": MenuFlowCatalog.DEFAULT_DIFFICULTY,
			"selected_runner_id": "elf",
			"leaderboard": [],
			"unlocked_runners": MenuFlowCatalog.DEFAULT_UNLOCKED_RUNNERS.duplicate(),
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

	_ensure_defaults()


func _ensure_defaults() -> void:
	if not _data.has("high_score"):
		_data["high_score"] = 0
	if not _data.has("total_coins"):
		_data["total_coins"] = 0
	if not _data.has("wallet_coins"):
		_data["wallet_coins"] = get_total_coins()
	if not _data.has("player_name"):
		_data["player_name"] = MenuFlowCatalog.DEFAULT_PLAYER_NAME
	if not _data.has("selected_difficulty"):
		_data["selected_difficulty"] = MenuFlowCatalog.DEFAULT_DIFFICULTY
	if not _data.has("selected_runner_id"):
		_data["selected_runner_id"] = "elf"
	if not _data.has("leaderboard"):
		_data["leaderboard"] = []
	if not _data.has("unlocked_runners"):
		_data["unlocked_runners"] = MenuFlowCatalog.DEFAULT_UNLOCKED_RUNNERS.duplicate()
	if not _data.has("settings"):
		_data["settings"] = {
			"music_enabled": true,
			"sfx_enabled": true,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
		}

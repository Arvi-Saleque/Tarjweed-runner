extends RefCounted
class_name ControlsManager

const SETTINGS_KEY: String = "control_bindings"

const ACTION_ORDER: Array[String] = [
	"move_left",
	"move_right",
	"jump",
	"slide",
	"blast",
	"bridge",
	"pause",
]

static var ACTION_CONFIG: Dictionary = {
	"move_left": {
		"label": "MOVE LEFT",
		"hint": "Shift one lane left",
		"defaults": [65, 4194319],
	},
	"move_right": {
		"label": "MOVE RIGHT",
		"hint": "Shift one lane right",
		"defaults": [68, 4194321],
	},
	"jump": {
		"label": "JUMP",
		"hint": "Leap over hazards",
		"defaults": [32, 4194320],
	},
	"slide": {
		"label": "SLIDE",
		"hint": "Duck under obstacles",
		"defaults": [83, 4194322],
	},
	"blast": {
		"label": "BLAST",
		"hint": "Double tap to fire",
		"defaults": [70],
	},
	"bridge": {
		"label": "BRIDGE",
		"hint": "Hold to build",
		"defaults": [69],
	},
	"pause": {
		"label": "PAUSE",
		"hint": "Pause or resume gameplay",
		"defaults": [4194305],
	},
}

static func ensure_controls_ready() -> void:
	for action in ACTION_ORDER:
		if not InputMap.has_action(action):
			InputMap.add_action(action)

	var stored_bindings: Dictionary = _get_saved_bindings()
	for action in ACTION_ORDER:
		_clear_key_events(action)
		var default_keys: Array = ACTION_CONFIG.get(action, {}).get("defaults", [])
		if stored_bindings.has(action):
			InputMap.action_add_event(action, _make_key_event(int(stored_bindings[action])))
		else:
			for keycode in default_keys:
				InputMap.action_add_event(action, _make_key_event(int(keycode)))

static func get_actions() -> Array[Dictionary]:
	ensure_controls_ready()
	var result: Array[Dictionary] = []
	for action in ACTION_ORDER:
		var config: Dictionary = ACTION_CONFIG.get(action, {})
		result.append({
			"action": action,
			"label": String(config.get("label", action.to_upper())),
			"hint": String(config.get("hint", "")),
		})
	return result


static func get_binding_display(action: String) -> String:
	ensure_controls_ready()
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var keycode: int = _extract_keycode(key_event)
			if keycode != 0:
				return OS.get_keycode_string(keycode).to_upper()
	return "UNBOUND"


static func set_binding(action: String, keycode: int) -> void:
	ensure_controls_ready()
	if not ACTION_ORDER.has(action) or keycode == 0:
		return

	for managed_action in ACTION_ORDER:
		_remove_key_from_action(managed_action, keycode)

	_clear_key_events(action)
	InputMap.action_add_event(action, _make_key_event(keycode))
	_save_current_bindings()
	SaveManager.save_now()


static func reset_to_defaults() -> void:
	SaveManager.set_setting(SETTINGS_KEY, {})
	SaveManager.save_now()
	ensure_controls_ready()


static func _get_saved_bindings() -> Dictionary:
	var stored: Variant = SaveManager.get_setting(SETTINGS_KEY, {})
	if stored is Dictionary:
		var result: Dictionary = {}
		for action in ACTION_ORDER:
			if stored.has(action):
				result[action] = int(stored[action])
		return result
	return {}


static func _save_current_bindings() -> void:
	var bindings: Dictionary = {}
	for action in ACTION_ORDER:
		var keycode: int = _get_primary_keycode(action)
		if keycode != 0:
			bindings[action] = keycode
	SaveManager.set_setting(SETTINGS_KEY, bindings)


static func _get_primary_keycode(action: String) -> int:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			return _extract_keycode(event as InputEventKey)
	return 0


static func _clear_key_events(action: String) -> void:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)


static func _remove_key_from_action(action: String, keycode: int) -> void:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	for event in events:
		if event is InputEventKey and _extract_keycode(event as InputEventKey) == keycode:
			InputMap.action_erase_event(action, event)


static func _make_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


static func _extract_keycode(event: InputEventKey) -> int:
	if int(event.physical_keycode) != 0:
		return int(event.physical_keycode)
	return int(event.keycode)

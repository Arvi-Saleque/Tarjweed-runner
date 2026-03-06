extends RefCounted
## CoinPattern — Static utility for spawning coins in various patterns.
## Creates coins using the coin.gd script with real GLB models.

enum Pattern { LINE, ARC, ZIGZAG, CLUSTER, RAMP }

const COIN_SCRIPT: String = "res://scripts/collectibles/coin.gd"
const COIN_HEIGHT: float = 0.8
const COIN_SPACING: float = 2.0


static func spawn_pattern(parent: Node3D, pattern: Pattern, start_pos: Vector3,
		lane_idx: int, generator: Node3D) -> void:
	match pattern:
		Pattern.LINE:
			_spawn_line(parent, start_pos, lane_idx, generator)
		Pattern.ARC:
			_spawn_arc(parent, start_pos, lane_idx, generator)
		Pattern.ZIGZAG:
			_spawn_zigzag(parent, start_pos, lane_idx, generator)
		Pattern.CLUSTER:
			_spawn_cluster(parent, start_pos, lane_idx, generator)
		Pattern.RAMP:
			_spawn_ramp(parent, start_pos, lane_idx, generator)


static func pick_random_pattern(difficulty: float) -> Pattern:
	var roll: float = randf()
	# More complex patterns appear at higher difficulty
	if difficulty > 1.8 and roll < 0.15:
		return Pattern.RAMP
	if difficulty > 1.5 and roll < 0.3:
		return Pattern.ZIGZAG
	if difficulty > 1.2 and roll < 0.45:
		return Pattern.ARC
	if roll < 0.15:
		return Pattern.CLUSTER
	return Pattern.LINE


# --- Pattern Implementations ---

static func _spawn_line(parent: Node3D, start: Vector3, lane_idx: int, gen: Node3D) -> void:
	## Straight line of coins in one lane
	var count: int = randi_range(4, 7)
	var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
	for i in count:
		var pos := Vector3(lane_x, COIN_HEIGHT, start.z - i * COIN_SPACING)
		_create_coin(parent, pos, "gold", gen)


static func _spawn_arc(parent: Node3D, start: Vector3, lane_idx: int, gen: Node3D) -> void:
	## Arc of coins — rise up then come down
	var count: int = randi_range(5, 7)
	var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
	var arc_peak: float = 2.5  # Peak height above base

	for i in count:
		var t: float = float(i) / float(count - 1) if count > 1 else 0.0
		var height: float = COIN_HEIGHT + sin(t * PI) * arc_peak
		var pos := Vector3(lane_x, height, start.z - i * COIN_SPACING)
		_create_coin(parent, pos, "gold", gen)


static func _spawn_zigzag(parent: Node3D, start: Vector3, lane_idx: int, gen: Node3D) -> void:
	## Zigzag across lanes — coins alternate between adjacent lanes
	var count: int = randi_range(4, 6)
	var other_lane: int = clampi(lane_idx + 1, 0, 2) if lane_idx < 2 else lane_idx - 1

	for i in count:
		var use_lane: int = lane_idx if i % 2 == 0 else other_lane
		var lane_x: float = GameManager.LANE_POSITIONS[use_lane]
		var pos := Vector3(lane_x, COIN_HEIGHT, start.z - i * COIN_SPACING)
		_create_coin(parent, pos, "gold", gen)


static func _spawn_cluster(parent: Node3D, start: Vector3, lane_idx: int, gen: Node3D) -> void:
	## Tight cluster of coins — mix of gold and silver
	var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
	var positions: Array[Vector3] = [
		Vector3(lane_x, COIN_HEIGHT, start.z),
		Vector3(lane_x - 0.5, COIN_HEIGHT, start.z - 1.2),
		Vector3(lane_x + 0.5, COIN_HEIGHT, start.z - 1.2),
		Vector3(lane_x, COIN_HEIGHT + 0.5, start.z - 1.2),
		Vector3(lane_x, COIN_HEIGHT, start.z - 2.4),
	]

	for i in positions.size():
		var type: String = "gold" if i == 3 else "silver"  # Center-top coin is gold
		_create_coin(parent, positions[i], type, gen)


static func _spawn_ramp(parent: Node3D, start: Vector3, lane_idx: int, gen: Node3D) -> void:
	## Ascending line — good for jump paths
	var count: int = randi_range(4, 6)
	var lane_x: float = GameManager.LANE_POSITIONS[lane_idx]
	var height_step: float = 0.5

	for i in count:
		var pos := Vector3(lane_x, COIN_HEIGHT + i * height_step, start.z - i * COIN_SPACING)
		_create_coin(parent, pos, "gold" if i >= count - 1 else "silver", gen)


# --- Coin Creation ---

static func _create_coin(parent: Node3D, pos: Vector3, type: String, gen: Node3D) -> void:
	var coin_script: GDScript = load(COIN_SCRIPT) as GDScript
	if not coin_script:
		return

	var coin := Area3D.new()
	coin.set_script(coin_script)
	coin.position = pos
	coin.name = "Coin"
	parent.add_child(coin)

	# Get the appropriate coin model from generator
	var model_scene: PackedScene = null
	if gen and gen.has_method("get_coin_scene"):
		model_scene = gen.get_coin_scene(type)

	coin.call("setup", model_scene, type)

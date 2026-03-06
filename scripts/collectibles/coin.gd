extends Area3D
## Coin — Collectible coin with spin/bob animation and pickup effect.
## Uses real GLB coin models (gold/silver/bronze).

const SPIN_SPEED: float = 3.0       # Radians per second
const BOB_SPEED: float = 2.5        # Bob frequency
const BOB_HEIGHT: float = 0.15      # Bob amplitude
const MAGNET_RANGE: float = 2.0     # Auto-collect distance
const MAGNET_SPEED: float = 12.0    # Pull speed when magnetized

var coin_type: String = "gold"
var _model: Node3D = null
var _base_y: float = 0.0
var _time: float = 0.0
var _collected: bool = false
var _magnetized: bool = false
var _player_ref: Node3D = null


func setup(model_scene: PackedScene, type: String = "gold") -> void:
	coin_type = type
	collision_layer = 8  # Collectibles layer (layer 4)
	collision_mask = 0
	add_to_group("coins")
	set_meta("coin_type", coin_type)

	# Instance the GLB model
	if model_scene:
		_model = model_scene.instantiate()
		add_child(_model)
	else:
		_create_placeholder()

	# Collision shape
	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	col.shape = sphere
	add_child(col)

	_base_y = position.y
	_time = randf() * TAU  # Random phase offset


func _create_placeholder() -> void:
	_model = Node3D.new()
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.25
	cyl.height = 0.08
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1, 1.0)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.1, 1.0)
	mat.emission_energy_multiplier = 0.3
	cyl.material = mat
	mesh_inst.mesh = cyl
	mesh_inst.rotation.x = deg_to_rad(90)
	_model.add_child(mesh_inst)
	add_child(_model)


func _process(delta: float) -> void:
	if _collected:
		return

	_time += delta

	# Spin
	if _model:
		_model.rotation.y += SPIN_SPEED * delta

	# Bob
	position.y = _base_y + sin(_time * BOB_SPEED) * BOB_HEIGHT

	# Magnet pull toward player
	if _magnetized and _player_ref and is_instance_valid(_player_ref):
		var dir: Vector3 = (_player_ref.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
		global_position += dir * MAGNET_SPEED * delta
		if global_position.distance_to(_player_ref.global_position + Vector3(0, 0.8, 0)) < 0.3:
			collect()
		return

	# Check distance to player for magnet
	if not _player_ref:
		var players := get_tree().get_nodes_in_group("player") if is_inside_tree() else []
		if players.size() > 0:
			_player_ref = players[0]

	if _player_ref and is_instance_valid(_player_ref):
		var dist: float = global_position.distance_to(_player_ref.global_position + Vector3(0, 0.8, 0))
		if dist < MAGNET_RANGE:
			_magnetized = true


func collect() -> void:
	if _collected:
		return
	_collected = true

	GameManager.collect_coin(coin_type)
	AudioManager.play_coin_sound()

	# Spawn particle burst VFX
	var CoinVFXScript: GDScript = load("res://scripts/vfx/coin_vfx.gd")
	if CoinVFXScript:
		var vfx := Node3D.new()
		vfx.set_script(CoinVFXScript)
		get_parent().add_child(vfx)
		vfx.global_position = global_position
		vfx._emit()

	# Pickup animation — scale down and fade
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", position.y + 1.0, 0.2)
	tween.chain().tween_callback(queue_free)

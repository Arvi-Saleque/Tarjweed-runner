extends Area3D
## GiantRock — A massive rock blocking ALL 3 lanes.
## Player must double-tap spacebar to trigger a sonic blast and destroy it.
## If player reaches the rock without blasting, they die.

signal rock_destroyed

enum RockState { INTACT, EXPLODING, DESTROYED }

const DETECTION_RANGE: float = 35.0  # How far ahead player can see/target the rock
const BLAST_RANGE: float = 25.0       # Must be within this range for blast to work
const ROCK_WIDTH: float = 7.0         # Spans all 3 lanes
const ROCK_HEIGHT: float = 3.5        # Tall enough to block everything
const NATURE_ROCK_DIFFUSE_PATH: String = "res://assets/Obstacles/GiantRock/textures/namaqualand_boulder_02/diffuse.jpg"
const NATURE_ROCK_NORMAL_PATH: String = "res://assets/Obstacles/GiantRock/textures/namaqualand_boulder_02/normal_gl.exr"
const NATURE_ROCK_ROUGHNESS_PATH: String = "res://assets/Obstacles/GiantRock/textures/namaqualand_boulder_02/roughness.exr"

var state: RockState = RockState.INTACT
var _model: Node3D = null
var _hint_root: Node3D = null
var _hint_icon: Sprite3D = null
var _shake_timer: float = 0.0
var _original_positions: Array[Vector3] = []
var _debris_nodes: Array[Node3D] = []
static var _cached_nature_rock_material: StandardMaterial3D = null


func setup(model_scene: PackedScene) -> void:
	collision_layer = 4  # Obstacles layer
	collision_mask = 0
	add_to_group("obstacles")
	add_to_group("giant_rocks")

	if model_scene:
		_model = model_scene.instantiate()
		add_child(_model)
		# Scale up to be imposing — fill all lanes
		var model_scale := Vector3(3.5, 3.0, 3.0)
		if model_scene.resource_path.contains("BlastRocks/Rocks.glb"):
			_recenter_blast_rocks_model(_model)
			model_scale = Vector3(2.35, 2.35, 2.35)
			_model.position = Vector3(0.0, 0.12, 0.0)
		_model.scale = model_scale
		if not GameManager.is_cyberprank_theme() and not model_scene.resource_path.contains("BlastRocks/Rocks.glb"):
			_apply_nature_rock_material(_model)

	# Create wide collision spanning all 3 lanes
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ROCK_WIDTH, ROCK_HEIGHT, 1.5)
	col.shape = box
	col.position.y = ROCK_HEIGHT / 2.0
	col.name = "RockCollision"
	add_child(col)

	_create_hint_label()


func _process(delta: float) -> void:
	match state:
		RockState.EXPLODING:
			_shake_timer += delta
			if _shake_timer > 1.5:
				_finish_destroy()

		RockState.DESTROYED:
			pass


func trigger_blast() -> void:
	## Called when player fires blast — instantly destroys the rock with VFX.
	if state != RockState.INTACT:
		return
	state = RockState.EXPLODING
	_shake_timer = 0.0

	# Remove collision immediately so player passes through
	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	remove_from_group("obstacles")

	# Hide hint
	if _hint_root:
		_hint_root.visible = false

	# Spawn explosion VFX
	_spawn_blast_effect()

	# Scatter debris
	_explode_model()

	# Camera shake via player's camera rig
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var camera_rig = players[0].get_node_or_null("CameraRig")
		if camera_rig and camera_rig.has_method("shake"):
			camera_rig.shake(0.5, 3.0)

	# Award bonus coins for destroying rock
	GameManager.collect_coin("gold")

	rock_destroyed.emit()


func _explode_model() -> void:
	## Break the rock into flying debris chunks
	if not _model:
		return

	# Hide original model
	_model.visible = false

	# Create debris pieces flying outward
	var debris_count: int = 12
	for i in debris_count:
		var debris := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		var size := randf_range(0.2, 0.6)
		box_mesh.size = Vector3(size, size, size)

		var mat := StandardMaterial3D.new()
		if GameManager.is_cyberprank_theme():
			mat.albedo_color = Color(0.10, 0.18, 0.24).lerp(Color(0.72, 0.26, 1.0), randf() * 0.45)
			mat.roughness = 0.24
			mat.metallic = 0.55
			mat.emission_enabled = true
			mat.emission = Color(0.14, 0.86, 1.0)
			mat.emission_energy_multiplier = 1.2
		else:
			var nature_material := _get_nature_rock_material()
			if nature_material != null:
				mat = nature_material.duplicate() as StandardMaterial3D
				mat.albedo_color = mat.albedo_color.darkened(randf_range(0.0, 0.12))
			else:
				mat.albedo_color = Color(0.5, 0.45, 0.4).lerp(Color(0.35, 0.3, 0.25), randf())
				mat.roughness = 0.9
		box_mesh.material = mat

		debris.mesh = box_mesh
		debris.position = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(0.5, 2.5),
			randf_range(-0.5, 0.5)
		)
		add_child(debris)
		_debris_nodes.append(debris)

		# Animate debris flying outward
		var tween := create_tween()
		var target_pos := debris.position + Vector3(
			randf_range(-6.0, 6.0),
			randf_range(3.0, 8.0),
			randf_range(-4.0, 4.0)
		)
		var end_pos := target_pos + Vector3(0, -10.0, 0)  # Fall down

		tween.tween_property(debris, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(debris, "position", end_pos, 0.8).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(debris, "rotation", Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5)), 1.2)
		tween.tween_callback(debris.queue_free)


func _spawn_blast_effect() -> void:
	## Create the sonic blast shockwave VFX
	var blast_script: GDScript = load("res://scripts/obstacles/sonic_blast.gd") as GDScript
	if not blast_script:
		return

	var blast := Node3D.new()
	blast.set_script(blast_script)
	blast.position = Vector3(0, 1.5, 0)
	add_child(blast)
	blast.call("start")


func _finish_destroy() -> void:
	state = RockState.DESTROYED
	# Clean up any remaining debris
	for d in _debris_nodes:
		if is_instance_valid(d):
			d.queue_free()
	_debris_nodes.clear()


func _create_hint_label() -> void:
	if _hint_root:
		return

	_hint_root = Node3D.new()
	_hint_root.name = "HintRoot"
	_hint_root.position = Vector3(0.0, ROCK_HEIGHT + 0.9, 0.0)
	_hint_root.visible = false
	add_child(_hint_root)

	_hint_icon = Sprite3D.new()
	_hint_icon.name = "HintIcon"
	_hint_icon.texture = load("res://assets/UI/kenney_input_prompts/touch_tap_double.png") as Texture2D
	_hint_icon.pixel_size = 0.006
	_hint_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint_icon.modulate = Color(0.18, 0.92, 1.0, 0.98) if GameManager.is_cyberprank_theme() else Color(1.0, 0.96, 0.86, 0.95)
	_hint_root.add_child(_hint_icon)


func show_hint() -> void:
	if _hint_root == null:
		_create_hint_label()
	if _hint_root:
		_hint_root.visible = true


func hide_hint() -> void:
	if _hint_root:
		_hint_root.visible = false


func _apply_nature_rock_material(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for surface_idx in mi.mesh.get_surface_count():
				var textured_material := _get_nature_rock_material()
				if textured_material != null:
					mi.set_surface_override_material(surface_idx, textured_material)

	for child in node.get_children():
		_apply_nature_rock_material(child)


func _get_nature_rock_material() -> StandardMaterial3D:
	if _cached_nature_rock_material != null:
		return _cached_nature_rock_material
	if not ResourceLoader.exists(NATURE_ROCK_DIFFUSE_PATH):
		return null

	var material := StandardMaterial3D.new()
	material.albedo_texture = load(NATURE_ROCK_DIFFUSE_PATH) as Texture2D
	material.albedo_color = Color(0.92, 0.90, 0.86, 1.0)
	material.roughness = 0.88
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	if ResourceLoader.exists(NATURE_ROCK_NORMAL_PATH):
		material.normal_enabled = true
		material.normal_texture = load(NATURE_ROCK_NORMAL_PATH) as Texture2D
		material.normal_scale = 1.05

	if ResourceLoader.exists(NATURE_ROCK_ROUGHNESS_PATH):
		material.roughness_texture = load(NATURE_ROCK_ROUGHNESS_PATH) as Texture2D

	_cached_nature_rock_material = material
	return _cached_nature_rock_material


func _recenter_blast_rocks_model(root: Node3D) -> void:
	var parts: Array[Node3D] = []
	var x_sum: float = 0.0
	for child in root.get_children():
		if child is Node3D:
			parts.append(child)
			x_sum += (child as Node3D).position.x

	if parts.is_empty():
		return

	var x_center: float = x_sum / float(parts.size())
	for part in parts:
		part.position.x -= x_center


func _apply_glow_tint(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := StandardMaterial3D.new()
			mat.albedo_color = color
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.5, 0.1)
			mat.emission_energy_multiplier = 2.0
			mat.roughness = 0.5
			mi.set_surface_override_material(i, mat)
	for child in node.get_children():
		_apply_glow_tint(child, color)

extends Area3D
## GiantRock — A massive rock blocking ALL 3 lanes.
## Player must double-tap spacebar to trigger a sonic blast and destroy it.
## If player reaches the rock without blasting, they die.

signal rock_destroyed

enum RockState { INTACT, EXPLODING, DESTROYED }

const DETECTION_RANGE: float = 35.0  # How far ahead player can see/target the rock
const BLAST_RANGE: float = 25.0      # Must be within this range for blast to work
const ROCK_WIDTH: float = 7.0        # Spans all 3 lanes
const ROCK_HEIGHT: float = 3.5       # Tall enough to block everything
const ROCK_COLLISION_DEPTH: float = 2.35
const ROCK_COLLISION_FORWARD_OFFSET: float = 0.34
const NATURE_ROCK_DIFFUSE_PATH: String = "res://assets/Obstacles/GiantRock/textures/namaqualand_boulder_02/diffuse.jpg"
const NATURE_ROCK_NORMAL_PATH: String = "res://assets/Obstacles/GiantRock/textures/namaqualand_boulder_02/normal_gl.exr"
const NATURE_ROCK_ROUGHNESS_PATH: String = "res://assets/Obstacles/GiantRock/textures/namaqualand_boulder_02/roughness.exr"
const NATURE_WOOD_DIFFUSE_PATH: String = "res://assets/world/quaternius_nature/Bark_NormalTree.png"
const NATURE_WOOD_NORMAL_PATH: String = "res://assets/world/quaternius_nature/Bark_NormalTree_Normal.png"

var state: RockState = RockState.INTACT
var _model: Node3D = null
var _hint_root: Node3D = null
var _hint_icon: Sprite3D = null
var _shake_timer: float = 0.0
var _debris_nodes: Array[Node3D] = []
static var _cached_nature_rock_material: StandardMaterial3D = null
static var _cached_nature_wood_material: StandardMaterial3D = null


func setup(model_scene: PackedScene) -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("obstacles")
	add_to_group("giant_rocks")

	if not GameManager.is_cyberprank_theme():
		_model = _build_nature_blast_barricade()
		add_child(_model)
	elif model_scene:
		_model = model_scene.instantiate()
		add_child(_model)
		_model.scale = Vector3(3.5, 3.0, 3.0)
		_model.position = Vector3(0.0, 0.0, -0.38)

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ROCK_WIDTH, ROCK_HEIGHT, ROCK_COLLISION_DEPTH)
	col.shape = box
	col.position = Vector3(0.0, ROCK_HEIGHT / 2.0, ROCK_COLLISION_FORWARD_OFFSET)
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
	if state != RockState.INTACT:
		return

	state = RockState.EXPLODING
	_shake_timer = 0.0

	for child in get_children():
		if child is CollisionShape3D:
			child.set_deferred("disabled", true)
	remove_from_group("obstacles")

	if _hint_root:
		_hint_root.visible = false

	_spawn_blast_effect()
	_explode_model()

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var camera_rig := players[0].get_node_or_null("CameraRig")
		if camera_rig and camera_rig.has_method("shake"):
			camera_rig.shake(0.5, 3.0)

	GameManager.collect_coin("gold")
	rock_destroyed.emit()


func _explode_model() -> void:
	if not _model:
		return

	_model.visible = false

	for i in 12:
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

		var tween := create_tween()
		var target_pos := debris.position + Vector3(
			randf_range(-6.0, 6.0),
			randf_range(3.0, 8.0),
			randf_range(-4.0, 4.0)
		)
		var end_pos := target_pos + Vector3(0, -10.0, 0)

		tween.tween_property(debris, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(debris, "position", end_pos, 0.8).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(
			debris,
			"rotation",
			Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5)),
			1.2
		)
		tween.tween_callback(debris.queue_free)


func _spawn_blast_effect() -> void:
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


func _build_nature_blast_barricade() -> Node3D:
	var barricade := Node3D.new()
	barricade.name = "NatureBlastBarricade"
	barricade.position = Vector3(0.0, 0.02, -0.20)

	var beam_material := _get_nature_wood_material()
	var post_material := _get_nature_wood_material()
	var packed_fill := _get_nature_rock_material()

	_add_barricade_piece(barricade, Vector3(0.0, 0.26, 0.22), Vector3(6.9, 0.44, 0.40), beam_material)
	_add_barricade_piece(barricade, Vector3(-2.18, 0.78, 0.08), Vector3(0.22, 1.02, 0.22), post_material)
	_add_barricade_piece(barricade, Vector3(0.0, 0.88, 0.08), Vector3(0.24, 1.22, 0.24), post_material)
	_add_barricade_piece(barricade, Vector3(2.18, 0.78, 0.08), Vector3(0.22, 1.02, 0.22), post_material)

	_add_barricade_piece(barricade, Vector3(0.0, 1.66, 0.0), Vector3(2.16, 2.34, 0.82), packed_fill)
	_add_barricade_piece(barricade, Vector3(-2.22, 0.92, 0.0), Vector3(1.80, 1.08, 0.82), packed_fill)
	_add_barricade_piece(barricade, Vector3(2.22, 0.92, 0.0), Vector3(1.80, 1.08, 0.82), packed_fill)
	_add_barricade_piece(barricade, Vector3(-1.06, 0.98, 0.10), Vector3(0.72, 0.90, 0.54), packed_fill)
	_add_barricade_piece(barricade, Vector3(1.06, 0.98, 0.10), Vector3(0.72, 0.90, 0.54), packed_fill)

	return barricade


func _add_barricade_piece(parent: Node3D, pos: Vector3, size: Vector3, material: StandardMaterial3D) -> void:
	var piece := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	piece.mesh = mesh
	piece.position = pos
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if material != null:
		var applied := material.duplicate() as StandardMaterial3D
		applied.uv1_scale = Vector3(1.0, 1.0, 1.0)
		piece.material_override = applied
	parent.add_child(piece)


func _get_nature_wood_material() -> StandardMaterial3D:
	if _cached_nature_wood_material != null:
		return _cached_nature_wood_material

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.50, 0.34, 0.20, 1.0)
	material.roughness = 0.95
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

	if ResourceLoader.exists(NATURE_WOOD_DIFFUSE_PATH):
		material.albedo_texture = load(NATURE_WOOD_DIFFUSE_PATH) as Texture2D
	if ResourceLoader.exists(NATURE_WOOD_NORMAL_PATH):
		material.normal_enabled = true
		material.normal_texture = load(NATURE_WOOD_NORMAL_PATH) as Texture2D
		material.normal_scale = 0.8

	_cached_nature_wood_material = material
	return _cached_nature_wood_material


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

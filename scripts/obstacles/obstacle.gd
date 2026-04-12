extends Area3D
## Obstacle — Base behavior for all obstacle types.
## Handles collision shape auto-sizing from mesh and visual feedback.

enum ObstacleType { GROUND, LOW, TALL }

var obstacle_type: ObstacleType = ObstacleType.GROUND
var _model: Node3D = null


func setup(model_scene: PackedScene, obs_type: ObstacleType = ObstacleType.GROUND) -> void:
	obstacle_type = obs_type
	collision_layer = 4  # Obstacles layer (layer 3)
	collision_mask = 0
	add_to_group("obstacles")

	# Instance the GLB model
	if model_scene:
		_model = model_scene.instantiate()
		add_child(_model)
		if not GameManager.is_cyberprank_theme():
			_apply_nature_contrast_tint(_model)

	# Create collision from model bounds
	_auto_collision()


func setup_overhead(model_scene: PackedScene) -> void:
	## Setup an overhead obstacle the player must slide under.
	## Model is elevated so its bottom sits above slide height (~0.9m).
	obstacle_type = ObstacleType.LOW
	collision_layer = 4
	collision_mask = 0
	add_to_group("obstacles")

	if model_scene:
		_model = model_scene.instantiate()
		add_child(_model)
		if not GameManager.is_cyberprank_theme():
			_apply_nature_contrast_tint(_model)

	# Get model AABB to know its size
	var aabb := _compute_aabb()
	var model_height: float = aabb.size.y if aabb.size.y > 0.1 else 0.5

	# Position model so its bottom edge is at OVERHEAD_Y
	var overhead_y: float = 0.9
	var model_bottom: float = aabb.position.y  # local-space bottom of model
	if _model:
		_model.position.y = overhead_y - model_bottom

	# Scale the model wider to span the lane and look imposing
	if _model:
		_model.scale = Vector3(1.8, 1.4, 1.6)

	# Create collision that covers the overhead area
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Wide collision spanning the lane, from overhead_y upward
	var col_height: float = maxf(model_height * 1.4, 1.2)
	box.size = Vector3(1.4, col_height, 0.8)
	col.shape = box
	col.position.y = overhead_y + col_height / 2.0
	add_child(col)


func setup_placeholder(box_size: Vector3, material: StandardMaterial3D = null) -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("obstacles")

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	col.shape = box
	col.position.y = box_size.y / 2.0
	add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	if material:
		box_mesh.material = material
	mesh_inst.mesh = box_mesh
	mesh_inst.position.y = box_size.y / 2.0
	add_child(mesh_inst)


func _auto_collision() -> void:
	# Calculate AABB from all mesh children
	var aabb := AABB()
	var found_mesh := false

	for child in _get_all_children(self):
		if child is MeshInstance3D:
			var mesh_aabb: AABB = child.get_aabb()
			var child_transform: Transform3D = child.global_transform * self.global_transform.inverse()
			if not found_mesh:
				aabb = child_transform * mesh_aabb
				found_mesh = true
			else:
				aabb = aabb.merge(child_transform * mesh_aabb)

	if not found_mesh:
		# Fallback collision
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.8, 0.8, 0.8)
		col.shape = box
		col.position.y = 0.4
		add_child(col)
		return

	# Create box collision from AABB
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Slightly shrink collision for fair gameplay
	box.size = aabb.size * 0.85
	col.shape = box
	col.position = aabb.get_center()
	add_child(col)


func _compute_aabb() -> AABB:
	## Calculate combined AABB of all mesh children.
	var aabb := AABB()
	var found := false
	for child in _get_all_children(self):
		if child is MeshInstance3D:
			var mesh_aabb: AABB = child.get_aabb()
			if not found:
				aabb = mesh_aabb
				found = true
			else:
				aabb = aabb.merge(mesh_aabb)
	return aabb


func _apply_nature_contrast_tint(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface_idx in mesh_instance.mesh.get_surface_count():
				var source_material := mesh_instance.get_active_material(surface_idx)
				var tinted_material: StandardMaterial3D = null

				if source_material is StandardMaterial3D:
					var std_material := source_material as StandardMaterial3D
					if std_material.albedo_texture != null:
						continue
					tinted_material = std_material.duplicate() as StandardMaterial3D
				else:
					tinted_material = StandardMaterial3D.new()

				var base_color := Color(0.82, 0.82, 0.82, 1.0)
				if source_material is StandardMaterial3D:
					base_color = (source_material as StandardMaterial3D).albedo_color

				var darker_target := Color(0.24, 0.22, 0.20, 1.0)
				tinted_material.albedo_color = base_color.lerp(darker_target, 0.7)
				tinted_material.roughness = maxf(tinted_material.roughness, 0.88)
				tinted_material.metallic = 0.0
				tinted_material.emission_enabled = false
				mesh_instance.set_surface_override_material(surface_idx, tinted_material)

	for child in node.get_children():
		_apply_nature_contrast_tint(child)


func _get_all_children(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

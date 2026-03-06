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

	# Create collision from model bounds
	_auto_collision()


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


func _get_all_children(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result

extends Node3D
## Simple side-by-side showroom for previewing shortlisted Nature theme runners.

const CHARACTER_SPECS: Array[Dictionary] = [
	{
		"label": "CASUAL MALE",
		"path": "res://nature-assets/Ultimate Animated Character Pack - Nov 2019-20260413T141612Z-3-001/Ultimate Animated Character Pack - Nov 2019/glTF/Casual_Male.gltf",
		"x": -8.0,
	},
	{
		"label": "CASUAL FEMALE",
		"path": "res://nature-assets/Ultimate Animated Character Pack - Nov 2019-20260413T141612Z-3-001/Ultimate Animated Character Pack - Nov 2019/glTF/Casual_Female.gltf",
		"x": -4.0,
	},
	{
		"label": "WORKER MALE",
		"path": "res://nature-assets/Ultimate Animated Character Pack - Nov 2019-20260413T141612Z-3-001/Ultimate Animated Character Pack - Nov 2019/glTF/Worker_Male.gltf",
		"x": 0.0,
	},
	{
		"label": "WORKER FEMALE",
		"path": "res://nature-assets/Ultimate Animated Character Pack - Nov 2019-20260413T141612Z-3-001/Ultimate Animated Character Pack - Nov 2019/glTF/Worker_Female.gltf",
		"x": 4.0,
	},
	{
		"label": "ELF",
		"path": "res://nature-assets/Ultimate Animated Character Pack - Nov 2019-20260413T141612Z-3-001/Ultimate Animated Character Pack - Nov 2019/glTF/Elf.gltf",
		"x": 8.0,
	},
]

@onready var roster_root: Node3D = $RosterRoot

var _spawned_characters: Array[Node3D] = []


func _ready() -> void:
	_spawn_characters()


func _process(delta: float) -> void:
	for model in _spawned_characters:
		if is_instance_valid(model):
			model.rotation.y += delta * 0.35


func _spawn_characters() -> void:
	for spec in CHARACTER_SPECS:
		var scene_path: String = spec.get("path", "")
		if not ResourceLoader.exists(scene_path):
			push_warning("Nature showroom missing resource: %s" % scene_path)
			continue

		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			push_warning("Nature showroom failed to load: %s" % scene_path)
			continue

		var holder := Node3D.new()
		holder.name = spec.get("label", "Character").capitalize().replace(" ", "")
		holder.position = Vector3(float(spec.get("x", 0.0)), 0.0, 0.0)
		roster_root.add_child(holder)

		var instance := packed_scene.instantiate() as Node3D
		if instance == null:
			push_warning("Nature showroom scene is not Node3D: %s" % scene_path)
			holder.queue_free()
			continue

		instance.rotation.y = PI
		holder.add_child(instance)
		_spawned_characters.append(instance)

		var pedestal := MeshInstance3D.new()
		var pedestal_mesh := CylinderMesh.new()
		pedestal_mesh.top_radius = 0.9
		pedestal_mesh.bottom_radius = 1.0
		pedestal_mesh.height = 0.12
		var pedestal_material := StandardMaterial3D.new()
		pedestal_material.albedo_color = Color(0.30, 0.24, 0.18, 1.0)
		pedestal_material.roughness = 0.92
		pedestal_mesh.material = pedestal_material
		pedestal.mesh = pedestal_mesh
		pedestal.position = Vector3(0.0, 0.06, 0.0)
		holder.add_child(pedestal)

		var label := Label3D.new()
		label.text = spec.get("label", "CHARACTER")
		label.position = Vector3(0.0, 2.5, 0.0)
		label.font_size = 28
		label.modulate = Color(0.95, 0.94, 0.88, 1.0)
		label.outline_modulate = Color(0.12, 0.10, 0.07, 1.0)
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		holder.add_child(label)

extends RefCounted
class_name ThemeRegistry
## ThemeRegistry - Centralized visual theme profiles for gameplay presentation.
## Gameplay mode stays in GameManager.current_mode; visuals come from current_visual_theme.

const CYBERPRANK_PLAYER_VARIANTS: Dictionary = {
	"character": {
		"id": "character",
		"title": "CHARACTER",
		"subtitle": "Sleek cyber runner",
		"color": Color(0.16, 0.86, 1.0),
		"icon_text": "CORE",
		"base_scene_path": "res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.44,
		"style": "cyber_mech",
		"preview_scale": 1.2,
		"preview_height": -0.9,
	},
	"george": {
		"id": "george",
		"title": "GEORGE",
		"subtitle": "Heavy neon mech",
		"color": Color(0.28, 0.96, 1.0),
		"icon_text": "GEO",
		"base_scene_path": "res://assets/Characters/cyberprank/mech_pack/George.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.42,
		"style": "cyber_mech",
		"preview_scale": 1.1,
		"preview_height": -0.95,
	},
	"leela": {
		"id": "leela",
		"title": "LEELA",
		"subtitle": "Agile mech frame",
		"color": Color(0.86, 0.34, 1.0),
		"icon_text": "LEE",
		"base_scene_path": "res://assets/Characters/cyberprank/mech_pack/Leela.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.42,
		"style": "cyber_mech",
		"preview_scale": 1.1,
		"preview_height": -0.95,
	},
	"mike": {
		"id": "mike",
		"title": "MIKE",
		"subtitle": "Compact mech striker",
		"color": Color(0.96, 0.72, 0.24),
		"icon_text": "MIK",
		"base_scene_path": "res://assets/Characters/cyberprank/mech_pack/Mike.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.42,
		"style": "cyber_mech",
		"preview_scale": 1.1,
		"preview_height": -0.95,
	},
	"stan": {
		"id": "stan",
		"title": "STAN",
		"subtitle": "Chunky armored bot",
		"color": Color(0.98, 0.44, 0.58),
		"icon_text": "STN",
		"base_scene_path": "res://assets/Characters/cyberprank/mech_pack/Stan.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.42,
		"style": "cyber_mech",
		"preview_scale": 1.1,
		"preview_height": -0.95,
	},
	"bee": {
		"id": "bee",
		"title": "BARBARA",
		"subtitle": "Space bee mech",
		"color": Color(0.94, 0.86, 0.22),
		"icon_text": "BEE",
		"base_scene_path": "res://assets/Characters/cyberprank/space_mechs/Mech_BarbaraTheBee.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.48,
		"style": "cyber_mech",
		"preview_scale": 1.05,
		"preview_height": -1.0,
	},
	"fernando": {
		"id": "fernando",
		"title": "FERNANDO",
		"subtitle": "Flamingo mech glide",
		"color": Color(1.0, 0.42, 0.72),
		"icon_text": "FER",
		"base_scene_path": "res://assets/Characters/cyberprank/space_mechs/Mech_FernandoTheFlamingo.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.48,
		"style": "cyber_mech",
		"preview_scale": 1.05,
		"preview_height": -1.0,
	},
	"finn": {
		"id": "finn",
		"title": "FINN",
		"subtitle": "Frog mech sprinter",
		"color": Color(0.34, 1.0, 0.72),
		"icon_text": "FIN",
		"base_scene_path": "res://assets/Characters/cyberprank/space_mechs/Mech_FinnTheFrog.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.48,
		"style": "cyber_mech",
		"preview_scale": 1.05,
		"preview_height": -1.0,
	},
	"rae": {
		"id": "rae",
		"title": "RAE",
		"subtitle": "Red panda mech ace",
		"color": Color(1.0, 0.54, 0.26),
		"icon_text": "RAE",
		"base_scene_path": "res://assets/Characters/cyberprank/space_mechs/Mech_RaeTheRedPanda.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.48,
		"style": "cyber_mech",
		"preview_scale": 1.05,
		"preview_height": -1.0,
	},
}

const NATURE_PROFILE: Dictionary = {
	"id": "nature",
	"road": {
		"ground": Color(0.60, 0.48, 0.31, 1.0),
		"ground_roughness": 0.96,
		"detail": Color(0.68, 0.55, 0.36, 1.0),
		"detail_roughness": 0.98,
		"patch": Color(0.42, 0.34, 0.24, 1.0),
		"patch_roughness": 1.0,
		"side": Color(0.31, 0.47, 0.24, 1.0),
		"side_roughness": 0.95,
		"edge": Color(0.33, 0.26, 0.18, 1.0),
		"edge_roughness": 0.90,
		"lane_marker": Color(0.73, 0.67, 0.50, 0.58),
		"lane_marker_emission": Color(0.0, 0.0, 0.0, 1.0),
		"lane_marker_emission_energy": 0.0,
	},
	"decorations": {
		"trees_large": [
			"res://assets/world/quaternius_nature/trees/CommonTree_2.gltf",
			"res://assets/world/quaternius_nature/trees/CommonTree_4.gltf",
		],
		"trees_pine": [
			"res://assets/world/quaternius_nature/trees/Pine_2.gltf",
			"res://assets/world/quaternius_nature/trees/Pine_4.gltf",
		],
		"bushes": [
			"res://assets/world/quaternius_nature/plants/Bush_Common.gltf",
			"res://assets/world/quaternius_nature/plants/Fern_1.gltf",
		],
		"flowers": [
			"res://assets/world/quaternius_nature/plants/Flower_4_Group.gltf",
		],
		"rocks": [
			"res://assets/world/quaternius_nature/rocks/Rock_Medium_1.gltf",
			"res://assets/world/quaternius_nature/rocks/Rock_Medium_2.gltf",
		],
		"rocks_small": [
			"res://assets/world/quaternius_nature/rocks/RockPath_Round_Small_2.gltf",
			"res://assets/world/quaternius_nature/rocks/RockPath_Round_Wide.gltf",
		],
		"grass": [
			"res://assets/world/quaternius_nature/plants/Grass_Common_Short.gltf",
			"res://assets/world/quaternius_nature/plants/Grass_Common_Tall.gltf",
		],
		"background": [
			"res://assets/world/quaternius_nature/background/DeadTree_3.gltf",
			"res://assets/world/quaternius_nature/background/TwistedTree_4.gltf",
		],
	},
	"obstacles": {
		"ground": [
			"res://assets/Obstacles/ExtraObstacleProps/barrel.glb",
			"res://assets/Obstacles/ExtraObstacleProps/crate.glb",
			"res://assets/Obstacles/ExtraObstacleProps/crate-strong.glb",
			"res://assets/Obstacles/ExtraObstacleProps/fence-broken.glb",
			"res://assets/Obstacles/ExtraObstacleProps/fence-low-broken.glb",
			"res://assets/Obstacles/ExtraObstacleProps/trap-spikes.glb",
			"res://assets/Obstacles/ExtraObstacleProps/trap-spikes-large.glb",
			"res://assets/Obstacles/ExtraObstacleProps/bomb.glb",
			"res://assets/Obstacles/ExtraObstacleProps/spike-block.glb",
			"res://assets/Obstacles/ExtraObstacleProps/spike-block-wide.glb",
			"res://assets/Obstacles/ExtraObstacleProps/rocks.glb",
			"res://assets/Obstacles/ExtraObstacleProps/stones.glb",
			"res://assets/Obstacles/ExtraObstacleProps/hedge.glb",
			"res://assets/Obstacles/ExtraObstacleProps/hedge-corner.glb",
			"res://assets/Obstacles/ExtraObstacleProps/cliff_block_stone.glb",
			"res://assets/Obstacles/ExtraObstacleProps/cliff_blockHalf_stone.glb",
			"res://assets/Obstacles/ExtraObstacleProps/cliff_blockQuarter_stone.glb",
			"res://assets/Obstacles/RocksSmall/cliff_blockHalf_rock.glb",
			"res://assets/Obstacles/RocksSmall/cliff_blockQuarter_rock.glb",
			"res://assets/Obstacles/RocksBig/cliff_block_rock.glb",
		],
		"overhead": [
			"res://assets/Obstacles/Overhead/fence-rope.glb",
			"res://assets/Obstacles/Overhead/pipe.glb",
			"res://assets/Obstacles/Overhead/poles.glb",
			"res://assets/Obstacles/Overhead/saw.glb",
			"res://assets/Obstacles/Overhead/log_large.glb",
			"res://assets/Obstacles/Overhead/fence_gate.glb",
		],
		"giant": [
			"res://assets/Obstacles/GiantRock/rock_tallA.glb",
			"res://assets/Obstacles/GiantRock/rock_tallB.glb",
			"res://assets/Obstacles/GiantRock/rock_tallC.glb",
			"res://assets/Obstacles/GiantRock/rock_largeA.glb",
		],
	},
	"player": {
		"base_scene_path": "res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		"extra_anim_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementAdvanced.glb",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_General.glb",
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_CombatMelee.glb",
		],
		"fallback_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_gradient",
	},
	"ui": {
		"skin": "nature",
	},
}

const CYBERPRANK_PROFILE: Dictionary = {
	"id": "cyberprank",
	"road": {
		"ground": Color(0.07, 0.09, 0.12, 1.0),
		"ground_roughness": 0.72,
		"detail": Color(0.10, 0.14, 0.18, 1.0),
		"detail_roughness": 0.58,
		"patch": Color(0.04, 0.29, 0.39, 1.0),
		"patch_roughness": 0.40,
		"side": Color(0.04, 0.06, 0.09, 1.0),
		"side_roughness": 0.78,
		"edge": Color(0.06, 0.11, 0.18, 1.0),
		"edge_roughness": 0.32,
		"edge_emission": Color(0.08, 0.78, 0.98, 1.0),
		"edge_emission_energy": 1.8,
		"lane_marker": Color(0.52, 0.95, 1.0, 0.78),
		"lane_marker_emission": Color(0.12, 0.84, 1.0, 1.0),
		"lane_marker_emission_energy": 2.5,
	},
	"decorations": {
		"trees_large": [
			"res://assets/world/cyberprank/space_kit/environment/Building_L.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Base_Large.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Long.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Single.gltf",
		],
		"trees_pine": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Light_Street_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Light_Street_2.gltf",
			"res://assets/world/cyberprank/space_kit/environment/MetalSupport.gltf",
			"res://assets/world/cyberprank/space_kit/environment/SolarPanel_Structure.gltf",
		],
		"bushes": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Computer.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Computer_Large.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/TV_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/TV_2.gltf",
		],
		"flowers": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_2.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_3.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_4.gltf",
		],
		"rocks": [
			"res://assets/world/cyberprank/space_kit/environment/Rock_Large_1.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Rock_Large_2.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Rock_Large_3.gltf",
		],
		"rocks_small": [
			"res://assets/world/cyberprank/space_kit/environment/Rock_1.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Rock_2.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Rock_3.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Rock_4.gltf",
		],
		"grass": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Pipe_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Pipe_2.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Rail_Short.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Support.gltf",
		],
		"background": [
			"res://assets/world/cyberprank/space_kit/environment/GeodesicDome.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Cylinder.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_OpenBack.gltf",
		],
	},
	"obstacles": {
		"ground": [
			"res://assets/world/cyberprank/space_kit/characters/Enemy_Small.gltf",
			"res://assets/world/cyberprank/space_kit/characters/Enemy_Large.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Computer_Large.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Fence.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_Corner_Hazard.gltf",
		],
		"overhead": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Pipe_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Pipe_2.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Rail_Long.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Support_Long.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Light_Street_2.gltf",
		],
		"giant": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Enemy_Large_Gun.gltf",
			"res://assets/Characters/cyberprank/cyberpunk_kit/Enemy_2Legs_Gun.gltf",
			"res://assets/Characters/cyberprank/mech_pack/George.gltf",
			"res://assets/Characters/cyberprank/mech_pack/Stan.gltf",
		],
	},
	"player": {
		"base_scene_path": "res://assets/Characters/cyberprank/cyberpunk_kit/Character.gltf",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.44,
		"style": "cyber_mech",
	},
	"ui": {
		"skin": "cyberprank",
	},
}


static func get_profile(theme_id: String = "") -> Dictionary:
	var resolved_theme: String = theme_id
	if resolved_theme.is_empty():
		resolved_theme = GameManager.current_visual_theme

	match resolved_theme:
		"cyberprank":
			var cyber_profile: Dictionary = CYBERPRANK_PROFILE.duplicate(true)
			cyber_profile["player"] = get_player_profile(resolved_theme)
			return cyber_profile
		_:
			return NATURE_PROFILE.duplicate(true)


static func get_player_profile(theme_id: String = "", variant_id: String = "") -> Dictionary:
	var resolved_theme: String = theme_id if not theme_id.is_empty() else GameManager.current_visual_theme
	if resolved_theme != "cyberprank":
		return NATURE_PROFILE.get("player", {}).duplicate(true)

	var resolved_variant: String = variant_id if not variant_id.is_empty() else GameManager.current_player_variant
	if resolved_variant.is_empty() or not CYBERPRANK_PLAYER_VARIANTS.has(resolved_variant):
		resolved_variant = "character"
	return CYBERPRANK_PLAYER_VARIANTS[resolved_variant].duplicate(true)


static func get_player_options(theme_id: String = "") -> Array[Dictionary]:
	var resolved_theme: String = theme_id if not theme_id.is_empty() else GameManager.current_visual_theme
	if resolved_theme != "cyberprank":
		return []

	var order: Array[String] = [
		"character", "george", "leela", "mike", "stan",
		"bee", "fernando", "finn", "rae",
	]
	var options: Array[Dictionary] = []
	for variant_id in order:
		if CYBERPRANK_PLAYER_VARIANTS.has(variant_id):
			options.append(CYBERPRANK_PLAYER_VARIANTS[variant_id].duplicate(true))
	return options

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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/character.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/george.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/leela.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/mike.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/stan.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/bee.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/fernando.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/finn.png",
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
		"preview_image_path": "res://assets/UI/cyberprank/runner_previews/rae.png",
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

const NATURE_PLAYER_VARIANTS: Dictionary = {
	"elf": {
		"id": "elf",
		"title": "ELF",
		"subtitle": "Forest trail scout",
		"color": Color(0.42, 0.82, 0.44),
		"icon_text": "ELF",
		"base_scene_path": "res://assets/Characters/nature_variants/Elf.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/elf.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.05,
		"preview_height": -0.98,
	},
	"goblin_male": {
		"id": "goblin_male",
		"title": "GOBLIN",
		"subtitle": "Playful forest trickster",
		"color": Color(0.36, 0.74, 0.30),
		"icon_text": "GOB",
		"base_scene_path": "res://assets/Characters/nature_variants/Goblin_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/goblin_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.56,
		"style": "nature_passthrough",
		"preview_scale": 1.02,
		"preview_height": -0.96,
	},
	"soldier_male": {
		"id": "soldier_male",
		"title": "SOLDIER",
		"subtitle": "Steady trail guardian",
		"color": Color(0.58, 0.76, 0.42),
		"icon_text": "SOL",
		"base_scene_path": "res://assets/Characters/nature_variants/Soldier_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/soldier_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.04,
		"preview_height": -0.98,
	},
	"cowboy_male": {
		"id": "cowboy_male",
		"title": "COWBOY",
		"subtitle": "Trail rider",
		"color": Color(0.78, 0.66, 0.34),
		"icon_text": "COW",
		"base_scene_path": "res://assets/Characters/nature_variants/Cowboy_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/cowboy_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.04,
		"preview_height": -0.98,
	},
	"kimono_male": {
		"id": "kimono_male",
		"title": "KIMONO",
		"subtitle": "Path traveler",
		"color": Color(0.74, 0.42, 0.40),
		"icon_text": "KIM",
		"base_scene_path": "res://assets/Characters/nature_variants/Kimono_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/kimono_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.04,
		"preview_height": -0.98,
	},
	"knight_male": {
		"id": "knight_male",
		"title": "KNIGHT",
		"subtitle": "Woodland knight",
		"color": Color(0.62, 0.64, 0.74),
		"icon_text": "KNT",
		"base_scene_path": "res://assets/Characters/nature_variants/Knight_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/knight_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.04,
		"preview_height": -0.98,
	},
	"ninja_male": {
		"id": "ninja_male",
		"title": "NINJA",
		"subtitle": "Silent runner",
		"color": Color(0.20, 0.24, 0.24),
		"icon_text": "NIN",
		"base_scene_path": "res://assets/Characters/nature_variants/Ninja_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/ninja_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.04,
		"preview_height": -0.98,
	},
	"pirate_male": {
		"id": "pirate_male",
		"title": "PIRATE",
		"subtitle": "River rogue",
		"color": Color(0.74, 0.52, 0.30),
		"icon_text": "PIR",
		"base_scene_path": "res://assets/Characters/nature_variants/Pirate_Male.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/pirate_male.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.04,
		"preview_height": -0.98,
	},
	"witch": {
		"id": "witch",
		"title": "WITCH",
		"subtitle": "Mystic path runner",
		"color": Color(0.56, 0.30, 0.58),
		"icon_text": "WIT",
		"base_scene_path": "res://assets/Characters/nature_variants/Witch.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/witch.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.06,
		"preview_height": -1.0,
	},
	"wizard": {
		"id": "wizard",
		"title": "WIZARD",
		"subtitle": "Ancient grove mage",
		"color": Color(0.42, 0.50, 0.82),
		"icon_text": "WIZ",
		"base_scene_path": "res://assets/Characters/nature_variants/Wizard.gltf",
		"preview_image_path": "res://assets/UI/nature/runner_previews/wizard.png",
		"fallback_scene_paths": [
			"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb",
		],
		"extra_anim_scene_paths": [],
		"visual_scale": 0.58,
		"style": "nature_passthrough",
		"preview_scale": 1.06,
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
		"patch_emission": Color(0.0, 0.0, 0.0, 1.0),
		"patch_emission_energy": 0.0,
	},
	"atmosphere": {
		"background_mode": "sky",
		"background_color": Color(0.58, 0.68, 0.80, 1.0),
		"ambient_source": "sky",
		"ambient_color": Color(0.75, 0.80, 0.85, 1.0),
		"ambient_energy": 0.7,
		"exposure": 1.0,
		"white": 6.0,
		"glow_base": 0.40,
		"glow_max": 0.70,
		"glow_strength": 0.8,
		"glow_bloom": 0.15,
		"fog_color": Color(0.78, 0.85, 0.92, 1.0),
		"fog_density_base": 0.003,
		"fog_density_max": 0.007,
		"fog_light_energy": 0.8,
		"fog_aerial": 0.6,
		"fog_sky_affect": 0.7,
		"adjustment_brightness": 1.02,
		"adjustment_contrast": 1.05,
		"adjustment_saturation": 1.1,
		"sun_color": Color(1.0, 0.96, 0.88, 1.0),
		"sun_energy": 1.3,
		"sun_indirect_energy": 0.5,
		"shadow_max_distance": 100.0,
	},
	"ambient_motion": {
		"enabled": false,
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
			"res://assets/Obstacles/GiantRock/BlastRocks/Rocks.glb",
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
		"ground": Color(0.045, 0.055, 0.075, 1.0),
		"ground_roughness": 0.66,
		"detail": Color(0.075, 0.095, 0.125, 1.0),
		"detail_roughness": 0.46,
		"patch": Color(0.02, 0.35, 0.50, 1.0),
		"patch_roughness": 0.22,
		"side": Color(0.025, 0.03, 0.045, 1.0),
		"side_roughness": 0.82,
		"edge": Color(0.05, 0.09, 0.16, 1.0),
		"edge_roughness": 0.20,
		"edge_emission": Color(0.10, 0.86, 1.0, 1.0),
		"edge_emission_energy": 2.6,
		"lane_marker": Color(0.62, 0.97, 1.0, 0.86),
		"lane_marker_emission": Color(0.22, 0.90, 1.0, 1.0),
		"lane_marker_emission_energy": 3.2,
		"patch_emission": Color(0.12, 0.82, 1.0, 1.0),
		"patch_emission_energy": 1.25,
	},
	"atmosphere": {
		"background_mode": "color",
		"background_color": Color(0.015, 0.025, 0.045, 1.0),
		"ambient_source": "color",
		"ambient_color": Color(0.08, 0.13, 0.19, 1.0),
		"ambient_energy": 0.35,
		"exposure": 0.92,
		"white": 4.4,
		"glow_base": 0.56,
		"glow_max": 0.95,
		"glow_strength": 1.18,
		"glow_bloom": 0.28,
		"fog_color": Color(0.12, 0.14, 0.20, 1.0),
		"fog_density_base": 0.0075,
		"fog_density_max": 0.016,
		"fog_light_energy": 0.18,
		"fog_aerial": 0.86,
		"fog_sky_affect": 0.18,
		"adjustment_brightness": 0.92,
		"adjustment_contrast": 1.2,
		"adjustment_saturation": 0.94,
		"sun_color": Color(0.74, 0.66, 0.56, 1.0),
		"sun_energy": 0.86,
		"sun_indirect_energy": 0.18,
		"shadow_max_distance": 62.0,
		"road_fill_color": Color(0.12, 0.90, 1.0, 1.0),
		"road_fill_energy": 0.72,
		"rim_color": Color(0.92, 0.22, 1.0, 1.0),
		"rim_energy": 0.34,
	},
	"ambient_motion": {
		"enabled": true,
		"signal_bob_height": 0.10,
		"signal_bob_speed": 1.4,
		"signal_yaw_speed": 0.24,
		"signal_light_min": 0.35,
		"signal_light_max": 0.88,
		"service_bob_height": 0.04,
		"service_bob_speed": 1.1,
		"service_yaw_speed": 0.12,
		"service_light_min": 0.18,
		"service_light_max": 0.46,
		"overhead_bob_height": 0.18,
		"overhead_bob_speed": 0.9,
		"overhead_yaw_speed": 0.16,
		"overhead_light_min": 0.26,
		"overhead_light_max": 0.72,
		"particle_amount": 36,
		"streak_amount": 10,
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
		"pods": [
			"res://assets/world/cyberprank/space_kit/environment/GeodesicDome.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Cylinder.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Single.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_OpenBack.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Single_Support.gltf",
		],
		"infrastructure": [
			"res://assets/world/cyberprank/space_kit/environment/Base_Large.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Building_L.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Long.gltf",
			"res://assets/world/cyberprank/space_kit/environment/MetalSupport.gltf",
			"res://assets/world/cyberprank/space_kit/environment/SolarPanel_Ground.gltf",
			"res://assets/world/cyberprank/space_kit/environment/SolarPanel_Roof.gltf",
			"res://assets/world/cyberprank/space_kit/environment/SolarPanel_Structure.gltf",
		],
		"signals": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Light_Street_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Light_Street_2.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_2.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_3.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Sign_4.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/TV_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/TV_2.gltf",
		],
		"service_props": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Computer.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Computer_Large.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Pipe_1.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Pipe_2.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Rail_Short.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Support.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Fence.gltf",
		],
		"skyline": [
			"res://assets/world/cyberprank/space_kit/environment/Base_Large.gltf",
			"res://assets/world/cyberprank/space_kit/environment/Building_L.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Long.gltf",
			"res://assets/world/cyberprank/space_kit/environment/GeodesicDome.gltf",
			"res://assets/world/cyberprank/space_kit/environment/House_Single_Support.gltf",
		],
		"scenic_overhead": [
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Rail_Long.gltf",
			"res://assets/world/cyberprank/cyberpunk_kit/platforms/Support_Long.gltf",
			"res://assets/world/cyberprank/space_kit/environment/SolarPanel_Structure.gltf",
			"res://assets/world/cyberprank/space_kit/environment/MetalSupport.gltf",
		],
	},
	"obstacles": {
		"ground": [
			"res://assets/world/cyberprank/space_kit/characters/Enemy_Small.gltf",
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
			"res://assets/world/cyberprank/space_kit/characters/Enemy_Small.gltf",
			"res://assets/Characters/cyberprank/mech_pack/George.gltf",
			"res://assets/Characters/cyberprank/mech_pack/Stan.gltf",
		],
		"giant": [
			"res://assets/Characters/cyberprank/cyberpunk_kit/Enemy_2Legs.gltf",
			"res://assets/Characters/cyberprank/cyberpunk_kit/Enemy_2Legs_Gun.gltf",
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
			var nature_profile: Dictionary = NATURE_PROFILE.duplicate(true)
			nature_profile["player"] = get_player_profile("nature")
			return nature_profile


static func get_player_profile(theme_id: String = "", variant_id: String = "") -> Dictionary:
	var resolved_theme: String = theme_id if not theme_id.is_empty() else GameManager.current_visual_theme
	if resolved_theme == "nature":
		var resolved_nature_variant: String = variant_id if not variant_id.is_empty() else GameManager.current_player_variant
		if resolved_nature_variant.is_empty() or resolved_nature_variant == "nature_default" or not NATURE_PLAYER_VARIANTS.has(resolved_nature_variant):
			resolved_nature_variant = "elf"
		return NATURE_PLAYER_VARIANTS[resolved_nature_variant].duplicate(true)
	if resolved_theme != "cyberprank":
		return NATURE_PROFILE.get("player", {}).duplicate(true)

	var resolved_variant: String = variant_id if not variant_id.is_empty() else GameManager.current_player_variant
	if resolved_variant.is_empty() or not CYBERPRANK_PLAYER_VARIANTS.has(resolved_variant):
		resolved_variant = "character"
	return CYBERPRANK_PLAYER_VARIANTS[resolved_variant].duplicate(true)


static func get_player_options(theme_id: String = "") -> Array[Dictionary]:
	var resolved_theme: String = theme_id if not theme_id.is_empty() else GameManager.current_visual_theme
	if resolved_theme == "nature":
		var nature_order: Array[String] = [
			"elf", "goblin_male", "soldier_male",
			"cowboy_male", "kimono_male", "knight_male",
			"ninja_male", "pirate_male", "witch", "wizard",
		]
		var nature_options: Array[Dictionary] = []
		for variant_id in nature_order:
			if NATURE_PLAYER_VARIANTS.has(variant_id):
				nature_options.append(NATURE_PLAYER_VARIANTS[variant_id].duplicate(true))
		return nature_options
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

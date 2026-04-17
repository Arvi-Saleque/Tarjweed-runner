extends RefCounted

const BASE_SCENE_PATH: String = "res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementBasic.glb"
const EXTRA_ANIM_SCENE_PATHS: Array[String] = [
	"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_MovementAdvanced.glb",
	"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_General.glb",
	"res://assets/Characters/Animations_GLTF/Rig_Medium/Rig_Medium_CombatMelee.glb",
]

const IDLE_ANIM_OPTIONS: Array[String] = [
	"Idle_No_Loop", "Idle_Rail_Loop", "Idle_A", "Idle", "Idle_Neutral",
	"Idle_Gun_Pointing", "Idle_Gun_Shoot",
]

const RUN_ANIM_OPTIONS: Array[String] = [
	"Running_A", "Running_B", "Run", "Walk_Carry_Loop", "Zombie_Walk_Fwd_Loop",
	"Walk", "Run_Holding", "Run_Tall",
]

const JUMP_ANIM_OPTIONS: Array[String] = [
	"Jump_Start", "NinjaJump_Start", "Jump", "Jump_Idle", "NinjaJump_Idle_Loop",
]

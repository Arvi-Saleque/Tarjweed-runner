extends RefCounted

const IDLE_OPTIONS: Array[String] = ["Idle_No_Loop", "Idle_Rail_Loop", "Idle_A", "Idle", "Idle_Neutral"]
const RUN_OPTIONS: Array[String] = ["Running_A", "Running_B", "Run", "Walk_Carry_Loop", "Zombie_Walk_Fwd_Loop", "Walk"]
const JUMP_UP_OPTIONS: Array[String] = ["Jump_Start", "NinjaJump_Start", "Jump"]
const JUMP_FALL_OPTIONS: Array[String] = ["Jump_Idle", "NinjaJump_Idle_Loop", "Jump"]
const JUMP_LAND_OPTIONS: Array[String] = ["Jump_Land", "NinjaJump_Land", "Land", "Idle"]
const SLIDE_OPTIONS: Array[String] = ["Crouching", "Slide_Loop", "Duck", "Idle"]
const DEATH_OPTIONS: Array[String] = ["Death_A", "Death", "Hit_Knockback"]
const STUMBLE_OPTIONS: Array[String] = ["Hit_A", "Hit_Knockback", "HitRecieve_1", "HitRecieve_2", "HitRecieve", "HitReact"]

const XFADE: float = 0.15
const XFADE_FAST: float = 0.08

extends RefCounted

const UISkinIds = preload("res://scripts/ui/ui_skin_ids.gd")

const ACTIVE_UI_SKIN := UISkinIds.NATURE

const PREVIEW_IDLE_ANIMS: Array[String] = [
	"Idle", "Idle_Neutral", "Idle_No_Loop", "Idle_A", "Idle_Gun_Pointing",
	"Running_A", "Run", "Walk",
]

const MODES: Array[Dictionary] = [
	{
		"id": "normal",
		"title": "NORMAL",
		"subtitle": "Classic endless run",
		"color": Color(0.427, 0.745, 0.341),
		"icon_text": "RUN",
	},
	{
		"id": "quiz",
		"title": "QUIZ",
		"subtitle": "Math challenges",
		"color": Color(0.957, 0.773, 0.259),
		"icon_text": "123",
	},
	{
		"id": "pronunciation",
		"title": "PRONUNCIATION",
		"subtitle": "Word pronunciation",
		"color": Color(0.718, 0.522, 0.306),
		"icon_text": "MIC",
	},
]

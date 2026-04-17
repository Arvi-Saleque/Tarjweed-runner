extends RefCounted

const ACTIVE_UI_SKIN := "nature"

const PREVIEW_IDLE_ANIMS: Array[String] = [
	"Idle", "Idle_Neutral", "Idle_No_Loop", "Idle_A", "Idle_Gun_Pointing",
	"Running_A", "Run", "Walk",
]

const MODES: Array[Dictionary] = [
	{
		"id": "normal",
		"title": "NORMAL",
		"subtitle": "Classic endless run",
		"color": Color(0.20, 0.72, 0.33),
		"icon_text": "RUN",
	},
	{
		"id": "quiz",
		"title": "QUIZ",
		"subtitle": "Math challenges",
		"color": Color(0.30, 0.55, 0.95),
		"icon_text": "123",
	},
	{
		"id": "pronunciation",
		"title": "PRONUNCIATION",
		"subtitle": "Word pronunciation",
		"color": Color(0.70, 0.35, 0.90),
		"icon_text": "MIC",
	},
]

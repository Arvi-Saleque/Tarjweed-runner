extends RefCounted

const DEFAULT_PLAYER_NAME := "Explorer"
const DEFAULT_DIFFICULTY := "medium"
const LEADERBOARD_LIMIT := 15

const DIFFICULTIES: Array[Dictionary] = [
	{
		"id": "easy",
		"title": "EASY",
		"subtitle": "Relaxed trail",
	},
	{
		"id": "medium",
		"title": "MEDIUM",
		"subtitle": "Balanced journey",
	},
	{
		"id": "hard",
		"title": "HARD",
		"subtitle": "Fast forest chase",
	},
]

const DEFAULT_UNLOCKED_RUNNERS: Array[String] = [
	"elf",
	"goblin_male",
	"soldier_male",
]

const RUNNER_PRICES: Dictionary = {
	"elf": 0,
	"goblin_male": 0,
	"soldier_male": 0,
	"cowboy_male": 120,
	"kimono_male": 160,
	"knight_male": 220,
	"ninja_male": 260,
	"pirate_male": 320,
	"witch": 380,
	"wizard": 440,
}


static func get_runner_price(runner_id: String) -> int:
	return int(RUNNER_PRICES.get(runner_id, 0))

extends Node
# A global class with stats for various objects in the game, which change
# depending on the overall state of the game.

signal upgraded_first_gathering_spot

const MIN_MONEY_GIVING_EVENT_CHARACTERS: int = 2

# The thresholds are represented by how many gathering spots have been upgraded.
const LEVEL_THRESHOLDS: Dictionary = {
	1: 4,
	2: 10,
	3: 100,
}

var level: int = 1

var curr_money_giving_event_characters: int = 0

var hireable_workers_per_level: Dictionary = {
	1: [
		Enums.WorkerType.NINE_TO_FIVE,
		Enums.WorkerType.HUSTLING,
		Enums.WorkerType.SWIFT,
		Enums.WorkerType.GAMBLING,
		Enums.WorkerType.HOME_COOK,
	],
	2: [
		Enums.WorkerType.HUSTLING,
		Enums.WorkerType.SWIFT,
		Enums.WorkerType.GAMBLING,
		Enums.WorkerType.CHEESE_LOVING,
		Enums.WorkerType.ICE_LOVING,
		Enums.WorkerType.LEAF_LOVING,
		Enums.WorkerType.REFLECTION,
		Enums.WorkerType.HOME_COOK,
	],
	3: [
		Enums.WorkerType.HUSTLING,
		Enums.WorkerType.SWIFT,
		Enums.WorkerType.GAMBLING,
		Enums.WorkerType.CHEESE_LOVING,
		Enums.WorkerType.ICE_LOVING,
		Enums.WorkerType.LEAF_LOVING,
		Enums.WorkerType.REFLECTION,
		Enums.WorkerType.HOME_COOK,
	],
}

var character_event_stats: Dictionary = {
	1: [
		{
			"reward_type": Enums.Resource.MONEY,
			"take_amount_min": 20,
			"take_amount_max": 30,
			"give_amount_min": 125,
			"give_amount_max": 250,
		},
		{
			"reward_type": Enums.Resource.SUPPORTER,
			"take_amount_min": 80,
			"take_amount_max": 160,
			"give_amount_min_percentage": 4,
			"give_amount_max_percentage": 6,
		},
	],
	2: [
		{
			"reward_type": Enums.Resource.MONEY,
			"take_amount_min": 40,
			"take_amount_max": 80,
			"give_amount_min": 275,
			"give_amount_max": 375,
		},
		{
			"reward_type": Enums.Resource.SUPPORTER,
			"take_amount_min": 175,
			"take_amount_max": 275,
			"give_amount_min_percentage": 6,
			"give_amount_max_percentage": 8,
		},
		{
			"reward_type": Enums.Resource.STEAL_SUPPORTER,
			"take_amount_min": 250,
			"take_amount_max": 300,
			"give_amount_min_percentage": 2,
			"give_amount_max_percentage": 4,
		},
	],
	3: [
		{
			"reward_type": Enums.Resource.MONEY,
			"take_amount_min": 100,
			"take_amount_max": 150,
			"give_amount_min": 400,
			"give_amount_max": 600,
		},
		{
			"reward_type": Enums.Resource.SUPPORTER,
			"take_amount_min": 300,
			"take_amount_max": 350,
			"give_amount_min_percentage": 8,
			"give_amount_max_percentage": 12,
		},
		{
			"reward_type": Enums.Resource.STEAL_SUPPORTER,
			"take_amount_min": 400,
			"take_amount_max": 500,
			"give_amount_min_percentage": 5,
			"give_amount_max_percentage": 7,
		},
	],
}

var _upgraded_gathering_spots: int = 0

func _ready() -> void:
	randomize()
	reset()
	_connect_signals()

# Increases the counter for gathering spots and updates the world
# level based on that.
func progress_world_state() -> void:
	_upgraded_gathering_spots += 1
	if _upgraded_gathering_spots == 1:
		emit_signal("upgraded_first_gathering_spot")
	if LEVEL_THRESHOLDS[level] <= _upgraded_gathering_spots:
		level += 1

# Returns data based on the current world level that can be used to create a 
# character event instance. reward_type is the resource type the character event 
# rewards. If left to -1, a random type will be chosen.
func get_random_character_event_stats() -> Dictionary:
	if curr_money_giving_event_characters >= MIN_MONEY_GIVING_EVENT_CHARACTERS:
		var rand_index: int = randi() % character_event_stats[level].size()
		var rand_event: Dictionary = character_event_stats[level][rand_index]
		if rand_event.reward_type == Enums.Resource.MONEY:
			curr_money_giving_event_characters += 1
		return rand_event
	for stats in character_event_stats[level]:
		if stats.reward_type == Enums.Resource.MONEY:
			curr_money_giving_event_characters += 1
			return stats
	return {}

# Resets the world state.
func reset() -> void:
	level = 1
	curr_money_giving_event_characters = 0
	_upgraded_gathering_spots = 0


func _connect_signals() -> void:
	DebugHelper.connect("requested_set_word_level", self, "_debug_helper_requested_set_word_level")


func _debug_helper_requested_set_word_level(new_level: int) -> void:
	level = new_level

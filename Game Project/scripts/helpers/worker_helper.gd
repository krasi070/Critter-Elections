extends Node

const PRE_WORK_METHOD: String = "set_up_%s_bee_pre_work"
const POST_WORK_METHOD: String = "set_up_%s_bee_post_work"

var _data_by_type: Dictionary = {
	Enums.WorkerType.NINE_TO_FIVE: {
		"name": "Nine to Five Bee",
		"type": Enums.WorkerType.NINE_TO_FIVE,
		"info": "1x reap \\ 1x speed",
		"price": 2,
		"reward_multiplier": 1,
		"work_speed": 1,
	},
	Enums.WorkerType.HUSTLING: {
		"name": "Hustling Bee",
		"type": Enums.WorkerType.HUSTLING,
		"info": "2x reap \\ 1x speed",
		"price": 4,
		"reward_multiplier": 2,
		"work_speed": 1,
	},
	Enums.WorkerType.SWIFT: {
		"name": "Swift Bee",
		"type": Enums.WorkerType.SWIFT,
		"info": "1x reap \\ 2x speed",
		"price": 5,
		"reward_multiplier": 1,
		"work_speed": 2,
	},
	Enums.WorkerType.GAMBLING: {
		"name": "Gambling Bee",
		"type": Enums.WorkerType.GAMBLING,
		"info": "1x speed\n50/50 chance to get 0x or 5x reap",
		"price": 6,
		"reward_multiplier": 0,
		"work_speed": 1,
	},
	Enums.WorkerType.REFLECTION: {
		"name": "Mirror Bee",
		"type": Enums.WorkerType.REFLECTION,
		"temporary_type": Enums.WorkerType.NINE_TO_FIVE,
		"info": "copies the stats and effects of the bee to the left of it when placed",
		"price": 10,
		"reward_multiplier": 1,
		"work_speed": 1,
	},
	Enums.WorkerType.HOME_COOK: {
		"name": "Home Cook Bee",
		"type": Enums.WorkerType.HOME_COOK,
		"info": "1x reap / 1x speed\n+1*honeycomb* when finished working",
		"price": 5,
		"reward_multiplier": 1,
		"work_speed": 1,
	},
	Enums.WorkerType.LEAF_LOVING: {
		"name": "Leaf Loving Bee",
		"type": Enums.WorkerType.LEAF_LOVING,
		"info": "1x reap / 1x speed\n3x reap if collecting *leaves*",
		"price": 8,
		"reward_multiplier": 1,
		"work_speed": 1,
	},
	Enums.WorkerType.CHEESE_LOVING: {
		"name": "Cheese Loving Bee",
		"type": Enums.WorkerType.CHEESE_LOVING,
		"info": "1x reap / 1x speed\n3x reap if collecting *cheese*",
		"price": 8,
		"reward_multiplier": 1,
		"work_speed": 1,
	},
	Enums.WorkerType.ICE_LOVING: {
		"name": "Ice Loving Bee",
		"type": Enums.WorkerType.ICE_LOVING,
		"info": "1x reap / 1x speed\n3x reap if collecting *ice*",
		"price": 8,
		"reward_multiplier": 1,
		"work_speed": 1,
	},
}

var _default_worker_data: Dictionary = {
	"curr_work_completed": 0,
	"is_working": false,
	"working_at": "", 
	"id": "",
	"employer_id": -1,
}

func _ready() -> void:
	randomize()

# Returns new instance of worker data of the specified type.
func get_duplicated_worker_data_by_type(type: int) -> Dictionary:
	var worker_data: Dictionary = _data_by_type[type].duplicate()
	var default_data: Dictionary = _default_worker_data.duplicate()
	worker_data.merge(default_data)
	return worker_data

# Prework preparations for gambling bee.
func set_up_gambling_bee_pre_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	var multipliers: Array = [0, 5]
	var rand_index: int = randi() % multipliers.size()
	_worker.reward_multiplier = multipliers[rand_index]

# Prework preparations for leaf loving bee.
func set_up_leaf_loving_bee_pre_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	_set_up_resource_loving_bee_pre_work(_worker, _gathering_spot_data, _to_be_place_index, Enums.Resource.LEAVES)

# Prework preparations for cheese loving bee.
func set_up_cheese_loving_bee_pre_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	_set_up_resource_loving_bee_pre_work(_worker, _gathering_spot_data, _to_be_place_index, Enums.Resource.CHEESE)

# Prework preparations for ice loving bee.
func set_up_ice_loving_bee_pre_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	_set_up_resource_loving_bee_pre_work(_worker, _gathering_spot_data, _to_be_place_index, Enums.Resource.ICE)

# Prework preparations for reflection bee.
func set_up_reflection_bee_pre_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	var left_worker: Dictionary = {}
	if _to_be_place_index > 0 and \
		not _gathering_spot_data.working_workers[_to_be_place_index - 1].empty():
		left_worker = _gathering_spot_data.working_workers[_to_be_place_index - 1]
	if left_worker.empty():
		_worker.reward_multiplier = 1
		_worker.work_speed = 1
		_worker.temporary_type = Enums.WorkerType.NINE_TO_FIVE
		return
	_worker.temporary_type = left_worker.type
	if left_worker.type == Enums.WorkerType.REFLECTION:
		_worker.temporary_type = left_worker.temporary_type
	_worker.reward_multiplier = left_worker.reward_multiplier
	_worker.work_speed = left_worker.work_speed
	var pre_work_method: String = \
		PRE_WORK_METHOD % Enums.to_str_snake_case(Enums.WorkerType, _worker.temporary_type)
	if has_method(pre_work_method):
		call(pre_work_method, _worker, _gathering_spot_data, _to_be_place_index)

# Postwork preparations for reflection bee.
func set_up_reflection_bee_post_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	var post_work_method: String = \
		POST_WORK_METHOD % Enums.to_str_snake_case(Enums.WorkerType, _worker.temporary_type)
	if has_method(post_work_method):
		call(post_work_method, _worker, _gathering_spot_data, _to_be_place_index)

# Postwork preparations for home cook bee.
func set_up_home_cook_bee_post_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int) -> void:
	var honeycomb_bonus: int = 1
	var player_id: int = _worker.employer_id
	MatchRoomManager.players[player_id].resources[Enums.Resource.HONEYCOMB] += honeycomb_bonus

# Helper function for resource loving bee workers.
func _set_up_resource_loving_bee_pre_work(_worker: Dictionary, _gathering_spot_data: Dictionary, _to_be_place_index: int, res_type: int) -> void:
	_worker.reward_multiplier = 1
	var lover_multiplier: int = 3
	if _gathering_spot_data.resource_type == res_type:
		_worker.reward_multiplier = lover_multiplier

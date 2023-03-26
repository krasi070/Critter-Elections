class_name GatheringSpot
extends MapObject
# GatheringSpot's script.

signal ready_for_production(location)
signal worker_is_done(gathering_spot, worker)
signal upgraded

const MAX_LEVEL: int = 6
const MAX_WORKER_LIMIT: int = 4
const STARTING_WORKER_LIMIT: int = 2

const PRODUCTION_TIME_DEFAULT: float = 30.0
const PRODUCTION_AMOUNT_DEFAULT: int = 10
const PRODUCTION_AMOUNT_UPGRADES: Array = [5, 10, 15, 40]
const PRODUCTION_TIME_UPGRADE: int = 20
const UPGRADES: Array = [
	-1,
	Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT,
	Enums.GatheringSpotUpgrade.INCREASE_WORKER_LIMIT,
	Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT,
	Enums.GatheringSpotUpgrade.INCREASE_WORKER_LIMIT,
	Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT,
]

const CAPACITY_FORMAT: String = "%d/%d"
const MAX_CAPACITY_TEXT: String = "FULL"
const NAME_BY_TYPE: Dictionary = {
	Enums.Resource.CHEESE: "Cheese Mine",
	Enums.Resource.ICE: "Ice Igloo",
	Enums.Resource.LEAVES: "Leafy Bush",
}

var resource_type: int
var production_speed: float
var production_time: float
var production_amount: float
var production_amount_upgrades: Array
var curr_production_value: float
var level: int setget _set_level
var worker_limit: int
var working_workers: Array

onready var sprite: Sprite = $Sprite
onready var progress_bar: ProgressBar = $ProgressBar
onready var capacity_label: Label = $CapacityLabel
onready var anim_player: AnimationPlayer = $AnimationPlayer

var _is_automatic_production_on: bool = false

func _ready() -> void:
	add_to_group("interactables")
	progress_bar.visible = _is_automatic_production_on
	capacity_label.visible = not _is_automatic_production_on
	_set_default_data()
	_update_capacity_label()


func _physics_process(delta: float) -> void:
	if _is_automatic_production_on:
		_update_pogress(delta)
	else:
		_update_working_workers_progress(delta)
	
# Returns all the data associated with the gathering spot instance.
func get_data() -> Dictionary:
	return {
		"name": NAME_BY_TYPE[resource_type],
		"resource_type": resource_type,
		"production_speed": production_speed,
		"production_time": production_time,
		"production_amount": production_amount,
		"curr_production_value": curr_production_value,
		"level": level,
		"max_level": MAX_LEVEL,
		"worker_limit": worker_limit,
		"working_workers": working_workers,
		"next_level_info": _get_next_level_info(), 
		"upgrade_price": _get_upgrade_price(),
	}

# Sets all the data associated with the gathering spot instance.
# Updates capacity label.
func set_data(data: Dictionary) -> void:
	var resource_str: String = Enums.to_str_snake_case(Enums.Resource, data.resource_type)
	sprite.texture = load(Paths.GATHERING_SPOT_SPRITE_PATH_FORMAT % resource_str)
	resource_type = data.resource_type
	production_speed = data.production_speed
	production_time = data.production_time
	production_amount = data.production_amount
	#curr_production_value = data.curr_production_value
	level = data.level
	worker_limit = data.worker_limit
	working_workers = data.working_workers
	_update_capacity_label()

# Sets the resource data for the gathering spot based on its location's
# area type.
func set_data_on_type(area_type: int) -> void:
	resource_type = _get_resource_type_by_area_type(area_type)

# Returns the number of available spaces for workers.
func get_number_of_free_spaces() -> int:
	return worker_limit - working_workers.size()

# Set a worker to a working space. Updates capacity label.
func set_worker(worker: Dictionary, space_index: int) -> void:
	_do_worker_set_up(WorkerHelper.PRE_WORK_METHOD, worker, space_index)
	working_workers[space_index] = worker
	worker.is_working = true
	worker.working_at = name
	if not anim_player.is_playing():
		anim_player.play("working")
	_update_capacity_label()

# Level up the shop and apply level up benefits. The player_id is to
# find out who upgraded the gathering spot. Returns true, if upgrade is successful.
func upgrade(player_id: int) -> bool:
	var next_level_price: int = _get_upgrade_price()
	if level == MAX_LEVEL:
		return false
	if MatchRoomManager.players[player_id].resources[Enums.Resource.MONEY] < next_level_price:
		return false
	MatchRoomManager.players[player_id].resources[Enums.Resource.MONEY] -= next_level_price
	var upgrade_type: int = UPGRADES[level]
	match upgrade_type:
		Enums.GatheringSpotUpgrade.INCREASE_WORKER_LIMIT:
			worker_limit += 1
			working_workers.append({})
		Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT:
			production_amount += production_amount_upgrades.pop_front()
		Enums.GatheringSpotUpgrade.DECREASE_PRODUCTION_TIME:
			production_time *= (100 - PRODUCTION_TIME_UPGRADE) / 100.0
	# On any upgrade the player gets a recruiting resource which can be used to recruit
	var recruiting_tokens_to_give: int = _get_recruiting_tokens_for_level()
	MatchRoomManager.players[player_id].resources[Enums.Resource.HONEYCOMB] += recruiting_tokens_to_give
	_set_level(level + 1)
	_update_capacity_label()
	MatchRoomManager.update_player(player_id)
	MatchRoomManager.update_location_player_is_on(player_id, get_data())
	emit_signal("upgraded")
	return true


func _get_next_level_info() -> Array:
	var upgrades: Array = []
	if level == MAX_LEVEL:
		return upgrades
	var upgrade_type: int = UPGRADES[level]
	var recruiting_tokens: int = _get_recruiting_tokens_for_level()
	match upgrade_type:
		Enums.GatheringSpotUpgrade.INCREASE_WORKER_LIMIT:
			upgrades.append({
				"type": Enums.GatheringSpotUpgrade.INCREASE_WORKER_LIMIT,
				"amount": 1,
			})
		Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT:
			upgrades.append({
				"type": Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT,
				"amount": production_amount_upgrades[0],
			})
	upgrades.append({
		"type": Enums.GatheringSpotUpgrade.HONEYCOMB,
		"amount": recruiting_tokens,
	})
	return upgrades


func _get_upgrade_price() -> int:
	if level == MAX_LEVEL:
		return 0
	return level * 100


func _get_resource_type_by_area_type(area_type: int) -> int:
	match area_type:
		Enums.TileType.GREEN:
			return Enums.Resource.LEAVES
		Enums.TileType.SNOWY:
			return Enums.Resource.ICE
		Enums.TileType.URBAN:
			return Enums.Resource.CHEESE
		_:
			return -1


func _set_level(new_level: int) -> void:
	level = int(clamp(new_level, 1, MAX_LEVEL))


func _update_visual_progress() -> void:
	progress_bar.min_value = 0
	progress_bar.max_value = production_time
	progress_bar.value = curr_production_value


func _update_capacity_label() -> void:
	var working_count: int = 0
	for worker in working_workers:
		if not worker.empty() and worker.is_working:
			working_count += 1
	if working_count == worker_limit:
		capacity_label.text = MAX_CAPACITY_TEXT
		return
	capacity_label.text = CAPACITY_FORMAT % [working_count, worker_limit]


func _get_recruiting_tokens_for_level() -> int:
	return 4 + (level - 1) * 2


func _set_default_data() -> void:
	var resource_str: String = Enums.to_str_snake_case(Enums.Resource, resource_type)
	sprite.texture = load(Paths.GATHERING_SPOT_SPRITE_PATH_FORMAT % resource_str)
	production_speed = 5
	production_time = PRODUCTION_TIME_DEFAULT
	production_amount = PRODUCTION_AMOUNT_DEFAULT
	production_amount_upgrades = PRODUCTION_AMOUNT_UPGRADES.duplicate()
	curr_production_value = 0
	level = 1
	worker_limit = STARTING_WORKER_LIMIT
	_free_working_workers()


func _do_worker_set_up(method: String, worker: Dictionary, space_index: int) -> void:
	var worker_type_str: String = Enums.to_str_snake_case(Enums.WorkerType, worker.type)
	var worker_method: String = method % worker_type_str
	if WorkerHelper.has_method(worker_method):
		WorkerHelper.call(worker_method, worker, get_data(), space_index)


func _free_working_workers() -> void:
	for worker in working_workers:
		if not worker.empty():
			var player_worker: Dictionary = \
				MatchRoomManager.players[worker.employer_id].workers[worker.id]
			player_worker.is_working = false
			player_worker.working_at = ""
	working_workers = []
	for _i in range(worker_limit):
		working_workers.append({})
	_update_capacity_label()


func _update_working_workers_progress(delta: float) -> void:
	for i in range(working_workers.size()):
		if not working_workers[i].empty():
			_update_worker_progress(working_workers[i], i, delta)


func _update_worker_progress(worker: Dictionary, index: int, delta: float) -> void:
	worker.curr_work_completed += worker.work_speed * delta
	if worker.curr_work_completed >= production_time:
		_free_finished_worker(worker, index)
		_update_capacity_label()


func _free_finished_worker(worker: Dictionary, index: int) -> void:
	var player_worker: Dictionary = \
			MatchRoomManager.players[worker.employer_id].workers[worker.id]
	_do_worker_set_up(WorkerHelper.POST_WORK_METHOD, worker, index)
	player_worker.is_working = false
	player_worker.working_at = ""
	player_worker.curr_work_completed = 0
	working_workers[index] = {}
	#print("type ", Enums.to_str_snake_case(Enums.Resource, resource_type), " ", _get_working_workers_count())
	if _get_working_workers_count() == 0:
		anim_player.stop()
	MatchRoomManager.players[worker.employer_id].resources[resource_type] += \
		production_amount * worker.reward_multiplier
	MatchRoomManager.update_player(worker.employer_id)
	MapData.update_location_data_for_player_if_present(location)
	emit_signal("worker_is_done", self, player_worker)


func _get_working_workers_count() -> int:
	var working_workers_count: int = 0
	for worker in working_workers:
		if not worker.empty():
			working_workers_count += 1
	return working_workers_count


func _update_pogress(delta: float) -> void:
	curr_production_value += production_speed * delta
	if curr_production_value >= production_time:
		_produce()
		curr_production_value = 0
		emit_signal("ready_for_production", location)
	_update_visual_progress()


func _produce() -> void:
	var to_update_player_ids: Dictionary = {}
	for worker in working_workers:
		if not worker.empty():
			MatchRoomManager.players[worker.employer_id].resources[resource_type] += production_amount
			to_update_player_ids[worker.employer_id] = true
	_free_working_workers()
	for player_id in to_update_player_ids.keys():
		MatchRoomManager.update_player(player_id)
		MapData.update_location_data_for_player_if_present(location)

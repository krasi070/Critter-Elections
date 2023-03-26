class_name HiringSpot
extends MapObject
# HiringSpot's script.

const APPEAR_ANIM_DURATION: float = 0.3
const FOR_HIRE_SIZE: int = 4

var for_hire: Array

var _last_hired_worker_type: int = -1
var _id_counter: int = 1000

func _ready() -> void:
	add_to_group("interactables")
	randomize()
	_appear()
	_init_for_hire_data()

# Returns the for hire data.
func get_data() -> Dictionary:
	return { "for_hire": for_hire }

# Sets the for hire data.
func set_data(data: Dictionary) -> void:
	for_hire = data.for_hire

# Retruns the worker at the given rank and removes it from the
# for hire list. Returns an empty dictionary, if did not hire.
func hire_worker_at_rank(player_id: int, rank: int) -> Dictionary:
	var player: Dictionary = MatchRoomManager.players[player_id]
	var total_price: int = for_hire[rank].price + rank
	if player.resources[Enums.Resource.HONEYCOMB] < total_price:
		return {}
	player.resources[Enums.Resource.HONEYCOMB] -= total_price
	var hired_worker: Dictionary = for_hire.pop_at(rank)
	_last_hired_worker_type = hired_worker.type
	_add_new_worker_to_for_hire()
	return hired_worker


func _init_for_hire_data() -> void:
	for _i in range(FOR_HIRE_SIZE):
		_add_new_worker_to_for_hire()


func _appear() -> void:
	modulate = Color.transparent
	var tween: SceneTreeTween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, APPEAR_ANIM_DURATION)


func _add_new_worker_to_for_hire() -> void:
	var new_worker_pool: Array = \
		WorldLevelStats.hireable_workers_per_level[WorldLevelStats.level].duplicate()
	_remove_for_hire_workers_from_new_hire_pool(new_worker_pool)
	if new_worker_pool.empty():
		new_worker_pool.append(Enums.WorkerType.NINE_TO_FIVE)
	var rand_index: int = randi() % new_worker_pool.size()
	var worker_data: Dictionary = \
		WorkerHelper.get_duplicated_worker_data_by_type(new_worker_pool[rand_index])
	worker_data.id = str(get_instance_id()) + str(_id_counter)
	for_hire.append(worker_data)
	_id_counter += 1


func _remove_for_hire_workers_from_new_hire_pool(new_hire_pool: Array) -> void:
	new_hire_pool.erase(_last_hired_worker_type)
	for for_hire_worker in for_hire:
		new_hire_pool.erase(for_hire_worker.type)

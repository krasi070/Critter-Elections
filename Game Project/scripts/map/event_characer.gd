class_name EventCharacter
extends MapObject
# EventCharacter's script.

signal event_ended(location, amount, res_type, team, loss_team)

const WAIT_TIME: float = 20.0
const SECOND_PAYER_MULTIPLIERS: Array = [1.2, 1.5, 1.8]

onready var sprite: Sprite = $Sprite
onready var progress_bar: TextureProgress = $TextureProgress
onready var timer: Timer = $Timer
onready var anim_player: AnimationPlayer = $AnimationPlayer

# The minimum required payment for the event.
var _min_payment: int
# The type of resource the payment must be made in.
var _resource_type: int
# The amount of reward upon successful completion of the event.
var _reward_amount: int
# The resource type the reward is in.
var _reward_type: int
# The amount paid by the first player.
var _first_payment_amount: int
# True if the first payment has gone through.
var _has_first_payment_been_made: bool = false
# The ID of the player who made the first payment.
var _first_payment_by: int
# The ID of the player who made the second payment.
var _second_payment_by: int
# Used if the reward type is STEAL_SUPPORTER. The team index of the team
# the stealing will happen.
var _steal_from_team: int
# Set to true when player pays the second payment.
var _has_event_ended: bool = false
# Shows whether the second payer managed to overbid the first payer.
var _is_second_payer_successful: bool = false
# The amount paid by the second player.
var _second_payment_amount: int
# The teams the offer has been refused by.
var _refused_by: Array = []

func _ready() -> void:
	add_to_group("interactables")
	_set_default_data()
	_set_progress_bar_values()
	_connect_signals()
	anim_player.play("appear")


func _physics_process(_delta: float) -> void:
	progress_bar.value = WAIT_TIME - timer.time_left

# Gets the data representing the present state of the event.
func get_data() -> Dictionary:
	return {
		"min_payment": _min_payment,
		"resource_type": _resource_type,
		"reward_amount": _reward_amount,
		"reward_type": _reward_type,
		"first_payment_amount": _first_payment_amount,
		"has_first_payment_been_made": _has_first_payment_been_made,
		"first_payment_by": _first_payment_by,
		"has_event_ended": _has_event_ended,
		"second_payer_multiplier": SECOND_PAYER_MULTIPLIERS[1],
		"steal_from": _steal_from_team,
		"refused_by": _refused_by,
		"is_second_payer_successful": _is_second_payer_successful,
		"second_payment_amount": _second_payment_amount,
		"area": _get_area_in(),
	}

# Sets the necessary data for the event.
func set_data(data: Dictionary) -> void:
	_min_payment = data.min_payment
	_resource_type = data.resource_type
	_reward_amount = data.reward_amount
	_reward_type = data.reward_type
	_first_payment_amount = data.first_payment_amount
	_has_first_payment_been_made = data.has_first_payment_been_made
	_first_payment_by = data.first_payment_by

# Sets all the event's data releated to resources.
func set_resources_data_based_on_area(takes: int, takes_amount: int, gives: int, gives_amount: int) -> void:
	_resource_type = takes
	_reward_type = gives
	_min_payment = takes_amount
	_reward_amount = gives_amount
	if _reward_type == Enums.Resource.STEAL_SUPPORTER:
		_steal_from_team = _get_can_steal_from_team()

# If the timer is running it will be paused.
func pause() -> void:
	timer.paused = true

# Unpause the timer if it is set to run.
func unpause() -> void:
	timer.paused = false

# Pays first payment by given player. If invalid, returns false and does nothing.
func pay_as_first_visitor(player_id: int, payment_amount: int) -> bool:
	if payment_amount < _min_payment:
		return false
	if MatchRoomManager.players[player_id].resources[_resource_type] < payment_amount:
		return false
	_first_payment_amount = payment_amount
	_has_first_payment_been_made = true
	timer.start(WAIT_TIME)
	timer.paused = true
	_first_payment_by = player_id
	progress_bar.visible = true
	MatchRoomManager.players[player_id].resources[_resource_type] -= payment_amount
	MatchRoomManager.update_player(player_id)
	MatchRoomManager.update_location_player_is_on(player_id, get_data())
	return true

# Pays second payment by given player. If invalid, returns false.
func pay_as_second_visitor(player_id: int, payment_amount: int) -> bool:
#	var need_to_pay: int = int(_first_payment_amount * SECOND_PAYER_MULTIPLIERS[1])
	var need_to_pay: int = _first_payment_amount
	_second_payment_amount = payment_amount
	if not _has_first_payment_been_made:
		return false
	if payment_amount <= need_to_pay:
		_is_second_payer_successful = false
		_has_event_ended = true
		MatchRoomManager.update_location_player_is_on(player_id, get_data())
		return false
	if MatchRoomManager.players[player_id].resources[_resource_type] < payment_amount:
		return false
	_has_event_ended = true
	_is_second_payer_successful = true
	_second_payment_by = player_id
	MatchRoomManager.players[player_id].resources[_resource_type] -= payment_amount
	_reward_player(player_id)
	MatchRoomManager.update_location_player_is_on(player_id, get_data())
	MatchRoomManager.players[_first_payment_by].resources[_resource_type] += _first_payment_amount
	MatchRoomManager.update_player(_first_payment_by)
	return true

# Adds the player to the refused players list.
func add_to_refused(refuser_id: int) -> void:
	_refused_by.append(refuser_id)
	MatchRoomManager.update_location_player_is_on(refuser_id, get_data())

# Returns true if no one has made an offer yet.
func is_offer_failing() -> bool:
	return not _has_first_payment_been_made


func _get_area_in() -> int:
	if not MapData.map.has(location):
		return -1
	return MapData.map[location].area_type

# Ends the event, handles leftover tasks, and frees the instance. Emits event_ended signal.
func end_event() -> void:
	var successful_player_id: int = -1
	if not _is_second_payer_successful and _has_first_payment_been_made:
		_reward_player(_first_payment_by)
		successful_player_id = _first_payment_by
	elif _is_second_payer_successful:
		successful_player_id = _second_payment_by
	var successful_team: int = MatchRoomManager.get_team_by_player_id(successful_player_id)
	if successful_player_id == -1:
		emit_signal("event_ended", location, 0, -1, Enums.Team.NOT_SELECTED, Enums.Team.NOT_SELECTED)	
	elif _reward_type == Enums.Resource.STEAL_SUPPORTER:
		emit_signal("event_ended", location, _reward_amount, _reward_type, successful_team, _steal_from_team)
	else:
		emit_signal("event_ended", location, _reward_amount, _reward_type, successful_team, Enums.Team.NOT_SELECTED)
	MapData.remove_map_object(location, false)
	anim_player.play("disappear")


func _reward_player(player_id: int) -> void:
	if _reward_type == Enums.Resource.SUPPORTER:
		_add_supporters(player_id)
	elif _reward_type == Enums.Resource.STEAL_SUPPORTER:
		_steal_supporters(player_id)
	elif _reward_type == Enums.Resource.MONEY:
		_add_money(player_id)
	MatchRoomManager.update_player(player_id)


func _add_money(player_id: int) -> void:
	MatchRoomManager.players[player_id].resources[_reward_type] += _reward_amount


func _add_supporters(player_id: int) -> void:
	var team: int = MatchRoomManager.get_team_by_player_id(player_id)
	var area: int = _get_area_in()
	var supporters: int = MapData.get_population_by_percentage_in_area(_reward_amount, area)
	MapData.add_supporters_to_team_in_area(supporters, team, area)


func _steal_supporters(player_id: int) -> void:
	var stealing_team: int = MatchRoomManager.get_team_by_player_id(player_id)
	var area: int = _get_area_in()
	var supporters: int = MapData.get_population_by_percentage_in_area(_reward_amount, area)
	MapData.move_supporters_between_teams(supporters, _steal_from_team, stealing_team, area)

func _connect_signals() -> void:
	anim_player.connect("animation_finished", self, "_anim_player_animation_finished")
	timer.connect("timeout", self, "_timeout_timer")
	MapData.connect("player_moved", self, "_player_moved_map_data")


func _set_progress_bar_values() -> void:
	progress_bar.min_value = 0
	progress_bar.max_value = WAIT_TIME
	progress_bar.value = 0


func _set_default_data() -> void:
	_first_payment_amount = 0
	_has_first_payment_been_made = false
	_first_payment_by = 0
	_has_event_ended = false
	progress_bar.visible = false
	var sprite_texture: Texture
	if _reward_type != Enums.Resource.MONEY:
		sprite_texture = \
			load(Paths.EVENT_CHARACTER_SPRITE_PATH_FORMAT % [Enums.to_str_snake_case(Enums.Resource, _reward_type)])
	else:
		sprite_texture = \
			load(Paths.EVENT_CHARACTER_SPRITE_PATH_FORMAT % [Enums.to_str_snake_case(Enums.Resource, _resource_type)])
	sprite.texture = sprite_texture


func _get_can_steal_from_team() -> int:
	var to_steal_from: int = -1
	var max_supporters: int = -1
	if not MapData.is_inside(location):
		return Enums.Team.NOT_SELECTED
	var area: int = MapData.map[location].area_type
	for team in MapData.projections[area].candidate_support.keys():
		#var steal_supporters_amount: int = MapData.get_population_by_percentage_in_area(_reward_amount, area)
		var team_supporters: int = MapData.projections[area].candidate_support[team]
		if max_supporters < team_supporters:
			to_steal_from = team
			max_supporters = team_supporters
	print("set to ", to_steal_from)
	return to_steal_from


func _has_everyone_refused() -> bool:
	return _refused_by.size() == MatchRoomManager.teams.size() or \
		(_refused_by.size() == MatchRoomManager.teams.size() - 1 and _has_first_payment_been_made)


func _timeout_timer() -> void:
	end_event()


func _anim_player_animation_finished(anim_name: String) -> void:
	if anim_name == "appear":
		anim_player.play("idle")
	elif anim_name == "disappear":
		if _reward_type == Enums.Resource.MONEY:
			WorldLevelStats.curr_money_giving_event_characters -= 1
		queue_free()


func _player_moved_map_data(_player_id: int, old_location: Vector2, new_location: Vector2) -> void:
	if location == old_location and (_has_event_ended or _has_everyone_refused()):
		end_event()
	elif location == old_location:
		unpause()
	elif location == new_location:
		pause()

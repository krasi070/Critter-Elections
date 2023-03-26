extends Node
# A singleton class containing various data about the player.

signal updated_resources
signal updated_workers
signal updated_location_data
signal updated_teammate_data
signal is_exchanging_value_changed
signal rejoin_data_set
signal join_order_changed

# The options the player can pick from when selecting the first half of their
# name.
var start_name_options: Array
# The options the player can pick from when selecting the second half of their
# name.
var end_name_options: Array
# The selected first half of the name of the player.
var start_name: String
# The selected second half of the name of the player.
var end_name: String
# The original network ID the player was given on their first connection
# to the server.
var id: int
# The player name, made up of start_name and end_name.
var join_order: int setget set_join_order
# An array of disconnected players. Used to reconnect back to game if disconnected.
var rejoin_data: Array setget set_rejoin_data

# The player's team.
var team_index: int
# The player's role.
var team_role: int
# The player's teammate's data.
var teammate_data: Dictionary setget set_teammate_data
# Is player is exchange resources mode.
var is_exchanging: bool setget set_is_exchanging

# The player's current location on the map.
var location: Vector2
# What is on the location the player is on. Uses Enums.LocationType to set values.
var location_type: int
# Holds data about the interactable map object the player is on.
var location_data: Dictionary setget set_location_data

# Number of resources held per resource.
var resources: Dictionary

# The hired workers by the player.
var workers: Dictionary

func _ready() -> void:
	reset_data()


func _physics_process(delta: float) -> void:
	_simulate_working_worker_progress(delta)

# Sets the new data for the player.
func set_data(data: Dictionary) -> void:
	start_name_options = data.start_names
	end_name_options = data.end_names
	set_player_name_if_available(data.name)
	set_join_order(data.join_order)
	resources = data.resources
	workers = data.workers
	team_index = data.team
	team_role = data.role
	set_is_exchanging(data.is_exchanging)
	emit_signal("updated_workers")
	emit_signal("updated_resources")

# Sets the player's start and end name if they are present and not set already.
func set_player_name_if_available(player_name: String) -> void:
	if not start_name.empty() and not end_name.empty():
		return
	var name_args: PoolStringArray = player_name.split(" ", false)
	if name_args.size() > 1 and \
		start_name_options.has(name_args[0]) and \
		end_name_options.has(name_args[1]):
		start_name = name_args[0]
		end_name = name_args[1]

# Sets the player's join order in the room they are in.
func set_join_order(new_join_order: int) -> void:
	if join_order == new_join_order:
		return
	join_order = new_join_order
	emit_signal("join_order_changed")

# Sets data about the player's teammate.
func set_teammate_data(data: Dictionary) -> void:
	teammate_data = data
	emit_signal("updated_teammate_data")

# Sets the is exchaning value.
func set_is_exchanging(_is_exchanging: bool) -> void:
	if is_exchanging == _is_exchanging:
		return
	is_exchanging = _is_exchanging
	emit_signal("is_exchanging_value_changed")

# Returns the network ID of the player.
func get_network_id() -> int:
	return get_tree().get_network_unique_id()

# Returns the player's name made up of start_name and end_name.
func get_full_name() -> String:
	return start_name + " " + end_name

# Returns true, if the player joined the room first, which makes them
# the room master.
func is_room_master() -> bool:
	return join_order == 0

# Sets the location data and emits updated_location_data signal.
func set_location_data(new_location_data: Dictionary) -> void:
	location_data = new_location_data
	emit_signal("updated_location_data")

# Sets the rejoin data and emits rejoin_data_set signal.
func set_rejoin_data(data: Array) -> void:
	rejoin_data = data
	emit_signal("rejoin_data_set")

# Returns true if the player's teammate is directly next to the player in one
# of the cardinal directions.
func is_next_to_teammate() -> bool:
	if not teammate_data.has("location"):
		return false
	return (location - teammate_data.location).is_normalized()

# Returns the number of working workers. 
func get_amount_of_working_workers() -> int:
	var working_count: int = 0
	for worker in workers.values():
		if worker.is_working:
			working_count += 1
	return working_count

# Returns the number of non-working/available workers. 
func get_amount_of_available_workers() -> int:
	var available_count: int = 0
	for worker in workers.values():
		if not worker.is_working:
			available_count += 1
	return available_count

# Set all the player data to their default values.
func reset_data() -> void:
	id = 0
	start_name_options = []
	end_name_options = []
	start_name = ""
	end_name = ""
	join_order = -1
	team_index = Enums.Team.NOT_SELECTED
	team_role = Enums.Role.NOT_SELECTED
	teammate_data = {}
	is_exchanging = false
	location = Vector2.ZERO
	location_type = Enums.LocationType.FREE_SPACE
	resources = {
		Enums.Resource.MONEY: 0,
		Enums.Resource.HONEY: 0,
		Enums.Resource.ICE: 0,
		Enums.Resource.LEAVES: 0,
		Enums.Resource.CARROTS: 0,
		Enums.Resource.CHEESE: 0,
	}
	workers = {}
	rejoin_data = []


func _simulate_working_worker_progress(delta: float) -> void:
	# Simulate the progress the workers are doing. The actual progress is
	# calculated in game projected but in to not constantly call for updates
	# simulating here should be close enough, doesn't need to be 100% accurate.
	if not location_data.has("working_workers"):
		return
	for worker in location_data.working_workers:
		if not worker.empty() and worker.is_working:
			worker.curr_work_completed += worker.work_speed * delta

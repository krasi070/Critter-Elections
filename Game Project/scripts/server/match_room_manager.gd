extends Node
# Deals with the room state and handles the players within the room.

signal created_room(key)
signal closed_room
signal updated_players(players)
signal game_started
signal restarted_game
signal requested_teammate_exchange(player_id)
signal cancelled_teammate_exchange(player_id)
signal requested_character_speech(player_id)
signal requested_different_teams
signal room_master_pressed_continued

# Various room data.
var room_key: String = ""
var team_names: Array
var team_colors: Array
var allowed_number_of_teams: int
var players: Dictionary = {}
var teams: Dictionary = {}
var is_showing_predictions: bool = false
var can_continue_from_predictions: bool = false
var curr_round: int = 0

func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	_connect_signals()

# Sends create_room request to network master.
func send_create_room_request() -> void:
	rpc_id(Server.NETWORK_MASTER_ID, "create_room")

# If room_key is set, sends close_room request to network master.
func send_close_room_request() -> void:
	if room_key == "":
		return
	rpc_id(Server.NETWORK_MASTER_ID, "close_room", room_key)

# If room_key is set, sends send_room_disconnected_to_players request to network master.
func send_disconnect_players_request() -> void:
	if room_key == "":
		return
	rpc_id(Server.NETWORK_MASTER_ID, "send_room_disconnected_to_players", room_key)

# Sets the room key. Emits created_room signal.
puppet func set_room_key(key: String) -> void:
	print("ROOM CLIENT: Got room key! Key is %s" % key)
	room_key = key
	emit_signal("created_room", room_key)

# Resets data and emits closed_room signal.
remote func remove_room_data() -> void:
	print("ROOM CLIENT: Room %s closed!" % room_key)
	reset()
	MapData.reset()
	WorldLevelStats.reset()
	emit_signal("closed_room")

# Updates team and player data. Calls update_players within.
puppet func update_room(room_data: Dictionary) -> void:
	print("ROOM CLIENT: Update room team number to %d!" % room_data.allowed_number_of_teams)
	team_names = room_data.team_names
	team_colors = room_data.team_colors
	allowed_number_of_teams = room_data.allowed_number_of_teams
	update_players(room_data.players)

# Updates player data and sends update_player_data and update_teams signal to
# players in the room. Emits updated_players signal.
puppet func update_players(updated_players: Dictionary) -> void:
	players = updated_players
	print("ROOM CLIENT: Updated players!")
	var team_data: Array = _create_team_data()
	for player_id in players.keys():
		if not players[player_id].is_disconnected:
			rpc_id(players[player_id].id, "update_player_data", players[player_id])
			rpc_id(players[player_id].id, "update_teams", team_data, allowed_number_of_teams, players[player_id].team, players[player_id].role)
		MapData.update_player_visuals(player_id)
	emit_signal("updated_players", players.values())

# Updates players data and location of the rejoined player after a successful rejoin to the room.
puppet func update_after_player_rejoin(rejoined_player_id: int, updated_players: Dictionary) -> void:
	update_players(updated_players)
	send_player_info_to_teammate(rejoined_player_id)
	var teammate_id: int = _get_player_teammate_id(rejoined_player_id)
	if teammate_id > 0:
		send_player_info_to_teammate(teammate_id)
	MovementManager.update_player_location_data(rejoined_player_id)
	if is_showing_predictions:
		print("predictions")
		rpc_id(players[rejoined_player_id].id, "enter_predictions_state", curr_round, Settings.number_of_rounds)
		if can_continue_from_predictions:
			rpc_id(players[rejoined_player_id].id, "ready_to_continue")
	elif get_tree().paused:
		rpc_id(players[rejoined_player_id].id, "pause")

# Updates specified player's data and sends update_player_data request to 
# that player. Emits updated_players signal.
func update_player(player_id: int, data: Dictionary = {}) -> void:
	if not data.empty():
		players[player_id] = data
	print("ROOM CLIENT: Updated player %d!" % player_id)
	rpc_id(Server.NETWORK_MASTER_ID, "update_room_players", room_key, players)
	if not players[player_id].is_disconnected:
		rpc_id(players[player_id].id, "update_player_data", players[player_id])
	emit_signal("updated_players", players.values())

# Sends the given player info about their teammate.
func send_player_info_to_teammate(player_id: int) -> void:
	var teammmate_id: int = _get_player_teammate_id(player_id)
	if players.has(teammmate_id) and not players[teammmate_id].is_disconnected:
		rpc_id(players[teammmate_id].id, "set_teammate_data", players[player_id])

# Emits requested_character_speech signal.
remote func show_character_speech() -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	emit_signal("requested_character_speech", player_id)

# Places a player's worker in a gathering spot place. Updates player.
# Requests update_location_data to player.
remote func place_worker(worker_id: String, space_index: int) -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var player_location: Vector2 = MapData.players[player_id].location
	var gathering_spot: Node2D = MapData.map[player_location].map_object
	gathering_spot.set_worker(players[player_id].workers[worker_id], space_index)
	update_player(player_id)
	if not players[player_id].is_disconnected:
		rpc_id(player_network_id, "update_location_data", gathering_spot.get_data())

# Hires worker at the given rank from the hiring spot the player is on.
# Updates player. Reqests update_location_data to player.
remote func hire_worker_at_rank(rank: int) -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var player_location: Vector2 = MapData.players[player_id].location
	var hiring_spot: Node2D = MapData.map[player_location].map_object
	var hired_worker: Dictionary = hiring_spot.hire_worker_at_rank(player_id, rank)
	if hired_worker.empty():
		return
	_add_hired_worker_to_player(player_id, hired_worker)
	update_player(player_id)
	if not players[player_id].is_disconnected:
		rpc_id(player_network_id, "update_location_data", hiring_spot.get_data())

# Calls MapData function to upgrade the gathering spot the player who
# made this request is currently on.
remote func upgrade_gathering_spot() -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var player_location: Vector2 = MapData.players[player_id].location
	MapData.map[player_location].map_object.upgrade(player_id)

# Informs the event map object that a player wishes to pay as the
# first visitor.
remote func pay_as_first_visitor(payment_amount: int) -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var player_location: Vector2 = MapData.players[player_id].location
	if is_instance_valid(MapData.map[player_location].map_object):
		MapData.map[player_location].map_object.pay_as_first_visitor(player_id, payment_amount)

# Informs the event map object that a player wishes to pay as the
# second visitor.
remote func pay_as_second_visitor(payment_amount: int) -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var player_location: Vector2 = MapData.players[player_id].location
	if is_instance_valid(MapData.map[player_location].map_object):
		MapData.map[player_location].map_object.pay_as_second_visitor(player_id, payment_amount)

remote func refuse_offer() -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var player_location: Vector2 = MapData.players[player_id].location
	MapData.map[player_location].map_object.add_to_refused(player_id)

# Sets is_exchanging value on player that sent the request to true. If both
# players in that team are exchanging, the campaigner gives all non money and non
# worker related resources to the campagner and the campaigner gives all of their
# money to the gatherer.
remote func exchange_teammate_resources() -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	var teammate_id: int = _get_player_teammate_id(player_id)
	players[player_id].is_exchanging = true
	update_player(player_id)
	if teammate_id <= 0:
		return
	if not (players[player_id].is_exchanging and players[teammate_id].is_exchanging):
		emit_signal("requested_teammate_exchange", player_id)
		return
	var campaigner_id: int = player_id
	if players[teammate_id].role == Enums.Role.CAMPAIGNER:
		campaigner_id = teammate_id
	var gatherer_id: int = player_id
	if players[teammate_id].role == Enums.Role.GATHERER:
		gatherer_id = teammate_id
	_give_resources_from_to(gatherer_id, campaigner_id, Enums.Resource.ICE)
	_give_resources_from_to(gatherer_id, campaigner_id, Enums.Resource.CHEESE)
	_give_resources_from_to(gatherer_id, campaigner_id, Enums.Resource.LEAVES)
	_give_resources_from_to(campaigner_id, gatherer_id, Enums.Resource.MONEY)
	players[campaigner_id].is_exchanging = false
	emit_signal("cancelled_teammate_exchange", campaigner_id)
	players[gatherer_id].is_exchanging = false
	emit_signal("cancelled_teammate_exchange", gatherer_id)
	update_player(campaigner_id)
	update_player(gatherer_id)

# Sets the player's is_exchaning value to false and updates them on the change.
remote func cancel_exchange() -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = get_player_id_by_network_id(player_network_id)
	players[player_id].is_exchanging = false
	emit_signal("cancelled_teammate_exchange", player_id)
	update_player(player_id)

# Sends update_location_data to specified player.
func update_location_player_is_on(player_id: int, location_data: Dictionary) -> void:
	if not players[player_id].is_disconnected:
		rpc_id(players[player_id].id, "update_location_data", location_data)

# Sets role specific data to players and sends update request to players and server. 
# Emits game_started signal. Sends start_game request to players in the room.
remote func start_game() -> void:
	_set_teams()
	_set_initial_worker_data_for_gather()
	emit_signal("game_started")
	for player_id in players.keys():
		rpc_id(players[player_id].id, "update_player_data", players[player_id])
		if _get_player_teammate_id(player_id) > 0:
			send_player_info_to_teammate(player_id)
		if not players[player_id].is_disconnected:
			rpc_id(players[player_id].id, "start_game", player_id)
	rpc_id(Server.NETWORK_MASTER_ID, "start_game", room_key, players)

# Resets the state of the game so that a new game can be started with the same teams.
remote func restart_with_same_teams() -> void:
	_reset_round_values()
	_reset_players_data(false)
	_set_initial_worker_data_for_gather()
	emit_signal("restarted_game")
	for player_id in players.keys():
		rpc_id(players[player_id].id, "update_player_data", players[player_id])
		if _get_player_teammate_id(player_id) > 0:
			send_player_info_to_teammate(player_id)
		if not players[player_id].is_disconnected:
			rpc_id(players[player_id].id, "restart_game")
	rpc_id(Server.NETWORK_MASTER_ID, "start_game", room_key, players)

# Resets the state of the game so that a new game can be started with the same
# teams but the players' roles are swapped.
remote func restart_with_swapped_roles() -> void:
	_reset_round_values()
	_reset_players_data(true)
	_set_initial_worker_data_for_gather()
	emit_signal("restarted_game")
	var team_data: Array = _create_team_data()
	for player_id in players.keys():
		rpc_id(players[player_id].id, "update_player_data", players[player_id])
		rpc_id(players[player_id].id, "update_teams", team_data, allowed_number_of_teams, players[player_id].team, players[player_id].role)
		if _get_player_teammate_id(player_id) > 0:
			send_player_info_to_teammate(player_id)
		if not players[player_id].is_disconnected:
			rpc_id(players[player_id].id, "restart_game")
	rpc_id(Server.NETWORK_MASTER_ID, "start_game", room_key, players)

# Returns to room creation and sends go_back_to_room_creation request to the server
# and go_back_to_team_selection request to the players. Emits requested_different_teams signal.
remote func restart_with_different_teams() -> void:
	teams = {}
	_reset_round_values()
	_reset_players_data(false, true)
	rpc_id(Server.NETWORK_MASTER_ID, "go_back_to_room_creation", room_key, players)
	for player_id in players.keys():
		var network_id: int = players[player_id].id
		if not players[player_id].is_disconnected:
			rpc_id(network_id, "update_player_data", players[player_id])
			rpc_id(network_id, "go_back_to_team_selection")
	emit_signal("requested_different_teams")

# Emits room_master_pressed_continued signal.
remote func continue_game_after_predictions() -> void:
	is_showing_predictions = false
	emit_signal("room_master_pressed_continued")

# Returns the player ID corresponding to the given network ID. If
# not found, returns 0.
func get_player_id_by_network_id(network_id: int) -> int:
	for player_id in players.keys():
		if players[player_id].id == network_id:
			return player_id
	return 0

# Returns the team index of the given player.
func get_team_by_player_id(player_id: int) -> int:
	for team in teams.keys():
		for role in teams[team].keys():
			if teams[team][role] == player_id:
				return team
	return Enums.Team.NOT_SELECTED

# Prints error.
puppet func print_error(error_str: String) -> void:
	print("ROOM CLIENT: ", error_str)

# Sends enter_predictions_state request to every connected player in the room.
func inform_players_of_predictions_enter(_curr_round: int) -> void:
	is_showing_predictions = true
	can_continue_from_predictions = false
	curr_round = _curr_round
	_rpc_every_connected_player("enter_predictions_state", [curr_round, Settings.number_of_rounds])

# Sends read_to_continue request to every connected player in the room.
func inform_players_of_predictions_over() -> void:
	can_continue_from_predictions = true
	_rpc_every_connected_player("ready_to_continue")

# Sends continue_after_predictions request to every connected player in the room.
func inform_players_to_continue_after_predictions() -> void:
	_rpc_every_connected_player("continue_after_predictions")

# Sends pause request to every connected player in the room.
func pause_players() -> void:
	_rpc_every_connected_player("pause")

# Sends unpause request to every connected player in the room.
func unpause_players() -> void:
	_rpc_every_connected_player("unpause")

# Sets all the room data to its default values.
func reset() -> void:
	room_key = ""
	team_names = []
	team_colors = []
	teams = {}
	allowed_number_of_teams = 0
	players = {}
	_reset_round_values()


func _reset_round_values() -> void:
	curr_round = 0
	is_showing_predictions = false
	can_continue_from_predictions = false


func _connect_signals() -> void:
	MovementManager.connect("player_moved", self, "_movement_manager_player_moved")
	DebugHelper.connect("requested_give_command", self, "_debug_helper_requested_give_command")
	DebugHelper.connect("requested_disconnect_player", self, "_debug_helper_requsted_disconnect_player")
	DebugHelper.connect("requested_quick_start", self, "_debug_helper_requested_quick_start")


func _create_team_data() -> Array:
	var data: Array = []
	for team_index in range(team_names.size()):
		data.append({
			"name": team_names[team_index],
			"index": team_index,
			"color": team_colors[team_index],
			"role_a": _get_player_name_in_team_and_role(team_index, Enums.Role.CAMPAIGNER),
			"role_b": _get_player_name_in_team_and_role(team_index, Enums.Role.GATHERER),
		})
	data.append({
		"index": Enums.Team.NOT_SELECTED,
		"players": _get_players_with_unselected_team(),
	})
	return data


func _set_teams() -> void:
	for team_name in Enums.Team.keys():
		if Enums.Team[team_name] >= 0:
			teams[Enums.Team[team_name]] = {}
	for id in players.keys():
		teams[players[id].team][players[id].role] = id
	for team_index in teams.keys():
		if teams[team_index].empty():
			teams.erase(team_index)


func _reset_players_data(swap_roles: bool, reset_teams: bool = false) -> void:
	for player_id in players.keys():
		var player: Dictionary = players[player_id]
		if reset_teams:
			player.team = Enums.Team.NOT_SELECTED
			player.role = Enums.Role.NOT_SELECTED
		if swap_roles:
			if player.role == Enums.Role.CAMPAIGNER:
				player.role = Enums.Role.GATHERER
			elif player.role == Enums.Role.GATHERER:
				player.role = Enums.Role.CAMPAIGNER
		player.location = Vector2(-1, -1)
		for res in player.resources.keys():
			player.resources[res] = 0
		player.workers = {}
		player.is_exchanging = false


func _rpc_every_connected_player(func_name: String, args: Array = []) -> void:
	for player in players.values():
		if not player.is_disconnected:
			match args.size():
				0:
					rpc_id(player.id, func_name)
				1:
					rpc_id(player.id, func_name, args[0])
				2:
					rpc_id(player.id, func_name, args[0], args[1])
				3:
					rpc_id(player.id, func_name, args[0], args[1], args[2])
				4:
					rpc_id(player.id, func_name, args[0], args[1], args[2], args[3])
				5:
					rpc_id(player.id, func_name, args[0], args[1], args[2], args[3], args[4])


func _get_player_teammate_id(player_id: int) -> int:
	var player_team: int = players[player_id].team
	var player_role: int = players[player_id].role
	var teammate_role: int = Enums.Role.NOT_SELECTED
	if player_role == Enums.Role.CAMPAIGNER:
		teammate_role = Enums.Role.GATHERER
	else:
		teammate_role = Enums.Role.CAMPAIGNER
	if not teams[player_team].has(teammate_role):
		return -1
	return teams[player_team][teammate_role]


func _get_players_with_unselected_team() -> Array:
	var unselected_team_players: Array = []
	for player in players.values():
		if player.team == Enums.Team.NOT_SELECTED:
			unselected_team_players.append(player.name)
	return unselected_team_players


func _get_player_name_in_team_and_role(team: int, role: int) -> String:
	for player in players.values():
		if player.team == team and player.role == role:
			return player.name
	return "free"


func _give_resources_from_to(from_id: int, to_id: int, res_type: int) -> void:
	players[to_id].resources[res_type] += players[from_id].resources[res_type]
	players[from_id].resources[res_type] = 0


func _add_hired_worker_to_player(player_id: int, hired_worker: Dictionary) -> void:
	hired_worker.employer_id = player_id
	hired_worker.team_index = players[player_id].team
	players[player_id].workers[hired_worker.id] = hired_worker


func _add_worker_to_player(player_id: int, worker_type: int) -> void:
	var new_worker: Dictionary = \
		WorkerHelper.get_duplicated_worker_data_by_type(worker_type)
	new_worker.employer_id = player_id
	new_worker.team_index = players[player_id].team
	new_worker.id = str(player_id) + str(players[player_id].workers.size())
	players[player_id].workers[new_worker.id] = new_worker


func _set_initial_worker_data_for_gather() -> void:
	for id in players.keys():
		if players[id].role == Enums.Role.GATHERER:
			for _i in range(3):
				_add_worker_to_player(id, Enums.WorkerType.NINE_TO_FIVE)


func _get_player_id_by_team_and_role(team_id: int, team_role: String) -> int:
	for id in players.keys():
		if players[id].team == team_id and players[id].role == Enums.Role[team_role]:
			return id
	return 0


func _movement_manager_player_moved(player_id: int, new_location: Vector2) -> void:
	players[player_id].location = new_location
	rpc_id(Server.NETWORK_MASTER_ID, "update_room_players", room_key, players)
	if _get_player_teammate_id(player_id) > 0:
		send_player_info_to_teammate(player_id)


func _debug_helper_requested_give_command(team_id: int, team_role: String, res_type: String, amount: int) -> void:
	var player_id: int = _get_player_id_by_team_and_role(team_id, team_role)
	if player_id == 0:
		DebugHelper.write_line("Invalid args! There is no player in team %d with role %s!" % \
			[team_id, team_role])
		return
	if not Enums.Resource.has(res_type):
		DebugHelper.write_line("Invalid args! There is no resource %s!" % res_type)
		return
	players[player_id].resources[Enums.Resource[res_type]] += amount
	update_player(player_id)


func _debug_helper_requsted_disconnect_player(team: int, team_role: String) -> void:
	var player_id: int = _get_player_id_by_team_and_role(team, team_role)
	if player_id == 0:
		DebugHelper.write_line("Invalid args! There is no player in team %d with role %s!" % \
			[team, team_role])
		return
	if not players[player_id].is_disconnected:
		rpc_id(players[player_id].id, "leave_room")
		players[player_id].is_disconnected = true
		update_player(player_id)


func _debug_helper_requested_quick_start(amount: int) -> void:
	for player_id in players.keys():
		for res in players[player_id].resources.keys():
			players[player_id].resources[res] += amount
			update_player(player_id)

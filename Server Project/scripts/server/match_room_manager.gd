extends Node
# Deals with management of rooms and the players in those rooms.

const INVALID_ROOM_KEY_ERROR_MSG_FORMAT: String = "Room %s not found!"
const ROOM_IS_ACTIVE_ERROR_MSG_FORMAT: String = "Game in room %s has already started!"
const ROOM_IS_FULL_ERROR_MSG_FORMAT: String = "Room %s has reached the player limit!"

const LabelData = preload("res://scripts/label_data.gd")

# Number of allowed runs to run at the same time on the server.
const MAX_ROOMS: int = 10
# Number of allowed players in a single room.
const MAX_PLAYERS_PER_ROOM: int = 8
# The length of the room key.
const ROOM_KEY_LENGTH: int = 4
# The symbols used for room key generation.
const ROOM_KEY_ALPHABET: Array = [
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
]

# The number of name options shown to players.
const NAME_SELECTION_AMOUNT: int = 3
# The minimum amount of full teams required to play a game.
const MIN_TEAMS_REQUIRED: int = 2
# The maximum amount of full teams permitted to play in a single room.
const MAX_TEAMS_PERMITTED: int = 4

# Room related data.
var active_rooms: int
var rooms: Dictionary = {}
var room_key_by_id: Dictionary = {}
var rejoin_candidates_by_room: Dictionary = {}

func _ready() -> void:
	randomize()
	reset()

# Allocates room key for a new room and sends the new room data to the peer
# that requested the room creation.
master func create_room() -> void:
	var sender_id: int = get_tree().get_rpc_sender_id()
	print("SERVER: Create room request received from %d" % sender_id)
	if active_rooms == MAX_ROOMS:
		print("SERVER: Room limit reached! Cannot create more rooms!")
		rpc_id(sender_id, "print_error", "Room limit reached! Cannot create more rooms!")
		return
	var room_key: String = _handle_room_creation(sender_id)
	print("SERVER: Room %s created!" % room_key)
	rpc_id(sender_id, "set_room_key", room_key)
	rpc_id(sender_id, "update_room", rooms[room_key])

# Deletes room data in and sends back a request for the original request sender
# to do the same.
master func close_room(room_key: String) -> void:
	if not rooms.has(room_key):
		return
	var room_id: int = rooms[room_key].master
	print("SERVER: Close room %s request received from %d" % [room_key, room_id])
	# No longer needed to manually close the room, room always disconnects on
	# closing on its own.
	#_handle_room_closing(room_key)
	rpc_id(room_id, "remove_room_data")

# Creates player data in specified room and sends back the room peer id to the
# to the player peer that requested the creation. Sends update_room request to the
# specfied room as well. Also sends rejoin data on reconnect attempt.
master func join_room(room_key: String) -> void:
	var sender_id: int = get_tree().get_rpc_sender_id()
	if not rooms.has(room_key):
		rpc_id(sender_id, "inform_of_denied_request", INVALID_ROOM_KEY_ERROR_MSG_FORMAT % room_key)
		return
	print("SERVER: Player %d wants to join room %s" % [sender_id, room_key])
	if not rooms[room_key].has_started:
		if not _add_player_to_room(sender_id, room_key):
			return
		rpc_id(sender_id, "set_player_room_data", rooms[room_key].master, rooms[room_key].players[sender_id])
		rpc_id(rooms[room_key].master, "update_room", rooms[room_key])
	else:
		var disconnected_players: Array = _get_disconnected_players_data(room_key)
		if disconnected_players.empty():
			rpc_id(sender_id, "inform_of_denied_request", ROOM_IS_ACTIVE_ERROR_MSG_FORMAT % room_key)
			return
		rejoin_candidates_by_room[room_key].append(sender_id)
		room_key_by_id[sender_id] = room_key
		rpc_id(sender_id, "set_rejoin_room_data", disconnected_players, LabelData.TEAM_NAMES)

# Resets the player data after a successful reconnect.
master func rejoin_player_in_room(room_key: String, player_name: String) -> void:
	var sender_id: int = get_tree().get_rpc_sender_id()
	print("SERVER: Player %d wants to rejoin room %s as %s" % [sender_id, room_key, player_name])
	var original_id: int = _get_player_id_by_player_name(room_key, player_name)
	if original_id == 0 or not rooms[room_key].players[original_id].is_disconnected:
		return
	rooms[room_key].players[original_id].join_order = _get_new_mid_game_join_order(room_key)
	rooms[room_key].players[original_id].id = sender_id
	rooms[room_key].players[original_id].is_disconnected = false
	rejoin_candidates_by_room[room_key].erase(sender_id)
	room_key_by_id[sender_id] = room_key
	rpc_id(sender_id, "set_player_room_data", rooms[room_key].master, rooms[room_key].players[original_id])
	rpc_id(rooms[room_key].master, "update_after_player_rejoin", original_id, rooms[room_key].players)
	_update_rejoin_candidates(room_key)

# Sets player name and sends back confirmation to the player with the name.
# Sends update_players request to the specfied room as well.
master func set_player_name(room_key: String, p_name: String) -> void:
	var sender_id: int = get_tree().get_rpc_sender_id()
	print("SERVER: Player %d wants to set name to %s" % [sender_id, p_name])
	if not rooms.has(room_key) or not rooms[room_key].players.has(sender_id):
		print("SERVER: Player %d sent invalid request to room %s" % [sender_id, room_key])
		return
	rooms[room_key].players[sender_id].name = p_name
	rpc_id(sender_id, "set_name", p_name)
	rpc_id(rooms[room_key].master, "update_players", rooms[room_key].players)

# Sets player team and role and sends back confirmation to that player.
# Sends update_players request to the specfied room as well.
master func set_player_team_role(room_key: String, team_index: int, team_role: int) -> void:
	var sender_id: int = get_tree().get_rpc_sender_id()
	print("SERVER: Player %d wants to be role %d in team %d" % [sender_id, team_role, team_index])
	if not rooms.has(room_key) or not rooms[room_key].players.has(sender_id):
		print("SERVER: Player %d sent invalid request to room %s" % [sender_id, room_key])
		return
	if _is_role_in_team_taken(room_key, team_index, team_role):
		print("SERVER: Player %d sent invalid request to room %s" % [sender_id, room_key])
		return
	rooms[room_key].players[sender_id].team = team_index
	rooms[room_key].players[sender_id].role = team_role
	rpc_id(rooms[room_key].master, "update_players", rooms[room_key].players)

# Checks if disconnected peer is a player or a room.
# If disconnected peer is a room, disassociates players in that room from it and
# deletes room data.
# If disconnected peer is a player, deletes player data and sends update_room
# request to the disconnected player's room.
# If disconnected peer is a player trying to rejoin, forget them.
func handle_disconnect(disconnected_peer_id: int) -> void:
	if not room_key_by_id.has(disconnected_peer_id):
		return
	var room_key: String = room_key_by_id[disconnected_peer_id]
	if _is_peer_a_room(disconnected_peer_id):
		send_room_disconnected_to_players(room_key)
		_handle_room_closing(room_key)
	elif _is_peer_trying_to_rejoin(disconnected_peer_id):
		rejoin_candidates_by_room[room_key].erase(disconnected_peer_id)
		room_key_by_id.erase(disconnected_peer_id)
	elif _is_peer_a_player(disconnected_peer_id):
		send_player_disconnected_from_room(disconnected_peer_id, room_key)

# Sends a leave_room request to players in specified room.
master func send_room_disconnected_to_players(room_key: String) -> void:
	print("SERVER: Room %s disconnected" % room_key)
	for player_id in rooms[room_key].players.keys():
		if not rooms[room_key].players[player_id].is_disconnected:
			rpc_id(rooms[room_key].players[player_id].id, "leave_room")
			print("SERVER: Sent disconnect order to player %d" % player_id)

# Deletes player data if game has not started and sends update_room request to 
# the disconnected player's room. If game has started sets is_disconnected
# property of the player to true.
master func send_player_disconnected_from_room(player_network_id: int, room_key: String) -> void:
	var player_id: int = _get_player_id_by_network_id(room_key, player_network_id)
	if not rooms[room_key].players.has(player_id) or not room_key_by_id.has(player_network_id):
		return
	print("SERVER: Player %d disconnected" % player_id)
	_deincrement_join_orders(room_key, rooms[room_key].players[player_id].join_order)
	if not rooms[room_key].has_started:
		rooms[room_key].start_names.append_array(rooms[room_key].players[player_id].start_names)
		rooms[room_key].end_names.append_array(rooms[room_key].players[player_id].end_names)
		rooms[room_key].players.erase(player_id)
		_set_allowed_number_of_teams_for_room(room_key)
	else:
		rooms[room_key].players[player_id].is_disconnected = true
		_update_rejoin_candidates(room_key)
		room_key_by_id.erase(player_network_id)
	rpc_id(rooms[room_key].master, "update_room", rooms[room_key])

# Forgets the rejoin request from the sender.
master func forget_player_rejoin(room_key: String) -> void:
	if not rooms.has(room_key):
		return
	var sender_id: int = get_tree().get_rpc_sender_id()
	rejoin_candidates_by_room[room_key].erase(sender_id)
	room_key_by_id.erase(sender_id)

# Updates the local state of the players in the specified room.
master func update_room_players(room_key: String, players: Dictionary) -> void:
	print("SERVER: Room %s wants to update players on server" % room_key)
	rooms[room_key].players = players

# Calls update_room_players and sets the room to the start state.
master func start_game(room_key: String, players: Dictionary) -> void:
	update_room_players(room_key, players)
	rooms[room_key].has_started = true

# Calls update_room_players and sets the room to still not started state.
master func go_back_to_room_creation(room_key: String, players: Dictionary) -> void:
	update_room_players(room_key, players)
	for player_id in rooms[room_key].players.keys():
		if rooms[room_key].players[player_id].is_disconnected:
			room_key_by_id.erase(players[player_id].id)
			rooms[room_key].start_names.append_array(rooms[room_key].players[player_id].start_names)
			rooms[room_key].end_names.append_array(rooms[room_key].players[player_id].end_names)
			rooms[room_key].players.erase(player_id)
			_set_allowed_number_of_teams_for_room(room_key)
	rooms[room_key].has_started = false
	rpc_id(rooms[room_key].master, "update_room", rooms[room_key])

# Sets available_room_keys to all possible room keys and deletes room data.
func reset() -> void:
	active_rooms = 0
	room_key_by_id = {}
	rooms = {}
	rejoin_candidates_by_room = {}


func _generate_room_key() -> String:
	var room_key: String = ""
	for _i in range(ROOM_KEY_LENGTH):
		var rand_index: int = randi() % ROOM_KEY_ALPHABET.size()
		room_key += ROOM_KEY_ALPHABET[rand_index]
	return room_key


func _handle_room_creation(room_id: int) -> String:
	var room_key: String = _generate_room_key()
	while rooms.has(room_key):
		room_key = _generate_room_key()
	rooms[room_key] = _get_default_room_data(room_id)
	room_key_by_id[room_id] = room_key
	rejoin_candidates_by_room[room_key] = []
	active_rooms += 1
	return room_key


func _handle_room_closing(room_key: String) -> void:
	for player_id in rooms[room_key].players:
		room_key_by_id.erase(rooms[room_key].players[player_id].id)
	room_key_by_id.erase(rooms[room_key].master)
	rooms.erase(room_key)
	active_rooms -= 1


func _add_player_to_room(player_id: int, room_key: String) -> bool:
	if not rooms.has(room_key):
		print("SERVER: Requested room %s by player %d does not exist!" % [room_key, player_id])
		rpc_id(player_id, "inform_of_denied_request", INVALID_ROOM_KEY_ERROR_MSG_FORMAT % room_key)
		return false
	if rooms[room_key].players.size() >= MAX_PLAYERS_PER_ROOM:
		print("SERVER: Requested room %s by player %d is full!" % [room_key, player_id])
		rpc_id(player_id, "inform_of_denied_request", ROOM_IS_FULL_ERROR_MSG_FORMAT % room_key)
		return false
	if rooms[room_key].has_started:
		print("SERVER: Requested room %s by player %d is already mid-game!" % [room_key, player_id])
		rpc_id(player_id, "inform_of_denied_request", ROOM_IS_ACTIVE_ERROR_MSG_FORMAT % room_key)
		return false
	rooms[room_key].players[player_id] = _get_default_player_data(room_key, player_id)
	room_key_by_id[player_id] = room_key
	_set_allowed_number_of_teams_for_room(room_key)
	print("SERVER: Player %d successfully joined room %s" % [player_id, room_key])
	return true


func _update_rejoin_candidates(room_key: String) -> void:
	for id in rejoin_candidates_by_room[room_key]:
		rpc_id(id, "set_rejoin_room_data", _get_disconnected_players_data(room_key))


func _get_disconnected_players_data(room_key: String) -> Array:
	var disconnected_players: Array = []
	if not rooms.has(room_key):
		return []
	for id in rooms[room_key].players.keys():
		var player: Dictionary = rooms[room_key].players[id]
		if player.is_disconnected:
			disconnected_players.append({
				"name": player.name,
				"id": id,
				"team": player.team,
				"role": player.role,
			})
	return disconnected_players


func _get_player_id_by_player_name(room_key: String, player_name: String) -> int:
	if not rooms.has(room_key):
		return 0
	for id in rooms[room_key].players.keys():
		if rooms[room_key].players[id].name == player_name:
			return id
	return 0


func _get_player_id_by_network_id(room_key: String, player_network_id: int) -> int:
	if not rooms.has(room_key):
		return 0
	for id in rooms[room_key].players.keys():
		if player_network_id == rooms[room_key].players[id].id:
			return id
	return 0


func _get_random_set_from_array(arr: Array, amount: int) -> Array:
	if amount > arr.size():
		print("Asking for more elements than size of array!")
		return []
	var result: Array = []
	arr.shuffle()
	for _i in range(amount):
		result.append(arr.pop_front())
	return result


func _get_default_room_data(room_id: int) -> Dictionary:
	return  {
		"master": room_id,
		"players": {},
		"start_names": LabelData.PLAYER_NAMES.start_names.duplicate(),
		"end_names": LabelData.PLAYER_NAMES.end_names.duplicate(),
		"team_names": LabelData.TEAM_NAMES,
		"team_colors": LabelData.TEAM_COLORS,
		"allowed_number_of_teams": MIN_TEAMS_REQUIRED,
		"has_started": false, 
	}


func _get_default_player_data(room_key: String, player_id: int) -> Dictionary:
	var number_of_players: int = rooms[room_key].players.size()
	return {
		"id": player_id,
		"name": "Player %d" % (number_of_players + 1),
		"start_names": _get_random_set_from_array(rooms[room_key].start_names, NAME_SELECTION_AMOUNT),
		"end_names": _get_random_set_from_array(rooms[room_key].end_names, NAME_SELECTION_AMOUNT),
		"is_disconnected": false,
		"team": Enums.Team.NOT_SELECTED,
		"role": Enums.Role.NOT_SELECTED,
		"join_order": number_of_players,
		"location": Vector2(-1, -1),
		"resources": {
			Enums.Resource.MONEY: 0,
			#Enums.Resource.HONEY: 0,
			Enums.Resource.ICE: 0,
			Enums.Resource.LEAVES: 0,
			#Enums.Resource.CARROTS: 0,
			Enums.Resource.CHEESE: 0,
			Enums.Resource.HONEYCOMB: 0,
		},
		"workers": {},
		"is_exchanging": false,
	}


func _is_role_in_team_taken(room_key: String, team: int, role: int) -> bool:
	if team == Enums.Team.NOT_SELECTED or role == Enums.Role.NOT_SELECTED:
		return false
	for player in rooms[room_key].players.values():
		if player.team == team and player.role == role:
			return true
	return false


func _deincrement_join_orders(room_key: String, from: int) -> void:
	for player in rooms[room_key].players.values():
		if player.join_order >= from:
			player.join_order -= 1


func _get_new_mid_game_join_order(room_key: String) -> int:
	var join_order: int = 0
	for player in rooms[room_key].players.values():
		if not player.is_disconnected:
			join_order += 1
	return join_order


func _set_allowed_number_of_teams_for_room(room_key: String) -> void:
	rooms[room_key].allowed_number_of_teams = clamp(
		ceil(rooms[room_key].players.size() / 2.0),
		MIN_TEAMS_REQUIRED,
		MAX_TEAMS_PERMITTED)


func _is_peer_a_room(peer_id: int) -> bool:
	return peer_id == rooms[room_key_by_id[peer_id]].master


func _is_peer_a_player(peer_id: int) -> bool:
	if not room_key_by_id.has(peer_id):
		return false
	var room_key: String = room_key_by_id[peer_id]
	for player in rooms[room_key].players.values():
		if player.id == peer_id:
			return true
	return false


func _is_peer_trying_to_rejoin(peer_id: int) -> bool:
	for candidates in rejoin_candidates_by_room.values():
		if candidates.has(peer_id):
			return true
	return false

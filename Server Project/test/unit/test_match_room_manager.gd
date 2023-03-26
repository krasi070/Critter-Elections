extends GutTest

func before_each() -> void:
	pass


func after_each() -> void:
	MatchRoomManager.reset()


func test_handle_room_creation() -> void:
	var room_id: int = 1000
	var active_rooms_before: int = MatchRoomManager.active_rooms
	var rooms_before_creation: int = MatchRoomManager.rooms.size()
	var room_key: String = MatchRoomManager._handle_room_creation(room_id)
	assert_eq(
		room_key.length(), 
		MatchRoomManager.ROOM_KEY_LENGTH, 
		"Room key length expected to be of length %d!" % MatchRoomManager.ROOM_KEY_LENGTH)
	assert_eq(
		MatchRoomManager.active_rooms, 
		active_rooms_before + 1, 
		"Did not increase active rooms count!")
	assert_eq(
		MatchRoomManager.rooms.size(), 
		rooms_before_creation + 1, 
		"Room was not added to the rooms dictionary!")


func test_handle_room_closing() -> void:
	var room_id: int = 1000
	var room_key: String = MatchRoomManager._handle_room_creation(room_id)
	var active_rooms_before: int = MatchRoomManager.active_rooms
	MatchRoomManager._handle_room_closing(room_key)
	assert_eq(
		MatchRoomManager.rooms.size(), 
		0, 
		"Expected no rooms to be present!")
	assert_eq(
		MatchRoomManager.active_rooms, 
		active_rooms_before - 1, 
		"Did not decrease active rooms count!")


func test_add_player_to_room() -> void:
	var player_id: int = 2000
	_set_dummy_room_data(1)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var was_added: bool = MatchRoomManager._add_player_to_room(player_id, room_key)
	assert_true(was_added, "Player was not successfully added!")
	assert_eq(
		MatchRoomManager.rooms[room_key].players.size(),
		1,
		"Player was not added to the room!")


func test_player_default_data() -> void:
	var players_in_room: int = 3
	_set_dummy_room_data(1, players_in_room)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var player_id: int = 2000
	var player_data: Dictionary = MatchRoomManager._get_default_player_data(room_key, player_id)
	assert_eq(
		player_data.name,
		"Player %d" % (players_in_room + 1),
		"Player default name is incorrect!")
	assert_eq(
		player_data.id,
		player_id,
		"Player ID is not set correctly!")
	assert_false(
		player_data.is_disconnected,
		"Player is_disconnected field is not set to false by default!")
	assert_eq(
		player_data.team,
		Enums.Team.NOT_SELECTED,
		"Player team is not set to not selected by default!")
	assert_eq(
		player_data.role,
		Enums.Role.NOT_SELECTED,
		"Player role is not set to not selected by default!")
	assert_eq(
		player_data.join_order,
		players_in_room,
		"Player join order was not set correctly!")
	assert_eq(
		player_data.location,
		Vector2(-1, -1),
		"Player location was not set as expected!")
	assert_eq(
		player_data.resources.size(),
		5,
		"Player has more or less resource types than expected!")
	assert_eq(
		player_data.workers.size(),
		0,
		"Player should start with zero workers by default!")
	assert_false(
		player_data.is_exchanging,
		"Player should bo be exchanging by default!")


func test_update_room_players() -> void:
	_set_dummy_room_data(3)
	var player_id: int = 2000
	var room_key: String = MatchRoomManager.rooms.keys()[1]
	MatchRoomManager._add_player_to_room(player_id, room_key)
	var old_players: Dictionary = \
		MatchRoomManager.rooms[room_key].players.duplicate(true)
	var updated_players: Dictionary = \
		MatchRoomManager.rooms[room_key].players.duplicate(true)
	updated_players[player_id].name = "New Name"
	updated_players[player_id].team = Enums.Team.TEAM_B
	updated_players[player_id].role = Enums.Role.GATHERER
	updated_players[player_id].resources[Enums.Resource.MONEY] = 120
	MatchRoomManager.update_room_players(room_key, updated_players)
	assert_eq(
		MatchRoomManager.rooms[room_key].players,
		updated_players,
		"Players dictionary reference was not changed!")
	assert_ne(
		MatchRoomManager.rooms[room_key].players[player_id].name,
		old_players[player_id].name,
		"Player's old and new name are the same!")
	assert_ne(
		MatchRoomManager.rooms[room_key].players[player_id].team,
		old_players[player_id].team,
		"Player's old and new team are the same!")
	assert_ne(
		MatchRoomManager.rooms[room_key].players[player_id].role,
		old_players[player_id].role,
		"Player's old and new role are the same!")
	assert_ne(
		MatchRoomManager.rooms[room_key].players[player_id].resources[Enums.Resource.MONEY],
		old_players[player_id].resources[Enums.Resource.MONEY],
		"Player's money didn't update!")


func test_is_role_in_team_taken() -> void:
	_set_dummy_room_data(1, 3)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var player_one_id: int = MatchRoomManager.rooms[room_key].players.keys()[0]
	MatchRoomManager.rooms[room_key].players[player_one_id].team = \
		Enums.Team.TEAM_A
	MatchRoomManager.rooms[room_key].players[player_one_id].role = \
		Enums.Role.GATHERER
	var is_team_a_gatherer_taken: bool = \
		MatchRoomManager._is_role_in_team_taken(room_key,
			Enums.Team.TEAM_A,
			Enums.Role.GATHERER)
	var is_team_a_campaigner_taken: bool = \
		MatchRoomManager._is_role_in_team_taken(room_key,
			Enums.Team.TEAM_A,
			Enums.Role.CAMPAIGNER)
	var is_not_selected_taken: bool = \
		MatchRoomManager._is_role_in_team_taken(room_key,
			Enums.Team.NOT_SELECTED,
			Enums.Role.NOT_SELECTED)
	assert_true(is_team_a_gatherer_taken, "Gatherer role in Team A should not be available!")
	assert_false(is_team_a_campaigner_taken, "Campaigner role in Team A should be available!")
	assert_false(is_not_selected_taken, "Not selected roles should always be available!")


func test_handle_rejoin_candidate_disconnect() -> void:
	_set_dummy_room_data(1)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var rejoin_peer_id: int = 1000
	MatchRoomManager.rejoin_candidates_by_room[room_key].append(rejoin_peer_id)
	MatchRoomManager.room_key_by_id[rejoin_peer_id] = room_key
	MatchRoomManager.handle_disconnect(rejoin_peer_id)
	assert_eq(
		MatchRoomManager.rejoin_candidates_by_room[room_key].size(),
		0,
		"Rejoin candidate still present after disconnect!")


func test_deincrement_join_orders() -> void:
	_set_dummy_room_data(1, 5)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var player_three_id: int = MatchRoomManager.rooms[room_key].players.keys()[2]
	var player_four_id: int = MatchRoomManager.rooms[room_key].players.keys()[3]
	var player_five_id: int = MatchRoomManager.rooms[room_key].players.keys()[4]
	MatchRoomManager._deincrement_join_orders(room_key, 2)
	assert_eq(
		MatchRoomManager.rooms[room_key].players[player_three_id].join_order,
		1,
		"Player 3's join order should be 1!")
	assert_eq(
		MatchRoomManager.rooms[room_key].players[player_four_id].join_order,
		2,
		"Player 3's join order should be 2!")
	assert_eq(
		MatchRoomManager.rooms[room_key].players[player_five_id].join_order,
		3,
		"Player 3's join order should be 3!")


func test_start_game() -> void:
	_set_dummy_room_data(1)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	MatchRoomManager.start_game(room_key, {})
	assert_true(
		MatchRoomManager.rooms[room_key].has_started, 
		"Has started flag was not set correctly!")


func test_reset() -> void:
	var number_of_rooms: int = 3
	var number_of_players_per_room: int = 4 
	_set_dummy_room_data(number_of_rooms, number_of_players_per_room)
	assert_eq(
		MatchRoomManager.rooms.size(),
		number_of_rooms,
		"There should be %d rooms!" % number_of_rooms)
	MatchRoomManager.reset()
	assert_eq(
		MatchRoomManager.active_rooms,
		0,
		"There should be 0 active rooms!")
	MatchRoomManager.reset()
	assert_eq(
		MatchRoomManager.room_key_by_id.size(),
		0,
		"There should be no elements in room_key_by_id!")
	assert_eq(
		MatchRoomManager.rooms.size(),
		0,
		"There should be 0 rooms!")
	assert_eq(
		MatchRoomManager.rejoin_candidates_by_room.size(),
		0,
		"There should be no elements in rejoin_candidates_by_room!")


func test_generate_room_key() -> void:
	var key: String = MatchRoomManager._generate_room_key()
	var every_symbol_is_in_the_alphabet: bool = true
	for symbol in key:
		if not MatchRoomManager.ROOM_KEY_ALPHABET.has(symbol):
			every_symbol_is_in_the_alphabet = false
			return
	assert_true(
		every_symbol_is_in_the_alphabet,
		"A symbol in the key was not in the alphabet!")
	assert_eq(
		key.length(),
		MatchRoomManager.ROOM_KEY_LENGTH,
		"Room key length was not %d!" % MatchRoomManager.ROOM_KEY_LENGTH)


func test_get_disconnected_players_data() -> void:
	_set_dummy_room_data(1, 4)
	var required_elements: Array = ["name", "id", "team", "role"]
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var player_one_id: int = MatchRoomManager.rooms[room_key].players.keys()[0]
	MatchRoomManager.rooms[room_key].players[player_one_id].is_disconnected = true
	var disconnected_data: Array = MatchRoomManager._get_disconnected_players_data(room_key)
	assert_eq(
		disconnected_data.size(),
		1,
		"Disconnected data size should be 1!")
	for element in required_elements:
		assert_true(
			disconnected_data[0].has(element),
			"Disconnected data element should have a(n) %s!" % element)


func test_get_default_room_data() -> void:
	var room_id: int = 1000
	var room_data: Dictionary = MatchRoomManager._get_default_room_data(room_id)
	assert_eq(room_data.master, room_id, "Room ID was not set correctly!")
	assert_eq(room_data.players.size(), 0, "There should be no players!")
	assert_eq(room_data.players.size(), 0, "There should be no players!")
	assert_true(room_data.has("start_names"), "start_names field is not present!")
	assert_true(room_data.has("end_names"), "end_names field is not present!")
	assert_true(room_data.has("team_names"), "team_names field is not present!")
	assert_true(room_data.has("team_colors"), "team_colors field is not present!")
	assert_eq(
		room_data.allowed_number_of_teams,
		MatchRoomManager.MIN_TEAMS_REQUIRED,
		"allowed_number_of_teams shoulf be %d!" % MatchRoomManager.MIN_TEAMS_REQUIRED)
	assert_false(room_data.has_started, "Game in room should not have started!")


func test_get_new_mid_game_join_order() -> void:
	var num_of_players: int = 6
	var num_of_disconnected_players: int = 3
	_set_dummy_room_data(1, num_of_players)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	for i in range(num_of_disconnected_players):
		var player_id: int = MatchRoomManager.rooms[room_key].players.keys()[i]
		MatchRoomManager.rooms[room_key].players[player_id].is_disconnected = true
	assert_eq(
		MatchRoomManager._get_new_mid_game_join_order(room_key),
		num_of_players - num_of_disconnected_players,
		"Join order number should be %d!" % (num_of_players - num_of_disconnected_players))


func test_get_player_id_by_player_name() -> void:
	_set_dummy_room_data(1, 6)
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var player_name: String = "Player 4"
	var expected_id: int = int(MatchRoomManager.rooms[room_key].master) * 10 + 3
	assert_eq(
		MatchRoomManager._get_player_id_by_player_name(room_key, player_name),
		expected_id,
		"Incorrect player ID!")


func test_get_player_id_by_network_id() -> void:
	_set_dummy_room_data(1, 6)
	var player_index: int = 1
	var room_key: String = MatchRoomManager.rooms.keys()[0]
	var network_id: int = MatchRoomManager.rooms[room_key].players.values()[player_index].id
	var expected_id: int = int(MatchRoomManager.rooms[room_key].master) * 10 + player_index
	assert_eq(
		MatchRoomManager._get_player_id_by_network_id(room_key, network_id),
		expected_id,
		"Incorrect player ID!")
	MatchRoomManager.rooms[room_key].players.values()[player_index].id = 0
	assert_ne(
		MatchRoomManager._get_player_id_by_network_id(room_key, network_id),
		expected_id,
		"Incorrectly found the player ID!")


func _set_dummy_room_data(number_of_rooms: int, players_per_room: int = 0) -> void:
	for room_id in range(number_of_rooms):
		room_id += 1
		var room_key: String = MatchRoomManager._handle_room_creation(room_id)
		for i in range(players_per_room):
			var player_id: int = room_id * 10 + i
			MatchRoomManager._add_player_to_room(player_id, room_key)

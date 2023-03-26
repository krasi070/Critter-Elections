extends Node
# Handles the player state within the room they are in.

signal joined_room(key)
signal set_name(p_name)
signal left_room
signal game_started
signal restarted_game
signal entered_predictions(curr_round, number_of_rounds)
signal finished_showing_predictions
signal game_continued_after_predictions
signal requested_to_go_back_to_team_selection
signal paused
signal unpaused
signal request_denied(error_msg)

# The room peer ID.
var room_id: int = -1
# The attempt room key refers to the key the player inputs to join the room.
var attempt_room_key: String = ""
# Refers to the room key of the room the player is in.
var room_key: String = ""
# Used to track what state to start the entry screen with.
var was_restarted_with_different_teams: bool = false

func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS

# Sets attempt_room_key and sends join_room request to network master.
func send_join_room_request(key: String) -> void:
	attempt_room_key = key
	rpc_id(Server.NETWORK_MASTER_ID, "join_room", key)

# Sends set_player_name request to network master.
func send_name_confirmation_request(p_name: String) -> void:
	rpc_id(Server.NETWORK_MASTER_ID, "set_player_name", room_key, p_name)

# Sends send_player_disconnected_from_room request to network master.
# Deletes player and room data. Emits left_room signal.
func send_leave_room_request() -> void:
	rpc_id(
		Server.NETWORK_MASTER_ID, 
		"send_player_disconnected_from_room", 
		get_tree().get_network_unique_id(), 
		room_key)
	leave_room()

# Sends remove_room_data request to the room the player is in.
func send_close_room_request() -> void:
	rpc_id(room_id, "remove_room_data")

# Sends forget_player_rejoin request to network master.
# Deletes player and room data. Emits left_room signal.
func send_forget_rejoin_request() -> void:
	rpc_id(
		Server.NETWORK_MASTER_ID, 
		"forget_player_rejoin",
		attempt_room_key)
	leave_room()

# Sends set_player_team_role request to network master.
func send_select_team_role_request(team_index: int, team_role: int) -> void:
	rpc_id(
		Server.NETWORK_MASTER_ID, 
		"set_player_team_role", 
		room_key, 
		team_index, 
		team_role)

# Sends start_game request to the room the player is in.
func send_start_game_request() -> void:
	rpc_id(room_id, "start_game")

# Sends restart_with_same_teams request to the room the player is in.
func send_restart_game_with_same_teams_request() -> void:
	rpc_id(room_id, "restart_with_same_teams")

# Sends restart_with_swapped_roles request to the room the player is in.
func send_restart_game_with_swapped_roles_request() -> void:
	rpc_id(room_id, "restart_with_swapped_roles")

# Sends restart_with_different_teams request to the room the player is in.
func send_change_teams_request() -> void:
	rpc_id(room_id, "restart_with_different_teams")

# Sends rejoin_player_in_room request to the server.
func send_rejoin_room_request(player_data: Dictionary) -> void:
	rpc_id(
		Server.NETWORK_MASTER_ID, 
		"rejoin_player_in_room", 
		attempt_room_key, 
		player_data.name)
	PlayerData.id = player_data.id

# Sends show_character_speech request to the server.
func send_show_character_speech_request() -> void:
	rpc_id(room_id, "show_character_speech")

# Sends update_player_workers request to the room the player is in.
#func send_update_player_worker_data_request_to_room() -> void:
#	rpc_id(room_id, "update_player_workers", PlayerData.workers)

# Sends place_worker request to the room the player is in.
func send_place_worker_request(worker_id: String, space_index: int) -> void:
	rpc_id(room_id, "place_worker", worker_id, space_index)

# Sends hire_worker_at_rank request to the room the player is in.
func send_hire_worker_at_rank_request(rank: int) -> void:
	rpc_id(room_id, "hire_worker_at_rank", rank) 

# Sends upgrade_gathering_spot request to the room the player is in.
func send_upgrade_gathering_spot_request() -> void:
	rpc_id(room_id, "upgrade_gathering_spot")

# Sends pay_as_first_visitor to the room the player is in.
func send_pay_as_first_visitor_request(payment_amount: int) -> void:
	rpc_id(room_id, "pay_as_first_visitor", payment_amount)

# Sends pay_as_second_visitor to the room the player is in.
func send_pay_as_second_visitor_request(payment_amount: int) -> void:
	rpc_id(room_id, "pay_as_second_visitor", payment_amount)

# Sends refuse_offer request to the room the player is in.
func send_refuse_offer_request() -> void:
	rpc_id(room_id, "refuse_offer")

# Sends exchange_teammate_resources to the room the player is in.
func send_exchange_with_teammate_request() -> void:
	rpc_id(room_id, "exchange_teammate_resources")

# Sends cancel_exchange to the room the player is in.
func send_cancel_exchaning_with_teammate_request() -> void:
	rpc_id(room_id, "cancel_exchange")

# Sends continue_game_after_predictions to the room the player is in.
func send_continue_game_after_predictions_request() -> void:
	rpc_id(room_id, "continue_game_after_predictions")

# Sets room and player data. Emits joined_room signal.
puppet func set_player_room_data(id: int, player_data: Dictionary) -> void:
	room_id = id
	room_key = attempt_room_key
	PlayerData.set_data(player_data)
	print("PLAYER CLIENT: Successfully joined room %s with ID %d!" % [room_key, id])
	emit_signal("joined_room", room_key)

# Emits set_name signal.
puppet func set_name(p_name: String) -> void:
	print("PLAYER CLIENT: Set name to %s!" % p_name)
	emit_signal("set_name", p_name)

# Emits game_started signal.
remote func start_game(player_id: int) -> void:
	PlayerData.id = player_id
	emit_signal("game_started")

# Emits restarted_game signal.
remote func restart_game() -> void:
	emit_signal("restarted_game")

# Sets updated player data in PlayerData.
remote func update_player_data(player_data: Dictionary) -> void:
	PlayerData.set_data(player_data)
	print("PLAYER CLIENT: Successfully updated player data!")

# Updates data about the location the player is currently at.
remote func update_location_data(data: Dictionary) -> void:
	PlayerData.location_data = data

# Sets data about the player's teammate in PlayerData.
remote func set_teammate_data(teammate_data: Dictionary) -> void:
	PlayerData.set_teammate_data(teammate_data)

# Sets updated team data in TeamData.
remote func update_teams(team_data: Array, allowed_number_of_teams: int, player_team_index: int, player_role: int) -> void:
	print("PLAYER CLIENT: Updated team data received!")
	PlayerData.team_index = player_team_index
	PlayerData.team_role = player_role
	TeamData.set_data(team_data)
	TeamData.allowed_number_of_teams = allowed_number_of_teams

# Sets the data needed to rejoin a room the player was disconncted from.
puppet func set_rejoin_room_data(rejoin_data: Array, team_names: Array) -> void:
	print("PLAYER CLIENT: Received rejoin data!")
	TeamData.team_names = team_names
	PlayerData.set_rejoin_data(rejoin_data)

# Emits entered_predictions signal, which will change the state of the game.
remote func enter_predictions_state(curr_round: int, number_of_rounds: int) -> void:
	print("PLAYER CLIENT: Finished #%d!" % curr_round)
	emit_signal("entered_predictions", curr_round, number_of_rounds)

# Emits finished_showing_predictions signal, which will allow the room master
# to continue the game for everyone.
remote func ready_to_continue() -> void:
	print("PLAYER CLIENT: Game is ready to continue to the next round!")
	emit_signal("finished_showing_predictions")

# Emits game_continued_after_predictions signal, which will take the player out
# of the predictions state of the game.
remote func continue_after_predictions() -> void:
	print("PLAYER CLIENT: Game continued to the next section!")
	emit_signal("game_continued_after_predictions")

# Emits requested_to_go_back_to_team_selection signal.
remote func go_back_to_team_selection() -> void:
	print("PLAYER CLIENT: Requested to go back to team selection!")
	was_restarted_with_different_teams = true
	TeamData.reset_data()
	emit_signal("requested_to_go_back_to_team_selection")

# Emits the paused signal.
remote func pause() -> void:
	print("PLAYER CLIENT: Paused!")
	emit_signal("paused")

# Emits the unpaused signal.
remote func unpause() -> void:
	print("PLAYER CLIENT: Unpaused!")
	emit_signal("unpaused")

# Deletes player and room data. Emits left_room signal.
remote func leave_room() -> void:
	print("PLAYER CLIENT: Left room %s!" % room_key)
	room_key = ""
	attempt_room_key = ""
	room_id = -1
	was_restarted_with_different_teams = false
	PlayerData.reset_data()
	TeamData.reset_data()
	emit_signal("left_room")

# Emits request_denied signal.
remote func inform_of_denied_request(error_msg: String) -> void:
	print("PLAYER CLIENT: Request denied! %s" % error_msg)
	emit_signal("request_denied", error_msg)

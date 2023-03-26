extends State
# The Rejoin state of the EntryScreen.
# Shows rejoin buttons.

const TRYING_TO_CONNECT_MSG: String = "Trying to connect to server..."
const CONNECTED_TO_SERVER_MSG: String = "Connected to server."
const CONTROLLER_SCREEN_SCENE_PATH: String = "res://scenes/screens/ControllerScreen.tscn"

# Connects MatchRoomManager and button signals. Hides all the elements and then
# shows only the JoinRoom elements.
func on_enter() -> void:
	_connect_signals()
	obj.hide_all_elements()
	_update_rejoin_buttons()
	_set_elements_visibility(true)

# Disconnects MatchRoomManager and button signals. Hides the JoinRoom elements.
func on_exit() -> void:
	_disconnect_signals()
	_set_elements_visibility(false)


func run(_delta: float) -> void:
	pass


func _set_elements_visibility(is_visible: bool) -> void:
	obj.rejoin_section.visible = is_visible
	obj.back_button.visible = is_visible	


func _connect_signals() -> void:
	obj.back_button.connect("pressed", self, "_pressed_back_button")
	PlayerData.connect("rejoin_data_set", self, "_player_data_rejoin_data_set")
	MatchRoomManager.connect("joined_room", self, "_match_room_manager_joined_room")
	MatchRoomManager.connect("left_room", self, "_match_room_manager_left_room")


func _disconnect_signals() -> void:
	obj.back_button.disconnect("pressed", self, "_pressed_back_button")
	PlayerData.disconnect("rejoin_data_set", self, "_player_data_rejoin_data_set")
	MatchRoomManager.disconnect("joined_room", self, "_match_room_manager_joined_room")
	MatchRoomManager.disconnect("left_room", self, "_match_room_manager_left_room")


func _update_rejoin_buttons() -> void:
	obj.rejoin_section.free_rejoin_buttons()
	for disconnected_player in PlayerData.rejoin_data:
		var button: Button = obj.rejoin_section.create_rejoin_button(disconnected_player)
		button.connect("pressed", self, "_pressed_rejoin_button", [disconnected_player])


func _pressed_back_button() -> void:
	MatchRoomManager.send_forget_rejoin_request()


func _player_data_rejoin_data_set() -> void:
	_update_rejoin_buttons()


func _pressed_rejoin_button(player_data: Dictionary) -> void:
	MatchRoomManager.send_rejoin_room_request(player_data)


func _match_room_manager_joined_room(_room_key: String) -> void:
	get_tree().change_scene(CONTROLLER_SCREEN_SCENE_PATH)


func _match_room_manager_left_room() -> void:
	fsm.transition_to_state(fsm.states.JoinRoom, true)

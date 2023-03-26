extends State
# The JoinRoom state of the EntryScreen.
# Shows the room key input, a numpad and a button to join.

# Connects MatchRoomManager and button signals. Hides all the elements and then
# shows only the JoinRoom elements.
func on_enter() -> void:
	Server.disconnect_from_server()
	Server.attempt_connection()
	_connect_signals()
	obj.hide_all_elements()
	_set_elements_visibility(true)
	obj.set_trying_to_connect_values(false)

# Disconnects MatchRoomManager and button signals. Hides the JoinRoom elements.
func on_exit() -> void:
	_disconnect_signals()
	_set_elements_visibility(false)


func run(_delta: float) -> void:
	pass


func _set_elements_visibility(is_visible: bool) -> void:
	obj.numpad.visible = is_visible
	obj.join_btn.visible = is_visible
	obj.rules_button.visible = is_visible
	obj.msg_label.visible = is_visible


func _connect_signals() -> void:
	MatchRoomManager.connect("joined_room", self, "_match_room_manager_joined_room")
	PlayerData.connect("rejoin_data_set", self, "_player_data_rejoin_data_set")
	obj.join_btn.connect("pressed", self, "_join_btn_pressed")
	obj.rules_button.connect("pressed", self, "_rules_button_pressed")


func _disconnect_signals() -> void:
	MatchRoomManager.disconnect("joined_room", self, "_match_room_manager_joined_room")
	PlayerData.disconnect("rejoin_data_set", self, "_player_data_rejoin_data_set")
	obj.join_btn.disconnect("pressed", self, "_join_btn_pressed")
	obj.rules_button.disconnect("pressed", self, "_rules_button_pressed")


func _join_btn_pressed() -> void:
	MatchRoomManager.send_join_room_request(obj.numpad.line_edit.text)


func _rules_button_pressed() -> void:
	fsm.transition_to_state(fsm.states.Rules)


func _match_room_manager_joined_room(_key: String) -> void:
	fsm.transition_to_state(fsm.states.PickName)


func _player_data_rejoin_data_set() -> void:
	fsm.transition_to_state(fsm.states.Rejoin)

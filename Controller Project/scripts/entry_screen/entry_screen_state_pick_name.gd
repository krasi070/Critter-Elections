extends State
# The PickName state of the EntryScreen.
# Shows the player info, options for names, confirm name button and 
# a back button.

# Sets the name options. Connects MatchRoomManager and button signals.
# Shows only the PickName elements.
func on_enter() -> void:
	_set_name_options()
	_connect_signals()
	_set_elements_visibility(true)
	obj.player_info_container.reset()
	obj.player_info_container.set_all()

# Disconnects MatchRoomManager and button signals. Hides the PickName elements.
func on_exit() -> void:
	_disconnect_signals()
	_set_elements_visibility(false)


func run(_delta: float) -> void:
	pass


func _set_name_options() -> void:
	obj.start_names_container.button_labels = PlayerData.start_name_options.duplicate()
	obj.start_names_container.update()
	obj.start_names_container.select_button_by_text(PlayerData.start_name)
	obj.end_names_container.button_labels = PlayerData.end_name_options.duplicate()
	obj.end_names_container.update()
	obj.end_names_container.select_button_by_text(PlayerData.end_name)


func _set_elements_visibility(is_visible: bool) -> void:
	obj.player_info_container.visible = is_visible
	obj.start_names_container.visible = is_visible
	obj.end_names_container.visible = is_visible
	if is_visible:
		_set_confirm_name_button_visibility()
	else:
		obj.confirm_name_button.visible = false
	obj.back_button.visible = is_visible


func _connect_signals() -> void:
	MatchRoomManager.connect("set_name", self, "_match_room_manager_set_name")
	MatchRoomManager.connect("left_room", self, "_match_room_manager_left_room")
	obj.start_names_container.connect(
		"button_pressed", 
		self, 
		"_start_names_container_button_pressed")
	obj.start_names_container.connect(
		"selection_removed", 
		self, 
		"_start_names_container_selection_removed")
	obj.end_names_container.connect(
		"button_pressed", 
		self, 
		"_end_names_container_button_pressed")
	obj.end_names_container.connect(
		"selection_removed", 
		self, 
		"_end_names_container_selection_removed")
	obj.confirm_name_button.connect("pressed", self, "_confirm_name_button_pressed")
	obj.back_button.connect("pressed", self, "_back_button_pressed")


func _disconnect_signals() -> void:
	MatchRoomManager.disconnect("set_name", self, "_match_room_manager_set_name")
	MatchRoomManager.disconnect("left_room", self, "_match_room_manager_left_room")
	obj.start_names_container.disconnect(
		"button_pressed", 
		self, 
		"_start_names_container_button_pressed")
	obj.start_names_container.disconnect(
		"selection_removed", 
		self, 
		"_start_names_container_selection_removed")
	obj.end_names_container.disconnect(
		"button_pressed", 
		self, 
		"_end_names_container_button_pressed")
	obj.end_names_container.disconnect(
		"selection_removed", 
		self, 
		"_end_names_container_selection_removed")
	obj.confirm_name_button.disconnect("pressed", self, "_confirm_name_button_pressed")
	obj.back_button.disconnect("pressed", self, "_back_button_pressed")


func _set_confirm_name_button_visibility() -> void:
	obj.confirm_name_button.visible = \
			obj.start_names_container.is_any_button_toggled() and \
			obj.end_names_container.is_any_button_toggled()


func _match_room_manager_set_name(_p_name: String) -> void:
	fsm.transition_to_state(fsm.states.SelectTeam)


func _match_room_manager_left_room() -> void:
	PlayerData.start_name = ""
	PlayerData.end_name = ""
	fsm.transition_to_state(fsm.states.JoinRoom, true)


func _start_names_container_button_pressed(button_label: String) -> void:
	obj.player_info_container.set_start_name(button_label)
	PlayerData.start_name = button_label
	_set_confirm_name_button_visibility()


func _start_names_container_selection_removed() -> void:
	obj.player_info_container.set_start_name("")
	PlayerData.start_name = ""
	_set_confirm_name_button_visibility()


func _end_names_container_button_pressed(button_label: String) -> void:
	obj.player_info_container.set_end_name(button_label)
	PlayerData.end_name = button_label
	_set_confirm_name_button_visibility()


func _end_names_container_selection_removed() -> void:
	obj.player_info_container.set_end_name("")
	PlayerData.end_name = ""
	_set_confirm_name_button_visibility()


func _confirm_name_button_pressed() -> void:
	MatchRoomManager.send_name_confirmation_request(PlayerData.get_full_name())


func _back_button_pressed() -> void:
	MatchRoomManager.leave_room()

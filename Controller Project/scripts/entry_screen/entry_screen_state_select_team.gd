extends State
# The SelectTeam state of the EntryScreen.
# Shows the player info, team role options, leave team button, back button and
# a start game button for the player room master.

const ROLE_NAMES: Dictionary = {
	Enums.Role.CAMPAIGNER: "Candidate",
	Enums.Role.GATHERER: "Bee Manager",
}

const START_GAME_TEXT: String = "Start Game"
const WAITING_FOR_TEAMS_TEXT_FORMAT: String = "Waiting for teams to fill up (%d/%d)"

const TEAM_CONTAINER_SCENE: PackedScene = preload("res://scenes/ui/containers/ButtonGroupContainer.tscn")
const TEAM_AND_ROLE_BUTTON_GROUP: ButtonGroup = preload("res://assets/button_groups/TeamAndRoleButtonGroup.tres")
const CONTROLLER_SCREEN_SCENE_PATH: String = "res://scenes/screens/ControllerScreen.tscn"
const CHARACTER_ICON_PATH_FORMAT: String = "res://assets/sprites/player_characters/%s_%s.png"
const CHILD_HIERARCHY_OFFSET: int = 2
const ROLE_BUTTON_HEIGHT: float = 100.0

# Holds the instances of the role button groups for each team. 
var team_button_groups: Dictionary = {}

# Connects MatchRoomManager and button signals. 
# Shows only the SelectTeam elements.
func on_enter() -> void:
	_connect_signals()
	obj.hide_all_elements()
	_update_team_containers()
	_set_elements_visibility(true)

# Disonnects MatchRoomManager and button signals. Hides the SelectTeam elements.
func on_exit() -> void:
	_disconnect_signals()
	_set_elements_visibility(false)


func run(_delta: float) -> void:
	pass


func _set_elements_visibility(is_visible: bool) -> void:
	obj.player_info_container.visible = is_visible
	if is_visible:
		_set_start_game_button_visibility()
	else:
		obj.start_game_button.visible = false
	if is_visible:
		_set_leave_team_button_visibility()
	else:
		obj.leave_team_button.visible = false
	obj.back_button.visible = is_visible
	for button_group in team_button_groups.values():
		button_group.visible = is_visible


func _set_leave_team_button_visibility() -> void:
	obj.leave_team_button.visible = \
		PlayerData.team_index != Enums.Team.NOT_SELECTED and \
		PlayerData.team_role != Enums.Role.NOT_SELECTED


func _set_start_game_button_visibility() -> void:
	obj.start_game_button.visible = PlayerData.is_room_master()
	# Commented out for ease of testing.
	if PlayerData.is_room_master() and TeamData.is_allowed_team_requirement_met():
	#if PlayerData.is_room_master() and PlayerData.team_role != Enums.Role.NOT_SELECTED:
		obj.start_game_button.disabled = false
		obj.start_game_button.text = START_GAME_TEXT
	else:
		obj.start_game_button.disabled = true
		obj.start_game_button.text = WAITING_FOR_TEAMS_TEXT_FORMAT % [
			TeamData.get_number_of_full_teams(),
			TeamData.allowed_number_of_teams,
		]


func _connect_signals() -> void:
	MatchRoomManager.connect("left_room", self, "_match_room_manager_left_room")
	MatchRoomManager.connect("game_started", self, "_match_room_manager_game_started")
	TeamData.connect("updated_teams", self, "_team_data_updated_teams")
	obj.start_game_button.connect("pressed", self, "_start_game_button_pressed")
	obj.leave_team_button.connect("pressed", self, "_leave_team_button_pressed")
	obj.back_button.connect("pressed", self, "_back_button_pressed")


func _disconnect_signals() -> void:
	MatchRoomManager.disconnect("left_room", self, "_match_room_manager_left_room")
	MatchRoomManager.disconnect("game_started", self, "_match_room_manager_game_started")
	TeamData.disconnect("updated_teams", self, "_team_data_updated_teams")
	obj.start_game_button.disconnect("pressed", self, "_start_game_button_pressed")
	obj.leave_team_button.disconnect("pressed", self, "_leave_team_button_pressed")
	obj.back_button.disconnect("pressed", self, "_back_button_pressed")


func _add_team(team: Dictionary) -> void:
	var team_container_instance: VBoxContainer = TEAM_CONTAINER_SCENE.instance()
	obj.main_container.add_child(team_container_instance)
	obj.main_container.move_child(
		team_container_instance, 
		CHILD_HIERARCHY_OFFSET + team_button_groups.size())
	team_button_groups[team.name] = team_container_instance
	_set_team_data(team_container_instance, team)


func _set_team_data(container: VBoxContainer, data: Dictionary) -> void:
	container.label_text = data.name
	container.button_group = TEAM_AND_ROLE_BUTTON_GROUP
	container.button_min_height = ROLE_BUTTON_HEIGHT
	container.button_labels.clear()
	container.button_icons.clear()
	_set_role_data(container, data.index, Enums.Role.CAMPAIGNER, data.role_a)
	_set_role_data(container, data.index, Enums.Role.GATHERER, data.role_b)
	container.update()
	container.buttons[0].disabled = not data.role_a == "free"
	container.buttons[0].connect("pressed", self, "_pressed_team_role_button", 
		[data.index, Enums.Role.CAMPAIGNER])
	container.buttons[1].disabled = not data.role_b == "free"
	container.buttons[1].connect("pressed", self, "_pressed_team_role_button", 
		[data.index, Enums.Role.GATHERER])


func _set_role_data(container: VBoxContainer, team: int, role: int, role_taken_by: String) -> void:
	if role_taken_by == "free":
		container.button_labels.append(ROLE_NAMES[role])
		container.button_icons.append(_get_icon_for_button(team, role))
	else:
		container.button_labels.append(role_taken_by)
		container.button_icons.append(null)


func _remove_team(team_name: String) -> void:
	if TeamData.get_team_index_by_name(team_name) == Enums.Team.NOT_SELECTED:
		MatchRoomManager.send_select_team_role_request(
			Enums.Team.NOT_SELECTED, 
			Enums.Role.NOT_SELECTED)
	team_button_groups[team_name].queue_free()
	team_button_groups.erase(team_name)


func _check_for_added_and_updated_teams() -> void:
	for team in TeamData.all_teams:
		if team.has("name"):
			if team_button_groups.has(team.name):
				_set_team_data(team_button_groups[team.name], team)
			else:
				_add_team(team)


func _check_for_removed_teams() -> void:
	for team_name in team_button_groups.keys():
		if not TeamData.has_team(team_name):
			_remove_team(team_name)


func _get_icon_for_button(team: int, role: int) -> Texture:
	var icon_path: String = _get_icon_path_for_character(team, role)
	var icon_texture: Texture = load(icon_path)
	return icon_texture


func _get_icon_path_for_character(team: int, role: int) -> String:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	var role_str: String = Enums.to_str_snake_case(Enums.Role, role)
	return CHARACTER_ICON_PATH_FORMAT % [team_str, role_str]


func _update_team_containers() -> void:
	_check_for_removed_teams()
	_check_for_added_and_updated_teams()
	_set_leave_team_button_visibility()
	_set_start_game_button_visibility()
	obj.player_info_container.set_all()


func _match_room_manager_game_started() -> void:
	get_tree().change_scene(CONTROLLER_SCREEN_SCENE_PATH)


func _match_room_manager_left_room() -> void:
	fsm.transition_to_state(fsm.states.JoinRoom, true)


func _team_data_updated_teams() -> void:
	_update_team_containers()


func _pressed_team_role_button(team_index: int, role: int) -> void:
	MatchRoomManager.send_select_team_role_request(team_index, role)


func _start_game_button_pressed() -> void:
	MatchRoomManager.send_start_game_request()


func _leave_team_button_pressed() -> void:
	MatchRoomManager.send_select_team_role_request(
		Enums.Team.NOT_SELECTED, 
		Enums.Role.NOT_SELECTED)


func _back_button_pressed() -> void:
	MatchRoomManager.send_select_team_role_request(Enums.Team.NOT_SELECTED, Enums.Role.NOT_SELECTED)
	PlayerData.team_index = Enums.Team.NOT_SELECTED
	PlayerData.team_role = Enums.Role.NOT_SELECTED
	fsm.transition_to_state(fsm.states.PickName)

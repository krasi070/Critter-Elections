extends Control
# EntryScreen's script.
# Handles the showing the correct input based on the state of the room joining
# process.

const TRYING_TO_CONNECT_MSG: String = "Trying to connect to server..."
const CONNECTED_TO_SERVER_MSG: String = "Connected to server."

const DEFAULT_FONT_COLOR: Color = Color.white
const ERROR_FONT_COLOR: Color = Color(240 / 255.0, 137 / 255.0, 93 / 255.0)

# The finite state machine.
var fsm: FiniteStateMachine

# The join room view elements.
onready var numpad: Control = $MainContainer/Numpad
onready var join_btn: Button = $MainContainer/JoinRoomButton
onready var rules_button: Button = $MainContainer/RulesButton

# The rejoin view elements.
onready var rejoin_section: Control = $MainContainer/RejoinSection

# The pick name view elements.
onready var start_names_container: VBoxContainer = $MainContainer/StartNamesContainer
onready var end_names_container: VBoxContainer = $MainContainer/EndNamesContainer
onready var confirm_name_button: Button = $MainContainer/ConfirmNameButton

# The select team view elements.
onready var start_game_button: Button = $MainContainer/StartGameButton
onready var leave_team_button: Button = $MainContainer/LeaveTeamButton

# The multiuse view elements.
onready var main_container: VBoxContainer = $MainContainer
onready var player_info_container: HBoxContainer = $MainContainer/PlayerInfoContainer
onready var back_button: Button = $MainContainer/BackButton
onready var msg_label: Label = $MainContainer/MessageLabel

# Rules elements.
onready var rules_container: VBoxContainer = $MainContainer/RulesContainer

# The states needed to start the finate state machine.
onready var states: Node = $States
onready var join_room_state: Node = $States/JoinRoom
onready var select_team_state: Node = $States/SelectTeam

func _ready() -> void:
	var starting_state: Node = join_room_state
	if MatchRoomManager.was_restarted_with_different_teams:
		starting_state = select_team_state
	fsm = FiniteStateMachine.new(self, states, starting_state, true)
	_connect_signals()


func _physics_process(delta: float) -> void:
	fsm.run_machine(delta)

# Hide every child element, whose name doesn't start with padding.
func hide_all_elements() -> void:
	for child in main_container.get_children():
		if not child.name.begins_with("Padding"):
			child.hide()


# Sets the message label to show server connectivity.
func set_trying_to_connect_values(is_connected: bool) -> void:
	msg_label.set("custom_colors/font_color", DEFAULT_FONT_COLOR)
	if is_connected:
		join_btn.disabled = false
		msg_label.text = CONNECTED_TO_SERVER_MSG
	else:
		join_btn.disabled = true
		msg_label.text = TRYING_TO_CONNECT_MSG


func _connect_signals() -> void:
	Server.connect("connected_to_server", self, "_server_connected_to_server")
	Server.connect("connection_failed", self, "_server_connection_failed")
	MatchRoomManager.connect("request_denied", self, "_match_room_manager_request_denied")


func _server_connected_to_server() -> void:
	set_trying_to_connect_values(true)


func _server_connection_failed() -> void:
	Server.attempt_connection()
	set_trying_to_connect_values(false)


func _match_room_manager_request_denied(error_msg: String) -> void:
	msg_label.set("custom_colors/font_color", ERROR_FONT_COLOR)
	msg_label.text = error_msg
	msg_label.show()

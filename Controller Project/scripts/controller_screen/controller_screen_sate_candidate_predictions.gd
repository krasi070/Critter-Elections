extends State
# The Candidate Predictions state of the ControllerScreen.

var default_return_state: Node
var curr_round: int
var number_of_rounds: int
var is_last_round: bool
var can_continue: bool

func _ready() -> void:
	can_continue = false
	_connect_signals()


func on_enter() -> void:
	get_tree().paused = true
	_set_pause_view_element_states(can_continue)
	obj.show_paused_view()
	_connnect_temporary_signals()


func on_exit() -> void:
	can_continue = false
	get_tree().paused = false
	obj.show_unpaused_view()
	_disconnnect_temporary_signals()


func run(_delta: float) -> void:
	pass


func _connect_signals() -> void:
	MatchRoomManager.connect("entered_predictions", self, "_match_room_manager_entered_predictions")
	MatchRoomManager.connect("finished_showing_predictions", self, "_match_room_manager_finished_showing_predictions")


func _connnect_temporary_signals() -> void:
	obj.pause_elements_container.continue_button.connect("pressed", self, "_pressed_continue_button")
	obj.pause_elements_container.keep_teams_button.connect("pressed", self, "_pressed_keep_teams_button")
	obj.pause_elements_container.swap_roles_button.connect("pressed", self, "_pressed_swap_roles_button")
	obj.pause_elements_container.change_teams_button.connect("pressed", self, "_pressed_change_teams_button")
	obj.pause_elements_container.close_room_button.connect("pressed", self, "_pressed_close_room_button")
	PlayerData.connect("join_order_changed", self, "_player_data_join_order_changed")
	MatchRoomManager.connect("game_continued_after_predictions", self, "_match_room_manager_game_continued_after_predictions")
	MatchRoomManager.connect("restarted_game", self, "_match_room_manager_restarted_game")


func _disconnnect_temporary_signals() -> void:
	obj.pause_elements_container.continue_button.disconnect("pressed", self, "_pressed_continue_button")
	obj.pause_elements_container.keep_teams_button.disconnect("pressed", self, "_pressed_keep_teams_button")
	obj.pause_elements_container.swap_roles_button.disconnect("pressed", self, "_pressed_swap_roles_button")
	obj.pause_elements_container.change_teams_button.disconnect("pressed", self, "_pressed_change_teams_button")
	obj.pause_elements_container.close_room_button.disconnect("pressed", self, "_pressed_close_room_button")
	PlayerData.disconnect("join_order_changed", self, "_player_data_join_order_changed")
	MatchRoomManager.disconnect("game_continued_after_predictions", self, "_match_room_manager_game_continued_after_predictions")
	MatchRoomManager.disconnect("restarted_game", self, "_match_room_manager_restarted_game")


func _set_pause_view_element_states(can_cantinue: bool) -> void:
	if is_last_round and can_cantinue and PlayerData.is_room_master():
		obj.pause_elements_container.show_game_end_view()
		return
	obj.pause_elements_container.show_predictions_view(curr_round, number_of_rounds)
	obj.pause_elements_container.continue_button.disabled = not can_cantinue


func _match_room_manager_entered_predictions(_curr_round: int, _number_of_rounds: int) -> void:
	curr_round = _curr_round
	number_of_rounds = _number_of_rounds
	is_last_round = curr_round == number_of_rounds
	fsm.transition_to_state(fsm.states.CandidatePredictions, true)


func _match_room_manager_finished_showing_predictions() -> void:
	can_continue = true
	if fsm.state_curr.name == name and PlayerData.is_room_master():
		_set_pause_view_element_states(can_continue)


func _player_data_join_order_changed() -> void:
	if PlayerData.is_room_master():
		_set_pause_view_element_states(can_continue)


func _pressed_continue_button() -> void:
	if PlayerData.is_room_master():
		MatchRoomManager.send_continue_game_after_predictions_request()


func _pressed_keep_teams_button() -> void:
	MatchRoomManager.send_restart_game_with_same_teams_request()


func _pressed_swap_roles_button() -> void:
	MatchRoomManager.send_restart_game_with_swapped_roles_request()


func _pressed_change_teams_button() -> void:
	MatchRoomManager.send_change_teams_request()


func _pressed_close_room_button() -> void:
	MatchRoomManager.send_close_room_request()


func _match_room_manager_game_continued_after_predictions() -> void:
	fsm.transition_to_state(default_return_state)


func _match_room_manager_restarted_game() -> void:
	on_exit()
	get_tree().reload_current_scene()

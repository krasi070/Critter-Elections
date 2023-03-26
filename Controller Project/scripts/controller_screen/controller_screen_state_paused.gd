extends State
# The Paused state of the ControllerScreen.

var default_return_state: Node

func _ready() -> void:
	_connect_signals()


func on_enter() -> void:
	get_tree().paused = true
	_set_pause_view_element_states()
	obj.show_paused_view()


func on_exit() -> void:
	get_tree().paused = false
	obj.show_unpaused_view()


func run(_delta: float) -> void:
	pass


func _connect_signals() -> void:
	MatchRoomManager.connect("paused", self, "_match_room_manager_paused")
	MatchRoomManager.connect("unpaused", self, "_match_room_manager_unpaused")


func _set_pause_view_element_states() -> void:
	obj.pause_elements_container.show_paused_view()


func _match_room_manager_paused() -> void:
	fsm.transition_to_state(fsm.states.Paused, true)


func _match_room_manager_unpaused() -> void:
	if is_instance_valid(fsm.state_prev):
		fsm.transition_to_state(fsm.state_prev)
	else:
		fsm.transition_to_state(default_return_state)

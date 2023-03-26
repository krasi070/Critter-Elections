extends State
# The InHiringSpot state of the ControllerScreen.

const HELPER_TEXT: String = "Hire bees! When a bee goes up in the list it gets cheaper, try it out and see."
const EXIT_BTN: String = "Exit"

var action_buttons: Dictionary = {
	EXIT_BTN: "_pressed_exit_button",
}

func on_enter() -> void:
	obj.helper_label.text = HELPER_TEXT
	_set_elements_visibility(true)
	_set_for_hire_worker_data()
	obj.create_action_buttons(self, action_buttons)
	_connect_signals()


func on_exit() -> void:
	_set_elements_visibility(false)
	_disconnect_signals()


func run(_delta: float) -> void:
	pass


func _set_elements_visibility(is_visible: bool) -> void:
	obj.helper_label.visible = is_visible
	obj.worker_buttons_container.visible = is_visible
	obj.action_buttons_container.visible = is_visible


func _connect_signals() -> void:
	PlayerData.connect("updated_location_data", self, "_player_data_updated_location_data")


func _disconnect_signals() -> void:
	PlayerData.disconnect("updated_location_data", self, "_player_data_updated_location_data")


func _set_for_hire_worker_data() -> void:
	obj.worker_buttons_container.free_children()
	var rank_counter: int = 0
	for for_hire_worker in PlayerData.location_data.for_hire:
		_init_worker_button(for_hire_worker, rank_counter)
		rank_counter += 1


func _init_worker_button(worker_data: Dictionary, rank: int) -> void:
	var worker_button: Button = \
		obj.worker_buttons_container.create_worker_button(worker_data, rank, true)
	worker_button.connect("pressed", self, "_pressed_for_hire_worker", [worker_button])


func _player_data_updated_location_data() -> void:
	obj.worker_buttons_container.update_for_hire_worker_buttons()
	_init_worker_button(
		PlayerData.location_data.for_hire[-1],
		PlayerData.location_data.for_hire.size() - 1)


func _pressed_for_hire_worker(pressed_button: Button) -> void:
	MatchRoomManager.send_hire_worker_at_rank_request(pressed_button.rank)


func _pressed_exit_button() -> void:
	fsm.transition_to_state(fsm.states.DefaultGatherer)

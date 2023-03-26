extends State
# The InGatheringSpot state of the ControllerScreen.

const NO_ACTIVITY_HELPER_TEXT: String = "Place a bee! You can leave and do other things while they're working."
const UPGRADE_BTN: String = "Upgrade"
const UPGRADE_BTN_TEXT_FORMAT: String = "Upgrade (%d*money*)"
const EXIT_BTN: String = "Exit"

var action_buttons: Dictionary = {
	UPGRADE_BTN: "_pressed_upgrade_button",
	EXIT_BTN: "_pressed_exit_button",
}

var _curr_space_index: int = -1

func on_enter() -> void:
	_curr_space_index = -1
	obj.no_activity_helper_label.text = NO_ACTIVITY_HELPER_TEXT
	obj.create_action_buttons(self, action_buttons)
	_set_visial_data()
	_set_elements_visibility(true)
	_connect_signals()
	obj.start_no_activity_timer()


func on_exit() -> void:
	_set_elements_visibility(false)
	obj.no_activity_container.hide()
	_free_instances()
	_disconnect_signals()


func run(_delta: float) -> void:
	pass


func _set_visial_data() -> void:
	obj.gathering_spot_data_container.set_values(PlayerData.location_data)
	if PlayerData.location_data.upgrade_price > 0:
		obj.action_buttons_container.set_new_button_text(
			UPGRADE_BTN,
			UPGRADE_BTN_TEXT_FORMAT % PlayerData.location_data.upgrade_price, 
			true)
		obj.action_buttons_container.set_action_button_disabled(
			UPGRADE_BTN,
			PlayerData.resources[Enums.Resource.MONEY] < PlayerData.location_data.upgrade_price)
	else:
		obj.action_buttons_container.free_action_button_by_text(UPGRADE_BTN)
	_set_places()
	_set_player_available_worker_buttons()


func _set_elements_visibility(is_visible: bool) -> void:
	obj.gathering_spot_data_container.visible = is_visible
	obj.gathering_spot_places_container.visible = is_visible
	obj.action_buttons_container.visible = is_visible


func _free_instances() -> void:
	obj.gathering_spot_places_container.free_children()
	obj.worker_buttons_container.free_children()


func _set_player_available_worker_buttons() -> void:
	obj.worker_buttons_container.free_children()
	for worker in PlayerData.workers.values():
		if not worker.is_working:
			var button_instance: Button = \
				obj.worker_buttons_container.create_worker_button(worker)
			button_instance.connect("pressed", self, "_player_worker_button_pressed", [worker.id])


func _set_places() -> void:
	obj.gathering_spot_places_container.free_children()
	var working_workers: Array = PlayerData.location_data.working_workers
	for index in range(working_workers.size()):
		if not working_workers[index].empty():
			obj.gathering_spot_places_container.create_taken_place_instance(
				working_workers[index], 
				PlayerData.location_data.production_time,
				index)
		else:
			var is_selected: bool = _curr_space_index == index
			obj.gathering_spot_places_container.create_free_space_button_instance(index, is_selected)


func _connect_signals() -> void:
	obj.gathering_spot_places_container.connect(
		"selected_place", 
		self, 
		"_selected_place_gathering_spot_places_container")
	obj.gathering_spot_places_container.connect(
		"deselected_place", 
		self, 
		"_deselected_place_gathering_spot_places_container")
	obj.no_activity_timer.connect("timeout", self, "_no_activity_timer_timeout")
	PlayerData.connect("updated_workers", self, "_player_data_updated_workers")
	PlayerData.connect("updated_location_data", self, "_player_data_updated_location_data")


func _disconnect_signals() -> void:
	obj.gathering_spot_places_container.disconnect(
		"selected_place", 
		self, 
		"_selected_place_gathering_spot_places_container")
	obj.gathering_spot_places_container.disconnect(
		"deselected_place", 
		self, 
		"_deselected_place_gathering_spot_places_container")
	obj.no_activity_timer.disconnect("timeout", self, "_no_activity_timer_timeout")
	PlayerData.disconnect("updated_workers", self, "_player_data_updated_workers")
	PlayerData.disconnect("updated_location_data", self, "_player_data_updated_location_data")


func _no_activity_timer_timeout() -> void:
	obj.no_activity_container.show()


func _selected_place_gathering_spot_places_container(_pressed_button: Button, space_index: int) -> void:
	_curr_space_index = space_index
	obj.worker_buttons_container.show()
	obj.start_no_activity_timer()


func _deselected_place_gathering_spot_places_container() -> void:
	_curr_space_index = -1
	obj.worker_buttons_container.hide()
	obj.start_no_activity_timer()


func _player_worker_button_pressed(worker_id: String) -> void:
	MatchRoomManager.send_place_worker_request(worker_id, _curr_space_index)
	_curr_space_index = -1
	obj.worker_buttons_container.hide()
	obj.start_no_activity_timer()


func _player_data_updated_workers() -> void:
	_set_visial_data()


func _player_data_updated_location_data() -> void:
	_set_visial_data()


func _pressed_upgrade_button() -> void:
	MatchRoomManager.send_upgrade_gathering_spot_request()
	obj.start_no_activity_timer()


func _pressed_exit_button() -> void:
	fsm.transition_to_state(fsm.states.DefaultGatherer)

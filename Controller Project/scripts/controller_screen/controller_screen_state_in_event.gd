extends State
# The InEvent state of the ControllerScreen.

const PAY_BTN_TEXT_FORMAT: String = "Offer (%d*%s*)"

var action_buttons: Dictionary

var _buttons_to_free: Array = []

func on_enter() -> void:
	_populate_action_buttons_dictionary()
	_set_visual_data()
	_create_action_buttons_based_on_visitor()
	_set_elements_visibility(true)
	_connect_signals()


func on_exit() -> void:
	_set_elements_visibility(false)
	_disconnect_signals()


func run(_delta: float) -> void:
	pass


func _populate_action_buttons_dictionary() -> void:
	action_buttons = {
		obj.event_character_data_container.PAY_BTN: "_pressed_pay_button",
		obj.event_character_data_container.DECLINE_BTN: "_pressed_decline_button",
		obj.event_character_data_container.LEAVE_BTN: "_pressed_leave_button",
	}


func _set_elements_visibility(is_visible: bool) -> void:
	obj.event_character_data_container.visible = is_visible
	obj.action_buttons_container.visible = is_visible


func _set_visual_data() -> void:
	_buttons_to_free = \
		obj.event_character_data_container.set_values(PlayerData.location_data)


func _create_action_buttons_based_on_visitor() -> void:
	obj.create_action_buttons(self, action_buttons)
	for button_text in _buttons_to_free:
		obj.action_buttons_container.free_action_button_by_text(button_text)
	_update_pay_button_text(PlayerData.location_data.min_payment)


func _update_pay_button_text(value: int) -> void:
	obj.action_buttons_container.set_new_button_text(
			obj.event_character_data_container.PAY_BTN,
			PAY_BTN_TEXT_FORMAT % [value, Enums.to_str_snake_case(
				Enums.Resource, 
				PlayerData.location_data.resource_type)],
			true)
	var can_pay: bool = \
		PlayerData.resources[PlayerData.location_data.resource_type] >= value
	obj.action_buttons_container.set_action_button_disabled(
		obj.event_character_data_container.PAY_BTN, 
		not can_pay)
	var is_slider_visible: bool = can_pay and \
		obj.action_buttons_container.action_buttons.has(obj.event_character_data_container.PAY_BTN)
	obj.event_character_data_container.slider_container.visible = is_slider_visible


func _connect_signals() -> void:
	PlayerData.connect("updated_resources", self, "_player_data_updated_resources")
	PlayerData.connect("updated_location_data", self, "_player_data_updated_location_data")
	obj.event_character_data_container.slider_container.connect(
		"value_changed",
		self,
		"_slider_value_changed")


func _disconnect_signals() -> void:
	PlayerData.disconnect("updated_resources", self, "_player_data_updated_resources")
	PlayerData.disconnect("updated_location_data", self, "_player_data_updated_location_data")
	obj.event_character_data_container.slider_container.disconnect(
		"value_changed",
		self,
		"_slider_value_changed")


func _is_visitor_the_first_payer() -> bool:
	return PlayerData.location_data.first_payment_by == PlayerData.id


func _pressed_pay_button() -> void:
	var payment_amount: int = obj.event_character_data_container.get_slider_value()
	var is_second_visitor: bool = PlayerData.location_data.has_first_payment_been_made
	if is_second_visitor:
		MatchRoomManager.send_pay_as_second_visitor_request(payment_amount)
		return
	MatchRoomManager.send_pay_as_first_visitor_request(payment_amount)


func _pressed_decline_button() -> void:
	MatchRoomManager.send_refuse_offer_request()


func _pressed_leave_button() -> void:
	fsm.transition_to_state(fsm.states.DefaultCampaigner)


func _player_data_updated_resources() -> void:
	_set_visual_data()
	_create_action_buttons_based_on_visitor()


func _player_data_updated_location_data() -> void:
	if PlayerData.location_type != Enums.LocationType.EVENT or \
		PlayerData.location_data.empty():
		fsm.transition_to_state(fsm.states.DefaultCampaigner)
		return
	_set_visual_data()
	_create_action_buttons_based_on_visitor()


func _slider_value_changed(value: int) -> void:
	_update_pay_button_text(value)

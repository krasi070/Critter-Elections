extends ControllerScreenStateDefault
# The DefaultGatherer state of the ControllerScreen.

const ENTER_GATHERING_SPOT_BTN: String = "Enter Gathering Spot"
const ENTER_HIRING_SPOT_BTN: String = "Enter Hiring Spot"
const EXCHANGE_RESOURCES_FOR_MONEY_BTN: String = "Exchange Resources for Money"

var action_buttons: Dictionary = {
	ENTER_GATHERING_SPOT_BTN: "_pressed_enter_gathering_spot_button",
	ENTER_HIRING_SPOT_BTN: "_pressed_enter_hiring_spot_button",
	EXCHANGE_RESOURCES_FOR_MONEY_BTN: "_pressed_exchange_resources_button",
}

func on_enter() -> void:
	.on_enter()
	_exchange_button_text = EXCHANGE_RESOURCES_FOR_MONEY_BTN
	obj.create_action_buttons(self, action_buttons)
	_show_actions_based_on_location_type()
	can_move_with_keyboard = true


func on_exit() -> void:
	can_move_with_keyboard = false
	.on_exit()


func run(_delta: float) -> void:
	pass


func _show_actions_based_on_location_type() -> void:
	var actions: Dictionary = obj.action_buttons_container.action_buttons
	obj.hide_all_action_buttons()
	match PlayerData.location_type:
		Enums.LocationType.GATHERING_SPOT:
			actions[ENTER_GATHERING_SPOT_BTN].show()
		Enums.LocationType.HIRING_SPOT:
			actions[ENTER_HIRING_SPOT_BTN].show()
		_:
			pass
	._show_actions_based_on_location_type()


func _pressed_enter_gathering_spot_button() -> void:
	print("PLAYER CLIENT: Pressed enter gathering spot button.")
	fsm.transition_to_state(fsm.states.InGatheringSpot)


func _pressed_enter_hiring_spot_button() -> void:
	print("PLAYER CLIENT: Pressed enter hiring spot button.")
	fsm.transition_to_state(fsm.states.InHiringSpot)

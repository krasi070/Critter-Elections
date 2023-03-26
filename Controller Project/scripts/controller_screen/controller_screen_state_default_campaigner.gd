extends ControllerScreenStateDefault
# The DefaultCampaigner state of the ControllerScreen.

const DISCUSS_FUNDING_BTN: String = "Discuss Deal"
const EXCHANGE_MONEY_FOR_RESOURCES_BTN: String = "Exchange Money for Resources"

var action_buttons: Dictionary = {
	DISCUSS_FUNDING_BTN: "_pressed_discuss_funding_button",
	EXCHANGE_MONEY_FOR_RESOURCES_BTN: "_pressed_exchange_resources_button",
}

func on_enter() -> void:
	.on_enter()
	_exchange_button_text = EXCHANGE_MONEY_FOR_RESOURCES_BTN
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
		Enums.LocationType.EVENT:
			actions[DISCUSS_FUNDING_BTN].show()
	._show_actions_based_on_location_type()


func _pressed_discuss_funding_button() -> void:
	print("PLAYER CLIENT: Pressed discuss funding!")
	fsm.transition_to_state(fsm.states.InEvent)


func _pressed_enter_shop_button() -> void:
	print("PLAYER CLIENT: Pressed enter shop button!")

class_name ActionButtonsContainer
extends VBoxContainer
# ActionButtonsContainer's script.

var action_buttons: Dictionary = {}

const ACTION_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/buttons/ActionButton.tscn")

# Creates buttons based on button text and on pressed function name and add
# them to the container.
func create_action_buttons(signal_target: Object, button_data: Dictionary) -> void:
	for button_text in button_data.keys():
		var button_instance: Button = ACTION_BUTTON_SCENE.instance()
		button_instance.text = button_text
		button_instance.name = button_text
		button_instance.connect("pressed", signal_target, button_data[button_text])
		add_child(button_instance)
		action_buttons[button_text] = button_instance

# Sets the given action button's visibility.
func set_action_button_visibility(button_text: String, is_visible: bool) -> void:
	if not action_buttons.has(button_text):
		return
	action_buttons[button_text].visible = is_visible

# Sets the given action button to disabled or active based on the given arguments.
func set_action_button_disabled(button_text: String, is_disabled: bool) -> void:
	if not action_buttons.has(button_text):
		return
	action_buttons[button_text].set_disabled_value(is_disabled)

# Hides the buttons in action_buttons_container.
func hide_all_action_buttons() -> void:
	for button in get_children():
		button.hide()

# Frees action button with the given button text. If the button is not
# found, does nothing.
func free_action_button_by_text(button_text: String) -> void:
	if not action_buttons.has(button_text):
		return
	action_buttons[button_text].queue_free()
	action_buttons.erase(button_text)

# Free all the buttons.
func free_action_buttons() -> void:
	for button in get_children():
		button.queue_free()
	action_buttons = {}

# Sets new text for the button. Does not update the key for the
# button in the action_buttons dictionary.
func set_new_button_text(button_text: String, new_text: String, with_symbol: bool = false) -> void:
	if not action_buttons.has(button_text):
		return
	if with_symbol:
		action_buttons[button_text].set_symbol_text(new_text)
		action_buttons[button_text].set_to_symbol_type()
	else:
		action_buttons[button_text].text = new_text

extends VBoxContainer
# ButtonGroupContainer's script.
# Simplifies the handling of a container of buttons in the same group.

signal button_pressed(button_label)
signal selection_removed()

const BUTTON_SCENE: PackedScene = preload("res://scenes/ui/buttons/ButtonGroupButton.tscn")

export(String) var label_text
export(ButtonGroup) var button_group
export(Array) var button_labels
export(Array) var button_icons

var buttons: Array
var button_min_height: float = 0
var is_deselection_on: bool = false

onready var label: Label = $Label
onready var container: HBoxContainer = $ButtonContainer

var _last_pressed: Button

func _ready() -> void:
	update()

# Sets the text of the label for the button group. Frees up any existing buttons
# and creates new ones based on the button_labels array and adds them to the 
# container. 
func update() -> void:
	label.text = label_text
	_free_buttons()
	_init_buttons()

# Sets the button with the given button text to be toggled. If button is not 
# found, does nothing.
func select_button_by_text(button_text: String) -> void:
	for button in buttons:
		if button.text == button_text:
			button.pressed = true
			return

# Resets the button icon on the button with the given text.
func reset_button_icon_on_button_with_text(button_text: String) -> void:
	for i in range(buttons.size()):
		if buttons[i].text == button_text:
			buttons[i].icon = _get_button_icon_if_available(i)
			return

# Removes the button icon on the button with the given text.
func remove_button_icon_on_button_with_text(button_text: String) -> void:
	for button in buttons:
		if button.text == button_text:
			button.icon = null
			return

# Returns true if any one of the buttons is pressed/toggled. Otherwise, false.
func is_any_button_toggled() -> bool:
	for button in buttons:
		if button.pressed:
			return true
	return false

# Returns true if any one of the buttons is disabled. Otherwise, false.
func is_any_button_disabled() -> bool:
	for button in buttons:
		if button.disabled:
			return true
	return false


func _init_buttons() -> void:
	for i in range(button_labels.size()):
		var b_label: String = button_labels[i]
		var b_instance: Button = BUTTON_SCENE.instance()
		b_instance.text = b_label
		b_instance.icon = _get_button_icon_if_available(i)
		b_instance.group = button_group
		b_instance.rect_min_size = Vector2(0, button_min_height)
		b_instance.connect("pressed", self, "_button_pressed", [b_instance])
		container.add_child(b_instance)
		buttons.append(b_instance)


func _free_buttons() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()


func _get_button_icon_if_available(index: int) -> Texture:
	if index < button_icons.size():
		return button_icons[index]
	return null


func _button_pressed(button: Button) -> void:
	if is_deselection_on and \
		is_instance_valid(_last_pressed) and \
		button == _last_pressed:
		button.pressed = false
		_last_pressed = null
		emit_signal("selection_removed")
		return
	_last_pressed = button
	emit_signal("button_pressed", button.text)

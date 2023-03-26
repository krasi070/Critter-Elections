extends Control
# Numpad's script.
# Represents a number pad.

var buttons: Array

onready var line_edit: LineEdit = $MarginContainer/VBoxContainer/LineEdit
onready var num_buttons_container: GridContainer = \
	$MarginContainer/VBoxContainer/NumpadContainer

func _ready() -> void:
	line_edit.text = ""
	_set_buttons()


func _set_buttons() -> void:
	for child in num_buttons_container.get_children():
		if child is Button:
			child.connect("pressed", self, "_button_pressed", [child.text])
			buttons.append(child)


func _button_pressed(button_text: String) -> void:
	if not is_instance_valid(line_edit):
		return
	if button_text.to_lower().begins_with("c"):
		line_edit.text = ""
	elif button_text.to_lower().begins_with("b"):
		line_edit.text = line_edit.text.substr(0, line_edit.text.length() - 1)
	else:
		line_edit.text += button_text

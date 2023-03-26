extends VBoxContainer
# ReadonlyInputContainer's script.
# A container with a Label and a readonly LineEdit.

export(String) var label_text
export(int, 20) var max_length

onready var label: Label = $Label
onready var line_edit: LineEdit = $LineEdit

func _ready() -> void:
	label.text = label_text
	line_edit.max_length = max_length

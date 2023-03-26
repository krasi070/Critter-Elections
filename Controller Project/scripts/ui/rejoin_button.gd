class_name RejoinButton
extends Button
# RejoinButton's script.

onready var label: Label = $MarginContainer/Label

func _ready() -> void:
	text = ""

# Sets the child label's text.
func set_text(text: String) -> void:
	label.text = text

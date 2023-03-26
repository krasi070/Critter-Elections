extends CanvasLayer
# DebugHelper's script.
# Used to execute commands to help debugging.

onready var container: MarginContainer = $MarginContainer
onready var console_text: TextEdit = $MarginContainer/BackgroundRect/Margin/VBoxContainer/ConsoleText
onready var input_line: LineEdit = $MarginContainer/BackgroundRect/Margin/VBoxContainer/InputLine

func _ready() -> void:
	container.visible = false


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_toggle"):
		container.visible = not container.visible
	if event.is_action_pressed("debug_enter") and container.visible:
		_execute_command()


func _execute_command() -> void:
	var cmd_args: String = input_line.text
	# Add commands

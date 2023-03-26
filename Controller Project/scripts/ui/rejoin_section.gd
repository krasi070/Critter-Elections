class_name RejoinSection
extends NinePatchRect
# RejoinSection's script.

const CHARACTER_ICON_PATH_FORMAT: String = "res://assets/sprites/player_characters/%s_%s.png"
const REJOIN_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/buttons/RejoinButton.tscn")

onready var container: GridContainer = \
	$MarginContainer/VBoxContainer/RejoinButtonsContainer

# Frees all of the rejoin buttons.
func free_rejoin_buttons() -> void:
	for button in container.get_children():
		button.queue_free()

# Creates and returns a rejoin button.
func create_rejoin_button(button_data: Dictionary) -> Button:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, button_data.team)
	var role_str: String = Enums.to_str_snake_case(Enums.Role, button_data.role)
	var instance: Button = REJOIN_BUTTON_SCENE.instance()
	container.add_child(instance)
	instance.set_text(button_data.name)
	instance.icon = load(CHARACTER_ICON_PATH_FORMAT % [team_str, role_str])
	return instance

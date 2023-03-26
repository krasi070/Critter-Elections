class_name GatheringSpotPlacesContainer
extends GridContainer
# GatheringSpotPlacesContainer's script.

signal selected_place(button)
signal deselected_place

const TAKEN_PLACE_TEXTURE_RECT_SCENE: PackedScene = \
	preload("res://scenes/ui/TakenPlaceTextureRect.tscn")
const FREE_SPACE_BUTTON_SCENE: PackedScene = \
	preload("res://scenes/ui/buttons/FreeSpaceButton.tscn")
const WORKER_FREE_SPACE_BUTTON_GROUP: ButtonGroup = \
	preload("res://assets/button_groups/WorkerFreeSpaceButtonGroup.tres")

var _last_pressed: Button

# Calls queue_free on every direct child of the container.
func free_children() -> void:
	for child in get_children():
		child.queue_free()

# Creates and returns a taken place TextureRect instance and adds it to the container.
func create_taken_place_instance(worker_data: Dictionary, production_time: float, index: int) -> TextureRect:
	var taken_instance: TextureRect = TAKEN_PLACE_TEXTURE_RECT_SCENE.instance()
	add_child(taken_instance)
	taken_instance.set_values(worker_data, production_time, index)
	return taken_instance

# Creates and returns a taken place TextureRect instance and adds it to the container.
func create_free_space_button_instance(index: int, is_selected: bool = false) -> Button:
	var free_instance: Button = FREE_SPACE_BUTTON_SCENE.instance()
	free_instance.group = WORKER_FREE_SPACE_BUTTON_GROUP
	add_child(free_instance)
	free_instance.pressed = is_selected
	free_instance.connect("pressed", self, "_pressed_free_space_button", [free_instance, index])
	return free_instance


func _pressed_free_space_button(button: Button, index: int) -> void:
	if is_instance_valid(_last_pressed) and button == _last_pressed:
		button.pressed = false
		_last_pressed = null
		emit_signal("deselected_place")
		return
	_last_pressed = button
	emit_signal("selected_place", button, index)

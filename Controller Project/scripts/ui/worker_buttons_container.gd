class_name WorkerButtonsContainer
extends Panel
# WorkerButtonsContainer's script.

const WORKER_BUTTON_SCENE: PackedScene = preload("res://scenes/ui/buttons/WorkerButton.tscn")

onready var vbox: VBoxContainer = $MarginContainer/WorkerButtonsContainer/VBoxContanier

# Calls queue_free on every direct child of the container.
func free_children() -> void:
	for child in vbox.get_children():
		child.queue_free()

# Calls queue_free on the child of the container with the given index.
func free_child_at_index(index: int) -> void:
	if vbox.get_child_count() <= index:
		return
	var child: Node = vbox.get_child(index)
	vbox.remove_child(child)
	child.queue_free()

# Creates and returns a worker button and adds it to the container.
func create_worker_button(worker_data: Dictionary, rank: int = 0, show_prices: bool = false) -> Button:
	var instance: Button = WORKER_BUTTON_SCENE.instance()
	vbox.add_child(instance)
	instance.set_worker_data(worker_data, rank)
	instance.set_hire_worker_elements_visibility(show_prices)
	return instance

# Update the buttons after hiring spot was updated.
func update_for_hire_worker_buttons() -> void:
	if PlayerData.location_type != Enums.LocationType.HIRING_SPOT:
		return
	var missing_index: int = _get_index_of_missing_worker()
	free_child_at_index(missing_index)
	for i in range(vbox.get_child_count()):
		var button: Button = vbox.get_child(i)
		button.set_worker_data(button.get_worker_data(), i)

# Reranks the worker buttons in the conatiner based on their
# position as a child of the container. Starts from 0.
func rerank_worker_buttons() -> void:
	var worker_buttons: Array = vbox.get_children()
	for i in range(worker_buttons.size()):
		worker_buttons[i].rank = i

# Frees the button with the given name.
func free_worker_button(button_name: String) -> void:
	vbox.get_node(button_name).queue_free()


func _get_index_of_missing_worker() -> int:
	var worker_buttons: Array = vbox.get_children()
	for i in range(worker_buttons.size()):
		var worker_data: Dictionary = worker_buttons[i].get_worker_data()
		if worker_data.empty():
			return -1
		if worker_data.id != PlayerData.location_data.for_hire[i].id:
			return i
	return -1

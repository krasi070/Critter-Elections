class_name WorkerDataContainer
extends HBoxContainer
# WorkerDataContainer's script.

onready var working_workers_amount_label: Label = \
	$WorkingWorkersContainer/AmountLabel
onready var working_workers_anim_player: AnimationPlayer = \
	$WorkingWorkersContainer/AnimationPlayer
onready var available_workers_amount_label: Label = \
	$AvailableWorkersContainer/AmountLabel
onready var available_workers_anim_player: AnimationPlayer = \
	$AvailableWorkersContainer/AnimationPlayer
onready var recruiting_workers_amount_label: Label = \
	$HoneycombContainer/AmountLabel
onready var recruiting_workers_anim_player: AnimationPlayer = \
	$HoneycombContainer/AnimationPlayer

func _ready() -> void:
	_connect_signals()
	_set_initial_values()
	update_labels_based_on_player_data()

# Updates the labels according to the worker data in PlayerData.
func update_labels_based_on_player_data() -> void:
	_update_value(
		PlayerData.get_amount_of_working_workers(), 
		working_workers_amount_label,
		working_workers_anim_player)
	_update_value(
		PlayerData.get_amount_of_available_workers(),
		available_workers_amount_label,
		available_workers_anim_player)
	_update_value(
		PlayerData.resources[Enums.Resource.HONEYCOMB],
		recruiting_workers_amount_label,
		recruiting_workers_anim_player)


func _update_value(new_value: int, label: Label, anim_player: AnimationPlayer) -> void:
	var old_value: int = int(label.text)
	if old_value == new_value:
		return
	label.text = str(new_value)
	anim_player.play("change_value")


func _set_initial_values() -> void:
	working_workers_amount_label.text = str(PlayerData.get_amount_of_working_workers())
	available_workers_amount_label.text = str(PlayerData.get_amount_of_available_workers())
	recruiting_workers_amount_label.text = str(PlayerData.resources[Enums.Resource.HONEYCOMB])


func _connect_signals() -> void:
	PlayerData.connect("updated_workers", self, "_player_data_updated_workers")


func _player_data_updated_workers() -> void:
	update_labels_based_on_player_data()

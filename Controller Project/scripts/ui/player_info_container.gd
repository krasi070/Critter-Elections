extends HBoxContainer
# PlayerInfoContainer's script.
# Represents a number pad that can be connected to a LineEdit.

const ROOM_MASTER_SUFFIX: String = " (RM)"

# The first half of the player's name.
var start_name: String setget set_start_name
# The second half of the player's name.
var end_name: String setget set_end_name

onready var name_label: Label = $NameLabel

func _ready() -> void:
	reset()

# Sets all the labels' texts according to the data in PlayerData.
func set_all() -> void:
	name_label.text = PlayerData.get_full_name()
	_add_room_master_suffix()

# Sets all the labels' texts to the empty string. If PlayerData has
# start and end names, use those.
func reset() -> void:
	name_label.text = ""
	start_name = ""
	end_name = ""
	if not PlayerData.start_name.empty():
		start_name = PlayerData.start_name
	if not PlayerData.end_name.empty():
		end_name = PlayerData.end_name

# Sets the first half of the player's name and updates the name label.
func set_start_name(_start_name: String) -> void:
	start_name = _start_name
	update_name_label()

# Sets the second half of the player's name and updates the name label.
func set_end_name(_end_name: String) -> void:
	end_name = _end_name
	update_name_label()

# Sets the name label by combining start_name and end_name.
func update_name_label() -> void:
	name_label.text = "%s %s" % [start_name, end_name]
	_add_room_master_suffix()


func _add_room_master_suffix() -> void:
	if PlayerData.is_room_master() and \
		not start_name.empty() and not end_name.empty():
		name_label.text += ROOM_MASTER_SUFFIX

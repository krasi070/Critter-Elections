class_name ResourceDataContainer
extends HBoxContainer
# ResourceDataContainer's script.
# Holds the visual elements that show the amount of resources a player has.

onready var money_label: Label = $MoneyContainer/AmountLabel
onready var money_anim_player: AnimationPlayer = $MoneyContainer/AnimationPlayer
onready var cheese_label: Label = $CheeseContainer/AmountLabel
onready var cheese_anim_player: AnimationPlayer = $CheeseContainer/AnimationPlayer
onready var ice_label: Label = $IceContainer/AmountLabel
onready var ice_anim_player: AnimationPlayer = $IceContainer/AnimationPlayer
onready var leaves_label: Label = $LeavesContainer/AmountLabel
onready var leaves_anim_player: AnimationPlayer = $LeavesContainer/AnimationPlayer

func _ready() -> void:
	_connect_signals()
	_set_initial_values()


func _connect_signals() -> void:
	PlayerData.connect("updated_resources", self, "_player_data_updated_resources")


func _update_labels_based_on_player_data() -> void:
	_update_value(PlayerData.resources[Enums.Resource.MONEY], money_label, money_anim_player)
	_update_value(PlayerData.resources[Enums.Resource.CHEESE], cheese_label, cheese_anim_player)
	_update_value(PlayerData.resources[Enums.Resource.ICE], ice_label, ice_anim_player)
	_update_value(PlayerData.resources[Enums.Resource.LEAVES], leaves_label, leaves_anim_player)


func _update_value(new_value: int, label: Label, anim_player: AnimationPlayer) -> void:
	var old_value: int = int(label.text)
	if old_value == new_value:
		return
	label.text = str(new_value)
	anim_player.play("change_value")


func _set_initial_values() -> void:
	money_label.text = str(PlayerData.resources[Enums.Resource.MONEY])
	cheese_label.text = str(PlayerData.resources[Enums.Resource.CHEESE])
	ice_label.text = str(PlayerData.resources[Enums.Resource.ICE])
	leaves_label.text = str(PlayerData.resources[Enums.Resource.LEAVES])


func _player_data_updated_resources() -> void:
	#NotificationManager.new_notification("You got new resources!")
	_update_labels_based_on_player_data()

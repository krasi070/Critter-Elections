extends CanvasLayer
# NotificationManager's script. Holds containers for placing notification
# messages and is responsible for their handling.

const NOTIF_SCENE: PackedScene = preload("res://scenes/ui/NotificationMessage.tscn")
const DEFAULT_PLACEMENT: int = Enums.NotificationPlacement.TOP

onready var containers: Dictionary = {
	Enums.NotificationPlacement.TOP: $TopMessageContainer,
	Enums.NotificationPlacement.CENTER: $CenterMessageContainer,
	Enums.NotificationPlacement.BOTTOM: $BottomMessageContainer,
}

func _ready() -> void:
	_hide_all_containers()

# Create a notification instance based on the given arguments.
func new_notification(text: String, placement: int = DEFAULT_PLACEMENT) -> void:
	containers[placement].show()
	var notif_instance: Control = NOTIF_SCENE.instance()
	notif_instance.connect("message_freed", self, "_notification_message_freed", [placement])
	containers[placement].add_child(notif_instance)
	notif_instance.rich_text.bbcode_text = text


func _hide_all_containers() -> void:
	for container in containers.values():
		container.hide()


func _notification_message_freed(placement: int) -> void:
	yield(get_tree().create_timer(0.05), "timeout")
	if containers[placement].get_child_count() == 0:
		containers[placement].hide()

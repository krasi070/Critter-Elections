extends Button
# MenuButton's script.

func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	connect("mouse_entered", self, "_mouse_entered")
	connect("pressed", self, "_pressed")


func _mouse_entered() -> void:
	AudioController.play_ui_sound(AudioController.HOVER_SOUND)


func _pressed() -> void:
	AudioController.play_ui_sound(AudioController.CLICK_SOUND)

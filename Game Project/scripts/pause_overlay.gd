extends CanvasLayer
# PauseOverlay's script.

var is_pausible: bool = false

onready var main_control: Control = $MainControl
onready var resume_button: Button = \
	$MainControl/TransparentBackground/VBoxContainer/ResumeButton
onready var title_screen_button: Button = \
	$MainControl/TransparentBackground/VBoxContainer/ReturnToTitleScreenButton

func _ready() -> void:
	hide()
	_connect_signals()


func _input(event: InputEvent) -> void:
	if is_pausible and event.is_action_pressed("toggle_pause"):
		if get_tree().paused:
			unpause()
		else:
			pause()

# Shows the pause overlay. Sends pause requests to connected players.
# Pauses the tree.
func pause() -> void:
	show()
	MatchRoomManager.pause_players()
	get_tree().paused = true

# Hides the pause overlay. Sends unpause requests to connected players.
# Unpauses the tree.
func unpause() -> void:
	MatchRoomManager.unpause_players()
	get_tree().paused = false
	hide()


func _connect_signals() -> void:
	resume_button.connect("pressed", self, "_pressed_resume_button")
	title_screen_button.connect("pressed", self, "_pressed_title_screen_button")
	MatchRoomManager.connect("closed_room", self, "_match_room_manager_closed_room")


func _pressed_resume_button() -> void:
	unpause()


func _pressed_title_screen_button() -> void:
	MatchRoomManager.send_disconnect_players_request()
	MatchRoomManager.send_close_room_request()


func _match_room_manager_closed_room() -> void:
	get_tree().paused = false
	hide()
	get_tree().change_scene(Paths.TITLE_SCREEN_SCENE_PATH)

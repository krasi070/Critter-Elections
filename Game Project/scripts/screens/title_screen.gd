extends Control
# TitleScreen's script.
# Mainly handles executing the actions of the buttons in the title screen
# when pressed.

signal pressed_play

const PLAY_BUTTON_TEXT_DEFAULT: String = "Play"
const PLAY_BUTTON_TEXT_CONNECTING: String = "Connecting..."

# Main menu view elements.
onready var main_menu_container: VBoxContainer = $MainContainer
onready var play_button: Button = $MainContainer/PlayButton
onready var options_button: Button = $MainContainer/OptionsButton
onready var quit_button: Button = $MainContainer/QuitButton

# Options menu view elements.
onready var options_container: VBoxContainer = $OptionsContainer
onready var volume_slider: Control = $OptionsContainer/VolumeSlider
onready var back_button: Button = $OptionsContainer/BackButton

func _ready() -> void:
	Server.disconnect_from_server()
	_connect_signals()
	_show_main_menu_view()
	_set_play_button_state(false)
	AudioController.play_music(AudioController.MAIN_THEME)


func _connect_signals() -> void:
	play_button.connect("pressed", self, "_pressed_play_button")
	options_button.connect("pressed", self, "_pressed_options_button")
	quit_button.connect("pressed", self, "_pressed_quit_button")
	back_button.connect("pressed", self, "_pressed_back_button")
	Server.attempt_connection_on_signal_emitted(self, "pressed_play")
	Server.connect("connected_to_server", self, "_server_connected_to_server")
	Server.connect("connection_failed", self, "_server_connection_failed")
	MatchRoomManager.connect("created_room", self, "_match_room_manager_created_room")


func _show_main_menu_view() -> void:
	main_menu_container.show()
	options_container.hide()


func _show_options_view() -> void:
	main_menu_container.hide()
	options_container.show()


func _set_play_button_state(is_connecting: bool) -> void:
	if is_connecting:
		play_button.text = PLAY_BUTTON_TEXT_CONNECTING
		play_button.disabled = true
	else:
		play_button.text = PLAY_BUTTON_TEXT_DEFAULT
		play_button.disabled = false


func _pressed_play_button() -> void:
	emit_signal("pressed_play")
	_set_play_button_state(true)


func _pressed_options_button() -> void:
	_show_options_view()


func _pressed_quit_button() -> void:
	get_tree().quit()


func _pressed_back_button() -> void:
	_show_main_menu_view()


func _server_connected_to_server() -> void:
	print("ROOM CLIENT: Sending create room request!")
	MatchRoomManager.send_create_room_request()


func _server_connection_failed() -> void:
	_set_play_button_state(false)


func _match_room_manager_created_room(_key: String) -> void:
	get_tree().change_scene(Paths.ROOM_CREATION_SCENE_PATH)

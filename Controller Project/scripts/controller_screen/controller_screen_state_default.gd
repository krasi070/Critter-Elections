class_name ControllerScreenStateDefault
extends State
# An abstract state of the ControllerScreen to be inherited from.

const WAITING_FOR_TEAMMATE_TO_EXCHANGE_MSG: String = "Waiting for teammate..."

var can_move_with_keyboard: bool = false

# Intended to be set by inheritors.
var _exchange_button_text: String

func _input(event: InputEvent) -> void:
	if not is_instance_valid(fsm.state_curr):
		return
	if not can_move_with_keyboard:
		return
	if not obj.is_desktop_mode_on:
		return
	if event.is_action_pressed("up"):
		_pressed_direction_button(Vector2.UP)
	elif event.is_action_pressed("down"):
		_pressed_direction_button(Vector2.DOWN)
	elif event.is_action_pressed("right"):
		_pressed_direction_button(Vector2.RIGHT)
	elif event.is_action_pressed("left"):
		_pressed_direction_button(Vector2.LEFT)
	if event.is_action_pressed("talk"):
		_pressed_character_button()


func on_enter() -> void:
	_connect_signals()
	obj.hide_all_input_containers()
	_set_elements_visibility(true)


func on_exit() -> void:
	_disconnect_signals()
	_set_elements_visibility(false)
	if PlayerData.is_exchanging:
		MatchRoomManager.send_cancel_exchaning_with_teammate_request()


func run(_delta: float) -> void:
	pass


func _set_elements_visibility(is_visible: bool) -> void:
	if obj.is_desktop_mode_on:
		obj.dir_buttons_container.visible = is_visible
		obj.swipe_box_container.visible = false
	else:
		obj.dir_buttons_container.visible = false
		obj.swipe_box_container.visible = is_visible
	obj.action_buttons_container.visible = is_visible


func _show_actions_based_on_location_type() -> void:
	obj.action_buttons_container.set_action_button_visibility(
		_exchange_button_text, PlayerData.is_next_to_teammate())


func _show_character_speech() -> void:
	MatchRoomManager.send_show_character_speech_request()


func _connect_signals() -> void:
	obj.swipe_box.connect("swiped", self, "_swiped_swipe_box")
	obj.swipe_box.connect("tapped_character", self, "_tapped_character_swipe_box")
	obj.connect("updated_desktop_mode", self, "_controller_screen_updated_desktop_mode")
	obj.character_button.connect("pressed", self, "_pressed_character_button")
	obj.up_button.connect(
		"pressed", 
		self, 
		"_pressed_direction_button", 
		[Vector2.UP])
	obj.down_button.connect(
		"pressed", 
		self, 
		"_pressed_direction_button", 
		[Vector2.DOWN])
	obj.left_button.connect(
		"pressed", 
		self, 
		"_pressed_direction_button", 
		[Vector2.LEFT])
	obj.right_button.connect(
		"pressed", 
		self, 
		"_pressed_direction_button", 
		[Vector2.RIGHT])
	MovementManager.connect(
		"updated_location", 
		self, 
		"_movement_manager_updated_location")
	PlayerData.connect(
		"updated_teammate_data", 
		self, 
		"_player_data_updated_team_data")
	PlayerData.connect(
		"is_exchanging_value_changed", 
		self, 
		"_player_data_is_exchanging_value_changed")


func _disconnect_signals() -> void:
	obj.swipe_box.disconnect("swiped", self, "_swiped_swipe_box")
	obj.swipe_box.disconnect("tapped_character", self, "_tapped_character_swipe_box")
	obj.disconnect("updated_desktop_mode", self, "_controller_screen_updated_desktop_mode")
	obj.character_button.disconnect("pressed", self, "_pressed_character_button")
	obj.up_button.disconnect(
		"pressed", 
		self, 
		"_pressed_direction_button")
	obj.down_button.disconnect(
		"pressed", 
		self, 
		"_pressed_direction_button")
	obj.left_button.disconnect(
		"pressed", 
		self, 
		"_pressed_direction_button")
	obj.right_button.disconnect(
		"pressed", 
		self, 
		"_pressed_direction_button")
	MovementManager.disconnect(
		"updated_location", 
		self, 
		"_movement_manager_updated_location")
	PlayerData.disconnect(
		"updated_teammate_data", 
		self, 
		"_player_data_updated_team_data")
	PlayerData.disconnect(
		"is_exchanging_value_changed", 
		self, 
		"_player_data_is_exchanging_value_changed")


func _pressed_character_button() -> void:
	_show_character_speech()


func _pressed_direction_button(dir: Vector2) -> void:
	if not obj.is_desktop_mode_on:
		return
	MovementManager.send_move_request(dir)


func _tapped_character_swipe_box() -> void:
	_show_character_speech()


func _swiped_swipe_box(dir: Vector2) -> void:
	if obj.is_desktop_mode_on:
		return
	MovementManager.send_move_request(dir)


func _controller_screen_updated_desktop_mode() -> void:
	_set_elements_visibility(true)


func _movement_manager_updated_location() -> void:
	_show_actions_based_on_location_type()
	if PlayerData.is_exchanging:
		MatchRoomManager.send_cancel_exchaning_with_teammate_request()


func _player_data_updated_team_data() -> void:
	if not PlayerData.is_next_to_teammate():
		MatchRoomManager.send_cancel_exchaning_with_teammate_request()
	obj.action_buttons_container.set_action_button_visibility(
		_exchange_button_text,
		PlayerData.is_next_to_teammate())


func _pressed_exchange_resources_button() -> void:
	MatchRoomManager.send_exchange_with_teammate_request()
	print("PLAYER CLIENT: Pressed exchange money for resources button!")


func _player_data_is_exchanging_value_changed() -> void:
	if PlayerData.is_exchanging:
		obj.action_buttons_container.set_action_button_disabled(
			_exchange_button_text,
			true)
		obj.action_buttons_container.set_new_button_text(
			_exchange_button_text,
			WAITING_FOR_TEAMMATE_TO_EXCHANGE_MSG)
		return
	obj.action_buttons_container.set_action_button_disabled(
		_exchange_button_text,
		false)
	obj.action_buttons_container.set_new_button_text(
		_exchange_button_text, 
		_exchange_button_text)

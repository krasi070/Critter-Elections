extends Control
# ControllerScreen's script.
# Handles showing the correct inputs based the player state.

signal updated_desktop_mode

const NO_ACTIVITY_WAIT_TIME: float = 15.0

const CAMPAIGNER_RESOURCE_PANEL_HEIGHT: int = 92
const GATHERER_RESOURCE_PANEL_HEIGHT: int = 160

const ENTRY_SCREEN_SCENE_PATH: String = "res://scenes/screens/EntryScreen.tscn"
const CHARACTER_SPRITE_PATH_FORMAT: String = "res://assets/sprites/player_characters/%s_%s.png"

# If desktop mode is on, show arrow buttons and allow keyboard input.
var is_desktop_mode_on: bool = false

# The finite state machine.
var fsm: FiniteStateMachine

onready var main_container: VBoxContainer = \
	$MainContainer
onready var player_info_container: HBoxContainer = \
	$TopBarContainer/PlayerInfoContainer
onready var desktop_mode_button: Button = \
	$TopBarContainer/DesktopModeButton
onready var up_button: Button = \
	$MainContainer/DirectionalButtonsContainer/UpButtonContainer/UpButton
onready var down_button: Button = \
	$MainContainer/DirectionalButtonsContainer/DownButtonContainer/DownButton
onready var left_button: Button = \
	$MainContainer/DirectionalButtonsContainer/LeftButtonContainer/LeftButton
onready var right_button: Button = \
	$MainContainer/DirectionalButtonsContainer/RightButtonContainer/RightButton
onready var character_button: Button = \
	$MainContainer/DirectionalButtonsContainer/CharacterButton
onready var dir_buttons_container: GridContainer = \
	$MainContainer/DirectionalButtonsContainer
onready var action_buttons_container: VBoxContainer = \
	$MainContainer/ActionButtonsContainer
onready var event_character_data_container: VBoxContainer = \
	$MainContainer/EventCharacterDataContainer
onready var resources_panel: Panel = \
	$MainContainer/ResourcesPanel
onready var helper_label: Label = \
	$MainContainer/HelperTextLabel
onready var worker_data_container: HBoxContainer = \
	$MainContainer/ResourcesPanel/MarginContainer/RowsContainer/WorkerDataContainer
onready var gathering_spot_data_container: HBoxContainer = \
	$MainContainer/GatheringSpotDataContainer
onready var gathering_spot_places_container: GridContainer = \
	$MainContainer/GatheringSpotPlacesContainer
onready var worker_buttons_container: Panel = \
	$MainContainer/WorkerButtonsContainer
onready var swipe_box_container: VBoxContainer = \
	$MainContainer/SwipeBoxContainer
onready var swipe_box: Control = \
	$MainContainer/SwipeBoxContainer/SwipeDetectorBox
onready var no_activity_container: MarginContainer = $NoActivityHelperContainer
onready var no_activity_helper_label: Label = \
	$NoActivityHelperContainer/NoActivityHelperLabel
onready var no_activity_timer: Timer = $NoActivityTimer
onready var pause_elements_container: VBoxContainer = $PauseElementsContainer

func _ready() -> void:
	_init_fsm()
	_connect_always_on_signals()
	_set_resources_visibility()
	player_info_container.set_all()
	show_unpaused_view()
	_update_desktop_mode_button_text()
	_update_actions_button_alignment_based_on_desktop_mode()
	_set_character_sprite()


func _physics_process(delta: float) -> void:
	fsm.run_machine(delta)

# Create buttons based on button text and on pressed function name and add
# them to action_buttons_container. Removes any previous existing buttons.
func create_action_buttons(signal_target: Object, button_data: Dictionary) -> void:
	action_buttons_container.free_action_buttons()
	action_buttons_container.create_action_buttons(signal_target, button_data)

# Hide the buttons in action_buttons_container.
func hide_all_action_buttons() -> void:
	action_buttons_container.hide_all_action_buttons()

# Hide the directional, action and worker button containers.
func hide_all_input_containers() -> void:
	helper_label.hide()
	dir_buttons_container.hide()
	action_buttons_container.hide()
	event_character_data_container.hide()
	gathering_spot_data_container.hide()
	gathering_spot_places_container.hide()
	worker_buttons_container.hide()
	swipe_box_container.hide()

# Hide all buttons from view.
func hide_all_buttons() -> void:
	dir_buttons_container.hide()
	action_buttons_container.hide()

# Hides main container and shows the pause label.
func show_paused_view() -> void:
	main_container.hide()
	no_activity_container.hide()
	pause_elements_container.show()

# Shows main container and hides the pause label.
func show_unpaused_view() -> void:
	main_container.show()
	no_activity_container.hide()
	pause_elements_container.hide()

# Free all the buttons, which are children of action_buttons_container.
func free_action_buttons() -> void:
	action_buttons_container.free_action_buttons()

# Starts the no activity timer.
func start_no_activity_timer() -> void:
	no_activity_container.hide()
	no_activity_timer.start(NO_ACTIVITY_WAIT_TIME)


func _set_resources_visibility() -> void:
	if PlayerData.team_role == Enums.Role.GATHERER:
		worker_data_container.visible = true
		resources_panel.rect_min_size = Vector2(
			resources_panel.rect_min_size.x,
			GATHERER_RESOURCE_PANEL_HEIGHT)
		worker_data_container.update_labels_based_on_player_data()
	else:
		worker_data_container.visible = false
		resources_panel.rect_min_size = Vector2(
			resources_panel.rect_min_size.x,
			CAMPAIGNER_RESOURCE_PANEL_HEIGHT)


func _init_fsm() -> void:
	if PlayerData.team_role == Enums.Role.CAMPAIGNER:
		fsm = FiniteStateMachine.new(self, $States, $States/DefaultCampaigner, true)
		fsm.states.Paused.default_return_state = $States/DefaultCampaigner
		fsm.states.CandidatePredictions.default_return_state = $States/DefaultCampaigner
	else:
		fsm = FiniteStateMachine.new(self, $States, $States/DefaultGatherer, true)
		fsm.states.Paused.default_return_state = $States/DefaultGatherer
		fsm.states.CandidatePredictions.default_return_state = $States/DefaultGatherer


func _set_character_sprite() -> void:
	var texture: Texture = _get_character_sprite(PlayerData.team_index, PlayerData.team_role)
	character_button.icon = texture
	swipe_box.character_texture_rect.texture = texture


func _get_character_sprite(team: int, role: int) -> Texture:
	var sprite_path: String = _get_sprite_path_for_character(team, role)
	var sprite_texture: Texture = load(sprite_path)
	return sprite_texture


func _get_sprite_path_for_character(team: int, role: int) -> String:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	var role_str: String = Enums.to_str_snake_case(Enums.Role, role)
	return CHARACTER_SPRITE_PATH_FORMAT % [team_str, role_str]


func _update_desktop_mode_button_text() -> void:
	if is_desktop_mode_on:
		desktop_mode_button.text = "Desktop Mode: ON"
	else:
		desktop_mode_button.text = "Desktop Mode: OFF"


func _update_actions_button_alignment_based_on_desktop_mode() -> void:
	if is_desktop_mode_on:
		action_buttons_container.alignment = action_buttons_container.ALIGN_BEGIN
	else:
		action_buttons_container.alignment = action_buttons_container.ALIGN_END


func _connect_always_on_signals() -> void:
	desktop_mode_button.connect("pressed", self, "_pressed_desktop_mode_button")
	PlayerData.connect("join_order_changed", self, "_player_data_join_order_changed")
	MatchRoomManager.connect("requested_to_go_back_to_team_selection", self, "_match_room_manager_requested_to_go_back_to_team_selection")
	MatchRoomManager.connect("left_room", self, "_match_room_manager_left_room")


func _pressed_desktop_mode_button() -> void:
	is_desktop_mode_on = not is_desktop_mode_on
	_update_actions_button_alignment_based_on_desktop_mode()
	_update_desktop_mode_button_text()
	emit_signal("updated_desktop_mode")


func _player_data_join_order_changed() -> void:
	player_info_container.update_name_label()


func _match_room_manager_requested_to_go_back_to_team_selection() -> void:
	get_tree().paused = false
	get_tree().change_scene(ENTRY_SCREEN_SCENE_PATH)


func _match_room_manager_left_room() -> void:
	get_tree().paused = false
	get_tree().change_scene(ENTRY_SCREEN_SCENE_PATH)

extends Control
# RoomCreationScreen's script.
# Shows visual data about the room, such as who is in it.

const ROOM_KEY_FORMAT: String = "[center][wave amp=50 freq=6]%s[/wave][/center]"

onready var room_key_label: RichTextLabel = \
	$MarginContainer/MainContainer/JoinGameInfoContainer/RoomKeyLabel
onready var player_info: TextEdit = \
	$MarginContainer/MainContainer/JoinedPlayersContainer/PlayerInfoTextEdit
onready var map_size_setting: HBoxContainer = \
	$MarginContainer/MainContainer/JoinGameInfoContainer/MapSizeSettingContainer
onready var number_of_rounds_setting: HBoxContainer = \
	$MarginContainer/MainContainer/JoinGameInfoContainer/NumberOfRoundsSettingContainer
onready var round_duration_setting: HBoxContainer = \
	$MarginContainer/MainContainer/JoinGameInfoContainer/RoundDurationSettingContainer
onready var exit_room_btn: Button = \
	$MarginContainer/MainContainer/JoinGameInfoContainer/ExitRoomButtonContainer/ExitRoomButton

func _ready() -> void:
	_connect_signals()
	_set_up_settings()
	_set_initial_text_values()


func _set_up_settings() -> void:
	map_size_setting.set_options("map_size", Settings.map_size_options, 1)
	number_of_rounds_setting.set_options("number_of_rounds", Settings.number_of_rounds_options, 1)
	round_duration_setting.set_options("round_duration", Settings.round_duration_options, 0)


func _connect_signals() -> void:
	exit_room_btn.connect("pressed", self, "_exit_room_btn_pressed")
	MatchRoomManager.connect("closed_room", self, "_match_room_manager_closed_room")
	MatchRoomManager.connect("updated_players", self, "_match_room_manager_updated_players")
	MatchRoomManager.connect("game_started", self, "_match_room_manager_game_started")


func _set_initial_text_values() -> void:
	_update_player_list(MatchRoomManager.players.values())
	room_key_label.bbcode_text = ROOM_KEY_FORMAT % MatchRoomManager.room_key


func _update_player_list(players: Array) -> void:
	var player_names: String = ""
	for player in players:
		player_names += player.name
		if player.join_order == 0:
			player_names += " (Room Master)"
		player_names += "\n"
	player_info.show_line_numbers = player_names.length() > 0
	player_info.text = player_names.trim_suffix("\n")


func _exit_room_btn_pressed() -> void:
	MatchRoomManager.send_close_room_request()


func _match_room_manager_closed_room() -> void:
	get_tree().change_scene(Paths.TITLE_SCREEN_SCENE_PATH)


func _match_room_manager_updated_players(players: Array) -> void:
	_update_player_list(players)


func _match_room_manager_game_started() -> void:
	get_tree().change_scene(Paths.MAP_SCREEN_SCENE_PATH)

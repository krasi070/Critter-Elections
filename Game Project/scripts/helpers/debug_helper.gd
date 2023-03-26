extends CanvasLayer
# DebugHelper's script.

signal requested_create_command(obj_type, row, col)
signal requested_give_command(team_id, team_role, res_type, amount)
signal requested_set_word_level(new_level)
signal requested_show_results
signal requested_pause_round
signal requested_resume_round
signal requested_quick_start(amount)
signal requested_disconnect_player(team, role)

onready var container: MarginContainer = $MarginContainer
onready var console_text: TextEdit = $MarginContainer/BackgroundRect/Margin/VBoxContainer/ConsoleText
onready var input_line: LineEdit = $MarginContainer/BackgroundRect/Margin/VBoxContainer/InputLine

var _history: Array
var _history_index: int
var _curr_input: String

func _ready() -> void:
	console_text.text = ""
	input_line.text = ""
	container.visible = false
	_history_index = 0


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_toggle"):
		container.visible = not container.visible
	if event.is_action_pressed("debug_enter") and container.visible:
		_execute_command()
	if event.is_action_pressed("debug_up") and container.visible:
		_cycle_through_history(-1)
	if event.is_action_pressed("debug_down") and container.visible:
		_cycle_through_history(1)


func write_line(line: String) -> void:
	if not console_text.text.empty():
		console_text.text += "\n"
	console_text.text += line


func _cycle_through_history(dir: int) -> void:
	if _history_index + dir < 0 or _history_index + dir > _history.size():
		return
	_history_index += dir
	if _history_index == _history.size():
		input_line.text = ""
	else:
		input_line.text = _history[_history_index]
	input_line.grab_focus()


func _execute_command() -> void:
	write_line(input_line.text)
	_history.append(input_line.text)
	_history_index = _history.size()
	var cmd_args: PoolStringArray = input_line.text.split(" ", false)
	var cmd: String = cmd_args[0].to_lower()
	cmd_args.remove(0)
	match cmd:
		"clear":
			_clear_console()
		"create":
			_create_object(cmd_args)
		"give":
			_give_player_resources(cmd_args)
		"support":
			_support_team(cmd_args)
		"setwl":
			_set_world_level(cmd_args)
		"area_info":
			_print_area_info(cmd_args)
		"end_round":
			_end_round()
		"rpause":
			_pause_round()
		"rresume":
			_resume_round()
		"disconnect":
			_disconnect_player(cmd_args)
		"qckst":
			_set_quick_start_params(cmd_args)
		"help":
			_show_help()
		_:
			write_line("%s: Not recognized!" % input_line.text)
	input_line.text = ""


func _clear_console() -> void:
	console_text.text = ""


func _create_object(args: PoolStringArray) -> void:
	var curr_node: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if curr_node.name != "MapScreen":
		write_line("Invalid command! Currently in %s, not in MapScreen!" % curr_node.name)
		return
	if args.size() != 3:
		write_line("Expected 3 arguments! Got %d." % args.size())
		return
	var object_str: String = args[0].to_upper()
	var row: int = int(args[1])
	var col: int = int(args[2])
	emit_signal("requested_create_command", object_str, row, col)


func _give_player_resources(args: PoolStringArray) -> void:
	var curr_node: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if curr_node.name != "MapScreen":
		write_line("Invalid command! Currently in %s, not in MapScreen!" % curr_node.name)
		return
	if args.size() != 4:
		write_line("Expected 4 arguments! Got %d." % args.size())
		return
	var team_id: int = int(args[0])
	var team_role: String = args[1].to_upper()
	var amount: int = int(args[2])
	var resource_type: String = args[3].to_upper()
	emit_signal("requested_give_command", team_id, team_role, resource_type, amount)


func _support_team(args: PoolStringArray) -> void:
	var curr_node: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if curr_node.name != "MapScreen":
		write_line("Invalid command! Currently in %s, not in MapScreen!" % curr_node.name)
		return
	if args.size() != 3:
		write_line("Expected 3 arguments! Got %d." % args.size())
		return
	var team_id: int = int(args[0])
	var area_str: String = args[1].to_upper()
	var area_index: int = Enums.TileType[area_str]
	var support_amount: int = int(args[2])
	MapData.add_supporters_to_team_in_area(support_amount, team_id, area_index)


func _set_world_level(args: PoolStringArray) -> void:
	var curr_node: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if curr_node.name != "MapScreen":
		write_line("Invalid command! Currently in %s, not in MapScreen!" % curr_node.name)
		return
	if args.size() != 1:
		write_line("Expected 1 arguments! Got %d." % args.size())
		return
	var new_level: int = int(args[0])
	emit_signal("requested_set_word_level", new_level)


func _print_area_info(args: PoolStringArray) -> void:
	var curr_node: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if curr_node.name != "MapScreen":
		write_line("Invalid command! Currently in %s, not in MapScreen!" % curr_node.name)
		return
	if args.size() != 1:
		write_line("Expected 1 argument! Got %d." % args.size())
		return
	var area_str: String = args[0].to_upper()
	var area_index: int = Enums.TileType[area_str]
	write_line("[%s AREA INFO]" % area_str)
	# Print the total population of the area.
	var population: int = MapData.projections[area_index].population
	write_line("- Population: %d" % population)
	# Print the number of supporters for each candidate and their ratios.
	for team in MapData.projections[area_index].candidate_support.keys():
		var supporters: int = MapData.projections[area_index].candidate_support[team]
		var supporters_percentage: float = MapData.get_percentage_of_population_in_area(supporters, area_index)
		var team_name: String = Enums.to_str(Enums.Team, team)
		if MatchRoomManager.team_names.size() > team:
			team_name = MatchRoomManager.team_names[team]
		write_line("- %s: %d (%1.1f%%)" % [team_name, supporters, supporters_percentage])
	# Print the undecided number of residents in the area and their ratio.
	var undecided: int = MapData.projections[area_index].undecided
	var undecided_percentage: float = MapData.get_percentage_of_population_in_area(undecided, area_index)
	write_line("- Undecided: %d (%1.1f%%)" % [undecided, undecided_percentage])


func _end_round() -> void:
	emit_signal("requested_show_results")


func _pause_round() -> void:
	emit_signal("requested_pause_round")


func _resume_round() -> void:
	emit_signal("requested_resume_round")


func _disconnect_player(args: PoolStringArray) -> void:
	var curr_node: Node = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	if curr_node.name != "MapScreen":
		write_line("Invalid command! Currently in %s, not in MapScreen!" % curr_node.name)
		return
	if args.size() != 2:
		write_line("Expected 2 arguments! Got %d." % args.size())
		return
	var team_index: int = int(args[0])
	var team_role: String = args[1].to_upper()
	emit_signal("requested_disconnect_player", team_index, team_role)


func _set_quick_start_params(args: PoolStringArray) -> void:
	var amount: int = 100
	if not args.empty():
		amount = int(args[0])
	emit_signal("requested_quick_start", amount)


func _show_help() -> void:
	write_line("clear: Clears the text in the text console.")
	write_line("create [OBJ_TYPE] [ROW] [COLUMN]: In MapScreen, creates [OBJ_TYPE] at [ROW], [COLUMN].")
	write_line("give [PLAYER_TEAM_ID] [PLAYER_TEAM_ROLE] [AMOUNT] [RESOURCE_TYPE]: In Map Screen, " + \
		"gives the player with role [PLAYER_TEAM_ROLE] in team [PLAYER_TEAM_ID] [AMOUNT] [RESOURCE_TYPE].")
	write_line("support [PLAYER_TEAM_ID] [AREA] [AMOUNT]: Add [AMOUNT] supporters to team [PLAYER_TEAM_ID] in [AREA].")
	write_line("setwl [LEVEL]: Sets the world level to [LEVEL].")
	write_line("area_info [AREA]: Prints various data about the given [AREA].")
	write_line("end_round: Ends the current round and shows the projection results.")
	write_line("rpause: Pauses the timer for the current round.")
	write_line("rresume: If the round timer is paused, unpauses it.")
	write_line("disconnect [PLAYER_TEAM_ID] [PLAYER_TEAM_ROLE]: Disonnects the specified player from the room.")
	write_line("qckst [AMOUNT]: Sets every player's resources to [AMOUNT] each. [AMOUNT] is optional and 100 by default.")

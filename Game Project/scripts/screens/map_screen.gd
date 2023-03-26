extends Node2D
# MapScreen's script. 
# Manipulates the child nodes to visually display the state of the map.

const PLAYER_CHARACTER_SCENE: PackedScene = preload("res://scenes/map_objects/PlayerCharacter.tscn")
const GATHERING_SPOT_SCENE: PackedScene = preload("res://scenes/map_objects/GatheringSpot.tscn")
const HIRING_SPOT_SCENE: PackedScene = preload("res://scenes/map_objects/HiringSpot.tscn")
const EVENT_CHARACTER_SCENE: PackedScene = preload("res://scenes/map_objects/EventCharacter.tscn")
const PICKABLE_RESOURCE_SCENE: PackedScene = preload("res://scenes/map_objects/PickableResource.tscn")

const FADE_OUT_TEXT_SCENE: PackedScene = preload("res://scenes/ui/FadeOutText.tscn")

const ROUND_TEXT_FORMAT: String = "R%d"
const FINAL_ROUND_TEXT: String = "F"

const PICKABLE_RESOURCES: Dictionary = {
	Enums.Resource.MONEY: {
		"min_amount": 1,
		"max_amount": 5,
	},
	Enums.Resource.SUPPORTER: {
		"min_amount": 1,
		"max_amount": 3,
	},
}

const SAILBOAT_START_POS: Vector2 = Vector2(96, 86)
const SAILBOAT_END_POS: Vector2 = Vector2(1834, 86)

export(int, 6, 10, 2) var rows = 8
export(int, 8, 20, 2) var columns = 14
export var area_rough_sizes: Array = [10, 7, 4]

export(float, 1.0, 100.0) var pickable_resource_spawn_time_lower = 1.0
export(float, 1.0, 100.0) var pickable_resource_spawn_time_upper = 2.0
export(float, 1.0, 100.0) var event_character_spawn_time_lower = 20.0
export(float, 1.0, 100.0) var event_character_spawn_time_upper = 40.0

onready var tile_map_layers: Node2D = $TileMapLayers
onready var shadow_layer: TileMap = $TileMapLayers/ShadowLayer
onready var ground_layer: TileMap = $TileMapLayers/GroundLayer
onready var players_y_sort: YSort = $PlayersYSort
onready var interactables_y_sort: YSort = $InteractablesYSort
onready var prediction_results_overlay: CanvasLayer = $PredictionResultsOverlay
onready var room_key_bg_texture_rect: TextureRect = $RoomKeyBackgroundTextureRect
onready var room_key_label: Label = $RoomKeyBackgroundTextureRect/MarginContainer/RoomKeyLabel
onready var sailboat_sprite: AnimatedSprite = $SailboatSprite
onready var round_label: Label = $SailboatSprite/RoundLabel
onready var time_label: Label = $SailboatSprite/TimeLabel
onready var game_timer: Timer = $GameTimer

func _ready() -> void:
	randomize()
	_set_map_size()
	_set_tile_map_offset()
	_set_tileset_cells()
	_set_map_data()
	_init_interactables()
	_init_players()
	_place_players()
	_connect_signals()
	_start_resource_timer()
	_start_event_character_timers(MapData.projections.keys())
	_set_room_key_elements()
	_start_round()
	PauseOverlay.is_pausible = true


func _physics_process(_delta: float) -> void:
	if game_timer.paused:
		time_label.text = "---"
		return
	_update_sailboat()


func _get_screen_tile_width() -> int:
	return int(ceil(1.0 * ProjectSettings.get("display/window/size/width") / ground_layer.cell_size.x))


func _get_screen_tile_height() -> int:
	return int(ceil(1.0 * ProjectSettings.get("display/window/size/height") / ground_layer.cell_size.y))


func _get_start_x() -> int:
	return (_get_screen_tile_width() - columns * tile_map_layers.scale.x) / 2


func _get_start_y() -> int:
	return (_get_screen_tile_height() - rows * tile_map_layers.scale.y) / 2


func _set_map_size() -> void:
	match Settings.map_size:
		Enums.MapSize.CRAMPED_MAP:
			rows = 8
			columns = 10
			area_rough_sizes = [8, 6, 4]
		Enums.MapSize.JUST_RIGHT_MAP:
			rows = 8
			columns = 14
			area_rough_sizes = [10, 8, 5]
		Enums.MapSize.SPACIOUS_MAP:
			rows = 8
			columns = 18
			area_rough_sizes = [14, 10, 6]


func _set_tile_map_offset() -> void:
	var x_offset: float = _get_start_x() * ground_layer.cell_size.x
	var y_offset: float = _get_start_y() * ground_layer.cell_size.y
	tile_map_layers.position = Vector2(x_offset, y_offset)


func _set_tileset_cells() -> void:
	# Clear tilemaps:
	shadow_layer.clear()
	ground_layer.clear()
	# Generate random map.
	var map: Dictionary = _generate_valid_map()
	# Set cells according to map.
	for y in range(rows):
		for x in range(columns):
			if map.has(Vector2(x, y)):
				# Set shadow layer cells.
				shadow_layer.set_cell(x * 2, y * 2, 3)
				shadow_layer.set_cell(x * 2 + 1, y * 2, 3)
				shadow_layer.set_cell(x * 2, y * 2 + 1, 3)
				shadow_layer.set_cell(x * 2 + 1, y * 2 + 1, 3)
				# Set ground layer cells.
				ground_layer.set_cell(x * 2, y * 2, map[Vector2(x, y)])
				ground_layer.set_cell(x * 2 + 1, y * 2, map[Vector2(x, y)])
				ground_layer.set_cell(x * 2, y * 2 + 1, map[Vector2(x, y)])
				ground_layer.set_cell(x * 2 + 1, y * 2 + 1, map[Vector2(x, y)])
	# Update tilemap bitmask regions.
	shadow_layer.update_bitmask_region()
	ground_layer.update_bitmask_region()


func _generate_valid_map() -> Dictionary:
	while true:
		var candidate_map: Dictionary = _generate_map()
		if _is_every_cell_reachable(candidate_map):
			return candidate_map
	return {}


func _is_every_cell_reachable(map: Dictionary) -> bool:
	var locations: Array = map.keys()
	var rand_index: int = randi() % locations.size()
	var starting_loc: Vector2 = locations.pop_at(rand_index)
	var visited_cells: int = 0
	var to_visit_queue: Array = [starting_loc]
	while to_visit_queue.size() > 0:
		var curr_loc: Vector2 = to_visit_queue.pop_front()
		visited_cells += 1
		if locations.has(curr_loc + Vector2.UP):
			to_visit_queue.append(curr_loc + Vector2.UP)
			locations.erase(curr_loc + Vector2.UP)
		if locations.has(curr_loc + Vector2.RIGHT):
			to_visit_queue.append(curr_loc + Vector2.RIGHT)
			locations.erase(curr_loc + Vector2.RIGHT)
		if locations.has(curr_loc + Vector2.DOWN):
			to_visit_queue.append(curr_loc + Vector2.DOWN)
			locations.erase(curr_loc + Vector2.DOWN)
		if locations.has(curr_loc + Vector2.LEFT):
			to_visit_queue.append(curr_loc + Vector2.LEFT)
			locations.erase(curr_loc + Vector2.LEFT)
	print("Total: %d, Visited: %d" % [map.size(), visited_cells])
	return visited_cells == map.size()


func _generate_map() -> Dictionary:
	# Variables.
	var map: Dictionary = {}
	var data: Dictionary = {}
	var amounts: Array = area_rough_sizes.duplicate()
	var tile_types: Array = Enums.TileType.values()
	var corners: Array = [
		Vector2(1, 1),
		Vector2(columns / 2 - 2, 1),
		Vector2(1, rows / 2 - 2),
		Vector2(columns / 2 - 2, rows / 2 - 2),
	]
	# Decrease each area amount by 1 after placeing corners.
	for i in range(amounts.size()):
		amounts[i] -= 1
	# Randomizing.
	corners.shuffle()
	tile_types.shuffle()
	amounts.shuffle()
	for _i in Enums.TileType.size():
		var type: int = tile_types.pop_front()
		var corner: Vector2 = corners.pop_front()
		var amount: int = amounts.pop_front()
		data[type] = {
			"points": [corner],
			"amount": amount,
		}
		map[corner] = type
	_extend_points(data, map)
	return map


func _extend_points(data: Dictionary, map: Dictionary) -> void:
	var map_size: Vector2 = Vector2(columns / 2, rows / 2)
	while data.size() > 0:
		for type in data.keys():
			var rand_index: int = randi() % data[type].points.size()
			var point: Vector2 = data[type].points[rand_index]
			var rand_dir: Vector2 = _get_random_free_direction(map, map_size, point)
			if rand_dir == Vector2.ZERO:
				data[type].points.remove(rand_index)
			else:
				map[point + rand_dir] = type
				data[type].points.append(point + rand_dir)
				data[type].amount -= 1
				if data[type].amount == 0:
					data.erase(type)
			if data.has(type) and data[type].points.size() == 0:
				data.erase(type)


func _get_random_free_direction(map: Dictionary, map_size: Vector2, from: Vector2) -> Vector2:
	var directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	directions.shuffle()
	for dir in directions:
		var loc: Vector2 = from + dir
		if loc.x >= 0 and loc.x < map_size.x and \
			loc.y >= 0 and loc.y < map_size.y and \
			not map.has(loc):
			return dir
	return Vector2.ZERO


func _start_event_character_timers(areas: Array) -> void:
	for area in areas:
		var rand_time: float = rand_range(
			event_character_spawn_time_lower, 
			event_character_spawn_time_upper)
		var timer: SceneTreeTimer = get_tree().create_timer(rand_time, false)
		timer.connect("timeout", self, "_event_character_timer_timeout", [area])


func _start_resource_timer() -> void:
	var rand_time: float = rand_range(
		pickable_resource_spawn_time_lower, 
		pickable_resource_spawn_time_upper)
	var timer: SceneTreeTimer = get_tree().create_timer(rand_time, false)
	timer.connect("timeout", self, "_resource_timer_timeout")


func _set_room_key_elements() -> void:
	var colors: Array = ["blue", "green"]
	colors.shuffle()
	var rand_color: String = colors.pop_front()
	var box_texture: Texture = load(Paths.UI_COLOR_BOX_SPRITE_PATH_FORMAT % rand_color)
	room_key_bg_texture_rect.texture = box_texture
	room_key_label.text = MatchRoomManager.room_key


func _connect_signals() -> void:
	game_timer.connect("timeout", self, "_timeout_game_timer")
	prediction_results_overlay.connect("closed_prediction_results", self, "_closed_prediction_results")
	WorldLevelStats.connect("upgraded_first_gathering_spot", self, "_world_level_stats_upgraded_first_gathering_spot")
	MovementManager.connect("player_moved", self, "_movement_manager_player_moved")
	MatchRoomManager.connect("closed_room", self, "_match_room_manager_closed_room")
	MatchRoomManager.connect("requested_character_speech", self, "_match_room_manager_requested_character_speech")
	MatchRoomManager.connect("restarted_game", self, "_match_room_manager_restarted_game")
	MatchRoomManager.connect("requested_different_teams", self, "_match_room_manager_requested_different_teams")
	MatchRoomManager.connect("requested_teammate_exchange", self, "_match_room_manager_requested_teammate_exchange")
	MatchRoomManager.connect("cancelled_teammate_exchange", self, "_match_room_manager_cancelled_teammate_exchange")
	DebugHelper.connect("requested_create_command", self, "_debug_helper_requested_create_command")
	DebugHelper.connect("requested_show_results", self, "_debug_helper_requested_show_results")
	DebugHelper.connect("requested_pause_round", self, "_debug_helper_requested_pause_round")
	DebugHelper.connect("requested_resume_round", self, "_debug_helper_requested_resume_round")


func _start_round() -> void:
	var curr_round: int = prediction_results_overlay.curr_round + 1
	if curr_round == Settings.number_of_rounds:
		round_label.text = FINAL_ROUND_TEXT
	else:
		round_label.text = ROUND_TEXT_FORMAT % curr_round
	game_timer.start(Settings.round_duration)
	AudioController.play_music(AudioController.GAME_LOOP)


func _update_sailboat() -> void:
	var diff: Vector2 = SAILBOAT_END_POS - SAILBOAT_START_POS
	var percentage_passed: float = (Settings.round_duration - game_timer.time_left) / Settings.round_duration
	sailboat_sprite.position = Vector2(
		SAILBOAT_START_POS.x + diff.x * percentage_passed, 
		SAILBOAT_START_POS.y)
	time_label.text = "%1.0f" % game_timer.time_left


func _free_players() -> void:
	var player_nodes: Array = get_tree().get_nodes_in_group("players")
	for player in player_nodes:
		player.queue_free()


func _get_player_with_name(_name: String) -> Node:
	var player_nodes: Array = get_tree().get_nodes_in_group("players")
	for player in player_nodes:
		if player.name == _name:
			return player
	return null


func _init_players() -> void:
	for id in MatchRoomManager.players.keys():
		var player_with_same_id: Node = _get_player_with_name(str(id))
		if is_instance_valid(player_with_same_id):
			player_with_same_id.queue_free()
			yield(player_with_same_id, "tree_exited")
		var p_instance: Node2D = PLAYER_CHARACTER_SCENE.instance()
		p_instance.name = str(id)
		players_y_sort.add_child(p_instance)
		p_instance.set_sprite(
			MatchRoomManager.players[id].team, 
			MatchRoomManager.players[id].role)


func _init_interactables() -> void:
	for location in MapData.map.keys():
		_init_interactable_at_location(location)


func _init_interactable_at_location(location: Vector2) -> void:
	if not MapData.is_inside(location):
		return
	var instance: Node2D
	match MapData.map[location].type:
		Enums.LocationType.GATHERING_SPOT:
			instance = _instance_gathering_spot(location)
		Enums.LocationType.HIRING_SPOT:
			instance = _instance_hiring_spot()
		Enums.LocationType.EVENT:
			instance = _instance_character_event(location)
		Enums.LocationType.PICKABLE_RESOURCE:
			instance = _instance_pickable_resource()
	_set_interactable(instance, location)


func _instance_gathering_spot(location: Vector2) -> Node2D:
	var instance: Node2D = GATHERING_SPOT_SCENE.instance()
	instance.set_data_on_type(MapData.map[location].area_type)
	instance.connect("ready_for_production", self, "_gathering_spot_ready_for_production")
	instance.connect("worker_is_done", self, "_gathering_spot_worker_is_done")
	instance.connect("upgraded", self, "_gathering_spot_upgraded")
	return instance


func _instance_hiring_spot() -> Node2D:
	var instance: Node2D = HIRING_SPOT_SCENE.instance()
	return instance


func _instance_character_event(location: Vector2) -> Node2D:
	var instance: Node2D = EVENT_CHARACTER_SCENE.instance()
	instance.location = location
	_set_random_data_for_event_character(instance)
	instance.connect("event_ended", self, "_character_event_ended")
	return instance


func _instance_pickable_resource() -> Node2D:
	var instance: Node2D = PICKABLE_RESOURCE_SCENE.instance()
	var rand_res_index: int = randi() % PICKABLE_RESOURCES.size()
	var rand_res: int = PICKABLE_RESOURCES.keys()[rand_res_index]
	var res_max_amount: int = PICKABLE_RESOURCES[rand_res].max_amount
	var res_min_amount: int = PICKABLE_RESOURCES[rand_res].min_amount
	instance.set_data({ 
		"type": rand_res, 
		"amount": randi() % res_max_amount + res_min_amount })
	return instance


func _set_interactable(interactable: Node2D, location: Vector2) -> void:
	if not is_instance_valid(interactable):
		return
	MapData.map[location].map_object = interactable
	interactables_y_sort.add_child(interactable)
	interactable.set_location(location)


func _place_players() -> void:
	var player_nodes: Array = get_tree().get_nodes_in_group("players")
	for player in player_nodes:
		var player_id: int = int(player.name)
		MatchRoomManager.players[player_id].location = MapData._get_random_empty_tile_in_area(Enums.TileType.GREEN)
		var location: Vector2 = MatchRoomManager.players[player_id].location
		player.set_location(location)
		MapData.set_player(player_id, player)
		MovementManager.update_player_location_data(player_id)


func _set_map_data() -> void:
	MapData.reset()
	MapData.set_size(rows, columns)
	MapData.set_tile_maps(ground_layer)
	MapData.set_map()
	MapData.set_character_event_limits_based_on_areas()
	MapData.place_interactables()
	MapData.place_pickable_resources()


func _play_fade_out_text(text: String, pos: Vector2, res_type: int, team: int = Enums.Team.NOT_SELECTED) -> Control:
	var fade_out_instance: Control = FADE_OUT_TEXT_SCENE.instance()
	add_child(fade_out_instance)
	fade_out_instance.set_text(text)
	if Enums.Resource.values().has(res_type) and \
		not res_type == Enums.Resource.SUPPORTER and \
		not res_type == Enums.Resource.STEAL_SUPPORTER:
		fade_out_instance.set_resource_texture(res_type)
	if not team == Enums.Team.NOT_SELECTED:
		fade_out_instance.set_team_texture(team)
	fade_out_instance.center_at_position(pos)
	fade_out_instance.fade()
	return fade_out_instance


func _set_random_data_for_event_character(event_character: Node2D) -> void:
	var stats: Dictionary = WorldLevelStats.get_random_character_event_stats()
	var take_amount: int = int(round(rand_range(stats.take_amount_min, stats.take_amount_max)))
	var take_type: int
	var give_type: int
	var give_amount: int
	if stats.reward_type == Enums.Resource.MONEY:
		var resource_pool: Array = [Enums.Resource.CHEESE, Enums.Resource.ICE, Enums.Resource.LEAVES]
		resource_pool.shuffle()
		take_type = resource_pool.pop_front()
		give_type = Enums.Resource.MONEY
		give_amount = int(round(rand_range(stats.give_amount_min, stats.give_amount_max)))
	else:
		take_type = Enums.Resource.MONEY
		give_type = stats.reward_type
		give_amount = int(round(rand_range(stats.give_amount_min_percentage, stats.give_amount_max_percentage)))
	event_character.set_resources_data_based_on_area(
		take_type,
		take_amount,
		give_type,
		give_amount)


func _free_unsuccessful_character_events() -> void:
	var interactable_nodes: Array = get_tree().get_nodes_in_group("interactables")
	for interactable in interactable_nodes:
		if interactable is EventCharacter and interactable.is_offer_failing():
			interactable.end_event()


func _end_character_events() -> void:
	var interactable_nodes: Array = get_tree().get_nodes_in_group("interactables")
	for interactable in interactable_nodes:
		if interactable is EventCharacter:
			interactable.end_event()


func _check_if_resource_was_picked_up(player_id: int, location: Vector2) -> void:
	if MapData.map[location].type == Enums.LocationType.PICKABLE_RESOURCE:
		var resource: Node2D = MapData.map[location].map_object
		if MatchRoomManager.players[player_id].resources.has(resource.type):
			MatchRoomManager.players[player_id].resources[resource.type] += resource.amount
			MatchRoomManager.update_player(player_id)
		elif resource.type == Enums.Resource.SUPPORTER:
			MapData.pick_up_supporters(location, player_id)
		if resource.type == Enums.Resource.SUPPORTER:
			var area: int =  MapData.map[location].area_type
			var percentage: float = MapData.get_percentage_of_population_in_area(resource.amount, area)
			_play_fade_out_text(
				"+%1.2f%% in %s Area" % [percentage, Enums.to_str(Enums.TileType, area)], 
				MapData.map_location_to_world_position(location),
				resource.type)
		else:
			_play_fade_out_text(
				"+%d" % resource.amount, 
				MapData.map_location_to_world_position(location), 
				resource.type)
		MapData.remove_map_object(location)


func _end_round() -> void:
	if Settings.number_of_rounds == prediction_results_overlay.curr_round + 1:
		_end_character_events()
	prediction_results_overlay.show_prediction_results()


func _timeout_game_timer() -> void:
	_end_round()


func _closed_prediction_results() -> void:
	_free_unsuccessful_character_events()
	_start_round()


func _event_character_timer_timeout(area: int) -> void:
	var new_event_character_loc: Vector2 = MapData.place_event_character_in_area(area)
	if MapData.is_inside(new_event_character_loc):
		var instance: Node2D = _instance_character_event(new_event_character_loc)
		_set_interactable(instance, new_event_character_loc)
	_start_event_character_timers([area])


func _resource_timer_timeout() -> void:
	var new_resource_loc: Vector2 = MapData.place_pickable_resource()
	if MapData.is_inside(new_resource_loc):
		var instance: Node2D = _instance_pickable_resource()
		_set_interactable(instance, new_resource_loc)
	_start_resource_timer()


func _character_event_ended(loc: Vector2, amount: int, res_type: int, team: int, stolen_from_team: int) -> void:
	var world_pos: Vector2 = MapData.map_location_to_world_position(loc)
	if team == Enums.Team.NOT_SELECTED:
		_play_fade_out_text("No Deal", world_pos, res_type)
		return
	var area: int =  MapData.map[loc].area_type
	if res_type == Enums.Resource.STEAL_SUPPORTER:
		var text: String = "-%d%% in %s" % [amount, Enums.to_str(Enums.TileType, area)]
		var instance: Control = _play_fade_out_text(text, world_pos, res_type, stolen_from_team)
		yield(instance, "faded_out")
	var text: String
	if res_type == Enums.Resource.STEAL_SUPPORTER or \
		res_type == Enums.Resource.SUPPORTER:
		text = "+%d%% in %s" % [amount, Enums.to_str(Enums.TileType, area)]
	else:
		text = "+%d" % amount
	_play_fade_out_text(text, world_pos, res_type, team)


func _gathering_spot_ready_for_production(location: Vector2) -> void:
	var gathering_spot_obj: Node2D = MapData.map[location].map_object
	var resource_str: String = Enums.to_str(Enums.Resource, gathering_spot_obj.resource_type)
	var amount: int = gathering_spot_obj.production_amount
	var world_pos: Vector2 = MapData.map_location_to_world_position(location)
	_play_fade_out_text("%d %s" % [amount, resource_str], world_pos, false)


func _gathering_spot_worker_is_done(gathering_spot: Node2D, worker: Dictionary) -> void:
	var player_id: int = worker.employer_id
	var team: int = MatchRoomManager.get_team_by_player_id(player_id)
	var amount: int = gathering_spot.production_amount * worker.reward_multiplier
	var world_pos: Vector2 = MapData.map_location_to_world_position(gathering_spot.location)
	_play_fade_out_text("+%d" % amount, world_pos, gathering_spot.resource_type, team)


func _gathering_spot_upgraded() -> void:
	WorldLevelStats.progress_world_state()


func _world_level_stats_upgraded_first_gathering_spot() -> void:
	pass
#	var loc: Vector2 = MapData.place_starting_hiring_spot()
#	if MapData.is_inside(loc):
#		_init_interactable_at_location(loc)
#	var world_pos: Vector2 = MapData.map_location_to_world_position(loc)
#	_play_fade_out_text("NEW BUILDING", world_pos, -1)


func _match_room_manager_requested_character_speech(player_id: int) -> void:
	var player: Node = MapData.players[player_id]
	player.show_character_speech()


func _movement_manager_player_moved(player_id: int, new_location: Vector2) -> void:
	_check_if_resource_was_picked_up(player_id, new_location)


func _match_room_manager_closed_room() -> void:
	get_tree().change_scene(Paths.TITLE_SCREEN_SCENE_PATH)


func _match_room_manager_restarted_game() -> void:
	get_tree().reload_current_scene()


func _match_room_manager_requested_different_teams() -> void:
	PauseOverlay.is_pausible = false
	get_tree().paused = false
	MapData.reset()
	WorldLevelStats.reset()
	get_tree().change_scene(Paths.ROOM_CREATION_SCENE_PATH)


func _match_room_manager_requested_teammate_exchange(player_id: int) -> void:
	MapData.players[player_id].show_exchanging_speech()


func _match_room_manager_cancelled_teammate_exchange(player_id: int) -> void:
	MapData.players[player_id].cancel_exchanging_speech()


func _debug_helper_requested_create_command(obj_type: String, row: int, column: int) -> void:
	var location: Vector2 = Vector2(column, row)
	if not MapData.is_inside(location):
		DebugHelper.write_line("Invalid command! Given location is not inside the map!")
		return
	if MapData.map[location].type != Enums.LocationType.FREE_SPACE:
		DebugHelper.write_line("Invalid command! Given location is not free!")
		return
	if is_instance_valid(MapData.map[location].player):
		DebugHelper.write_line("Invalid command! Player is present in given location!")
		return
	MapData.map[location].type = Enums.LocationType[obj_type]
	_init_interactable_at_location(location)


func _debug_helper_requested_show_results() -> void:
	_end_round()


func _debug_helper_requested_pause_round() -> void:
	game_timer.paused = true


func _debug_helper_requested_resume_round() -> void:
	game_timer.paused = false

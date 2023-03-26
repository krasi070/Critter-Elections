extends Node
# Handles map form and each tile's data.

signal player_moved(player_id, old_location, new_location)

const PICKABLE_RESOURCE_LIMIT: int = 10 
const POPULATION_DENSITY: int = 25
const HIGHEST_POPULATION_AREA_CHARACTER_EVENT_LIMIT: int = 3
const DEFAULT_CHARACTER_EVENT_LIMIT: int = 2

var rows: int
var columns: int

var players: Dictionary
var map: Dictionary
var projections: Dictionary

var event_character_limits_per_area: Dictionary

var _ground_map: TileMap
var _area_tiles: Dictionary

var _curr_number_of_pickable_resources: int = 0
var _starting_pickable_money_amount_lower_bound: int = 2
var _starting_pickable_money_amount_upper_bound: int = 4

var _curr_number_of_event_charcters_per_area: Dictionary

func _ready() -> void:
	randomize()
	reset()

# Sets the rows and columns.
func set_size(_rows: int, _columns: int) -> void:
	rows = _rows
	columns = _columns

# Sets the map dictionary which shows what is on which location.
func set_map() -> void:
	for y in range(rows):
		for x in range(columns):
			_set_map_cell_according_to_ground_layer(x, y)

# Sets the TileMap instance to be used.
func set_tile_maps(ground_layer: TileMap) -> void:
	_ground_map = ground_layer

# Places the interactables for the game start.
func place_interactables() -> void:
	_place_starting_gathering_spots()
	place_starting_hiring_spot()
	_place_starting_event_characters()

func place_event_character_in_area(area: int) -> Vector2:
	if not _curr_number_of_event_charcters_per_area.has(area):
		return Vector2(-1, -1)
	if _curr_number_of_event_charcters_per_area[area] >= \
		event_character_limits_per_area[area]:
		return Vector2(-1, -1)
	var loc: Vector2 = _get_random_empty_tile_in_area(area)
	map[loc].type = Enums.LocationType.EVENT
	_curr_number_of_event_charcters_per_area[area] += 1
	return loc

# Places the pickable resources for game start.
func place_pickable_resources() -> void:
	var starting_pickable_money: int = int(round(rand_range(
		_starting_pickable_money_amount_lower_bound,
		_starting_pickable_money_amount_upper_bound)))
	for _i in starting_pickable_money:
		place_pickable_resource()

# Places a pickable resource instance and records it in the map.
func place_pickable_resource() -> Vector2:
	if _curr_number_of_pickable_resources >= PICKABLE_RESOURCE_LIMIT:
		return Vector2(-1, -1)
	var loc: Vector2 = _get_random_empty_tile()
	map[loc].type = Enums.LocationType.PICKABLE_RESOURCE
	_curr_number_of_pickable_resources += 1
	return loc

# Sets player instances on map. Adds the player's team as a candidate.
func set_player(player_id: int, player: Node) -> void:
	map[player.location].player = player
	players[player_id] = player
	var player_team: int = MatchRoomManager.players[player_id].team
	_add_team_as_candidate(player_team)

# Updates the player character to show any visual changes.
func update_player_visuals(player_id: int) -> void:
	if players.has(player_id) and is_instance_valid(players[player_id]):
		if MatchRoomManager.players[player_id].is_disconnected:
			MapData.players[player_id].show_player_message(PlayerCharacter.DISCONNECTED_BBCODE_TEXT)
		else:
			MapData.players[player_id].hide_player_message()

# Forgets a map object from the map and set it to a free space. If free is
# set to true, free the map object instance saved in the map.
func remove_map_object(location: Vector2, free: bool = true) -> void:
	if map[location].type == Enums.LocationType.PICKABLE_RESOURCE:
		_curr_number_of_pickable_resources -= 1
	elif map[location].type == Enums.LocationType.EVENT:
		var area: int = map[location].area_type
		_curr_number_of_event_charcters_per_area[area] -= 1
	map[location].type = Enums.LocationType.FREE_SPACE
	if free:
		map[location].map_object.queue_free()
	map[location].map_object = null
	if not is_instance_valid(map[location].player):
		return
	MovementManager.update_player_location_data(map[location].player.get_player_id())

# Updates the given player's location.
func set_new_player_location(player_id: int, new_location: Vector2) -> void:
	var old_location: Vector2 = players[player_id].location
	map[old_location].player = null
	map[new_location].player = players[player_id]
	emit_signal("player_moved", player_id, old_location, new_location)

# Sets the limits for appearances of event characters in areas.
func set_character_event_limits_based_on_areas() -> void:
	var highest_population_area: int = _get_area_with_highest_population()
	for area in projections.keys():
		if area == highest_population_area:
			event_character_limits_per_area[area] = \
				HIGHEST_POPULATION_AREA_CHARACTER_EVENT_LIMIT
		else:
			event_character_limits_per_area[area] = \
				DEFAULT_CHARACTER_EVENT_LIMIT
		_curr_number_of_event_charcters_per_area[area] = 0

# Updates the data associated with the specified location.
func update_location_data(location: Vector2, data: Dictionary) -> void:
	if not is_instance_valid(map[location].map_object):
		return
	map[location].map_object.set_data(data)

# If player is present on the given location, send them the current
# state of th location they are on.
func update_location_data_for_player_if_present(location: Vector2) -> void:
	if not is_instance_valid(map[location].player):
		return
	MatchRoomManager.update_location_player_is_on(
		map[location].player.get_player_id(), 
		get_location_data(location))

# Returns the data associated with the given location.
func get_location_data(location: Vector2) -> Dictionary:
	if map[location].type == Enums.LocationType.FREE_SPACE:
		return {}
	return map[location].map_object.get_data()

# Checks if given location is inside the map.
func is_inside(location: Vector2) -> bool:
	return map.has(location)

# Checks if the location is inside the map, it is not invalid and
# a player is not already on it.
func is_walkable(location: Vector2) -> bool:
	 return is_inside(location) and \
		map[location].type != Enums.LocationType.INVALID_SPACE and \
		not is_instance_valid(map[location].player) 

# Transforms map location to world position.
func map_location_to_world_position(location: Vector2) -> Vector2:
	var offset: Vector2 = _ground_map.get_parent().position
	var cell_size: Vector2 = _ground_map.cell_size
	return offset + location * cell_size

# Takes the number of given supporters, subtracts it from the undecided residents,
# and adds it to the supporters of the give team in the specified area.
func add_supporters_to_team_in_area(supporters: int, team: int, area: int) -> void:
	if projections[area].undecided < supporters:
		supporters = projections[area].undecided
	projections[area].candidate_support[team] += supporters
	projections[area].undecided -= supporters

# Takes the given supperters from the 'from' team to and gives them to the 'to' team.
func move_supporters_between_teams(supporters: int, from: int, to: int, area: int) -> void:
	if from == Enums.Team.NOT_SELECTED or to == Enums.Team.NOT_SELECTED or from == to:
		return
	if projections[area].candidate_support[from] < supporters:
		supporters = projections[area].candidate_support[from]
	add_supporters_to_team_in_area(-supporters, from, area)
	add_supporters_to_team_in_area(supporters, to, area)

# Returns what percent the given number_of_residents is out of the population
# in the given area.
func get_percentage_of_population_in_area(number_of_residents: int, area: int) -> float:
	return 100.0 * number_of_residents / projections[area].population

# Returns the number of residents the percentage shows in a given area.
func get_population_by_percentage_in_area(percentage: float, area: int) -> int:
	return percentage / 100.0 * projections[area].population

# Returns data about the candidate projection results as a dictionary.
func get_area_projection_results() -> Dictionary:
	var results: Dictionary = _create_base_for_results()
	_set_projected_areas_for_results(results)
	_set_candidate_placements_for_results(results)
	_set_candidate_ties_for_results(results)
	return results

# Places a hiring spot at a random location. Returns the location used.
func place_starting_hiring_spot() -> Vector2:
	var hiring_spot_loc: Vector2 = _get_random_empty_tile(true)
	map[hiring_spot_loc].type = Enums.LocationType.HIRING_SPOT
	return hiring_spot_loc

# Picks up pickable supporters.
func pick_up_supporters(loc: Vector2, player_id: int) -> void:
	if (not map.has(loc)) or \
		map[loc].type != Enums.LocationType.PICKABLE_RESOURCE or \
		map[loc].map_object.type != Enums.Resource.SUPPORTER:
		return
	var res_data: Node = map[loc].map_object
	var area: int = map[loc].area_type
	var team: int = MatchRoomManager.get_team_by_player_id(player_id)
	if team == Enums.Team.NOT_SELECTED:
		return
	if projections[area].undecided < res_data.amount:
		return
	projections[area].candidate_support[team] += res_data.amount
	projections[area].undecided -= res_data.amount

# Resets all of the map data to its default values.
func reset() -> void:
	rows = 0
	columns = 0
	players = {}
	map = {}
	projections = {
		Enums.TileType.GREEN: {
			"population": 0,
			"undecided": 0,
			"candidate_support": {},
		},
		Enums.TileType.SNOWY: {
			"population": 0,
			"undecided": 0,
			"candidate_support": {},
		},
		Enums.TileType.URBAN: {
			"population": 0,
			"undecided": 0,
			"candidate_support": {},
		},
	}
	event_character_limits_per_area = {}
	_ground_map = null
	_area_tiles = {
		Enums.TileType.GREEN: [],
		Enums.TileType.SNOWY: [],
		Enums.TileType.URBAN: [],
	}
	_curr_number_of_pickable_resources = 0
	_starting_pickable_money_amount_lower_bound = 2
	_starting_pickable_money_amount_upper_bound = 4
	_curr_number_of_event_charcters_per_area = {}


func _create_base_for_results() -> Dictionary:
	var results: Dictionary = {
		"teams": {}, 
		"undecided_areas": [],
	}
	for team in MatchRoomManager.teams.keys():
		if team != Enums.Team.NOT_SELECTED:
			results.teams[team] = {
				"areas": [],
				"placement": -1,
				"is_tied": false,
			}
	return results


func _set_projected_areas_for_results(results: Dictionary) -> void:
	for area in projections.keys():
		var leading_team: int = Enums.Team.NOT_SELECTED
		var most_support: int = 0
		for team in projections[area].candidate_support:
			var support: int = projections[area].candidate_support[team]
			if support > most_support:
				leading_team = team
				most_support = support
		var is_leading_team_tied: bool = false
		for team in projections[area].candidate_support:
			var support: int = projections[area].candidate_support[team]
			if team != leading_team and support == most_support:
				is_leading_team_tied = true
		if leading_team != Enums.Team.NOT_SELECTED and not is_leading_team_tied:
			results.teams[leading_team].areas.append(area)
		else:
			results.undecided_areas.append(area)


func _set_candidate_placements_for_results(results: Dictionary) -> void:
	for team in results.teams.keys():
		var placement: int = 1
		for other_team in results.teams.keys():
			if other_team != team and \
				results.teams[other_team].areas.size() > results.teams[team].areas.size():
				placement += 1
		results.teams[team].placement = placement


func _set_candidate_ties_for_results(results: Dictionary) -> void:
	for team in results.teams.keys():
		for other_team in results.teams.keys():
			if other_team != team and \
				results.teams[other_team].placement == results.teams[team].placement:
				results.teams[team].is_tied = true
				break


func _set_map_cell_according_to_ground_layer(x: int, y: int) -> void:
	var cell_type: int = _ground_map.get_cell(x, y)
	if cell_type < 0:
		return
	map[Vector2(x, y)] = {
		"player": null, 
		"map_object": null,
		"type": Enums.LocationType.FREE_SPACE,
		"area_type": cell_type,
	}
	projections[cell_type].population += POPULATION_DENSITY
	projections[cell_type].undecided += POPULATION_DENSITY
	_area_tiles[cell_type].append(Vector2(x, y))


func _get_random_empty_tile_in_area(area_type: int) -> Vector2:
	var area_tiles: Array = _area_tiles[area_type].duplicate()
	area_tiles.shuffle()
	while area_tiles.size() > 0:
		var tile_loc_candidate: Vector2 = area_tiles.pop_front()
		if map[tile_loc_candidate].type == Enums.LocationType.FREE_SPACE and \
			not is_instance_valid(map[tile_loc_candidate].player):
			return tile_loc_candidate
	return Vector2(-1, -1)


func _get_random_empty_tile(adjacent_tiles_also_empty: bool = false) -> Vector2:
	var locations: Array = map.keys().duplicate()
	locations.shuffle()
	while locations.size() > 0:
		var loc_candidate: Vector2 = locations.pop_front()
		if map[loc_candidate].type == Enums.LocationType.FREE_SPACE and \
			not is_instance_valid(map[loc_candidate].player):
			if adjacent_tiles_also_empty:
				if _are_adjacent_tiles_empty(loc_candidate):
					return loc_candidate
			else:
				return loc_candidate
	return Vector2(-1, -1)


func _are_adjacent_tiles_empty(loc: Vector2) -> bool:
	return _is_location_empty(loc + Vector2.UP) and \
		_is_location_empty(loc + Vector2.RIGHT) and \
		_is_location_empty(loc + Vector2.DOWN) and \
		_is_location_empty(loc + Vector2.LEFT)


func _is_location_empty(loc: Vector2, no_player: bool = false) -> bool:
	if not map.has(loc):
		return true
	if no_player:
		return map[loc].type == Enums.LocationType.FREE_SPACE and \
			not is_instance_valid(map[loc].player)
	return map[loc].type == Enums.LocationType.FREE_SPACE


func _add_team_as_candidate(team: int) -> void:
	for area in projections.keys():
		projections[area].candidate_support[team] = 0


func _get_area_with_highest_population() -> int:
	var highest_population_area: int = -1
	var highest_population: int = -1
	for area in projections.keys():
		if projections[area].population > highest_population:
			highest_population_area = area
			highest_population = projections[area].population
	return highest_population_area


func _place_starting_gathering_spots() -> void:
	var leaf_spot_loc: Vector2 = _get_random_empty_tile_in_area(Enums.TileType.GREEN)
	map[leaf_spot_loc].type = Enums.LocationType.GATHERING_SPOT
	var ice_spot_loc: Vector2 = _get_random_empty_tile_in_area(Enums.TileType.SNOWY)
	map[ice_spot_loc].type = Enums.LocationType.GATHERING_SPOT
	var cheese_spot_loc: Vector2 = _get_random_empty_tile_in_area(Enums.TileType.URBAN)
	map[cheese_spot_loc].type = Enums.LocationType.GATHERING_SPOT
	var highest_population_area: int = _get_area_with_highest_population()
	var loc_in_highest_population_area: Vector2 = _get_random_empty_tile_in_area(highest_population_area)
	map[loc_in_highest_population_area].type = Enums.LocationType.GATHERING_SPOT


func _place_starting_event_characters() -> void:
	place_event_character_in_area(Enums.TileType.GREEN)
	place_event_character_in_area(Enums.TileType.SNOWY)
	place_event_character_in_area(Enums.TileType.URBAN)

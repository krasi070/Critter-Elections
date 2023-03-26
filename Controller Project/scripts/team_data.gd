extends Node
# A singleton class containing data about the teams in the same room
# the player is in.

signal updated_teams

# All the teams in the room.
var all_teams: Array = [] setget set_data
# Used for displaying info to player during rejoin.
var team_names: Array
# The required number of full teams to start the game.
var allowed_number_of_teams: int

# Sets the teams.
func set_data(data: Array) -> void:
	all_teams = data
	emit_signal("updated_teams")

# Sets all team data to default vaues.
func reset_data() -> void:
	all_teams = []

# Returns true if one of the teams has the given name. Otherwise, false.
func has_team(team_name: String) -> bool:
	for team in all_teams:
		if team.has("name") and team.name == team_name:
			return true
	return false

# Returns the index of the given team. Otherwise, returns NOT_SELECTED.
func get_team_index_by_name(team_name: String) -> int:
	for team in all_teams:
		if team.has("name") and team.name == team_name:
			return team.index
	return Enums.Team.NOT_SELECTED

# Returns the team name of the team with the specified index. 
# If the team index is not found, returns the empty string.
func get_team_name_by_index(team_index: int) -> String:
	for team in all_teams:
		if team.has("name") and team.index == team_index:
			return team.name
	return "[INVALID TEAM]"

# Returns the team color of the team with the specified index. 
# If the team index is not found, returns Color.transparent.
func get_team_color_by_index(team_index: int) -> Color:
	for team in all_teams:
		if team.has("color") and team.index == team_index:
			return team.color
	return Color.transparent

# Returns the number of full teams
func get_number_of_full_teams() -> int:
	var number_of_full_teams: int = 0
	for team in all_teams:
		if team.has("role_a") and team.role_a != "free" and \
			team.has("role_b") and team.role_b != "free":
			number_of_full_teams += 1
	return number_of_full_teams

# Returns true if enough teams are full to start a game. Otherwise, false.
func is_allowed_team_requirement_met() -> bool:
	var number_of_full_teams: int = get_number_of_full_teams()
	var unselected_team_players: int = all_teams[Enums.Team.NOT_SELECTED].players.size()
	return allowed_number_of_teams == number_of_full_teams and unselected_team_players == 0

class_name ElectionLoserContainer
extends HBoxContainer
# ElectionLoserContainer's script.

onready var placement_label: Label = $PlacementLabel
onready var campaigner_texture_rect: TextureRect = $CampaignerTextureRect
onready var gatherer_texture_rect: TextureRect = $GathererTextureRect

const PLACEMENT_TEXTS: Dictionary = {
	1: "tie",
	2: "2nd", 
	3: "3rd", 
	4: "4th", 
}

# Sets the labels and texture with info about the given team.
func set_loser_team(team: int, placement: int) -> void:
	placement_label.text = PLACEMENT_TEXTS[placement]
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	var campaigner_str: String = Enums.to_str_snake_case(Enums.Role, Enums.Role.CAMPAIGNER)
	var gatherer_str: String = Enums.to_str_snake_case(Enums.Role, Enums.Role.GATHERER)
	campaigner_texture_rect.texture = load(Paths.CHARACTER_SPRITE_PATH_FORMAT % [team_str, campaigner_str])
	gatherer_texture_rect.texture = load(Paths.CHARACTER_SPRITE_PATH_FORMAT % [team_str, gatherer_str])

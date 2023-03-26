extends Node
# Holds values for the settings player can alter in the game.

var map_size_options: Dictionary = {
	Enums.to_str(Enums.MapSize, Enums.MapSize.CRAMPED_MAP): Enums.MapSize.CRAMPED_MAP,
	Enums.to_str(Enums.MapSize, Enums.MapSize.JUST_RIGHT_MAP): Enums.MapSize.JUST_RIGHT_MAP,
	Enums.to_str(Enums.MapSize, Enums.MapSize.SPACIOUS_MAP): Enums.MapSize.SPACIOUS_MAP,
}

var number_of_rounds_options: Dictionary = {
	"2 rounds": 2,
	"3 rounds": 3,
	"4 rounds": 4,
}

var round_duration_options: Dictionary = {
	"3 min / round": 180,
	"4 min / round": 240,
	"5 min / round": 300,
}

var map_size: int = Enums.MapSize.JUST_RIGHT_MAP
var number_of_rounds: int = 2
var round_duration: float = 180.0

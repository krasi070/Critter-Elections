extends Node
# Global script that has various enums.

enum Team {
	NOT_SELECTED = -1,
	TEAM_A = 0,
	TEAM_B = 1,
	TEAM_C = 2,
	TEAM_D = 3,
}

enum Role {
	NOT_SELECTED = -1,
	CAMPAIGNER = 0,
	GATHERER = 1,
}

enum Resource {
	MONEY = 0,
	HONEY = 1,
	ICE = 2,
	CARROTS = 3,
	LEAVES = 4,
	CHEESE = 5,
	HONEYCOMB = 6,
	SUPPORTER = 7,
	STEAL_SUPPORTER = 8,
}

enum LocationType {
	INVALID_SPACE = -1,
	FREE_SPACE = 0,
	EVENT = 1,
	UPGRADE_SHOP = 2,
	GATHERING_SPOT = 3,
	HIRING_SPOT = 4,
	PICKUP = 5,
	PICKABLE_RESOURCE = 6,
}

enum TileType {
	GREEN = 0,
	SNOWY = 1,
	URBAN = 2,
}

enum WorkerType {
	NINE_TO_FIVE = 0,
	HUSTLING = 1,
	SWIFT = 2,
	GAMBLING = 3,
	HOME_COOK = 4,
	REFLECTION = 5,
	ICE_LOVING = 6,
	LEAF_LOVING = 7,
	CHEESE_LOVING = 8,
}

enum GatheringSpotUpgrade {
	INCREASE_WORKER_LIMIT = 0,
	DECREASE_PRODUCTION_TIME = 1,
	INCREASE_PRODUCTION_AMOUNT = 2,
	HONEYCOMB = 3,
}

enum MapSize {
	CRAMPED_MAP = 0,
	JUST_RIGHT_MAP = 1,
	SPACIOUS_MAP = 2,
}

# Returns capitalized version of the enum value name.
# Example: FREE_SPACE -> Free Space
func to_str(_enum: Dictionary, val: int) -> String:
	for key in _enum.keys():
		if _enum[key] == val:
			return key.capitalize()
	return ""

# Returns a snake case version of the enum value name.
# Example: FREE_SPACE -> free_space
func to_str_snake_case(_enum: Dictionary, val: int) -> String:
	for key in _enum.keys():
		if _enum[key] == val:
			return key.to_lower().replace(" ", "_")
	return ""

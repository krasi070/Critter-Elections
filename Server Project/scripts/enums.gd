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

enum LocationType {
	INVALID_SPACE = -1,
	FREE_SPACE = 0,
	EVENT = 1,
	UPGRADE_SHOP = 2,
	GATHERING_SPOT = 3,
	HIRING_SPOT = 4,
	PICKUP = 5,
}

enum Resource {
	MONEY = 0,
	HONEY = 1,
	ICE = 2,
	CARROTS = 3,
	LEAVES = 4,
	CHEESE = 5,
	HONEYCOMB = 6,
}

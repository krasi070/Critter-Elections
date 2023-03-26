tool
extends TileSet

const GREEN_AREA: int = 0
const SNOWY_AREA: int = 1
const URBAN_AREA: int = 2

var binds: Dictionary = {
	GREEN_AREA: [SNOWY_AREA, URBAN_AREA],
	SNOWY_AREA: [GREEN_AREA, URBAN_AREA],
	URBAN_AREA: [GREEN_AREA, SNOWY_AREA],
}

func _is_tile_bound(drawn_id: int, neighbor_id: int) -> bool:
	if binds.has(drawn_id):
		return binds[drawn_id].has(neighbor_id)
	return false

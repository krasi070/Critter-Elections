extends Node
# Handles helpful worker related tasks.

const WORKER_BEE_SPRITE_PATH_FORMAT: String = \
	"res://assets/sprites/workers/%s_bee.png"

# Returns the texture of the given worker.
func get_texture_by_worker_type(type: int) -> Texture:
	var type_str: String = Enums.to_str_snake_case(Enums.WorkerType, type)
	var texture: Texture = load(WORKER_BEE_SPRITE_PATH_FORMAT % type_str)
	return texture

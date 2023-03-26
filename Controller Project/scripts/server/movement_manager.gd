extends Node
# Handles player map movement.

signal updated_location

func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS

# Send move_player request to player's room.
func send_move_request(dir: Vector2) -> void:
	rpc_unreliable_id(MatchRoomManager.room_id, "move_player", dir)
	#rpc_id(MatchRoomManager.room_id, "move_player", dir)

# Sets location position, data and type in PlayerData. 
# Emits updated_location signal.
remote func set_location_data(location_data: Dictionary) -> void:
	PlayerData.location = location_data.location
	PlayerData.location_type = location_data.type
	PlayerData.location_data = location_data.object_data
	emit_signal("updated_location")

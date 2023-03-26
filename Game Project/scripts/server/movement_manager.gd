extends Node
# Handles player map movement.

signal player_moved(player_id, new_location)

func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS

# Updates the given player's location data.
func update_player_location_data(player_id: int) -> void:
	var player: Node2D = MapData.players[player_id]
	var location_data: Dictionary = {
		"type": MapData.map[player.location].type,
		"location": player.location,
		"object_data": MapData.get_location_data(player.location),
	}
	rpc_id(MatchRoomManager.players[player_id].id, "set_location_data", location_data)

# If valid, updates and move player character to new location based on the
# specified direction. Emits player_moved signal.
remote func move_player(dir: Vector2) -> void:
	var player_network_id: int = get_tree().get_rpc_sender_id()
	var player_id: int = MatchRoomManager.get_player_id_by_network_id(player_network_id)
	var player: Node2D = MapData.players[player_id]
	if MapData.is_walkable(player.location + dir):
		MapData.set_new_player_location(player_id, player.location + dir)
		player.move(dir)
		update_player_location_data(player_id)
		emit_signal("player_moved", player_id, player.location)
	else:
		player.wobble()

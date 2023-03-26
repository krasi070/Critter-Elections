class_name MapObject
extends Node2D
# Abstract class for objects that will be shown on the map, such as players.

# The object's map location.
var location: Vector2

# Sets new position based on the object's location on the map.
func set_location(_location: Vector2) -> void:
	location = _location
	position = MapData.map_location_to_world_position(location)

# Returns the data associated with this map object. Intended to be overwritten.
func get_data() -> Dictionary:
	return {}

# Sets the data associated with this map object. Intended to be overwritten.
func set_data(_data: Dictionary) -> void:
	pass

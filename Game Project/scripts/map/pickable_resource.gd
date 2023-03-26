class_name PickableResource
extends MapObject
# PickableResource's script.

const RESOURCE_SPRITE_PATH_FORMAT: String = "res://assets/sprites/symbols/%s.png"

var type: int
var amount: int

onready var sprite: Sprite = $Sprite
onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	add_to_group("interactables")
	sprite.self_modulate = Color.transparent
	sprite.texture = load(RESOURCE_SPRITE_PATH_FORMAT % Enums.to_str_snake_case(Enums.Resource, type))

# Does what the base MapObject set_location does and plays an appear animation.
func set_location(_location: Vector2) -> void:
	.set_location(_location)
	anim_player.play("fall_down")

# Sets the resource type and amount data.
func set_data(data: Dictionary) -> void:
	type = data.type
	amount = data.amount
	if not is_instance_valid(sprite):
		return
	sprite.texture = load(RESOURCE_SPRITE_PATH_FORMAT % Enums.to_str_snake_case(Enums.Resource, type))

# Returns the resource type and amount data.
func get_data() -> Dictionary:
	return {
		"type": type,
		"amount": amount,
	}

class_name FadeOutText
extends Control
# FadeOutText's script.
# Used to display brief text feedback to the players.

signal faded_out

const TILE_SIZE: int = 96
const Y_FLOAT_AMOUNT: float = TILE_SIZE / 2.0
const FLOAT_DURATION: float = 1.0

onready var container: HBoxContainer = $HorizontalContainer
onready var amount_label: Label = $HorizontalContainer/AmountLabel
onready var resource_texture_rect: TextureRect = $HorizontalContainer/ResourceTextureRect
onready var to_label: Label = $HorizontalContainer/ToLabel
onready var character_portrait_texture_rect: TextureRect = \
	$HorizontalContainer/CharacterPortraitTextureRect

func _ready() -> void:
	amount_label.hide()
	resource_texture_rect.hide()
	to_label.hide()
	character_portrait_texture_rect.hide()

# Sets the float label's text.
func set_text(text: String) -> void:
	amount_label.text = text
	amount_label.show()

# Sets the float texture.
func set_resource_texture(res_type: int) -> void:
	var res_str: String = Enums.to_str_snake_case(Enums.Resource, res_type)
	resource_texture_rect.texture = load(Paths.RESOURCE_SYMBOL_PATH_FORMAT % res_str)
	resource_texture_rect.show()

func set_team_texture(team: int) -> void:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	character_portrait_texture_rect.texture = load(Paths.CANDIDATE_PORTRAIT_TEXTURE_PATH_FORMAT % team_str)
	to_label.show()
	character_portrait_texture_rect.show()

# Centers the container at the specified position during the next idle frame.
func center_at_position(pos: Vector2) -> void:
	call_deferred("_center_at", pos)

# Starts the fade tween animation. On finished, frees the object.
func fade() -> void:
	var fade_tween: SceneTreeTween = create_tween()
	fade_tween.connect("finished", self, "_fade_finished")
	fade_tween.tween_property(
		container, 
		"rect_position:y", 
		container.rect_position.y - Y_FLOAT_AMOUNT,
		FLOAT_DURATION)
	fade_tween.parallel().tween_property(
		container, 
		"modulate:a", 
		0.0,
		FLOAT_DURATION)


func _center_at(pos: Vector2) -> void:
	rect_position = pos - Vector2((container.rect_size.x - TILE_SIZE) / 2, 0)


func _fade_finished() -> void:
	emit_signal("faded_out")
	queue_free()

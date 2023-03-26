class_name PlayerCharacter
extends MapObject
# PlayerCharacter's script.
# Shows the player state visually on the map, be it the player's location
# or other.

const CHARACTER_MESSAGES: Dictionary = {
	Vector2(Enums.Team.TEAM_A, Enums.Role.CAMPAIGNER): "Vote foxes!",
	Vector2(Enums.Team.TEAM_A, Enums.Role.GATHERER): "Vote foxes!",
	Vector2(Enums.Team.TEAM_B, Enums.Role.CAMPAIGNER): "Vote crows!",
	Vector2(Enums.Team.TEAM_B, Enums.Role.GATHERER): "Vote crows!",
	Vector2(Enums.Team.TEAM_C, Enums.Role.CAMPAIGNER): "Vote raccoons!",
	Vector2(Enums.Team.TEAM_C, Enums.Role.GATHERER): "Vote raccoons!",
	Vector2(Enums.Team.TEAM_D, Enums.Role.CAMPAIGNER): "Vote frogs!",
	Vector2(Enums.Team.TEAM_D, Enums.Role.GATHERER): "Vote frogs!",
}

const EXCHANGING_MSG: String = "..."

const MOVE_DURATION: float = 0.16
const MESSAGE_DURATION: float = 3.0
const SPEECH_BUBBLE_APPEAR_DURATION: float = 0.3

const DISCONNECTED_BBCODE_TEXT: String = "\n[wave amp=30 freq=6]Disconnected[/wave]"

onready var sprite: Sprite = $Sprite
onready var msg_label: RichTextLabel = $MessageRichTextLabel
onready var speech_bubble: TextureRect = $SpeechBubble
onready var speech_label: Label = $SpeechBubble/MarginContainer/SpeechLabel
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var message_timer: Timer = $MessageTimer

var _moving_to: Vector2
var _rotating_dir: int = 1
var _team: int
var _role: int
var _tween: SceneTreeTween

func _ready() -> void:
	add_to_group("players")
	hide_player_message()

# Sets the character sprite based on the player's team and role.
func set_sprite(team: int, role: int) -> void:
	_team = team
	_role = role
	var sprite_path: String = _get_sprite_path_for_character(team, role)
	var sprite_texture: Texture = load(sprite_path)
	sprite.texture = sprite_texture

# Sets new position based on the direction moved on the map.
func move(dir: Vector2) -> void:
	set_location_with_tween(location + dir)
	if dir == Vector2.LEFT:
		sprite.flip_h = true
	if dir == Vector2.RIGHT:
		sprite.flip_h = false
	_animate_movement()

# Plays the wobble animation, used when trying to move to a dead end.
func wobble() -> void:
	anim_player.play("wobble")

# Sets new position based on the object's location on the map.
func set_location_with_tween(_location: Vector2) -> void:
	location = _location
	_moving_to = MapData.map_location_to_world_position(location)

# Returns the name of the node as an int since the name is set to the ID.
func get_player_id() -> int:
	return int(name)

# Shows the message signaling the player is trying to exchange.
func show_exchanging_speech() -> void:
	if is_instance_valid(_tween):
		_tween.stop()
	speech_bubble.show()
	speech_label.text = EXCHANGING_MSG

# Shows the message signaling the player is trying to exchange.
func cancel_exchanging_speech() -> void:
	if is_instance_valid(_tween):
		_tween.stop()
	speech_bubble.hide()
	speech_label.text = ""

# Shows the character's speech bubble with a random message for a few seconds.
func show_character_speech() -> void:
	if speech_bubble.visible:
		return
	speech_bubble.modulate= Color.transparent
	_tween = create_tween()
	_tween.tween_property(speech_bubble, "modulate:a", 1.0, SPEECH_BUBBLE_APPEAR_DURATION)
	speech_label.text = CHARACTER_MESSAGES[Vector2(_team, _role)]
	speech_bubble.show()
	message_timer.start(MESSAGE_DURATION)
	yield(message_timer, "timeout")
	if speech_label.text == EXCHANGING_MSG:
		return
	_tween = create_tween()
	_tween.tween_property(speech_bubble, "modulate:a", 0.0, SPEECH_BUBBLE_APPEAR_DURATION)
	yield(_tween, "finished")
	speech_bubble.hide()

# Shows a given message above the player sprite. BBCode is enabled.
func show_player_message(text: String) -> void:
	speech_bubble.hide()
	msg_label.bbcode_text = text
	msg_label.show()

# Hides the label used for messages above the player sprite.
func hide_player_message() -> void:
	msg_label.hide()
	speech_bubble.hide()


func _animate_movement() -> void:
	var tween: SceneTreeTween = create_tween()
	tween.tween_property(self, "position:x", _moving_to.x, MOVE_DURATION)
	tween.parallel().tween_property(self, "position:y", _moving_to.y, MOVE_DURATION)
	tween.parallel().tween_property(sprite, "rotation", deg2rad(rand_range(2.5, 7.5) * _rotating_dir), MOVE_DURATION)
	_rotating_dir *= -1
	anim_player.play("walk")


func _get_sprite_path_for_character(team: int, role: int) -> String:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	var role_str: String = Enums.to_str_snake_case(Enums.Role, role)
	return Paths.CHARACTER_SPRITE_PATH_FORMAT % [team_str, role_str]

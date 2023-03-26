class_name SwipeDetectorBox
extends Control
# SwipeDetectorBox's script.
# Detects swiping motions on touch device which either start or end inside the box.

signal swiped(direction)
signal tapped_character

const MAX_DIAGONAL_SLOPE: float = 1.3
const MIN_DISTANCE: float = 2.0

const MOVE_DURATION: float = 0.2
const MOVE_BACK_DURATION: float = 0.1
const MOVE_MULTIPLIER: float = 100.0

onready var character_texture_rect: TextureRect = $CharacterTextureRect
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var timer: Timer = $Timer

var _character_default_position: Vector2
var _swipe_start_point: Vector2
var _tween: SceneTreeTween

func _ready() -> void:
	_character_default_position = character_texture_rect.rect_position
	anim_player.play("alpha_blend")


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not event is InputEventScreenTouch:
		return
	if event.pressed:
		_start_detection(event.position)
	elif not timer.is_stopped():
		_end_detection(event.position)


func _start_detection(point: Vector2) -> void:
	_swipe_start_point = point
	timer.start()


func _end_detection(point: Vector2) -> void:
	timer.stop()
	if _is_character_press(point):
		emit_signal("tapped_character")
		return
	if not _is_in_box(_swipe_start_point, self) and not _is_in_box(point, self):
		return
	var distance: float = _swipe_start_point.distance_to(point)
	if distance < MIN_DISTANCE:
		return
	var direction: Vector2 = (point - _swipe_start_point).normalized()
	if abs(direction.x) + abs(direction.y) >= MAX_DIAGONAL_SLOPE:
		return
	var cardinal_direction: Vector2 = Vector2(sign(direction.x), 0.0)
	if abs(direction.x) <= abs(direction.y):
		cardinal_direction = Vector2(0.0, sign(direction.y))
	_play_anim(direction, cardinal_direction)
	emit_signal("swiped", cardinal_direction)


func _is_character_press(end_point: Vector2) -> bool:
	var distance: float = _swipe_start_point.distance_to(end_point)
	if _is_in_box(_swipe_start_point, character_texture_rect) and \
		_is_in_box(end_point, character_texture_rect) and \
		distance < MIN_DISTANCE:
		return true
	return false


func _play_anim(dir: Vector2, cardinal_direction: Vector2) -> void:
	if is_instance_valid(_tween):
		_tween.stop()
		character_texture_rect.rect_position = _character_default_position
	if cardinal_direction == Vector2.LEFT:
		character_texture_rect.flip_h = true
	elif cardinal_direction == Vector2.RIGHT:
		character_texture_rect.flip_h = false
	_tween = create_tween()
	_tween.tween_property(
		character_texture_rect, 
		"rect_position:x", 
		_character_default_position.x + dir.x * MOVE_MULTIPLIER, 
		MOVE_DURATION)
	_tween.parallel().tween_property(
		character_texture_rect, 
		"rect_position:y", 
		_character_default_position.y + dir.y * MOVE_MULTIPLIER, 
		MOVE_DURATION)
	_tween.connect("finished", self, "_finished_tween", ["move"])


func _is_in_box(point: Vector2, box: Control) -> bool:
	return point.x >= box.rect_global_position.x and \
		point.x <= box.rect_global_position.x + box.rect_size.x and \
		point.y >= box.rect_global_position.y and \
		point.y <= box.rect_global_position.y + box.rect_size.y


func _finished_tween(tween_name: String) -> void:
	if tween_name == "move":
		_tween = create_tween()
		_tween.tween_property(
			character_texture_rect, 
			"rect_position:x", 
			_character_default_position.x, 
			MOVE_BACK_DURATION)
		_tween.parallel().tween_property(
			character_texture_rect, 
			"rect_position:y", 
			_character_default_position.y, 
			MOVE_BACK_DURATION)

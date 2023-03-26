extends Control

const CENTER: Vector2 = Vector2(960, 540)
const MOVE_WITH_MOUSE_MULTIPLIER: Vector2 = Vector2(-0.02, -0.02)

var obj_original_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	obj_original_pos = rect_position

func _physics_process(_delta: float) -> void:
	_handle_move_with_mouse()


func _handle_move_with_mouse() -> void:
	var mouse_pos_centered = get_global_mouse_position() - CENTER
	rect_position = \
		obj_original_pos + mouse_pos_centered * MOVE_WITH_MOUSE_MULTIPLIER

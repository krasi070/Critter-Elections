class_name NotificationMessage
extends Control
# NotificationMessage's script.

signal message_freed

const WAIT_TIME: float = 5.0
const FADE_OUT_DURATION: float = 1.0

onready var close_button: Button = $CloseButton
onready var rich_text:  RichTextLabel = $TextContainer/MessageRichText

func _ready() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(WAIT_TIME, false)
	timer.connect("timeout", self, "_timer_timeout")
	close_button.connect("pressed", self, "_close_button_pressed")


func _fade_out() -> void:
	var tween: SceneTreeTween = create_tween()
	tween.connect("finished", self, "_tween_finished")
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)


func _timer_timeout() -> void:
	_fade_out()


func _tween_finished() -> void:
	emit_signal("message_freed")
	queue_free()


func _close_button_pressed() -> void:
	emit_signal("message_freed")
	queue_free()

class_name VolumeSlider
extends Control
# VolumeSlider's script.

onready var slider: HSlider = $HBoxContainer/Slider
onready var amount_label: Label = $HBoxContainer/AmountLabel

func _ready() -> void:
	_connect_signals()
	_set_defaults()


func _set_defaults() -> void:
	slider.min_value = AudioController.MIN_VOLUME
	slider.max_value = AudioController.MAX_VOLUME
	slider.step = AudioController.STEP
	slider.value = AudioController.volume_setting_value


func _connect_signals() -> void:
	slider.connect("value_changed", self, "_value_changed_slider")
	connect("visibility_changed", self, "_visibility_changed")


func _value_changed_slider(value: float) -> void:
	AudioController.set_volume(int(value))
	amount_label.text = str(value)
	AudioController.play_ui_sound(AudioController.CLICK_SOUND)


func _visibility_changed() -> void:
	if is_visible_in_tree():
		slider.value = AudioController.volume_setting_value

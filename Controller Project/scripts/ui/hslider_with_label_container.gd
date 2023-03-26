class_name HSliderWithLabelContainer
extends HBoxContainer
# HSliderWithLabelContainer's script.

signal value_changed(value)

onready var hslider: HSlider = $HSlider
onready var value_label: Label = $ValueLabel

func _ready() -> void:
	_connect_signals()

# Sets the slider's minimum, maximum and current value.
func set_slider_values(_min: int, _max: int, _curr: int) -> void:
	hslider.min_value = _min
	hslider.max_value = _max
	hslider.value = _curr


func _connect_signals() -> void:
	hslider.connect("value_changed", self, "_hslider_value_changed")


func _hslider_value_changed(value: int) -> void:
	value_label.text = str(value)
	emit_signal("value_changed", value)

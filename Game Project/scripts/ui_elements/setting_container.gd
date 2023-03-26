class_name SettingContainer
extends HBoxContainer
# SettingContainer's script.

const ANIM_START_FONT_SIZE: int = 18
const ANIM_END_FONT_SIZE: int = 36
const ANIM_DURATION: float = 0.1

onready var left_button: Button = $LeftButton
onready var right_button: Button = $RightButton
onready var selected_label: Label = $SelectedLabel

var _setting: String
var _options: Dictionary = {}
var _options_list: Array = []
var _selected_index: int

func _ready() -> void:
	_connect_signals()
	_make_label_font_unique()

# Fills the setting with the given options and sets the default option.
func set_options(setting_name: String, options: Dictionary, default_index: int = 0) -> void:
	_setting = setting_name
	_options = options
	for option_name in options.keys():
		_options_list.append(option_name)
	_selected_index = default_index
	_update_selection(false)


func _update_selection(play_anim: bool = true) -> void:
	var option_text: String = _options_list[_selected_index]
	Settings.set(_setting, _options[option_text])
	selected_label.text = option_text
	if play_anim:
		_animate()


func _animate() -> void:
	var tween: SceneTreeTween = create_tween()
	var font: Font = selected_label.get("custom_fonts/font")
	font.size = ANIM_START_FONT_SIZE
	tween.tween_property(font, "size", ANIM_END_FONT_SIZE, ANIM_DURATION)


func _make_label_font_unique() -> void:
	var unique_font: Font = selected_label.get("custom_fonts/font").duplicate()
	selected_label.set("custom_fonts/font", unique_font)


func _connect_signals() -> void:
	left_button.connect("pressed", self, "_pressed_left_button")
	right_button.connect("pressed", self, "_pressed_right_button")


func _pressed_left_button() -> void:
	var num_of_options: int = _options_list.size()
	_selected_index = (num_of_options + _selected_index - 1) % num_of_options
	_update_selection()


func _pressed_right_button() -> void:
	_selected_index = (_selected_index + 1) % _options_list.size()
	_update_selection()

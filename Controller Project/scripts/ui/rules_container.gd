class_name RulesContainer
extends VBoxContainer
# RulesContainer's script.

signal pressed_back_button

const RULES_PAGE_TEXTURE_PATH_FORMAT: String = "res://assets/sprites/rule_pages/temp_rules_page_%d.png"
const PAGE_TEXT_FORMAT: String = "Page %d/%d"

onready var page_info_container: HBoxContainer = $PageInfoContainer
onready var page_label: Label = $PageInfoContainer/PageLabel
onready var prev_page_button: Button = $PageInfoContainer/PreviousPageButtonContainer/PreviousPageButton
onready var next_page_button: Button = $PageInfoContainer/NextPageButtonContainer/NextPageButton
onready var back_button: Button = $BackButton
onready var pages: Array = [
	$Page1,
	$Page2,
	$Page3,
	$Page4,
]

var _curr_page_index: int = 0

func _ready() -> void:
	_show_page(_curr_page_index)
	_update_page_label()
	_connect_signals()


func _connect_signals() -> void:
	prev_page_button.connect("pressed", self, "_pressed_prev_page_button")
	next_page_button.connect("pressed", self, "_pressed_next_page_button")
	back_button.connect("pressed", self, "_pressed_back_button")


func _show_page(page_index: int) -> void:
	for i in range(pages.size()):
		pages[i].visible = page_index == i


func _update_page_label() -> void:
	page_label.text = PAGE_TEXT_FORMAT % [_curr_page_index + 1, pages.size()]
	prev_page_button.visible = _curr_page_index > 0
	next_page_button.visible = _curr_page_index < pages.size() - 1


func _pressed_prev_page_button() -> void:
	_curr_page_index = int(clamp(_curr_page_index - 1, 0, pages.size() - 1))
	_show_page(_curr_page_index)
	_update_page_label()


func _pressed_next_page_button() -> void:
	_curr_page_index = int(clamp(_curr_page_index + 1, 0, pages.size() - 1))
	_show_page(_curr_page_index)
	_update_page_label()


func _pressed_back_button() -> void:
	emit_signal("pressed_back_button")

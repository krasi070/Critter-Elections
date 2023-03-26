class_name WorkerButton
extends Button
# WorkerButton's script.
# A representation of a worker in a button.

const ANIM_START_FONT_SIZE: int = 24
const ANIM_END_FONT_SIZE: int = 48
const ANIM_DURATION: float = 0.1

const SYMBOL_BBCODE_TEXT_FORMAT: String = "[font=res://assets/fonts/ImgVerticalOffsetBitmapFont.tres][img=20]res://assets/sprites/symbols/inline/inline_%s.png[/img][/font]"
const CANNOT_BUY_COLOR: Color = Color(240 / 255.0, 137 / 255.0, 93 / 255.0)

# Used for rankings in hiring spots.
var rank: int setget set_rank, get_rank

onready var worker_texture_rect: TextureRect = \
	$MarginContainer/HBoxContainer/WorkerTextureRect
onready var worker_price_label: Label = \
	$MarginContainer/HBoxContainer/WorkerTextureRect/ColorRect/HBoxContainer/WorkerPriceLabel
onready var text_container: VBoxContainer = \
	$MarginContainer/HBoxContainer/TextContainer
onready var worker_name_label: Label = \
	$MarginContainer/HBoxContainer/TextContainer/WorkerNameLabel
onready var info_label: RichTextLabel = \
	$MarginContainer/HBoxContainer/TextContainer/InfoRichTextLabel
onready var rank_and_total_price_container = \
	$MarginContainer/HBoxContainer/RankAndTotalPriceContainer
onready var rank_label = \
	$MarginContainer/HBoxContainer/RankContainer/RankNumberLabel
onready var total_price_label = \
	$MarginContainer/HBoxContainer/RankAndTotalPriceContainer/TotalPriceContainer/WorkerPriceLabel

# The data of the worker the button represents.
var _data: Dictionary

var _inline_symbols: Array = [
	Enums.to_str_snake_case(Enums.Resource, Enums.Resource.CHEESE),
	Enums.to_str_snake_case(Enums.Resource, Enums.Resource.HONEYCOMB),
	Enums.to_str_snake_case(Enums.Resource, Enums.Resource.ICE),
	Enums.to_str_snake_case(Enums.Resource, Enums.Resource.LEAVES),
	Enums.to_str_snake_case(Enums.Resource, Enums.Resource.MONEY),
]

func _ready() -> void:
	_connect_signals()
	_make_label_font_unique(total_price_label)

# Sets the visibility of the elements showing price to the given bool value.
func set_hire_worker_elements_visibility(are_visible: bool = false) -> void:
	#worker_price_bg.visible = are_visible
	rank_and_total_price_container.visible = are_visible
	if are_visible:
		_update_hireable()

# Sets the view elements to the given data.
func set_worker_data(data: Dictionary, _rank: int = 0) -> void:
	_data = data
	worker_name_label.text = data.name
	worker_price_label.text = str(data.price)
	info_label.bbcode_text = _set_reource_symbols(data.info)
	set_rank(_rank)
	rank_label.text = "RANK %d" % rank
	total_price_label.text = str(data.price + rank)
	worker_texture_rect.texture = WorkerHelper.get_texture_by_worker_type(data.type)

# Returns the worker data the button represents.
func get_worker_data() -> Dictionary:
	return _data

# Returns the total price of the worker.
func get_total_price() -> int:
	if _data.empty():
		return 0
	return _data.price + rank

# Gets the worker buttons's rank.
func get_rank() -> int:
	return rank

# Sets the worker button's rank.
func set_rank(new_rank: int) -> void:
	if new_rank < rank:
		_play_updated_total_price_anim()
	rank = new_rank


func _connect_signals() -> void:
	PlayerData.connect("updated_resources", self, "_player_data_updated_resources")


func _play_updated_total_price_anim() -> void:
	var tween: SceneTreeTween = create_tween()
	var font: Font = total_price_label.get("custom_fonts/font")
	font.size = ANIM_START_FONT_SIZE
	tween.tween_property(font, "size", ANIM_END_FONT_SIZE, ANIM_DURATION)


func _make_label_font_unique(label: Label) -> void:
	var unique_font: Font = label.get("custom_fonts/font").duplicate()
	label.set("custom_fonts/font", unique_font)


func _set_reource_symbols(text: String) -> String:
	for res_symbol_str in _inline_symbols:
		text = text.replace(
			"*%s*" % res_symbol_str,
			SYMBOL_BBCODE_TEXT_FORMAT % res_symbol_str)
	return text


func _update_hireable() -> void:
	if PlayerData.resources[Enums.Resource.HONEYCOMB] < get_total_price():
		disabled = true
		total_price_label.set("custom_colors/font_color", CANNOT_BUY_COLOR)
	else:
		disabled = false
		total_price_label.set("custom_colors/font_color", Color.white)


func _player_data_updated_resources() -> void:
	if rank_and_total_price_container.visible:
		_update_hireable()

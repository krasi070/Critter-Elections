class_name ActionButton
extends Button
# ActionButton's script.

const DEFAULT_FONT_COLOR: Color = Color.white
const DISABLED_FONT_COLOR: Color = Color(180 / 255.0, 180 / 255.0, 180 / 255.0)
const DEFAULT_TEXTURE_OPACITY: Color = Color.white
const DISABLED_TEXTURE_OPACITY: Color = Color(127 / 255.0, 127 / 255.0, 127 / 255.0)

const RESOURCE_SPRITE_PATH_FORMAT: String = "res://assets/sprites/symbols/%s.png"

onready var symbol_type_container: MarginContainer = $MarginContainer
onready var before_texture_label: Label = $MarginContainer/HBoxContainer/BeforeTextureLabel
onready var symbol_texture_rect: TextureRect = $MarginContainer/HBoxContainer/SymbolTextureRect
onready var after_texture_label: Label = $MarginContainer/HBoxContainer/AfterTextureLabel

func _ready() -> void:
	symbol_type_container.hide()

func _physics_process(_delta: float) -> void:
	if not disabled and is_hovered() and not pressed:
		symbol_type_container.margin_bottom = -22
		symbol_type_container.margin_top = 18
	else:
		symbol_type_container.margin_bottom = -20
		symbol_type_container.margin_top = 20

# Shows the symbol type container.
func set_to_symbol_type() -> void:
	symbol_type_container.show()

# Sets the symbol text. The text pput between two * will be made into a texture.
func set_symbol_text(symbol_text: String) -> void:
	text = ""
	var text_args: PoolStringArray = symbol_text.split("*", false)
	if text_args.size() < 2:
		return
	before_texture_label.text = text_args[0]
	symbol_texture_rect.texture = load(RESOURCE_SPRITE_PATH_FORMAT % text_args[1])
	if text_args.size() == 2:
		return
	after_texture_label.text = text_args[2]

# Returns true if the button is a symbol type which uses a texture within itself.
func is_symbol_type() -> bool:
	return symbol_type_container.visible

# Sets the button's disabled value and updates the symbol texture elements
# accordingly.
func set_disabled_value(is_disabled: bool) -> void:
	disabled = is_disabled
	if disabled:
		before_texture_label.set("custom_colors/font_color", DISABLED_FONT_COLOR)
		symbol_texture_rect.modulate = DISABLED_TEXTURE_OPACITY
		after_texture_label.set("custom_colors/font_color", DISABLED_FONT_COLOR)
	else:
		before_texture_label.set("custom_colors/font_color", DEFAULT_FONT_COLOR)
		symbol_texture_rect.modulate = DEFAULT_TEXTURE_OPACITY
		after_texture_label.set("custom_colors/font_color", DEFAULT_FONT_COLOR)

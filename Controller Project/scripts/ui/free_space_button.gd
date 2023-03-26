extends Button

const STYLE_NAMES: Array = [
	"Hover",
	"Pressed",
	"Normal",
]

func _ready() -> void:
	if PlayerData.location_type == Enums.LocationType.GATHERING_SPOT:
		set_button_style_based_on_resource(PlayerData.location_data.resource_type)

# Sets the buttons style according to the given resource type.
func set_button_style_based_on_resource(resource: int) -> void:
	var path_format: String = \
		"res://assets/styles/gathering_spot_buttons/%sButton%sStyle.tres"
	for style_name in STYLE_NAMES:
		var path: String = path_format % [Enums.to_str(Enums.Resource, resource), style_name]
		var style: StyleBox = load(path)
		add_stylebox_override(style_name.to_lower(), style)

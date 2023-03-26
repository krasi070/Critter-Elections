class_name GatheringSpotDataContainer
extends HBoxContainer
# GatheringSpotDataContainer's script.

const BOX_STYLE_PATH_FORMAT: String = "res://assets/styles/boxes/%sBoxStyle.tres"

const NAME_AND_LEVEL_TEXT_FORMAT: String = "%s LV %s"
const INFO_BBCODE_TEXT_FORMAT: String = \
	"[center]%d [font=res://assets/fonts/ImgVerticalOffsetBitmapFont.tres][img=32]res://assets/sprites/symbols/inline/inline_%s.png[/img][/font] per bee[/center]"
const WORKER_LIMIT_INCREASE_BBCODE_TEXT_FORMAT: String = \
	"[center][img=44]res://assets/sprites/gathering_spot_buttons/%s_button_normal.png[/img][/center]"
const PRODUCTION_INCREASE_BBCODE_TEXT_FORMAT: String = \
	"[center]+ %d [font=res://assets/fonts/ImgVerticalOffsetBitmapFont.tres][img=32]res://assets/sprites/symbols/inline/inline_%s.png[/img][/font] per bee[/center]"
const HONEYCOMB_BONUS_BBCODE_TEXT_FORMAT: String = \
	"[center]+ %d [font=res://assets/fonts/ResSymbolVerticalOffsetBitmapFont.tres][img=32]res://assets/sprites/symbols/inline/inline_honeycomb.png[/img][/font][/center]"

onready var name_and_level_panel: Panel = \
	$GatheringSpotDataInfoPanel
onready var name_and_level_label: Label = \
	$GatheringSpotDataInfoPanel/MarginContainer/LabelContainer/NameAndLevelLabel
onready var info_label: RichTextLabel = \
	$GatheringSpotDataInfoPanel/MarginContainer/LabelContainer/InfoRichTextLabel
onready var upgrade_info_panel: Panel = \
	$UpgradeInfoContainer/NextUpgradeTextPanel
onready var upgrade_info_container: VBoxContainer = $UpgradeInfoContainer
onready var first_bonus_panel: Panel = \
	$UpgradeInfoContainer/UpgradeBonusInfoContainer/FirstBonusPanel
onready var first_bonus_label: RichTextLabel = \
	$UpgradeInfoContainer/UpgradeBonusInfoContainer/FirstBonusPanel/MarginContainer/FirstBonusRichTextLabel
onready var second_bonus_panel: Panel = \
	$UpgradeInfoContainer/UpgradeBonusInfoContainer/SecondBonusPanel
onready var second_bonus_label: RichTextLabel = \
	$UpgradeInfoContainer/UpgradeBonusInfoContainer/SecondBonusPanel/MarginContainer/SecondBonusRichTextLabel

func _ready() -> void:
	set_default_values()

# Sets the visual data according to the given gathering spot data.
func set_values(data: Dictionary) -> void:
	var level_str: String = "MAX"
	var resource_type_str: String = Enums.to_str_snake_case(Enums.Resource, data.resource_type)
	upgrade_info_container.hide()
	_set_panel_styles(data.resource_type)
	if data.level < data.max_level:
		level_str = str(data.level)
		_set_upgrade_bonus(
			data.next_level_info[0].type, 
			data.next_level_info[0].amount, 
			resource_type_str,
			first_bonus_label)
		_set_upgrade_bonus(
			data.next_level_info[1].type, 
			data.next_level_info[1].amount, 
			resource_type_str,
			second_bonus_label)
		upgrade_info_container.show()
	name_and_level_label.text = NAME_AND_LEVEL_TEXT_FORMAT % [data.name, level_str]
	info_label.bbcode_text = INFO_BBCODE_TEXT_FORMAT % [data.production_amount, resource_type_str]

# Sets the default visual data.
func set_default_values() -> void:
	info_label.text = ""


func _set_panel_styles(res_type: int) -> void:
	var res_str: String = Enums.to_str(Enums.Resource, res_type)
	var style: StyleBoxTexture = load(BOX_STYLE_PATH_FORMAT % res_str)
	name_and_level_panel.set("custom_styles/panel", style)
	upgrade_info_panel.set("custom_styles/panel", style)
	first_bonus_panel.set("custom_styles/panel", style)
	second_bonus_panel.set("custom_styles/panel", style)


func _set_upgrade_bonus(type: int, amount: int, res_type_str: String, label: RichTextLabel) -> void:
	match type:
		Enums.GatheringSpotUpgrade.INCREASE_WORKER_LIMIT:
			label.bbcode_text = WORKER_LIMIT_INCREASE_BBCODE_TEXT_FORMAT % res_type_str
		Enums.GatheringSpotUpgrade.INCREASE_PRODUCTION_AMOUNT:
			label.bbcode_text = PRODUCTION_INCREASE_BBCODE_TEXT_FORMAT % [amount, res_type_str]
		Enums.GatheringSpotUpgrade.HONEYCOMB:
			label.bbcode_text = HONEYCOMB_BONUS_BBCODE_TEXT_FORMAT % amount

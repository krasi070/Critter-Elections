class_name OverallCandidateProjectionContainer
extends HBoxContainer
# OverallCandidateProjectionContainer's script.

const PREDICTED_POINTS_TEXT_FORMAT: String = "predicted to win in %d areas (%s)"
const PREDICTED_ONE_POINT_TEXT_FORMAT: String = "predicted to win in 1 area (%s)"
const PREDICTED_ZERO_POINTS_TEXT_FORMAT: String = "predicted to win in 0 areas"
const IN_THE_LEAD_BBCODE_TEXT: String = "\n[center][wave amp=50 freq=5]in the lead[/wave][/center]\n"
const CLOSE_RACE_BBCODE_TEXT: String = "\n[center][wave amp=50 freq=5]close race[/wave][/center]\n"
const SECOND_PICK_BBCODE_TEXT: String = "\n[center]second pick[/center]\n"
const UNDERDOG_BBCODE_TEXT: String = "\n[center]underdog[/center]\n"
const UNDECIDED_TEXT_FORMAT: String = "Undecided areas: %s"

const WINNING_FONT_COLOR: Color = Color.white
const NOT_WINNING_FONT_COLOR: Color = Color.gray

onready var rich_text_container: VBoxContainer = $RichTextContainer
onready var rich_text_label: RichTextLabel = $RichTextContainer/RichTextLabel
onready var candidate_texture_rect: TextureRect = $CandidateTextureRect
onready var predicted_points_label: Label = $PredictedPointsLabel
onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	modulate = Color.transparent


func set_candidate(team: int, leading_areas: Array, placement: int, is_tied: bool = false) -> void:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	var candidate_texture: Texture = load(Paths.CANDIDATE_SPRITE_PATH_FORMAT % team_str)
	candidate_texture_rect.texture = candidate_texture
	var font_color: Color = WINNING_FONT_COLOR
	if placement == 1 and not is_tied:
		rich_text_label.bbcode_text = IN_THE_LEAD_BBCODE_TEXT
	elif placement == 1 and is_tied:
		rich_text_label.bbcode_text = CLOSE_RACE_BBCODE_TEXT
	elif placement == 2:
		rich_text_label.bbcode_text = SECOND_PICK_BBCODE_TEXT
		font_color = NOT_WINNING_FONT_COLOR
	else:
		rich_text_label.bbcode_text = UNDERDOG_BBCODE_TEXT
		font_color = NOT_WINNING_FONT_COLOR
	rich_text_label.set("custom_colors/default_color", font_color)
	predicted_points_label.set("custom_colors/font_color", font_color)
	if leading_areas.size() > 1:
		predicted_points_label.text = \
			PREDICTED_POINTS_TEXT_FORMAT % [leading_areas.size(), _get_areas_as_str(leading_areas)]
	elif leading_areas.size() == 1:
		predicted_points_label.text = PREDICTED_ONE_POINT_TEXT_FORMAT % [_get_areas_as_str(leading_areas)]
	else:
		predicted_points_label.text = PREDICTED_ZERO_POINTS_TEXT_FORMAT


func set_undecided(undecided_areas: Array) -> void:
	rich_text_container.hide()
	candidate_texture_rect.hide()
	if undecided_areas.size() > 0:
		predicted_points_label.text = UNDECIDED_TEXT_FORMAT % _get_areas_as_str(undecided_areas)
	else: 
		predicted_points_label.hide()


func show_results() -> void:
	anim_player.play("appear")


func _get_areas_as_str(areas: Array) -> String:
	var areas_str: String = ""
	for area in areas:
		areas_str += "%s, " % Enums.to_str(Enums.TileType, area)
	areas_str = areas_str.trim_suffix(", ")
	return areas_str

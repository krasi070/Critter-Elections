class_name CandidateProjectionBarContainer
extends HBoxContainer
# CandidateProjectionBarContainer's script.
# Represents a visual representation of how well a candidate is doing.

signal finished_progress_animation

const PERCENTAGE_TEXT_FORMAT: String = "%1.1f%%  "

const ANIM_DELAY: float = 1.0
const PROGRESS_BAR_SIZE_MULTIPLIER: float = 5.0
const DEFAULT_PROGRESS_BAR_COLOR: Color = Color.gray

onready var percentage_label: Label = $PercentageLabel
onready var progress_bar_rect: ColorRect = $ProgressBarContainer/ProgressBarColorRect
onready var candidate_texture_rect: TextureRect = $CandidateTextureContainer/CandidatePortraitTextureRect
onready var non_candidate_text_label: Label = $TextLabel
onready var delay_timer: Timer = $DelayTimer

var _is_tweening: bool = false

func _ready() -> void:
	percentage_label.text = "?%  "
	progress_bar_rect.rect_min_size = Vector2(0, progress_bar_rect.rect_min_size.y)
	#animate_projection_value(0)


func _process(_delta: float) -> void:
	if _is_tweening:
		_update_percentage_label_based_on_progress_bar_size()


func prepare_projection(team: int, text: String = "undecided") -> void:
	percentage_label.text = "?%  "
	progress_bar_rect.rect_min_size = Vector2(0, progress_bar_rect.rect_min_size.y)
	if team < 0:
		set_non_team_text(text)
		progress_bar_rect.color = DEFAULT_PROGRESS_BAR_COLOR
		return
	var color: Color = DEFAULT_PROGRESS_BAR_COLOR
	if MatchRoomManager.team_colors.size() > team:
		color = MatchRoomManager.team_colors[team]
	progress_bar_rect.color = color
	set_team_texture(team)


func animate_projection_value(projection_value: float, wait: float = ANIM_DELAY) -> void:
	progress_bar_rect.rect_min_size = Vector2(0, progress_bar_rect.rect_min_size.y)
	_is_tweening = true
	var tween: SceneTreeTween = create_tween()
	tween.connect("finished", self, "_finished_tween", [wait])
	tween.tween_property(
		progress_bar_rect, 
		"rect_min_size:x", 
		projection_value * PROGRESS_BAR_SIZE_MULTIPLIER,
		min(projection_value / 10.0, 3.0)).set_ease(
			Tween.EASE_OUT).set_trans(
				Tween.TRANS_QUART)


func set_team_texture(team: int) -> void:
	candidate_texture_rect.texture = _get_texture_for_team(team)
	candidate_texture_rect.show()
	non_candidate_text_label.hide()


func set_non_team_text(text: String) -> void:
	non_candidate_text_label.text = text
	candidate_texture_rect.hide()
	non_candidate_text_label.show()


func _set_projection_value(projection_value: float) -> void:
	percentage_label.text = PERCENTAGE_TEXT_FORMAT % projection_value
	progress_bar_rect.rect_min_size = Vector2(
		projection_value * PROGRESS_BAR_SIZE_MULTIPLIER, 
		progress_bar_rect.rect_min_size.y)


func _update_percentage_label_based_on_progress_bar_size() -> void:
	var progress_bar_size: float = progress_bar_rect.rect_min_size.x
	var percentage: float = progress_bar_size / PROGRESS_BAR_SIZE_MULTIPLIER
	percentage_label.text = PERCENTAGE_TEXT_FORMAT % percentage


func _get_texture_for_team(team: int) -> Resource:
	var team_str: String = Enums.to_str_snake_case(Enums.Team, team)
	return load(Paths.CANDIDATE_PORTRAIT_TEXTURE_PATH_FORMAT % team_str)


func _finished_tween(wait: float) -> void:
	_is_tweening = false
	delay_timer.start(wait)
	yield(delay_timer, "timeout")
	emit_signal("finished_progress_animation")

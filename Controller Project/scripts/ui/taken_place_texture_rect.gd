class_name TakenPlaceTextureRect
extends TextureRect
# TakenPlaceTextureRect's script.

const MULTIPLIER_TEXT_FORMAT: String = "x%d"
const ALPHA_BLEND_SPEED: float = 0.001

onready var team_color_background: ColorRect = $TeamColorBackground
onready var progress: TextureProgress = $TextureProgress
onready var res_multiplier_label: Label = $ResourceMultiplierLabel

var _is_automatic_production_on: bool = false
var _worker_id: String
var _space_index: int = -1

func _ready() -> void:
	set_default_values()


func _physics_process(_delta: float) -> void:
	if _is_automatic_production_on:
		return
	if not PlayerData.location_type == Enums.LocationType.GATHERING_SPOT:
		return
	if _space_index < 0:
		return
	if not PlayerData.location_data.working_workers[_space_index].empty() and \
		not progress.value == progress.max_value:
		res_multiplier_label.modulate = Color(1, 1, 1, 1 - abs(sin(Time.get_ticks_msec() * ALPHA_BLEND_SPEED)))
		progress.value = PlayerData.location_data.working_workers[_space_index].curr_work_completed

# Sets the visual data according to the given worker data and production_time.
func set_values(worker_data: Dictionary, production_time: float, space_index: int) -> void:
	_worker_id = worker_data.id
	_space_index = space_index
	progress.max_value = production_time
	progress.min_value = 0.0
	progress.value = worker_data.curr_work_completed
	res_multiplier_label.visible = worker_data.reward_multiplier != 1
	res_multiplier_label.text = MULTIPLIER_TEXT_FORMAT % worker_data.reward_multiplier
	texture = WorkerHelper.get_texture_by_worker_type(worker_data.type)
	team_color_background.color = TeamData.get_team_color_by_index(worker_data.team_index)

# Sets the default visual data.
func set_default_values() -> void:
	_is_automatic_production_on = false
	_space_index = -1
	progress.value = progress.min_value
	res_multiplier_label.visible = false
	res_multiplier_label.modulate = Color(1, 1, 1, 1 - abs(sin(Time.get_ticks_msec() * ALPHA_BLEND_SPEED)))
	team_color_background.color = Color.transparent

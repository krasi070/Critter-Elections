class_name PredictionResultsOverlay
extends CanvasLayer
# PredictionResultsOverlay's script.

signal closed_prediction_results
signal finished_showing_title
signal finished_showing_area_results
signal finished_showing_overall_results
signal finished_showing_election_results

const PREDICTIONS_TIME_TITLE: String = "Extra! Extra! Read all about it!\nNew predictions for the elections are out!"
const ELECTION_RESULTS_TIME_TITLE: String = "Extra! Extra! Read all about it!\nThe mayor election results are OUT!"

const AREA_PREDICTIONS_TITLE_TEXT_FORMAT: String = "Predictions for %s Area"
const AREA_ELECTION_RESULTS_TITLE_TEXT_FORMAT: String = "Election Results for %s Area"
const OVERALL_PREDICTIONS_TITLE_TEXT: String = "Overall Predictions for Critter Island"
const OVERALL_ELECTION_RESULTS_TITLE_TEXT: String = "Election Results for Critter Island"

const DEFAULT_FADE_DURATION: float = 0.3

var curr_round: int = 0
var is_ready_to_close: bool = false

onready var screen_label: Label = $ScreenLabel
onready var effects_label: Label = $EffectScreenLabel
onready var results_rect: NinePatchRect = $ResultsRect
onready var anim_player: AnimationPlayer = $AnimationPlayer

var _curr_round_results: Dictionary

func _ready() -> void:
	hide()
	_connect_signals()


func _input(event: InputEvent) -> void:
	if visible and is_ready_to_close and get_tree().paused and event.is_action_pressed("continue"):
		_close_predictions_overlay()


func show_prediction_results() -> void:
	AudioController.play_music(AudioController.MAIN_THEME)
	var is_final_round: bool = _preshow_setup()
	_show_title_view()
	_show_title(is_final_round)
	yield(self, "finished_showing_title")
	_show_results_view()
	for area in Enums.TileType.values():
		_show_area_prediction_results(area, is_final_round)
		yield(self, "finished_showing_area_results")
	_show_overall_prediction_results(is_final_round)
	yield(self, "finished_showing_overall_results")
	if is_final_round:
		_show_election_results()
		yield(self, "finished_showing_election_results")
	else:
		results_rect.show_continue_label()
		is_ready_to_close = true
	MatchRoomManager.inform_players_of_predictions_over()


func _connect_signals() -> void:
	results_rect.return_to_title_screen_button.connect(
		"pressed", 
		self, 
		"_pressed_title_screen_button")
	MatchRoomManager.connect(
		"room_master_pressed_continued", 
		self, 
		"_match_room_manager_room_master_pressed_continue")
	MatchRoomManager.connect(
		"closed_room", 
		self, 
		"_match_room_manager_closed_room")
	MatchRoomManager.connect(
		"restarted_game", 
		self, 
		"_match_room_manager_restarted_game")


func _preshow_setup() -> bool:
	PauseOverlay.is_pausible = false
	get_tree().paused = true
	is_ready_to_close = false
	curr_round += 1
	_curr_round_results = MapData.get_area_projection_results()
	MatchRoomManager.inform_players_of_predictions_enter(curr_round)
	show()
	return curr_round == Settings.number_of_rounds


func _close_setup() -> void:
	get_tree().paused = false
	PauseOverlay.is_pausible = true
	hide()


func _show_title_view() -> void:
	screen_label.show()
	effects_label.show()
	results_rect.hide()


func _show_results_view() -> void:
	screen_label.hide()
	effects_label.hide()
	results_rect.show()


func _show_title(is_final: bool = false) -> void:
	var title: String = PREDICTIONS_TIME_TITLE
	if is_final:
		title = ELECTION_RESULTS_TIME_TITLE
	screen_label.text = title
	effects_label.text = title
	anim_player.play("enlarge")
	yield(anim_player, "animation_finished")
	emit_signal("finished_showing_title")


func _show_area_prediction_results(area: int, is_final: bool = false) -> void:
	results_rect.free_children_in_dynamic_containers()
	results_rect.show_area_projections_container()
	if is_final:
		results_rect.set_reslts_label(AREA_ELECTION_RESULTS_TITLE_TEXT_FORMAT % Enums.to_str(Enums.TileType, area))
	else:
		results_rect.set_reslts_label(AREA_PREDICTIONS_TITLE_TEXT_FORMAT % Enums.to_str(Enums.TileType, area))
	var team_projections: Dictionary = {}
	for team in MatchRoomManager.teams.keys():
		team_projections[team] = results_rect.add_default_projection()
		team_projections[team].prepare_projection(team)
	var undecided_projection: HBoxContainer = results_rect.add_default_projection()
	undecided_projection.prepare_projection(-1, "undecided")
	var percentages_sum: float = 0
	var fade_in_tween: SceneTreeTween = _fade_in_element(results_rect)
	yield(fade_in_tween, "finished")
	for team in MatchRoomManager.teams.keys():
		var supporters: int = MapData.projections[area].candidate_support[team]
		var percentage: float = stepify(MapData.get_percentage_of_population_in_area(supporters, area), 0.1)
		percentages_sum += percentage
		team_projections[team].animate_projection_value(percentage)
		yield(team_projections[team], "finished_progress_animation")
	undecided_projection.animate_projection_value(100 - percentages_sum)
	yield(undecided_projection, "finished_progress_animation")
	var fade_out_tween: SceneTreeTween = _fade_out_element(results_rect)
	yield(fade_out_tween, "finished")
	emit_signal("finished_showing_area_results")


func _show_overall_prediction_results(is_final: bool = false) -> void:
	results_rect.free_children_in_dynamic_containers()
	results_rect.show_overall_projections_container()
	if is_final:
		results_rect.set_reslts_label(OVERALL_ELECTION_RESULTS_TITLE_TEXT)
	else:
		results_rect.set_reslts_label(OVERALL_PREDICTIONS_TITLE_TEXT)
	var overall_projections: Array = []
	for team in _curr_round_results.teams.keys():
		overall_projections.append(
			results_rect.add_overall_candidate_projection(team, _curr_round_results.teams[team]))
	if _curr_round_results.undecided_areas.size() > 0:
		overall_projections.append(results_rect.add_overall_undecided_projection(_curr_round_results.undecided_areas))
	var fade_in_tween: SceneTreeTween = _fade_in_element(results_rect)
	yield(fade_in_tween, "finished")
	for projection in overall_projections:
		projection.show_results()
		yield(projection.anim_player, "animation_finished")
	yield(get_tree().create_timer(2.5), "timeout")
	emit_signal("finished_showing_overall_results")


func _show_election_results() -> void:
	results_rect.free_children_in_dynamic_containers()
	results_rect.show_election_results()
	results_rect.set_reslts_label(OVERALL_ELECTION_RESULTS_TITLE_TEXT)
	var teams_by_placement: Dictionary = _get_teams_by_placement_from_curr_round_results()
	var winning_team: int = Enums.Team.NOT_SELECTED
	if teams_by_placement[1].size() == 1:
		winning_team = teams_by_placement[1].pop_front()
		teams_by_placement.erase(1)
	if teams_by_placement.empty():
		results_rect.losers_container.hide()
	if winning_team != Enums.Team.NOT_SELECTED:
		results_rect.set_winner_elements(winning_team)
	else:
		results_rect.set_no_winner_text()
	var losing_team_containers: Array = []
	for placement in teams_by_placement.keys():
		for team in teams_by_placement[placement]:
			var instance: HBoxContainer = \
				results_rect.add_election_loser_element(team, placement)
			instance.modulate = Color.transparent
			losing_team_containers.append(instance)
	var fade_in_tween: SceneTreeTween = _fade_in_element(results_rect)
	yield(fade_in_tween, "finished")
	for element in losing_team_containers:
		fade_in_tween = _fade_in_element(element, results_rect.DEFAULT_FADE_DURATION)
		yield(fade_in_tween, "finished")
	emit_signal("finished_showing_election_results")


func _close_predictions_overlay() -> void:
	_close_setup()
	emit_signal("closed_prediction_results")
	MatchRoomManager.inform_players_to_continue_after_predictions()


func _get_teams_by_placement_from_curr_round_results() -> Dictionary:
	var teams_by_placement: Dictionary = {}
	for team in _curr_round_results.teams.keys():
		var placement: int = _curr_round_results.teams[team].placement
		if not teams_by_placement.has(placement):
			teams_by_placement[placement] = []
		teams_by_placement[placement].append(team)
	return teams_by_placement


func _fade_in_element(element: Control, duration: float = DEFAULT_FADE_DURATION) -> SceneTreeTween:
	element.modulate = Color.transparent
	var tween: SceneTreeTween = create_tween()
	tween.tween_property(element, "modulate:a", 1.0, duration)
	return tween


func _fade_out_element(element: Control, duration: float = DEFAULT_FADE_DURATION) -> SceneTreeTween:
	element.modulate = Color.white
	var tween: SceneTreeTween = create_tween()
	tween.tween_property(element, "modulate:a", 0.0, duration)
	return tween


func _match_room_manager_room_master_pressed_continue() -> void:
	_close_predictions_overlay()


func _pressed_title_screen_button() -> void:
	MatchRoomManager.send_disconnect_players_request()
	MatchRoomManager.send_close_room_request()


func _match_room_manager_closed_room() -> void:
	get_tree().paused = false
	hide()
	get_tree().change_scene(Paths.TITLE_SCREEN_SCENE_PATH)


func _match_room_manager_restarted_game() -> void:
	_close_setup()

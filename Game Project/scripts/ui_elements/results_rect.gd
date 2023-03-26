class_name ResultsRect
extends NinePatchRect
# ResultsRect's script.

signal element_faded_in(element)

const CANDIDATE_PROJECTION_BAR_CONTAINER_SCENE: PackedScene = \
	preload("res://scenes/ui/CandidateProjectionBarContainer.tscn")
const OVERALL_CANDIDATE_PROJECTION_SCENE: PackedScene = \
	preload("res://scenes/ui/OverallCandidateProjectionContainer.tscn")
const ELECTION_LOSER_CONTAINER_SCENE: PackedScene = \
	preload("res://scenes/ui/ElectionLoserContainer.tscn")

const WIN_BBCODE_TEXT: String = "\n[center][wave amp=20 freq=5]Critter Island's Newly Elected Mayor & Deputy Mayor[/wave][/center]"
const NO_WINNER_BBCODE_TEXT: String = "[center]Unfortunately, the top candidates tied and a mayor could not be appointed...[/center]"

const DEFAULT_FADE_DURATION: float = 1.0

onready var results_label: Label = \
	$MarginContainer/VBoxContainer/ResultsTextLabel
onready var projections_container: VBoxContainer = \
	$MarginContainer/VBoxContainer/ProjectionsContainer
onready var overall_projections_container: VBoxContainer = \
	$MarginContainer/VBoxContainer/OverallProjectionsContainer
onready var press_space_to_continue_label: Label = \
	$MarginContainer/VBoxContainer/PressSpaceToContinueLabel
onready var continue_label_anim_player: AnimationPlayer = \
	$MarginContainer/VBoxContainer/PressSpaceToContinueLabel/AnimationPlayer
onready var election_results_container: HBoxContainer = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer
onready var winners_container: VBoxContainer = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer/WinnersContainer
onready var winners_rich_text_label: RichTextLabel = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer/WinnersContainer/WinnersRichTextContainer/WinnersRichTextLabel
onready var winners_textures_container: HBoxContainer = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer/WinnersContainer/WinnersTexturesContainer
onready var winner_campaigner_texture_rect: TextureRect = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer/WinnersContainer/WinnersTexturesContainer/CampaignerTextureRect
onready var winner_gatherer_texture_rect: TextureRect = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer/WinnersContainer/WinnersTexturesContainer/GathererTextureRect
onready var losers_container: VBoxContainer = \
	$MarginContainer/VBoxContainer/ElectionResultsContainer/LosersContainer
onready var return_to_title_screen_button: Button = \
	$MarginContainer/VBoxContainer/ReturnToTitleScreenButton

func set_reslts_label(text: String) -> void:
	results_label.text = text


func show_area_projections_container() -> void:
	projections_container.show()
	overall_projections_container.hide()
	press_space_to_continue_label.hide()
	election_results_container.hide()
	return_to_title_screen_button.hide()


func show_overall_projections_container() -> void:
	projections_container.hide()
	overall_projections_container.show()
	press_space_to_continue_label.show()
	press_space_to_continue_label.modulate = Color.transparent
	election_results_container.hide()
	return_to_title_screen_button.hide()


func show_election_results() -> void:
	projections_container.hide()
	overall_projections_container.hide()
	press_space_to_continue_label.hide()
	election_results_container.show()
	return_to_title_screen_button.show()


func show_continue_label() -> void:
	press_space_to_continue_label.modulate = Color.white
	continue_label_anim_player.play("alpha_blend")


func fade_in_element(element: Control, duration: float = DEFAULT_FADE_DURATION) -> void:
	element.modulate = Color.transparent
	element.show()
	var fade_tween: SceneTreeTween = create_tween()
	fade_tween.connect("finished", self, "_finished_fade_tween", [element])
	fade_tween.tween_property(element, "modulate:a", 1.0, duration)


func set_winner_elements(winning_team: int) -> void:
	winners_rich_text_label.bbcode_text = WIN_BBCODE_TEXT
	winners_rich_text_label.show()
	var team_str: String = Enums.to_str_snake_case(Enums.Team, winning_team)
	winner_campaigner_texture_rect.texture = load(Paths.CANDIDATE_SPRITE_PATH_FORMAT % team_str)
	winner_campaigner_texture_rect.show()
	var gatherer_str: String = Enums.to_str_snake_case(Enums.Role, Enums.Role.GATHERER)
	winner_gatherer_texture_rect.texture = load(Paths.CHARACTER_SPRITE_PATH_FORMAT % [team_str, gatherer_str])
	winner_gatherer_texture_rect.show()
	winners_textures_container.show()


func set_no_winner_text() -> void:
	winners_textures_container.hide()
	winners_rich_text_label.bbcode_text = NO_WINNER_BBCODE_TEXT


func add_election_loser_element(team: int, placement: int) -> HBoxContainer:
	var instance: HBoxContainer = _add_election_loser_instance()
	instance.set_loser_team(team, placement)
	return instance


func add_overall_candidate_projection(team: int, team_results_data: Dictionary) -> HBoxContainer:
	var instance: HBoxContainer = _add_overall_projection_instance()
	instance.set_candidate(team, team_results_data.areas, team_results_data.placement, team_results_data.is_tied)
	return instance


func add_overall_undecided_projection(undecided_areas: Array) -> HBoxContainer:
	var instance: HBoxContainer = _add_overall_projection_instance()
	instance.set_undecided(undecided_areas)
	return instance


func add_default_projection() -> HBoxContainer:
	return _add_projection_instance()


func add_candidate_projection(projection_value: float, team: int) -> void:
	var candidate_projection: HBoxContainer = _add_projection_instance()
	candidate_projection.set_projection_for_team(projection_value, team)


func add_non_candidate_projection(projection_value: float, text: String) -> void:
	var projection: HBoxContainer = _add_projection_instance()
	projection.set_projection_for_non_team(projection_value, text)


func free_children_in_dynamic_containers() -> void:
	for projection in projections_container.get_children():
		projection.queue_free()
	for projection in overall_projections_container.get_children():
		projection.queue_free()
	for loser_team in losers_container.get_children():
		loser_team.queue_free()


func _add_projection_instance() -> HBoxContainer:
	var instance: HBoxContainer = CANDIDATE_PROJECTION_BAR_CONTAINER_SCENE.instance()
	projections_container.add_child(instance)
	return instance


func _add_overall_projection_instance() -> HBoxContainer:
	var instance: HBoxContainer = OVERALL_CANDIDATE_PROJECTION_SCENE.instance()
	overall_projections_container.add_child(instance)
	return instance


func _add_election_loser_instance() -> HBoxContainer:
	var instance: HBoxContainer = ELECTION_LOSER_CONTAINER_SCENE.instance()
	losers_container.add_child(instance)
	return instance


func _finished_fade_tween(element: Control) -> void:
	emit_signal("element_faded_in", element)

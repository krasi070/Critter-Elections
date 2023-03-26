class_name PauseElementsContainer
extends VBoxContainer
# PauseElementsContainer's script.

const PAUSED_TEXT: String = "PAUSED"
const ROUND_TEXTS: Array = ["First", "Second", "Third"]
const PREDICTIONS_TEXT_FORMAT: String = "%s Predictions"
const FINAL_ROUND_TEXT: String = "Final Predictions Before Elections"
const ELECTION_RESULTS_TEXT: String = "Election Results"
const PLAY_AGAIN_TEXT: String = "Play Again"

onready var main_label: Label = $MainLabel
onready var continue_button: Button = $ContinueButton
onready var keep_teams_button: Button = $KeepTeamsButton
onready var swap_roles_button: Button = $SwapRolesButton
onready var change_teams_button = $ChangeTeamsButton
onready var middle_label: Label = $MiddleLabel
onready var close_room_button: Button = $CloseRoomButton

# Sets the main label's text to Paused and hides every other element.
func show_paused_view() -> void:
	main_label.text = PAUSED_TEXT
	main_label.show()
	continue_button.hide()
	keep_teams_button.hide()
	swap_roles_button.hide()
	change_teams_button.hide()
	middle_label.hide()
	close_room_button.hide()

# Sets the main label's text to show the round. If the player is room master,
# the continue button is also shown if it is not the end of the game. 
# Hides every other element.
func show_predictions_view(curr_round: int, number_of_rounds: int) -> void:
	if curr_round == number_of_rounds:
		main_label.text = ELECTION_RESULTS_TEXT
	elif curr_round + 1 == number_of_rounds:
		main_label.text = FINAL_ROUND_TEXT
	else:
		main_label.text = PREDICTIONS_TEXT_FORMAT % ROUND_TEXTS[curr_round - 1]
	main_label.show()
	if PlayerData.is_room_master():
		continue_button.visible = curr_round != number_of_rounds
	keep_teams_button.hide()
	swap_roles_button.hide()
	change_teams_button.hide()
	middle_label.hide()
	close_room_button.hide()

# Only works for room master. Sets the main label's text to Play Again? and 
# hides the continue button. Shows every other element.
func show_game_end_view() -> void:
	if not PlayerData.is_room_master():
		return
	main_label.text = PLAY_AGAIN_TEXT
	main_label.show()
	continue_button.hide()
	keep_teams_button.show()
	swap_roles_button.show()
	change_teams_button.show()
	middle_label.show()
	close_room_button.show()

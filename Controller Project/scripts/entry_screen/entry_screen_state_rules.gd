extends State
# The Rules state of the EntryScreen.
# Shows navigateable pages of the rules.

func on_enter() -> void:
	_connect_signals()
	_set_elements_visibility(true)


func on_exit() -> void:
	_disconnect_signals()
	_set_elements_visibility(false)


func run(_delta: float) -> void:
	pass


func _connect_signals() -> void:
	obj.rules_container.connect("pressed_back_button", self, "_rules_container_pressed_back_button")


func _disconnect_signals() -> void:
	obj.rules_container.disconnect("pressed_back_button", self, "_rules_container_pressed_back_button")


func _set_elements_visibility(is_visible: bool) -> void:
	obj.rules_container.visible = is_visible


func _rules_container_pressed_back_button() -> void:
	fsm.transition_to_state(fsm.states.JoinRoom)

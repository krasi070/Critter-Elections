class_name State
extends Node
# Representation of a state in a finite state machine.
# Intended to be extended, comes with on_enter, on_exit and run functions.

# The finite state machine the state is a part of.
var fsm: Node
# The object that uses the finite state machine this state is a part of.
var obj: Node

# Executed when the finite state machine transitions to this state.
func on_enter() -> void:
	pass

# Executed when the finite state machine transitions from this state to another.
func on_exit() -> void:
	pass

# Executed every time _process or _physics_process is called, depending on
# where the run_machine function of the finite state machine is called.
func run(_delta: float) -> void:
	pass

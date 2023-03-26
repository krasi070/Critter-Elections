class_name FiniteStateMachine
extends Node
# Base finite state machine class.I
# Intended to be used by objects that have multiple states for ease of 
# transitioning between them. 

# If true, prints when the state is changed.
var debug: bool = false
# The state instances.
var states: Dictionary = {}
# The current state of the machine.
var state_curr: Node
# The next state the machine has to transition to.
var state_next: Node
# The state the machine was in before the current one.
var state_prev: Node
# The object using the finite state machine.
var obj: Node

func _init(_obj, states_parent_node, initial_state, _debug = false) -> void:
	self.obj = _obj
	self.debug = _debug
	_set_states_parent_node(states_parent_node)
	state_next = initial_state

# Intended to be called in the _process or _physics_process function of the
# class using the finite state machine. Checks for a change in states and
# transitions between them if necessary.
func run_machine(delta: float) -> void:
	if state_next != state_curr:
		if state_curr != null:
			_debug_log("changing from %s to %s" % [state_curr.name, state_next.name])
			state_curr.on_exit()
		else:
			_debug_log("starting with state %s" % state_next.name)
		state_prev = state_curr
		state_curr = state_next
		state_curr.on_enter()
	state_curr.run(delta)

# Set the next state of the machine. If force is false and the machine
# is mid transition to another state do not transition to the given state.
# If force is true, override any other transition that might be occuring.
func transition_to_state(to: Node, force: bool = false) -> void:
	if force:
		state_next = to
		return
	if state_curr == state_next:
		state_next = to


func _set_states_parent_node(parent_node: Node) -> void:
	_debug_log("found %d states" % parent_node.get_child_count())
	if parent_node.get_child_count() == 0:
		return
	var state_nodes = parent_node.get_children()
	for state_node in state_nodes:
		_debug_log("adding state %s" % state_node.name)
		states[state_node.name] = state_node
		state_node.fsm = self
		state_node.obj = self.obj


func _debug_log(msg: String) -> void:
	if debug:
		print("%s: %s" % [obj.name, msg])

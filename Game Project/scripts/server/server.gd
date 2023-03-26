extends Node
# Deals with network connectivity.

signal connected_to_server
signal connection_failed

const NETWORK_MASTER_ID: int = 1
const PORT: int = 9080
const SERVER_IP: String = "100.25.24.158"

var _client: WebSocketClient

func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	_connect_network_signals()

# Connects the given object's signal to a function that attempts a connection
# to the server.
func attempt_connection_on_signal_emitted(obj: Object, signal_name: String) -> void:
	obj.connect(signal_name, self, "_attempt_connection")

# Disconnects from the server.
func disconnect_from_server() -> void:
	if is_instance_valid(_client):
		_client.disconnect_from_host()


func _connect_network_signals() -> void:
	get_tree().connect("network_peer_disconnected", self, "_peer_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connected_failed")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func _attempt_connection() -> void:
	_client = WebSocketClient.new()
	# Uncomment and use for production.
	#var url = "ws://%s:%d" % [SERVER_IP, PORT]
	# Uncomment and use for testing.
	var url = "ws://127.0.0.1:%d" % PORT
	var _error: int = _client.connect_to_url(url, PoolStringArray(), true)
	get_tree().set_network_peer(_client)


func _peer_disconnected(id: int) -> void:
	print("ROOM CLIENT: Peer with id %d disconnected!" % id)


func _connected_to_server() -> void:
	print("ROOM CLIENT: Connected to server!")
	emit_signal("connected_to_server")


func _connected_failed() -> void:
	print("ROOM CLIENT: Connection failed!")
	MatchRoomManager.remove_room_data()
	emit_signal("connection_failed")


func _server_disconnected() -> void:
	print("ROOM CLIENT: Disconnected from server!")
	MatchRoomManager.remove_room_data()

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

# Attempts a connection to the server if possible.
func attempt_connection() -> void:
	_client = WebSocketClient.new()
	# Uncomment and use for production.
	#var url = "ws://%s:%d" % [SERVER_IP, PORT]
	# Uncomment and use for testing.
	var url = "ws://127.0.0.1:%d" % PORT
	var _error: int = _client.connect_to_url(url, PoolStringArray(), true)
	get_tree().set_network_peer(_client)

# Returns true if the player is connected to the server.
func is_connected_to_server() -> bool:
	if is_instance_valid(_client):
		return _client.get_connection_status() == _client.CONNECTION_CONNECTED
	return false

# Disconnects from the server.
func disconnect_from_server() -> void:
	if is_instance_valid(_client):
		_client.disconnect_from_host()


func _connect_network_signals() -> void:
	get_tree().connect("connected_to_server", self, "_connected_to_server", [], CONNECT_DEFERRED)
	get_tree().connect("connection_failed", self, "_connected_failed", [], CONNECT_DEFERRED)
	get_tree().connect("server_disconnected", self, "_server_disconnected", [], CONNECT_DEFERRED)


func _connected_to_server() -> void:
	print("PLAYER CLIENT: Connected to server!")
	emit_signal("connected_to_server")


func _connected_failed() -> void:
	print("PLAYER CLIENT: Connection failed!")
	MatchRoomManager.leave_room()
	emit_signal("connection_failed")


func _server_disconnected() -> void:
	print("PLAYER CLIENT: Disconnected from server!")
	MatchRoomManager.leave_room()

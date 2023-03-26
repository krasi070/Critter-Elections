extends Node
# Deals with network connectivity.

const PORT: int = 9080

var _server: WebSocketServer = WebSocketServer.new()

func _ready() -> void:
	_connect_network_signals()
	var err: int = _server.listen(PORT, PoolStringArray(), true)
	if err != OK:
		print("SERVER: Could not listen on port %d!" % PORT)
	else:
		print("SERVER: Server started listening on port %d!" % PORT)
	get_tree().set_network_peer(_server)


func _connect_network_signals() -> void:
	get_tree().connect("network_peer_connected", self, "_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_peer_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func _peer_connected(id: int) -> void:
	print("SERVER: Peer with id %d connected!" % id)


func _peer_disconnected(id: int) -> void:
	print("SERVER: Peer with id %d disconnected!" % id)
	MatchRoomManager.handle_disconnect(id)


func _connected_ok() -> void:
	print("SERVER: Connection successful!")


func _connected_fail() -> void:
	print("SERVER: Connection failed!")


func _server_disconnected() -> void:
	print("SERVER: Disconnected!")

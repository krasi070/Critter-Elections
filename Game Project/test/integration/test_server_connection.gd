extends GutTest

func test_connected_to_server() -> void:
	Server._attempt_connection()
	yield(yield_to(Server, "connected_to_server", 30), YIELD)
	assert_signal_emitted(Server, "connected_to_server", "Could not connect to server!")

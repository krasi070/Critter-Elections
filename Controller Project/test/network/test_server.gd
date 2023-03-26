extends GutTest

func test_connected_to_server() -> void:
	assert_true(get_tree().has_network_peer(), "Network peer is not set!")

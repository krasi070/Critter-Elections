extends GutTest

func test_is_network_server() -> void:
	assert_true(get_tree().is_network_server())

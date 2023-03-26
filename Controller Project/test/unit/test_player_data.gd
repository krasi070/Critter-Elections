extends GutTest

func before_each() -> void:
	pass


func after_each() -> void:
	PlayerData.reset_data()


func test_set_data() -> void:
	var data: Dictionary = {
		"start_names": ["aaa", "b", "c"],
		"end_names": ["x", "yyy", "zzz"],
		"join_order": 3,
	}
	PlayerData.set_data(data)
	assert_eq(PlayerData.start_name_options, data.start_names, "Start names do not match!")
	assert_eq(PlayerData.end_name_options, data.end_names, "End names do not match!")
	assert_eq(PlayerData.join_order, data.join_order, "Join order is not 3!")
	assert_eq(PlayerData.start_name, "", "Start name should not be set yet!")
	assert_eq(PlayerData.end_name, "", "End name should not be set yet!")

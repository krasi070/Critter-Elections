extends GutTest

func after_each() -> void:
	MatchRoomManager.reset()


func test_set_room_key() -> void:
	watch_signals(MatchRoomManager)
	var room_key: String = "ABCD"
	MatchRoomManager.set_room_key(room_key)
	assert_eq(MatchRoomManager.room_key, room_key, "Room keys do not match!")
	assert_signal_emitted(MatchRoomManager, "created_room", "created_room signal was not emitted!")


func _set_dummy_players() -> void:
	for i in range(4):
		MatchRoomManager.players[1_000_000 + i] = {
			"id": 1_000_000 + i,
			"name": "Player %d" % i,
			"start_names": [],
			"end_names": [],
			"is_disconnected": false,
			"team": Enums.Team.NOT_SELECTED,
			"role": Enums.Role.NOT_SELECTED,
			"join_order": i,
			"location": Vector2(i, 0),
			"resources": {
				Enums.Resource.MONEY: 0,
				Enums.Resource.HONEY: 0,
				Enums.Resource.ICE: 0,
				Enums.Resource.LEAVES: 0,
				Enums.Resource.CARROTS: 0,
				Enums.Resource.CHEESE: 0,
			},
			"workers": [],
		}

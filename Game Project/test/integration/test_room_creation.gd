extends GutTest

func before_all() -> void:
	Server._attempt_connection()
	yield(yield_to(Server, "connected_to_server", 30), YIELD)


func after_each() -> void:
	MatchRoomManager.reset()


func test_create_and_close_room() -> void:
	MatchRoomManager.send_create_room_request()
	yield(yield_to(MatchRoomManager, "created_room", 2), YIELD)
	assert_signal_emitted(MatchRoomManager, "created_room", "created_room signal was not emitted!")
	assert_ne(MatchRoomManager.room_key, "", "Room key was not set on creation!")
	MatchRoomManager.send_close_room_request()
	yield(yield_to(MatchRoomManager, "closed_room", 2), YIELD)
	assert_signal_emitted(MatchRoomManager, "closed_room")
	assert_eq(MatchRoomManager.room_key, "", "Room key was not forgotten on room closed!")


func test_start_game() -> void:
	MatchRoomManager.send_create_room_request()
	yield(yield_to(MatchRoomManager, "created_room", 2), YIELD)
	MatchRoomManager.start_game()
	assert_signal_emitted(MatchRoomManager, "game_started", "game_started signal not emitted!")

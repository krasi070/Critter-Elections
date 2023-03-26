extends Node
# A global script that contains the paths the various resources.

# Path format strings.
const CHARACTER_SPRITE_PATH_FORMAT: String = \
	"res://assets/sprites/characters/%s_%s.png"
const CANDIDATE_SPRITE_PATH_FORMAT: String = \
	"res://assets/sprites/characters/%s_campaigner.png"
const CANDIDATE_PORTRAIT_TEXTURE_PATH_FORMAT: String = \
	"res://assets/sprites/characters/candidate_portraits/%s_candidate.png"
const GATHERING_SPOT_SPRITE_PATH_FORMAT: String = \
	"res://assets/sprites/map_objects/%s_spot.png"
const EVENT_CHARACTER_SPRITE_PATH_FORMAT: String = \
	"res://assets/sprites/characters/%s_event_character.png"
const RESOURCE_SYMBOL_PATH_FORMAT: String = \
	"res://assets/sprites/symbols/%s.png"
const UI_COLOR_BOX_SPRITE_PATH_FORMAT: String = \
	"res://assets/sprites/ui_elements/%s_box.png"
	
# Concrete path strings.
const TITLE_SCREEN_SCENE_PATH: String = \
	"res://scenes/screens/TitleScreen.tscn"
const ROOM_CREATION_SCENE_PATH: String = \
	"res://scenes/screens/RoomCreationScreen.tscn"
const MAP_SCREEN_SCENE_PATH: String = \
	"res://scenes/screens/MapScreen.tscn"

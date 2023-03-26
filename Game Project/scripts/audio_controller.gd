extends Node
# Handles everything to do with music and audio.

const MIN_VOLUME: int = 0
const MAX_VOLUME: int = 10
const DEFAULT_VOLUME: int = 5
const STEP: int = 1

const CLICK_SOUND: String = "click"
const HOVER_SOUND: String = "hover"

const MAIN_THEME: AudioStreamMP3 = preload("res://assets/audio/music/main_theme.mp3")
const GAME_LOOP: AudioStreamMP3 = preload("res://assets/audio/music/game_loop.mp3")
const PAUSE_LOOP: AudioStreamMP3 = preload("res://assets/audio/music/pause_theme.mp3")

const SFX: Dictionary = {
	CLICK_SOUND: preload("res://assets/audio/sfx/click.ogg"),
	HOVER_SOUND: preload("res://assets/audio/sfx/hover.ogg"),
}

const VOLUME_FIXER: Dictionary = {
	CLICK_SOUND: -15.0,
	HOVER_SOUND: -15.0,
}

const PITCH_RANDOMIZER: Dictionary = {
	CLICK_SOUND: [0.8, 1.2],
	HOVER_SOUND: [0.8, 1.2],
}

const MUTE_VOLUME: float = -1000.0

var volume: float = 0.0
var volume_setting_value: int = DEFAULT_VOLUME

onready var music_player: AudioStreamPlayer = $MusicPlayer
onready var ui_player: AudioStreamPlayer = $UiPlayer

func _ready() -> void:
	randomize()

# Plays the sound effect associated with the given string on the UI AudioStreamPlayer.
func play_ui_sound(ui_sfx: String) -> void:
	_play_sound(ui_player, ui_sfx)

# Plays the music track associated with the given string on the music AudioStreamPlayer.
func play_music(music: AudioStreamMP3, force_replay: bool = false) -> void:
	if not force_replay and music_player.playing and music_player.stream == music:
		return
	music_player.volume_db = volume
	music_player.stream = music
	music_player.play()

# Sets the volume for evert AudioStreamPlayer.
func set_volume(volume_value: int) -> void:
	volume_setting_value = volume_value
	volume = (volume_value - MAX_VOLUME) * 4
	if volume_value == MIN_VOLUME:
		volume = MUTE_VOLUME
	music_player.volume_db = volume
	ui_player.volume_db = volume


func _play_sound(player: AudioStreamPlayer, sfx: String) -> void:
	player.pitch_scale = \
		rand_range(PITCH_RANDOMIZER[sfx][0], PITCH_RANDOMIZER[sfx][1])
	player.volume_db = volume + VOLUME_FIXER[sfx]
	player.stream = SFX[sfx]
	player.play()

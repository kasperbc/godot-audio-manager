extends Node

@export var num_sfx_players := 5 #more players means more sounds can play at once
@export var fading_music_starting_db = -20.0 # what db the song starts at when fading into it
@export var music : Array[Resource]
@export var effects : Array[Resource]

@onready var effects_container = $Effects
@onready var audio_stream_player = $Music/AudioStreamPlayer
@onready var audio_stream_player_2 = $Music/AudioStreamPlayer2

var paused_position : float = 0.0 #the position music has been paused at

var fading_music : bool = false
var fade_time : float = 0.0
var current_fade_time : float = 0.0

func _ready() -> void:
	for i in num_sfx_players:
		var stream = AudioStreamPlayer.new()
		effects_container.add_child(stream)

func _process(delta):
	if fading_music:
		_fade_music(delta)

func play_fx(play_sfx_name : String) -> void:
	var sound = _get_sound(play_sfx_name, false)
	if not sound: return
	
	var player = effects_container.get_child(0)
	player.stream = sound
	player.play()
	effects_container.move_child(player, num_sfx_players - 1)

func play_music(play_song_name : String) -> void:
	var song = _get_sound(play_song_name, true)
	if not song: return
	
	if audio_stream_player.stream != song or paused_position > 0.0 or !audio_stream_player.playing:
		audio_stream_player.stream = song
		audio_stream_player.play(paused_position)
		paused_position = 0.0

func stop_music() -> void:
	paused_position = 0.0
	audio_stream_player.stop()
	audio_stream_player_2.stop()

func pause_music() -> void:
	paused_position = audio_stream_player.get_playback_position()
	audio_stream_player.stop()

func fade_to_music(song_name, time) -> void:
	var song = _get_sound(song_name, true)
	if not song or fading_music: return
	
	audio_stream_player_2.stream = song
	audio_stream_player_2.volume_db = fading_music_starting_db
	audio_stream_player_2.play()
	
	fade_time = time
	current_fade_time = 0.0
	fading_music = true

func _fade_music(delta):
	current_fade_time += delta
	var time_10 = 1 - (current_fade_time / fade_time)
	var time_01 = current_fade_time / fade_time
	
	audio_stream_player_2.volume_db = time_10 * fading_music_starting_db
	audio_stream_player.volume_db = time_01 * fading_music_starting_db

	if time_10 <= 0:
		fading_music = false
		audio_stream_player.stop()
		audio_stream_player.stream = audio_stream_player_2.stream
		audio_stream_player.volume_db = 0.0
		audio_stream_player.play(audio_stream_player_2.get_playback_position())
		audio_stream_player_2.stop()

func _get_sound(sound_name, is_music : bool) -> Resource:
	for i in music.size():
		var sound = music[i] if is_music else effects[i]
		if sound.resource_path.get_file().get_basename() == sound_name:
			return sound
	
	return null

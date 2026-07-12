extends Node
## AudioManager singleton: pool of 8 AudioStreamPlayers over synthesized WAV SFX.

const SFX_DIR := "res://assets/sfx/"
const SFX_NAMES: Array[StringName] = [
	&"shoot", &"hurt", &"enemy_death", &"door", &"pickup", &"item", &"roar",
]
const POOL_SIZE := 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for sfx_name in SFX_NAMES:
		var path := SFX_DIR + sfx_name + ".wav"
		if ResourceLoader.exists(path):
			_streams[sfx_name] = load(path)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		_players.append(p)


func play_sfx(sfx_name: StringName) -> void:
	if not _streams.has(sfx_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sfx_name]
			p.play()
			return
	_players[0].stream = _streams[sfx_name]
	_players[0].play()


func play_music(_name: StringName) -> void:
	pass  # no music in the slice (M5+)

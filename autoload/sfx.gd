extends Node
## Sound effects, music and read-aloud speech.

const SOUNDS := {
	"click": "click_001", "pop": "drop_001", "good": "confirmation_001", "great": "confirmation_003",
	"soft": "pluck_001", "soft2": "pluck_002", "oops": "error_004", "tick": "tick_001",
	"open": "open_001", "close": "close_001", "chime": "glass_001", "bong": "bong_001",
	"thud": "impactSoft_medium_000", "wood": "impactWood_medium_000", "bell": "impactBell_heavy_000",
	"step": "footstep_grass_000", "select": "select_001", "question": "question_001",
	"up": "maximize_006", "down": "minimize_006", "switch": "switch_002", "plank": "impactPlank_medium_000",
}
const MUSIC := {
	"main": "farm_frolics", "calm": "night_at_the_beach", "play": "wacky_waiting",
	"title": "flowing_rocks", "story": "mishief_stroll",
}

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _current_music := ""
var _streams := {}
var _voice := ""
var _tts_ok := false


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)
	_tts_ok = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH) and DisplayServer.get_name() != "headless"
	if _tts_ok:
		var voices := DisplayServer.tts_get_voices_for_language("en")
		if not voices.is_empty():
			_voice = voices[0]
			for v in DisplayServer.tts_get_voices():
				if str(v.get("name", "")).begins_with("Samantha") and str(v.get("language", "")).begins_with("en"):
					_voice = v.id
		else:
			_tts_ok = false


func _stream(path: String) -> AudioStream:
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


func play(sound: String, pitch := 1.0) -> void:
	var vol: float = Game.settings.sfx
	if vol <= 0.01 or not SOUNDS.has(sound):
		return
	var s := _stream("res://assets/audio/sfx/%s.ogg" % SOUNDS[sound])
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(vol)
	p.play()


func jingle(n := 0) -> void:
	var names := ["jingle_00", "jingle_03", "jingle_07", "jingle_10", "jingle_12"]
	var s := _stream("res://assets/audio/jingles/%s.ogg" % names[n % names.size()])
	if s == null or Game.settings.sfx <= 0.01:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.pitch_scale = 1.0
	p.volume_db = linear_to_db(Game.settings.sfx * 0.8)
	p.play()


func music(track: String) -> void:
	if track == _current_music:
		return
	_current_music = track
	var s := _stream("res://assets/audio/music/%s.ogg" % MUSIC.get(track, track))
	if s is AudioStreamOggVorbis:
		s.loop = true
	var old := _music_a
	_music_a = _music_b
	_music_b = old
	var tw := create_tween().set_parallel()
	tw.tween_property(old, "volume_db", -50.0, 1.0)
	_music_a.stream = s
	_music_a.volume_db = -50.0
	if s:
		_music_a.play()
		tw.tween_property(_music_a, "volume_db", _music_db(), 1.0)
	tw.chain().tween_callback(old.stop)


func _music_db() -> float:
	return linear_to_db(maxf(Game.settings.music * 0.45, 0.0001))


func refresh_volume() -> void:
	_music_a.volume_db = _music_db()


## Read text aloud (if switched on). New speech replaces old speech.
func say(text: String) -> void:
	if not _tts_ok or not Game.settings.read_aloud or text.strip_edges() == "":
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _voice, 80, 1.05, 0.9)


func hush() -> void:
	if _tts_ok:
		DisplayServer.tts_stop()

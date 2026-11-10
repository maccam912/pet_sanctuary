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
var _speech := 0            # goes up with every say() / hush(), so old speech stops
var _tts_done := true
var _line_player: AudioStreamPlayer    # the child's recorded voice lines
var _animal_player: AudioStreamPlayer  # the child's recorded animal sounds
var _mic: AudioStreamPlayer
var _recorder: AudioEffectRecord
var _record_bus := -1
## The end-to-end test switches this off so it never touches the real
## microphone (the system's permission question would stop it).
var use_mic := true


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	add_child(_music_a)
	add_child(_music_b)
	_line_player = AudioStreamPlayer.new()
	_animal_player = AudioStreamPlayer.new()
	add_child(_line_player)
	add_child(_animal_player)
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
	if _tts_ok:
		for event in [DisplayServer.TTS_UTTERANCE_ENDED, DisplayServer.TTS_UTTERANCE_CANCELED]:
			DisplayServer.tts_set_utterance_callback(event, _on_tts_end)


func _on_tts_end(id: int) -> void:
	if id == _speech:
		_tts_done = true


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


## Read text aloud (if switched on). New speech replaces old speech. Any line
## the child has recorded in the booth is played in their voice instead.
func say(text: String) -> void:
	if text.strip_edges() == "":
		return
	var parts := Game.voice.plan(text)
	if not Game.settings.read_aloud:
		return
	hush()
	var recorded := parts.any(func(p): return p.stream != null)
	if not recorded and not _animal_player.playing:
		if _tts_ok:
			DisplayServer.tts_speak(text, _voice, 80, 1.05, 0.9)
		return
	_speak_parts(parts, _speech)


## Plays a mix of recorded lines and read-aloud speech one after the other,
## waiting for an animal sound to finish first.
func _speak_parts(parts: Array, ticket: int) -> void:
	while _animal_player.playing:
		await get_tree().process_frame
		if ticket != _speech:
			return
	for part in parts:
		if part.stream != null:
			_line_player.stream = part.stream
			_line_player.volume_db = 0.0
			_line_player.play()
			while _line_player.playing:
				await get_tree().process_frame
				if ticket != _speech:
					return
		elif _tts_ok:
			_tts_done = false
			DisplayServer.tts_speak(part.text, _voice, 80, 1.05, 0.9, ticket)
			var patience: float = 3.0 + part.text.length() * 0.12
			while not _tts_done and patience > 0.0:
				await get_tree().process_frame
				patience -= get_process_delta_time()
				if ticket != _speech:
					return


## The read-aloud voice says this, even if the child has recorded the line
## (the booth's "hear it first" button).
func read(text: String) -> void:
	hush()
	if _tts_ok:
		DisplayServer.tts_speak(text, _voice, 80, 1.05, 0.9)


func hush() -> void:
	_speech += 1
	_line_player.stop()
	if _tts_ok:
		DisplayServer.tts_stop()


## Plays the child's recorded sound for this animal and feeling. Returns false
## (and plays nothing) when there is no recording yet.
func animal(species: String, emotion := "happy") -> bool:
	var s := Game.voice.animal_stream(species, emotion)
	if s == null or Game.settings.sfx <= 0.01:
		return false
	_animal_player.stream = s
	_animal_player.volume_db = linear_to_db(Game.settings.sfx)
	_animal_player.play()
	return true


## Plays any recording once (the booth's "play it back" button).
func playback(stream: AudioStream) -> void:
	hush()
	_animal_player.stream = stream
	_animal_player.volume_db = 0.0
	_animal_player.play()


# ------------------------------------------------------- recording ----

## Switches the microphone on (only while the recording booth is open).
func mic_open() -> void:
	if not use_mic:
		return
	if _record_bus < 0:
		# Microphone -> "Record" bus (captures it) -> silent bus, so it is never
		# played back out of the speaker while recording.
		AudioServer.add_bus()
		var silent := AudioServer.bus_count - 1
		AudioServer.set_bus_name(silent, "Silent")
		AudioServer.set_bus_mute(silent, true)
		AudioServer.add_bus()
		_record_bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(_record_bus, "Record")
		AudioServer.set_bus_send(_record_bus, "Silent")
		_recorder = AudioEffectRecord.new()
		_recorder.format = AudioStreamWAV.FORMAT_16_BITS
		AudioServer.add_bus_effect(_record_bus, _recorder)
		_mic = AudioStreamPlayer.new()
		_mic.stream = AudioStreamMicrophone.new()
		_mic.bus = "Record"
		add_child(_mic)
	if OS.get_name() == "Android":
		OS.request_permission("android.permission.RECORD_AUDIO")
	_mic.play()


func mic_close() -> void:
	if _mic:
		_recorder.set_recording_active(false)
		_mic.stop()


func record_start() -> void:
	hush()
	_animal_player.stop()
	if _mic == null:
		return
	if not _mic.playing:
		_mic.play()
	_recorder.set_recording_active(true)


## Stops recording and returns the tidied take (null if nothing was heard).
func record_stop() -> AudioStreamWAV:
	if _recorder == null or not _recorder.is_recording_active():
		return null
	var take := _recorder.get_recording()
	_recorder.set_recording_active(false)
	return VoiceStore.clean(take)


## How loud the microphone is right now, 0..1 (for the booth's level lights).
func mic_level() -> float:
	if _record_bus < 0:
		return 0.0
	var db := maxf(AudioServer.get_bus_peak_volume_left_db(_record_bus, 0), AudioServer.get_bus_peak_volume_right_db(_record_bus, 0))
	return clampf((db + 50.0) / 45.0, 0.0, 1.0)

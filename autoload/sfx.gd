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
var _voice := ""            # the default read-aloud voice
var _readers: Array = []    # read-aloud voices a child can pick from (ids)
var _tts_ok := false
var _speech := 0            # goes up with every say() / hush(), so old speech stops
var _tts_done := true
var _line_player: AudioStreamPlayer    # the child's recorded voice lines
var _animal_player: AudioStreamPlayer  # the child's recorded animal sounds
var _mic_on := false
var _mic_frames := 0        # frames heard since the microphone was switched on
var _recording := false
var _take := PackedFloat32Array()
var _level := 0.0
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
			_find_readers()
		else:
			_tts_ok = false
	if _tts_ok:
		for event in [DisplayServer.TTS_UTTERANCE_ENDED, DisplayServer.TTS_UTTERANCE_CANCELED]:
			DisplayServer.tts_set_utterance_callback(event, _on_tts_end)


## Up to six English voices, the default first, then ones with the same accent.
## Voices that need the internet are left out.
func _find_readers() -> void:
	var all := DisplayServer.tts_get_voices().filter(func(v):
		return str(v.get("language", "")).begins_with("en") and not str(v.id).contains("network"))
	var lang := ""
	for v in all:
		if v.id == _voice:
			lang = v.language
	var ordered := []
	for rank in 3:
		for v in all:
			if rank == (0 if v.id == _voice else (1 if v.language == lang else 2)):
				ordered.append(v)
	var names := {}
	for v in ordered:
		var key := str(v.get("name", v.id)) + str(v.language)
		if names.has(key) or _readers.size() >= 6:
			continue
		names[key] = true
		_readers.append(v.id)


## The read-aloud voices a child can choose from ([] when there is no choice).
func reader_voices() -> Array:
	return _readers if _readers.size() > 1 else []


## The playing child's read-aloud voice.
func _reader() -> String:
	if Game.state != null and Game.state.voice.reader in _readers:
		return Game.state.voice.reader
	return _voice


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
	var parts := Game.voice.plan(text, Game.listen) if Game.voice else [{"text": text, "stream": null}]
	if not Game.settings.read_aloud:
		return
	hush()
	var recorded := parts.any(func(p): return p.stream != null)
	if not recorded and not _animal_player.playing:
		if _tts_ok:
			DisplayServer.tts_speak(text, _reader(), 80, 1.05, 0.9)
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
			DisplayServer.tts_speak(part.text, _reader(), 80, 1.05, 0.9, ticket)
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
		DisplayServer.tts_speak(text, _reader(), 80, 1.05, 0.9)


func hush() -> void:
	_speech += 1
	_line_player.stop()
	if _tts_ok:
		DisplayServer.tts_stop()


## Plays the child's recorded sound for this animal and feeling. Returns false
## (and plays nothing) when there is no recording yet.
func animal(species: String, emotion := "happy") -> bool:
	var s := Game.listen.animal_stream(species, emotion) if Game.listen else null
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
# The microphone is read straight from the audio server's input buffer. Going
# through an AudioStreamMicrophone player and a record bus instead lets the
# player's read position drift into old buffer data, which made some takes
# stutter.

## Switches the microphone on (only while the recording booth is open).
func mic_open() -> void:
	if not use_mic:
		return
	if OS.get_name() == "Android":
		OS.request_permission("android.permission.RECORD_AUDIO")
	_mic_start()


func _mic_start() -> void:
	# Off first: a start that failed (no permission yet) still counts as on.
	AudioServer.set_input_device_active(false)
	_mic_on = AudioServer.set_input_device_active(true) == OK
	_mic_frames = 0


func mic_close() -> void:
	_recording = false
	_level = 0.0
	if _mic_on:
		AudioServer.set_input_device_active(false)
		_mic_on = false


func _process(_delta: float) -> void:
	if _mic_on:
		_pull_mic()


## Takes everything the microphone has heard since last time: kept while
## recording, otherwise only used for the level lights.
func _pull_mic() -> void:
	var n := mini(AudioServer.get_input_frames_available(), AudioServer.get_input_buffer_length_frames())
	if n <= 0:
		return
	var frames := AudioServer.get_input_frames(n)
	_mic_frames += frames.size()
	var peak := 0.0
	var at := _take.size()
	if _recording:
		_take.resize(at + frames.size())
	for i in frames.size():
		var v := (frames[i].x + frames[i].y) * 0.5
		peak = maxf(peak, absf(v))
		if _recording:
			_take[at + i] = v
	_level = clampf((linear_to_db(maxf(peak, 0.00001)) + 50.0) / 45.0, 0.0, 1.0)


func record_start() -> void:
	hush()
	_animal_player.stop()
	if not use_mic:
		return
	if not _mic_on or _mic_frames == 0:
		_mic_start()  # maybe the microphone permission has been granted since
	if _mic_on:
		_pull_mic()  # throw away what was heard before Record was tapped
	_take = PackedFloat32Array()
	_recording = true


## Stops recording and returns the tidied take (null if nothing was heard).
func record_stop() -> AudioStreamWAV:
	if not _recording:
		return null
	if _mic_on:
		_pull_mic()
	_recording = false
	var take := _take
	_take = PackedFloat32Array()
	return VoiceStore.clean_samples(take, AudioServer.get_input_mix_rate())


## How loud the microphone is right now, 0..1 (for the booth's level lights).
func mic_level() -> float:
	return _level

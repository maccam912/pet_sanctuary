class_name RecorderBar
extends VBoxContainer
## Record / Play / Erase buttons for one recording in the VoiceStore, with a
## little microphone level bar. Used for animal sounds and voice lines.

signal changed  # a take was saved or erased

var file := ""            # VoiceStore file name this bar records into
var max_seconds := 5.0
var recording := false

var _time := 0.0
var _erase_armed := false
var _record: Button
var _play: Button
var _erase: Button
var _meter: ProgressBar
var _status: Label


func _init() -> void:
	add_theme_constant_override("separation", 8)
	var row := UI.hbox(12)
	_record = UI.button("Record", UI.CORAL, 28)
	_record.custom_minimum_size = Vector2(210, 88)
	_record.pressed.connect(_toggle)
	row.add_child(_record)
	_play = UI.button("Play", UI.LEAF, 28)
	_play.custom_minimum_size = Vector2(150, 88)
	_play.pressed.connect(play)
	row.add_child(_play)
	_erase = UI.button("Erase", UI.PAPER, 22)
	_erase.custom_minimum_size = Vector2(130, 88)
	_erase.pressed.connect(_on_erase)
	row.add_child(_erase)
	add_child(row)
	_meter = ProgressBar.new()
	_meter.show_percentage = false
	_meter.max_value = 1.0
	_meter.custom_minimum_size = Vector2(420, 22)
	_meter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_meter.add_theme_stylebox_override("fill", UI._bar(UI.CORAL))
	add_child(_meter)
	_status = UI.label("", 22, UI.INK_SOFT)
	add_child(_status)


## Point the bar at a recording (stops anything in progress).
func target(file_name: String, seconds: float) -> void:
	if recording:
		Sfx.record_stop()
		recording = false
	file = file_name
	max_seconds = seconds
	_erase_armed = false
	_refresh()
	_status.text = "Tap Record, then make your sound!" if not Game.voice.has(file) else "Tap Play to hear yours."


func _refresh() -> void:
	var have := Game.voice.has(file)
	_record.text = "Stop" if recording else ("Record again" if have else "Record")
	_record.add_theme_font_size_override("font_size", 24 if _record.text.length() > 8 else 28)
	_play.disabled = recording or not have
	_erase.disabled = recording or not have
	_erase.text = "Really?" if _erase_armed else "Erase"
	_meter.modulate.a = 1.0 if recording else 0.25


func _process(delta: float) -> void:
	if not recording:
		_meter.value = 0.0
		return
	_time += delta
	_meter.value = lerpf(_meter.value, Sfx.mic_level(), minf(1.0, delta * 14.0))
	_record.scale = Vector2.ONE * (1.0 + sin(_time * 7.0) * 0.03)
	if _time >= max_seconds:
		_toggle()


func _toggle() -> void:
	if file == "":
		return
	_erase_armed = false
	if not recording:
		recording = true
		_time = 0.0
		_record.pivot_offset = _record.size / 2.0
		Sfx.record_start()
		_status.text = "Recording... tap Stop when you are done."
		_refresh()
		return
	recording = false
	_record.scale = Vector2.ONE
	finish_take(Sfx.record_stop())


## Saves a finished take and plays it back (null = nothing was heard).
func finish_take(take: AudioStreamWAV) -> void:
	if take == null or not Game.voice.save(file, take):
		_status.text = "I could not hear that. Try again, a bit louder!"
		Sfx.play("soft")
	else:
		_status.text = "Got it! Here is how it sounds."
		Sfx.playback(take)
		changed.emit()
	_refresh()


func play() -> void:
	var s := Game.voice.stream(file)
	if s:
		Sfx.playback(s)


func _on_erase() -> void:
	if not _erase_armed:
		_erase_armed = true
		_refresh()
		return
	_erase_armed = false
	Game.voice.erase(file)
	_status.text = "Erased."
	changed.emit()
	_refresh()

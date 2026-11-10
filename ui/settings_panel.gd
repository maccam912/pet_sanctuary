class_name SettingsPanel
extends Control
## Kid-safe settings: sound, music, read-aloud and (in a game) whose voice to
## hear. Grown-up options sit behind the gate.

signal closed
signal quit_to_title

var in_game := false


func _init(game_running := false) -> void:
	in_game = game_running


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	var v := UI.vbox(18)
	v.add_child(UI.label("Settings", 40))
	v.add_child(_slider_row("Music", "music"))
	v.add_child(_slider_row("Sounds", "sfx"))
	var read_row := UI.hbox()
	var read_label := UI.label("Read out loud", 30, UI.INK, false)
	read_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_row.add_child(read_label)
	var toggle := UI.button("", UI.LEAF)
	toggle.custom_minimum_size = Vector2(150, 70)
	var refresh := func():
		toggle.text = "On" if Game.settings.read_aloud else "Off"
		UI.recolor(toggle, UI.LEAF if Game.settings.read_aloud else UI.PAPER)
	refresh.call()
	toggle.pressed.connect(func():
		Game.settings.read_aloud = not Game.settings.read_aloud
		Game.save_settings()
		refresh.call()
		if Game.settings.read_aloud:
			Sfx.say("I will read out loud.")
		else:
			Sfx.hush())
	read_row.add_child(toggle)
	v.add_child(read_row)
	if in_game:
		var others := Game.other_voices()
		if not others.is_empty():
			v.add_child(_voice_row(others))
		if not Sfx.reader_voices().is_empty():
			v.add_child(_reader_row())
	var row := UI.hbox()
	var adult := UI.button("Grown-ups", UI.LAVENDER, 26)
	adult.custom_minimum_size = Vector2(230, 76)
	adult.pressed.connect(func():
		AdultGateDialog.ask(self, func():
			var menu := AdultMenu.new()
			add_child(menu)))
	row.add_child(adult)
	if in_game:
		var home := UI.button("Save and go home", UI.SKY, 26)
		home.custom_minimum_size = Vector2(280, 76)
		home.pressed.connect(func(): quit_to_title.emit())
		row.add_child(home)
	v.add_child(row)
	var done := UI.button("Done", UI.LEAF)
	done.pressed.connect(func(): closed.emit(); queue_free())
	v.add_child(done)
	add_child(UI.centered(v, Vector2(640, 0)))


## Whose recordings the game plays: this child's own, or a brother's or sister's.
func _voice_row(others: Array) -> Control:
	var choices := [{"id": "", "name": "Mine"}] + others
	return _pick_row("Whose voice?", choices.map(func(c): return c.name), 130,
		func(): return choices.map(func(c): return c.id).find(Game.state.voice.from),
		func(i: int):
			Game.state.voice.from = choices[i].id
			Game.open_voices()
			var sample := Game.listen.sample()
			if sample:
				Sfx.playback(sample))


## The computer voice that reads every line nobody has recorded.
func _reader_row() -> Control:
	var ids := Sfx.reader_voices()
	return _pick_row("Reading voice", range(1, ids.size() + 1).map(func(n): return str(n)), 62,
		func(): return maxi(0, ids.find(Game.state.voice.reader)),
		func(i: int):
			Game.state.voice.reader = ids[i]
			Sfx.read("Hi! I can read to you in this voice."))


## A label and a row of buttons where the current choice is lit.
func _pick_row(text: String, names: Array, width: float, current: Callable, pick: Callable) -> Control:
	var row := UI.hbox(8)
	var l := UI.label(text, 30, UI.INK, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var buttons: Array[Button] = []
	for i in names.size():
		var b := UI.button(names[i], UI.PAPER, 24)
		b.custom_minimum_size = Vector2(width, 64)
		row.add_child(b)
		buttons.append(b)
	var paint := func():
		for i in buttons.size():
			UI.recolor(buttons[i], UI.SUN if i == current.call() else UI.PAPER)
	for i in buttons.size():
		buttons[i].pressed.connect(func():
			pick.call(i)
			paint.call())
	paint.call()
	return row


func _slider_row(text: String, key: String) -> Control:
	var row := UI.hbox()
	var l := UI.label(text, 30, UI.INK, false)
	l.custom_minimum_size = Vector2(170, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = Game.settings[key]
	s.custom_minimum_size = Vector2(340, 60)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(val: float):
		Game.settings[key] = val
		Sfx.refresh_volume()
		if key == "sfx":
			Sfx.play("soft"))
	s.drag_ended.connect(func(_c): Game.save_settings())
	row.add_child(s)
	return row

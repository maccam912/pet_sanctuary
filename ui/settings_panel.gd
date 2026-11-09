class_name SettingsPanel
extends Control
## Kid-safe settings: sound, music, read-aloud. Grown-up options sit behind the gate.

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

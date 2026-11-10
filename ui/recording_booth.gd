class_name RecordingBooth
extends Control
## The recording booth: the child gives the game its voice. One side records an
## animal sound for each animal and feeling; the other records the game's
## lines, which are then played instead of the read-aloud voice.

signal closed

const SOUND_FEELINGS := ["happy", "calm", "mad", "frustrated", "worried", "sad", "disappointed", "jealous", "embarrassed"]

var bar: RecorderBar
var lines: Array = []       # [{text, recorded}] from VoiceStore.booth_lines
var line_index := 0
var species := ""
var feeling := "happy"

var _tab := ""
var _tab_buttons := {}
var _body: Control
var _animal_list: VBoxContainer
var _animal_buttons := {}
var _animal_side: VBoxContainer
var _feeling_buttons := {}
var _line_text: Label
var _line_count: Label
var _line_star: Doodle


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop(Color("e9e0f7")))
	var m := MarginContainer.new()
	UI.full(m)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 22)
	add_child(m)
	var panel := UI.panel()
	m.add_child(panel)
	var v := UI.vbox(10)
	panel.add_child(v)
	var head := UI.hbox(10)
	var title := UI.label("Recording Booth", 34, UI.INK, false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	for tab in ["Animal Sounds", "Voice Lines"]:
		var b := UI.button(tab, UI.PAPER, 24)
		b.custom_minimum_size = Vector2(220, 64)
		b.pressed.connect(show_tab.bind(tab))
		head.add_child(b)
		_tab_buttons[tab] = b
	var done := UI.button("Done", UI.LEAF, 24)
	done.custom_minimum_size = Vector2(140, 64)
	done.pressed.connect(close)
	head.add_child(done)
	v.add_child(head)
	_body = Control.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_body)
	bar = RecorderBar.new()
	bar.changed.connect(_on_changed)
	Sfx.music("")
	Sfx.mic_open()
	UI.fade_in(self)
	show_tab("Animal Sounds")


func close() -> void:
	Sfx.hush()
	Sfx.mic_close()
	Game.voice.save_heard()
	closed.emit()
	queue_free()


func show_tab(tab: String) -> void:
	_tab = tab
	for t in _tab_buttons:
		UI.recolor(_tab_buttons[t], UI.SUN if t == tab else UI.PAPER)
	if bar.get_parent():
		bar.get_parent().remove_child(bar)
	for c in _body.get_children():
		c.queue_free()
	if tab == "Animal Sounds":
		_build_animals()
	else:
		_build_lines()


# ---------------------------------------------------- animal sounds ----

func _build_animals() -> void:
	var row := UI.hbox(16)
	UI.full(row)
	_body.add_child(row)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(250, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_animal_list = UI.vbox(8)
	_animal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_animal_list)
	row.add_child(scroll)
	_animal_buttons.clear()
	var first := ""
	for pet in Game.state.pets:
		var sp: String = pet.species
		if _animal_buttons.has(sp):
			continue
		if first == "":
			first = sp
		var b := UI.button("", UI.PAPER, 24)
		b.custom_minimum_size = Vector2(230, 92)
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var icon := UI.pet_icon(sp, 72)
		icon.position = Vector2(12, 4)
		icon.size = Vector2(72, 72)
		b.add_child(icon)
		b.pressed.connect(pick_animal.bind(sp))
		_animal_list.add_child(b)
		_animal_buttons[sp] = b
	_animal_side = UI.vbox(10)
	_animal_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_animal_side.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_animal_side)
	pick_animal(species if _animal_buttons.has(species) else first)


func pick_animal(sp: String) -> void:
	species = sp
	for s in _animal_buttons:
		UI.recolor(_animal_buttons[s], UI.SUN if s == sp else UI.PAPER)
		_animal_buttons[s].text = "%d of %d  " % [Game.voice.animal_count(s), SOUND_FEELINGS.size()]
	if bar.get_parent():
		bar.get_parent().remove_child(bar)
	for c in _animal_side.get_children():
		c.queue_free()
	var top := UI.hbox(14)
	top.add_child(PetStage.new(sp, 190))
	var ask := UI.text("What does this animal sound like when it feels...", 28, UI.INK, false)
	ask.custom_minimum_size = Vector2(420, 0)
	top.add_child(ask)
	_animal_side.add_child(top)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_feeling_buttons.clear()
	for e in SOUND_FEELINGS:
		var b := UI.button("", UI.PAPER)
		b.custom_minimum_size = Vector2(158, 118)
		var inner := UI.vbox(0)
		UI.full(inner)
		inner.offset_bottom = -8
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := Face.new(e, 58)
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(face)
		inner.add_child(UI.label(Content.EMOTIONS[e].label, 19))
		b.add_child(inner)
		var check := Doodle.new()
		check.kind = "check"
		check.position = Vector2(118, 6)
		check.size = Vector2(32, 32)
		b.add_child(check)
		b.set_meta("check", check)
		b.pressed.connect(pick_feeling.bind(e))
		grid.add_child(b)
		_feeling_buttons[e] = b
	_animal_side.add_child(grid)
	_animal_side.add_child(bar)
	pick_feeling(feeling)


func pick_feeling(e: String) -> void:
	feeling = e
	_refresh_feelings()
	bar.target(VoiceStore.animal_file(species, e), 4.0)


func _refresh_feelings() -> void:
	for e in _feeling_buttons:
		var b: Button = _feeling_buttons[e]
		UI.recolor(b, Content.EMOTIONS[e].color.lightened(0.3) if e == feeling else UI.PAPER)
		(b.get_meta("check") as Doodle).visible = Game.voice.has(VoiceStore.animal_file(species, e))
	if _animal_buttons.has(species):
		_animal_buttons[species].text = "%d of %d  " % [Game.voice.animal_count(species), SOUND_FEELINGS.size()]


# ------------------------------------------------------ voice lines ----

func _build_lines() -> void:
	var names := Game.state.pets.map(func(p): return p.name)
	lines = Game.voice.booth_lines(Content.voice_script(), names)
	line_index = 0
	for i in lines.size():
		if not lines[i].recorded:
			line_index = i
			break
	var v := UI.vbox(12)
	UI.full(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(v)
	_line_count = UI.label("", 22, UI.INK_SOFT)
	v.add_child(_line_count)
	var row := UI.hbox(14)
	var prev := UI.icon_button("back", UI.PAPER, 84)
	prev.pressed.connect(step_line.bind(-1))
	row.add_child(prev)
	var card := UI.panel(UI.PAPER, 30)
	card.custom_minimum_size = Vector2(820, 230)
	var inner := UI.hbox(10)
	_line_star = Doodle.new()
	_line_star.kind = "star"
	_line_star.custom_minimum_size = Vector2(54, 54)
	_line_star.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	inner.add_child(_line_star)
	_line_text = UI.text("", 36)
	_line_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_line_text)
	card.add_child(inner)
	row.add_child(card)
	var next := UI.icon_button("back", UI.PAPER, 84)
	next.get_child(0).scale.x = -1.0
	next.get_child(0).pivot_offset = Vector2(84 * 0.3, 0)
	next.pressed.connect(step_line.bind(1))
	row.add_child(next)
	v.add_child(row)
	var hear := UI.button("Hear it first", UI.SKY, 24)
	hear.custom_minimum_size = Vector2(260, 70)
	hear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hear.pressed.connect(func():
		if not lines.is_empty():
			Sfx.read(lines[line_index].text))
	v.add_child(hear)
	v.add_child(bar)
	v.add_child(UI.label("Say the words like a voice actor! The game will use your voice.", 20, UI.INK_SOFT))
	_show_line()


func step_line(by: int) -> void:
	if lines.is_empty():
		return
	line_index = posmod(line_index + by, lines.size())
	_show_line()


func _show_line() -> void:
	if lines.is_empty():
		return
	var line: Dictionary = lines[line_index]
	_line_text.text = line.text
	_line_text.add_theme_font_size_override("font_size", 36 if line.text.length() < 90 else 28)
	_line_star.tint = Color.TRANSPARENT if line.recorded else Color(0.84, 0.82, 0.78)
	var recorded := lines.filter(func(l): return l.recorded).size()
	_line_count.text = "Line %d of %d      You have recorded %d" % [line_index + 1, lines.size(), recorded]
	bar.target(VoiceStore.line_file(line.text), 14.0)


func _on_changed() -> void:
	if _tab == "Animal Sounds":
		_refresh_feelings()
	elif not lines.is_empty():
		lines[line_index].recorded = Game.voice.has_line(lines[line_index].text)
		var recorded := lines.filter(func(l): return l.recorded).size()
		_line_star.tint = Color.TRANSPARENT if lines[line_index].recorded else Color(0.84, 0.82, 0.78)
		_line_count.text = "Line %d of %d      You have recorded %d" % [line_index + 1, lines.size(), recorded]

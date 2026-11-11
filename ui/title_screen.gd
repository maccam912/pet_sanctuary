class_name TitleScreen
extends Node3D
## Title screen over a live view of the sanctuary, plus the save-slot picker.
## Each save belongs to one child: a new save (or an old one with no name yet)
## asks for the child's name first.

signal play_slot(slot: int, is_new: bool, child_name: String)

var _root: Control
var _card: Control
var _title_card: Control
var _cam: Camera3D
var _t := 0.0


func _ready() -> void:
	var world := WorldBuilder.new()
	add_child(world)
	var species := Content.SPECIES.keys()
	species.shuffle()
	for i in 7:
		var pet := Pet.new()
		add_child(pet)
		pet.setup({"species": species[i], "name": "", "friendship": 0}, i, world)
		pet.position = world.random_walkable(Game.rng)
	_cam = Camera3D.new()
	_cam.fov = 38.0
	add_child(_cam)
	_cam.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_root = UI.full(Control.new())
	_root.theme = UI.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_root)
	Sfx.music("title")
	Updates.found.connect(_on_update_found)
	_show_title_card()


func _process(delta: float) -> void:
	_t += delta * 0.05
	var center := Vector3(0, 0, 1)
	_cam.position = center + Vector3(sin(_t) * 24.0, 13.0, cos(_t) * 24.0)
	_cam.look_at(center + Vector3(0, 1.0, 0))


func _set_card(c: Control) -> void:
	if _card:
		_card.queue_free()
	_card = c
	_root.add_child(c)
	UI.fade_in(c)


func _show_title_card() -> void:
	var holder := UI.full(Control.new())
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := UI.vbox(10)
	var title := UI.label("Sunny Paws", 92, UI.INK)
	title.add_theme_color_override("font_outline_color", UI.CREAM)
	title.add_theme_constant_override("outline_size", 18)
	v.add_child(title)
	var sub := UI.label("Pet Sanctuary", 44, UI.CORAL.darkened(0.15))
	sub.add_theme_color_override("font_outline_color", UI.CREAM)
	sub.add_theme_constant_override("outline_size", 14)
	v.add_child(sub)
	v.add_child(UI.spacer(Vector2(0, 30)))
	var play := UI.button("Play", UI.LEAF, 48)
	play.custom_minimum_size = Vector2(360, 120)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_show_slots)
	v.add_child(play)
	var cc := CenterContainer.new()
	UI.full(cc)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(v)
	holder.add_child(cc)
	var gear := UI.icon_button("gear")
	gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gear.position = Vector2(-108, 24)
	gear.pressed.connect(_open_settings)
	holder.add_child(gear)
	var build := UpdateCheck.this_build()
	if build > 0:
		var ver := UI.label("Build %d" % build, 20, UI.INK_SOFT)
		ver.add_theme_color_override("font_outline_color", UI.CREAM)
		ver.add_theme_constant_override("outline_size", 6)
		ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		ver.grow_vertical = Control.GROW_DIRECTION_BEGIN
		ver.offset_left = -20
		ver.offset_right = -20
		ver.offset_top = -14
		ver.offset_bottom = -14
		holder.add_child(ver)
	_title_card = holder
	if not Updates.available.is_empty():
		_add_update_button(holder)
	_set_card(holder)
	UI.pop(play)


func _on_update_found(_info: Dictionary) -> void:
	if _card == _title_card:
		_add_update_button(_title_card)


## A newer build is on GitHub: a grown-up can install it from here.
func _add_update_button(holder: Control) -> void:
	var b := UI.button("New version!", UI.SUN, 26)
	b.custom_minimum_size = Vector2(230, 84)
	b.position = Vector2(24, 24)
	b.pressed.connect(func(): AdultGateDialog.ask(_root, func(): _root.add_child(UpdatePanel.new())))
	holder.add_child(b)
	UI.pop(b)


func _open_settings() -> void:
	var s := SettingsPanel.new(false)
	_root.add_child(s)


func _show_slots() -> void:
	var holder := UI.full(Control.new())
	var v := UI.vbox(18)
	v.add_child(UI.label("Pick your sanctuary", 40))
	var row := UI.hbox(20)
	for slot in range(1, SaveStore.SLOTS + 1):
		row.add_child(_slot_card(slot))
	v.add_child(row)
	var back := UI.button("Back", UI.PAPER, 26)
	back.custom_minimum_size = Vector2(200, 70)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_title_card)
	v.add_child(back)
	holder.add_child(UI.centered(v, Vector2(1040, 0)))
	_set_card(holder)


func _slot_card(slot: int) -> Control:
	var p := UI.panel(UI.PAPER, 28)
	p.custom_minimum_size = Vector2(310, 360)
	var v := UI.vbox(10)
	p.add_child(v)
	var st := Game.store.load_slot(slot)
	if st == null:
		v.add_child(UI.spacer())
		var paw := Doodle.new()
		paw.kind = "paw"
		paw.tint = UI.INK_SOFT.lightened(0.4)
		paw.custom_minimum_size = Vector2(110, 110)
		v.add_child(paw)
		v.add_child(UI.label("New sanctuary", 26, UI.INK_SOFT))
		v.add_child(UI.spacer())
		var start := UI.button("Start", UI.SUN, 32)
		start.pressed.connect(ask_name.bind(slot, true))
		v.add_child(start)
		return p
	if st.child_name != "":
		v.add_child(UI.label(st.child_name, 34, UI.CORAL.darkened(0.2)))
	var icons := UI.hbox(0)
	for i in mini(3, st.pets.size()):
		icons.add_child(UI.pet_picture(st.pets[st.pets.size() - 1 - i], 92))
	v.add_child(icons)
	v.add_child(UI.label("%d pets" % st.pets.size(), 30))
	var hearts := UI.hbox(8)
	var h := Doodle.new()
	h.kind = "heart"
	h.custom_minimum_size = Vector2(36, 36)
	hearts.add_child(h)
	hearts.add_child(UI.label(str(st.hearts), 30))
	v.add_child(hearts)
	v.add_child(UI.label("Played " + st.playtime_text(), 22, UI.INK_SOFT))
	v.add_child(UI.spacer())
	var play := UI.button("Play", UI.LEAF, 32)
	if st.child_name == "":
		play.pressed.connect(ask_name.bind(slot, false))
	else:
		play.pressed.connect(func(): play_slot.emit(slot, false, ""))
	v.add_child(play)
	return p


## Asks the child's name, then starts (or loads) the save.
func ask_name(slot: int, is_new: bool) -> void:
	var holder := UI.full(Control.new())
	var v := UI.vbox(18)
	var msg := "Hi! What is your name?"
	v.add_child(UI.label(msg, 40))
	var edit := LineEdit.new()
	edit.max_length = 12
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.add_theme_font_size_override("font_size", 40)
	edit.custom_minimum_size = Vector2(420, 84)
	edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(edit)
	var row := UI.hbox(14)
	var back := UI.button("Back", UI.PAPER, 24)
	back.custom_minimum_size = Vector2(160, 84)
	back.pressed.connect(_show_slots)
	row.add_child(back)
	var go := UI.button("Let's go!", UI.LEAF, 32)
	go.custom_minimum_size = Vector2(300, 84)
	go.disabled = true
	var start := func():
		var child_name := GameState.clean_name(edit.text, "")
		if child_name != "":
			play_slot.emit(slot, is_new, child_name)
	go.pressed.connect(start)
	edit.text_changed.connect(func(t: String): go.disabled = GameState.clean_name(t, "") == "")
	edit.text_submitted.connect(func(_t): start.call())
	row.add_child(go)
	v.add_child(row)
	holder.add_child(UI.centered(v, Vector2(640, 0)))
	_set_card(holder)
	edit.grab_focus.call_deferred()
	Sfx.say(msg)

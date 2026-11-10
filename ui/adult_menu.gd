class_name AdultMenu
extends Control
## The grown-ups area (always opened through AdultGateDialog).
## Guide, per-child skills and settings, progress, and save-file management.

signal closed

const GUIDE := """HOW THIS GAME TEACHES

Your child is the helper. The pets have big feelings, and your child teaches them what to do. Children put more effort into learning when they are teaching someone else (researchers call it the protégé effect), and it is easier to think about a pet's anger than your own.

Every feelings moment follows the steps child therapists teach in cognitive behavioral therapy (CBT):
1. Notice the feeling and name it.
2. Find it in the body (hot face, tight paws, fluttery tummy).
3. Rate how big it is on the feeling thermometer.
4. Calm the body FIRST. A flooded brain can't problem-solve.
5. Then swap the stormy thought for a helpful one, and solve the problem.

The calm-down tools are real, well-studied ones: slow breathing with a long out-breath, squeeze-and-release muscle relaxation, slow counting, the Turtle Technique (from the PATHS school program), a self-chosen calm-down break, sensory grounding, helpful self-talk, and slow stretching.

Left out on purpose: "letting it out" by hitting pillows, yelling or stomping. Studies keep finding that venting keeps anger going, while calming the body brings it down.

SKILL STAGES

Learning: the game walks through the tool step by step.
Practicing: your child chooses the tool and leads the pet.
Learned: the pet often asks for the tool by itself, and your child simply practices along. This is the goal: lots of repetitions.
Skills move up on their own, or set them by hand on the Skills tab.

PETS WHO WANT IT PERFECT

Some pets (the pet card says "Likes things just right") get stories about wobbly drawings, wrong answers and being too scared to try. Two mini-games practice the same idea: in Treasure Dig every wrong dig is a clue, and in Oops Art every paint splat turns into part of the picture. The message is the one therapists use for perfectionism: mistakes are how we learn, and "good enough" is good. You can help by cheerfully pointing out your own small mistakes: "Oops! I spilled. Oh well, I'll wipe it up."

YOUR CHILD'S VOICE

In the Recording Booth your child can record animal sounds for each pet and feeling, and record the game's lines in their own voice. The game then plays those instead of the computer voice. Saying the pets' helpful thoughts out loud ("I can't do it YET") is real practice of coping self-talk. Recordings never leave this device.

TRICKY MOMENTS

Knowing the right answer while calm is the easy part. Using it while upset is the hard part. So sometimes a mini-game goes wrong on purpose (the wind knocks the tower over, the cards get mixed up). The pet gets frustrated too, and they calm down together, with a little real frustration in the room. Choose how often on the Child Settings tab. Stay close the first few times, and turn it down if it is too much.

MAKING IT STICK IN REAL LIFE

- Borrow the game's words: "How big is your feeling, 1 to 5?" "Want to do Balloon Breaths like Biscuit?"
- Practice the tools together when everyone is calm. Children copy what they see you do.
- In a real meltdown: connect and calm the body first. Talk about it later.
- Notice the trying, not just the result: "You took a breath. That was hard to do."
- Expect it to take many, many repetitions. That is normal.

This game is practice, not treatment. If big feelings are getting in the way of school, friendships or family life, talk with your pediatrician or a child therapist."""

var _body: VBoxContainer
var _tabs := {}
var _tab_row: HBoxContainer


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop(Color(0.2, 0.13, 0.08, 0.75)))
	var m := MarginContainer.new()
	UI.full(m)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 28)
	add_child(m)
	var p := UI.panel()
	m.add_child(p)
	var v := UI.vbox(12)
	p.add_child(v)
	var head := UI.hbox()
	var title := UI.label("Grown-ups", 34, UI.INK, false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := UI.button("Close", UI.CORAL, 24)
	close.custom_minimum_size = Vector2(140, 60)
	close.pressed.connect(func():
		Game.save()
		Game.save_settings()
		closed.emit()
		queue_free())
	head.add_child(close)
	v.add_child(head)
	_tab_row = UI.hbox(8)
	_tab_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_child(_tab_row)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_body = UI.vbox(14)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_add_tab("Guide", _show_guide)
	if Game.state != null:
		_add_tab("Skills", _show_skills)
		_add_tab("Child Settings", _show_child_settings)
		_add_tab("Pets", _show_pets)
		_add_tab("Progress", _show_progress)
	_add_tab("Saves & PIN", _show_saves)
	_select("Guide" if Game.state == null else "Skills")


func _add_tab(tab_name: String, builder: Callable) -> void:
	var b := UI.button(tab_name, UI.PAPER, 22)
	b.custom_minimum_size = Vector2(0, 56)
	b.pressed.connect(_select.bind(tab_name))
	_tab_row.add_child(b)
	_tabs[tab_name] = {"button": b, "builder": builder}


func _select(tab_name: String) -> void:
	for n in _tabs:
		UI.recolor(_tabs[n].button, UI.SUN if n == tab_name else UI.PAPER)
	for c in _body.get_children():
		c.queue_free()
	_tabs[tab_name].builder.call()


func _text(text: String, size := 22, color := UI.INK) -> Label:
	var l := UI.text(text, size, color, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(l)
	return l


func _times(n: int) -> String:
	return "1 time" if n == 1 else "%d times" % n


func _show_guide() -> void:
	_text(GUIDE, 22)


## One row of choice buttons where exactly one is lit.
func _choice_row(options: Array, current: int, on_pick: Callable, width := 150) -> HBoxContainer:
	var row := UI.hbox(8)
	var buttons: Array[Button] = []
	for i in options.size():
		var b := UI.button(options[i], UI.SUN if i == current else UI.PAPER, 20)
		b.custom_minimum_size = Vector2(width, 54)
		buttons.append(b)
		row.add_child(b)
		b.pressed.connect(func():
			for j in buttons.size():
				UI.recolor(buttons[j], UI.SUN if j == i else UI.PAPER)
			on_pick.call(i))
	return row


func _setting(title: String, help: String, control: Control) -> void:
	var box := UI.panel(UI.PAPER, 22)
	var v := UI.vbox(6)
	v.add_child(UI.text(title, 24, UI.INK, false))
	if help != "":
		v.add_child(UI.text(help, 19, UI.INK_SOFT, false))
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(control)
	box.add_child(v)
	_body.add_child(box)


func _show_skills() -> void:
	var s := Game.state
	_text("Set where your child is with each calm-down tool. \"Learned\" tools are still practiced: the pets ask for them.", 20, UI.INK_SOFT)
	for id in Content.TECHNIQUE_ORDER:
		var t: Dictionary = Content.TECHNIQUES[id]
		var row := _choice_row(Content.STAGE_NAMES, s.stage_of(id), func(i: int): s.techniques[id].stage = i, 140)
		_setting("%s   (practiced %s)" % [t.name, _times(s.count_of(id))], t.science, row)
	_setting("Move skills up automatically", "After enough practice a tool moves Learning → Practicing → Learned, and the next tool is introduced. Turn off to control every step yourself.",
		_choice_row(["Off", "On"], 1 if s.adult.auto_progress else 0, func(i: int): s.adult.auto_progress = i == 1))


func _show_child_settings() -> void:
	var s := Game.state
	_setting("Tricky moments in mini-games", "How often a game goes wrong on purpose so your child can practice calming down while a little frustrated. Each one is followed by a calm-down tool and a fair retry.",
		_choice_row(["Off", "Gentle", "Medium", "Lots"], s.adult.frustration_level, func(i: int): s.adult.frustration_level = i))
	_setting("How often pets need help", "", _choice_row(["Less often", "Normal", "More often"], s.adult.frequency, func(i: int): s.adult.frequency = i, 170))
	_setting("Ask my child about their own feelings", "After helping a pet, sometimes ask \"How big is YOUR feeling right now?\" and offer to do a tool together.",
		_choice_row(["Off", "On"], 1 if s.adult.child_checkin else 0, func(i: int): s.adult.child_checkin = i == 1))
	var minutes := [0, 15, 20, 30, 45]
	var labels := ["No reminder", "15 min", "20 min", "30 min", "45 min"]
	_setting("Play-time reminder", "After this long, the pets get sleepy and suggest a break. It is a gentle nudge, not a lock.",
		_choice_row(labels, maxi(0, minutes.find(s.adult.session_minutes)), func(i: int): s.adult.session_minutes = minutes[i], 140))
	var focus_row := UI.hbox(8)
	for e in Content.BIG_FEELINGS:
		var b := UI.button(Content.EMOTIONS[e].label, UI.SUN if s.focus_enabled(e) else UI.PAPER, 20)
		b.custom_minimum_size = Vector2(134, 54)
		b.pressed.connect(func():
			s.adult.focus[e] = not s.focus_enabled(e)
			UI.recolor(b, UI.SUN if s.focus_enabled(e) else UI.PAPER))
		focus_row.add_child(b)
	_setting("Feelings to include", "Yellow feelings show up in pet stories. Switch one off to leave it out for now.", focus_row)


func _show_pets() -> void:
	var s := Game.state
	_text("Rename any pet here. Your child can also rename a pet any time with the pencil on its card.", 20, UI.INK_SOFT)
	_text("Your pets (%d)" % s.pets.size(), 26)
	var mine := _grid(3)
	for p in s.pets:
		var row := UI.hbox(10)
		row.add_child(UI.pet_picture(p, 56))
		var n := UI.label(p.name, 22, UI.INK, false)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(n)
		var rename := UI.button("Rename", UI.SKY, 18)
		rename.custom_minimum_size = Vector2(110, 50)
		rename.pressed.connect(_rename.bind(p))
		row.add_child(rename)
		mine.add_child(_cell(row))
	if s.roster_left() == 0:
		_text("Every pet has moved in!", 22)
		return
	_text("Add pets", 26)
	_text("Tap any animal to add it right away, for free, so your child can start with the ones they love. Added pets count as friends earned with hearts: the next one your child earns costs %d hearts." % s.arrival_cost(), 20, UI.INK_SOFT)
	var all := _grid(2)
	for sp in Content.SPECIES:
		var row := UI.hbox(8)
		for look in [""] + Content.LOOK_ORDER:
			var b := UI.button("", UI.CREAM)
			b.custom_minimum_size = Vector2(100, 100)
			var icon := UI.pet_icon(sp, 72, look)
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.offset_left = 12
			icon.offset_right = -12
			icon.offset_top = 8
			icon.offset_bottom = -16
			b.add_child(icon)
			if s.has_pet(sp, look):
				b.disabled = true
				var tick := Doodle.new()
				tick.kind = "check"
				tick.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
				tick.offset_left = -34
				tick.offset_bottom = 30
				b.add_child(tick)
			else:
				b.pressed.connect(_add_pet.bind(sp, look))
			row.add_child(b)
		all.add_child(_cell(row))


func _grid(columns: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(g)
	return g


func _cell(content: Control) -> PanelContainer:
	var box := UI.panel(UI.PAPER, 22)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(content)
	return box


func _rename(p: Dictionary) -> void:
	var namer := PetNamer.new(p, "What should we call %s?" % p.name)
	add_child(namer)
	var pet_name: String = await namer.done
	if pet_name != "":
		p.name = pet_name
		Game.save()
		_refresh_pets()


## A grown-up picks a pet for the child; it joins straight away, no hearts spent.
func _add_pet(sp: String, look: String) -> void:
	var s := Game.state
	var names: Array = Content.EXTRA_NAMES.duplicate()
	names.shuffle()
	var namer := PetNamer.new({"species": sp, "look": look, "name": Director.fresh_name(s, sp, look, names)},
		"What is your new friend's name?", "Welcome!")
	add_child(namer)
	var pet_name: String = await namer.done
	if pet_name == "" or s.has_pet(sp, look):
		return
	s.add_pet(sp, look, pet_name)
	Game.save()
	_refresh_pets()


## Rebuilds the Pets tab without jumping back to the top.
func _refresh_pets() -> void:
	var scroll := _body.get_parent() as ScrollContainer
	var at := scroll.scroll_vertical
	_select("Pets")
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = at


func _show_progress() -> void:
	var s := Game.state
	var st: Dictionary = s.stats
	_text("Play time: %s      Pets: %d      Feelings moments helped: %d" % [s.playtime_text(), s.pets.size(), s.moments_done], 24)
	var total := int(st.emotion_total)
	if total > 0:
		_text("Named the pet's feeling correctly on the first try: %d of %d" % [int(st.emotion_right), total])
	var picks := int(st.impulse_picked) + int(st.tool_picked_first)
	if picks > 0:
		_text("Chose a calm-down tool first (instead of the pet's unsafe urge): %d of %d" % [int(st.tool_picked_first), picks])
	_text("Tricky moments handled in mini-games: %d" % int(st.frustration_events))
	var be: Dictionary = st.by_emotion
	if not be.is_empty():
		var parts := []
		for e in be:
			parts.append("%s %d" % [Content.EMOTIONS[e].label, int(be[e])])
		_text("Feelings helped: " + ", ".join(parts))
	_text("Tool practice", 26)
	for id in Content.TECHNIQUE_ORDER:
		_text("%s: %s  (%s)" % [Content.TECHNIQUES[id].name, _times(s.count_of(id)), Content.STAGE_NAMES[s.stage_of(id)]])
	var checks: Array = st.child_checkins
	if not checks.is_empty():
		_text("Your child's own feeling check-ins (size before → after a tool)", 26)
		var parts := []
		for c in checks:
			parts.append("%d → %d" % [int(c[0]), int(c[1])] if int(c[1]) > 0 else str(int(c[0])))
		_text(",   ".join(parts))
		_text("A big number here can be a good moment for a hug and a chat.", 19, UI.INK_SOFT)


func _show_saves() -> void:
	# PIN
	var pin_row := UI.hbox(10)
	var pin_edit := LineEdit.new()
	pin_edit.placeholder_text = "4 digits"
	pin_edit.max_length = 4
	pin_edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	pin_edit.custom_minimum_size = Vector2(170, 54)
	pin_row.add_child(pin_edit)
	var pin_status := UI.label("PIN is set" if Game.settings.pin_hash != "" else "No PIN (uses a multiplication question)", 20, UI.INK_SOFT, false)
	var set_pin := UI.button("Set PIN", UI.LEAF, 20)
	set_pin.custom_minimum_size = Vector2(140, 54)
	set_pin.pressed.connect(func():
		if AdultGate.valid_pin(pin_edit.text):
			Game.settings.pin_hash = AdultGate.hash_pin(pin_edit.text)
			Game.save_settings()
			pin_edit.text = ""
			pin_status.text = "PIN is set"
		else:
			pin_status.text = "A PIN needs exactly 4 digits")
	pin_row.add_child(set_pin)
	var clear_pin := UI.button("Remove PIN", UI.PAPER, 20)
	clear_pin.custom_minimum_size = Vector2(170, 54)
	clear_pin.pressed.connect(func():
		Game.settings.pin_hash = ""
		Game.save_settings()
		pin_status.text = "No PIN (uses a multiplication question)")
	pin_row.add_child(clear_pin)
	pin_row.add_child(pin_status)
	_setting("Grown-ups PIN", "Protects this menu and deleting saves.", pin_row)
	# Slots
	for slot in range(1, SaveStore.SLOTS + 1):
		var row := UI.hbox(10)
		var st := Game.store.load_slot(slot)
		if st == null:
			row.add_child(UI.label("Empty", 20, UI.INK_SOFT, false))
		else:
			row.add_child(UI.label("%d pets, %d hearts, played %s, last played %s" % [st.pets.size(), st.hearts, st.playtime_text(), st.last_played.replace("T", " ")], 20, UI.INK, false))
			if slot == Game.slot:
				row.add_child(UI.label("(in use now)", 20, UI.INK_SOFT, false))
			else:
				var del := UI.button("Delete", UI.CORAL, 20)
				del.custom_minimum_size = Vector2(130, 54)
				var armed := [false]
				del.pressed.connect(func():
					if not armed[0]:
						armed[0] = true
						del.text = "Really delete?"
						del.custom_minimum_size.x = 220
						return
					Game.store.delete_to_trash(slot)
					_select("Saves & PIN"))
				row.add_child(del)
		_setting("Save %d" % slot, "", row)
	# Trash
	var trash := Game.store.list_trash()
	if trash.is_empty():
		_text("Deleted saves go to a recycle bin here first, so nothing is lost by accident. The bin is empty.", 20, UI.INK_SOFT)
		return
	_text("Recycle bin", 26)
	for file_name in trash:
		var row := UI.hbox(10)
		var free := Game.store.first_free_slot()
		var restore := UI.button("Restore to Save %d" % free if free > 0 else "No free save", UI.LEAF, 20)
		restore.custom_minimum_size = Vector2(240, 54)
		restore.disabled = free == 0
		restore.pressed.connect(func():
			Game.store.restore_from_trash(file_name, free)
			_select("Saves & PIN"))
		row.add_child(restore)
		_setting(file_name.trim_suffix(".json").replace("_", " "), "", row)
	var empty := UI.button("Empty the recycle bin forever", UI.CORAL, 20)
	empty.custom_minimum_size = Vector2(380, 54)
	var armed_empty := [false]
	empty.pressed.connect(func():
		if not armed_empty[0]:
			armed_empty[0] = true
			empty.text = "This cannot be undone. Tap again."
			return
		Game.store.empty_trash()
		_select("Saves & PIN"))
	_setting("Delete forever", "", empty)

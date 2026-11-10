class_name AdultMenu
extends Control
## The grown-ups area (always opened through AdultGateDialog).
## Guide, per-child skills and settings, progress, and save-file management
## (including moving a child's save and recordings to another tablet).

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

In the Recording Booth your child can record animal sounds for each pet and feeling, and record the game's lines in their own voice. The game then plays those instead of the computer voice. Saying the pets' helpful thoughts out loud ("I can't do it YET") is real practice of coping self-talk. Each save keeps its own recordings, so brothers and sisters each have their own voice; in Settings a child can choose to hear a sibling's recordings instead, and pick the computer voice that reads everything else. Recordings stay on this device unless you export them (Saves & PIN).

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
var _notice := ""  # shown once at the top of the Saves tab


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


func _recordings(n: int) -> String:
	return "1 recording" if n == 1 else "%d recordings" % n


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
	if _notice != "":
		_text(_notice, 22, UI.LEAF.darkened(0.4))
		_notice = ""
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
			_setting("Save %d" % slot, "", row)
			continue
		var name_edit := LineEdit.new()
		name_edit.text = st.child_name
		name_edit.placeholder_text = "Child's name"
		name_edit.max_length = 12
		name_edit.custom_minimum_size = Vector2(200, 54)
		row.add_child(name_edit)
		var rename := UI.button("Rename", UI.PAPER, 20)
		rename.custom_minimum_size = Vector2(130, 54)
		rename.pressed.connect(func():
			var new_name := GameState.clean_name(name_edit.text, "")
			if slot == Game.slot:
				Game.state.child_name = new_name
				Game.save()
			else:
				st.child_name = new_name
				Game.store.save(slot, st)
			_select("Saves & PIN"))
		row.add_child(rename)
		var export := UI.button("Export", UI.SKY, 20)
		export.custom_minimum_size = Vector2(130, 54)
		export.pressed.connect(_export.bind(slot))
		row.add_child(export)
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
		_setting("Save %d" % slot + (": " + st.child_name if st.child_name != "" else ""), _summary(st), row)
	var import := UI.button("Import from a file", UI.SKY, 20)
	import.custom_minimum_size = Vector2(260, 54)
	import.pressed.connect(_import)
	_setting("Move to another tablet", "Export saves one child's sanctuary and all of their recordings as a single .zip file. Put it where the other tablet can reach it (Google Drive, email, a USB stick), then on the other tablet open Grown-ups, Saves & PIN, and tap Import.", import)
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


func _summary(st: GameState) -> String:
	var recordings := VoiceStore.new(Game.store.voice_dir(st.profile_id)).count()
	return "%d pets, %d hearts, %s, played %s, last played %s" % [st.pets.size(), st.hearts, _recordings(recordings), st.playtime_text(), st.last_played.replace("T", " ")]


func _export(slot: int) -> void:
	if slot == Game.slot:
		Game.save()
	var st := Game.store.load_slot(slot)
	_pick_file(true, ProfilePack.file_name(st, slot), func(path: String):
		var err := ProfilePack.export_slot(Game.store, slot, path)
		_notice = "Exported %s. Now open it on the other tablet." % ProfilePack.file_name(st, slot) if err == OK else "Could not write the file (%s)." % error_string(err)
		_select("Saves & PIN"))


## Opens the system's file picker (on Android it reaches Downloads, Google
## Drive and so on), or Godot's own one where there is none.
func _pick_file(saving: bool, file_name: String, done: Callable) -> void:
	var filters := PackedStringArray(["*.zip ; Sunny Paws save"])
	if OS.get_name() == "Android" and not saving:
		filters = PackedStringArray()  # a file from a cloud drive may not be marked as a zip
	var picked := func(path: String):
		if is_inside_tree():
			done.call(path)
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var mode := DisplayServer.FILE_DIALOG_MODE_SAVE_FILE if saving else DisplayServer.FILE_DIALOG_MODE_OPEN_FILE
		DisplayServer.file_dialog_show("", OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), file_name, false, mode, filters,
			func(ok: bool, paths: PackedStringArray, _filter: int):
				if ok and not paths.is_empty():
					picked.call_deferred(paths[0]))
		return
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if saving else FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = filters
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	dialog.current_file = file_name
	dialog.file_selected.connect(picked)
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)


func _import() -> void:
	_pick_file(false, "", func(path: String):
		var pack := ProfilePack.read(path, Game.store.base_dir)
		if pack.is_empty():
			_notice = "That file is not a Sunny Paws save. Pick the .zip made by Export."
			_select("Saves & PIN")
		else:
			show_import(pack))


## Where should the imported save go? A free save, in place of another one
## (which goes to the recycle bin), or only its recordings added to a child
## who already has a sanctuary here.
func show_import(pack: Dictionary) -> void:
	for c in _body.get_children():
		c.queue_free()
	var incoming: GameState = pack.state
	var who := incoming.child_name if incoming.child_name != "" else "The sanctuary"
	_text("In the file: %s's sanctuary. %s" % [incoming.child_name, _summary_of_pack(pack)] if incoming.child_name != "" else "In the file: " + _summary_of_pack(pack), 26)
	_text("Where should it go?", 22, UI.INK_SOFT)
	for slot in range(1, SaveStore.SLOTS + 1):
		var st := Game.store.load_slot(slot)
		var row := UI.hbox(10)
		if st == null:
			row.add_child(_import_button("Put it here", UI.LEAF, func():
				ProfilePack.import_profile(Game.store, pack, slot)
				return "%s is in Save %d with %s." % [who, slot, _recordings(pack.recordings)]))
			_setting("Save %d (empty)" % slot, "", row)
			continue
		if slot != Game.slot:
			row.add_child(_import_button("Replace this save", UI.CORAL, func():
				ProfilePack.import_profile(Game.store, pack, slot)
				return "%s replaced Save %d. The old save is in the recycle bin." % [who, slot], true))
		row.add_child(_import_button("Add only the recordings", UI.SKY, func():
			ProfilePack.add_recordings(Game.store, pack, st.profile_id)
			return "Added %s to Save %d. Its sanctuary did not change." % [_recordings(pack.recordings), slot]))
		_setting("Save %d" % slot + (": " + st.child_name if st.child_name != "" else ""), _summary(st), row)
	var cancel := UI.button("Cancel", UI.PAPER, 20)
	cancel.custom_minimum_size = Vector2(160, 54)
	cancel.pressed.connect(_select.bind("Saves & PIN"))
	_body.add_child(cancel)


## A button that imports, then goes back to the Saves tab saying what happened.
## With `confirm`, the first tap only asks "Really?".
func _import_button(text: String, color: Color, apply: Callable, confirm := false) -> Button:
	var b := UI.button(text, color, 20)
	b.custom_minimum_size = Vector2(240, 54)
	var armed := [not confirm]
	b.pressed.connect(func():
		if not armed[0]:
			armed[0] = true
			b.text = "Really replace it?"
			return
		Game.save()  # so the playing child's lines are on disk before anything is merged in
		_notice = apply.call()
		if Game.state != null:
			Game.open_voices()
		_select("Saves & PIN"))
	return b


func _summary_of_pack(pack: Dictionary) -> String:
	var st: GameState = pack.state
	return "%d pets, %d hearts, %s, played %s" % [st.pets.size(), st.hearts, _recordings(pack.recordings), st.playtime_text()]

extends Node
## End-to-end smoke test + screenshot tour. Drives the real game through every
## screen using a throwaway save folder.
##   godot -- --autopilot=/path/for/screenshots        (windowed: saves PNGs)
##   godot --headless -- --autopilot                   (no PNGs, just checks it runs)

var main: Node
var out_dir := ""
var shots := 0
var steps_ok := 0


func _ready() -> void:
	Game.store = SaveStore.new("user://autopilot_saves")
	for i in range(1, 4):
		Game.store.delete_to_trash(i)
	Game.store.empty_trash()  # also clears the recordings of the deleted saves
	Game.settings.read_aloud = false
	Game.settings.music = 0.0
	Game.settings.sfx = 0.0
	Sfx.use_mic = false
	Game.rng.seed = 4242
	seed(4242)
	get_tree().create_timer(420.0).timeout.connect(func():
		print("AUTOPILOT TIMEOUT (a step failed; see errors above)")
		get_tree().quit(1))
	_run()


func must(ok: bool, what: String) -> void:
	if not ok:
		print("AUTOPILOT FAILED: ", what)
		get_tree().quit(1)
		await get_tree().create_timer(999.0).timeout


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func shot(label: String) -> void:
	steps_ok += 1
	print("autopilot: ", label)
	if out_dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	shots += 1
	get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [out_dir, shots, label])


func _buttons(root: Node) -> Array:
	var out := []
	for b in root.find_children("*", "Button", true, false):
		if not b.disabled and b.is_visible_in_tree():
			out.append(b)
	return out


func _mouse(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	Input.parse_input_event(ev)


func click(pos: Vector2) -> void:
	_mouse(pos, true)
	await wait(0.08)
	_mouse(pos, false)
	await wait(0.25)


func drag(from: Vector2, to: Vector2) -> void:
	_mouse(from, true)
	await wait(0.05)
	for i in range(1, 9):
		var ev := InputEventMouseMotion.new()
		ev.position = from.lerp(to, i / 8.0)
		ev.global_position = ev.position
		ev.relative = (to - from) / 8.0
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(ev)
		await wait(0.03)
	_mouse(to, false)
	await wait(0.2)


## A short beep standing in for a microphone take (the same shape the
## recorder hands over after tidying: mono, 16 bit).
func _fake_take() -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(12000 * 2)
	for i in 12000:
		bytes.encode_s16(i * 2, int(sin(i * 0.12) * 12000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 24000
	wav.data = bytes
	return wav


func _find_thermo(root: Node) -> Thermometer:
	for c in root.get_children():
		if c is Thermometer:
			return c
		var deeper := _find_thermo(c)
		if deeper:
			return deeper
	return null


## Plays a FeelingsFlow to the end by pressing buttons and finishing exercises.
func drive_flow(flow: FeelingsFlow, label: String) -> void:
	var i := 0
	var last_prompt := ""
	while is_instance_valid(flow) and i < 80:
		await wait(0.45)
		if not is_instance_valid(flow):
			break
		i += 1
		if flow._last_prompt != last_prompt:
			last_prompt = flow._last_prompt
			await shot("%s_%02d" % [label, i])
		var tech: Technique = null
		for c in flow._content.get_children():
			if c is Technique:
				tech = c
		if tech:
			await wait(0.8)
			await shot("%s_%02d_tool" % [label, i])
			tech.finish()
			await wait(1.0)
			continue
		# The thermometer needs a pick before its button enables.
		var thermo := _find_thermo(flow._content)
		if thermo:
			thermo.level = 4
			thermo.picked.emit(4)
			await wait(0.1)
		var buttons := _buttons(flow._content)
		if not buttons.is_empty():
			buttons[0].pressed.emit()
	if i >= 80:
		print("STUCK at: ", flow._last_prompt, " | buttons: ", _buttons(flow._content).size(), " | children: ", flow._content.get_children())
	must(i < 80, "flow did not finish: " + label)


func _run() -> void:
	await wait(1.5)
	await shot("title")
	var title: TitleScreen = main.current
	# A newer build is out: the title offers it and the grown-ups panel explains it.
	Updates.available = {"build": 99, "name": "SunnyPaws-build-99-android.apk", "url": "", "size": 31457280, "sha256": "", "page": ""}
	Updates.found.emit(Updates.available)
	must(_buttons(title._title_card).any(func(b): return b.text == "New version!"), "title offers the update")
	var update := UpdatePanel.new(true)
	title._root.add_child(update)
	await wait(0.4)
	await shot("update")
	must(_buttons(update).any(func(b): return b.text == "Update"), "update panel can start the download")
	update.queue_free()
	Updates.available = {}
	# Real input: click the Play button with a synthetic mouse click.
	# (Headless has no real window, so input checks only run windowed.)
	var real_input := DisplayServer.get_name() != "headless"
	if real_input:
		var play_button: Button = _buttons(title._root)[0]
		await click(play_button.get_global_rect().get_center())
		must(_buttons(title._root).size() >= 4, "Play click opened the slot picker")
	else:
		title._show_slots()
	await wait(0.6)
	await shot("slots_empty")
	title._open_settings()
	await wait(0.4)
	await shot("settings")
	var gate := AdultGateDialog.new()
	title._root.add_child(gate)
	await wait(0.4)
	await shot("adult_gate")
	gate.queue_free()
	for c in title._root.get_children():
		if c is SettingsPanel:
			c.queue_free()

	# A brother or sister already has a save with one recording.
	var sibling := GameState.new_game()
	sibling.child_name = "Sam"
	Game.store.save(2, sibling)
	VoiceStore.new(Game.store.voice_dir(sibling.profile_id)).save(VoiceStore.animal_file("dog", "happy"), _fake_take())
	title.ask_name(1, true)
	await wait(0.4)
	await shot("name_prompt")
	main._on_play_slot(1, true, "Robin")
	await wait(2.0)
	var s: Sanctuary = main.current
	await shot("sanctuary")
	must(Game.state.child_name == "Robin" and Game.voice.is_empty(), "a new child starts with a name and no recordings")
	# Settings: hear Sam's recordings instead, then go back to mine.
	s._open_settings()
	await wait(0.4)
	var settings: SettingsPanel = s._overlays.get_child(0)
	await shot("settings_voices")
	var voice_buttons := _buttons(settings).filter(func(b): return b.text in ["Mine", "Sam"])
	must(voice_buttons.size() == 2, "whose-voice choice lists the sibling")
	voice_buttons[1].pressed.emit()
	must(Game.listen.animal_stream("dog", "happy") != null and Game.voice.animal_stream("dog", "happy") == null, "hear the sibling's recordings, keep your own")
	voice_buttons[0].pressed.emit()
	must(Game.listen == Game.voice and Game.state.voice.from == "", "back to my own voice")
	settings.queue_free()
	await wait(0.3)
	# Real input: drag pans the camera, a tap on a pet selects it, one click = one press.
	if real_input:
		var before := s.cam_target
		await drag(Vector2(640, 500), Vector2(440, 420))
		must(s.cam_target.distance_to(before) > 1.0, "drag pans the camera")
		await wait(0.5)
		s.pets[0].stop()
		s.pets[0]._wait = 99.0
		s.pets[0].position = Vector3(0, 0, 4.5)  # open ground, clear of the station signs
		await wait(0.2)
		await click(s._screen(s.pets[0].global_position + Vector3(0, 0.8, 0)))
		must(s._selected == s.pets[0], "tap selects the pet")
		var hearts_before := Game.state.hearts
		var pet_btn: Button = _buttons(s._pet_card).filter(func(b): return b.text == "Pet")[0]
		await click(pet_btn.get_global_rect().get_center())
		must(Game.state.hearts == hearts_before + 1, "one click gives exactly one press")
		var pencil: Button = _buttons(s._pet_card)[0]
		await click(pencil.get_global_rect().get_center())
		await wait(0.3)
		must(s._overlays.get_child_count() == 1 and s._overlays.get_child(0) is PetNamer, "the pencil opens renaming")
		(s._overlays.get_child(0) as PetNamer)._finish("")
		await wait(0.2)
		s._deselect()
		s.cam_target = Vector3(0, 0, 2.5)
		print("autopilot: real input ok")
	s.cam_dist = 16.0
	s.cam_target = s.pets[0].position
	await wait(1.0)
	s._select(s.pets[0])
	await wait(0.6)
	await shot("pet_card")
	s._rename(s.pets[0])
	await wait(0.6)
	var namer: PetNamer = s._overlays.get_child(0)
	namer._name_edit.text = "Sir Woof"
	await shot("rename")
	namer.confirm()
	await wait(0.6)
	must(Game.state.pets[0].name == "Sir Woof" and s._selected == s.pets[0], "pet renamed from its card")
	s._pet_action(s.pets[0], "Pet")
	s._pet_action(s.pets[0], "Treat")
	await wait(2.5)
	s._pet_action(s.pets[0], "Fetch")
	await wait(1.0)
	await shot("fetch")
	await wait(4.0)
	s.cam_dist = 30.0
	s.cam_target = Vector3(0, 0, 2.5)

	# A full feelings moment.
	s._begin_help(Content.scenario_by_id("tower_fell"), s.pets[1])
	await wait(1.0)
	await shot("needs_help")
	s._start_moment()
	await wait(0.5)
	await drive_flow(s._overlays.get_child(0), "moment")
	await wait(0.5)
	must(Game.state.moments_done == 1, "moment recorded")
	must(Game.state.count_of("balloon") >= 1, "practice recorded")

	# Every tool in practice mode.
	for id in Content.TECHNIQUE_ORDER:
		Game.state.techniques[id].stage = Content.STAGE_PRACTICE
	for id in Content.TECHNIQUE_ORDER:
		var flow := FeelingsFlow.new({"mode": "practice", "scenario": Content.scenario_by_id("thunder"),
			"pet": Game.state.pets[0], "pet_index": 0, "friend": Game.state.pets[1], "tool": id})
		s._overlays.add_child(flow)
		await drive_flow(flow, "tool_" + id)
		await wait(0.3)

	# A second moment with a "learned" tool (pet initiates) and a worry story.
	for id in Content.TECHNIQUE_ORDER:
		Game.state.techniques[id].stage = Content.STAGE_LEARNED
	s._begin_help(Content.scenario_by_id("thunder"), s.pets[2])
	s._start_moment()
	await wait(0.5)
	await drive_flow(s._overlays.get_child(0), "learned")
	await wait(0.5)

	# Toolbox, garden.
	s._open_toolbox()
	await wait(0.5)
	await shot("toolbox")
	s._overlays.get_child(0).queue_free()
	await wait(0.2)
	s._on_station("garden")
	await wait(0.4)
	s.garden_tap(0)
	s.garden_tap(1)
	Game.state.garden[1].stage = 2
	Game.state.garden[2].stage = 4
	s._refresh_garden()
	await wait(0.3)
	await shot("garden")
	s.garden_tap(2)
	s._overlays.get_child(0).queue_free()
	await wait(0.3)

	# Mini-games.
	s._on_station("snack")
	await wait(1.2)
	await shot("snack_order")
	var snack: SnackGame = s._overlays.get_child(0)
	await wait(3.0)
	await shot("snack_pick")
	snack.close(0)
	await wait(0.3)

	s._on_station("cards")
	await wait(0.8)
	var cards: CardGame = s._overlays.get_child(0)
	cards._flip(0)
	cards._flip(1)
	await wait(0.4)
	await shot("cards")
	await wait(1.0)
	cards._mix_up()
	await wait(2.2)
	await drive_flow(s._overlays.get_child(1), "setback")
	await wait(0.4)
	cards.close(0)
	await wait(0.3)

	s._on_station("blocks")
	await wait(0.8)
	var blocks: BlockGame = s._overlays.get_child(0)
	for n in 3:
		blocks.mover.x = blocks.tower[-1].x + 10.0
		var click := InputEventMouseButton.new()
		click.pressed = true
		click.button_index = MOUSE_BUTTON_LEFT
		blocks._on_input(click)
		await wait(0.3)
	await shot("blocks")
	blocks.win(5, "What a tall tower!")
	await wait(0.6)
	await shot("win")
	blocks.close(5)
	await wait(0.3)

	# The three newer games.
	s._on_station("dig")
	await wait(0.8)
	var dig: DigGame = s._overlays.get_child(0)
	for round_number in DigGame.ROUNDS:
		var miss := (dig.treasure + 7) % dig.cells.size()
		dig.dig(miss)
		must(dig.cells[miss].text != "" and dig.misses == 1, "a wrong dig gives a clue")
		await wait(0.3)
		if round_number == 0:
			await shot("dig_clue")
		dig.dig(dig.treasure)
		await wait(2.2)
	await shot("dig_win")
	must(dig.round_index == DigGame.ROUNDS, "treasure dig finished")
	dig.close(5)
	await wait(0.3)

	s._on_station("band")
	await wait(1.0)
	var band: BandGame = s._overlays.get_child(0)
	await shot("band")
	for n in 80:
		if band.listening:
			break
		await wait(0.2)
	must(band.listening, "band hands over after the tune")
	var first_tune: Array = band.tune.duplicate()
	band.tap((first_tune[0] + 1) % band.pads.size())
	must(band.slips == 1 and not band.listening, "a wrong note replays the tune")
	for n in 80:
		if band.listening:
			break
		await wait(0.2)
	must(band.tune == first_tune, "same tune after a slip")
	for note in first_tune:
		band.tap(note)
		await wait(0.2)
	await wait(1.0)
	must(band.round_index == 1, "band round won")
	band.close(0)
	await wait(0.3)

	s._on_station("art")
	await wait(3.4)
	var art: ArtGame = s._overlays.get_child(0)
	await shot("art_splat")
	art.tell(ArtGame.STORMY)
	must(not art.waiting_tap, "stormy thought does not move on")
	art.tell(ArtGame.HELPFUL)
	must(art.waiting_tap, "helpful thought moves on")
	var kinds := ArtGame.THINGS.keys()
	for n in ArtGame.SPLATS:
		for wait_n in 30:
			if art.waiting_tap:
				break
			await wait(0.2)
		art.offer()
		await wait(0.2)
		if n == 0:
			await shot("art_ideas")
		art.make(kinds[n % kinds.size()])
	await wait(2.4)
	await shot("art_done")
	must(art.fixed == ArtGame.SPLATS, "every splat became something")
	art.close(4)
	await wait(0.3)

	# Recording booth: an animal sound and a voice line (with a stand-in take).
	s._on_station("booth")
	await wait(0.6)
	var booth: RecordingBooth = s._overlays.get_child(0)
	var first_name: String = Game.state.pets[0].name
	must(booth._animal_list.find_children("*", "Label", true, false).any(func(l): return first_name in l.text), "booth lists the pets by name")
	booth.pick_feeling("mad")
	await shot("booth_animals")
	booth.bar.finish_take(_fake_take())
	must(Game.voice.animal_stream(booth.species, "frustrated") != null, "animal sound saved and shared with a close feeling")
	await wait(0.3)
	booth.show_tab("Voice Lines")
	await wait(0.4)
	var line: String = booth.lines[booth.line_index].text
	booth.bar.finish_take(_fake_take())
	await shot("booth_lines")
	must(booth.lines[booth.line_index].recorded, "voice line saved")
	var spoken: Array = Game.voice.plan("Hello there, helper friend. %s Goodbye for now, friend." % line)
	must(spoken.size() == 3 and spoken[1].stream != null, "the recorded line is used inside spoken text")
	booth.step_line(1)
	must(not booth.lines[booth.line_index].recorded, "next line is waiting")
	booth.close()
	await wait(0.4)
	must(not s.overlay_open(), "booth closed")

	# A pet that wants everything perfect.
	var cat := s.pets[1]
	must(Content.trait_of(cat.info.species) == "perfect", "the starter cat is a perfectionist")
	s._begin_help(Content.scenario_by_id("wrong_answer"), cat)
	s._start_moment()
	await wait(0.5)
	await drive_flow(s._overlays.get_child(0), "perfect")
	await wait(0.5)

	# Hide and seek.
	s._start_hide()
	await wait(1.5)
	await shot("hide_count")
	await wait(4.5)
	await shot("hide_seek")
	for p in s._hide.pets.duplicate():
		s._found_hider(p)
	await wait(1.0)

	# New arrival.
	Game.state.hearts = 200
	s._refresh_hud()
	await wait(0.3)
	s._welcome_new_pet()
	await wait(0.8)
	var picker: FriendPicker = s._overlays.get_child(0)
	await shot("friend_picker")
	must(picker.offers.size() == 3 and picker.offers[2].look != "", "three animals to choose from, one in a special colour")
	picker.choose(2)
	await wait(0.6)
	picker._name_edit.text = "Sparkle"
	await shot("friend_name")
	picker.confirm(2)
	await wait(3.5)
	await shot("arrival")
	must(Game.state.pets.size() == 4, "pet arrived")
	must(Game.state.pets[3].name == "Sparkle" and Game.state.pets[3].look != "", "chosen pet, look and name are kept")
	must(Game.state.hearts == 170, "the first new friend costs 30 hearts")
	s._start_moment()
	await wait(0.5)
	await drive_flow(s._overlays.get_child(0), "arrival")

	# Grown-ups menu.
	var menu := AdultMenu.new()
	s._overlays.add_child(menu)
	await wait(0.4)
	for tab in ["Guide", "Skills", "Child Settings", "Pets", "Progress", "Saves & PIN"]:
		menu._select(tab)
		await wait(0.3)
		await shot("adult_" + tab.to_lower().replace(" ", "_").replace("&", "and"))
	# A grown-up adds a pet for free and renames another.
	var hearts_now := Game.state.hearts
	menu._select("Pets")
	await wait(0.3)
	menu._add_pet("koala", "sky")
	await wait(0.5)
	var adder: PetNamer = menu.get_child(menu.get_child_count() - 1)
	await shot("adult_pets_add")
	adder.confirm()
	await wait(0.4)
	must(Game.state.has_pet("koala", "sky") and Game.state.pets.size() == 5, "grown-up added a pet")
	must(Game.state.hearts == hearts_now, "adding a pet costs no hearts")
	menu._rename(Game.state.pets[1])
	await wait(0.4)
	var renamer: PetNamer = menu.get_child(menu.get_child_count() - 1)
	renamer._name_edit.text = "Captain"
	renamer.confirm()
	await wait(0.4)
	must(Game.state.pets[1].name == "Captain", "pet renamed in the grown-ups menu")
	await shot("adult_pets_after")
	# Move Robin to "another tablet": export, then import into the other saves.
	var zip_path := Game.store.base_dir + "/robin.zip"
	must(ProfilePack.export_slot(Game.store, 1, zip_path) == OK, "export a save")
	var pack := ProfilePack.read(zip_path, Game.store.base_dir)
	must(not pack.is_empty() and pack.recordings == 2, "read the export back")
	menu.show_import(pack)
	await wait(0.3)
	await shot("adult_import")
	var add_buttons := _buttons(menu).filter(func(b): return b.text == "Add only the recordings")
	must(add_buttons.size() == 2, "the save in use can only take recordings")
	add_buttons[1].pressed.emit()
	await wait(0.3)
	must(VoiceStore.new(Game.store.voice_dir(sibling.profile_id)).count() == 3 and Game.store.load_slot(2).child_name == "Sam", "recordings added to Sam, sanctuary kept")
	menu.show_import(pack)
	await wait(0.3)
	_buttons(menu).filter(func(b): return b.text == "Put it here")[0].pressed.emit()
	await wait(0.3)
	await shot("adult_imported")
	var copy := Game.store.load_slot(3)
	must(copy != null and copy.child_name == "Robin" and copy.profile_id != Game.state.profile_id, "imported into a free save as its own profile")
	must(VoiceStore.new(Game.store.voice_dir(copy.profile_id)).count() == 2, "with the recordings")
	menu.queue_free()
	await wait(0.1)
	s._meet_new_pets()
	must(s.pets.size() == Game.state.pets.size(), "the added pet walks in")
	await wait(2.0)
	await shot("pets_walk_in")

	# Save, reload, back to title.
	Game.save()
	var hearts := Game.state.hearts
	main.show_title()
	await wait(0.8)
	(main.current as TitleScreen)._show_slots()
	await wait(0.5)
	await shot("slots_saved")
	must(Game.store.load_slot(1).hearts == hearts, "save persisted")
	print("AUTOPILOT OK: %d steps, %d screenshots" % [steps_ok, shots])
	get_tree().quit()

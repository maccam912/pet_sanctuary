extends SceneTree
## Headless logic tests:  godot --headless -s tests/run_tests.gd

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("  FAIL: ", what)


func _init() -> void:
	test_content()
	test_state_roundtrip()
	test_director_scenarios()
	test_skill_progression()
	test_frustration()
	test_full_playthrough()
	test_save_store()
	test_adult_gate()
	test_roster_and_pacing()
	test_perfectionism()
	test_voice_store()
	test_profiles()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func rng(seed_value := 7) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_content() -> void:
	print("content")
	var ids := {}
	for s in Content.all_scenarios() + [Content.ACTIVITY_FRUSTRATION]:
		check(not ids.has(s.id), "unique id " + s.id)
		ids[s.id] = true
		check(Content.BIG_FEELINGS.has(s.emotion), s.id + " emotion valid")
		for k in ["hot", "impulse", "then", "clues", "helpful", "good", "bad", "bad_why", "ending", "level", "also"]:
			check(s.has(k), "%s has %s" % [s.id, k])
		check(s.helpful.size() == 2 and s.good.size() == 2, s.id + " has 2 helpful + 2 good")
		check(s.clues.size() >= 2, s.id + " has clues")
		for c in s.clues:
			check(Content.BODY_CLUES.has(c), "%s clue %s exists" % [s.id, c])
		check(s.level >= 2 and s.level <= 5, s.id + " level in range")
		check(Content.wrong_clues(s).size() >= 2, s.id + " has distractor clues")
	for id in Content.TECHNIQUE_ORDER:
		check(Content.TECHNIQUES.has(id), "technique " + id)
		for e in Content.TECHNIQUES[id]["for"]:
			check(Content.BIG_FEELINGS.has(e), id + " for-emotion valid")
	# The first tool must work for every feeling, so a new save is never stuck.
	check(Content.TECHNIQUES.balloon["for"].size() == Content.BIG_FEELINGS.size(), "balloon fits all feelings")
	for sp in Content.STARTER_SPECIES + Content.ARRIVAL_ORDER:
		check(Content.SPECIES.has(sp), "species " + sp)
		check(FileAccess.file_exists("res://assets/pets/animal-%s.glb" % sp), "model for " + sp)
	for f in Content.FOODS:
		check(FileAccess.file_exists("res://assets/food_icons/%s.png" % f), "food icon " + f)
	for it in Content.LOOK_ITEMS:
		check(FileAccess.file_exists("res://assets/food_icons/%s.png" % it[0]), "look icon " + it[0])
	check(Content.fill("{pet} and {friend}", "A", "B") == "A and B", "fill")


func test_state_roundtrip() -> void:
	print("state")
	var s := GameState.new_game()
	check(s.pets.size() == 3, "3 starter pets")
	check(s.stage_of("balloon") == Content.STAGE_LEARNING, "balloon starts in learning")
	check(s.stage_of("turtle") == Content.STAGE_LOCKED, "others locked")
	s.hearts = 42
	s.adult.frustration_level = 3
	s.adult.focus["sad"] = false
	s.techniques.count.stage = 2
	var json := JSON.stringify(s.to_dict())
	var s2 := GameState.from_dict(JSON.parse_string(json))
	check(s2.hearts == 42, "hearts survive")
	check(s2.adult.frustration_level == 3, "adult setting survives")
	check(not s2.focus_enabled("sad") and s2.focus_enabled("mad"), "focus survives")
	check(s2.stage_of("count") == 2, "stage survives")
	# Broken / partial data must not crash and must give a playable state.
	var s3 := GameState.from_dict({"hearts": "x", "pets": [{"species": "dragon"}], "adult": {"frustration_level": 99}})
	check(s3.adult.frustration_level == 3, "clamped")
	check(s3.techniques.size() == Content.TECHNIQUE_ORDER.size(), "techniques filled in")
	check(s.arrival_cost() == 30 and not s3.can_welcome(), "arrival cost")
	# Special-colour pets and typed names survive; unknown looks fall back to plain.
	s.add_pet("fox", "rose", "  Sparkle{pet}  ")
	s.pets.append({"species": "pig", "name": "Old", "friendship": 1, "look": "glitter"})
	var s4 := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	check(s4.has_pet("fox", "rose") and not s4.has_pet("fox"), "look survives")
	check(s4.pets[3].name == "Sparklepet", "typed name cleaned and kept")
	check(s4.has_pet("pig"), "unknown look becomes plain")
	check(GameState.clean_name("   ", "Maple") == "Maple" and GameState.clean_name("Abcdefghijklmnop", "x").length() == 12, "name limits")
	# Profile: the child's name, a stable id and their voice choices.
	check(GameState.valid_profile_id(s.profile_id) and s.profile_id != GameState.new_game().profile_id, "each save gets its own profile id")
	s.child_name = "Emma"
	s.voice = {"from": "0123456789abcdef", "reader": "voice.x"}
	var s5 := GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	check(s5.child_name == "Emma" and s5.profile_id == s.profile_id, "name and profile id survive")
	check(s5.voice.from == "0123456789abcdef" and s5.voice.reader == "voice.x", "voice choices survive")
	var s6 := GameState.from_dict({"profile_id": "../../evil", "voice": {"from": "x/y"}, "child_name": "A\"b"})
	check(GameState.valid_profile_id(s6.profile_id) and s6.voice.from == "" and s6.child_name == "Ab", "unsafe profile data replaced")


func test_director_scenarios() -> void:
	print("director: scenarios")
	var s := GameState.new_game()
	var r := rng()
	var seen := {}
	for i in 60:
		var sc := Director.pick_scenario(s, r)
		check(not sc.has("tag"), "no tagged scenario in normal rotation")
		check(not s.recent_scenarios.has(sc.id), "not a recent repeat")
		Director.remember_scenario(s, sc.id)
		seen[sc.id] = true
	check(seen.size() >= 12, "good variety (%d)" % seen.size())
	check(Director.pick_scenario(s, r, "arrival").id == "new_arrival", "arrival scenario")
	s.adult.focus = {"mad": false, "frustrated": false}
	s.recent_scenarios.clear()
	for i in 30:
		var sc := Director.pick_scenario(s, r)
		check(sc.emotion != "mad" and sc.emotion != "frustrated", "focus filter respected")
	# Emotion choices always contain the answer and never an also-accepted one as a distractor.
	for sc in Content.SCENARIOS:
		var ch := Director.emotion_choices(sc, r)
		check(ch.size() == 3 and ch.has(sc.emotion), "choices include answer")
		var right := 0
		for c in ch:
			if Director.emotion_is_right(sc, c):
				right += 1
		check(right == 1, sc.id + " exactly one right choice")
	check(Director.next_moment_delay(GameState.new_game(), r) < 60.0, "first moment is quick")


func test_skill_progression() -> void:
	print("director: skills")
	var s := GameState.new_game()
	var r := rng()
	check(Director.tool_choices(s, "worried", r) == ["balloon"], "only balloon at start")
	var res := {}
	for i in Director.LEARN_TO_PRACTICE:
		res = Director.record_practice(s, "balloon")
	check(s.stage_of("balloon") == Content.STAGE_PRACTICE, "balloon -> practicing")
	check(res.stage_up and res.unlocked == "count", "next tool unlocks")
	check(Director.record_practice(s, "balloon").unlocked == "", "only one tool in learning at a time")
	var ch := Director.tool_choices(s, "mad", r)
	check(ch[0] == "count", "learning tool offered first")
	check(Director.tool_choices(s, "mad", r, 2, ["count"]) == ["balloon"], "exclude used tool")
	check(not Director.tool_choices(s, "worried", r).has("count"), "count not offered for worry")
	for i in 20:
		Director.record_practice(s, "balloon")
	check(s.stage_of("balloon") == Content.STAGE_LEARNED, "balloon -> learned")
	check(not Director.pet_initiates(s, "count", r), "pets don't initiate tools still being learned")
	var asked := 0
	for i in 100:
		if Director.pet_initiates(s, "balloon", r):
			asked += 1
	check(asked > 30 and asked < 90, "learned pets initiate often")
	# Adult turns auto-progress off: nothing moves by itself.
	var s2 := GameState.new_game()
	s2.adult.auto_progress = false
	for i in 20:
		Director.record_practice(s2, "balloon")
	check(s2.stage_of("balloon") == Content.STAGE_LEARNING and s2.stage_of("count") == 0, "manual mode holds stages")
	# Adult locks everything: still get something to do.
	for id in s2.techniques:
		s2.techniques[id].stage = 0
	check(Director.tool_choices(s2, "mad", r) == ["balloon"], "fallback tool")
	check(Director.level_after_tool(4) == 3 and Director.level_after_tool(3) == 1 and Director.level_after_tool(2) == 1, "thermometer drop")


func test_frustration() -> void:
	print("director: frustration")
	var r := rng()
	var s := GameState.new_game()
	s.adult.frustration_level = 0
	for i in 50:
		Director.note_activity_play(s, "stack")
		check(not Director.frustration_event(s, "stack", r), "level 0 never frustrates")
	for level in [1, 3]:
		s = GameState.new_game()
		s.adult.frustration_level = level
		var hits := 0
		var last := false
		for i in 200:
			Director.note_activity_play(s, "stack")
			var hit := Director.frustration_event(s, "stack", r)
			if i < 2:
				check(not hit, "no setback in first plays")
			check(not (hit and last), "never twice in a row")
			last = hit
			if hit:
				hits += 1
		if level == 1:
			check(hits > 5 and hits < 45, "gentle is rare (%d/200)" % hits)
		else:
			check(hits > 45 and hits < 100, "lots is frequent (%d/200)" % hits)


## Litmus test: play a long stretch of the game with no engine nodes at all.
func test_full_playthrough() -> void:
	print("full playthrough")
	var s := GameState.new_game()
	var r := rng(99)
	for moment in 120:
		var sc := Director.pick_scenario(s, r)
		var level: int = sc.level
		var used := []
		var guard := 0
		while level >= 3 and guard < 5:
			var tools := Director.tool_choices(s, sc.emotion, r, 2, used)
			check(not tools.is_empty(), "always a tool to offer")
			used.append(tools[0])
			Director.record_practice(s, tools[0])
			level = Director.level_after_tool(level)
			guard += 1
		check(level < 3, "feeling comes down")
		Director.finish_moment(s, sc, moment % s.pets.size())
		while s.can_welcome():
			s.hearts -= s.arrival_cost()
			var offer: Dictionary = Director.arrival_offers(s)[0]
			s.add_pet(offer.species, offer.look, offer.name)
	check(s.moments_done == 120, "moments counted")
	# 120 moments is many hours of play: new friends should still be coming.
	check(s.pets.size() >= 10 and s.pets.size() <= 18, "new friends arrive slowly (%d)" % s.pets.size())
	for id in Content.TECHNIQUE_ORDER:
		check(s.stage_of(id) >= Content.STAGE_PRACTICE, id + " reached practicing+ (stage %d)" % s.stage_of(id))
	check(GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict()))).pets.size() == s.pets.size(), "late save roundtrip")


func test_save_store() -> void:
	print("save store")
	var dir := "user://test_saves_%d" % Time.get_ticks_usec()
	var store := SaveStore.new(dir)
	check(store.first_free_slot() == 1 and not store.exists(1), "empty at start")
	var s := GameState.new_game()
	s.hearts = 5
	check(store.save(1, s), "save ok")
	s.hearts = 9
	check(store.save(1, s), "second save ok")
	check(store.load_slot(1).hearts == 9, "load newest")
	# Corrupt the main file: the backup takes over.
	var f := FileAccess.open(store.slot_path(1), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	check(store.load_slot(1) != null and store.load_slot(1).hearts == 5, "backup used when corrupt")
	store.save(1, s)
	var trashed := store.delete_to_trash(1)
	check(trashed != "" and not store.exists(1), "delete moves to trash")
	check(store.load_slot(1) == null, "deleted slot is empty")
	check(store.list_trash() == [trashed], "trash lists it")
	store.save(1, GameState.new_game())
	check(not store.restore_from_trash(trashed, 1), "won't restore over a used slot")
	check(store.restore_from_trash(trashed, 2) and store.load_slot(2).hearts == 9, "restore to free slot")
	check(store.first_free_slot() == 3, "free slot")
	store.delete_to_trash(1)
	store.delete_to_trash(2)
	store.empty_trash()
	check(store.list_trash().is_empty(), "trash emptied")
	_wipe(dir)


func test_adult_gate() -> void:
	print("adult gate")
	var r := rng()
	for i in 20:
		var c := AdultGate.make_challenge(r)
		check(c.answer >= 72, "hard enough for a 7 year old: " + c.question)
		check(AdultGate.check_answer(c, str(c.answer)), "right answer accepted")
		check(not AdultGate.check_answer(c, str(c.answer + 1)) and not AdultGate.check_answer(c, ""), "wrong rejected")
	var h := AdultGate.hash_pin("4821")
	check(AdultGate.check_pin(h, "4821") and not AdultGate.check_pin(h, "0000"), "pin check")
	check(not AdultGate.check_pin("", "0000"), "no pin set")
	check(AdultGate.valid_pin("1234") and not AdultGate.valid_pin("12a4") and not AdultGate.valid_pin("123"), "pin format")


func test_roster_and_pacing() -> void:
	print("roster and pacing")
	check(Content.roster_size() >= 90, "big roster (%d)" % Content.roster_size())
	for look in Content.LOOK_ORDER:
		check(Content.LOOKS.has(look), "look " + look)
	var s := GameState.new_game()
	var costs := []
	var seen := {}
	while s.roster_left() > 0:
		var offers := Director.arrival_offers(s)
		check(offers.size() >= 1 and offers.size() <= Director.OFFERS, "1 to 3 animals to choose from")
		check(Director.arrival_offers(s) == offers, "offers stay the same until a pet is welcomed")
		var species := {}
		var names := {}
		for o in offers:
			check(not s.has_pet(o.species, o.look), "offer is a new pet")
			check(not s.name_taken(o.name), "offer has a fresh name")
			species[o.species] = true
			names[o.name] = true
		check(species.size() == offers.size() and names.size() == offers.size(), "offers differ from each other")
		costs.append(s.arrival_cost())
		var pick: Dictionary = offers[s.pets.size() % offers.size()]
		s.add_pet(pick.species, pick.look, pick.name)
		seen["%s/%s" % [pick.species, pick.look]] = true
	check(s.pets.size() == Content.roster_size() and not s.can_welcome(), "whole roster can be collected")
	check(seen.size() == Content.roster_size() - 3, "no pet offered twice")
	check(costs[0] >= 25 and costs[1] > costs[0] and costs[-1] >= 100 and costs.max() == costs[-1], "each friend costs more, up to a cap")
	# Early offers are mostly everyday animals with one special colour.
	var offers0 := Director.arrival_offers(GameState.new_game())
	check(offers0.filter(func(o): return o.look == "").size() == 2, "two everyday animals, one special")


func test_perfectionism() -> void:
	print("perfectionism")
	check(Content.PERFECT_SCENARIOS.size() >= 5, "perfectionism stories")
	for sp in Content.PERFECTIONISTS:
		check(Content.SPECIES.has(sp), "perfectionist species " + sp)
	check(Content.STARTER_SPECIES.any(func(sp): return Content.trait_of(sp) == "perfect"), "a starter pet is a perfectionist")
	check(Content.scenario_by_id("wrong_answer").emotion == "embarrassed", "lookup finds trait stories")
	var s := GameState.new_game()
	for id in Content.TECHNIQUE_ORDER:
		s.techniques[id].stage = Content.STAGE_PRACTICE
	var r := rng(5)
	var own := 0
	for i in 200:
		check(not Director.pick_scenario(s, r).has("trait"), "other pets never get perfectionism stories")
		var sc := Director.pick_scenario(s, r, "", "perfect")
		if sc.get("trait", "") == "perfect":
			own += 1
		Director.remember_scenario(s, sc.id)
	check(own > 60 and own < 150, "perfectionists get their stories about half the time (%d/200)" % own)
	# Every feeling has at least two tools, so a Big feeling can always come down.
	for e in Content.BIG_FEELINGS:
		var n := 0
		for id in Content.TECHNIQUE_ORDER:
			if Content.TECHNIQUES[id]["for"].has(e):
				n += 1
		check(n >= 2, e + " has two or more tools")


func test_voice_store() -> void:
	print("voice store")
	check(VoiceStore.normalize("  Oops!  It's OK. ") == "oops its ok", "normalize")
	check(VoiceStore.split("Biscuit: \"Ahhh. I feel calm now.\"") == ["Biscuit:", "\"Ahhh. I feel calm now.\""], "a quote is its own line")
	check(VoiceStore.split("Then... CRASH! It all fell down.") == ["Then... CRASH! It all fell down."], "short bits stay together")
	check(VoiceStore.split("Which calm tool should we use? Let's pick one together.").size() == 2, "sentences split")
	check(VoiceStore.split("Line one here.\nLine two here.").size() == 2, "line breaks split")
	check(VoiceStore.split("7") == ["7"] and VoiceStore.split("  ").is_empty(), "tiny and empty text")
	check(VoiceStore.line_file("I can't do it YET.") == VoiceStore.line_file("\"i cant do it yet\""), "same words, same file")
	check(VoiceStore.display("\"Ahhh. I feel calm now.\"") == "Ahhh. I feel calm now.", "display strips quotes")
	check(Content.voice_script().size() >= 40, "starter script")
	for line in Content.voice_script():
		check(not line.contains("{"), "starter line has no blanks: " + line)

	# Straight from the microphone: mono floats at 44.1 kHz.
	var mic := PackedFloat32Array()
	mic.resize(44100)
	for i in range(13230, 30870):
		mic[i] = sin(i * TAU * 440.0 / 44100.0) * 0.3
	var from_mic := VoiceStore.clean_samples(mic, 44100.0)
	check(from_mic != null and from_mic.mix_rate == 22050 and from_mic.get_length() > 0.4 and from_mic.get_length() < 0.7, "microphone samples become a trimmed take")
	check(VoiceStore.clean_samples(PackedFloat32Array([0.0, 0.0]), 44100.0) == null, "too short")

	# A fake microphone take: silence, a loud beep, silence (stereo, 48 kHz).
	var take := _beep(48000, 0.4, 0.5, 0.6)
	var wav := VoiceStore.clean(take)
	check(wav != null and not wav.stereo and wav.mix_rate == 24000, "take becomes small and mono")
	check(wav != null and wav.get_length() > 0.45 and wav.get_length() < 0.9, "silence trimmed (%.2fs)" % (wav.get_length() if wav else 0.0))
	check(VoiceStore.clean(_beep(48000, 0.5, 0.0, 0.5)) == null, "silence is not a take")
	check(VoiceStore.clean(null) == null, "no take")

	var dir := "user://test_voice_%d" % Time.get_ticks_usec()
	var store := VoiceStore.new(dir)
	check(store.animal_stream("dog", "happy") == null and not store.has_line("Hello there friend."), "empty at start")
	check(store.save(VoiceStore.animal_file("dog", "mad"), wav), "animal sound saved")
	check(store.animal_stream("dog", "mad") != null, "exact feeling")
	check(store.animal_stream("dog", "frustrated") != null, "close feeling borrows the sound")
	check(store.animal_stream("dog", "happy") == null and store.animal_stream("cat", "mad") == null, "no sound for others")
	check(store.animal_count("dog") == 1, "count")
	var plan := store.plan("Which tool? I can't do it YET. Try it now.")
	check(plan.size() == 1 and plan[0].stream == null, "nothing recorded: one read-aloud piece")
	check(store.save(VoiceStore.line_file("I can't do it YET."), wav), "line saved")
	plan = store.plan("Which tool shall we use? I can't do it YET. Try it now please.")
	check(plan.size() == 3 and plan[0].stream == null and plan[1].stream != null and plan[2].stream == null, "recorded line slots into the middle")
	store.plan("Biscuit has a big feeling.")
	store.save_heard()
	# A fresh store reads everything back from disk.
	var again := VoiceStore.new(dir)
	check(again.has_line("i cant do it yet") and again.stream(VoiceStore.line_file("I can't do it YET.")) != null, "recordings reload")
	check(again.heard.has("try it now please"), "heard lines reload")
	var lines := again.booth_lines(["I can't do it YET.", "Mistakes help me learn."], ["Biscuit"])
	check(lines[0].text == "I can't do it YET." and lines[0].recorded and not lines[1].recorded, "starter lines first")
	check(lines[-1].text == "Biscuit has a big feeling.", "lines that name a pet come last")
	var keys := {}
	for l in lines:
		keys[VoiceStore.normalize(l.text)] = true
	check(keys.size() == lines.size(), "no line listed twice")
	var other := VoiceStore.new(dir + "_other")
	check(other.is_empty() and other.sample() == null, "someone with no recordings")
	var borrowed := other.plan("Which tool shall we use? I can't do it YET.", again)
	check(borrowed.size() == 2 and borrowed[1].stream != null and other.heard.has("i cant do it yet") and not other.has_line("I can't do it YET."), "play someone else's recordings, remember the line as heard here")
	check(again.count() == 2 and again.sample() == again.stream(VoiceStore.line_file("I can't do it YET.")), "a sample prefers a line")
	_wipe(dir + "_other")
	again.erase(VoiceStore.line_file("I can't do it YET."))
	check(not again.has_line("I can't do it YET.") and VoiceStore.new(dir).stream(VoiceStore.line_file("I can't do it YET.")) == null, "erase")
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + f)
	DirAccess.remove_absolute(dir)


func test_profiles() -> void:
	print("profiles")
	var wav := VoiceStore.clean(_beep(48000, 0.1, 0.4, 0.1))
	# Recordings from before profiles: every save gets a copy.
	var root := "user://test_profiles_%d" % Time.get_ticks_usec()
	var old := root + "/old_voice"
	var old_store := VoiceStore.new(old)
	old_store.save(VoiceStore.animal_file("dog", "happy"), wav)
	var store := SaveStore.new(root + "/saves")
	store.adopt_old_recordings(old)
	check(DirAccess.dir_exists_absolute(old), "old recordings kept while there are no saves")
	var emma := GameState.new_game()
	emma.child_name = "Emma"
	emma.hearts = 33
	var file := FileAccess.open(store.slot_path(1), FileAccess.WRITE)
	var old_save := emma.to_dict()
	old_save.erase("profile_id")
	file.store_string(JSON.stringify(old_save))
	file.close()
	store.save(2, GameState.new_game())
	store.adopt_old_recordings(old)
	var id1 := store.load_slot(1).profile_id
	check(id1 == store.load_slot(1).profile_id and GameState.valid_profile_id(id1), "a save from before profiles always gets the same id")
	var last_played := store.load_slot(1).last_played
	store.adopt_old_recordings(old)
	check(store.load_slot(1).last_played == last_played, "nothing to adopt: saves are left alone")
	check(VoiceStore.new(store.voice_dir(id1)).animal_count("dog") == 1 and VoiceStore.new(store.voice_dir(store.load_slot(2).profile_id)).animal_count("dog") == 1, "every save got the old recordings")
	check(not DirAccess.dir_exists_absolute(old), "old folder tidied away")
	check(store.slot_of_profile(id1) == 1 and store.slot_of_profile("feedfeedfeedfeed") == 0, "find a profile's save")
	var mine := VoiceStore.new(store.voice_dir(id1))
	mine.save(VoiceStore.line_file("I can't do it YET."), wav)
	mine.plan("I can't do it YET.")
	mine.save_heard()

	# Export Emma, then bring her to a second "tablet".
	var path := root + "/emma.zip"
	check(ProfilePack.file_name(store.load_slot(1), 1) == "SunnyPaws-Emma.zip", "file name")
	check(ProfilePack.export_slot(store, 1, path) == OK and FileAccess.file_exists(path), "export")
	check(ProfilePack.export_slot(store, 3, path + "x") != OK, "nothing to export in an empty save")
	var tablet := SaveStore.new(root + "/tablet_b")
	var pack := ProfilePack.read(path, tablet.base_dir)
	check(not pack.is_empty() and pack.state.child_name == "Emma" and pack.state.hearts == 33 and pack.recordings == 2, "read the file back")
	check(ProfilePack.import_profile(tablet, pack, 2), "import into an empty save")
	var there := tablet.load_slot(2)
	check(there.child_name == "Emma" and there.profile_id == id1, "same child, same profile")
	var their_voice := VoiceStore.new(tablet.voice_dir(id1))
	check(their_voice.has_line("I can't do it YET.") and their_voice.animal_count("dog") == 1 and their_voice.heard.has("i cant do it yet"), "recordings came along")

	# Importing her again elsewhere keeps the two apart; replacing a save recycles it.
	tablet.save(1, GameState.new_game())
	check(ProfilePack.import_profile(tablet, ProfilePack.read(path, tablet.base_dir), 1), "replace a save")
	check(tablet.list_trash().size() == 1, "the replaced save is in the recycle bin")
	check(tablet.load_slot(1).profile_id != id1 and tablet.load_slot(2).profile_id == id1, "a second copy gets its own profile")

	# Recordings only: added to a child who already has a sanctuary there.
	var liam := GameState.new_game()
	liam.hearts = 7
	tablet.save(3, liam)
	var liam_voice := VoiceStore.new(tablet.voice_dir(liam.profile_id))
	liam_voice.save(VoiceStore.animal_file("cat", "mad"), wav)
	liam_voice.plan("Liam says hello to everyone.")
	liam_voice.save_heard()
	ProfilePack.add_recordings(tablet, pack, liam.profile_id)
	liam_voice = VoiceStore.new(tablet.voice_dir(liam.profile_id))
	check(liam_voice.animal_count("cat") == 1 and liam_voice.animal_count("dog") == 1 and liam_voice.has_line("I can't do it YET."), "recordings merged, none lost")
	check(liam_voice.heard.has("liam says hello to everyone") and liam_voice.heard.has("i cant do it yet"), "heard lines merged")
	check(tablet.load_slot(3).hearts == 7, "recordings only: the sanctuary is untouched")

	# Not a profile, or a file trying to write outside the voice folder.
	var bad := ZIPPacker.new()
	bad.open(root + "/bad.zip")
	bad.start_file("hello.txt")
	bad.write_file("hi".to_utf8_buffer())
	bad.close_file()
	bad.close()
	check(ProfilePack.read(root + "/bad.zip", root).is_empty(), "a zip that is not a profile")
	check(ProfilePack.read(root + "/missing.zip", root).is_empty(), "a missing file")
	var sneaky := ZIPPacker.new()
	sneaky.open(root + "/sneaky.zip")
	for entry in ["profile.json", "voice/../../evil.wav", "voice/Line_X.wav", "voice/notes.txt", "voice/line_ok.wav"]:
		sneaky.start_file(entry)
		sneaky.write_file((JSON.stringify({"format": 1, "save": GameState.new_game().to_dict()}) if entry == "profile.json" else "x").to_utf8_buffer())
		sneaky.close_file()
	sneaky.close()
	var sp := ProfilePack.read(root + "/sneaky.zip", root)
	check(sp.files.keys() == ["line_ok.wav"], "only plain recording names are taken")
	var future := ZIPPacker.new()
	future.open(root + "/future.zip")
	future.start_file("profile.json")
	future.write_file(JSON.stringify({"format": 99, "save": {}}).to_utf8_buffer())
	future.close_file()
	future.close()
	check(ProfilePack.read(root + "/future.zip", root).is_empty(), "a file from a newer version is refused")

	# Emptying the recycle bin forgets the recordings of saves that are gone.
	var trashed_id := tablet.load_slot(3).profile_id
	tablet.delete_to_trash(3)
	check(DirAccess.dir_exists_absolute(tablet.voice_dir(trashed_id)), "a recycled save keeps its recordings")
	tablet.empty_trash()
	check(not DirAccess.dir_exists_absolute(tablet.voice_dir(trashed_id)) and DirAccess.dir_exists_absolute(tablet.voice_dir(id1)), "only orphaned recordings are deleted")
	_wipe(root)


## Deletes a test folder and everything in it.
func _wipe(dir: String) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_wipe(dir + "/" + sub)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + "/" + f)
	DirAccess.remove_absolute(dir)


func _beep(rate: int, quiet_before: float, loud: float, quiet_after: float) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	var total := int(rate * (quiet_before + loud + quiet_after))
	bytes.resize(total * 4)
	for i in total:
		var t := float(i) / rate
		var v := 0
		if t >= quiet_before and t < quiet_before + loud:
			v = int(sin(t * TAU * 440.0) * 9000.0)
		bytes.encode_s16(i * 4, v)
		bytes.encode_s16(i * 4 + 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.stereo = true
	wav.mix_rate = rate
	wav.data = bytes
	return wav

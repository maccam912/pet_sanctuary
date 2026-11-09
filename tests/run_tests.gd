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
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func rng(seed_value := 7) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_content() -> void:
	print("content")
	var ids := {}
	for s in Content.SCENARIOS + [Content.ACTIVITY_FRUSTRATION]:
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
	check(s.arrival_cost() == 12 and not s3.can_welcome(), "arrival cost")


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
			s.add_pet(s.next_arrival())
	check(s.moments_done == 120, "moments counted")
	check(s.pets.size() == Content.SPECIES.size(), "all pets welcomed (%d)" % s.pets.size())
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
	DirAccess.remove_absolute(dir + "/trash")
	DirAccess.remove_absolute(dir)


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

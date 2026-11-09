class_name FeelingsFlow
extends Control
## One "feelings moment": the child helps a pet notice a feeling, name it, find
## it in the body, calm the body with a tool, then think and solve the problem.
##
## Modes: "moment"   full story for a pet that needs help
##        "activity" short version after a staged setback in a mini-game
##        "practice" just one tool, chosen from the toolbox

signal finished
signal _picked(value)

var cfg := {}
var scenario := {}
var pet := {}
var friend := {}
var mode := "moment"
var level := 3
var used_tools: Array = []
var unlocked_tool := ""
var leveled_tool := ""

var _state: GameState
var _bg: ColorRect
var _stage: PetStage
var _thermo: Thermometer
var _thermo_box: Control
var _face_row: HBoxContainer
var _prompt: Label
var _content: VBoxContainer
var _last_prompt := ""


func _init(config := {}) -> void:
	cfg = config
	scenario = cfg.get("scenario", Content.ACTIVITY_FRUSTRATION)
	pet = cfg.get("pet", {"species": "dog", "name": "Biscuit"})
	friend = cfg.get("friend", pet)
	mode = cfg.get("mode", "moment")
	level = int(scenario.level)


func _ready() -> void:
	_state = Game.state
	UI.full(self)
	theme = UI.theme()
	_bg = UI.backdrop(_mood_color())
	add_child(_bg)
	var m := MarginContainer.new()
	UI.full(m)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 26)
	add_child(m)
	var row := UI.hbox(20)
	m.add_child(row)

	var left := UI.vbox(6)
	left.custom_minimum_size = Vector2(390, 0)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	var name_plate := UI.panel(UI.CREAM, 26)
	name_plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_plate.add_child(UI.label(pet.name, 34))
	left.add_child(name_plate)
	_stage = PetStage.new(pet.species, 380)
	left.add_child(_stage)
	_face_row = UI.hbox(10)
	_face_row.custom_minimum_size = Vector2(0, 76)
	left.add_child(_face_row)
	row.add_child(left)

	_thermo_box = UI.vbox(6)
	_thermo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_thermo = Thermometer.new(1)
	_thermo_box.add_child(_thermo)
	_thermo_box.add_child(UI.label("Feeling\nsize", 20, UI.INK))
	_thermo_box.modulate.a = 0.0
	row.add_child(_thermo_box)

	var panel := UI.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)
	var v := UI.vbox(14)
	panel.add_child(v)
	var prompt_row := UI.hbox(12)
	var speak := UI.icon_button("speaker", UI.PAPER, 66)
	speak.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	speak.pressed.connect(func(): Sfx.say(_last_prompt))
	prompt_row.add_child(speak)
	_prompt = UI.text("", 30, UI.INK, false)
	_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prompt.custom_minimum_size = Vector2(0, 120)
	prompt_row.add_child(_prompt)
	v.add_child(prompt_row)
	_content = UI.vbox(14)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_content)

	UI.fade_in(self)
	Sfx.music("story")
	_run()


# --------------------------------------------------------- helpers ----

func t(text: String) -> String:
	return Content.fill(text, pet.name, friend.get("name", "a friend"))


func set_prompt(text: String, speak := true) -> void:
	_last_prompt = text
	_prompt.text = text
	if speak:
		Sfx.say(text)


func _mood_color() -> Color:
	var hot: Color = Content.EMOTIONS[scenario.emotion].color.lightened(0.45)
	var calm: Color = Content.EMOTIONS.calm.color.lightened(0.5)
	return calm.lerp(hot, clampf((level - 1) / 3.0, 0.0, 1.0))


func _clear() -> void:
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()


func _apply_level(animate := true) -> void:
	if animate:
		_thermo.animate_to(level)
		create_tween().tween_property(_bg, "color", _mood_color(), 1.2)
	else:
		_thermo.level = level
		_bg.color = _mood_color()
	_stage.shake = maxf(0.0, (level - 2) * 0.45)
	_stage.stress_color = Content.EMOTIONS[scenario.emotion].color.darkened(0.15)
	var stress_to := clampf((level - 2) / 3.0, 0.0, 1.0)
	if animate:
		create_tween().tween_property(_stage, "stress", stress_to, 1.0)
	else:
		_stage.stress = stress_to
	if level >= 3:
		_stage.play("gesture-negative", true)
	else:
		_stage.play("idle")


func _show_thermo() -> void:
	create_tween().tween_property(_thermo_box, "modulate:a", 1.0, 0.4)


## Big "next" button; resumes when tapped.
func _next(text := "Next", color := UI.LEAF) -> void:
	var b := UI.button(text, color, 32)
	b.custom_minimum_size = Vector2(320, 92)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): _picked.emit(0))
	_content.add_child(b)
	UI.pop(b)
	await _picked
	_clear()


## A list of big answer buttons. All the same colour, so the colour never
## gives the answer away. Returns the index picked. `disabled` are greyed out.
func _choose(options: Array, disabled: Array = []) -> int:
	_clear()
	for i in options.size():
		var b := UI.button(options[i], UI.PAPER, 27, true)
		b.custom_minimum_size = Vector2(0, 92)
		b.disabled = disabled.has(i)
		b.pressed.connect(func(): _picked.emit(i))
		_content.add_child(b)
	var pick: int = await _picked
	return pick


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _show_face(emotion: String) -> void:
	for c in _face_row.get_children():
		c.queue_free()
	_face_row.add_child(Face.new(emotion, 70))
	_face_row.add_child(UI.label(Content.EMOTIONS[emotion].label, 30))


# ------------------------------------------------------------ flow ----

func _run() -> void:
	await get_tree().process_frame
	match mode:
		"practice":
			await _run_practice()
		"activity":
			await _run_activity()
		_:
			await _run_moment()
	Sfx.hush()
	finished.emit()
	queue_free()


func _run_moment() -> void:
	_apply_level(false)
	await _step_story(t(scenario.story), "Uh oh! Let's help")
	await _step_name_feeling()
	if _state.moments_done < 5 or Game.rng.randf() < 0.6:
		await _step_body_clues()
	await _step_size()
	await _calm_down(true)
	if not used_tools.has("thoughts"):
		await _step_helpful_thought()
	await _step_solve()
	if _state.adult.child_checkin and Game.rng.randf() < 0.3:
		await _step_child_checkin()
	var hearts := Director.finish_moment(_state, scenario, int(cfg.get("pet_index", -1)))
	Game.hearts_changed.emit(_state.hearts)
	await _step_reward("You helped %s!" % pet.name, hearts)


func _run_activity() -> void:
	level = 3
	_apply_level(false)
	_show_face("frustrated")
	_show_thermo()
	await _step_story("%s That is SO frustrating, for you AND for %s!" % [cfg.get("story", "Oh no!"), pet.name], "We can handle it")
	set_prompt("Frustrated feelings are OK. Let's calm our bodies together, then try again.")
	await _next("OK")
	await _calm_down(false)
	if _state.adult.child_checkin:
		await _step_child_checkin()
	_stage.play("gesture-positive", true)
	set_prompt(t(scenario.ending))
	await _next("Try again!")


func _run_practice() -> void:
	level = 1
	_apply_level(false)
	var tool_id: String = cfg.get("tool", "balloon")
	set_prompt("Let's practice %s with %s. Practicing when we are calm makes it easier when feelings are big!" % [Content.TECHNIQUES[tool_id].name, pet.name])
	await _next("Let's go")
	await _do_tool(tool_id)
	_state.hearts += 2
	Game.hearts_changed.emit(_state.hearts)
	await _step_reward("Great practicing with %s!" % pet.name, 2)


func _step_story(text: String, button: String) -> void:
	set_prompt(text)
	Sfx.play("oops")
	await _next(button)


func _step_name_feeling() -> void:
	set_prompt("Look at %s. How do you think %s feels?" % [pet.name, pet.name])
	var choices := Director.emotion_choices(scenario, Game.rng)
	var first_try := true
	var buttons: Array[Button] = []
	var row := UI.hbox(16)
	for e in choices:
		var b := UI.button("", UI.PAPER)
		b.custom_minimum_size = Vector2(190, 210)
		var inner := UI.vbox(4)
		UI.full(inner)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := Face.new(e, 110)
		face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(face)
		inner.add_child(UI.label(Content.EMOTIONS[e].label, 24))
		b.add_child(inner)
		b.pressed.connect(func(): _picked.emit(e))
		buttons.append(b)
		row.add_child(b)
	_content.add_child(row)
	while true:
		var pick: String = await _picked
		if Director.emotion_is_right(scenario, pick):
			_state.stats.emotion_total = int(_state.stats.emotion_total) + 1
			if first_try:
				_state.stats.emotion_right = int(_state.stats.emotion_right) + 1
			Sfx.play("good")
			_clear()
			_show_face(pick)
			set_prompt("Yes! %s feels %s. Naming a feeling is the first step to taming it." % [pet.name, Content.EMOTIONS[pick].label.to_lower()])
			await _next()
			return
		first_try = false
		buttons[choices.find(pick)].disabled = true
		Sfx.play("soft")
		set_prompt("Good thinking! But look again. Remember what happened: %s" % t(scenario.story))


func _step_body_clues() -> void:
	var truths: Array = scenario.clues.duplicate()
	Director._shuffle(truths, Game.rng)
	truths = truths.slice(0, 2)
	var wrong := Content.wrong_clues(scenario)
	Director._shuffle(wrong, Game.rng)
	var all: Array = truths + wrong.slice(0, 2)
	Director._shuffle(all, Game.rng)
	set_prompt("Feelings show up in the body. Where does %s feel it? Tap to check!" % pet.name)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content.add_child(grid)
	var found := [0]
	for clue in all:
		var b := UI.button(Content.BODY_CLUES[clue], UI.PAPER, 26, true)
		b.custom_minimum_size = Vector2(300, 100)
		b.pressed.connect(func():
			b.disabled = true
			if truths.has(clue):
				found[0] += 1
				b.add_theme_stylebox_override("disabled", UI.box(Content.EMOTIONS[scenario.emotion].color.lightened(0.2), 26, 7))
				b.add_theme_color_override("font_disabled_color", UI.INK)
				Sfx.play("good")
				_stage.play("gesture-negative", true)
				set_prompt("Yes! %s: \"I feel it! %s.\"" % [pet.name, Content.BODY_CLUES[clue]])
			else:
				Sfx.play("soft")
				set_prompt("%s: \"Hmm, not that one this time.\"" % pet.name)
			if found[0] >= truths.size():
				_picked.emit(0))
		grid.add_child(b)
	await _picked
	await _wait(1.4)
	_clear()
	set_prompt("Those body clues are how %s can tell a big feeling is here. You have body clues too!" % pet.name)
	await _next()


func _step_size() -> void:
	_show_thermo()
	_apply_level()
	var text := "%s's feeling is %s right now." % [pet.name, Content.SIZE_WORDS[level]]
	if _state.moments_done < 4 or Game.rng.randf() < 0.35:
		text += " " + Content.EMOTIONS[scenario.emotion].brain
	set_prompt(text)
	await _wait(1.0)
	await _next("What can we do?")


## Offer tools and do them until the feeling is small. With `with_impulse`,
## the first choice also includes the pet's unsafe urge.
func _calm_down(with_impulse: bool) -> void:
	var first := true
	var guard := 0
	while level >= 3 and guard < 4:
		guard += 1
		var tools := Director.tool_choices(_state, scenario.emotion, Game.rng, 2, used_tools)
		var tool_id: String = tools[0]
		if Director.pet_initiates(_state, tool_id, Game.rng):
			var intro := ("%s says: \"%s\" But wait... %s remembers something!\n\"Can we do %s together?\"" % [pet.name, t(scenario.hot), pet.name, Content.TECHNIQUES[tool_id].name]) if first else ("%s: \"I still feel it a bit. Can we do %s too?\"" % [pet.name, Content.TECHNIQUES[tool_id].name])
			set_prompt(intro)
			await _next("Yes! Let's do it together")
		elif first and with_impulse:
			tool_id = await _choose_with_impulse(tools)
		else:
			if first:
				set_prompt("Which calm tool should we use?")
			else:
				set_prompt("The feeling is smaller, but still there. One tool is not always enough. Let's use one more!")
			var names := tools.map(func(id): return Content.TECHNIQUES[id].name)
			tool_id = tools[await _choose(names)]
			_clear()
		first = false
		await _do_tool(tool_id)
		level = Director.level_after_tool(level)
		_apply_level()
		_stage.play("gesture-positive", true)
		set_prompt("%s: \"Ahhh. My feeling got smaller!\"" % pet.name if level >= 2 else "%s: \"Ahhh. I feel calm now.\"" % pet.name)
		await _wait(1.3)
		await _next()
	_show_face("calm")


func _choose_with_impulse(tools: Array) -> String:
	var intro := "%s says: \"%s\"\n%s wants to: %s. What should we do FIRST?" % [pet.name, t(scenario.hot), pet.name, t(scenario.impulse).to_lower()]
	set_prompt(intro)
	var options: Array = [t(scenario.impulse)]
	for id in tools:
		options.append("Calm down with " + Content.TECHNIQUES[id].name)
	var order := range(options.size())
	Director._shuffle(order, Game.rng)
	var shown := order.map(func(i): return options[i])
	var first_pick := true
	var disabled := []
	while true:
		var pick: int = order[await _choose(shown, disabled)]
		if pick > 0:
			if first_pick:
				_state.stats.tool_picked_first = int(_state.stats.tool_picked_first) + 1
			_clear()
			return tools[pick - 1]
		if first_pick:
			_state.stats.impulse_picked = int(_state.stats.impulse_picked) + 1
		first_pick = false
		disabled.append(order.find(0))
		# Think it through instead of doing it: what would happen next?
		_clear()
		_thermo.animate_to(mini(5, level + 1), 0.8)
		set_prompt("Let's imagine that first...\n%s" % t(scenario.then))
		await _wait(1.0)
		await _next("Hmm...", UI.PAPER)
		_thermo.animate_to(level, 0.8)
		set_prompt("That would make the feeling BIGGER. When a feeling is big, we calm the body first. What should we try?")
	return tools[0]


func _do_tool(tool_id: String) -> void:
	var info: Dictionary = Content.TECHNIQUES[tool_id]
	var skill := _state.stage_of(tool_id)
	_clear()
	if skill <= Content.STAGE_LEARNING and _state.count_of(tool_id) == 0:
		var star := Doodle.new()
		star.kind = "star"
		star.custom_minimum_size = Vector2(90, 90)
		star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_content.add_child(star)
		set_prompt("A new calm tool: %s!\n%s\nLet's teach it to %s." % [info.name, info.how, pet.name])
		await _next("Teach " + pet.name)
	Sfx.music("calm")
	var tech: Technique = load("res://feelings/techniques/%s.gd" % tool_id).new()
	tech.flow = self
	tech.stage = _stage
	tech.pet_name = pet.name
	tech.friend_name = friend.get("name", "a friend")
	tech.skill_stage = skill
	tech.scenario = scenario
	_stage.shake = 0.0
	_stage.play("idle")
	_content.add_child(tech)
	await tech.done
	_clear()
	used_tools.append(tool_id)
	var result := Director.record_practice(_state, tool_id)
	if result.stage_up:
		leveled_tool = tool_id
	if result.unlocked != "":
		unlocked_tool = result.unlocked
	Sfx.music("story")


func _step_helpful_thought() -> void:
	var helpful: String = t(scenario.helpful[Game.rng.randi() % 2])
	var hot: String = t(scenario.hot)
	var options := [hot, helpful]
	if Game.rng.randf() < 0.5:
		options.reverse()
	set_prompt("%s's body is calm, so the thinking brain is back! Which thought will help %s?" % [pet.name, pet.name])
	var disabled := []
	while true:
		var pick := await _choose(options, disabled)
		if options[pick] == helpful:
			break
		disabled.append(pick)
		Sfx.play("soft")
		set_prompt("That is the stormy thought from before. Stormy thoughts make feelings bigger. Try the other one!")
	_clear()
	Sfx.play("good")
	set_prompt("%s: \"%s\"" % [pet.name, helpful])
	await _next()


func _step_solve() -> void:
	var options: Array = [t(scenario.good[0]), t(scenario.good[1]), t(scenario.bad)]
	var order := range(3)
	Director._shuffle(order, Game.rng)
	var shown := order.map(func(i): return options[i])
	set_prompt("Now %s can solve the problem. What is a good idea?" % pet.name)
	var disabled := []
	while true:
		var pick: int = order[await _choose(shown, disabled)]
		if pick < 2:
			break
		disabled.append(order.find(2))
		Sfx.play("soft")
		set_prompt("Hmm. %s What else could %s do?" % [t(scenario.bad_why), pet.name])
	_clear()
	level = 1
	_apply_level()
	_show_face("happy")
	_stage.play("dance")
	Sfx.jingle(0)
	set_prompt(t(scenario.ending))
	await _wait(1.5)
	await _next()
	_stage.play("idle")


## The bridge from the pet to the child: "how about YOU?"
func _step_child_checkin() -> void:
	_clear()
	set_prompt("How about YOU? How big is your feeling right now? Tap a number.")
	var before := await _ask_child_size()
	var after := 0
	if before >= 3:
		var tools := Director.tool_choices(_state, "frustrated", Game.rng, 1)
		var tool_id: String = tools[0]
		set_prompt("Thank you for telling me. That is a pretty big feeling. Want to do %s with %s, just for you?" % [Content.TECHNIQUES[tool_id].name, pet.name])
		if await _choose(["Yes, let's do it", "Not right now"]) == 0:
			await _do_tool(tool_id)
			set_prompt("How big is your feeling now?")
			after = await _ask_child_size()
			set_prompt("You checked in with your body and used a calm tool. That is what strong helpers do!")
		else:
			_clear()
			set_prompt("That's OK. You can always tap Calm Tools when you want one.")
		await _next()
	else:
		set_prompt("Thanks for checking in with your body!")
		await _next()
	Director.note_child_checkin(_state, before, after)


func _ask_child_size() -> int:
	_clear()
	var row := UI.hbox(30)
	var thermo := Thermometer.new(1, true)
	thermo.custom_minimum_size = Vector2(130, 340)
	row.add_child(thermo)
	var col := UI.vbox(12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var word := UI.label("Tiny", 40)
	word.custom_minimum_size = Vector2(240, 0)
	col.add_child(word)
	var ok := UI.button("That's it", UI.LEAF, 30)
	ok.custom_minimum_size = Vector2(240, 92)
	ok.disabled = true
	col.add_child(ok)
	row.add_child(col)
	_content.add_child(row)
	thermo.picked.connect(func(l: int):
		word.text = Content.SIZE_WORDS[l]
		ok.disabled = false)
	ok.pressed.connect(func(): _picked.emit(0))
	await _picked
	var result := int(thermo.level)
	_clear()
	return result


func _step_reward(title: String, hearts: int) -> void:
	_clear()
	_stage.play("dance")
	Sfx.jingle(3)
	var row := UI.hbox(10)
	var h := Doodle.new()
	h.kind = "heart"
	h.custom_minimum_size = Vector2(80, 80)
	row.add_child(h)
	row.add_child(UI.label("+%d" % hearts, 60))
	_content.add_child(row)
	UI.pop(row)
	var text := title
	if unlocked_tool != "":
		text += "\nNew calm tool in your toolbox: %s!" % Content.TECHNIQUES[unlocked_tool].name
	elif leveled_tool != "":
		text += "\n%s is getting really good at %s!" % [pet.name, Content.TECHNIQUES[leveled_tool].name]
	set_prompt(text)
	await _next("Yay!")

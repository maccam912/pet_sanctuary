extends Technique
## Look Around: sensory grounding (a child-sized 5-4-3-2-1). Worries live in
## "what if"; noticing what you can see, hear and feel brings you back to now.

const SOUNDS := [["chime", "a tinkly sound"], ["soft", "a plucky sound"], ["bell", "a deep bell sound"]]

var see_goal := 5
var seen := 0
var heard := 0
var sound_playing := false
var hold_time := 0.0
var holding := false
var _box: VBoxContainer
var _bar: ProgressBar
var phase := "see"


func begin() -> void:
	see_goal = 3 if learned() else 5
	_box = UI.vbox(14)
	UI.full(_box)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	_start_see()


func _reset() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func _start_see() -> void:
	tell("Let's look around with %s. Find %d things you can SEE. Tap them!" % [pet_name, see_goal])
	var items := Content.LOOK_ITEMS.duplicate()
	items.shuffle()
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for i in 8:
		var item: Array = items[i]
		var b := UI.button("", UI.WHITE)
		b.custom_minimum_size = Vector2(140, 140)
		var icon := UI.food_icon(item[0], 110)
		UI.full(icon)
		icon.offset_bottom = -10
		b.add_child(icon)
		b.pressed.connect(func():
			if phase != "see":
				return
			b.disabled = true
			b.add_theme_stylebox_override("disabled", UI.box(UI.PINK.lightened(0.3), 26, 7))
			seen += 1
			tell("%s: \"I see %s!\"  (%d of %d)" % [pet_name, item[1], seen, see_goal])
			if seen >= see_goal:
				phase = "wait"
				await get_tree().create_timer(1.6).timeout
				_start_hear())
		grid.add_child(b)
	_box.add_child(grid)


func _start_hear() -> void:
	_reset()
	phase = "hear"
	tell("Now use your ears. Be very quiet... Tap the ear each time you HEAR a sound.")
	var ear := UI.icon_button("ear", UI.PINK.lightened(0.2), 220)
	ear.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ear.pressed.connect(func():
		if not sound_playing:
			return
		sound_playing = false
		heard += 1
		tell("%s: \"I heard %s!\"  (%d of 3)" % [pet_name, SOUNDS[heard - 1][1], heard])
		if heard >= 3:
			phase = "wait"
			await get_tree().create_timer(1.6).timeout
			_start_feel()
		else:
			_queue_sound())
	_box.add_child(ear)
	_queue_sound(3.5)


func _queue_sound(delay := 0.0) -> void:
	await get_tree().create_timer(delay + randf_range(1.6, 3.0)).timeout
	if phase != "hear" or _finished:
		return
	Sfx.hush()
	Sfx.play(SOUNDS[heard][0])
	sound_playing = true


func _start_feel() -> void:
	_reset()
	phase = "feel"
	tell("Last one. FEEL your feet on the floor. Press them down, and hold the button while you take a slow breath.")
	var foot := UI.icon_button("foot", UI.PINK.lightened(0.2), 200)
	foot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	foot.button_down.connect(func(): holding = true)
	foot.button_up.connect(func(): holding = false)
	_box.add_child(foot)
	_bar = ProgressBar.new()
	_bar.max_value = 5.0
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(360, 30)
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(_bar)


func _process(delta: float) -> void:
	if phase != "feel" or _finished:
		return
	if holding:
		hold_time += delta
	_bar.value = hold_time
	if stage:
		stage.breath = 1.0 + sin(hold_time / 5.0 * PI) * 0.1
	if hold_time >= 5.0:
		tell("%s: \"I am right here, right now, and I am safe.\"" % pet_name)
		finish()

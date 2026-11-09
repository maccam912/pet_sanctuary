extends Technique
## Helpful Thoughts: catch the stormy thought, shrink it, and swap in a thought
## that is true AND helpful (cognitive reappraisal / coping self-talk).

const OTHER_STORMY := ["Everything is the WORST!", "Nothing will ever be OK!", "I can't handle anything!"]

var taps := 0
var _box: VBoxContainer
var _cloud: Button


func begin() -> void:
	_box = UI.vbox(14)
	UI.full(_box)
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_box)
	var hot := Content.fill(scenario.hot, pet_name, friend_name)
	tell("%s has a stormy thought: \"%s\" Is it helping? Tap the storm cloud to shrink it!" % [pet_name, hot])
	_cloud = UI.button(hot, Color("9aa3b8"), 30, true)
	_cloud.custom_minimum_size = Vector2(460, 220)
	_cloud.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cloud.add_theme_color_override("font_color", UI.WHITE)
	_cloud.add_theme_color_override("font_hover_color", UI.WHITE)
	_cloud.add_theme_color_override("font_pressed_color", UI.WHITE)
	_cloud.pressed.connect(_shrink)
	_box.add_child(_cloud)


func _shrink() -> void:
	taps += 1
	Sfx.play("down", 0.8 + taps * 0.15)
	_cloud.pivot_offset = _cloud.size / 2.0
	var target := 1.0 - taps * 0.22
	create_tween().tween_property(_cloud, "scale", Vector2.ONE * target, 0.2).set_trans(Tween.TRANS_BACK)
	if stage:
		stage.shake = maxf(0.0, 0.6 - taps * 0.2)
	if taps >= 4:
		_cloud.disabled = true
		await get_tree().create_timer(0.35).timeout
		_pick_helpful()


func _pick_helpful() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	tell("The stormy thought is tiny now. Which thought would HELP %s?" % pet_name)
	var options: Array = [
		[Content.fill(scenario.helpful[0], pet_name, friend_name), true],
		[Content.fill(scenario.helpful[1], pet_name, friend_name), true],
		[OTHER_STORMY[randi() % OTHER_STORMY.size()], false],
	]
	options.shuffle()
	for o in options:
		var b := UI.button(o[0], UI.PAPER, 26, true)
		b.custom_minimum_size = Vector2(0, 92)
		b.pressed.connect(func():
			if o[1]:
				_say_it(o[0])
			else:
				b.disabled = true
				Sfx.play("soft")
				tell("Hmm, that is another stormy thought. Would it make the feeling smaller? Try another one."))
		_box.add_child(b)


func _say_it(thought: String) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	Sfx.play("good")
	var sun := UI.panel(UI.SUN, 40)
	sun.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var l := UI.text(thought, 32)
	l.custom_minimum_size = Vector2(480, 120)
	sun.add_child(l)
	_box.add_child(sun)
	UI.pop(sun)
	tell("A helpful thought! Say it out loud with %s: \"%s\"" % [pet_name, thought])
	var b := UI.button("We said it!", UI.LEAF, 30)
	b.custom_minimum_size = Vector2(300, 92)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		b.disabled = true
		if stage:
			stage.play("gesture-positive", true)
		finish())
	_box.add_child(b)

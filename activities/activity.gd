class_name Activity
extends Control
## Shared frame for the mini-games: a buddy pet on the left, play area on the
## right. Games can stage a small setback and then calm down with the buddy.

signal finished(hearts: int)

var host: Sanctuary
var buddy := {"species": "dog", "name": "Biscuit"}
var activity_id := ""
var title := "Game"
var stage: PetStage
var area: Control
var _status: Label


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop(Color("cdeccf")))
	var m := MarginContainer.new()
	UI.full(m)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	add_child(m)
	var row := UI.hbox(18)
	m.add_child(row)
	var left := UI.vbox(8)
	left.custom_minimum_size = Vector2(300, 0)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	var plate := UI.panel(UI.CREAM, 24)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.add_child(UI.label(buddy.name, 30))
	left.add_child(plate)
	stage = PetStage.new(buddy.species, 300, buddy.get("look", ""))
	left.add_child(stage)
	_status = UI.text("", 26)
	_status.custom_minimum_size = Vector2(280, 120)
	left.add_child(_status)
	row.add_child(left)
	var panel := UI.panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)
	var v := UI.vbox(10)
	panel.add_child(v)
	var head := UI.hbox()
	var t := UI.label(title, 34, UI.INK, false)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := UI.icon_button("x", UI.PAPER, 64)
	x.pressed.connect(func(): close(0))
	head.add_child(x)
	v.add_child(head)
	area = Control.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.clip_contents = true
	v.add_child(area)
	UI.fade_in(self)
	await get_tree().process_frame
	await get_tree().process_frame
	start()


func start() -> void:
	pass


func say(text: String, speak := true) -> void:
	_status.text = text
	if speak:
		Sfx.say(text)


func close(hearts: int) -> void:
	Sfx.hush()
	finished.emit(hearts)
	queue_free()


## Ask the director whether this play should include a staged setback.
func wants_setback() -> bool:
	return Director.frustration_event(Game.state, activity_id, Game.rng)


## Something went wrong on purpose: calm down together with the buddy pet.
func calm(what_happened: String) -> void:
	stage.play("gesture-negative", true)
	Sfx.play("oops")
	Sfx.animal(buddy.species, "frustrated")
	await get_tree().create_timer(0.9).timeout
	await host.calm_together(what_happened, buddy)
	stage.play("idle")


func win(hearts: int, message: String) -> void:
	for c in area.get_children():
		c.queue_free()
	stage.play("dance")
	Sfx.jingle(4)
	Sfx.animal(buddy.species, "happy")
	say(message)
	var v := UI.vbox(16)
	UI.full(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var row := UI.hbox(10)
	var h := Doodle.new()
	h.kind = "heart"
	h.custom_minimum_size = Vector2(90, 90)
	row.add_child(h)
	row.add_child(UI.label("+%d" % hearts, 64))
	v.add_child(row)
	var b := UI.button("Hooray!", UI.LEAF, 34)
	b.custom_minimum_size = Vector2(300, 100)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): close(hearts))
	v.add_child(b)
	area.add_child(v)
	UI.pop(b)

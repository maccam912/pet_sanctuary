class_name PetNamer
extends Control
## Names one pet: the pet on its little stage, a name box and an OK button.
## Used to rename a pet and when a grown-up adds one. Emits `done` with the
## cleaned name, or "" if Back was tapped.

signal done(pet_name: String)

var pet := {}
var prompt := ""
var ok_text := ""
var _name_edit: LineEdit


## `pet_info` needs species, look and name (the name the box starts with).
func _init(pet_info: Dictionary = {}, ask := "", ok := "Done") -> void:
	pet = pet_info
	prompt = ask
	ok_text = ok


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	var v := UI.vbox(14)
	var stage := PetStage.new(pet.species, 280, pet.get("look", ""))
	stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stage)
	v.add_child(UI.text(prompt, 32))
	_name_edit = UI.name_edit(pet.name)
	_name_edit.text_submitted.connect(func(_t): confirm())
	v.add_child(_name_edit)
	v.add_child(UI.label("Tap the name to change it.", 20, UI.INK_SOFT))
	var row := UI.hbox(14)
	var back := UI.button("Back", UI.PAPER, 24)
	back.custom_minimum_size = Vector2(160, 84)
	back.pressed.connect(func(): _finish(""))
	row.add_child(back)
	var ok := UI.button(ok_text, UI.LEAF, 32)
	ok.custom_minimum_size = Vector2(300, 84)
	ok.pressed.connect(confirm)
	row.add_child(ok)
	v.add_child(row)
	var holder := UI.centered(v, Vector2(640, 0))
	add_child(holder)
	UI.fade_in(holder, 0.15)
	stage.play.call_deferred("gesture-positive", true)
	Sfx.animal(pet.species, "happy")
	Sfx.say(prompt)


func confirm() -> void:
	_finish(GameState.clean_name(_name_edit.text, pet.name))


func _finish(pet_name: String) -> void:
	Sfx.hush()
	done.emit(pet_name)
	queue_free()

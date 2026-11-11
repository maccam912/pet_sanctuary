class_name FriendPicker
extends Control
## A new friend is coming: the child chooses which animal to invite, then gives
## it a name. Emits `done` with the offer ({species, look, name}), or {} if the
## child would rather wait.

signal done(choice: Dictionary)

var offers: Array = []
var _holder: Control
var _name_edit: LineEdit


func _init(arrival_offers: Array = []) -> void:
	offers = arrival_offers


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	_show_offers()
	Sfx.jingle(1)


func _swap(content: Control, width: float) -> void:
	if _holder:
		_holder.queue_free()
	_holder = UI.centered(content, Vector2(width, 0))
	add_child(_holder)
	UI.fade_in(_holder, 0.15)


func _show_offers() -> void:
	var v := UI.vbox(14)
	var msg := "A new friend wants to move in! Who should we invite?"
	v.add_child(UI.label(msg, 34))
	var row := UI.hbox(18)
	for i in offers.size():
		var offer: Dictionary = offers[i]
		var card := UI.panel(UI.PAPER, 28)
		var col := UI.vbox(6)
		card.add_child(col)
		var stage := PetStage.new(offer.species, 250, offer.look)
		stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(stage)
		col.add_child(UI.label(offer.name, 30))
		var pet_trait := Content.trait_of(offer.species)
		col.add_child(UI.label(Content.TRAIT_LABELS.get(pet_trait, " "), 18, UI.INK_SOFT))
		var pick := UI.button("Pick me!", [UI.SUN, UI.SKY, UI.PINK][i % 3], 28)
		pick.pressed.connect(choose.bind(i))
		col.add_child(pick)
		row.add_child(card)
	v.add_child(row)
	var later := UI.button("Not now", UI.PAPER, 24)
	later.custom_minimum_size = Vector2(200, 70)
	later.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	later.pressed.connect(func(): _finish({}))
	v.add_child(later)
	_swap(v, 980)
	Sfx.say(msg)


## Step two: name the chosen friend.
func choose(index: int) -> void:
	var offer: Dictionary = offers[index]
	Sfx.animal(offer.species, "happy")
	var v := UI.vbox(14)
	var stage := PetStage.new(offer.species, 280, offer.look)
	stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(stage)
	var msg := "What is your new friend's name?"
	v.add_child(UI.label(msg, 32))
	_name_edit = UI.name_edit(offer.name)
	v.add_child(_name_edit)
	v.add_child(UI.label("Tap the name to change it.", 20, UI.INK_SOFT))
	var row := UI.hbox(14)
	var back := UI.button("Back", UI.PAPER, 24)
	back.custom_minimum_size = Vector2(160, 84)
	back.pressed.connect(_show_offers)
	row.add_child(back)
	var ok := UI.button("Welcome!", UI.LEAF, 32)
	ok.custom_minimum_size = Vector2(300, 84)
	ok.pressed.connect(func(): confirm(index))
	row.add_child(ok)
	v.add_child(row)
	_swap(v, 640)
	stage.play.call_deferred("gesture-positive", true)
	Sfx.say(msg)


func confirm(index: int) -> void:
	var choice: Dictionary = offers[index].duplicate()
	choice.name = GameState.clean_name(_name_edit.text if _name_edit else "", choice.name)
	_finish(choice)


func _finish(choice: Dictionary) -> void:
	Sfx.hush()
	done.emit(choice)
	queue_free()

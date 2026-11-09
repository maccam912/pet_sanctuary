class_name CardGame
extends Activity
## Match Cards: find the six pairs of pet friends.
## On a "tricky moment" the face-down cards get mixed up part-way through.

var cards: Array = []     # each {species, button, icon, back, up, matched}
var first := -1
var locked := false
var pairs := 0
var setback := false
var _grid: GridContainer


func _init() -> void:
	title = "Match Cards"


func start() -> void:
	setback = wants_setback()
	var species := Content.SPECIES.keys()
	species.shuffle()
	var deck := []
	for i in 6:
		deck.append(species[i])
		deck.append(species[i])
	deck.shuffle()
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	var cc := CenterContainer.new()
	UI.full(cc)
	cc.add_child(_grid)
	area.add_child(cc)
	for i in deck.size():
		var b := UI.button("", UI.SKY)
		b.custom_minimum_size = Vector2(136, 136)
		var icon := UI.pet_icon(deck[i], 110)
		UI.full(icon)
		icon.offset_bottom = -10
		icon.visible = false
		b.add_child(icon)
		var back := Doodle.new()
		back.kind = "paw"
		back.tint = UI.SKY.darkened(0.25)
		UI.full(back)
		back.offset_left = 36
		back.offset_right = -36
		back.offset_top = 30
		back.offset_bottom = -42
		b.add_child(back)
		b.pressed.connect(_flip.bind(i))
		_grid.add_child(b)
		cards.append({"species": deck[i], "button": b, "icon": icon, "back": back, "up": false, "matched": false})
	say("Find the matching friends with %s!" % buddy.name)


func _show(i: int, up: bool) -> void:
	var c: Dictionary = cards[i]
	c.up = up
	c.icon.visible = up
	c.back.visible = not up
	UI.recolor(c.button, UI.CREAM if up else UI.SKY)


func _flip(i: int) -> void:
	if locked or cards[i].up or cards[i].matched:
		return
	_show(i, true)
	Sfx.play("pop", 1.2)
	if first < 0:
		first = i
		return
	var a := first
	first = -1
	if cards[a].species == cards[i].species:
		cards[a].matched = true
		cards[i].matched = true
		pairs += 1
		Sfx.play("good")
		stage.play("gesture-positive", true)
		say("A match! %d of 6" % pairs, false)
		if pairs >= 6:
			locked = true
			await get_tree().create_timer(0.8).timeout
			win(5, "You found all the friends!")
		elif setback and pairs == 2:
			setback = false
			_mix_up()
		return
	locked = true
	await get_tree().create_timer(1.0).timeout
	_show(a, false)
	_show(i, false)
	locked = false


func _mix_up() -> void:
	locked = true
	await get_tree().create_timer(0.7).timeout
	Sfx.play("up")
	# Shuffle which animal sits under each unmatched card.
	var open := []
	for i in cards.size():
		if not cards[i].matched:
			open.append(i)
	var species := open.map(func(i): return cards[i].species)
	species.shuffle()
	for n in open.size():
		var c: Dictionary = cards[open[n]]
		c.species = species[n]
		c.icon.texture = load("res://assets/pet_icons/animal-%s.png" % species[n])
		var tw := create_tween()
		tw.tween_property(c.button, "modulate:a", 0.2, 0.25)
		tw.tween_property(c.button, "modulate:a", 1.0, 0.25)
	await calm("ACHOO! %s sneezed, and all the cards got mixed up." % buddy.name)
	say("OK. Calm brains remember better. Let's find them again!")
	locked = false

class_name DigGame
extends Activity
## Treasure Dig: a treat is buried under one of the mounds. A wrong dig is not
## a fail: it says how close you are (Hot / Warm / Cold). The buddy wants to
## get it right first time; the game shows that misses are how you find out.

const COLS := 5
const ROWS := 4
const ROUNDS := 3
const DIRT := Color("c9a27a")

var round_index := 0
var treasure := 0
var misses := 0         # in this round
var total_misses := 0
var cells: Array[Button] = []
var locked := true
var _grid: GridContainer


func _init() -> void:
	title = "Treasure Dig"


func start() -> void:
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	var cc := CenterContainer.new()
	UI.full(cc)
	cc.add_child(_grid)
	area.add_child(cc)
	say("A treat is hiding! %s wants to find it on the first try. But nobody can know where it is. Let's dig for clues!" % buddy.name)
	_next_round()


func _next_round() -> void:
	for c in _grid.get_children():
		c.queue_free()
	cells.clear()
	misses = 0
	treasure = Game.rng.randi() % (COLS * ROWS)
	for i in COLS * ROWS:
		var b := UI.button("", DIRT, 24)
		b.custom_minimum_size = Vector2(124, 112)
		b.add_theme_color_override("font_disabled_color", UI.INK)
		b.pressed.connect(dig.bind(i))
		_grid.add_child(b)
		cells.append(b)
	locked = false


## How many steps from this mound to the treat (diagonals count as one).
func steps_away(i: int) -> int:
	return maxi(absi(i % COLS - treasure % COLS), absi(i / COLS - treasure / COLS))


func dig(i: int) -> void:
	if locked or cells[i].disabled:
		return
	var b := cells[i]
	b.disabled = true
	var d := steps_away(i)
	if d == 0:
		locked = true
		b.add_theme_stylebox_override("disabled", UI.box(UI.CREAM, 26, 7))
		var icon := UI.food_icon(Content.FOODS[Game.rng.randi() % Content.FOODS.size()], 90)
		UI.full(icon)
		icon.offset_bottom = -8
		b.add_child(icon)
		Sfx.play("great")
		stage.play("eat", true)
		total_misses += misses
		round_index += 1
		if misses == 0:
			say("Wow, a lucky first dig!")
		else:
			say("Found it! The misses showed us the way.")
		await get_tree().create_timer(1.8).timeout
		if round_index >= ROUNDS:
			win(5, "Every miss was a clue. Mistakes help us learn!")
		else:
			say("Another treat is hiding. Dig for clues!")
			_next_round()
		return
	misses += 1
	Sfx.play("pop", 0.8)
	var clue: String = ["", "Hot!", "Warm", "Cold"][mini(d, 3)]
	var color: Color = [UI.CREAM, UI.CORAL, UI.SUN, UI.SKY][mini(d, 3)]
	b.text = clue
	b.add_theme_stylebox_override("disabled", UI.box(color, 26, 7))
	if misses == 1 and round_index == 0:
		stage.play("gesture-negative", true)
		say("%s: \"Oh no, we missed!\" That's OK. A miss is a clue. %s" % [buddy.name, _hint(d)])
	else:
		say(_hint(d))


func _hint(d: int) -> String:
	match d:
		1: return "Hot! The treat is right next to it."
		2: return "Warm. We are getting close!"
	return "Cold. Now we know it is far from there."

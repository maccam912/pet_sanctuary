class_name ArtGame
extends Activity
## Oops Art: the buddy is painting when SPLAT, a blob of paint lands on the
## picture. Tap the splat and turn it into something. Every "mistake" ends up
## as part of the painting: it does not have to be perfect to be good.

const SPLATS := 5
const COLORS := [UI.CORAL, UI.SKY, UI.SUN, UI.LAVENDER, UI.PINK, Color("ff9f5a")]
const THINGS := {"flower": "A flower", "fish": "A fish", "balloon": "A balloon",
	"butterfly": "A butterfly", "ladybug": "A ladybug", "tree": "A tree"}
const STORMY := "It has to be perfect!"
const HELPFUL := "Oops is OK. Let's make it into something!"

var items: Array = []      # each {pos, r, color, kind} where kind "" is a splat
var fixed := 0
var waiting_tap := false   # a splat is waiting to be tapped
var _canvas: Control
var _choices: HBoxContainer


func _init() -> void:
	title = "Oops Art"


func start() -> void:
	_canvas = Control.new()
	UI.full(_canvas)
	_canvas.offset_bottom = -112
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_picture)
	_canvas.gui_input.connect(_on_input)
	area.add_child(_canvas)
	_choices = UI.hbox(12)
	_choices.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_choices.offset_top = -100
	area.add_child(_choices)
	say("%s is painting a picture. It is going to be PERFECT..." % buddy.name)
	await get_tree().create_timer(2.6).timeout
	_splat()


func _splat() -> void:
	var size := _canvas.size
	var pos := Vector2.ZERO
	for attempt in 30:
		pos = Vector2(Game.rng.randf_range(90.0, size.x - 90.0), Game.rng.randf_range(80.0, size.y - 150.0))
		if not items.any(func(it): return it.pos.distance_to(pos) < 150.0):
			break
	items.append({"pos": pos, "r": Game.rng.randf_range(40.0, 52.0), "color": COLORS[items.size() % COLORS.size()], "kind": ""})
	_canvas.queue_redraw()
	Sfx.play("thud", 1.3)
	stage.play("gesture-negative", true)
	if fixed > 0:
		say("SPLAT! Another oops. Tap it. What could it be?")
		waiting_tap = true
		return
	Sfx.animal(buddy.species, "frustrated")
	say("SPLAT! A blob of paint! %s: \"Oh no! It's ruined!\" What can we tell %s?" % [buddy.name, buddy.name])
	var options := [STORMY, HELPFUL]
	if Game.rng.randf() < 0.5:
		options.reverse()
	for text in options:
		var b := UI.button(text, UI.PAPER, 24, true)
		b.custom_minimum_size = Vector2(360, 96)
		b.pressed.connect(tell.bind(text, b))
		_choices.add_child(b)


## The first splat: swap the stormy thought for a helpful one.
func tell(text: String, button: Button = null) -> void:
	if text == STORMY:
		if button:
			button.disabled = true
		Sfx.play("soft")
		say("That stormy thought makes the feeling bigger. Try the other one!")
		return
	_clear_choices()
	Sfx.play("good")
	stage.play("gesture-positive", true)
	say("Good thinking! Tap the splat. What could it be?")
	waiting_tap = true


func _clear_choices() -> void:
	for c in _choices.get_children():
		c.queue_free()


func _on_input(event: InputEvent) -> void:
	if not waiting_tap or not (event is InputEventMouseButton and event.pressed):
		return
	var splat: Dictionary = items[-1]
	if event.position.distance_to(splat.pos) < splat.r + 45.0:
		offer()


## Three ideas for what the newest splat could turn into.
func offer() -> void:
	waiting_tap = false
	Sfx.play("pop")
	var kinds := THINGS.keys()
	Director._shuffle(kinds, Game.rng)
	for kind in kinds.slice(0, 3):
		var b := UI.button(THINGS[kind], UI.PAPER, 26)
		b.custom_minimum_size = Vector2(240, 96)
		b.pressed.connect(make.bind(kind))
		_choices.add_child(b)


func make(kind: String) -> void:
	_clear_choices()
	items[-1].kind = kind
	_canvas.queue_redraw()
	fixed += 1
	Sfx.play("good")
	stage.play("gesture-positive", true)
	say("%s: \"Ooh! %s. I love it!\"" % [buddy.name, THINGS[kind]])
	await get_tree().create_timer(2.0).timeout
	if fixed < SPLATS:
		_splat()
		return
	say("All done! Nobody planned it, and look how good it is.")
	var b := UI.button("Hang it up!", UI.LEAF, 30)
	b.custom_minimum_size = Vector2(320, 96)
	b.pressed.connect(func(): win(4, "It did not have to be perfect to be great!"))
	_choices.add_child(b)
	UI.pop(b)


# ---------------------------------------------------------- drawing ----

func _draw_picture() -> void:
	var c := _canvas
	var paper := Rect2(Vector2.ZERO, c.size)
	c.draw_style_box(UI.box(UI.WHITE, 22), paper)
	c.draw_style_box(UI.box(Color("d9f0ff"), 22), Rect2(8, 8, c.size.x - 16, c.size.y - 16))
	c.draw_rect(Rect2(8, c.size.y - 96, c.size.x - 16, 74), Color("bfe6a6"))
	c.draw_style_box(UI.box(Color("bfe6a6"), 22), Rect2(8, c.size.y - 60, c.size.x - 16, 52))
	for it in items:
		_draw_item(it)


func _draw_item(it: Dictionary) -> void:
	var c := _canvas
	var p: Vector2 = it.pos
	var r: float = it.r
	var col: Color = it.color
	var ink := UI.INK
	match it.kind:
		"":
			c.draw_circle(p, r, col)
			for i in 7:
				var a := i * 0.9 + r
				var d := r * (1.0 + 0.3 * absf(sin(i * 2.3 + r)))
				c.draw_circle(p + Vector2.from_angle(a) * d, r * (0.24 + 0.1 * cos(i * 1.7)), col)
		"flower":
			c.draw_line(p, p + Vector2(0, r * 2.4), UI.LEAF.darkened(0.15), 8.0, true)
			for i in 6:
				c.draw_circle(p + Vector2.from_angle(i * TAU / 6.0) * r * 0.62, r * 0.46, col)
			c.draw_circle(p, r * 0.38, UI.SUN)
		"fish":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(r * 0.9, 0), p + Vector2(r * 1.8, -r * 0.7), p + Vector2(r * 1.8, r * 0.7)]), col.darkened(0.1))
			c.draw_set_transform(p, 0.0, Vector2(1.35, 0.9))
			c.draw_circle(Vector2.ZERO, r, col)
			c.draw_set_transform(Vector2.ZERO)
			c.draw_circle(p + Vector2(-r * 0.7, -r * 0.2), r * 0.2, UI.WHITE)
			c.draw_circle(p + Vector2(-r * 0.74, -r * 0.2), r * 0.1, ink)
		"balloon":
			var string := PackedVector2Array()
			for i in 9:
				string.append(p + Vector2(sin(i * 1.1) * 7.0, r + i * r * 0.28))
			c.draw_polyline(string, ink, 3.0, true)
			c.draw_circle(p, r, col)
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, r - 4), p + Vector2(-9, r + 12), p + Vector2(9, r + 12)]), col.darkened(0.1))
			c.draw_circle(p + Vector2(-r * 0.35, -r * 0.35), r * 0.18, Color(1, 1, 1, 0.6))
		"butterfly":
			for side: float in [-1.0, 1.0]:
				c.draw_circle(p + Vector2(side * r * 0.6, -r * 0.3), r * 0.62, col)
				c.draw_circle(p + Vector2(side * r * 0.48, r * 0.45), r * 0.44, col.lightened(0.2))
				c.draw_line(p + Vector2(0, -r * 0.6), p + Vector2(side * r * 0.35, -r * 1.15), ink, 3.0, true)
			c.draw_line(p + Vector2(0, -r * 0.7), p + Vector2(0, r * 0.75), ink, 9.0, true)
		"ladybug":
			c.draw_circle(p + Vector2(0, -r * 0.75), r * 0.42, ink)
			c.draw_circle(p, r * 0.9, col)
			c.draw_line(p + Vector2(0, -r * 0.9), p + Vector2(0, r * 0.9), ink, 4.0, true)
			for d in [Vector2(-0.4, -0.3), Vector2(0.4, -0.3), Vector2(-0.45, 0.35), Vector2(0.45, 0.35)]:
				c.draw_circle(p + d * r, r * 0.15, ink)
		"tree":
			c.draw_rect(Rect2(p + Vector2(-r * 0.18, r * 0.4), Vector2(r * 0.36, r * 1.7)), Color("a9764f"))
			c.draw_circle(p + Vector2(-r * 0.5, r * 0.1), r * 0.62, col)
			c.draw_circle(p + Vector2(r * 0.5, r * 0.1), r * 0.62, col)
			c.draw_circle(p + Vector2(0, -r * 0.4), r * 0.75, col)

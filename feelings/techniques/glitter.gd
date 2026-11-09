extends Technique
## Glitter Jar Break: a calm-down break with something quiet to watch. Shake
## the jar (like a stirred-up feeling), then hands off until it all settles.

const JAR := Vector2(250, 330)
const COLORS := [Color("ffd166"), Color("f2a6c8"), Color("b9a6f0"), Color("8ed1f0"), Color("ffffff")]

var phase := "shake"  # shake, settle
var shaken := 0.0
var dragging := false
var bits: Array = []   # each: {p: Vector2 (0..1 in jar), v: Vector2, c: Color, rest: float, s: float}
var quiet := 0.0


func begin() -> void:
	for i in 90:
		bits.append({"p": Vector2(randf(), randf_range(0.8, 1.0)), "v": Vector2.ZERO, "c": COLORS[i % COLORS.size()],
			"rest": randf_range(0.86, 0.99), "s": randf_range(0.055, 0.1)})
	tell("Time for a calm break with %s. First, shake the jar! Slide your finger all around." % pet_name)


func _gui_input(event: InputEvent) -> void:
	if _finished:
		return
	var pressed = press_state(event)
	if pressed != null:
		dragging = pressed
		if pressed and phase == "settle":
			_stir(0.5)
			quiet = 0.0
			tell("Oops, hands off! Let the glitter settle all by itself.", false)
	elif event is InputEventMouseMotion and dragging:
		var amount: float = event.relative.length()
		if phase == "shake":
			shaken += amount / 1400.0
			_stir(clampf(amount / 40.0, 0.1, 1.0))
			if shaken >= 1.0:
				phase = "settle"
				dragging = false
				Sfx.play("chime")
				tell("That is what a big feeling looks like inside! Now hands off. Watch quietly with %s until it all settles." % pet_name)
		else:
			_stir(0.3)
			quiet = 0.0


func _stir(power: float) -> void:
	for b in bits:
		b.v += Vector2(randf_range(-1.2, 1.2), randf_range(-1.6, 0.6)) * power


func _process(delta: float) -> void:
	if _finished:
		return
	var settled := 0
	for b in bits:
		b.v.y += b.s * delta * 2.0
		b.v *= pow(0.12, delta)
		b.v.y = maxf(b.v.y, -2.0)
		if phase == "settle" and absf(b.v.x) < 0.05:
			b.v.y = maxf(b.v.y, b.s)
		b.p += b.v * delta
		if b.p.x < 0.03 or b.p.x > 0.97:
			b.v.x = -b.v.x
			b.p.x = clampf(b.p.x, 0.03, 0.97)
		if b.p.y < 0.03:
			b.p.y = 0.03
			b.v.y = absf(b.v.y)
		if b.p.y >= b.rest:
			b.p.y = b.rest
			b.v = Vector2.ZERO
			settled += 1
	if phase == "settle":
		quiet += delta
		if stage:
			stage.breath = 1.0 + sin(quiet * 1.2) * 0.03
		if settled >= bits.size() - 2 and quiet > 6.0:
			tell("All settled. %s: \"My mind feels clear again, just like the jar.\"" % pet_name)
			finish()
	queue_redraw()


func _draw() -> void:
	var origin := Vector2(size.x / 2.0 - JAR.x / 2.0, size.y / 2.0 - JAR.y / 2.0 + 10.0)
	var glass := StyleBoxFlat.new()
	glass.bg_color = Color("d9f1fb")
	glass.set_corner_radius_all(46)
	glass.set_border_width_all(7)
	glass.border_color = UI.INK_SOFT.lightened(0.3)
	draw_style_box(glass, Rect2(origin, JAR))
	var lid := StyleBoxFlat.new()
	lid.bg_color = UI.LAVENDER.darkened(0.1)
	lid.set_corner_radius_all(12)
	draw_style_box(lid, Rect2(origin + Vector2(30, -26), Vector2(JAR.x - 60, 36)))
	for b in bits:
		var p: Vector2 = origin + Vector2(14, 14) + b.p * (JAR - Vector2(28, 28))
		draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), b.c)
	if phase == "shake":
		draw_arc(origin + JAR / 2.0, 215.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(shaken, 0.0, 1.0), 48, UI.LAVENDER, 12.0, true)

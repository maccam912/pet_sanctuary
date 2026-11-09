extends Technique
## Slow Stretch: follow the sun slowly up and over, like reaching tall as a tree.
## The sun only moves at a slow pace, and only while your finger stays with it.

const ARC_TIME := 7.0

var total := 3
var arcs := 0
var u := 0.0            # 0..1 along the current arc
var finger := Vector2(-999, -999)
var down := false
var pulse := 0.0
var told_slow := false


func begin() -> void:
	total = 2 if learned() else 3
	tell("Stretch with %s! Put your finger on the sun and follow it slowly. Reach up tall like a tree!" % pet_name)


func _sun_pos(t: float) -> Vector2:
	var r := minf(size.x * 0.4, size.y * 0.72)
	var base := Vector2(size.x / 2.0, size.y - 70.0)
	var a := t if arcs % 2 == 0 else 1.0 - t
	return base + Vector2(-cos(a * PI) * r, -sin(a * PI) * r)


func _gui_input(event: InputEvent) -> void:
	var pressed = press_state(event)
	if pressed != null:
		down = pressed
		finger = event.position
	elif event is InputEventMouseMotion:
		finger = event.position


func _process(delta: float) -> void:
	if _finished:
		return
	pulse += delta
	var on_sun := down and finger.distance_to(_sun_pos(u)) < 110.0
	if on_sun:
		u += delta / ARC_TIME
	elif down and not told_slow and finger.distance_to(_sun_pos(u)) > 220.0:
		told_slow = true
		tell("Whoa, too fast! Stay with the sun. Slow is the trick.", true)
	if stage:
		var lift := sin(clampf(u, 0.0, 1.0) * PI)
		stage.squash = 1.0 + lift * 0.22
		stage.breath = 1.0 + lift * 0.05
	if u >= 1.0:
		arcs += 1
		u = 0.0
		Sfx.play("good")
		if arcs >= total:
			tell("%s: \"Ahhh. My body feels long and loose.\"" % pet_name)
			finish()
		else:
			tell("And slowly back the other way...  (%d of %d)" % [arcs + 1, total], arcs == 1)
	queue_redraw()


func _draw() -> void:
	# Dotted path, then the sun.
	for i in 25:
		var t := i / 24.0
		var done_part := t <= u
		draw_circle(_sun_pos(t), 7.0, UI.SUN if done_part else UI.INK_SOFT.lightened(0.55))
	var p := _sun_pos(u)
	var held := down and finger.distance_to(p) < 110.0
	var r := 44.0 if held else 44.0 + sin(pulse * 5.0) * 6.0
	draw_circle(p, r + 26.0, Color(1.0, 0.85, 0.3, 0.3))
	for i in 10:
		draw_set_transform(p, i * TAU / 10.0 + pulse * 0.4)
		draw_rect(Rect2(-5, -r - 22.0, 10, 18), UI.SUN)
	draw_set_transform(Vector2.ZERO)
	draw_circle(p, r, UI.SUN)
	draw_circle(p + Vector2(-13, -6), 5.0, UI.INK)
	draw_circle(p + Vector2(13, -6), 5.0, UI.INK)
	draw_arc(p + Vector2(0, 4), 16.0, 0.3, PI - 0.3, 10, UI.INK, 4.0, true)
	if not held:
		draw_string(UI.font(), Vector2(0, size.y * 0.62), "Touch the sun and follow it", HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, UI.INK_SOFT)
	progress_dots(total, arcs, UI.SUN)

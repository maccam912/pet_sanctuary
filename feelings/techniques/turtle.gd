extends Technique
## Turtle Shell (the Turtle Technique from the PATHS program):
## 1 Stop.  2 Tuck into your shell and take 3 slow breaths.  3 Think.

const BREATH := 5.0  # seconds per slow breath inside the shell

var phase := "stop"  # stop, tuck, think
var holding := false
var held := 0.0
var pulse := 0.0


func begin() -> void:
	tell("Step 1: STOP! Tap the stop sign so %s freezes." % pet_name)


func _center() -> Vector2:
	return Vector2(size.x / 2.0, size.y / 2.0 - 10.0)


func _gui_input(event: InputEvent) -> void:
	var pressed = press_state(event)
	if pressed == null or _finished:
		return
	match phase:
		"stop":
			if pressed and event.position.distance_to(_center()) < 170.0:
				phase = "tuck"
				Sfx.play("bong")
				tell("Step 2: TUCK into your shell. Hold down and take 3 slow breaths with %s." % pet_name)
		"tuck":
			holding = pressed
		"think":
			if pressed and event.position.distance_to(_center()) < 170.0:
				tell("Stop. Tuck. Breathe. Think. That is the Turtle! Now %s can make a good choice." % pet_name)
				if stage:
					stage.play("gesture-positive", true)
				finish()


func _process(delta: float) -> void:
	if _finished:
		return
	pulse += delta
	if phase == "tuck":
		if holding:
			var before := int(held / BREATH)
			held += delta
			if int(held / BREATH) > before:
				Sfx.play("good")
			if held >= BREATH * 3.0:
				phase = "think"
				holding = false
				Sfx.play("chime")
				tell("Step 3: THINK. It is calm inside the shell, so %s has an idea! Tap the light bulb." % pet_name)
		if stage:
			stage.squash = lerpf(stage.squash, 0.72 if holding else 1.0, minf(1.0, delta * 6.0))
			stage.breath = 1.0 + (sin(held / BREATH * TAU - PI / 2.0) * 0.05 if holding else 0.0)
	elif stage:
		stage.squash = lerpf(stage.squash, 1.0, minf(1.0, delta * 6.0))
	queue_redraw()


func _draw() -> void:
	var c := _center()
	match phase:
		"stop":
			var r := 130.0 + sin(pulse * 4.0) * 6.0
			var pts := PackedVector2Array()
			for i in 8:
				pts.append(c + Vector2.from_angle(i * TAU / 8.0 + PI / 8.0) * r)
			draw_colored_polygon(pts, UI.CORAL.darkened(0.1))
			pts.clear()
			for i in 8:
				pts.append(c + Vector2.from_angle(i * TAU / 8.0 + PI / 8.0) * (r - 12.0))
			draw_colored_polygon(pts, UI.CORAL)
			draw_string(UI.font(), c + Vector2(-150, 24), "STOP", HORIZONTAL_ALIGNMENT_CENTER, 300, 68, UI.WHITE)
		"tuck":
			# A big cozy shell that glows with each slow breath.
			var cycle := fmod(held, BREATH) / BREATH
			var grow := sin(cycle * PI) * 14.0 if holding else 0.0
			var r := 140.0 + grow
			var green := UI.LEAF.darkened(0.05) if holding else UI.LEAF.lightened(0.2)
			draw_set_transform(c + Vector2(0, 40), 0.0, Vector2(1.25, 1.0))
			draw_circle(Vector2.ZERO, r, green.darkened(0.2))
			draw_circle(Vector2.ZERO, r - 10.0, green)
			for a in [-0.5, 0.0, 0.5]:
				draw_circle(Vector2(a * r * 1.1, -r * 0.2), r * 0.2, green.darkened(0.12))
			draw_circle(Vector2(-r * 0.3, r * 0.3), r * 0.17, green.darkened(0.12))
			draw_circle(Vector2(r * 0.3, r * 0.3), r * 0.17, green.darkened(0.12))
			draw_set_transform(Vector2.ZERO)
			var word := "Hold down to tuck in"
			if holding:
				word = "Breathe in..." if cycle < 0.45 else "Breathe out..."
			draw_string(UI.font(), Vector2(0, size.y - 62.0), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, UI.INK)
			progress_dots(3, int(held / BREATH), UI.LEAF)
		"think":
			var r := 100.0 + sin(pulse * 5.0) * 8.0
			draw_circle(c, r + 40.0, Color(1.0, 0.85, 0.3, 0.3))
			draw_circle(c + Vector2(0, -10), r, UI.SUN)
			draw_rect(Rect2(c + Vector2(-36, r - 26), Vector2(72, 56)), UI.INK_SOFT)
			draw_string(UI.font(), c + Vector2(-100, 6), "Idea!", HORIZONTAL_ALIGNMENT_CENTER, 200, 40, UI.INK)

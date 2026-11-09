extends Technique
## Balloon Breaths: slow belly breathing. Hold to breathe in (4s), let go to
## breathe out (6s). The longer out-breath is what calms the body.

const IN_TIME := 4.0
const OUT_TIME := 6.0

var total := 4
var breaths := 0
var fill := 0.0
var peak := 0.0
var phase := "ready"  # ready, in, full, out


func begin() -> void:
	total = 3 if learned() else 4
	tell("Breathe with %s! Press and hold to breathe IN and fill the balloon." % pet_name)


func _gui_input(event: InputEvent) -> void:
	var pressed = press_state(event)
	if pressed == null or _finished:
		return
	if pressed and phase == "ready":
		phase = "in"
		Sfx.play("up", 0.6)
	elif not pressed and (phase == "in" or phase == "full"):
		peak = fill
		phase = "out"
		Sfx.play("down", 0.6)
		if peak < 0.6:
			tell("That was a quick one. Next time, hold until the balloon is big.")
		elif breaths == 0:
			tell("Breathe OUT slowly... like blowing on hot cocoa.")


func _process(delta: float) -> void:
	if _finished:
		return
	match phase:
		"in":
			fill = minf(1.0, fill + delta / IN_TIME)
			if fill >= 1.0:
				phase = "full"
				Sfx.play("soft")
				tell("Now let go... and breathe OUT slowly.", breaths == 0)
		"out":
			fill = maxf(0.0, fill - delta * maxf(peak, 0.3) / OUT_TIME)
			if fill <= 0.0:
				if peak >= 0.6:
					breaths += 1
					Sfx.play("good")
				if breaths >= total:
					tell("%s: \"My body feels slower and softer.\"" % pet_name)
					finish()
				else:
					phase = "ready"
					tell("Again! Press and hold to breathe in.  (%d of %d)" % [breaths + 1, total], false)
	if stage:
		stage.breath = 1.0 + fill * 0.14
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y / 2.0 - 30.0)
	var r := 62.0 + fill * 100.0
	var knot := c + Vector2(0, r * 1.12)
	var pts := PackedVector2Array()
	for i in 12:
		pts.append(knot + Vector2(sin(i * 0.9) * 8.0, i * 9.0))
	draw_polyline(pts, UI.INK_SOFT, 3.0, true)
	draw_colored_polygon(PackedVector2Array([knot + Vector2(0, -8), knot + Vector2(-12, 10), knot + Vector2(12, 10)]), UI.SKY.darkened(0.2))
	draw_set_transform(c, 0.0, Vector2(1.0, 1.12))
	draw_circle(Vector2.ZERO, r, UI.SKY.darkened(0.15))
	draw_circle(Vector2.ZERO, r - 6.0, UI.SKY)
	draw_circle(Vector2(-r * 0.35, -r * 0.4), r * 0.16, Color(1, 1, 1, 0.6))
	draw_set_transform(Vector2.ZERO)
	var word := "Hold to breathe in"
	match phase:
		"in": word = "In...  %d" % (int(fill * IN_TIME) + 1)
		"full": word = "Let go"
		"out": word = "Out...  %d" % (int(fill / maxf(peak, 0.3) * OUT_TIME) + 1)
	draw_string(UI.font(), Vector2(0, size.y - 62.0), word, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, UI.INK)
	progress_dots(total, breaths, UI.SKY)

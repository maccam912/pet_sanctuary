extends Technique
## Slow Count to 10: fireflies light up one at a time. Rushing does nothing,
## so the only way through is slowly. That pause is the whole skill.

const GAP := 1.15  # seconds before the next firefly lights

var count := 0
var wait := 1.0
var lit := false
var glow := 0.0


func begin() -> void:
	tell("Count slowly with %s. Tap each firefly when it lights up. No rushing!" % pet_name)


func _fly_pos(i: int) -> Vector2:
	var cols := 5
	var x := size.x * (0.14 + 0.18 * (i % cols))
	var y := size.y * (0.3 if i < cols else 0.62) + sin(i * 1.7) * 18.0
	return Vector2(x, y)


func _process(delta: float) -> void:
	if _finished:
		return
	glow += delta
	if not lit:
		wait -= delta
		if wait <= 0.0:
			lit = true
			Sfx.play("tick", 1.0 + count * 0.05)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if press_state(event) != true or _finished:
		return
	if not lit:
		return
	if event.position.distance_to(_fly_pos(count)) > 85.0:
		return
	count += 1
	lit = false
	wait = GAP
	Sfx.play("soft", 0.8 + count * 0.06)
	Sfx.say(str(count))
	if stage:
		stage.breath = 1.0 + 0.02 * count
	if count >= 10:
		tell("Ten! %s waited, and the big feeling had time to shrink." % pet_name)
		finish()


func _draw() -> void:
	for i in 10:
		var p := _fly_pos(i)
		if i < count:
			draw_circle(p, 34.0, UI.SUN.darkened(0.1))
			draw_circle(p, 29.0, UI.SUN)
			draw_string(UI.font(), p + Vector2(-40, 12), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 80, 32, UI.INK)
		elif i == count and lit:
			var pulse := 1.0 + sin(glow * 6.0) * 0.12
			draw_circle(p, 62.0 * pulse, Color(1.0, 0.85, 0.3, 0.25))
			draw_circle(p, 46.0 * pulse, Color(1.0, 0.85, 0.3, 0.4))
			draw_circle(p, 32.0, UI.SUN)
			draw_circle(p + Vector2(-9, -6), 4.0, UI.INK)
			draw_circle(p + Vector2(9, -6), 4.0, UI.INK)
			draw_arc(p + Vector2(0, 2), 12.0, 0.3, PI - 0.3, 10, UI.INK, 3.0, true)
		else:
			draw_circle(p, 22.0, UI.INK_SOFT.lightened(0.55))
	var big := str(count) if count > 0 else ""
	draw_string(UI.font(), Vector2(0, size.y - 20.0), big, HORIZONTAL_ALIGNMENT_CENTER, size.x, 64, UI.INK)

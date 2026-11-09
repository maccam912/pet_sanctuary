extends Technique
## Squeeze and Melt: progressive muscle relaxation for kids. Tense a muscle
## group hard for a few seconds, then let go and notice the soft feeling.

const SQUEEZE_TIME := 4.0
const MELT_TIME := 4.5
const ROUNDS := [
	"Squeeze your paws tight, like squeezing lemons! Hold down to squeeze.",
	"Scrunch your shoulders up to your ears! Hold down.",
	"Make your WHOLE body tight like a rock! Hold down.",
]

var round_index := 0
var total := 3
var phase := "squeeze"  # squeeze, melt
var holding := false
var fill := 0.0
var melt := 0.0
var wobble := 0.0


func begin() -> void:
	total = 2 if learned() else 3
	tell(ROUNDS[0])


func _gui_input(event: InputEvent) -> void:
	var pressed = press_state(event)
	if pressed == null or _finished:
		return
	holding = pressed and phase == "squeeze"


func _process(delta: float) -> void:
	if _finished:
		return
	wobble += delta
	if phase == "squeeze":
		if holding:
			fill = minf(1.0, fill + delta / SQUEEZE_TIME)
			if fill >= 1.0:
				phase = "melt"
				holding = false
				melt = 0.0
				Sfx.play("down", 0.5)
				tell("Now let go... and MELT like ice cream in the sun. Feel how soft that is?")
		else:
			fill = maxf(0.0, fill - delta * 0.6)
		if stage:
			stage.shake = fill * 1.4 if holding else 0.0
			stage.squash = 1.0 - fill * 0.12
	else:
		melt += delta / MELT_TIME
		if stage:
			stage.shake = 0.0
			stage.squash = lerpf(0.88, 1.0, clampf(melt * 1.2 - 0.2, 0.0, 1.0)) - sin(clampf(melt, 0.0, 1.0) * PI) * 0.1
		if melt >= 1.0:
			round_index += 1
			if round_index >= total:
				tell("%s: \"My muscles feel loose and floppy. The tight feeling melted!\"" % pet_name)
				finish()
			else:
				phase = "squeeze"
				fill = 0.0
				Sfx.play("good")
				tell(ROUNDS[round_index])
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x / 2.0, size.y / 2.0 - 30.0)
	if phase == "squeeze":
		# A lemon that squishes as you squeeze.
		var squish := 1.0 - fill * 0.3
		var jitter := Vector2(sin(wobble * 50.0), cos(wobble * 43.0)) * fill * 4.0 if holding else Vector2.ZERO
		var col := UI.SUN.lerp(UI.CORAL, fill)
		draw_set_transform(c + jitter, 0.0, Vector2(1.25 * squish, 1.0 / squish * 0.95))
		draw_circle(Vector2.ZERO, 112.0, col.darkened(0.15))
		draw_circle(Vector2.ZERO, 104.0, col)
		draw_circle(Vector2(-36, -40), 16.0, Color(1, 1, 1, 0.45))
		draw_set_transform(Vector2.ZERO)
		draw_arc(c, 160.0, -PI / 2.0, -PI / 2.0 + TAU * fill, 48, UI.CORAL.darkened(0.1), 14.0, true)
		draw_string(UI.font(), Vector2(0, size.y - 62.0), "SQUEEZE!" if holding else "Hold down to squeeze", HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, UI.INK)
	else:
		# A puddle that spreads as you melt.
		var m := clampf(melt, 0.0, 1.0)
		draw_set_transform(c + Vector2(0, 40.0 * m), 0.0, Vector2(1.2 + m * 0.7, 1.0 - m * 0.55))
		draw_circle(Vector2.ZERO, 104.0, UI.SUN.lerp(Content.EMOTIONS.calm.color, m))
		draw_set_transform(Vector2.ZERO)
		draw_string(UI.font(), Vector2(0, size.y - 62.0), "Melt...", HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, UI.INK)
	progress_dots(total, round_index, UI.CORAL)

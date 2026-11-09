class_name BlockGame
extends Activity
## Block Tower: a block slides side to side; tap to drop it on the tower.
## Whatever hangs over the edge is trimmed off. Stack 8 to win.
## On a "tricky moment" a gust of wind knocks the tower down part-way.

const GOAL := 8
const BLOCK_H := 42.0
const COLORS := [UI.CORAL, UI.SUN, UI.LEAF, UI.SKY, UI.LAVENDER, UI.PINK]

var tower: Array = []     # each {x, w, c, off: Vector2, rot}
var mover := {"x": 0.0, "w": 230.0, "dir": 1.0}
var falling: Array = []   # trimmed bits / missed blocks dropping away
var playing := false
var setback_at := -1
var _canvas: Control


func _init() -> void:
	title = "Block Tower"


func start() -> void:
	_canvas = Control.new()
	UI.full(_canvas)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.draw.connect(_draw_game)
	_canvas.gui_input.connect(_on_input)
	area.add_child(_canvas)
	if wants_setback():
		setback_at = 5 + Game.rng.randi() % 2
	_reset_tower()
	say("Tap to drop each block. Stack %d blocks with %s!" % [GOAL, buddy.name])
	playing = true


func _reset_tower() -> void:
	tower.clear()
	var w := 230.0
	tower.append({"x": _canvas.size.x / 2.0 - w / 2.0, "w": w, "c": UI.INK_SOFT.lightened(0.3), "off": Vector2.ZERO, "rot": 0.0})
	mover = {"x": 0.0, "w": w, "dir": 1.0}


func _speed() -> float:
	return 250.0 + tower.size() * 28.0


func _process(delta: float) -> void:
	if _canvas == null:
		return
	if playing:
		mover.x += mover.dir * _speed() * delta
		if mover.x < 0.0:
			mover.x = 0.0
			mover.dir = 1.0
		elif mover.x + mover.w > _canvas.size.x:
			mover.x = _canvas.size.x - mover.w
			mover.dir = -1.0
	for f in falling:
		f.vy += 1400.0 * delta
		f.y += f.vy * delta
		f.x += f.vx * delta
	falling = falling.filter(func(f): return f.y < _canvas.size.y + 100.0)
	_canvas.queue_redraw()


func _row_y(i: int) -> float:
	return _canvas.size.y - 16.0 - BLOCK_H * (i + 1)


func _on_input(event: InputEvent) -> void:
	if not playing or not (event is InputEventMouseButton and event.pressed):
		return
	var top: Dictionary = tower[-1]
	var left := maxf(mover.x, top.x)
	var right := minf(mover.x + mover.w, top.x + top.w)
	var overlap := right - left
	var color: Color = COLORS[tower.size() % COLORS.size()]
	var y := _row_y(tower.size())
	if overlap < 14.0:
		falling.append({"x": mover.x, "y": y, "w": mover.w, "vx": mover.dir * 80.0, "vy": 0.0, "c": color})
		Sfx.play("thud")
		say("Whoops, it slipped! Try that one again.", false)
		stage.play("gesture-negative", true)
		return
	if overlap > mover.w - 12.0:
		left = top.x
		overlap = top.w if top.w <= mover.w else mover.w
		Sfx.play("good")
		say("Perfect!", false)
	else:
		# Trim the part hanging over the edge.
		var cut_x: float = mover.x if mover.x < top.x else right
		falling.append({"x": cut_x, "y": y, "w": mover.w - overlap, "vx": mover.dir * 60.0, "vy": 0.0, "c": color})
		Sfx.play("wood", 0.9 + tower.size() * 0.05)
		say("%d of %d" % [tower.size(), GOAL], false)
	tower.append({"x": left, "w": overlap, "c": color, "off": Vector2.ZERO, "rot": 0.0})
	mover.w = maxf(overlap, 60.0)
	mover.x = 0.0 if mover.dir > 0.0 else _canvas.size.x - mover.w
	var stacked := tower.size() - 1
	if stacked == setback_at:
		setback_at = -1
		_blow_down()
	elif stacked >= GOAL:
		playing = false
		await get_tree().create_timer(0.6).timeout
		win(5, "What a tall tower! You and %s did it!" % buddy.name)


func _blow_down() -> void:
	playing = false
	await get_tree().create_timer(0.4).timeout
	Sfx.play("plank")
	Sfx.play("thud", 0.7)
	for i in range(1, tower.size()):
		falling.append({"x": tower[i].x, "y": _row_y(i), "w": tower[i].w, "vx": 240.0 + i * 60.0, "vy": -260.0 - i * 30.0, "c": tower[i].c})
	_reset_tower()
	await calm("WHOOSH! A big gust of wind blew the whole tower down.")
	say("Deep breath. Let's build it again!")
	playing = true


func _draw_game() -> void:
	var c := _canvas
	c.draw_rect(Rect2(0, c.size.y - 16.0, c.size.x, 16.0), UI.LEAF.darkened(0.1))
	for i in tower.size():
		_block(Rect2(tower[i].x, _row_y(i), tower[i].w, BLOCK_H - 3.0), tower[i].c)
	if playing:
		_block(Rect2(mover.x, _row_y(tower.size()) - 26.0, mover.w, BLOCK_H - 3.0), COLORS[tower.size() % COLORS.size()])
	for f in falling:
		_block(Rect2(f.x, f.y, f.w, BLOCK_H - 3.0), f.c)
	# Goal line
	var gy := _row_y(GOAL) + BLOCK_H
	for x in range(0, int(c.size.x), 36):
		c.draw_rect(Rect2(x, gy, 18, 4), UI.SUN.darkened(0.1))
	Doodle.draw_star(c, Vector2(c.size.x - 30.0, gy), 22.0, UI.SUN)


func _block(rect: Rect2, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(9)
	sb.border_width_bottom = 6
	sb.border_color = color.darkened(0.2)
	_canvas.draw_style_box(sb, rect)

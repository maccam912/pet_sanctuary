class_name Thermometer
extends Control
## Feeling thermometer, 1 (tiny) to 5 (HUGE). Shows a level, or lets the child pick one.

signal picked(level: int)

var level := 1.0:
	set(v):
		level = v
		queue_redraw()
var interactive := false
var _shown := 1.0

const COLORS := [Color("8fd6c2"), Color("b9de8a"), Color("ffd166"), Color("f59e42"), Color("ef6f5e")]


func _init(start := 1, can_pick := false) -> void:
	level = start
	_shown = start
	interactive = can_pick
	custom_minimum_size = Vector2(110, 330)
	mouse_filter = Control.MOUSE_FILTER_STOP if can_pick else Control.MOUSE_FILTER_IGNORE


func animate_to(target: int, time := 1.2) -> void:
	create_tween().tween_property(self, "level", float(target), time).set_trans(Tween.TRANS_SINE)


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and event.button_mask != 0):
		var seg := size.y / 5.0
		var l := clampi(5 - int(event.position.y / seg), 1, 5)
		if l != int(level) or event is InputEventMouseButton:
			level = l
			Sfx.play("tick")
			picked.emit(l)


func _draw() -> void:
	var w := minf(size.x, 110.0)
	var x := (size.x - w) / 2.0
	var seg := size.y / 5.0
	var back := StyleBoxFlat.new()
	back.bg_color = UI.WHITE
	back.set_corner_radius_all(int(w / 2.0))
	back.set_border_width_all(6)
	back.border_color = UI.INK_SOFT
	draw_style_box(back, Rect2(x, 0, w, size.y))
	for i in 5:
		var lvl := i + 1
		var fill := clampf(level - i, 0.0, 1.0)
		var rect := Rect2(x + 14, size.y - seg * lvl + 6, w - 28, seg - 12)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(16)
		sb.bg_color = COLORS[i] if fill > 0.5 else Color(0.92, 0.9, 0.86)
		draw_style_box(sb, rect)
		draw_string(UI.font(), rect.position + Vector2(0, rect.size.y * 0.5 + 12), str(lvl), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 32, UI.INK if fill > 0.5 else UI.INK_SOFT)

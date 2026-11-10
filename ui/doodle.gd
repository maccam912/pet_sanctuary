class_name Doodle
extends Control
## Small hand-drawn style icons, drawn in code so every icon matches the palette.

@export var kind := "heart":
	set(v):
		kind = v
		queue_redraw()
var tint := Color.TRANSPARENT:  # optional override colour
	set(v):
		tint = v
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _col(c: Color) -> Color:
	return tint if tint.a > 0.0 else c


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 0.0:
		return
	var c := size / 2.0
	var r := s / 2.0
	match kind:
		"heart":
			draw_heart(self, c, r, _col(UI.CORAL))
		"star":
			draw_star(self, c, r, _col(UI.SUN))
		"storm":
			var g := _col(Color("8a93a8"))
			draw_circle(c + Vector2(-r * 0.4, -r * 0.1), r * 0.42, g)
			draw_circle(c + Vector2(r * 0.05, -r * 0.35), r * 0.5, g)
			draw_circle(c + Vector2(r * 0.5, -r * 0.05), r * 0.38, g)
			draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.1), Vector2(r * 0.95, r * 0.4)), g)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.1, r * 0.25), c + Vector2(-r * 0.3, r * 0.65),
				c + Vector2(-r * 0.02, r * 0.62), c + Vector2(-r * 0.2, r), c + Vector2(r * 0.35, r * 0.5), c + Vector2(r * 0.08, r * 0.52)]), UI.SUN)
		"gear":
			var col := _col(UI.INK_SOFT)
			for i in 8:
				draw_set_transform(c, i * TAU / 8.0)
				draw_rect(Rect2(-r * 0.16, -r, r * 0.32, r * 0.4), col)
			draw_set_transform(Vector2.ZERO)
			draw_circle(c, r * 0.72, col)
			draw_circle(c, r * 0.3, UI.CREAM)
		"speaker":
			var col := _col(UI.INK)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.9, -r * 0.3), c + Vector2(-r * 0.45, -r * 0.3),
				c + Vector2(0, -r * 0.75), c + Vector2(0, r * 0.75), c + Vector2(-r * 0.45, r * 0.3), c + Vector2(-r * 0.9, r * 0.3)]), col)
			draw_arc(c, r * 0.4, -0.8, 0.8, 12, col, r * 0.14, true)
			draw_arc(c, r * 0.75, -0.8, 0.8, 16, col, r * 0.14, true)
		"lock":
			var col := _col(UI.INK_SOFT)
			draw_arc(c + Vector2(0, -r * 0.2), r * 0.42, PI, TAU, 16, col, r * 0.2, true)
			draw_rect(Rect2(c + Vector2(-r * 0.65, -r * 0.2), Vector2(r * 1.3, r * 1.1)), col)
			draw_circle(c + Vector2(0, r * 0.3), r * 0.16, UI.CREAM)
		"paw":
			var col := _col(UI.INK)
			draw_circle(c + Vector2(0, r * 0.3), r * 0.5, col)
			for p in [Vector2(-0.62, -0.2), Vector2(-0.22, -0.62), Vector2(0.22, -0.62), Vector2(0.62, -0.2)]:
				draw_circle(c + p * r, r * 0.22, col)
		"bulb":
			draw_circle(c + Vector2(0, -r * 0.2), r * 0.62, _col(UI.SUN))
			draw_rect(Rect2(c + Vector2(-r * 0.28, r * 0.35), Vector2(r * 0.56, r * 0.45)), UI.INK_SOFT)
		"back":
			var col := _col(UI.INK)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.9, 0), c + Vector2(-r * 0.1, -r * 0.75), c + Vector2(-r * 0.1, r * 0.75)]), col)
			draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.25), Vector2(r, r * 0.5)), col)
		"check":
			draw_polyline(PackedVector2Array([c + Vector2(-r * 0.7, 0), c + Vector2(-r * 0.2, r * 0.5), c + Vector2(r * 0.75, -r * 0.55)]), _col(UI.LEAF.darkened(0.2)), r * 0.28, true)
		"book":
			draw_rect(Rect2(c + Vector2(-r * 0.85, -r * 0.7), Vector2(r * 0.82, r * 1.4)), _col(UI.SKY))
			draw_rect(Rect2(c + Vector2(r * 0.03, -r * 0.7), Vector2(r * 0.82, r * 1.4)), _col(UI.SKY).lightened(0.2))
			draw_star(self, c + Vector2(r * 0.44, 0), r * 0.3, UI.SUN)
		"toolbox":
			draw_arc(c + Vector2(0, -r * 0.3), r * 0.3, PI, TAU, 12, UI.INK_SOFT, r * 0.16, true)
			draw_rect(Rect2(c + Vector2(-r * 0.9, -r * 0.3), Vector2(r * 1.8, r * 1.1)), _col(UI.CORAL))
			draw_rect(Rect2(c + Vector2(-r * 0.9, r * 0.05), Vector2(r * 1.8, r * 0.16)), UI.INK_SOFT)
			draw_heart(self, c + Vector2(0, r * 0.14), r * 0.3, UI.CREAM)
		"stop":
			var pts := PackedVector2Array()
			for i in 8:
				pts.append(c + Vector2.from_angle(i * TAU / 8.0 + PI / 8.0) * r)
			draw_colored_polygon(pts, _col(UI.CORAL))
			draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.14), Vector2(r, r * 0.28)), UI.WHITE)
		"ear":
			draw_arc(c, r * 0.6, -PI * 0.9, PI * 0.5, 20, _col(UI.INK), r * 0.22, true)
			draw_arc(c + Vector2(0, r * 0.1), r * 0.25, -PI * 0.8, PI * 0.6, 12, _col(UI.INK), r * 0.16, true)
		"foot":
			var col := _col(UI.INK)
			draw_set_transform(c, 0.0, Vector2(0.62, 1.0))
			draw_circle(Vector2(0, r * 0.25), r * 0.7, col)
			draw_set_transform(Vector2.ZERO)
			for i in 4:
				draw_circle(c + Vector2(-r * 0.42 + i * r * 0.28, -r * 0.68 + absf(i - 1.5) * r * 0.08), r * 0.13, col)
		"sun":
			var col := _col(UI.SUN)
			for i in 10:
				draw_set_transform(c, i * TAU / 10.0)
				draw_rect(Rect2(-r * 0.08, -r, r * 0.16, r * 0.3), col)
			draw_set_transform(Vector2.ZERO)
			draw_circle(c, r * 0.6, col)
		"x":
			var col := _col(UI.INK)
			draw_line(c + Vector2(-r, -r) * 0.6, c + Vector2(r, r) * 0.6, col, r * 0.26, true)
			draw_line(c + Vector2(-r, r) * 0.6, c + Vector2(r, -r) * 0.6, col, r * 0.26, true)


static func draw_heart(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.42, -r * 0.28), r * 0.48, col)
	ci.draw_circle(c + Vector2(r * 0.42, -r * 0.28), r * 0.48, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.86, -r * 0.05), c + Vector2(r * 0.86, -r * 0.05), c + Vector2(0, r * 0.9)]), col)


static func draw_star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var rad := r if i % 2 == 0 else r * 0.46
		pts.append(c + Vector2.from_angle(-PI / 2.0 + i * TAU / 10.0) * rad)
	ci.draw_colored_polygon(pts, col)

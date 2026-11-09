class_name Face
extends Control
## A feeling face drawn in code. One face per emotion in Content.EMOTIONS.

var emotion := "calm":
	set(v):
		emotion = v
		queue_redraw()


func _init(e := "calm", px := 96) -> void:
	emotion = e
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var r := minf(size.x, size.y) / 2.0
	if r <= 0.0:
		return
	var c := size / 2.0
	var col: Color = Content.EMOTIONS.get(emotion, Content.EMOTIONS.calm).color
	var ink := UI.INK
	var w := r * 0.1
	draw_circle(c, r, col.darkened(0.18))
	draw_circle(c, r * 0.92, col)
	var el := c + Vector2(-r * 0.36, -r * 0.1)
	var er := c + Vector2(r * 0.36, -r * 0.1)
	var eye := r * 0.12
	match emotion:
		"mad":
			draw_circle(el, eye, ink)
			draw_circle(er, eye, ink)
			draw_line(el + Vector2(-r * 0.24, -r * 0.36), el + Vector2(r * 0.2, -r * 0.16), ink, w, true)
			draw_line(er + Vector2(r * 0.24, -r * 0.36), er + Vector2(-r * 0.2, -r * 0.16), ink, w, true)
			draw_arc(c + Vector2(0, r * 0.62), r * 0.32, PI * 1.15, PI * 1.85, 16, ink, w, true)
		"frustrated":
			# squeezed-shut eyes and gritted teeth
			for e in [el, er]:
				var d := 1.0 if e == el else -1.0
				draw_line(e + Vector2(-r * 0.16 * d, -r * 0.1), e + Vector2(r * 0.12 * d, 0), ink, w, true)
				draw_line(e + Vector2(-r * 0.16 * d, r * 0.1), e + Vector2(r * 0.12 * d, 0), ink, w, true)
			draw_line(el + Vector2(-r * 0.2, -r * 0.34), el + Vector2(r * 0.2, -r * 0.22), ink, w, true)
			draw_line(er + Vector2(r * 0.2, -r * 0.34), er + Vector2(-r * 0.2, -r * 0.22), ink, w, true)
			var m := Rect2(c + Vector2(-r * 0.36, r * 0.28), Vector2(r * 0.72, r * 0.26))
			draw_rect(m, UI.WHITE)
			draw_rect(m, ink, false, w * 0.7)
			for i in [1, 2, 3]:
				draw_line(m.position + Vector2(m.size.x * i / 4.0, 0), m.position + Vector2(m.size.x * i / 4.0, m.size.y), ink, w * 0.5)
		"worried":
			draw_circle(el, eye * 1.2, ink)
			draw_circle(er, eye * 1.2, ink)
			draw_line(el + Vector2(-r * 0.22, -r * 0.2), el + Vector2(r * 0.18, -r * 0.38), ink, w, true)
			draw_line(er + Vector2(r * 0.22, -r * 0.2), er + Vector2(-r * 0.18, -r * 0.38), ink, w, true)
			var pts := PackedVector2Array()
			for i in 9:
				pts.append(c + Vector2(-r * 0.32 + i * r * 0.08, r * 0.42 + (r * 0.06 if i % 2 == 0 else -r * 0.06)))
			draw_polyline(pts, ink, w, true)
			draw_circle(c + Vector2(r * 0.68, -r * 0.42), r * 0.1, Color("bfe6ff"))
		"sad":
			draw_circle(el, eye, ink)
			draw_circle(er, eye, ink)
			draw_line(el + Vector2(-r * 0.22, -r * 0.18), el + Vector2(r * 0.16, -r * 0.34), ink, w, true)
			draw_line(er + Vector2(r * 0.22, -r * 0.18), er + Vector2(-r * 0.16, -r * 0.34), ink, w, true)
			draw_arc(c + Vector2(0, r * 0.66), r * 0.34, PI * 1.2, PI * 1.8, 16, ink, w, true)
			draw_circle(el + Vector2(-r * 0.04, r * 0.34), r * 0.1, Color("dff3ff"))
			draw_colored_polygon(PackedVector2Array([el + Vector2(-r * 0.12, r * 0.3), el + Vector2(r * 0.04, r * 0.3), el + Vector2(-r * 0.04, r * 0.12)]), Color("dff3ff"))
		"disappointed":
			draw_arc(el + Vector2(0, -r * 0.04), eye * 1.3, 0.1, PI - 0.1, 10, ink, w, true)
			draw_arc(er + Vector2(0, -r * 0.04), eye * 1.3, 0.1, PI - 0.1, 10, ink, w, true)
			draw_line(el + Vector2(-r * 0.2, -r * 0.28), el + Vector2(r * 0.2, -r * 0.28), ink, w, true)
			draw_line(er + Vector2(-r * 0.2, -r * 0.28), er + Vector2(r * 0.2, -r * 0.28), ink, w, true)
			draw_arc(c + Vector2(0, r * 0.6), r * 0.22, PI * 1.2, PI * 1.8, 12, ink, w, true)
		"jealous":
			# side-eye
			for e in [el, er]:
				draw_circle(e, eye * 1.7, UI.WHITE)
				draw_circle(e + Vector2(eye * 0.8, 0), eye, ink)
			draw_line(el + Vector2(-r * 0.22, -r * 0.3), el + Vector2(r * 0.2, -r * 0.22), ink, w, true)
			draw_line(er + Vector2(r * 0.22, -r * 0.38), er + Vector2(-r * 0.2, -r * 0.2), ink, w, true)
			draw_line(c + Vector2(-r * 0.26, r * 0.5), c + Vector2(r * 0.26, r * 0.38), ink, w, true)
		"happy":
			draw_circle(el, eye, ink)
			draw_circle(er, eye, ink)
			draw_arc(c + Vector2(0, r * 0.16), r * 0.42, PI * 0.12, PI * 0.88, 18, ink, w, true)
		_:
			# calm: soft closed eyes, small smile
			draw_arc(el, eye * 1.4, PI * 1.1, PI * 1.9, 10, ink, w, true)
			draw_arc(er, eye * 1.4, PI * 1.1, PI * 1.9, 10, ink, w, true)
			draw_arc(c + Vector2(0, r * 0.22), r * 0.3, PI * 0.2, PI * 0.8, 14, ink, w, true)

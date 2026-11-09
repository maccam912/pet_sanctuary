class_name UI
extends RefCounted
## One look for the whole game: palette, theme and small widget factories.

const CREAM := Color("fff8ec")
const PAPER := Color("fdeed3")
const INK := Color("5b4636")
const INK_SOFT := Color("8a735f")
const LEAF := Color("7bc47f")
const SKY := Color("8ed1f0")
const SUN := Color("ffd166")
const CORAL := Color("ff8c7a")
const LAVENDER := Color("b9a6f0")
const PINK := Color("f2a6c8")
const WHITE := Color("ffffff")
const SHADE := Color(0.2, 0.13, 0.08, 0.55)

static var _theme: Theme
static var _font: Font


static func font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		# Rounded, friendly, easy-to-read faces; falls back to the platform default.
		f.font_names = PackedStringArray(["Arial Rounded MT Bold", "Nunito", "Varela Round", "Chalkboard SE", "Comic Sans MS", "Verdana", "sans-serif"])
		f.font_weight = 700
		f.allow_system_fallback = true
		_font = f
	return _font


static func box(color: Color, radius := 28, lip := 0, shadow := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14 + lip
	if lip > 0:
		sb.border_width_bottom = lip
		sb.border_color = color.darkened(0.22)
	if shadow > 0:
		sb.shadow_color = Color(0.25, 0.15, 0.05, 0.22)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, shadow * 0.5)
	return sb


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 28
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("panel", "PanelContainer", box(CREAM, 36, 0, 14))
	_style_button(t, "Button", LEAF)
	t.set_color("font_color", "CheckButton", INK)
	t.set_stylebox("normal", "LineEdit", box(WHITE, 18))
	t.set_stylebox("focus", "LineEdit", box(WHITE, 18))
	t.set_color("font_color", "LineEdit", INK)
	var grab := box(LEAF, 16)
	t.set_stylebox("slider", "HSlider", _bar(PAPER.darkened(0.12)))
	t.set_stylebox("grabber_area", "HSlider", _bar(LEAF))
	t.set_stylebox("grabber_area_highlight", "HSlider", _bar(LEAF))
	t.set_stylebox("background", "ProgressBar", _bar(PAPER.darkened(0.1)))
	t.set_stylebox("fill", "ProgressBar", _bar(LEAF))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	_theme = t
	return t


static func _bar(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(10)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func _style_button(t: Theme, type: String, color: Color) -> void:
	t.set_stylebox("normal", type, box(color, 26, 7))
	t.set_stylebox("hover", type, box(color.lightened(0.08), 26, 7))
	var pressed := box(color.darkened(0.08), 26, 2)
	pressed.content_margin_top = 19
	pressed.content_margin_bottom = 16
	t.set_stylebox("pressed", type, pressed)
	var dis := box(Color(0.8, 0.78, 0.74), 26, 7)
	t.set_stylebox("disabled", type, dis)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, type, INK)
	t.set_color("font_disabled_color", type, Color(0.55, 0.52, 0.48))


static func label(text: String, size := 30, color := INK, center := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A label that wraps onto several lines. Give it a width (minimum size or expand).
static func text(words: String, size := 30, color := INK, center := true) -> Label:
	var l := label(words, size, color, center)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func button(text: String, color := LEAF, size := 30, wrap := false) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(120, 84)
	if wrap:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recolor(b, color)
	b.pressed.connect(func(): Sfx.play("click"))
	return b


static func recolor(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", box(color, 26, 7))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.08), 26, 7))
	var pressed := box(color.darkened(0.08), 26, 2)
	pressed.content_margin_top = 19
	pressed.content_margin_bottom = 16
	b.add_theme_stylebox_override("pressed", pressed)


## Round button with a drawn icon (no text), for the HUD.
static func icon_button(kind: String, color := CREAM, size := 84) -> Button:
	var b := button("", color)
	b.custom_minimum_size = Vector2(size, size)
	var d := Doodle.new()
	d.kind = kind
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.offset_left = size * 0.2
	d.offset_right = -size * 0.2
	d.offset_top = size * 0.14
	d.offset_bottom = -size * 0.26
	b.add_child(d)
	return b


static func panel(color := CREAM, radius := 36) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(color, radius, 0, 14))
	return p


static func vbox(sep := 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	return h


static func spacer(min_size := Vector2.ZERO) -> Control:
	var c := Control.new()
	c.custom_minimum_size = min_size
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func full(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


## Dim backdrop that fills the screen and blocks taps to whatever is below.
static func backdrop(color := SHADE) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	full(r)
	return r


## Wrap `content` in a centered cream panel of a given size.
static func centered(content: Control, min_size := Vector2(720, 0)) -> CenterContainer:
	var cc := CenterContainer.new()
	full(cc)
	var p := panel()
	p.custom_minimum_size = min_size
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 18)
	m.add_child(content)
	p.add_child(m)
	cc.add_child(p)
	return cc


static func pet_icon(species: String, size := 96) -> TextureRect:
	return picture("res://assets/pet_icons/animal-%s.png" % species, size)


static func food_icon(food: String, size := 96) -> TextureRect:
	return picture("res://assets/food_icons/%s.png" % food, size)


static func picture(path: String, size := 96) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Little bounce to draw the eye to something new.
static func pop(node: Control) -> void:
	if not node.is_inside_tree():
		await node.ready
	await node.get_tree().process_frame
	if not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2.0
	node.scale = Vector2(0.7, 0.7)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func fade_in(node: CanvasItem, time := 0.25) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, time)

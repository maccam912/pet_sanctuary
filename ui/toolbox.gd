class_name Toolbox
extends Control
## The Calm Toolbox: every calm-down tool learned so far. Tap one to practice
## it with a pet any time (also the child's own "I need a calm moment" button).

signal practice(tool_id: String)


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	var v := UI.vbox(12)
	v.add_child(UI.label("Calm Tools", 40))
	v.add_child(UI.label("Need a calm moment? Pick a tool and do it with a pet.", 24, UI.INK_SOFT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := UI.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	v.add_child(scroll)
	for id in Content.TECHNIQUE_ORDER:
		list.add_child(_row(id))
	var done := UI.button("Done", UI.LEAF)
	done.custom_minimum_size = Vector2(260, 80)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(queue_free)
	v.add_child(done)
	add_child(UI.centered(v, Vector2(900, 0)))


func _row(id: String) -> Control:
	var info: Dictionary = Content.TECHNIQUES[id]
	var stage := Game.state.stage_of(id)
	var locked := stage == Content.STAGE_LOCKED
	var p := UI.panel(info.color.lightened(0.45) if not locked else Color(0.9, 0.88, 0.84), 24)
	var row := UI.hbox(14)
	p.add_child(row)
	var text := UI.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UI.label(info.name if not locked else "???", 28, UI.INK, false))
	text.add_child(UI.text(info.short if not locked else "Help more pets to discover this tool.", 21, UI.INK_SOFT, false))
	row.add_child(text)
	var stars := UI.hbox(2)
	for i in 3:
		var s := Doodle.new()
		s.kind = "star"
		s.custom_minimum_size = Vector2(34, 34)
		if i >= stage:
			s.tint = Color(0.82, 0.8, 0.76)
		stars.add_child(s)
	row.add_child(stars)
	if locked:
		var lock := Doodle.new()
		lock.kind = "lock"
		lock.custom_minimum_size = Vector2(170, 50)
		row.add_child(lock)
	else:
		var b := UI.button("Practice", info.color, 24)
		b.custom_minimum_size = Vector2(170, 70)
		b.pressed.connect(func():
			practice.emit(id)
			queue_free())
		row.add_child(b)
	return p

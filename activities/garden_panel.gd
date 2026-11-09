class_name GardenPanel
extends Control
## The garden: plant, wait, water, wait, pick. A small daily dose of patience.

var host: Sanctuary
var _buttons: Array[Button] = []
var _bars: Array[ProgressBar] = []


func _init(sanctuary: Sanctuary = null) -> void:
	host = sanctuary


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	var v := UI.vbox(16)
	v.add_child(UI.label("Garden", 40))
	v.add_child(UI.label("Plants take time. Come back and check on them!", 24, UI.INK_SOFT))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for i in 6:
		var b := UI.button("", UI.PAPER, 24)
		b.custom_minimum_size = Vector2(230, 130)
		b.pressed.connect(func(): host.garden_tap(i))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = Sanctuary.GROW_SECONDS
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_left = 24
		bar.offset_right = -24
		bar.offset_top = -44
		bar.offset_bottom = -24
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(bar)
		grid.add_child(b)
		_buttons.append(b)
		_bars.append(bar)
	v.add_child(grid)
	var done := UI.button("Done", UI.LEAF)
	done.custom_minimum_size = Vector2(260, 84)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(queue_free)
	v.add_child(done)
	add_child(UI.centered(v, Vector2(820, 0)))
	refresh()


func refresh() -> void:
	for i in 6:
		var plot: Dictionary = Game.state.garden[i]
		var b := _buttons[i]
		var growing: bool = plot.stage == 1 or plot.stage == 3
		_bars[i].visible = growing
		match int(plot.stage):
			0:
				b.text = "Plant a seed"
				UI.recolor(b, UI.PAPER)
			1, 3:
				b.text = "Growing..."
				UI.recolor(b, UI.LEAF.lightened(0.35))
			2:
				b.text = "Thirsty!\nTap to water"
				UI.recolor(b, UI.SKY)
			4:
				b.text = "Ready!\nPick it  +3"
				UI.recolor(b, UI.SUN)


func _process(_delta: float) -> void:
	for i in 6:
		_bars[i].value = Game.state.garden[i].t

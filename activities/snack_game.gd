class_name SnackGame
extends Activity
## Snack Time: a hungry pet shows what it wants, then the picture hides.
## Remember the order and serve it. Orders grow from 1 to 3 snacks.

const ROUNDS := [1, 2, 2, 3, 3]

var round_index := 0
var order: Array = []
var served: Array = []
var accepting := false
var _bubble: HBoxContainer
var _bubble_panel: PanelContainer
var _tray: GridContainer
var _customer := {}


func _init() -> void:
	title = "Snack Time"


func start() -> void:
	var v := UI.vbox(16)
	UI.full(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	area.add_child(v)
	_bubble_panel = UI.panel(UI.WHITE, 40)
	_bubble_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bubble_panel.custom_minimum_size = Vector2(380, 150)
	_bubble = UI.hbox(8)
	_bubble_panel.add_child(_bubble)
	v.add_child(_bubble_panel)
	_tray = GridContainer.new()
	_tray.columns = 4
	_tray.add_theme_constant_override("h_separation", 12)
	_tray.add_theme_constant_override("v_separation", 12)
	_tray.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(_tray)
	_next_round()


func _next_round() -> void:
	if round_index >= ROUNDS.size():
		win(4, "Everyone is full and happy!")
		return
	var pets: Array = Game.state.pets
	_customer = pets[Game.rng.randi() % pets.size()]
	stage.set_species(_customer.species, _customer.get("look", ""))
	var foods := Content.FOODS.duplicate()
	foods.shuffle()
	order = foods.slice(0, ROUNDS[round_index])
	served = []
	var tray_foods := foods.slice(0, 8)
	tray_foods.shuffle()
	for c in _tray.get_children():
		c.queue_free()
	for f in tray_foods:
		var b := UI.button("", UI.PAPER)
		b.custom_minimum_size = Vector2(132, 132)
		var icon := UI.food_icon(f, 104)
		UI.full(icon)
		icon.offset_bottom = -10
		b.add_child(icon)
		b.pressed.connect(_serve.bind(f, b))
		_tray.add_child(b)
	say("%s is hungry! Remember the order..." % _customer.name)
	await _show_order(1.6 + 0.9 * order.size())
	say("What did %s want?" % _customer.name)


func _show_order(seconds: float) -> void:
	accepting = false
	for c in _bubble.get_children():
		c.queue_free()
	for f in order:
		var icon := UI.food_icon(f, 110)
		if served.has(f):
			icon.modulate = Color(1, 1, 1, 0.3)
		_bubble.add_child(icon)
	_bubble_panel.modulate.a = 1.0
	await get_tree().create_timer(seconds).timeout
	for c in _bubble.get_children():
		c.queue_free()
	var q := UI.label("?", 80, UI.INK_SOFT)
	_bubble.add_child(q)
	accepting = true


func _serve(food: String, button: Button) -> void:
	if not accepting:
		return
	if order.has(food) and not served.has(food):
		served.append(food)
		button.disabled = true
		Sfx.play("good")
		stage.play("eat", true)
		if served.size() >= order.size():
			accepting = false
			round_index += 1
			say("Yum! Thank you!", false)
			stage.play("gesture-positive", true)
			await get_tree().create_timer(1.3).timeout
			_next_round()
	else:
		Sfx.play("soft")
		say("Not that one. Here, look again!", false)
		await _show_order(1.6)

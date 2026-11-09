class_name AdultGateDialog
extends Control
## "Grown-ups only" check: a PIN if one is set, otherwise a multiplication question.

signal passed
signal closed

var _challenge := {}
var _typed := ""
var _display: Label
var _hint: Label
var _use_pin := false


func _ready() -> void:
	UI.full(self)
	theme = UI.theme()
	add_child(UI.backdrop())
	_use_pin = Game.settings.pin_hash != ""
	_challenge = AdultGate.make_challenge(Game.rng)
	var v := UI.vbox(12)
	var top := UI.hbox()
	var lock := Doodle.new()
	lock.kind = "lock"
	lock.custom_minimum_size = Vector2(48, 48)
	top.add_child(lock)
	top.add_child(UI.label("Grown-ups only", 34))
	v.add_child(top)
	_hint = UI.label("Enter your 4-digit PIN" if _use_pin else "Ask a grown-up to answer:\nWhat is %s ?" % _challenge.question, 26, UI.INK_SOFT)
	v.add_child(_hint)
	_display = UI.label(" ", 44)
	_display.custom_minimum_size = Vector2(0, 70)
	var disp_panel := UI.panel(UI.WHITE, 20)
	disp_panel.add_child(_display)
	v.add_child(disp_panel)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "<", "0", "OK"]:
		var b := UI.button(key, UI.LEAF if key == "OK" else (UI.CORAL if key == "<" else UI.PAPER), 30)
		b.custom_minimum_size = Vector2(110, 70)
		b.pressed.connect(_on_key.bind(key))
		grid.add_child(b)
	var gc := CenterContainer.new()
	gc.add_child(grid)
	v.add_child(gc)
	var cancel := UI.button("Back", UI.PAPER, 24)
	cancel.custom_minimum_size = Vector2(0, 60)
	cancel.pressed.connect(func(): closed.emit(); queue_free())
	v.add_child(cancel)
	add_child(UI.centered(v, Vector2(460, 0)))


func _on_key(key: String) -> void:
	if key == "<":
		_typed = _typed.substr(0, maxi(0, _typed.length() - 1))
	elif key == "OK":
		_submit()
		return
	elif _typed.length() < 4:
		_typed += key
	_display.text = "•".repeat(_typed.length()) if _use_pin else _typed
	if _display.text == "":
		_display.text = " "


func _submit() -> void:
	var ok := AdultGate.check_pin(Game.settings.pin_hash, _typed) if _use_pin else AdultGate.check_answer(_challenge, _typed)
	if ok:
		Sfx.play("good")
		passed.emit()
		queue_free()
		return
	Sfx.play("oops")
	_typed = ""
	_display.text = " "
	if not _use_pin:
		_challenge = AdultGate.make_challenge(Game.rng)
		_hint.text = "Not quite. Ask a grown-up:\nWhat is %s ?" % _challenge.question
	else:
		_hint.text = "That PIN did not match. Try again."


## Open the gate on top of `host`; `on_pass` runs only after a correct answer.
static func ask(host: Node, on_pass: Callable) -> void:
	var g := AdultGateDialog.new()
	g.passed.connect(on_pass)
	host.add_child(g)

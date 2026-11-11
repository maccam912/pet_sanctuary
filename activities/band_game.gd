class_name BandGame
extends Activity
## Pet Band: the pets play a tune one after another, then you play it back in
## the same order. A wrong note just means "listen again". Each pet sings with
## the animal sound recorded in the booth (or a plucked note until there is one).

const ROUNDS := [2, 3, 3, 4, 5]
const PAD_COLORS := [UI.CORAL, UI.SKY, UI.SUN, UI.LEAF]
const PITCHES := [0.8, 1.0, 1.25, 1.5]

var players: Array = []    # the pets in the band (save-data entries)
var pads: Array[Button] = []
var tune: Array = []       # pad numbers, in order
var step := 0
var round_index := 0
var listening := false     # true while the child may play
var slips := 0


func _init() -> void:
	title = "Pet Band"


func start() -> void:
	players = Game.state.pets.duplicate()
	players.shuffle()
	players = players.slice(0, 4)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	var cc := CenterContainer.new()
	UI.full(cc)
	cc.add_child(grid)
	area.add_child(cc)
	for i in players.size():
		var b := UI.button("", PAD_COLORS[i])
		b.custom_minimum_size = Vector2(270, 220)
		var inner := UI.vbox(0)
		UI.full(inner)
		inner.offset_bottom = -10
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(UI.pet_picture(players[i], 140))
		inner.add_child(UI.label(players[i].name, 26))
		b.add_child(inner)
		b.pressed.connect(tap.bind(i))
		grid.add_child(b)
		pads.append(b)
	say("The pets made a band! Listen to the tune, then play it back.")
	await get_tree().create_timer(2.2).timeout
	_new_tune()


func _new_tune() -> void:
	tune.clear()
	for i in ROUNDS[round_index]:
		tune.append(Game.rng.randi() % pads.size())
	_play_tune()


func _play_tune() -> void:
	listening = false
	step = 0
	say("Listen...", false)
	await get_tree().create_timer(0.6).timeout
	for i in tune:
		await _note(i)
		await get_tree().create_timer(0.15).timeout
	listening = true
	say("Your turn! Play it back.", false)


## One pet sings: its pad lights up while its sound plays.
func _note(i: int) -> void:
	var seconds := 0.5
	var sp: String = players[i].species
	if Sfx.animal(sp, "happy"):
		seconds = clampf(Game.listen.animal_stream(sp, "happy").get_length() + 0.1, 0.5, 1.4)
	else:
		Sfx.play("soft", PITCHES[i])
	var pad := pads[i]
	UI.recolor(pad, UI.WHITE)
	pad.pivot_offset = pad.size / 2.0
	pad.scale = Vector2.ONE * 1.06
	await get_tree().create_timer(seconds).timeout
	UI.recolor(pad, PAD_COLORS[i])
	pad.scale = Vector2.ONE


func tap(i: int) -> void:
	if not listening:
		return
	if tune[step] != i:
		# A slip costs nothing: hear the same tune again.
		listening = false
		slips += 1
		Sfx.play("soft2", 0.7)
		say("Oops! That's OK. Listen one more time.")
		await get_tree().create_timer(2.4).timeout
		_play_tune()
		return
	step += 1
	if step < tune.size():
		_note(i)
		return
	listening = false
	await _note(i)
	round_index += 1
	stage.play("gesture-positive", true)
	Sfx.play("good")
	if round_index >= ROUNDS.size():
		win(5, "You kept trying, and the band got it. That is how learning works!" if slips > 0 else "What a band! You played every tune!")
		return
	say("Yes! Here comes a longer tune.")
	await get_tree().create_timer(2.0).timeout
	_new_tune()

class_name Sanctuary
extends Node3D
## The main game: the living 3D sanctuary, its HUD, and the director loop that
## makes a pet need help every so often.

signal quit_to_title

const PITCH := deg_to_rad(41.0)
const GROW_SECONDS := 60.0
const PETTING_REST := 60.0  # seconds before the same pet gives another heart for petting
const STATION_COLORS := {"snack": UI.SUN, "blocks": UI.CORAL, "cards": UI.SKY, "hide": UI.LEAF, "garden": UI.PINK, "calm": UI.LAVENDER,
	"booth": UI.CREAM, "dig": UI.SUN, "band": UI.LAVENDER, "art": UI.PINK}
const GARDEN_BLOOMS := ["flower_redA", "crop_pumpkin", "flower_yellowA", "crop_carrot", "flower_purpleA", "crop_melon"]

var world: WorldBuilder
var cam: Camera3D
var pets: Array[Pet] = []
var cam_target := Vector3(0, 0, 2.5)
var cam_dist := 34.0

var _root: Control
var _markers: Control
var _overlays: Control
var _hearts_label: Label
var _next_label: Label
var _toast: PanelContainer
var _toast_label: Label
var _station_buttons := {}
var _help_bubble: Button
var _gate_button: Button
var _pet_card: Control
var _selected: Pet
var _help_pet: Pet
var _help_scenario := {}
var _moment_left := 60.0
var _autosave := 20.0
var _session := 0.0
var _session_warned := false
var _touches := {}
var _moved := false
var _last_reward := {}       # pet index -> time of last small heart reward
var _garden_nodes: Array = []
var _garden_panel: GardenPanel
var _hide := {"active": false, "pets": [], "found": 0, "hop": 2.0}
var _clock := 0.0


func _ready() -> void:
	world = WorldBuilder.new()
	add_child(world)
	cam = Camera3D.new()
	cam.fov = 40.0
	add_child(cam)
	cam.make_current()
	for i in Game.state.pets.size():
		_spawn_pet(i, world.random_walkable(Game.rng))
	_garden_nodes.resize(6)
	_build_ui()
	_refresh_garden()
	_refresh_hud()
	Game.hearts_changed.connect(func(_n): _refresh_hud())
	_moment_left = Director.next_moment_delay(Game.state, Game.rng)
	Sfx.music("main")
	if Game.state.moments_done == 0 and Game.state.play_seconds < 5.0:
		toast("Welcome, helper! Tap a pet to say hello.", 5.0)


func _spawn_pet(index: int, pos: Vector3) -> Pet:
	var pet := Pet.new()
	add_child(pet)
	pet.setup(Game.state.pets[index], index, world)
	pet.position = pos
	pets.append(pet)
	return pet


# ---------------------------------------------------------------- UI ----

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_root = UI.full(Control.new())
	_root.theme = UI.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_root)
	_markers = UI.full(Control.new())
	_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_markers)
	for id in WorldBuilder.STATION_LABELS:
		var b := UI.button(WorldBuilder.STATION_LABELS[id], STATION_COLORS[id], 22)
		b.custom_minimum_size = Vector2(0, 54)
		b.pressed.connect(_on_station.bind(id))
		_markers.add_child(b)
		_station_buttons[id] = b
	_gate_button = UI.button("New friend!", UI.SUN, 24)
	_gate_button.custom_minimum_size = Vector2(0, 64)
	_gate_button.pressed.connect(_welcome_new_pet)
	_markers.add_child(_gate_button)
	_help_bubble = UI.icon_button("storm", UI.CREAM, 92)
	_help_bubble.pressed.connect(_start_moment)
	_help_bubble.visible = false
	_markers.add_child(_help_bubble)

	# Top bar
	var bar := UI.hbox(12)
	bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 20
	bar.offset_right = -20
	bar.offset_top = 16
	bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bar)
	var hearts := UI.panel(UI.CREAM, 30)
	var hrow := UI.hbox(8)
	var heart := Doodle.new()
	heart.kind = "heart"
	heart.custom_minimum_size = Vector2(40, 40)
	hrow.add_child(heart)
	_hearts_label = UI.label("0", 32)
	hrow.add_child(_hearts_label)
	hearts.add_child(hrow)
	hearts.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.add_child(hearts)
	var next := UI.panel(UI.CREAM, 30)
	var nrow := UI.hbox(6)
	var paw := Doodle.new()
	paw.kind = "paw"
	paw.tint = UI.INK_SOFT
	paw.custom_minimum_size = Vector2(36, 36)
	nrow.add_child(paw)
	_next_label = UI.label("", 24, UI.INK_SOFT)
	nrow.add_child(_next_label)
	next.add_child(nrow)
	next.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bar.add_child(next)
	bar.add_child(UI.spacer())
	var calm := UI.button("Calm Tools", UI.LAVENDER, 24)
	calm.custom_minimum_size = Vector2(190, 84)
	calm.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	calm.pressed.connect(_open_toolbox)
	bar.add_child(calm)
	var gear := UI.icon_button("gear")
	gear.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	gear.pressed.connect(_open_settings)
	bar.add_child(gear)

	_toast = UI.panel(UI.CREAM, 30)
	_toast_label = UI.text("", 28)
	_toast_label.custom_minimum_size = Vector2(560, 0)
	_toast.add_child(_toast_label)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 120
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	_root.add_child(_toast)

	_overlays = UI.full(Control.new())
	_overlays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_overlays)


func toast(text: String, seconds := 3.5) -> void:
	_toast_label.text = text
	_toast.reset_size()
	Sfx.say(text)
	var tw := create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(seconds)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _refresh_hud() -> void:
	var s := Game.state
	_hearts_label.text = str(s.hearts)
	_next_label.get_parent().get_parent().visible = s.roster_left() > 0
	_next_label.text = "New friend: %d / %d" % [mini(s.hearts, s.arrival_cost()), s.arrival_cost()]


func overlay_open() -> bool:
	return _overlays.get_child_count() > 0


func _open(overlay: Control) -> void:
	_deselect()
	_overlays.add_child(overlay)


# ------------------------------------------------------------- frame ----

func _process(delta: float) -> void:
	_clock += delta
	Game.state.play_seconds += delta
	_update_camera(delta)
	_update_markers()
	_grow_garden(delta)
	_autosave -= delta
	if _autosave <= 0.0:
		_autosave = 20.0
		Game.save()
	if overlay_open():
		return
	_session += delta
	var limit := float(Game.state.adult.session_minutes) * 60.0
	if limit > 0.0 and _session > limit and not _session_warned:
		_session_warned = true
		_show_sleepy()
		return
	if _hide.active:
		_hide.hop -= delta
		if _hide.hop <= 0.0:
			_hide.hop = randf_range(1.8, 3.2)
			var hidden: Array = _hide.pets.filter(func(p): return p.busy)
			if not hidden.is_empty():
				hidden[randi() % hidden.size()].hop()
				Sfx.play("soft2", randf_range(1.1, 1.5))
		return
	if _help_pet == null:
		_moment_left -= delta
		if _moment_left <= 0.0:
			_begin_help()


func _update_camera(delta: float) -> void:
	cam_target.x = clampf(cam_target.x, -12.0, 12.0)
	cam_target.z = clampf(cam_target.z, -8.0, 12.0)
	var want := cam_target + Vector3(0, sin(PITCH) * cam_dist, cos(PITCH) * cam_dist)
	cam.position = cam.position.lerp(want, minf(1.0, delta * 8.0)) if cam.position != Vector3.ZERO else want
	cam.rotation = Vector3(-PITCH, 0, 0)


func _screen(p: Vector3) -> Vector2:
	return cam.unproject_position(p)


func _update_markers() -> void:
	var show: bool = not overlay_open() and not _hide.active
	_markers.visible = show
	if not show:
		return
	for id in _station_buttons:
		var b: Button = _station_buttons[id]
		b.position = _screen(WorldBuilder.STATIONS[id] + Vector3(0, 4.2, 0)) - b.size / 2.0
	_gate_button.visible = Game.state.can_welcome() and _help_pet == null
	if _gate_button.visible:
		_gate_button.position = _screen(WorldBuilder.STATIONS.gate + Vector3(0, 3.0, 0)) - _gate_button.size / 2.0
		_gate_button.scale = Vector2.ONE * (1.0 + sin(_clock * 4.0) * 0.04)
	_help_bubble.visible = _help_pet != null
	if _help_pet:
		var p := _screen(_help_pet.head_height() + Vector3(0, 0.9, 0))
		_help_bubble.position = p - _help_bubble.size / 2.0 + Vector2(0, sin(_clock * 3.0) * 8.0)
	if _pet_card and _selected:
		pass


# ------------------------------------------------------------- input ----

func _unhandled_input(event: InputEvent) -> void:
	if overlay_open():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_moved = false
		else:
			if _touches.size() == 1 and not _moved:
				_tap(event.position)
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		if _touches.size() >= 2 and _touches.has(event.index):
			var other := Vector2.ZERO
			for k in _touches:
				if k != event.index:
					other = _touches[k]
			var before: float = (_touches[event.index] - other).length()
			var after: float = (event.position - other).length()
			if before > 10.0 and after > 10.0:
				cam_dist = clampf(cam_dist * before / after, 14.0, 40.0)
			_touches[event.index] = event.position
			_moved = true
		elif _touches.has(event.index):
			if event.position.distance_to(_touches[event.index]) > 14.0 or _moved:
				_moved = true
				_touches[event.index] = event.position
				var k := cam_dist * 0.0021
				cam_target.x -= event.relative.x * k
				cam_target.z -= event.relative.y * k / sin(PITCH)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = clampf(cam_dist * 0.92, 14.0, 40.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = clampf(cam_dist * 1.08, 14.0, 40.0)
	elif event is InputEventMagnifyGesture:
		cam_dist = clampf(cam_dist / event.factor, 14.0, 40.0)


func _pet_at(screen_pos: Vector2, candidates: Array) -> Pet:
	var best: Pet = null
	var best_d := 95.0 * (27.0 / cam_dist)
	for pet in candidates:
		var d := _screen(pet.global_position + Vector3(0, 0.8, 0)).distance_to(screen_pos)
		if d < best_d:
			best_d = d
			best = pet
	return best


func _tap(pos: Vector2) -> void:
	if _hide.active:
		var found := _pet_at(pos, _hide.pets.filter(func(p): return p.busy))
		if found:
			_found_hider(found)
		return
	var pet := _pet_at(pos, pets)
	if pet == null:
		_deselect()
	elif pet == _help_pet:
		_start_moment()
	else:
		_select(pet)


# --------------------------------------------------------- pet card ----

func _deselect() -> void:
	if _pet_card:
		_pet_card.queue_free()
		_pet_card = null
	if _selected and not _hide.active:
		_selected.busy = false
	_selected = null


func _select(pet: Pet) -> void:
	_deselect()
	if pet.busy:
		return
	_selected = pet
	pet.busy = true
	pet.stop()
	pet.face_camera()
	pet.play("gesture-positive")
	pet.anim.queue("idle")
	Sfx.play("soft")
	Sfx.animal(pet.info.species, "happy")
	var card := UI.panel(UI.CREAM, 34)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card.offset_bottom = -18
	var row := UI.hbox(14)
	row.add_child(UI.pet_picture(pet.info, 100))
	var names := UI.vbox(2)
	var name_row := UI.hbox(8)
	name_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	name_row.add_child(UI.label(pet.info.name, 34, UI.INK, false))
	var rename := UI.icon_button("pencil", UI.PAPER, 52)
	rename.pressed.connect(_rename.bind(pet))
	name_row.add_child(rename)
	names.add_child(name_row)
	var friends := UI.hbox(2)
	friends.alignment = BoxContainer.ALIGNMENT_BEGIN
	for i in 5:
		var h := Doodle.new()
		h.kind = "heart"
		h.custom_minimum_size = Vector2(26, 26)
		if int(pet.info.friendship) < (i + 1) * 4:
			h.tint = Color(0.85, 0.82, 0.78)
		friends.add_child(h)
	names.add_child(friends)
	var pet_trait := Content.trait_of(pet.info.species)
	if pet_trait != "":
		names.add_child(UI.label(Content.TRAIT_LABELS[pet_trait], 18, UI.INK_SOFT, false))
	row.add_child(names)
	for action in [["Pet", UI.PINK], ["Treat", UI.SUN], ["Fetch", UI.SKY], ["Dance", UI.LAVENDER]]:
		var b := UI.button(action[0], action[1], 26)
		b.custom_minimum_size = Vector2(124, 84)
		b.pressed.connect(_pet_action.bind(pet, action[0]))
		row.add_child(b)
	var x := UI.icon_button("x", UI.PAPER, 64)
	x.pressed.connect(_deselect)
	row.add_child(x)
	card.add_child(row)
	_root.add_child(card)
	_root.move_child(card, _overlays.get_index())
	_pet_card = card
	UI.fade_in(card, 0.15)
	Sfx.say(pet.info.name)


## Anyone can give a pet a new name, any time: the pencil on its card.
func _rename(pet: Pet) -> void:
	var namer := PetNamer.new(pet.info, "What should we call %s?" % pet.info.name)
	_open(namer)
	var new_name: String = await namer.done
	if new_name != "":
		pet.info.name = new_name
		Game.save()
	_select(pet)


func _small_reward(pet: Pet) -> void:
	var last: float = _last_reward.get(pet.index, -100.0)
	if _clock - last < PETTING_REST:
		return
	_last_reward[pet.index] = _clock
	pet.info.friendship = int(pet.info.friendship) + 1
	Game.add_hearts(1)
	_float_heart(pet)


func _float_heart(pet: Pet) -> void:
	var h := Doodle.new()
	h.kind = "heart"
	h.size = Vector2(54, 54)
	h.position = _screen(pet.head_height()) - h.size / 2.0
	_root.add_child(h)
	var tw := h.create_tween().set_parallel()
	tw.tween_property(h, "position:y", h.position.y - 110.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(h, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(h.queue_free)
	Sfx.play("pop", 1.3)


func _pet_action(pet: Pet, action: String) -> void:
	if pet != _selected:
		return
	match action:
		"Pet":
			pet.cheer()
			_small_reward(pet)
		"Dance":
			pet.play("dance")
			Sfx.jingle(randi() % 5)
			Sfx.animal(pet.info.species, "happy")
			_small_reward(pet)
			await get_tree().create_timer(3.0).timeout
			if is_instance_valid(pet) and pet == _selected:
				pet.play("idle")
		"Treat":
			var food: Node3D = load("res://assets/food/%s.glb" % Content.FOODS[randi() % Content.FOODS.size()]).instantiate()
			food.scale = Vector3.ONE * 1.6
			add_child(food)
			food.position = pet.position + Vector3(0, 0, 1.3)
			pet.play("eat")
			Sfx.play("pop")
			var tw := food.create_tween()
			tw.tween_interval(1.2)
			tw.tween_property(food, "scale", Vector3.ONE * 0.01, 0.6)
			tw.tween_callback(food.queue_free)
			await tw.finished
			if is_instance_valid(pet):
				pet.cheer()
				_small_reward(pet)
		"Fetch":
			_fetch(pet)


func _fetch(pet: Pet) -> void:
	var home := pet.position
	var dest := home
	for i in 20:
		var a := randf() * TAU
		var p := home + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 7.0)
		if world.walkable(p):
			dest = p
			break
	var ball := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	ball.mesh = sphere
	ball.material_override = WorldBuilder.flat_mat(UI.CORAL, 0.5)
	add_child(ball)
	ball.position = home + Vector3(0, 1.5, 0.8)
	Sfx.play("up")
	var tw := ball.create_tween().set_parallel()
	tw.tween_property(ball, "position:x", dest.x, 0.7)
	tw.tween_property(ball, "position:z", dest.z, 0.7)
	tw.tween_property(ball, "position:y", 4.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_property(ball, "position:y", 0.35, 0.35).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_deselect()
	pet.busy = true
	var back_home := func():
		pet.busy = false
		pet.cheer()
		_small_reward(pet)
	var got_ball := func():
		ball.queue_free()
		Sfx.play("pop")
		pet.go_to(home, back_home, true)
	pet.go_to(dest, got_ball, true)


# ----------------------------------------------------- feelings loop ----

func _other_pet(not_this: Pet) -> Pet:
	var others := pets.filter(func(p): return p != not_this)
	return others[randi() % others.size()] if not others.is_empty() else not_this


## A pet gets a big feeling. With no arguments a free pet is picked, and then a
## story that fits that pet.
func _begin_help(scenario := {}, pet: Pet = null) -> void:
	if pet == null:
		var free := pets.filter(func(p): return not p.busy)
		if free.is_empty():
			_moment_left = 10.0
			return
		pet = free[randi() % free.size()]
	if scenario.is_empty():
		scenario = Director.pick_scenario(Game.state, Game.rng, "", Content.trait_of(pet.info.species))
	_help_pet = pet
	_help_scenario = scenario
	pet.needs_help = true
	pet.feeling = scenario.emotion
	pet.stop()
	Sfx.play("question")
	Sfx.animal(pet.info.species, scenario.emotion)
	toast("%s has a big feeling. Tap the cloud to help!" % pet.info.name, 4.0)


func _start_moment() -> void:
	if _help_pet == null or overlay_open():
		return
	var pet := _help_pet
	var flow := FeelingsFlow.new({"mode": "moment", "scenario": _help_scenario, "pet": pet.info,
		"pet_index": pet.index, "friend": _other_pet(pet).info})
	_open(flow)
	await flow.finished
	pet.needs_help = false
	_help_pet = null
	pet.cheer()
	_moment_left = Director.next_moment_delay(Game.state, Game.rng)
	_refresh_hud()
	Game.save()
	Sfx.music("main")


## Used by mini-games after a staged setback: the child and the buddy pet calm
## down together, then the game carries on. Await it.
func calm_together(what_happened: String, pet_info: Dictionary) -> void:
	var index := Game.state.pets.find(pet_info)
	var friend: Dictionary = Game.state.pets[(index + 1) % Game.state.pets.size()]
	var flow := FeelingsFlow.new({"mode": "activity", "scenario": Content.ACTIVITY_FRUSTRATION, "pet": pet_info,
		"pet_index": index, "friend": friend, "story": what_happened})
	_overlays.add_child(flow)
	await flow.finished
	Sfx.music("play")


## The child chooses which animal to invite and what to call it. Hearts are
## only spent once a friend is picked.
func _welcome_new_pet() -> void:
	var s := Game.state
	if not s.can_welcome() or _help_pet != null or overlay_open():
		return
	var picker := FriendPicker.new(Director.arrival_offers(s))
	_open(picker)
	var choice: Dictionary = await picker.done
	if choice.is_empty() or not s.can_welcome():
		return
	Game.add_hearts(-s.arrival_cost())
	s.add_pet(choice.species, choice.look, choice.name)
	var gate: Vector3 = WorldBuilder.STATIONS.gate
	var pet := _spawn_pet(s.pets.size() - 1, gate + Vector3(0, 0, 3.5))
	pet.busy = true
	cam_target = gate + Vector3(0, 0, -4.0)
	Sfx.jingle(1)
	var arrived := func():
		pet.busy = false
		_begin_help(Director.pick_scenario(s, Game.rng, "arrival"), pet)
	pet.go_to(gate + Vector3(0, 0, -3.0), arrived)
	_refresh_hud()
	Game.save()


## Pets a grown-up added in the grown-ups menu walk in through the gate.
func _meet_new_pets() -> void:
	var s := Game.state
	var first := pets.size()
	if s.pets.size() <= first:
		return
	var gate: Vector3 = WorldBuilder.STATIONS.gate
	for i in range(first, s.pets.size()):
		var pet := _spawn_pet(i, gate + Vector3(randf_range(-1.5, 1.5), 0, 3.5))
		var spot := gate + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-6.0, -3.0))
		pet.go_to(spot if world.walkable(spot) else world.random_walkable(Game.rng))
	cam_target = gate + Vector3(0, 0, -4.0)
	Sfx.jingle(1)
	var count := s.pets.size() - first
	var msg := "%s moved in! Tap to say hello." % s.pets[first].name
	if count > 1:
		msg = "%d new friends moved in! Tap to say hello." % count
	toast(msg)
	_refresh_hud()


# --------------------------------------------------------- stations ----

func _random_buddy() -> Dictionary:
	var free := pets.filter(func(p): return p != _help_pet)
	return free[randi() % free.size()].info if not free.is_empty() else pets[0].info


func _on_station(id: String) -> void:
	if overlay_open():
		return
	match id:
		"calm":
			_open_toolbox()
		"garden":
			_garden_panel = GardenPanel.new(self)
			_open(_garden_panel)
		"hide":
			_start_hide()
		"booth":
			var booth := RecordingBooth.new()
			_open(booth)
			await booth.closed
			Sfx.music("main")
		_:
			var game: Activity
			match id:
				"snack": game = SnackGame.new()
				"blocks": game = BlockGame.new()
				"dig": game = DigGame.new()
				"band": game = BandGame.new()
				"art": game = ArtGame.new()
				_: game = CardGame.new()
			game.host = self
			game.buddy = _random_buddy()
			Director.note_activity_play(Game.state, id)
			game.activity_id = id
			_open(game)
			Sfx.music("play")
			var hearts: int = await game.finished
			Sfx.music("main")
			if hearts > 0:
				Game.add_hearts(hearts)
				toast("You earned %d hearts!" % hearts, 2.5)
			Game.save()


func _open_toolbox() -> void:
	if overlay_open():
		return
	var box := Toolbox.new()
	box.practice.connect(func(tool_id: String):
		var buddy := _random_buddy()
		var flow := FeelingsFlow.new({"mode": "practice", "scenario": Content.ACTIVITY_FRUSTRATION, "pet": buddy,
			"pet_index": Game.state.pets.find(buddy), "friend": buddy, "tool": tool_id})
		_overlays.add_child(flow)
		await flow.finished
		_refresh_hud()
		Game.save()
		Sfx.music("main"))
	_open(box)


func _open_settings() -> void:
	if overlay_open():
		return
	var s := SettingsPanel.new(true)
	s.quit_to_title.connect(func(): quit_to_title.emit())
	s.closed.connect(_meet_new_pets)
	_open(s)


func _show_sleepy() -> void:
	var o := UI.full(Control.new())
	o.add_child(UI.backdrop())
	var v := UI.vbox(18)
	v.add_child(Face.new("calm", 120))
	v.get_child(0).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var msg := "The pets are getting sleepy. It's a good time for a break!"
	v.add_child(UI.text(msg, 32))
	var home := UI.button("Save and go home", UI.LEAF, 30)
	home.pressed.connect(func(): quit_to_title.emit())
	v.add_child(home)
	var more := UI.button("A little longer", UI.PAPER, 24)
	more.pressed.connect(o.queue_free)
	v.add_child(more)
	o.add_child(UI.centered(v, Vector2(620, 0)))
	_open(o)
	Sfx.say(msg)


# ------------------------------------------------------ hide & seek ----

func _start_hide() -> void:
	var seekers: Array = pets.filter(func(p): return p != _help_pet)
	seekers.shuffle()
	seekers = seekers.slice(0, 3)
	if seekers.is_empty():
		return
	_deselect()
	Director.note_activity_play(Game.state, "hide")
	var cover := UI.full(Control.new())
	cover.add_child(UI.backdrop(UI.SKY))
	var count := UI.label("Close your eyes...", 64)
	UI.full(count)
	cover.add_child(count)
	_overlays.add_child(cover)
	Sfx.say("Close your eyes. The pets are hiding!")
	var spots := world.hide_spots.duplicate()
	spots.shuffle()
	for i in seekers.size():
		var pet: Pet = seekers[i]
		pet.busy = true
		pet.stop()
		pet.position = spots[i]
		pet.rotation.y = 0.0
	for n in ["3", "2", "1", "Ready or not!"]:
		await get_tree().create_timer(1.0).timeout
		count.text = n
		Sfx.play("tick")
	await get_tree().create_timer(0.7).timeout
	cover.queue_free()
	await get_tree().process_frame
	_hide = {"active": true, "pets": seekers, "found": 0, "hop": 1.5}
	cam_target = Vector3(0, 0, 2.5)
	cam_dist = 32.0
	toast("Find %d hiding friends! Slide to look around." % seekers.size(), 4.0)


func _found_hider(pet: Pet) -> void:
	pet.busy = false
	pet.cheer()
	Sfx.play("good")
	_float_heart(pet)
	_hide.found += 1
	pet.go_to(world.random_walkable(Game.rng), Callable(), true)
	if _hide.found >= _hide.pets.size():
		_hide.active = false
		Game.add_hearts(4)
		Sfx.jingle(2)
		toast("You found everyone! 4 hearts!", 3.0)
		Game.save()
	else:
		toast("Found %s! %d more to find." % [pet.info.name, _hide.pets.size() - _hide.found], 2.0)


# ----------------------------------------------------------- garden ----
# Plot stages: 0 empty, 1 sprout growing, 2 thirsty (tap to water),
# 3 growing again, 4 ready to pick.

func _grow_garden(delta: float) -> void:
	var changed := false
	for plot in Game.state.garden:
		if plot.stage == 1 or plot.stage == 3:
			plot.t += delta
			if plot.t >= GROW_SECONDS:
				plot.t = 0.0
				plot.stage += 1
				changed = true
	if changed:
		_refresh_garden()


func garden_tap(i: int) -> void:
	var plot: Dictionary = Game.state.garden[i]
	match int(plot.stage):
		0:
			plot.stage = 1
			plot.t = 0.0
			Sfx.play("pop")
		2:
			plot.stage = 3
			plot.t = 0.0
			Sfx.play("chime")
		4:
			plot.stage = 0
			Game.add_hearts(2)
			Sfx.play("great")
		_:
			Sfx.play("soft")
	_refresh_garden()


func _refresh_garden() -> void:
	var ready := false
	for i in 6:
		var plot: Dictionary = Game.state.garden[i]
		var want := ""
		match int(plot.stage):
			1, 2: want = "crops_leafsStageA"
			3: want = "crops_leafsStageB"
			4: want = GARDEN_BLOOMS[i]
		if plot.stage == 2 or plot.stage == 4:
			ready = true
		var node: Node3D = _garden_nodes[i]
		if node and node.get_meta("kind", "") == want:
			continue
		if node:
			node.queue_free()
			_garden_nodes[i] = null
		if want != "":
			var n := WorldBuilder.model(want, 6.0 if plot.stage == 4 else 5.0)
			n.set_meta("kind", want)
			n.position = world.garden_plots[i].position + Vector3(0, 0.25, 0)
			add_child(n)
			_garden_nodes[i] = n
	_station_buttons.garden.text = "Garden !" if ready else "Garden"
	if _garden_panel and is_instance_valid(_garden_panel):
		_garden_panel.refresh()

class_name WorldBuilder
extends Node3D
## Builds the 3D sanctuary diorama: sky, light, ground, pond, scenery and the
## activity stations. Used by the title screen (as a backdrop) and the game.

const N := "res://assets/nature/%s.glb"
const S := 4.0  # nature kit models are tiny next to the pets

## Where things are. The sanctuary yard is roughly x -13..13, z -10..12.
const STATIONS := {
	"snack": Vector3(-7.5, 0, 0.5),
	"blocks": Vector3(7.5, 0, 2.0),
	"cards": Vector3(0.5, 0, -7.5),
	"hide": Vector3(-10.5, 0, -6.5),
	"garden": Vector3(8.5, 0, 8.5),
	"calm": Vector3(-9.0, 0, 7.5),
	"gate": Vector3(0, 0, 13.0),
	"booth": Vector3(-4.4, 0, 6.2),
	"dig": Vector3(-3.4, 0, -3.4),
	"band": Vector3(-12.2, 0, -1.8),
	"art": Vector3(4.8, 0, 6.6),
}
const STATION_LABELS := {
	"snack": "Snack Time", "blocks": "Block Tower", "cards": "Match Cards",
	"hide": "Hide & Seek", "garden": "Garden", "calm": "Calm Corner",
	"booth": "Recording Booth", "dig": "Treasure Dig", "band": "Pet Band", "art": "Oops Art",
}
const POND := Vector3(9.5, 0, -6.5)
const POND_R := 3.8

var hide_spots: Array[Vector3] = []
var garden_plots: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


static func model(name: String, scale_by := S) -> Node3D:
	var n: Node3D = load(N % name).instantiate()
	n.scale = Vector3.ONE * scale_by
	return n


func place(name: String, pos: Vector3, yaw := 0.0, scale_by := S) -> Node3D:
	var n := model(name, scale_by)
	n.position = pos
	n.rotation.y = yaw
	add_child(n)
	return n


static func flat_mat(color: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


func disc(pos: Vector3, radius: float, color: Color, height := 0.04) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 40
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = flat_mat(color)
	mi.position = pos + Vector3(0, height / 2.0, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _ready() -> void:
	_rng.seed = 20240607
	_build_sky()
	_build_ground()
	_build_pond()
	_build_edge()
	_build_stations()
	_scatter_details()


func _build_sky() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("bfe8ff")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff3e0")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 35, 0)
	sun.light_color = Color("fff1d6")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.shadow_opacity = 0.55
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(220, 220)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = flat_mat(Color("7cc462"))
	add_child(ground)
	# Lighter yard and sandy paths.
	var yard := disc(Vector3(0, 0, 1), 15.5, Color("93d672"), 0.03)
	yard.scale = Vector3(1.0, 1.0, 0.82)
	var sand := Color("ecd093")
	disc(Vector3(0, 0, 1), 3.2, sand, 0.06)
	for id in ["snack", "blocks", "cards", "garden", "calm", "gate", "booth", "dig", "band", "art"]:
		var to: Vector3 = STATIONS[id]
		var from := Vector3(0, 0, 1)
		var steps := int(from.distance_to(to) / 1.5)
		for i in range(1, steps + 1):
			var p := from.lerp(to, float(i) / steps)
			disc(p + Vector3(_rng.randf_range(-0.2, 0.2), 0, _rng.randf_range(-0.2, 0.2)), _rng.randf_range(0.75, 1.0), sand, 0.05)
	# Campfire meeting spot in the middle.
	place("campfire_stones", Vector3(0, 0.05, 1), 0, 5.0)
	place("campfire_logs", Vector3(0, 0.05, 1), 0, 5.0)
	place("log", Vector3(-2.4, 0, 1.4), 0.3)
	place("log", Vector3(2.3, 0, 0.2), -0.4)


func _build_pond() -> void:
	disc(POND, POND_R + 0.5, Color("e3cf9c"), 0.05)
	var water := disc(POND, POND_R, Color("6cc6ea"), 0.09)
	(water.material_override as StandardMaterial3D).roughness = 0.15
	for i in 5:
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(0.5, POND_R - 0.8)
		place("lily_large" if i % 2 == 0 else "lily_small", POND + Vector3(cos(a) * d, 0.1, sin(a) * d), a)
	place("rock_smallA", POND + Vector3(-POND_R, 0, 1.0), 0.5)
	place("rock_smallB", POND + Vector3(POND_R - 0.4, 0, 2.2), 1.5)
	place("canoe", POND + Vector3(0.6, 0.1, -1.2), 0.9, 3.2)
	place("plant_flatTall", POND + Vector3(2.4, 0, -3.0), 0.0)
	place("plant_flatTall", POND + Vector3(-3.4, 0, -1.8), 1.0)


## A ring of trees, bushes and rocks so the world feels tucked in and cozy.
func _build_edge() -> void:
	var trees := ["tree_default", "tree_oak", "tree_detailed", "tree_fat", "tree_tall", "tree_simple",
		"tree_cone", "tree_plateau", "tree_pineRoundA", "tree_small", "tree_thin", "tree_default_fall", "tree_oak_fall"]
	for ring in 3:
		var count := 30 + ring * 8
		for i in count:
			var a := TAU * i / count + _rng.randf_range(-0.06, 0.06)
			var rx := 18.5 + ring * 5.0 + _rng.randf_range(-1.0, 1.0)
			var rz := 15.5 + ring * 5.0 + _rng.randf_range(-1.0, 1.0)
			var p := Vector3(cos(a) * rx, 0, sin(a) * rz + 1.0)
			# Leave the view from the camera (south) more open on the first ring.
			if ring == 0 and p.z > 9.0 and absf(p.x) < 16.0:
				continue
			place(trees[_rng.randi() % trees.size()], p, _rng.randf() * TAU, S * _rng.randf_range(1.0, 1.5))
	# Front gate with a little fence on both sides.
	var gate: Vector3 = STATIONS.gate
	place("fence_gate", gate + Vector3(0, 0, 2.0), 0, S)
	for i in range(1, 5):
		place("fence_simple", gate + Vector3(i * S, 0, 2.0), 0, S)
		place("fence_simple", gate + Vector3(-i * S, 0, 2.0), 0, S)
	place("sign", gate + Vector3(3.0, 0, -0.6), -0.3, 5.0)
	# Bushes to hide behind (Hide & Seek uses these spots).
	var bush_spots := [Vector3(-12.5, 0, -4), Vector3(-8, 0, -9.5), Vector3(-4.5, 0, -8.5), Vector3(4.5, 0, -9.5),
		Vector3(12.5, 0, -1.5), Vector3(12.5, 0, 5.5), Vector3(-13, 0, 2.5), Vector3(3.5, 0, 9.5), Vector3(-4.0, 0, 10.0)]
	for b in bush_spots:
		place("plant_bushLarge", b, _rng.randf() * TAU, 9.0)
		place("plant_bushSmall", b + Vector3(1.4, 0, 0.5), _rng.randf() * TAU, 6.0)
		hide_spots.append(b + Vector3(0.2, 0, -1.3))
	# Trees inside the yard to hide behind too.
	for t in [Vector3(-11.5, 0, -8.5), Vector3(-6.5, 0, -6.0), Vector3(5.0, 0, -3.5), Vector3(12.0, 0, 9.5)]:
		place("tree_oak", t, _rng.randf() * TAU, 5.5)
		hide_spots.append(t + Vector3(0.3, 0, -1.6))


func _build_stations() -> void:
	# Snack table: a big stump with fruit.
	var snack: Vector3 = STATIONS.snack
	place("stump_roundDetailed", snack, 0, 6.5)
	for i in 3:
		var food: Node3D = load("res://assets/food/%s.glb" % ["apple", "carrot", "banana"][i]).instantiate()
		food.scale = Vector3.ONE * 1.8
		food.position = snack + Vector3(-0.5 + i * 0.5, 1.38, 0.1 * i)
		add_child(food)
	place("pot_large", snack + Vector3(2.3, 0, -0.6), 0.4)
	place("pot_small", snack + Vector3(-2.2, 0, 0.5), 0.0)
	# Block tower: chunky toy blocks.
	var blocks: Vector3 = STATIONS.blocks
	var cols := [UI.CORAL, UI.SKY, UI.SUN, UI.LEAF, UI.LAVENDER, UI.PINK]
	var spots := [Vector3(0, 0.45, 0), Vector3(0.95, 0.45, 0.1), Vector3(0.45, 1.35, 0.05), Vector3(-1.4, 0.45, 0.7), Vector3(1.9, 0.45, -0.8), Vector3(0.45, 2.25, 0.05)]
	for i in spots.size():
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.9
		mi.mesh = box
		mi.material_override = flat_mat(cols[i], 0.6)
		mi.position = blocks + spots[i]
		mi.rotation.y = _rng.randf_range(-0.4, 0.4)
		add_child(mi)
	# Match cards: stumps as a table and seats.
	var cards: Vector3 = STATIONS.cards
	place("stump_round", cards, 0, 7.0)
	place("stump_round", cards + Vector3(-2.2, 0, 0.8), 0, 5.0)
	place("stump_round", cards + Vector3(2.2, 0, 0.8), 0, 5.0)
	for i in 3:
		var card := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.55, 0.05, 0.75)
		card.mesh = cm
		card.material_override = flat_mat([UI.CORAL, UI.SKY, UI.SUN][i], 0.6)
		card.position = cards + Vector3(-0.6 + i * 0.6, 1.52, 0)
		card.rotation.y = _rng.randf_range(-0.3, 0.3)
		add_child(card)
	# Hide & seek sign.
	place("sign", STATIONS.hide, 0.3, 6.0)
	place("mushroom_redGroup", STATIONS.hide + Vector3(1.3, 0, 0.6), 0.0, 5.0)
	# Garden: six dirt plots (plants are added by the game).
	var garden: Vector3 = STATIONS.garden
	for i in 6:
		var p := garden + Vector3((i % 3 - 1) * 2.1, 0, (i / 3) * 2.1 - 1.0)
		var plot := place("crops_dirtSingle", p, 0, 5.0)
		garden_plots.append(plot)
	place("fence_simple", garden + Vector3(0, 0, -0.6), 0, S)
	place("fence_simple", garden + Vector3(-S, 0, -0.6), 0, S)
	place("fence_simple", garden + Vector3(S, 0, -0.6), 0, S)
	# Calm corner: cozy tent, beds and soft flowers.
	var calm: Vector3 = STATIONS.calm
	place("tent_detailedOpen", calm + Vector3(-1.0, 0, -1.5), 0.5, 7.0)
	place("bed_floor", calm + Vector3(2.4, 0, -0.6), -0.4, 4.5)
	place("bed_floor", calm + Vector3(1.6, 0, 1.6), 0.9, 4.5)
	place("flower_purpleA", calm + Vector3(-3.2, 0, 1.0), 0, 5.0)
	place("flower_purpleB", calm + Vector3(3.6, 0, 1.4), 0, 5.0)
	place("mushroom_tanGroup", calm + Vector3(-2.6, 0, 2.0), 0, 5.0)
	# Recording booth: a little tent with a big microphone outside.
	var booth: Vector3 = STATIONS.booth
	place("tent_smallOpen", booth + Vector3(-0.9, 0, -0.6), 0.4, 5.0)
	_box(booth + Vector3(1.2, 0.9, 0.4), Vector3(0.16, 1.8, 0.16), UI.INK_SOFT)
	var mic := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.42
	ball.height = 0.84
	mic.mesh = ball
	mic.material_override = flat_mat(UI.CORAL, 0.5)
	mic.position = booth + Vector3(1.2, 2.0, 0.4)
	add_child(mic)
	# Treasure dig: a patch of dirt mounds.
	var dig: Vector3 = STATIONS.dig
	for i in 5:
		place("crops_dirtSingle", dig + Vector3((i % 3 - 1) * 1.5, 0, (i / 3) * 1.4 - 0.6), _rng.randf() * TAU, 4.0)
	place("rock_smallA", dig + Vector3(-2.0, 0, 0.9), 0.8)
	# Pet band: stump drums and a log to sit on.
	var band: Vector3 = STATIONS.band
	place("stump_round", band + Vector3(-0.9, 0, 0), 0, 5.5)
	place("stump_round", band + Vector3(0.7, 0, -0.5), 0, 4.0)
	place("log", band + Vector3(0.2, 0, 1.4), 1.5)
	# Oops art: an easel with a splattery painting.
	var art: Vector3 = STATIONS.art
	for side: float in [-0.6, 0.6]:
		_box(art + Vector3(side, 1.0, 0.25), Vector3(0.14, 2.0, 0.14), Color("b98a5e"))
	var board := _box(art + Vector3(0, 1.5, 0.12), Vector3(1.9, 1.5, 0.1), UI.WHITE)
	board.rotation.x = -0.15
	for i in 5:
		var blob := _box(art + Vector3(-0.6 + 0.3 * i, 1.2 + 0.25 * (i % 3), 0.22 - 0.035 * (i % 3)), Vector3(0.34, 0.34, 0.06), [UI.CORAL, UI.SKY, UI.SUN, UI.LEAF, UI.LAVENDER][i])
		blob.rotation.z = _rng.randf() * TAU


func _box(pos: Vector3, box_size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mi.mesh = mesh
	mi.material_override = flat_mat(color, 0.6)
	mi.position = pos
	add_child(mi)
	return mi


func _scatter_details() -> void:
	var bits := ["flower_redA", "flower_redB", "flower_yellowA", "flower_yellowB", "flower_purpleA",
		"grass", "grass_large", "grass_leafs", "grass", "grass_large", "mushroom_red", "mushroom_tan", "rock_smallC"]
	var placed := 0
	var tries := 0
	while placed < 90 and tries < 600:
		tries += 1
		var p := Vector3(_rng.randf_range(-16, 16), 0, _rng.randf_range(-11, 13))
		if _near_something(p):
			continue
		place(bits[_rng.randi() % bits.size()], p, _rng.randf() * TAU, S * _rng.randf_range(0.9, 1.3))
		placed += 1
	place("rock_largeA", Vector3(-14.5, 0, -8.5), 0.4)
	place("rock_largeB", Vector3(14.5, 0, 12.0), 1.4)
	place("log_stack", Vector3(13.5, 0, 2.5), 1.2)


func _near_something(p: Vector3) -> bool:
	if p.distance_to(POND) < POND_R + 0.8 or p.distance_to(Vector3(0, 0, 1)) < 3.6:
		return true
	for id in STATIONS:
		if p.distance_to(STATIONS[id]) < 3.2:
			return true
	return false


## True when a pet can stand here (inside the yard, not in the pond or a station).
func walkable(p: Vector3) -> bool:
	if (p.x * p.x) / (13.0 * 13.0) + ((p.z - 1.0) * (p.z - 1.0)) / (9.5 * 9.5) > 1.0:
		return false
	if p.distance_to(POND) < POND_R + 1.2:
		return false
	for id in ["snack", "blocks", "cards", "garden", "calm"]:
		if p.distance_to(STATIONS[id]) < 3.0:
			return false
	for id in ["booth", "dig", "band", "art"]:
		if p.distance_to(STATIONS[id]) < 2.4:
			return false
	return true


func random_walkable(rng: RandomNumberGenerator) -> Vector3:
	for i in 40:
		var p := Vector3(rng.randf_range(-13, 13), 0, rng.randf_range(-8.5, 10.5))
		if walkable(p):
			return p
	return Vector3(0, 0, 4)

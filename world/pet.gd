class_name Pet
extends Node3D
## One resident pet in the 3D world: model, animation, wandering and reactions.

const LOOPS := ["idle", "walk", "run", "dance", "eat"]

var info: Dictionary   # the save-data entry {species, name, friendship}
var index := 0
var world: WorldBuilder
var anim: AnimationPlayer
var model: Node3D
var needs_help := false
var busy := false       # true while the game is directing this pet

var _target := Vector3.ZERO
var _moving := false
var _run := false
var _wait := 0.0
var _on_arrive := Callable()
var _fuss := 0.0


static func make_model(species: String) -> Node3D:
	return load("res://assets/pets/animal-%s.glb" % species).instantiate()


static func find_anim(root: Node) -> AnimationPlayer:
	for c in root.find_children("*", "AnimationPlayer", true, false):
		var ap := c as AnimationPlayer
		for a in LOOPS:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		return ap
	return null


func setup(pet_info: Dictionary, pet_index: int, world_ref: WorldBuilder) -> void:
	info = pet_info
	index = pet_index
	world = world_ref
	model = make_model(info.species)
	add_child(model)
	anim = find_anim(model)
	play("idle")
	_wait = randf_range(0.5, 4.0)


func play(a: String) -> void:
	if anim and anim.has_animation(a) and anim.current_animation != a:
		anim.play(a, 0.2)


func _process(delta: float) -> void:
	if _moving:
		var to := _target - position
		to.y = 0
		var dist := to.length()
		var speed := 5.5 if _run else 2.2
		if dist < 0.15:
			_moving = false
			play("idle")
			if _on_arrive.is_valid():
				var cb := _on_arrive
				_on_arrive = Callable()
				cb.call()
		else:
			var dir := to / dist
			position += dir * minf(speed * delta, dist)
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 9.0))
		return
	if busy:
		return
	if needs_help:
		# Show the feeling in the body: stompy / shaky now and then.
		_fuss -= delta
		if _fuss <= 0.0:
			_fuss = randf_range(2.5, 4.5)
			play("gesture-negative")
			if anim:
				anim.queue("idle")
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = randf_range(3.0, 9.0)
		if randf() < 0.75 and world:
			go_to(world.random_walkable(Game.rng))
		else:
			play("idle")


func go_to(pos: Vector3, on_arrive := Callable(), run := false) -> void:
	_target = Vector3(pos.x, 0, pos.z)
	_moving = true
	_run = run
	_on_arrive = on_arrive
	play("run" if run else "walk")


func stop() -> void:
	_moving = false
	_on_arrive = Callable()
	play("idle")


func face_camera() -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation:y", 0.0, 0.3)


## Little jump for joy.
func hop() -> void:
	var tw := create_tween()
	tw.tween_property(model, "position:y", 0.9, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(model, "position:y", 0.0, 0.22).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


func cheer() -> void:
	hop()
	play("gesture-positive")
	if anim:
		anim.queue("idle")


func head_height() -> Vector3:
	return global_position + Vector3(0, 2.1, 0)

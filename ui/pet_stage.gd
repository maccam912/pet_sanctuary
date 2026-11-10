class_name PetStage
extends SubViewportContainer
## A close-up 3D pet on a little grass stage, shown inside the 2D screens.
## Exercises drive it: `breath` swells the pet, `shake` makes it tremble.

var species := "dog"
var look := ""
var breath := 1.0
var shake := 0.0
var squash := 1.0   # 1 = normal, <1 = tucked / melted
var stress := 0.0   # 0..1: draws jagged "big feeling" marks around the pet
var stress_color := Color("ef6f5e")

var _vp: SubViewport
var _holder: Node3D
var _model: Node3D
var _anim: AnimationPlayer
var _t := 0.0
var _marks: Control


func _init(pet_species := "dog", px := 380, pet_look := "") -> void:
	species = pet_species
	look = pet_look
	custom_minimum_size = Vector2(px, px)
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_2X
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff3e0")
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 30, 0)
	sun.light_energy = 1.2
	_vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0, 1.75, 5.0)
	_vp.add_child(cam)
	cam.look_at(Vector3(0, 0.72, 0))
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.5
	floor_mesh.bottom_radius = 1.5
	floor_mesh.height = 0.12
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.material_override = WorldBuilder.flat_mat(Color("a5dd84"))
	floor_node.position.y = -0.06
	_vp.add_child(floor_node)
	_holder = Node3D.new()
	_holder.rotation.y = 0.35
	_vp.add_child(_holder)
	set_species(species, look)
	_marks = Control.new()
	_marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.draw.connect(_draw_marks)
	add_child(_marks)


func _draw_marks() -> void:
	if stress <= 0.02:
		return
	var s := size.x
	var wob := sin(_t * 9.0) * 0.08
	for side: float in [-1.0, 1.0]:
		var origin := Vector2(s * (0.5 + side * 0.33), s * 0.3)
		for i in 3:
			var ang := -PI / 2.0 + side * (0.45 + i * 0.42) + wob * side
			var dir := Vector2.from_angle(ang)
			var a := origin + dir * s * 0.07
			var b := origin + dir * s * (0.1 + 0.07 * stress)
			_marks.draw_line(a, b, stress_color, 5.0 + 5.0 * stress, true)


func set_species(sp: String, pet_look := "") -> void:
	species = sp
	look = pet_look
	if _model:
		_model.queue_free()
	_model = Pet.make_model(sp, look)
	_holder.add_child(_model)
	_anim = Pet.find_anim(_model)
	play("idle")


func play(a: String, then_idle := false) -> void:
	if _anim and _anim.has_animation(a):
		_anim.play(a, 0.2)
		if then_idle:
			_anim.queue("idle")


func _process(delta: float) -> void:
	if _holder == null:
		return
	_t += delta
	var jitter := Vector3.ZERO
	if shake > 0.0:
		jitter = Vector3(sin(_t * 47.0), 0, cos(_t * 53.0)) * 0.035 * shake
	_holder.position = jitter
	if _marks and (stress > 0.02 or _marks.has_meta("drawn")):
		_marks.set_meta("drawn", stress > 0.02)
		_marks.queue_redraw()
	_holder.scale = Vector3(breath * (2.0 - squash), breath * squash, breath * (2.0 - squash))

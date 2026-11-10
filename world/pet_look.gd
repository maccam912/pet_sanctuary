class_name PetLook
extends RefCounted
## Special colours for pets (Content.LOOKS). The same recolouring is used on
## the 3D model and on the flat picture, so a rose fox looks rose everywhere.

const RECOLOR := """
uniform float hue = 0.0;
uniform vec3 tint : source_color = vec3(1.0);

vec3 recolor(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	vec3 hsv = vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-6)), d / (q.x + 1e-6), q.x);
	vec3 turned = hsv.z * mix(vec3(1.0), clamp(abs(fract(hsv.x + hue + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0), hsv.y);
	// White and grey parts have no colour to turn, so they take the tint.
	return mix(c * tint, turned, smoothstep(0.08, 0.3, hsv.y));
}
"""

static var _shader_3d: Shader
static var _shader_2d: Shader


## Recolours a pet model in place. Does nothing for the everyday look.
static func apply(model: Node3D, look: String) -> void:
	if not Content.LOOKS.has(look):
		return
	if _shader_3d == null:
		_shader_3d = Shader.new()
		_shader_3d.code = "shader_type spatial;\nuniform sampler2D tex : source_color;\n" + RECOLOR + "void fragment() {\n\tALBEDO = recolor(texture(tex, UV).rgb);\n\tROUGHNESS = 1.0;\n}\n"
	var made := {}
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if base == null:
				continue
			if not made.has(base):
				var m := ShaderMaterial.new()
				m.shader = _shader_3d
				m.set_shader_parameter("tex", base.albedo_texture)
				_set_look(m, look)
				made[base] = m
			mi.set_surface_override_material(i, made[base])


## Material for a flat pet picture (null for the everyday look).
static func icon_material(look: String) -> ShaderMaterial:
	if not Content.LOOKS.has(look):
		return null
	if _shader_2d == null:
		_shader_2d = Shader.new()
		_shader_2d.code = "shader_type canvas_item;\n" + RECOLOR + "void fragment() {\n\tvec4 c = texture(TEXTURE, UV);\n\tCOLOR = vec4(recolor(c.rgb), c.a) * COLOR;\n}\n"
	var m := ShaderMaterial.new()
	m.shader = _shader_2d
	_set_look(m, look)
	return m


static func _set_look(m: ShaderMaterial, look: String) -> void:
	m.set_shader_parameter("hue", Content.LOOKS[look].hue)
	var tint: Color = Content.LOOKS[look].tint
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))

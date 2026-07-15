class_name LevelGeometry
extends RefCounted

static func material(color: Color, roughness := 0.86) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

static func add_box(parent: Node3D, name: String, position: Vector3, size: Vector3, color: Color, collision_layer := 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = position
	body.collision_layer = collision_layer
	body.collision_mask = 0
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material(color)
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = size
	shape.shape = collider
	body.add_child(shape)
	return body

static func add_label(parent: Node3D, text: String, position: Vector3, color := Color(0.68, 0.73, 0.76)) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.modulate = color
	label.font_size = 28
	label.outline_size = 8
	label.outline_modulate = Color(0.01, 0.01, 0.02, 0.9)
	label.no_depth_test = true
	parent.add_child(label)
	return label

static func add_light(parent: Node3D, position: Vector3, color: Color, energy := 1.0, range := 8.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	light.shadow_enabled = true
	parent.add_child(light)
	return light


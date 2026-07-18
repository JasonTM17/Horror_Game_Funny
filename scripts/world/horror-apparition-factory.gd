class_name HorrorApparitionFactory
extends RefCounted

static func spawn(
	parent: Node3D,
	position: Vector3,
	actor_name: String,
	actor_scale := Vector3.ONE,
	add_eyes := false
) -> Node3D:
	var apparition := Node3D.new()
	apparition.name = actor_name
	apparition.position = position
	apparition.scale = actor_scale
	parent.add_child(apparition)
	_add_body(apparition)
	_add_head(apparition)
	if add_eyes:
		_add_eye(apparition, "EyeLeft", Vector3(-0.1, 1.07, 0.28))
		_add_eye(apparition, "EyeRight", Vector3(0.1, 1.07, 0.28))
	return apparition

static func _add_body(apparition: Node3D) -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.3
	body_mesh.height = 2.1
	body.mesh = body_mesh
	body.material_override = LevelGeometry.material(Color(0.008, 0.006, 0.01))
	apparition.add_child(body)

static func _add_head(apparition: Node3D) -> void:
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.31
	head_mesh.height = 0.62
	head.mesh = head_mesh
	head.position.y = 1.02
	head.material_override = LevelGeometry.material(Color(0.006, 0.004, 0.008))
	apparition.add_child(head)

static func _add_eye(parent: Node3D, eye_name: String, eye_position: Vector3) -> void:
	var eye := MeshInstance3D.new()
	eye.name = eye_name
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.025
	eye_mesh.height = 0.05
	eye.mesh = eye_mesh
	eye.position = eye_position
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.68, 0.018, 0.012)
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.82, 0.012, 0.006)
	eye_material.emission_energy_multiplier = 1.8
	eye_material.roughness = 0.32
	eye.material_override = eye_material
	parent.add_child(eye)

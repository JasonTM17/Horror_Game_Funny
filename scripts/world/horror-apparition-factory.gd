class_name HorrorApparitionFactory
extends RefCounted

const EYE_EMISSION_ENERGY := 1.8
const EYE_EMISSION_FLASH := 4.2

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
	_add_shoulders(apparition)
	_add_arm(apparition, "ArmLeft", Vector3(-0.42, 0.72, -0.05), Vector3(0.0, 0.0, 0.35))
	_add_arm(apparition, "ArmRight", Vector3(0.42, 0.72, -0.05), Vector3(0.0, 0.0, -0.35))
	_add_head(apparition)
	if add_eyes:
		# Eyes face local -Z so look_at() orients the face toward the player.
		_add_eye(apparition, "EyeLeft", Vector3(-0.1, 1.08, -0.3))
		_add_eye(apparition, "EyeRight", Vector3(0.1, 1.08, -0.3))
	return apparition

static func face_toward(actor: Node3D, world_target: Vector3) -> void:
	if not is_instance_valid(actor):
		return
	var from := actor.global_position
	var flat_target := Vector3(world_target.x, from.y, world_target.z)
	if from.distance_squared_to(flat_target) < 0.0004:
		return
	actor.look_at(flat_target, Vector3.UP)

static func flash_eyes(actor: Node3D, energy := EYE_EMISSION_FLASH) -> void:
	if not is_instance_valid(actor):
		return
	for eye_name in ["EyeLeft", "EyeRight"]:
		var eye := actor.get_node_or_null(eye_name) as MeshInstance3D
		if eye == null:
			continue
		var material := eye.material_override as StandardMaterial3D
		if material == null:
			continue
		material.emission_energy_multiplier = maxf(material.emission_energy_multiplier, energy)

static func _body_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	material.metallic = 0.0
	return material

static func _add_body(apparition: Node3D) -> void:
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 2.05
	body.mesh = body_mesh
	body.position.y = 0.05
	body.material_override = _body_material(Color(0.012, 0.008, 0.014))
	apparition.add_child(body)

static func _add_shoulders(apparition: Node3D) -> void:
	var shoulders := MeshInstance3D.new()
	shoulders.name = "Shoulders"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.82, 0.18, 0.28)
	shoulders.mesh = mesh
	shoulders.position = Vector3(0.0, 0.95, -0.02)
	shoulders.material_override = _body_material(Color(0.01, 0.007, 0.012))
	apparition.add_child(shoulders)

static func _add_arm(
	apparition: Node3D,
	arm_name: String,
	arm_position: Vector3,
	arm_rotation: Vector3
) -> void:
	var arm := MeshInstance3D.new()
	arm.name = arm_name
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.07
	mesh.height = 1.05
	arm.mesh = mesh
	arm.position = arm_position
	arm.rotation = arm_rotation
	arm.material_override = _body_material(Color(0.009, 0.006, 0.011))
	apparition.add_child(arm)

static func _add_head(apparition: Node3D) -> void:
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.29
	head_mesh.height = 0.58
	head.mesh = head_mesh
	# Slightly elongated, forward-tilted head reads more humanoid at distance.
	head.position = Vector3(0.0, 1.08, -0.04)
	head.scale = Vector3(0.92, 1.12, 0.98)
	head.material_override = _body_material(Color(0.008, 0.005, 0.01))
	apparition.add_child(head)

static func _add_eye(parent: Node3D, eye_name: String, eye_position: Vector3) -> void:
	var eye := MeshInstance3D.new()
	eye.name = eye_name
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.032
	eye_mesh.height = 0.064
	eye.mesh = eye_mesh
	eye.position = eye_position
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.72, 0.02, 0.014)
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.9, 0.02, 0.008)
	eye_material.emission_energy_multiplier = EYE_EMISSION_ENERGY
	eye_material.roughness = 0.22
	eye.material_override = eye_material
	parent.add_child(eye)

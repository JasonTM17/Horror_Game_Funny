class_name ChaseEntityVisualBuilder
extends RefCounted

static func build(entity: CharacterBody3D) -> void:
	var silhouette_material := _silhouette_material()
	_add_capsule(entity, "EntityBody", 0.45, 2.5, Vector3(0, 1.25, 0), Vector3.ZERO, silhouette_material)
	var head := _add_sphere(entity, "EntityHead", 0.34, 0.62, Vector3(-0.035, 2.27, -0.01), silhouette_material)
	head.rotation.z = deg_to_rad(-8.0)
	_add_capsule(entity, "EntityArmLeft", 0.105, 2.0, Vector3(-0.5, 1.12, 0), Vector3(0, 0, deg_to_rad(-12.0)), silhouette_material)
	_add_capsule(entity, "EntityArmRight", 0.1, 2.18, Vector3(0.53, 1.05, 0.02), Vector3(0, 0, deg_to_rad(5.0)), silhouette_material)

	var eye_material := _emissive_material(Color(0.95, 0.035, 0.018), 4.2)
	_add_sphere(entity, "EntityEyeLeft", 0.052, 0.085, Vector3(-0.13, 2.31, -0.32), eye_material)
	_add_sphere(entity, "EntityEyeRight", 0.052, 0.085, Vector3(0.13, 2.31, -0.32), eye_material)
	var wound_material := _emissive_material(Color(0.24, 0.006, 0.008), 0.9)
	for index in 3:
		_add_box(
			entity,
			"EntityRib%02d" % index,
			Vector3(0.52 - float(index) * 0.06, 0.025, 0.035),
			Vector3(0, 1.52 - float(index) * 0.2, -0.445),
			wound_material
		)
	_add_box(entity, "EntityMouth", Vector3(0.18, 0.025, 0.035), Vector3(0, 2.08, -0.325), wound_material)

	var rim_light := OmniLight3D.new()
	rim_light.name = "EntityRimLight"
	rim_light.position = Vector3(0, 1.65, -0.05)
	rim_light.light_color = Color(0.72, 0.025, 0.016)
	rim_light.light_energy = 0.58
	rim_light.omni_range = 2.8
	rim_light.shadow_enabled = false
	entity.add_child(rim_light)

static func _silhouette_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.012, 0.005, 0.008)
	material.roughness = 0.52
	material.emission_enabled = true
	material.emission = Color(0.026, 0.002, 0.004)
	material.emission_energy_multiplier = 0.75
	material.rim_enabled = true
	material.rim = 0.62
	material.rim_tint = 0.78
	return material

static func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.darkened(0.55)
	material.roughness = 0.28
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

static func _add_capsule(parent: Node3D, name: String, radius: float, height: float, position: Vector3, rotation: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _add_sphere(parent: Node3D, name: String, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 7
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance

static func _add_box(parent: Node3D, name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

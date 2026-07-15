extends Node3D

var variant := 0
var signs: Array[Label3D] = []
var variant_roots: Array[Node3D] = []
var _cooldown := 0.0

func build(_parent: Node3D) -> void:
	for index in 3:
		var sign := LevelGeometry.add_label(self, "FLOOR 4", Vector3(-3.25, 2.0, WorldLayout.MEMORY_START_Z - 20.0 - index * 60.0), Color(0.45, 0.48, 0.5))
		signs.append(sign)
	for index in 4:
		var root := Node3D.new()
		root.name = "Variant%d" % index
		root.visible = index == 0
		add_child(root)
		variant_roots.append(root)
	_build_variant_props()

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func reconfigure_for_memory(memory_count: int) -> void:
	if memory_count <= variant or _cooldown > 0.0:
		return
	variant = mini(memory_count, 3)
	_cooldown = 1.5
	for index in variant_roots.size():
		variant_roots[index].visible = index == variant
	for index in signs.size():
		var sign := signs[index]
		sign.text = "FLOOR %d" % (4 - variant) if index == variant - 1 else "FLOOR 4"
		sign.modulate = Color(0.7, 0.22, 0.2) if index == variant - 1 else Color(0.45, 0.48, 0.5)

func _build_variant_props() -> void:
	LevelGeometry.add_box(variant_roots[0], "CleanBench", Vector3(2.9, 0.35, -180.0), Vector3(1.4, 0.7, 0.5), Color(0.11, 0.13, 0.15), 0)
	for index in 5:
		var z := -145.0 - index * 34.0
		_add_door_panel(variant_roots[0], "IntactDoor%d" % index, -3.82 if index % 2 == 0 else 3.82, z, Color(0.12, 0.11, 0.13))
		LevelGeometry.add_label(variant_roots[0], "40%d" % (index + 1), Vector3(-3.55 if index % 2 == 0 else 3.55, 1.9, z), Color(0.5, 0.52, 0.55))
	for z in [-155.0, -205.0, -255.0]:
		LevelGeometry.add_box(variant_roots[1], "LowBeam", Vector3(0, 2.65, z), Vector3(7.5, 0.25, 0.4), Color(0.18, 0.14, 0.13), 0)
	LevelGeometry.add_box(variant_roots[1], "MovedBench", Vector3(-2.6, 0.35, -230.0), Vector3(1.8, 0.7, 0.55), Color(0.16, 0.11, 0.1), 0)
	for index in 4:
		LevelGeometry.add_label(variant_roots[1], "40%d" % (6 - index), Vector3(3.5 if index % 2 == 0 else -3.5, 1.85, -155.0 - index * 42.0), Color(0.66, 0.28, 0.25))
	LevelGeometry.add_box(variant_roots[2], "WrongDoor", Vector3(3.7, 1.1, -185.0), Vector3(0.18, 2.2, 1.5), Color(0.26, 0.08, 0.08), 0)
	LevelGeometry.add_box(variant_roots[2], "WrongDoorTwin", Vector3(-3.7, 1.1, -245.0), Vector3(0.18, 2.2, 1.5), Color(0.26, 0.08, 0.08), 0)
	LevelGeometry.add_box(variant_roots[2], "AbandonedCart", Vector3(2.4, 0.55, -215.0), Vector3(1.4, 1.1, 0.75), Color(0.13, 0.16, 0.16), 0)
	LevelGeometry.add_label(variant_roots[2], "407  407  407", Vector3(0, 2.15, -285.0), Color(0.72, 0.08, 0.07))
	for z in [-150.0, -180.0, -210.0, -240.0, -270.0, -300.0]:
		LevelGeometry.add_box(variant_roots[3], "BreathingRib", Vector3(0, 2.35, z), Vector3(7.3, 0.18, 0.18), Color(0.24, 0.035, 0.04), 0)
		LevelGeometry.add_light(variant_roots[3], Vector3(0, 2.5, z), Color(0.48, 0.04, 0.04), 0.32, 3.5)

func _add_door_panel(parent: Node3D, name: String, x: float, z: float, color: Color) -> void:
	LevelGeometry.add_box(parent, name, Vector3(x, 1.25, z), Vector3(0.12, 2.5, 1.55), color, 0)

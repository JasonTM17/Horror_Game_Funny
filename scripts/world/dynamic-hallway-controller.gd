extends Node3D

var variant := 0
var signs: Array[Label3D] = []
var _cooldown := 0.0

func build(parent: Node3D) -> void:
	for index in 3:
		var sign := LevelGeometry.add_label(parent, "FLOOR 4", Vector3(-3.25, 2.0, -43.0 - index * 12.0), Color(0.45, 0.48, 0.5))
		signs.append(sign)

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)

func reconfigure_for_memory(memory_count: int) -> void:
	if memory_count <= variant or _cooldown > 0.0:
		return
	variant = mini(memory_count, 3)
	_cooldown = 1.5
	for index in signs.size():
		var sign := signs[index]
		sign.text = "FLOOR %d" % (4 - variant) if index == variant - 1 else "FLOOR 4"
		sign.modulate = Color(0.7, 0.22, 0.2) if index == variant - 1 else Color(0.45, 0.48, 0.5)


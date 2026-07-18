class_name StoryPropVisualBuilder
extends RefCounted

const MEMORY_PHOTO_TEXTURE := preload("res://assets/images/memory-photo-rabbit.png")
const ROOM_DRAWING_TEXTURE := preload("res://assets/images/room-drawing-rabbit.png")
const FAMILY_TABLE_TEXTURE := preload("res://assets/images/family-table-memory.png")

static func build(parent: Node3D, id: String, color: Color) -> void:
	match id:
		"phone": _build_phone(parent, color)
		"desk_clock": _build_clock(parent, color)
		"logbook", "lobby_register": _build_book(parent, id, color)
		"floor_notice", "memory_photo", "room_drawing", "final_clue": _build_paper_clue(parent, id, color)
		"fuse_pickup": _build_fuse(parent, color)
		"fuse_box": _build_fuse_box(parent, color)
		"memory_cassette", "room_record": _build_cassette(parent, color)
		"memory_rabbit": _build_rabbit(parent, color)
		"memory_echo": _build_memory_echo(parent, color)
		"radio": _build_radio(parent, color)
		"room_bed_observation", "room_wardrobe_observation": _build_search_marker(parent, id, color)
		"room_family_table": _build_family_table_clue(parent, color)
		"exit": _build_exit_panel(parent, color)
		_: _add_box(parent, "StoryProp", Vector3(0.55, 0.65, 0.45), Vector3.ZERO, color)

static func _build_phone(parent: Node3D, color: Color) -> void:
	_add_box(parent, "PhoneBase", Vector3(0.72, 0.22, 0.5), Vector3(0, -0.12, 0), color)
	_add_box(parent, "PhoneHandset", Vector3(0.7, 0.13, 0.17), Vector3(0, 0.13, 0), color.lightened(0.18))
	_add_box(parent, "PhoneReceiverLeft", Vector3(0.17, 0.2, 0.22), Vector3(-0.27, 0.16, 0), color.lightened(0.1))
	_add_box(parent, "PhoneReceiverRight", Vector3(0.17, 0.2, 0.22), Vector3(0.27, 0.16, 0), color.lightened(0.1))
	_add_label(parent, "PhoneIndicator", "RING", Vector3(0, -0.05, 0.27), Color(0.86, 0.18, 0.12), 13)

static func _build_clock(parent: Node3D, color: Color) -> void:
	_add_box(parent, "ClockBody", Vector3(0.72, 0.38, 0.24), Vector3.ZERO, color)
	_add_box(parent, "ClockFace", Vector3(0.58, 0.22, 0.035), Vector3(0, 0, 0.135), Color(0.025, 0.03, 0.035))
	_add_label(parent, "ClockDigits", "00:07", Vector3(0, -0.05, 0.16), Color(0.82, 0.16, 0.12), 18)

static func _build_book(parent: Node3D, id: String, color: Color) -> void:
	_add_box(parent, "BookPages", Vector3(0.75, 0.13, 0.52), Vector3(0, -0.05, 0), Color(0.48, 0.44, 0.36))
	_add_box(parent, "BookCover", Vector3(0.82, 0.05, 0.58), Vector3(0, 0.04, 0), color)
	var title := "NIGHT REGISTER" if id == "lobby_register" else "SHIFT LOG"
	_add_label(parent, "BookTitle", title, Vector3(0, 0.09, 0.04), Color(0.76, 0.72, 0.62), 11)

static func _build_paper_clue(parent: Node3D, id: String, color: Color) -> void:
	var vertical := id == "floor_notice" or id == "room_drawing"
	var size := Vector3(0.86, 0.95, 0.045) if vertical else Vector3(0.75, 0.04, 0.58)
	if id == "final_clue":
		size = Vector3(1.05, 0.04, 0.78)
		_add_box(parent, "FinalClueBacking", Vector3(1.18, 0.025, 0.92), Vector3(0, -0.028, 0), Color(0.38, 0.045, 0.035))
	_add_box(parent, "PaperClue", size, Vector3.ZERO, color.lightened(0.2))
	if id == "memory_photo":
		_add_textured_quad(parent, "MemoryPhotoImage", MEMORY_PHOTO_TEXTURE, Vector2(0.69, 0.46), Vector3(0, 0.027, 0), Vector3(-PI / 2.0, 0, 0))
	elif id == "room_drawing":
		# Right-wall prop: face corridor center (-X) so the single-sided still is visible on the -Z approach.
		_add_textured_quad(parent, "RoomDrawingImage", ROOM_DRAWING_TEXTURE, Vector2(0.79, 0.87), Vector3(-0.027, 0, 0), Vector3(0, -PI / 2.0, 0))
	var text: String = {
		"floor_notice": "FLOOR 4\nCLOSED 2007",
		"memory_photo": "00:07",
		"room_drawing": "ME + RABBIT",
		"final_clue": "RUN TO RED\nDON'T LOOK BACK"
	}.get(id, "CLUE")
	var label_position := Vector3(0, 0, 0.035) if vertical else Vector3(0, 0.055, 0.04)
	var font_size := 13 if id == "final_clue" else 12
	_add_label(parent, "PaperWriting", text, label_position, Color(0.38, 0.055, 0.04), font_size)

static func _build_fuse(parent: Node3D, color: Color) -> void:
	_add_cylinder(parent, "FuseGlass", 0.15, 0.5, Vector3.ZERO, color.lightened(0.18))
	_add_cylinder(parent, "FuseCapTop", 0.19, 0.1, Vector3(0, 0.27, 0), Color(0.36, 0.32, 0.22))
	_add_cylinder(parent, "FuseCapBottom", 0.19, 0.1, Vector3(0, -0.27, 0), Color(0.36, 0.32, 0.22))

static func _build_fuse_box(parent: Node3D, color: Color) -> void:
	_add_box(parent, "FuseBoxCase", Vector3(0.9, 1.05, 0.3), Vector3.ZERO, color)
	_add_box(parent, "FuseBoxDoor", Vector3(0.72, 0.82, 0.04), Vector3(0, 0, 0.17), color.lightened(0.12))
	_add_box(parent, "FuseSlot", Vector3(0.16, 0.5, 0.06), Vector3(0, 0, 0.21), Color(0.035, 0.035, 0.04))

static func _build_cassette(parent: Node3D, color: Color) -> void:
	_add_box(parent, "CassetteBody", Vector3(0.75, 0.48, 0.16), Vector3.ZERO, color.lightened(0.12))
	_add_cylinder(parent, "CassetteReelLeft", 0.12, 0.06, Vector3(-0.19, 0, 0.12), Color(0.52, 0.48, 0.4), Vector3(PI / 2.0, 0, 0))
	_add_cylinder(parent, "CassetteReelRight", 0.12, 0.06, Vector3(0.19, 0, 0.12), Color(0.52, 0.48, 0.4), Vector3(PI / 2.0, 0, 0))

static func _build_rabbit(parent: Node3D, color: Color) -> void:
	_add_sphere(parent, "RabbitBody", Vector3(0.24, 0.32, 0.2), Vector3(0, -0.12, 0), color)
	_add_sphere(parent, "RabbitHead", Vector3(0.2, 0.2, 0.18), Vector3(0, 0.2, 0), color.lightened(0.08))
	_add_capsule(parent, "RabbitEarLeft", 0.07, 0.34, Vector3(-0.11, 0.48, 0), color)
	_add_capsule(parent, "RabbitEarRight", 0.07, 0.34, Vector3(0.11, 0.48, 0), color)
	_add_sphere(parent, "RabbitEye", Vector3(0.035, 0.035, 0.025), Vector3(-0.07, 0.23, 0.17), Color(0.015, 0.01, 0.01))

static func _build_memory_echo(parent: Node3D, color: Color) -> void:
	_add_box(parent, "MemoryEchoSlab", Vector3(1.25, 0.9, 0.05), Vector3.ZERO, color)
	_add_label(parent, "MemoryEchoWriting", "I REMEMBER", Vector3(0, 0, 0.04), Color(0.86, 0.16, 0.13), 16)

static func _build_radio(parent: Node3D, color: Color) -> void:
	_add_box(parent, "RadioBody", Vector3(0.92, 0.58, 0.4), Vector3.ZERO, color.lightened(0.12))
	_add_box(parent, "RadioSpeaker", Vector3(0.44, 0.34, 0.035), Vector3(-0.17, 0, 0.215), Color(0.035, 0.04, 0.045))
	_add_cylinder(parent, "RadioDial", 0.11, 0.06, Vector3(0.29, -0.06, 0.24), Color(0.54, 0.48, 0.36), Vector3(PI / 2.0, 0, 0))
	_add_label(parent, "RadioChannel", "CH 04", Vector3(0.21, 0.16, 0.24), Color(0.62, 0.76, 0.68), 11)

static func _build_search_marker(parent: Node3D, id: String, color: Color) -> void:
	_add_box(parent, "SearchHandle", Vector3(0.18, 0.42, 0.16), Vector3.ZERO, color.lightened(0.22))
	_add_label(parent, "SearchMark", "X" if id == "room_bed_observation" else "407", Vector3(0, 0, 0.1), Color(0.72, 0.16, 0.13), 14)

static func _build_family_table_clue(parent: Node3D, color: Color) -> void:
	_add_box(parent, "FamilyPhoto", Vector3(0.62, 0.06, 0.48), Vector3.ZERO, color.lightened(0.2))
	_add_textured_quad(parent, "FamilyTableImage", FAMILY_TABLE_TEXTURE, Vector2(0.56, 0.42), Vector3(0, 0.034, 0), Vector3(-PI / 2.0, 0, 0))
	for index in 4:
		_add_cylinder(parent, "Plate%d" % index, 0.1, 0.025, Vector3(-0.3 + index * 0.2, 0.06, -0.05), Color(0.5, 0.46, 0.38))

static func _build_exit_panel(parent: Node3D, color: Color) -> void:
	_add_box(parent, "ExitPanel", Vector3(1.2, 0.55, 0.12), Vector3.ZERO, color)
	_add_label(parent, "ExitWriting", "EXIT", Vector3(0, 0, 0.08), Color(0.92, 0.18, 0.12), 20)

static func _add_box(parent: Node3D, name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = LevelGeometry.material(color)
	parent.add_child(instance)

static func _add_cylinder(parent: Node3D, name: String, radius: float, height: float, position: Vector3, color: Color, rotation := Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = LevelGeometry.material(color)
	parent.add_child(instance)

static func _add_sphere(parent: Node3D, name: String, scale: Vector3, position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 6
	instance.mesh = mesh
	instance.scale = scale
	instance.position = position
	instance.material_override = LevelGeometry.material(color)
	parent.add_child(instance)

static func _add_capsule(parent: Node3D, name: String, radius: float, height: float, position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 3
	instance.mesh = mesh
	instance.position = position
	instance.material_override = LevelGeometry.material(color)
	parent.add_child(instance)

static func _add_textured_quad(
	parent: Node3D,
	name: String,
	texture: Texture2D,
	size: Vector2,
	position: Vector3,
	rotation: Vector3
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = name
	var mesh := QuadMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = LevelGeometry.textured_material(texture, Color(0.92, 0.9, 0.84), 0.96)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

static func _add_label(parent: Node3D, name: String, text: String, position: Vector3, color: Color, font_size: int) -> void:
	var label := Label3D.new()
	label.name = name
	label.text = text
	label.position = position
	label.modulate = color
	label.font_size = font_size
	label.outline_size = 4
	label.outline_modulate = Color(0.01, 0.01, 0.015, 0.9)
	label.no_depth_test = true
	parent.add_child(label)

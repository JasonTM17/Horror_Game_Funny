extends Node3D

var _director: Node
var _hallway: Node

func setup(director: Node, hallway: Node) -> void:
	_director = director
	_hallway = hallway

func trigger(event_id: String) -> void:
	if not GameState.mark_event_complete(event_id):
		return
	match event_id:
		"memory_photo":
			_spawn_message("YOU WERE HERE", Vector3(0, 2.2, -51.0), Color(0.72, 0.2, 0.18))
			AudioManager.play_tone("memory_whisper", 210.0, 0.6, -17.0)
		"memory_cassette":
			_spawn_message("DON'T TURN AROUND", Vector3(0, 2.2, -62.0), Color(0.62, 0.58, 0.5))
			AudioManager.play_tone("memory_whisper_two", 95.0, 0.9, -18.0)
		"memory_rabbit":
			_spawn_apparition(Vector3(0, 1.25, -75.0))
			AudioManager.play_tone("memory_whisper_three", 56.0, 1.1, -14.0)
		"fuse_power":
			_spawn_message("THE LIGHTS REMEMBER", Vector3(-2.8, 2.0, -36.0), Color(0.48, 0.64, 0.72))

func _spawn_message(text: String, position: Vector3, color: Color) -> void:
	var label := LevelGeometry.add_label(self, text, position, color)
	label.font_size = 22
	var timer := get_tree().create_timer(6.0)
	timer.timeout.connect(label.queue_free)

func _spawn_apparition(position: Vector3) -> void:
	var apparition := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.3
	mesh.height = 2.1
	apparition.mesh = mesh
	apparition.material_override = LevelGeometry.material(Color(0.008, 0.006, 0.01))
	apparition.position = position
	add_child(apparition)
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(apparition.queue_free)

class_name TurnAwayApparition
extends Node3D

var _player: Node3D
var _camera: Camera3D
var _armed := false
var _revealed := false

func setup(player: Node3D, apparition_position: Vector3) -> void:
	_player = player
	global_position = apparition_position
	_camera = player.get_node_or_null("Head/Camera3D") as Camera3D
	_build_silhouette()
	visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(_camera):
		queue_free()
		return
	var to_apparition := (_camera.global_position - global_position).normalized()
	var camera_forward := -_camera.global_transform.basis.z.normalized()
	var looking_toward := camera_forward.dot(-to_apparition)
	if not _armed and looking_toward < -0.25:
		_armed = true
		visible = true
	elif _armed and not _revealed and looking_toward > 0.35:
		_revealed = true
		AudioManager.play_spatial_tone(self, "turn_away_reveal", 63.0, 0.55, -13.0)
		var timer := get_tree().create_timer(0.55)
		timer.timeout.connect(queue_free)

func _build_silhouette() -> void:
	var mesh_instance := MeshInstance3D.new()
	var silhouette := CapsuleMesh.new()
	silhouette.radius = 0.32
	silhouette.height = 2.2
	mesh_instance.mesh = silhouette
	mesh_instance.material_override = LevelGeometry.material(Color(0.006, 0.004, 0.008))
	add_child(mesh_instance)

class_name TurnAwayApparition
extends Node3D

var _player: Node3D
var _camera: Camera3D
var _armed := false
var _revealed := false
var _duration_scale := 1.0

func setup(player: Node3D, apparition_position: Vector3, duration_scale := 1.0) -> void:
	_player = player
	global_position = apparition_position
	_camera = player.get_node_or_null("Head/Camera3D") as Camera3D
	_duration_scale = clampf(duration_scale, 0.01, 2.0)
	_build_silhouette()
	visible = false
	_expire_after_delay()

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
		AudioManager.play_spatial_tone(self, "scare_cassette_breath_behind", 57.0, 0.72, -21.0)
	elif _armed and not _revealed and looking_toward > 0.35:
		_revealed = true
		AudioManager.play_spatial_tone(self, "scare_cassette_reveal_low", 43.0, 0.48, -16.0)
		AudioManager.play_spatial_tone(self, "scare_cassette_reveal_snap", 127.0, 0.22, -20.0)
		var timer := get_tree().create_timer(_scaled_duration(0.55), false)
		timer.timeout.connect(queue_free)

func _exit_tree() -> void:
	for cue_id in [
		"scare_cassette_breath_behind",
		"scare_cassette_reveal_low",
		"scare_cassette_reveal_snap",
	]:
		AudioManager.stop_tone(cue_id)

func _expire_after_delay() -> void:
	await get_tree().create_timer(_scaled_duration(18.0), false).timeout
	if is_inside_tree() and not _revealed:
		queue_free()

func _scaled_duration(seconds: float) -> float:
	return maxf(0.001, seconds * _duration_scale)

func _build_silhouette() -> void:
	var mesh_instance := MeshInstance3D.new()
	var silhouette := CapsuleMesh.new()
	silhouette.radius = 0.32
	silhouette.height = 2.2
	mesh_instance.mesh = silhouette
	mesh_instance.material_override = LevelGeometry.material(Color(0.006, 0.004, 0.008))
	add_child(mesh_instance)

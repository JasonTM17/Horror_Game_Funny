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
		# Behind-player breath while still facing away — anticipation, not snap.
		AudioManager.play_spatial_tone(self, "scare_cassette_breath_behind", 57.0, 0.72, -21.0)
		_pulse_fear(0.22, 0.45)
	elif _armed and not _revealed and looking_toward > 0.35:
		_revealed = true
		HorrorApparitionFactory.face_toward(self, _camera.global_position)
		AudioManager.play_spatial_tone(self, "scare_cassette_reveal_low", 43.0, 0.48, -16.0)
		AudioManager.play_spatial_tone(self, "scare_cassette_reveal_snap", 127.0, 0.22, -20.0)
		if is_instance_valid(_player) and _player.has_method("add_camera_shake"):
			_player.call("add_camera_shake", 0.07, 0.4)
		_pulse_fear(0.72, 0.8)
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

func _pulse_fear(intensity: float, hold_seconds: float) -> void:
	var layer := get_tree().get_first_node_in_group("visual_effects")
	if layer != null and layer.has_method("pulse_fear"):
		layer.call("pulse_fear", intensity, _scaled_duration(hold_seconds))

func _build_silhouette() -> void:
	# Match factory silhouette language (shoulders + arms) without eyes so the
	# look-back reveal stays a dark figure until the snap cues fire.
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.3
	body_mesh.height = 2.15
	body.mesh = body_mesh
	body.material_override = _silhouette_material(Color(0.008, 0.005, 0.01))
	add_child(body)
	var shoulders := MeshInstance3D.new()
	shoulders.name = "Shoulders"
	var shoulder_mesh := BoxMesh.new()
	shoulder_mesh.size = Vector3(0.78, 0.16, 0.26)
	shoulders.mesh = shoulder_mesh
	shoulders.position = Vector3(0.0, 0.98, 0.0)
	shoulders.material_override = _silhouette_material(Color(0.007, 0.004, 0.009))
	add_child(shoulders)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.3
	head_mesh.height = 0.6
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.1, 0.0)
	head.scale = Vector3(0.9, 1.15, 0.95)
	head.material_override = _silhouette_material(Color(0.006, 0.004, 0.008))
	add_child(head)
	_add_arm("ArmLeft", Vector3(-0.4, 0.72, -0.04), 0.34)
	_add_arm("ArmRight", Vector3(0.4, 0.72, -0.04), -0.34)

func _add_arm(arm_name: String, arm_position: Vector3, lean: float) -> void:
	var arm := MeshInstance3D.new()
	arm.name = arm_name
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.07
	arm_mesh.height = 1.05
	arm.mesh = arm_mesh
	arm.position = arm_position
	arm.rotation.z = lean
	arm.material_override = _silhouette_material(Color(0.007, 0.004, 0.009))
	add_child(arm)

func _silhouette_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	return material

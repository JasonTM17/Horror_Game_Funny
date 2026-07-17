class_name HorrorScareSequence
extends Node3D

signal finished

var duration_scale := 1.0
var _audio_ids: Array[String] = []
var _light_snapshots: Dictionary = {}
var _owned_nodes: Array[Node] = []
var _cleaned_up := false

func setup(scale: float) -> void:
	duration_scale = clampf(scale, 0.01, 2.0)

func wait(seconds: float) -> bool:
	await get_tree().create_timer(_scaled_duration(seconds), false).timeout
	return is_inside_tree() and not _cleaned_up

func play_spatial_at(
	position: Vector3,
	cue_id: String,
	frequency: float,
	duration: float,
	volume_db: float
) -> Node3D:
	var anchor := Node3D.new()
	anchor.name = _node_name_from_cue(cue_id)
	anchor.position = position
	add_child(anchor)
	play_spatial_on(anchor, cue_id, frequency, duration, volume_db)
	return anchor

func play_spatial_on(
	parent: Node3D,
	cue_id: String,
	frequency: float,
	duration: float,
	volume_db: float
) -> void:
	if _cleaned_up or not is_instance_valid(parent) or cue_id.is_empty():
		return
	if not _audio_ids.has(cue_id):
		_audio_ids.append(cue_id)
	AudioManager.play_spatial_tone(parent, cue_id, frequency, duration, volume_db)

func own_node(node: Node) -> void:
	if _cleaned_up or not is_instance_valid(node) or _owned_nodes.has(node):
		return
	_owned_nodes.append(node)

func set_light(light: OmniLight3D, energy_factor: float, color: Color) -> void:
	if _cleaned_up or not is_instance_valid(light):
		return
	var instance_id := light.get_instance_id()
	if not _light_snapshots.has(instance_id):
		_light_snapshots[instance_id] = {
			"light": light,
			"energy": light.light_energy,
			"color": light.light_color,
		}
	light.light_energy = maxf(0.0, float(_light_snapshots[instance_id]["energy"]) * energy_factor)
	light.light_color = color

func restore_lights() -> void:
	for snapshot_value in _light_snapshots.values():
		var snapshot := snapshot_value as Dictionary
		var light := snapshot.get("light") as OmniLight3D
		if not is_instance_valid(light):
			continue
		light.light_energy = float(snapshot.get("energy", light.light_energy))
		light.light_color = snapshot.get("color", light.light_color) as Color
	_light_snapshots.clear()

func finish() -> void:
	if _cleaned_up:
		return
	_cleanup()
	finished.emit()
	queue_free()

func cancel() -> void:
	if _cleaned_up:
		return
	_cleanup()
	queue_free()

func _exit_tree() -> void:
	_cleanup()

func _cleanup() -> void:
	if _cleaned_up:
		return
	_cleaned_up = true
	for cue_id in _audio_ids:
		AudioManager.stop_tone(cue_id)
	_audio_ids.clear()
	for owned_node in _owned_nodes:
		if is_instance_valid(owned_node):
			owned_node.queue_free()
	_owned_nodes.clear()
	restore_lights()

func _scaled_duration(seconds: float) -> float:
	return maxf(0.001, seconds * duration_scale)

func _node_name_from_cue(cue_id: String) -> String:
	var node_name := cue_id.to_pascal_case()
	return node_name if not node_name.is_empty() else "ScareAudioAnchor"

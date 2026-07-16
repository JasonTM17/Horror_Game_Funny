extends Node

signal beat_finished(flag: String)
@export_range(0.05, 2.0, 0.05) var duration_scale := 1.0
var _running := false
var _queue: Array[Dictionary] = []

func play(lines: Array, completion_flag: String, seconds_per_line := 4.5) -> bool:
	if GameState.has_flag(completion_flag) or lines.is_empty():
		return false
	for queued in _queue:
		if str(queued.get("flag", "")) == completion_flag:
			return false
	var sequence := {
		"lines": lines.duplicate(),
		"flag": completion_flag,
		"seconds_per_line": seconds_per_line
	}
	if _running:
		_queue.append(sequence)
	else:
		_run_sequence(sequence)
	return true

func _run_sequence(sequence: Dictionary) -> void:
	_running = true
	for line in sequence.get("lines", []):
		GameState.set_subtitle(str(line))
		AudioManager.play_tone("dialogue_tick", 165.0, 0.08, -29.0)
		await get_tree().create_timer(float(sequence.get("seconds_per_line", 4.5)) * duration_scale, false).timeout
	GameState.set_subtitle("")
	var completion_flag := str(sequence.get("flag", ""))
	GameState.set_flag(completion_flag)
	_running = false
	beat_finished.emit(completion_flag)
	if not _queue.is_empty():
		_run_sequence(_queue.pop_front())

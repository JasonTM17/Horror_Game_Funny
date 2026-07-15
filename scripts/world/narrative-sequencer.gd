extends Node

signal beat_finished(flag: String)
@export_range(0.05, 2.0, 0.05) var duration_scale := 1.0
var _running := false

func play(lines: Array, completion_flag: String, seconds_per_line := 4.5) -> bool:
	if _running or GameState.has_flag(completion_flag) or lines.is_empty():
		return false
	_running = true
	for line in lines:
		GameState.set_subtitle(str(line))
		AudioManager.play_tone("dialogue_tick", 165.0, 0.08, -29.0)
		await get_tree().create_timer(seconds_per_line * duration_scale).timeout
	GameState.set_subtitle("")
	GameState.set_flag(completion_flag)
	_running = false
	beat_finished.emit(completion_flag)
	return true

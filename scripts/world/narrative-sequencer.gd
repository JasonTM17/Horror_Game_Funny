extends Node

const VOICE_OVER_PLAYER_SCRIPT := preload("res://scripts/audio/voice-over-player.gd")

signal beat_finished(flag: String)
@export_range(0.05, 2.0, 0.05) var duration_scale := 1.0
@export var voice_over_enabled := true
var _running := false
var _active_flag := ""
var _owned_subtitle := ""
var _queue: Array[Dictionary] = []
var _voice_player: VoiceOverPlayer
var _voice_contract_failures := PackedStringArray()
var _validated_voice_cues: Dictionary = {}

func _ready() -> void:
	_voice_player = VOICE_OVER_PLAYER_SCRIPT.new() as VoiceOverPlayer
	_voice_player.name = "VoiceOverPlayer"
	add_child(_voice_player)
	GameState.subtitle_changed.connect(_on_subtitle_changed)

func play(lines: Array, completion_flag: String, seconds_per_line := 4.5) -> bool:
	if GameState.has_flag(completion_flag) or completion_flag == _active_flag or lines.is_empty():
		return false
	for queued in _queue:
		if str(queued.get("flag", "")) == completion_flag:
			return false
	_validate_voice_contract(lines, completion_flag)
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

func voice_contract_failures() -> PackedStringArray:
	return _voice_contract_failures.duplicate()

func validated_voice_cue_count() -> int:
	return _validated_voice_cues.size()

func _validate_voice_contract(lines: Array, completion_flag: String) -> void:
	for line_index in range(lines.size()):
		var subtitle := str(lines[line_index])
		var cue_id := VoiceOverPlayer.make_cue_id(completion_flag, line_index)
		if _voice_player.has_cue(completion_flag, line_index, subtitle):
			_validated_voice_cues[cue_id] = true
			continue
		var failure := "%s does not exactly match the voice manifest" % cue_id
		if not _voice_contract_failures.has(failure):
			_voice_contract_failures.append(failure)

func _run_sequence(sequence: Dictionary) -> void:
	_running = true
	var lines: Array = sequence.get("lines", [])
	var completion_flag := str(sequence.get("flag", ""))
	_active_flag = completion_flag
	var base_seconds := float(sequence.get("seconds_per_line", 4.5))
	for line_index in range(lines.size()):
		var subtitle := str(lines[line_index])
		_owned_subtitle = subtitle
		GameState.set_subtitle(subtitle)
		var voice_duration := 0.0
		if voice_over_enabled:
			voice_duration = _voice_player.play_cue(completion_flag, line_index, subtitle)
		else:
			_voice_player.stop_cue()
		if voice_duration <= 0.0:
			AudioManager.play_tone("dialogue_tick", 165.0, 0.08, -29.0)
		var wait_seconds := VoiceOverPlayer.line_wait_seconds(base_seconds, duration_scale, voice_duration)
		await get_tree().create_timer(wait_seconds, false).timeout
	_voice_player.stop_cue()
	_owned_subtitle = ""
	GameState.set_subtitle("")
	GameState.set_flag(completion_flag)
	_active_flag = ""
	beat_finished.emit(completion_flag)
	if not _queue.is_empty():
		_run_sequence(_queue.pop_front())
	else:
		_running = false

func _on_subtitle_changed(subtitle: String) -> void:
	if _running and subtitle != _owned_subtitle and is_instance_valid(_voice_player):
		_voice_player.stop_cue()

func _exit_tree() -> void:
	if is_instance_valid(_voice_player):
		_voice_player.stop_cue()
	_queue.clear()
	_running = false
	_active_flag = ""
	_owned_subtitle = ""
	GameState.set_subtitle("")

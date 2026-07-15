class_name PlaythroughPacingTelemetry
extends Node

const LOG_PREFIX := "PLAYTHROUGH_PACING: "
const BOUNDARY_ORDER: Array[String] = [
	"lobby",
	"floor4_dark",
	"floor4_powered",
	"memory_loop",
	"room_407",
	"chase",
	"ending",
	"credits",
]
const CHAPTER_BOUNDARIES := {
	"opening": ["lobby", "floor4_dark"],
	"floor4": ["floor4_dark", "memory_loop"],
	"memory_loop": ["memory_loop", "room_407"],
	"room407": ["room_407", "chase"],
	"chase_ending": ["chase", "credits"],
}
const TARGET_SECONDS := {
	"opening": [120.0, 180.0],
	"floor4": [180.0, 240.0],
	"memory_loop": [240.0, 300.0],
	"room407": [180.0, 240.0],
	"chase_ending": [120.0, 180.0],
	"total": [900.0, 1200.0],
}

var _started := false
var _eligible_full_run := false
var _initial_stage := GameState.Stage.LOBBY
var _active_seconds := 0.0
var _wall_started_usec := 0
var _pause_started_usec := -1
var _paused_usec := 0
var _report_emitted := false
var _boundary_order: Array[String] = []
var _stage_active_seconds: Dictionary = {}
var _stage_wall_seconds: Dictionary = {}

func begin(fresh_run: bool, initial_stage: int) -> void:
	if _started:
		return
	_started = true
	_initial_stage = initial_stage
	_eligible_full_run = fresh_run and initial_stage == GameState.Stage.LOBBY
	_wall_started_usec = Time.get_ticks_usec()
	if get_tree() != null and get_tree().paused:
		_pause_started_usec = _wall_started_usec
	_record_stage(initial_stage)
	if not GameState.stage_changed.is_connected(_on_stage_changed):
		GameState.stage_changed.connect(_on_stage_changed)

func _process(delta: float) -> void:
	if not _started or _report_emitted:
		return
	# Headless and heavily loaded frames can report a delta slightly larger than
	# elapsed monotonic time. Clamp against unpaused wall time so simulation drift
	# cannot absorb a recorded pause interval.
	var unpaused_wall_seconds := maxf(0.0, _elapsed_wall_seconds() - _elapsed_paused_seconds())
	_active_seconds = minf(_active_seconds + maxf(0.0, delta), unpaused_wall_seconds)

func _notification(what: int) -> void:
	if not _started or _report_emitted:
		return
	if what == NOTIFICATION_PAUSED and _pause_started_usec < 0:
		_pause_started_usec = Time.get_ticks_usec()
	elif what == NOTIFICATION_UNPAUSED:
		_close_pause_interval()

func _exit_tree() -> void:
	_disconnect_stage_signal()

func record_credits() -> void:
	if not _started or _report_emitted:
		return
	_close_pause_interval()
	_record_boundary("credits")
	_report_emitted = true
	_disconnect_stage_signal()
	print(LOG_PREFIX + JSON.stringify(get_report()))

func get_report() -> Dictionary:
	var missing_milestones: Array[String] = []
	for milestone: String in BOUNDARY_ORDER:
		if not _stage_active_seconds.has(milestone):
			missing_milestones.append(milestone)
	var actual_order: Array[String] = _boundary_order.duplicate()
	var boundary_order_valid := _has_valid_boundary_order(actual_order)
	var chapter_seconds: Dictionary = {}
	var chapter_within_target: Dictionary = {}
	for chapter: String in CHAPTER_BOUNDARIES:
		var boundaries: Array = CHAPTER_BOUNDARIES[chapter] as Array
		var duration: Variant = _duration_between(str(boundaries[0]), str(boundaries[1]))
		chapter_seconds[chapter] = duration
		chapter_within_target[chapter] = _within_target(duration, TARGET_SECONDS[chapter] as Array)
	var complete := missing_milestones.is_empty() and boundary_order_valid
	var active_total: float = _elapsed_active_seconds()
	var within_target: Variant = null
	if complete and _eligible_full_run:
		within_target = _is_between(active_total, TARGET_SECONDS["total"] as Array)
	return {
		"eligible_full_run": _eligible_full_run,
		"complete": complete,
		"within_target": within_target,
		"initial_stage": _stage_key(_initial_stage),
		"active_gameplay_seconds": _round_seconds(active_total),
		"wall_clock_seconds": _round_seconds(_elapsed_wall_seconds()),
		"paused_seconds": _round_seconds(_elapsed_paused_seconds()),
		"boundary_order": actual_order,
		"boundary_order_valid": boundary_order_valid,
		"missing_milestones": missing_milestones,
		"stage_active_seconds": _stage_active_seconds.duplicate(true),
		"stage_wall_seconds": _stage_wall_seconds.duplicate(true),
		"chapter_active_seconds": chapter_seconds,
		"chapter_within_target": chapter_within_target,
		"target_seconds": TARGET_SECONDS.duplicate(true),
	}

func _on_stage_changed(stage: int) -> void:
	_record_stage(stage)

func _disconnect_stage_signal() -> void:
	if GameState.stage_changed.is_connected(_on_stage_changed):
		GameState.stage_changed.disconnect(_on_stage_changed)

func _record_stage(stage: int) -> void:
	var key := _stage_key(stage)
	if key.is_empty():
		return
	_record_boundary(key)

func _record_boundary(key: String) -> void:
	if _stage_active_seconds.has(key):
		return
	_boundary_order.append(key)
	_stage_active_seconds[key] = _round_seconds(_active_seconds)
	_stage_wall_seconds[key] = _round_seconds(_elapsed_wall_seconds())

func _duration_between(start_key: String, end_key: String) -> Variant:
	if not _stage_active_seconds.has(start_key) or not _stage_active_seconds.has(end_key):
		return null
	var start_seconds := float(_stage_active_seconds[start_key])
	var end_seconds := float(_stage_active_seconds[end_key])
	if end_seconds < start_seconds:
		return null
	return _round_seconds(end_seconds - start_seconds)

func _has_valid_boundary_order(actual_order: Array[String]) -> bool:
	var previous_index := -1
	for boundary: String in actual_order:
		var boundary_index := BOUNDARY_ORDER.find(boundary)
		if boundary_index <= previous_index:
			return false
		previous_index = boundary_index
	return true

func _within_target(duration: Variant, target: Array) -> Variant:
	if not _eligible_full_run or duration == null:
		return null
	return _is_between(float(duration), target)

func _is_between(seconds: float, target: Array) -> bool:
	return seconds >= float(target[0]) and seconds <= float(target[1])

func _elapsed_active_seconds() -> float:
	if _stage_active_seconds.has("credits"):
		return float(_stage_active_seconds["credits"])
	return _active_seconds

func _elapsed_wall_seconds() -> float:
	if _stage_wall_seconds.has("credits"):
		return float(_stage_wall_seconds["credits"])
	if not _started:
		return 0.0
	var elapsed_usec: int = Time.get_ticks_usec() - _wall_started_usec
	return float(maxi(0, elapsed_usec)) / 1000000.0

func _elapsed_paused_seconds() -> float:
	var elapsed_usec := _paused_usec
	if _pause_started_usec >= 0:
		elapsed_usec += maxi(0, Time.get_ticks_usec() - _pause_started_usec)
	return float(maxi(0, elapsed_usec)) / 1000000.0

func _close_pause_interval() -> void:
	if _pause_started_usec < 0:
		return
	_paused_usec += maxi(0, Time.get_ticks_usec() - _pause_started_usec)
	_pause_started_usec = -1

func _round_seconds(value: float) -> float:
	return snappedf(maxf(0.0, value), 0.01)

func _stage_key(stage: int) -> String:
	match stage:
		GameState.Stage.LOBBY:
			return "lobby"
		GameState.Stage.FLOOR4_DARK:
			return "floor4_dark"
		GameState.Stage.FLOOR4_POWERED:
			return "floor4_powered"
		GameState.Stage.MEMORY_LOOP:
			return "memory_loop"
		GameState.Stage.ROOM_407:
			return "room_407"
		GameState.Stage.CHASE:
			return "chase"
		GameState.Stage.ENDING:
			return "ending"
	return ""

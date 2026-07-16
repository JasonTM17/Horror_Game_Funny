extends Node

## Serializable story state shared by authored scenes.
signal stage_changed(stage: int)
signal objective_changed(text: String)
signal inventory_changed(items: Array[String])
signal flag_changed(id: String, value: bool)
signal subtitle_changed(text: String)

enum Stage { LOBBY, FLOOR4_DARK, FLOOR4_POWERED, MEMORY_LOOP, ROOM_407, CHASE, ENDING }

var stage: int = Stage.LOBBY
var objective: String = "Find the night desk and sign in."
var subtitle: String = ""
var inventory: Array[String] = []
var flags: Dictionary = {}
var completed_events: Dictionary = {}
var checkpoint: Dictionary = {}
var pending_spawn_id: String = "start"

func reset_run() -> void:
	stage = Stage.LOBBY
	objective = "Find the night desk and sign in."
	subtitle = ""
	inventory.clear()
	flags.clear()
	completed_events.clear()
	checkpoint.clear()
	pending_spawn_id = "start"
	stage_changed.emit(stage)
	objective_changed.emit(objective)
	inventory_changed.emit(inventory.duplicate())
	subtitle_changed.emit(subtitle)

func advance_stage(next_stage: int) -> void:
	if next_stage < stage:
		return
	if next_stage == stage:
		return
	stage = next_stage
	stage_changed.emit(stage)

func set_objective(text: String) -> void:
	if objective == text:
		return
	objective = text
	objective_changed.emit(objective)

func set_subtitle(text: String) -> void:
	if subtitle == text:
		return
	subtitle = text
	subtitle_changed.emit(subtitle)

func add_item(item_id: String) -> bool:
	if item_id.is_empty() or inventory.has(item_id):
		return false
	inventory.append(item_id)
	inventory_changed.emit(inventory.duplicate())
	return true

func consume_item(item_id: String) -> bool:
	var index := inventory.find(item_id)
	if index < 0:
		return false
	inventory.remove_at(index)
	inventory_changed.emit(inventory.duplicate())
	return true

func consume_item_and_set_flag(item_id: String, flag_id: String) -> bool:
	if item_id.is_empty() or flag_id.is_empty():
		return false
	if has_flag(flag_id):
		return true
	var index := inventory.find(item_id)
	if index < 0:
		return false
	# Commit both values before either synchronous signal can observe the state.
	inventory.remove_at(index)
	flags[flag_id] = true
	inventory_changed.emit(inventory.duplicate())
	flag_changed.emit(flag_id, true)
	return true

func has_item(item_id: String) -> bool:
	return inventory.has(item_id)

func set_flag(id: String, value: bool = true) -> bool:
	if id.is_empty() or bool(flags.get(id, false)) == value:
		return false
	flags[id] = value
	flag_changed.emit(id, value)
	return true

func has_flag(id: String) -> bool:
	return bool(flags.get(id, false))

func mark_event_complete(event_id: String) -> bool:
	if event_id.is_empty() or bool(completed_events.get(event_id, false)):
		return false
	completed_events[event_id] = true
	return true

func create_checkpoint(scene_path: String, spawn_id: String) -> Dictionary:
	checkpoint = {
		"scene_path": scene_path,
		"spawn_id": spawn_id,
		"stage": stage,
		"objective": objective,
		"inventory": inventory.duplicate(),
		"flags": flags.duplicate(),
		"completed_events": completed_events.duplicate()
	}
	return checkpoint.duplicate(true)

func restore_checkpoint() -> bool:
	if checkpoint.is_empty():
		return false
	stage = int(checkpoint.get("stage", Stage.LOBBY))
	objective = str(checkpoint.get("objective", ""))
	inventory = Array(checkpoint.get("inventory", []))
	flags = Dictionary(checkpoint.get("flags", {}))
	completed_events = Dictionary(checkpoint.get("completed_events", {}))
	pending_spawn_id = str(checkpoint.get("spawn_id", "start"))
	stage_changed.emit(stage)
	objective_changed.emit(objective)
	inventory_changed.emit(inventory.duplicate())
	return true

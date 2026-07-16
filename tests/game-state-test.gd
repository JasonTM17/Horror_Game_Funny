extends SceneTree

const STATE_SCRIPT := preload("res://scripts/autoload/game-state.gd")

func _init() -> void:
	var state: Node = STATE_SCRIPT.new()
	root.add_child(state)
	state.reset_run()
	assert(state.add_item("key"), "first item add should succeed")
	assert(not state.add_item("key"), "duplicate item add should be idempotent")
	assert(state.has_item("key"), "item should be present")
	assert(state.set_flag("phone_answered"), "first flag set should succeed")
	assert(not state.set_flag("phone_answered"), "duplicate flag set should be idempotent")
	assert(state.add_item("door_key"), "door transaction fixture should add its key")
	var transaction_observations: Array[bool] = []
	state.inventory_changed.connect(func(_items: Array[String]) -> void:
		transaction_observations.append(state.has_flag("door_unlocked") and not state.has_item("door_key"))
	)
	state.flag_changed.connect(func(id: String, value: bool) -> void:
		if id == "door_unlocked" and value:
			transaction_observations.append(state.has_flag("door_unlocked") and not state.has_item("door_key"))
	)
	assert(state.consume_item_and_set_flag("door_key", "door_unlocked"), "door transaction should succeed")
	assert(transaction_observations == [true, true], "door transaction signals observed partial state")
	assert(state.consume_item_and_set_flag("door_key", "door_unlocked"), "door transaction should be idempotent")
	state.set_objective("Checkpoint objective")
	state.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "safe")
	state.add_item("extra")
	assert(state.restore_checkpoint(), "checkpoint should restore")
	assert(state.has_item("key") and not state.has_item("extra"), "checkpoint inventory mismatch")
	var restored_checkpoint := JSON.stringify(state.checkpoint)
	assert(state.add_item("post_restore_item"), "post-restore item fixture should mutate live state")
	assert(state.set_flag("post_restore_flag"), "post-restore flag fixture should mutate live state")
	assert(state.mark_event_complete("post_restore_event"), "post-restore event fixture should mutate live state")
	assert(JSON.stringify(state.checkpoint) == restored_checkpoint, "live state aliases and mutates restored checkpoint collections")
	assert(state.mark_event_complete("floor_arrival"), "first horror event should complete")
	assert(not state.mark_event_complete("floor_arrival"), "horror event guard should reject duplicates")
	state.reset_run()
	assert(state.mark_event_complete("floor_arrival"), "new run should reset the horror event guard")
	print("GAME_STATE_TEST_OK")
	quit(0)

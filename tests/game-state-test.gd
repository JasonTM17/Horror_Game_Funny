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
	state.set_objective("Checkpoint objective")
	state.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "safe")
	state.add_item("extra")
	assert(state.restore_checkpoint(), "checkpoint should restore")
	assert(state.has_item("key") and not state.has_item("extra"), "checkpoint inventory mismatch")
	print("GAME_STATE_TEST_OK")
	quit(0)

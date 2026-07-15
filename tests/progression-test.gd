extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

func _ready() -> void:
	var gameplay: Node3D = GAMEPLAY_SCENE.instantiate() as Node3D
	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: Node = gameplay.get_node("Player")
	var director: Node = gameplay
	GameState.reset_run()
	if not _require(not director.handle_story_action("logbook", player), "logbook must stay gated"): return
	if not _require(director.handle_story_action("phone", player), "phone should answer"): return
	if not _require(director.handle_story_action("logbook", player), "logbook should grant key"): return
	if not _require(not director.handle_story_action("radio", player), "radio must wait for memories"): return
	if not _require(director.handle_story_action("fuse_pickup", player), "fuse pickup should work"): return
	if not _require(director.handle_story_action("fuse_box", player), "fuse should install"): return
	for memory_id in ["memory_photo", "memory_cassette", "memory_rabbit"]:
		if not _require(director.handle_story_action(memory_id, player), "%s should collect" % memory_id): return
	if not _require(not director.handle_story_action("memory_photo", player), "duplicate memory must be rejected"): return
	if not _require(director.handle_story_action("radio", player), "radio UI should open"): return
	director.on_radio_solved()
	if not _require(GameState.has_flag("radio_solved"), "radio flag missing"): return
	GameState.set_flag("room_entered")
	if not _require(director.handle_story_action("final_clue", player), "final clue should open note"): return
	director.on_note_closed()
	if not _require(GameState.has_flag("final_clue_seen"), "final clue flag missing"): return
	director._start_chase()
	if not _require(GameState.stage == GameState.Stage.CHASE, "chase stage missing"): return
	director.fail_chase()
	if not _require(is_equal_approx(player.global_position.z, -108.0), "fail recovery marker mismatch"): return
	var entity_count := 0
	for child in gameplay.get_children():
		if child.name.begins_with("TheEntity"):
			entity_count += 1
	if not _require(entity_count == 1, "fail recovery duplicated the entity"): return
	GameState.reset_run()
	if not _require(not director.handle_story_action("exit", player), "ending must reject a fresh run"): return
	print("PROGRESSION_TEST_OK")
	gameplay.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("PROGRESSION_ASSERT: " + message)
	get_tree().quit(2)
	return false

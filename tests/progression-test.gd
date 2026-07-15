extends Node

const GAMEPLAY_SCENE := preload("res://scenes/gameplay/gameplay.tscn")

func _ready() -> void:
	var gameplay: Node3D = GAMEPLAY_SCENE.instantiate() as Node3D
	add_child(gameplay)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: Node = gameplay.get_node("Player")
	var director: Node = gameplay
	director._narrative.duration_scale = 0.001
	GameState.reset_run()
	if not _require(not director.handle_story_action("exit", player), "ending must reject a fresh run"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook must stay gated"): return
	if not _require(director.handle_story_action("phone", player), "phone should answer"): return
	if not _require(await _wait_for_flag("phone_briefing_complete"), "phone briefing should complete"): return
	if not _require(director.handle_story_action("logbook", player), "logbook should grant key"): return
	if not _require(not director.handle_story_action("radio", player), "radio must wait for memories"): return
	if not _require(director.handle_story_action("fuse_pickup", player), "fuse pickup should work"): return
	if not _require(director.handle_story_action("fuse_box", player), "fuse should install"): return
	if not _require(await _wait_for_flag("power_stable"), "power sequence should stabilize"): return
	if not _require(director.handle_story_action("memory_photo", player), "photo should collect"): return
	if not _require(await _wait_for_flag("memory_photo_recalled"), "photo memory should finish"): return
	if not _require(director.handle_story_action("hallway_loop", player), "first hallway loop should turn"): return
	if not _require(await _wait_for_transition(director), "first hallway transition should finish"): return
	if not _require(director.handle_story_action("memory_cassette", player), "cassette should collect"): return
	if not _require(await _wait_for_flag("memory_cassette_recalled"), "cassette memory should finish"): return
	if not _require(director.handle_story_action("hallway_loop", player), "second hallway loop should turn"): return
	if not _require(await _wait_for_transition(director), "second hallway transition should finish"): return
	if not _require(director.handle_story_action("memory_rabbit", player), "rabbit should collect"): return
	if not _require(await _wait_for_flag("memory_loop_complete"), "final memory transition should finish"): return
	if not _require(not director.handle_story_action("memory_photo", player), "duplicate memory must be rejected"): return
	if not _require(director.handle_story_action("radio", player), "radio UI should open"): return
	var radio_ui: Variant = director._story._radio_ui
	radio_ui.entry.text = "1111"
	radio_ui._submit()
	if not _require(radio_ui.submit_button.disabled, "wrong radio code must start cooldown"): return
	if not _require(await _wait_for_radio(radio_ui), "radio cooldown should end"): return
	radio_ui.entry.text = "0007"
	radio_ui._submit()
	if not _require(await _wait_for_flag("radio_solved"), "radio flag missing"): return
	GameState.set_flag("room_entered")
	if not _require(director.handle_story_action("room_record", player), "room recording should play"): return
	if not _require(await _wait_for_flag("room_record_heard"), "room recording should complete"): return
	if not _require(director.handle_story_action("room_drawing", player), "room drawing should unlock"): return
	if not _require(director.handle_story_action("final_clue", player), "final clue should open note"): return
	director.on_note_closed()
	if not _require(GameState.has_flag("final_clue_seen"), "final clue flag missing"): return
	if not _require(await _wait_for_flag("chase_ready"), "chase build-up should complete"): return
	director._start_chase()
	if not _require(GameState.stage == GameState.Stage.CHASE, "chase stage missing"): return
	director.fail_chase()
	await get_tree().create_timer(1.4).timeout
	if not _require(not director._chase.recovering, "fail recovery should finish"): return
	if not _require(is_equal_approx(player.global_position.z, WorldLayout.CHASE_RESPAWN_Z), "fail recovery marker mismatch"): return
	var entity_count := 0
	for child in gameplay.get_children():
		if child.name.begins_with("TheEntity"):
			entity_count += 1
	if not _require(entity_count == 1, "fail recovery duplicated the entity"): return
	if not _require(director.handle_story_action("exit", player), "ending should accept the completed chase path"): return
	if not _require(GameState.stage == GameState.Stage.ENDING, "ending stage missing"): return
	if not _require(gameplay.has_node("AbandonedLobbyFloor"), "abandoned lobby reveal missing"): return
	AudioManager.stop_all()
	print("PROGRESSION_TEST_OK")
	gameplay.queue_free()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("PROGRESSION_ASSERT: " + message)
	get_tree().quit(2)
	return false

func _wait_for_flag(flag: String, max_frames := 180) -> bool:
	for _frame in max_frames:
		if GameState.has_flag(flag):
			return true
		await get_tree().process_frame
	return false

func _wait_for_transition(director: Node, max_frames := 180) -> bool:
	for _frame in max_frames:
		if not director._story.loop_transitioning:
			return true
		await get_tree().process_frame
	return false

func _wait_for_radio(radio_ui: Variant, max_frames := 120) -> bool:
	for _frame in max_frames:
		if radio_ui._accepting_input:
			return true
		await get_tree().process_frame
	return false

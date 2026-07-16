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
	var pacing_before_pause: Dictionary = director.get_playthrough_pacing_report()
	get_tree().paused = true
	await get_tree().process_frame
	OS.delay_msec(60)
	await get_tree().process_frame
	get_tree().paused = false
	var pacing_after_pause: Dictionary = director.get_playthrough_pacing_report()
	if not _require(is_equal_approx(float(pacing_after_pause["active_gameplay_seconds"]), float(pacing_before_pause["active_gameplay_seconds"])), "paused time leaked into active gameplay pacing"): return
	if not _require(float(pacing_after_pause["wall_clock_seconds"]) > float(pacing_before_pause["wall_clock_seconds"]), "wall pacing did not include paused time"): return
	if not _require(not director.handle_story_action("exit", player), "ending must reject a fresh run"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook must stay gated"): return
	if not _require(not director.handle_story_action("lobby_register", player), "night register must stay gated before the phone briefing"): return
	if not _require(director.handle_story_action("phone", player), "phone should answer"): return
	if not _require(await _wait_for_flag("phone_briefing_complete"), "phone briefing should complete"): return
	if not _require(GameState.objective == "Read the stopped desk clock and night register, then sign the night log.", "phone objective skipped locked lobby observations"): return
	if not _require(not director.handle_story_action("phone", player), "phone answer must be one-shot"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook must wait for both lobby observations"): return
	if not _require(director.handle_story_action("desk_clock", player), "desk clock should be readable after the briefing"): return
	if not _require(await _wait_for_flag("desk_clock_observation_complete"), "desk clock observation should complete"): return
	if not _require(GameState.objective == "Read the night register, then sign the night log.", "desk clock objective did not advance to the register"): return
	if not _require(director.handle_story_action("lobby_register", player), "night register should be readable"): return
	if not _require(await _wait_for_flag("lobby_register_observation_complete"), "night register observation should complete"): return
	if not _require(not director.handle_story_action("lobby_register", player), "night register observation must be one-shot"): return
	if not _require(director.handle_story_action("logbook", player), "logbook should grant key"): return
	if not _require(GameState.has_item("floor_key"), "logbook should add the floor key"): return
	var hud := gameplay.get_node("HUD")
	if not _require("Fourth-floor key" in hud.inventory_label.text and not "floor_key" in hud.inventory_label.text, "HUD exposed the internal floor-key ID"): return
	if not _require(not director.handle_story_action("logbook", player), "logbook signing must be one-shot"): return
	var floor_door := gameplay.get_node("floor_door") as DoorInteractable
	GameState.consume_item("floor_key")
	if not _require(floor_door.interact(player), "missing-key door attempt was not handled"): return
	if not _require(not floor_door.is_open and not floor_door._moving and not GameState.has_flag("floor_door_unlocked"), "floor door mutated without the granted key"): return
	await get_tree().create_timer(0.3).timeout
	GameState.add_item("floor_key")
	var reentry_results: Array[bool] = []
	var inventory_reentry := func(_items: Array[String]) -> void:
		reentry_results.append(floor_door.interact(player))
	var flag_reentry := func(id: String, value: bool) -> void:
		if id == "floor_door_unlocked" and value:
			reentry_results.append(floor_door.interact(player))
	GameState.inventory_changed.connect(inventory_reentry)
	GameState.flag_changed.connect(flag_reentry)
	if not _require(floor_door.interact(player), "floor door rejected the granted key"): return
	GameState.inventory_changed.disconnect(inventory_reentry)
	GameState.flag_changed.disconnect(flag_reentry)
	if not _require(reentry_results == [false, false], "unlock signals reentered the door transaction"): return
	if not _require(not GameState.has_item("floor_key") and GameState.has_flag("floor_door_unlocked"), "floor-door unlock did not atomically consume the key and persist"): return
	await get_tree().create_timer(0.65).timeout
	if not _require(floor_door.is_open, "floor door did not finish opening"): return
	if not _require(floor_door.interact(player), "unlocked floor door did not close without restoring the key"): return
	await get_tree().create_timer(0.65).timeout
	if not _require(floor_door.interact(player), "permanently unlocked floor door did not reopen"): return
	await get_tree().create_timer(0.65).timeout
	if not _require(floor_door.is_open and not GameState.has_item("floor_key"), "floor door lost its session unlock invariant"): return
	if not _require(not director.handle_story_action("radio", player), "radio must wait for memories"): return
	if not _require(not director.handle_story_action("floor_notice", player), "floor notice must stay behind the fourth-floor gate"): return
	player.global_position.z = WorldLayout.FLOOR_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.has_flag("floor_reached") and GameState.stage == GameState.Stage.FLOOR4_DARK, "production floor threshold did not advance pacing stage"): return
	if not _require(not director.handle_story_action("fuse_pickup", player), "fuse pickup must wait for the maintenance notice"): return
	if not _require(director.handle_story_action("floor_notice", player), "floor notice should be readable"): return
	if not _require(await _wait_for_flag("floor_notice_observation_complete"), "floor notice observation should complete"): return
	if not _require(not director.handle_story_action("floor_notice", player), "floor notice observation must be one-shot"): return
	if not _require(director.handle_story_action("fuse_pickup", player), "fuse pickup should work"): return
	if not _require(GameState.has_item("spare_fuse"), "fuse pickup should add the spare fuse"): return
	if not _require(not director.handle_story_action("fuse_pickup", player), "fuse pickup must be one-shot"): return
	if not _require(director.handle_story_action("fuse_box", player), "fuse should install"): return
	if not _require(GameState.has_flag("fuse_collected") and GameState.has_flag("fuse_installed") and not GameState.has_item("spare_fuse"), "fuse installation should consume the one-shot spare"): return
	if not _require(director.get_story_prompt("fuse_pickup", player).is_empty(), "installed fuse regained a backtracking prompt"): return
	if not _require(not director.handle_story_action("fuse_pickup", player) and not GameState.has_item("spare_fuse"), "installed fuse could be collected again after consumption"): return
	if not _require(not director.handle_story_action("fuse_box", player), "fuse installation must be one-shot"): return
	if not _require(await _wait_for_flag("power_stable"), "power sequence should stabilize"): return
	player.global_position.z = WorldLayout.MEMORY_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.has_flag("memory_loop_started") and GameState.stage == GameState.Stage.MEMORY_LOOP, "production memory threshold did not advance pacing stage"): return
	if not _require(not director.handle_story_action("memory_cassette", player), "memories must be collected in authored order"): return
	if not _require(not director.handle_story_action("hallway_loop", player), "hallway loop must wait for the first memory echo"): return
	if not _require(director.handle_story_action("memory_photo", player), "photo should collect"): return
	if not _require(await _wait_for_flag("memory_photo_recalled"), "photo memory should finish"): return
	if not _require(not director.handle_story_action("hallway_loop", player), "hallway loop must wait for the environmental echo"): return
	if not _require(director.handle_story_action("memory_echo", player), "first memory echo should be readable"): return
	if not _require(await _wait_for_flag("memory_echo_1"), "first memory echo should finish"): return
	if not _require(director.handle_story_action("hallway_loop", player), "first hallway loop should turn"): return
	if not _require(await _wait_for_transition(director), "first hallway transition should finish"): return
	if not _require(director.handle_story_action("memory_cassette", player), "cassette should collect"): return
	if not _require(await _wait_for_flag("memory_cassette_recalled"), "cassette memory should finish"): return
	if not _require(not director.handle_story_action("memory_cassette", player), "cassette memory must be one-shot"): return
	if not _require(director.handle_story_action("memory_echo", player), "second memory echo should be readable"): return
	if not _require(await _wait_for_flag("memory_echo_2"), "second memory echo should finish"): return
	if not _require(director.handle_story_action("hallway_loop", player), "second hallway loop should turn"): return
	if not _require(await _wait_for_transition(director), "second hallway transition should finish"): return
	if not _require(director.handle_story_action("memory_rabbit", player), "rabbit should collect"): return
	if not _require(await _wait_for_flag("memory_rabbit_recalled"), "rabbit memory should finish"): return
	if not _require(not director.handle_story_action("memory_rabbit", player), "rabbit memory must be one-shot"): return
	if not _require(director.handle_story_action("memory_echo", player), "final memory echo should be readable"): return
	if not _require(await _wait_for_flag("memory_echo_3"), "final memory echo should finish"): return
	if not _require(await _wait_for_flag("memory_loop_complete"), "final memory transition should finish"): return
	if not _require(await _wait_for_transition(director), "final hallway transition should release player input"): return
	if not _require(not director.handle_story_action("memory_echo", player), "final memory echo must be one-shot"): return
	if not _require(not director.handle_story_action("hallway_loop", player), "completed memory loop must stay closed"): return
	if not _require(not director.handle_story_action("memory_photo", player), "duplicate memory must be rejected"): return
	if not _require(director.handle_story_action("radio", player), "radio UI should open"): return
	var radio_ui: Variant = director._story._radio_ui
	var radio_escape := InputEventAction.new()
	radio_escape.action = "pause_game"
	radio_escape.pressed = true
	radio_ui._unhandled_input(radio_escape)
	if not _require(not radio_ui.visible and not player.is_input_locked(), "Escape did not close radio and restore player input"): return
	if not _require(director.handle_story_action("radio", player), "radio did not reopen after stepping away"): return
	radio_ui._on_text_changed("0x0y")
	if not _require(radio_ui.entry.text == "00", "radio entry did not filter non-digit input"): return
	radio_ui.entry.text = "1111"
	radio_ui._submit()
	if not _require(radio_ui.submit_button.disabled, "wrong radio code must start cooldown"): return
	radio_ui.close()
	radio_ui.open(director, player)
	if not _require(not radio_ui._accepting_input and radio_ui.submit_button.disabled, "closing and reopening radio bypassed cooldown"): return
	radio_ui.entry.text = "0007"
	radio_ui._submit()
	if not _require(not GameState.has_flag("radio_sequence_started"), "radio accepted a code during cooldown"): return
	if not _require(await _wait_for_radio(radio_ui), "radio cooldown should end"): return
	radio_ui.entry.text = "2222"
	radio_ui._submit()
	if not _require(await _wait_for_radio(radio_ui), "second radio cooldown should end"): return
	radio_ui.entry.text = "3333"
	radio_ui._submit()
	if not _require(radio_ui.result.text == "Hint: the clock stopped at 00:07.", "radio did not reveal its fallback hint after three failures"): return
	if not _require(await _wait_for_radio(radio_ui), "third radio cooldown should end"): return
	radio_ui.entry.text = "0007"
	radio_ui._submit()
	if not _require(await _wait_for_flag("radio_solved"), "radio flag missing"): return
	if not _require(await _wait_for_checkpoint("room_entrance"), "radio completion did not create the pre-room checkpoint"): return
	if not _require(int(GameState.checkpoint.get("stage", -1)) == GameState.Stage.MEMORY_LOOP and not bool((GameState.checkpoint.get("flags", {}) as Dictionary).get("room_entered", false)), "room checkpoint was not captured before Room 407 entry"): return
	var room_checkpoint_snapshot := JSON.stringify(GameState.checkpoint)
	if not _require(not director.handle_story_action("radio", player), "solved radio must not reopen"): return
	if not _require(not director.handle_story_action("room_record", player), "Room 407 recording must wait for room entry"): return
	if not _require(not director.handle_story_action("room_drawing", player), "room drawing must wait for the family recording"): return
	if not _require(not director.handle_story_action("room_bed_observation", player), "bed search must wait for the family recording"): return
	if not _require(not director.handle_story_action("room_wardrobe_observation", player), "wardrobe search must wait for the family recording"): return
	if not _require(not director.handle_story_action("room_family_table", player), "family table search must wait for the family recording"): return
	player.global_position.z = WorldLayout.ROOM_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.has_flag("room_entered") and GameState.stage == GameState.Stage.ROOM_407, "production Room 407 threshold did not advance pacing stage"): return
	if not _require(JSON.stringify(GameState.checkpoint) == room_checkpoint_snapshot, "room threshold overwrote the safe pre-door checkpoint"): return
	if not _require(director.handle_story_action("room_record", player), "room recording should play"): return
	if not _require(await _wait_for_flag("room_record_heard"), "room recording should complete"): return
	if not _require(not director.handle_story_action("room_record", player), "room recording must be one-shot"): return
	if not _require(director.handle_story_action("room_drawing", player), "room drawing should unlock"): return
	if not _require(not director.handle_story_action("final_clue", player), "final clue must wait for the three Room 407 searches"): return
	if not _require(director.handle_story_action("room_bed_observation", player), "room bed observation should unlock"): return
	if not _require(await _wait_for_flag("room_bed_observation_complete"), "room bed observation should complete"): return
	if not _require(not director.handle_story_action("room_bed_observation", player), "bed observation must be one-shot"): return
	if not _require(director.handle_story_action("room_wardrobe_observation", player), "wardrobe observation should unlock"): return
	if not _require(await _wait_for_flag("room_wardrobe_observation_complete"), "wardrobe observation should complete"): return
	if not _require(not director.handle_story_action("final_clue", player), "final clue must wait for the family table observation"): return
	if not _require(director.handle_story_action("room_family_table", player), "family table observation should unlock"): return
	if not _require(await _wait_for_flag("room_family_table_observation_complete"), "family table observation should complete"): return
	if not _require(not director.handle_story_action("room_family_table", player), "family table observation must be one-shot"): return
	if not _require(director.handle_story_action("final_clue", player), "final clue should open note"): return
	director.on_note_closed()
	if not _require(GameState.has_flag("final_clue_seen"), "final clue flag missing"): return
	if not _require(await _wait_for_flag("chase_ready"), "chase build-up should complete"): return
	if not _require(str(GameState.checkpoint.get("spawn_id", "")) == "chase_start", "later chase checkpoint did not supersede the room checkpoint"): return
	player.global_position.z = WorldLayout.CHASE_TRIGGER_Z - 0.1
	director._process(0.0)
	if not _require(GameState.stage == GameState.Stage.CHASE, "chase stage missing"): return
	if not _require(is_instance_valid(director._chase.entity), "chase entity missing before capture test"): return
	# Center the capsule above the floor and let the scheduled production physics
	# path evaluate navigation, movement, collision recovery, and proximity.
	director._chase.entity.global_position = player.global_position + Vector3(0, 1.1, 0.05)
	director._chase.entity.velocity = Vector3.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not _require(director._chase.recovering, "enemy proximity did not trigger capture recovery"): return
	await get_tree().create_timer(1.4).timeout
	if not _require(not director._chase.recovering, "fail recovery should finish"): return
	if not _require(is_equal_approx(player.global_position.z, WorldLayout.CHASE_RESPAWN_Z), "fail recovery marker mismatch"): return
	var entity_count := 0
	for child in gameplay.get_children():
		if child.name.begins_with("TheEntity"):
			entity_count += 1
	if not _require(entity_count == 1, "fail recovery duplicated the entity"): return
	director._chase.ending_reveal_duration = 0.01
	if not _require(director.handle_story_action("exit", player), "ending should accept the completed chase path"): return
	if not _require(GameState.stage == GameState.Stage.ENDING, "ending stage missing"): return
	if not _require(gameplay.has_node("AbandonedLobbyFloor"), "abandoned lobby reveal missing"): return
	if not _require(await _wait_for_node(gameplay, "EndingOverlay"), "credits did not follow the in-world reveal"): return
	if not _verify_complete_pacing_report(director): return
	var pacing_before_duplicate: String = JSON.stringify(director.get_playthrough_pacing_report())
	director._chase.finish()
	await get_tree().process_frame
	if not _require(_count_named_children(gameplay, "EndingOverlay") == 1, "duplicate ending created a second credits overlay"): return
	if not _require(JSON.stringify(director.get_playthrough_pacing_report()) == pacing_before_duplicate, "duplicate ending mutated the pacing report"): return
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

func _verify_complete_pacing_report(director: Node) -> bool:
	if not _require(director.has_method("get_playthrough_pacing_report"), "gameplay director does not expose pacing telemetry"): return false
	var report: Dictionary = director.get_playthrough_pacing_report()
	if not _require(bool(report.get("eligible_full_run", false)), "fresh gameplay session was not eligible for pacing evidence"): return false
	if not _require(bool(report.get("complete", false)), "credits did not finalize the pacing report"): return false
	if not _require(report.get("within_target") == false, "compressed headless run was incorrectly accepted as a 15-20 minute playthrough"): return false
	if not _require((report.get("missing_milestones", []) as Array).is_empty(), "complete run retained missing pacing milestones"): return false
	var expected_order: Array[String] = ["lobby", "floor4_dark", "floor4_powered", "memory_loop", "room_407", "chase", "ending", "credits"]
	var actual_order: Array = report.get("boundary_order", []) as Array
	if not _require(actual_order == expected_order, "pacing boundary order did not follow production progression"): return false
	if not _require(bool(report.get("boundary_order_valid", false)), "complete pacing report marked its milestone order invalid"): return false
	var stage_seconds: Dictionary = report.get("stage_active_seconds", {}) as Dictionary
	var previous_seconds := -1.0
	for milestone: String in expected_order:
		if not _require(stage_seconds.has(milestone), "pacing report missing %s boundary" % milestone): return false
		var current_seconds := float(stage_seconds[milestone])
		if not _require(current_seconds >= previous_seconds, "pacing timestamps decreased at %s" % milestone): return false
		previous_seconds = current_seconds
	var chapter_seconds: Dictionary = report.get("chapter_active_seconds", {}) as Dictionary
	for chapter: String in ["opening", "floor4", "memory_loop", "room407", "chase_ending"]:
		var duration: Variant = chapter_seconds.get(chapter)
		if not _require(duration != null and float(duration) >= 0.0, "pacing chapter %s was incomplete" % chapter): return false
	var mutated_report: Dictionary = director.get_playthrough_pacing_report()
	mutated_report["eligible_full_run"] = false
	(mutated_report["target_seconds"] as Dictionary)["total"] = [0.0, 0.0]
	var fresh_report: Dictionary = director.get_playthrough_pacing_report()
	if not _require(bool(fresh_report["eligible_full_run"]), "pacing facade leaked top-level report mutations"): return false
	if not _require((fresh_report["target_seconds"] as Dictionary)["total"] == [900.0, 1200.0], "pacing facade leaked nested report mutations"): return false
	if not _require(float(report.get("paused_seconds", 0.0)) > 0.0, "pacing report lost the deliberate pause interval"): return false
	return _require(float(report.get("active_gameplay_seconds", -1.0)) >= 0.0 and float(report.get("wall_clock_seconds", -1.0)) >= float(report.get("active_gameplay_seconds", -1.0)), "pacing totals were invalid")

func _count_named_children(parent: Node, child_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name == child_name:
			count += 1
	return count

func _wait_for_flag(flag: String, max_frames := 180) -> bool:
	for _frame in max_frames:
		if GameState.has_flag(flag):
			return true
		await get_tree().process_frame
	return false

func _wait_for_checkpoint(spawn_id: String, max_frames := 180) -> bool:
	for _frame in max_frames:
		if str(GameState.checkpoint.get("spawn_id", "")) == spawn_id:
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

func _wait_for_node(parent: Node, node_name: String, max_frames := 120) -> bool:
	for _frame in max_frames:
		if parent.has_node(node_name):
			return true
		await get_tree().process_frame
	return false

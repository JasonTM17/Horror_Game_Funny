extends Node

const SETTINGS_SCENE := preload("res://scenes/ui/settings-panel.tscn")
const PAUSE_SCENE := preload("res://scenes/ui/pause-menu.tscn")
const BOOT_SCENE := preload("res://scenes/boot/boot.tscn")
const FAIL_SCENE := preload("res://scenes/ui/fail-overlay.tscn")
const ENDING_SCENE := preload("res://scenes/ui/ending-overlay.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

var _save_failure_path := ""
var _save_failure_error: Error = OK
var _panel_closed_count := 0

func run() -> bool:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not await _verify_save_failure_feedback(): return false
	if not await _verify_player_facing_copy(): return false
	if not await _verify_pause_focus_return(): return false
	if not await _verify_boot_focus_return(): return false
	GameState.reset_run()
	return true

func _verify_save_failure_feedback() -> bool:
	var panel := SETTINGS_SCENE.instantiate()
	add_child(panel)
	await get_tree().process_frame
	_save_failure_path = ""
	_save_failure_error = OK
	_panel_closed_count = 0
	SettingsManager.settings_save_failed.connect(_on_settings_save_failed, CONNECT_ONE_SHOT)
	panel.panel_closed.connect(_on_panel_closed, CONNECT_ONE_SHOT)
	var missing_directory_path := "user://missing-settings-directory/room407.cfg"
	panel._save_path = missing_directory_path
	panel.open_panel()
	if not _require(get_viewport().gui_get_focus_owner() == panel.get_node("Panel/Close"), "settings panel did not focus its primary close action"): return false
	panel.close_panel()
	if not _require(panel.visible and _panel_closed_count == 0, "settings panel pretended a failed save had closed successfully"): return false
	if not _require(_save_failure_path == missing_directory_path and _save_failure_error != OK, "settings manager did not return and report the save failure"): return false
	var status := panel.get_node("Panel/SaveStatus") as Label
	var close_without_saving := panel.get_node("Panel/CloseWithoutSaving") as Button
	if not _require(status.visible and status.text.begins_with("Your settings could not be saved.") and not status.text.contains("(") and close_without_saving.visible, "save failure exposed technical error text or omitted a readable recovery choice"): return false
	if not _require(_has_modal_mouse_blocker(panel), "settings panel does not block mouse input outside its dialog"): return false
	panel._unhandled_input(_make_escape_event())
	if not _require(not panel.visible and _panel_closed_count == 1, "Escape did not close the panel for this session after a save failure"): return false
	var focus_owner := get_viewport().gui_get_focus_owner()
	if not _require(not is_instance_valid(focus_owner) or not panel.get_node("Panel").is_ancestor_of(focus_owner), "hidden settings control retained keyboard focus"): return false
	panel.queue_free()
	await get_tree().process_frame
	return true

func _verify_player_facing_copy() -> bool:
	var settings := SETTINGS_SCENE.instantiate()
	var fail_overlay := FAIL_SCENE.instantiate()
	var ending_overlay := ENDING_SCENE.instantiate()
	add_child(settings)
	add_child(fail_overlay)
	add_child(ending_overlay)
	await get_tree().process_frame
	var settings_copy := " ".join([
		(settings.get_node("Panel/HeadBob") as CheckButton).text,
		(settings.get_node("Panel/MusicLabel") as Label).text,
		(settings.get_node("Panel/AmbienceLabel") as Label).text,
		(settings.get_node("Panel/FilmGrain") as CheckButton).text,
	])
	if not _require(settings_copy == "Camera movement Music Atmosphere Screen texture", "settings still use implementation-oriented presentation labels"): return false
	var comfort_copy := (settings.get_node("Panel/ComfortHint") as Label).text
	if not _require(comfort_copy == "Need a gentler shift? Disable flicker,\ncamera movement, shake, or screen texture.", "settings lost the concise comfort guidance"): return false
	var failure_copy := (fail_overlay.get_node("Panel/Message") as Label).text
	if not _require(failure_copy == "THE HALLWAY SWALLOWED YOU\nIt is waiting where you fell." and not failure_copy.to_lower().contains("checkpoint"), "failure overlay lost its in-world recovery message or exposes checkpoint terminology"): return false
	var credits_copy := (ending_overlay.get_node("Panel/Credits") as Label).text
	if not _require(credits_copy == "ROOM 407: THE LAST SHIFT\n\nCreated by JasonTM17 and contributors\n\nThank you for taking the last shift.", "ending credits lost their concise player-facing attribution"): return false
	var normalized_credits := credits_copy.to_lower()
	for technical_term in ["Engine", "4.7.1", "shader", "Procedural", "MIT licensed"]:
		if not _require(not normalized_credits.contains(technical_term.to_lower()), "ending credits expose technical production metadata: %s" % technical_term): return false
	settings.queue_free()
	fail_overlay.queue_free()
	ending_overlay.queue_free()
	await get_tree().process_frame
	return true

func _verify_pause_focus_return() -> bool:
	var pause_menu := PAUSE_SCENE.instantiate()
	add_child(pause_menu)
	var player := PLAYER_SCENE.instantiate()
	add_child(player)
	await get_tree().process_frame
	if not _require(pause_menu.has_node("Panel/Settings") and pause_menu.has_node("SettingsPanel"), "pause settings entry missing"): return false
	get_tree().paused = true
	player.set_input_locked("pause", true)
	pause_menu._process(0.0)
	if not _require(pause_menu.get_node("Panel").visible and get_viewport().gui_get_focus_owner() == pause_menu.get_node("Panel/Resume"), "pause menu did not focus Resume when opened"): return false
	pause_menu._settings()
	var settings_panel := pause_menu.get_node("SettingsPanel")
	if not _require(settings_panel.visible and not pause_menu.get_node("Panel").visible and player.is_input_locked() and get_viewport().gui_get_focus_owner() == settings_panel.get_node("Panel/Close"), "pause settings did not become modal while preserving the pause lock"): return false
	if not await _verify_focus_stays_in_settings(settings_panel): return false
	settings_panel._unhandled_input(_make_escape_event())
	if not _require(not settings_panel.visible and player.is_input_locked(), "closing settings cleared the underlying pause lock"): return false
	if not _require(get_viewport().gui_get_focus_owner() == pause_menu.get_node("Panel/Settings"), "pause settings did not return focus to its launcher"): return false
	pause_menu._resume()
	if not _require(not get_tree().paused and not player.is_input_locked() and not pause_menu.get_node("Panel").visible, "Resume did not close and unlock the pause menu"): return false
	var focus_owner := get_viewport().gui_get_focus_owner()
	if not _require(not is_instance_valid(focus_owner) or not pause_menu.get_node("Panel").is_ancestor_of(focus_owner), "hidden pause control retained keyboard focus"): return false
	pause_menu.queue_free()
	player.queue_free()
	await get_tree().process_frame
	return true

func _verify_boot_focus_return() -> bool:
	GameState.reset_run()
	var fresh_boot := BOOT_SCENE.instantiate()
	add_child(fresh_boot)
	await get_tree().process_frame
	await get_tree().process_frame
	var start_button := fresh_boot.find_child("Start", true, false) as Button
	var continue_button := fresh_boot.find_child("Continue", true, false) as Button
	var settings_button := fresh_boot.find_child("Settings", true, false) as Button
	var quit_button := fresh_boot.find_child("Quit", true, false) as Button
	var menu_background := fresh_boot.find_child("MenuBackground", true, false) as TextureRect
	if not _require(start_button != null and continue_button != null and not continue_button.visible and get_viewport().gui_get_focus_owner() == start_button, "fresh boot menu did not focus Start"): return false
	if not _require(menu_background != null and menu_background.texture != null and menu_background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "fresh boot menu lost its authored corridor background texture"): return false
	if not _require(_configured_window_title_is_player_facing(), "configured window title exposes a debug or production marker"): return false
	if not _require(_boot_copy_is_immersive(fresh_boot), "boot menu exposes runtime, combat, or checkpoint terminology"): return false
	settings_button.grab_focus()
	fresh_boot._show_settings()
	var boot_settings := fresh_boot.get_node("SettingsPanel")
	if not _require(boot_settings.visible and get_viewport().gui_get_focus_owner() == boot_settings.get_node("Panel/Close"), "boot settings did not take keyboard focus"): return false
	if not _require(start_button.disabled and continue_button.disabled and settings_button.disabled and quit_button.disabled, "boot settings left background menu actions enabled"): return false
	if not _require(start_button.focus_mode == Control.FOCUS_NONE and settings_button.focus_mode == Control.FOCUS_NONE and quit_button.focus_mode == Control.FOCUS_NONE, "boot settings left background menu actions focusable"): return false
	if not await _verify_focus_stays_in_settings(boot_settings): return false
	boot_settings.close_panel()
	if not _require(not boot_settings.visible and not settings_button.disabled and get_viewport().gui_get_focus_owner() == settings_button, "boot settings did not re-enable its caller and return focus"): return false
	fresh_boot.queue_free()
	await get_tree().process_frame
	GameState.set_objective("Continue focus test")
	GameState.create_checkpoint("res://scenes/gameplay/gameplay.tscn", "room_entrance")
	var checkpoint_boot := BOOT_SCENE.instantiate()
	add_child(checkpoint_boot)
	await get_tree().process_frame
	await get_tree().process_frame
	continue_button = checkpoint_boot.find_child("Continue", true, false) as Button
	if not _require(continue_button != null and continue_button.visible and get_viewport().gui_get_focus_owner() == continue_button, "checkpoint boot menu did not focus Continue"): return false
	if not _require(continue_button.text == "CONTINUE SHIFT", "continue action exposes checkpoint terminology"): return false
	checkpoint_boot.queue_free()
	GameState.reset_run()
	await get_tree().process_frame
	return true

func _boot_copy_is_immersive(boot_menu: Node) -> bool:
	var found_story_setup := false
	for node in boot_menu.find_children("*", "Label", true, false):
		var label := node as Label
		if label.text == "23:47. One last room remains unchecked.\nKeep the light on. Finish the shift.":
			found_story_setup = true
			var copy := label.text.to_lower()
			if copy.contains("minute") or copy.contains("no combat") or copy.contains("checkpoint"):
				return false
	var comfort_hint := boot_menu.find_child("ComfortHint", true, false) as Label
	return found_story_setup and comfort_hint != null and comfort_hint.text == "ESC pauses. Comfort options are available in Settings."

func _configured_window_title_is_player_facing() -> bool:
	var expected_title := "ROOM 407: THE LAST SHIFT"
	var configured_title := str(ProjectSettings.get_setting("application/config/name", ""))
	return configured_title == expected_title and not configured_title.to_upper().contains("DEBUG")

func _make_escape_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = "pause_game"
	event.pressed = true
	return event

func _verify_focus_stays_in_settings(settings_panel: CanvasLayer) -> bool:
	var dialog := settings_panel.get_node("Panel") as Control
	# Close is the last visible action in the dialog's focus order. One Tab
	# wraps globally, which is the exact path that used to reach the menu below.
	for _index in 3:
		var focus_next := InputEventAction.new()
		focus_next.action = "ui_focus_next"
		focus_next.pressed = true
		Input.parse_input_event(focus_next)
		var focus_release := InputEventAction.new()
		focus_release.action = "ui_focus_next"
		focus_release.pressed = false
		Input.parse_input_event(focus_release)
		await get_tree().process_frame
		var focus_owner := get_viewport().gui_get_focus_owner()
		if not is_instance_valid(focus_owner) or not dialog.is_ancestor_of(focus_owner):
			return _require(false, "focus traversal escaped the open Settings dialog")
	return true

func _has_modal_mouse_blocker(settings_panel: CanvasLayer) -> bool:
	var blocker := settings_panel.get_node_or_null("ModalBlocker") as Control
	return blocker != null and blocker.mouse_filter == Control.MOUSE_FILTER_STOP and is_equal_approx(blocker.anchor_right, 1.0) and is_equal_approx(blocker.anchor_bottom, 1.0)

func _on_settings_save_failed(path: String, error: Error) -> void:
	_save_failure_path = path
	_save_failure_error = error

func _on_panel_closed() -> void:
	_panel_closed_count += 1

func _require(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SETTINGS_AUDIO_ASSERT: " + message)
	get_tree().paused = false
	get_tree().quit(2)
	return false

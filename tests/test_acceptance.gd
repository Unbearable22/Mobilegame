extends SceneTree
const Main = preload("res://scenes/main.tscn")
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var ui := Main.instantiate()
	ui.save_path = "user://acceptance-progress.json"
	root.add_child(ui)
	await process_frame
	check(ui.overlay.visible and ui.screen == "menu", "main menu on startup")
	ui.close_overlay()
	ui.game.select_level(0)
	ui.game.frame_seconds = 0.05
	ui.game.tap(0)
	check(ui.targets_label.text.contains("0 / 1"), "HUD does not reveal future target activation")
	ui.toggle_sound()
	check(ui.targets_label.text.contains("0 / 1"), "sound refresh preserves animated target state")
	ui.toggle_sound()
	while ui.game.busy: await process_frame
	check(ui.screen == "won", "win state")
	ui.show_levels()
	ui.back_overlay()
	check(ui.screen == "won", "level selector Back restores result")
	ui.close_overlay()
	ui.game.select_level(2)
	ui.game.tap(0)
	while ui.game.busy: await process_frame
	check(ui.screen == "lost", "loss state from wrong direction")
	ui.show_levels()
	ui.back_overlay()
	check(ui.screen == "lost", "level selector Back restores loss")
	(ui.modal.get_child(2) as Button).pressed.emit()
	check(ui.game.grid.status() == "playing" and ui.game.grid.used == 0, "loss undo restores playable state")
	ui.show_main_menu()
	var sound: bool = ui.game.progress.data.sound
	ui.toggle_sound()
	check(ui.game.paused and ui.screen == "menu", "menu sound toggle keeps pause")
	ui.toggle_sound()
	check(ui.game.progress.data.sound == sound, "sound restored")
	ui.close_overlay()
	ui.game.select_level(5)
	ui.game.frame_seconds = 0.001
	ui.game.tap(0)
	while ui.game.busy: await process_frame
	ui.game.tap(0)
	while ui.game.busy: await process_frame
	check(ui.result_stars == 3, "required two-launch solution earns three stars")
	check(ui.buttons.restart.focus_mode == Control.FOCUS_NONE, "modal traps focus away from background")
	ui.close_overlay()
	check(ui.buttons.sound.custom_minimum_size.y >= 144, "48dp target at 360 logical phone width")
	ui.game.select_level(9)
	ui.game.tap(0)
	while ui.game.busy: await process_frame
	check(ui.game.grid.status() == "lost", "final level cannot bypass rotations")
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Acceptance: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

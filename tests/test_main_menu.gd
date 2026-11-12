extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Save = preload("res://scripts/core/save_manager.gd")
var passed: int = 0
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func run() -> void:
	var ui := Main.instantiate()
	ui.save_path = "user://test-menu-v4.json"
	root.add_child(ui)
	await process_frame
	check(ui.get("main_menu") != null,"dedicated full-screen main menu exists")
	if ui.get("main_menu") == null:
		ui.queue_free()
		await process_frame
		quit(1)
		return
	var menu: Control = ui.main_menu
	ui.game.progress.data = Save.defaults()
	ui.game.select_level(0)
	ui.show_main_menu()
	check(menu.visible and menu.reaction.is_processing(),"menu activates cosmetic animation")
	check(menu.progress_label.text == "0 / 100" and menu.stars_label.text == "0 / 300","fresh progress accurate")
	check(menu.progress_bar.value == 0,"fresh progress bar")
	var snapshot: Dictionary = ui.game.progress.data.duplicate(true)
	var state: Dictionary = ui.game.grid.state.duplicate(true)
	var phase: float = menu.reaction.phase
	await create_timer(0.1).timeout
	check(menu.reaction.phase > phase,"animation advances")
	menu.reaction.phase = 5.99
	menu.reaction._process(0.02)
	check(is_equal_approx(menu.reaction.phase,6.01),"decorative phase remains continuous across six-second boundary")
	check(ui.game.progress.data == snapshot and ui.game.grid.state == state,"animation never touches progress or model")
	ui.info.pressed.emit()
	check(ui.screen == "guide" and not menu.reaction.is_processing(),"information stops animation")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "menu" and menu.reaction.is_processing(),"Back restores menu animation")
	ui.gear.pressed.emit()
	check(ui.screen == "settings" and not menu.reaction.is_processing(),"settings stops animation")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(0.25).timeout
	check(ui.screen == "menu" and menu.reaction.is_processing(),"settings returns to animated menu")
	ui.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not menu.reaction.is_processing(),"background stops decorative processing")
	ui.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(menu.reaction.is_processing(),"foreground menu resumes decoration")
	menu.chapters_button.pressed.emit()
	check(ui.screen == "chapters" and not menu.visible and not menu.reaction.is_processing(),"chapter CTA functional and animation stopped")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "menu","chapters Back restores menu")
	for id in range(1,11): ui.game.progress.complete(id,2)
	ui.game.select_level(18)
	ui.show_main_menu()
	check(menu.progress_label.text == "10 / 100" and menu.stars_label.text == "20 / 300","partial campaign counts")
	check(menu.progress_bar.value == 10 and menu.chapter_label.text.contains("Пробуждение"),"current chapter and progress bar")
	menu.continue_button.pressed.emit()
	check(ui.screen == "game" and ui.game.current == 18 and not ui.game.paused,"Continue opens last accessible selected level")
	check(not menu.reaction.is_processing() and not ui.overlay.visible,"game has no menu input or animation")
	ui.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ui.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not menu.reaction.is_processing(),"foreground gameplay never starts menu animation")
	ui.game.frame_seconds = 0.1
	ui.game.select_level(0)
	ui.game.tap(0)
	ui.show_main_menu()
	var used: int = ui.game.grid.used
	menu.continue_button.pressed.emit()
	check(ui.game.busy and ui.game.grid.used == used,"Continue resumes reaction without restart or extra launch")
	while ui.game.busy: await process_frame
	for id in range(1,101): ui.game.progress.complete(id,3)
	ui.show_main_menu()
	check(menu.progress_label.text == "100 / 100" and menu.stars_label.text == "300 / 300","completed campaign totals")
	check(menu.status_label.text.contains("пройдены") and menu.progress_bar.value == 100,"distinct campaign completion")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "menu" and ui.game.paused,"Back on main menu does not start game")
	menu.apply_insets(96,140,80,100)
	await process_frame
	await process_frame
	check(ui.get_viewport_rect().encloses(menu.continue_button.get_global_rect()),"simulated notch insets keep Continue visible")
	check(ui.get_viewport_rect().encloses(menu.stars_label.get_global_rect()),"simulated bottom inset keeps progress visible")
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Main menu: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)

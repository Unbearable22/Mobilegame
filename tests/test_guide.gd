extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Guide = preload("res://scripts/ui/node_guide.gd")
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
	ui.save_path = "user://test-guide-v3.json"
	root.add_child(ui)
	await process_frame
	ui.game.progress.data = preload("res://scripts/core/save_manager.gd").defaults()
	ui.info.pressed.emit()
	check(ui.screen == "guide" and ui.game.paused,"menu info opens")
	for page in range(Guide.CARDS.size()):
		ui.guide_page = page
		ui.show_information()
		check(ui.guide_preview.get_script() == ui.board.get_script(),"preview uses actual Board renderer")
		check(ui.guide_preview.level.nodes[0].type == Guide.CARDS[page].type,"glyph matches described node")
		check(ui.guide_preview.mouse_filter == Control.MOUSE_FILTER_IGNORE,"preview never steals touch")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "menu" and ui.game.paused,"Back restores menu")
	ui.close_overlay()
	check(not ui.hint_label.visible and not ui.title_label.visible,"compact HUD no explanation")
	check(ui.buttons.undo.text.is_empty() and ui.buttons.restart.text.is_empty() and ui.buttons.pause.text.is_empty(),"HUD icons not text")
	ui.game.select_level(0)
	ui.game.frame_seconds = 0.08
	ui.game.tap(0)
	ui.info.pressed.emit()
	var state: Dictionary = ui.board.state.duplicate(true)
	await create_timer(0.1).timeout
	check(ui.game.busy and ui.board.state == state,"guide pauses wave")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	while ui.game.busy: await process_frame
	check(ui.screen == "won","guide resumes wave")
	ui.show_chapters()
	check(ui.screen == "chapters" and ui.modal.get_child_count() == 7,"five chapter cards plus title/back")
	check((ui.modal.get_child(2) as Button).disabled,"second chapter closed initially")
	for id in range(1,11): ui.game.progress.complete(id,3)
	ui.screen = "chapters"
	ui.show_chapters()
	check(not (ui.modal.get_child(2) as Button).disabled,"chapter card opens after completion")
	(ui.modal.get_child(2) as Button).pressed.emit()
	check(ui.screen == "levels" and ui.selected_chapter == 2,"chapter routes to its ten levels")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "chapters", "Back from level list returns chapters")
	ui.game.progress.data = preload("res://scripts/core/save_manager.gd").defaults()
	ui.close_overlay()
	ui.game.select_level(9)
	ui.show_result(true,3)
	check((ui.modal.get_child(2) as Button).get_meta("semantic_label") == "Завершить главу", "incomplete chapter result routes to chapter list")
	(ui.modal.get_child(2) as Button).pressed.emit()
	check(ui.screen == "chapters", "no silent Next into locked chapter")
	ui.selected_chapter = 1
	ui.show_levels()
	(ui.modal.get_child(ui.modal.get_child_count()-1) as Button).pressed.emit()
	check(ui.screen == "chapters", "visible Back agrees with Android Back")
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Guide/UI chapters: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)

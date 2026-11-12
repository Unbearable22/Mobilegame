extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Save = preload("res://scripts/core/save_manager.gd")
var passed: int = 0
var failed: int = 0
func check(ok: bool,label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func labels(node: Node) -> String:
	var result: String = node.text if node is Label or node is Button else ""
	for child in node.get_children(): result += labels(child)
	return result
func run() -> void:
	var ui := Main.instantiate()
	ui.save_path = "user://test-v5-ui.json"
	root.add_child(ui)
	await process_frame
	ui.game.progress.data = Save.defaults()
	ui.game.select_level(0)
	ui.show_main_menu()
	check(ui.has_method("show_achievements"),"achievement screen exists")
	if not ui.has_method("show_achievements"):
		ui.queue_free()
		await process_frame
		quit(1)
		return
	ui.main_menu.achievements_button.pressed.emit()
	check(ui.screen=="achievements" and ui.game.paused,"menu achievement link")
	check(not ui.main_menu.reaction.is_processing(),"achievement screen stops menu work")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="menu","achievement Back returns menu")
	ui.main_menu.themes_button.pressed.emit()
	check(ui.screen=="themes","menu themes link")
	check(ui.retention_view.theme_buttons["electric_blue"].disabled,"unearned theme disabled")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	ui.close_overlay()
	ui.game.select_level(2)
	ui.show_levels()
	check(ui.modal.get_child_count()==3,"minimal selector only title grid chapter-back")
	check(not labels(ui.modal).to_lower().contains("запуск") and not labels(ui.modal).contains("par_launches"),"no norms or mechanics in selector")
	var grid: GridContainer = ui.modal.get_child(1)
	check(grid.get_child_count()==25 and grid.columns==5,"compact25levelgrid")
	for i in range(25):
		var button: Button = grid.get_child(i)
		check(button.text=="%02d"%(i+1) and button.tooltip_text.is_empty(),"level button number only and no norm tooltip")
		check(button.custom_minimum_size.x>=144 and button.custom_minimum_size.y>=144,"finger sized level button")
	check(grid.get_child(2).get_meta("current_level",false),"current level highlighted")
	check(grid.get_child(2).get_theme_stylebox("normal").corner_radius_top_left>=20,"current neon frame keeps button silhouette")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="chapters","level Back returns chapters")
	ui.selected_chapter=2
	ui.screen="chapters"
	ui.show_levels()
	grid=ui.modal.get_child(1)
	await process_frame
	await process_frame
	for button in grid.get_children():
		check(button.disabled and button.get_meta("locked",false),"locked chapter grid disabled with lock")
		check(button.get_global_rect().encloses(button.get_child(0).get_global_rect()),"lock stays inside disabled level button")
	ui.close_overlay()
	ui.show_settings()
	ui.buttons.reduced_effects.button_pressed=true
	check(ui.game.settings.reduced_effects_enabled() and ui.board.reduced_effects,"reduced effects applies immediately")
	ui.show_statistics()
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="settings","statistics Back restores settings")
	ui.close_settings()
	await create_timer(.2).timeout
	check(ui.screen=="game","nested statistics never replaces settings parent")
	ui.show_main_menu()
	check(not ui.main_menu.reaction.is_processing(),"reduced effects removes menu motion")
	ui.show_statistics()
	check(ui.screen=="statistics","statistics screen")
	ui.retention_view.export_button.pressed.emit()
	check(ui.screen=="statistics_export" and FileAccess.file_exists(ui.statistics_export_path),"JSON export accessible and created")
	var parser:=JSON.new()
	check(parser.parse(ui.statistics_export_text)==OK,"export displayed as valid JSON")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="statistics","export Back returns statistics")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="menu","statistics Back restores parent")
	for id in range(1,11): ui.game.progress.complete(id,3)
	ui.show_themes()
	check(not ui.retention_view.theme_buttons.electric_blue.disabled,"earned theme available")
	var state: Dictionary=ui.game.grid.state.duplicate(true)
	ui.retention_view.theme_buttons.electric_blue.pressed.emit()
	check(ui.game.settings.theme_id()=="electric_blue" and ui.board.palette.accent!=Color("4de6f5"),"theme applies to board")
	check(ui.game.grid.state==state,"theme never changes gameplay state")
	ui.show_achievements()
	check(ui.retention_view.achievement_cards.size()==3,"achievement screen bounded pagination")
	ui.retention_view.next_button.pressed.emit()
	check(ui.achievement_page==1,"achievement pagination")
	ui.close_overlay()
	ui.game.select_level(0)
	ui.game.frame_seconds=.001
	ui.game.tap(0)
	while ui.game.busy: await process_frame
	check(ui.screen=="won" and ui.modal.get_child(1).text.contains("★★★"),"reduced effects final stars immediate")
	ui.show_settings()
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(.2).timeout
	check(ui.screen=="won","settings preserves result with effects preference")
	ui.close_overlay()
	ui.show_settings()
	ui.show_statistics()
	ui.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ui.game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ui.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="settings","background nested statistics returns settings")
	ui.close_settings()
	await create_timer(.2).timeout
	check(ui.screen=="pause" and ui.game.paused,"background nested statistics preserves pause ancestor")
	ui.queue_free()
	await create_timer(.2).timeout
	print("V5 UI: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

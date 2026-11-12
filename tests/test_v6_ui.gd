extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var passed:int=0
var failed:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if ok:passed+=1
	else:failed+=1;push_error(label)
func run()->void:
	var path:String="user://v6-ui.json"
	DirAccess.remove_absolute(path)
	var ui=load("res://scenes/main.tscn").instantiate()
	ui.save_path=path
	root.add_child(ui)
	await process_frame
	ui.game.settings.set_reduced_effects(true)
	ui.main_menu.reactor_button.pressed.emit()
	check(ui.screen=="reactor" and ui.game.paused,"reactor opens")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="menu","reactor AndroidBack")
	ui.main_menu.daily_button.pressed.emit()
	check(ui.screen=="daily" and ui.game.paused,"daily opens")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="menu","daily AndroidBack")
	ui.close_overlay()
	ui.show_reactor()
	ui.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ui.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	ui.back_overlay()
	check(ui.screen=="pause" and ui.game.paused,"reactor background preserves Pause")
	ui.close_overlay()
	ui.show_daily()
	ui.gear.pressed.emit()
	ui.close_settings()
	check(ui.screen=="daily","settings restores daily")
	ui.back_overlay()
	check(ui.screen=="game","daily restores previous gameplay")
	for id in range(1,76):ui.game.progress.complete(id,3)
	ui.selected_chapter=4;ui.screen="chapters";ui.show_levels()
	var grid=ui.modal.get_child(1)
	check(grid.get_child_count()==25 and grid.get_child(24).text=="100","chapter4 minimal25grid")
	grid.get_child(24).pressed.emit()
	check(ui.screen=="game" and ui.game.current==99,"finallevel navigation")
	ui.show_information()
	for page in range(ui.Guide.CARDS.size()):
		ui.guide_page=page;ui.show_information()
		check(ui.guide_preview.level.nodes[0].type==ui.Guide.CARDS[page].type,"canonicalguide%d"%page)
	ui.back_overlay()
	check(ui.screen=="game" and not ui.game.paused,"guide returnsgame")
	ui.show_main_menu()
	ui.show_daily()
	ui.retention_view.get_child(ui.retention_view.get_child_count()-1).pressed.emit()
	check(ui.screen=="game" and not ui.game.daily_date.is_empty(),"daily play button")
	ui.game.restart()
	ui.show_main_menu()
	ui.main_menu.continue_button.pressed.emit()
	check(ui.game.daily_date.is_empty() and ui.game.current==99,"Continue resumes saved campaign after daily")
	ui.queue_free();await process_frame
	print("V6 UI: %d passed,%d failed"%[passed,failed]);quit(1 if failed else 0)

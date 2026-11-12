extends SceneTree
var ui:Control
var failed:int=0
var checks:int=0
var prefix:String
var metrics:Dictionary={}
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failed+=1;push_error(label)
func touch(control:Control)->void:
	await process_frame;await process_frame
	await pointer(root.get_screen_transform()*control.get_global_rect().get_center())
func pointer(point:Vector2)->void:
	for down in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.position=point;event.pressed=down
		Input.parse_input_event(event);Input.flush_buffered_events()
		await process_frame
func collect(node:Node,result:Array)->void:
	if node is Control and not node.is_visible_in_tree():return
	if node is BaseButton or node is Label:result.append(node)
	for child in node.get_children():collect(child,result)
func capture(name:String)->void:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	var controls:Array=[]
	collect(ui.main_menu if ui.screen=="menu" else (ui.modal if ui.overlay.visible else ui.margin),controls)
	for control in controls:
		check(ui.get_viewport_rect().encloses(control.get_global_rect()),"clipped %s in %s"%[control,name])
		if control is Label:check(control.size.x+1>=control.get_minimum_size().x,"text %s in %s"%[control.text,name])
		if control is BaseButton:check(control.size.y>=120,"finger target "+name)
	var image:Image=root.get_texture().get_image()
	check(image.get_size()==DisplayServer.window_get_size(),"exact framebuffer")
	image.save_png("res://docs/screenshots/v6-%s-%s.png"%[prefix,name])
func settle()->void:
	var deadline:int=Time.get_ticks_msec()+15000
	while ui.game.busy and Time.get_ticks_msec()<deadline:await process_frame
	check(not ui.game.busy,"reaction bounded")
func measure(name:String)->void:
	var began:int=Time.get_ticks_usec()
	var calls:float=0
	var process_ms:float=0
	var draws:int=ui.main_menu.reaction.draw_count
	for frame in range(60):
		await process_frame
		calls+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		process_ms+=Performance.get_monitor(Performance.TIME_PROCESS)*1000
	metrics[name]={"frames":60,"mean_draw_calls":calls/60,"mean_process_ms":process_ms/60,"wall_ms":(Time.get_ticks_usec()-began)/1000.0,"cosmetic_redraws":ui.main_menu.reaction.draw_count-draws}
func run()->void:
	prefix="%dx%d"%[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	var path:String="user://v6-capture-%s.json"%prefix
	DirAccess.remove_absolute(path)
	ui=load("res://scenes/main.tscn").instantiate();ui.save_path=path
	root.add_child(ui)
	ui.game.settings.set_sound(false)
	ui.game.frame_seconds=.005
	for frame in range(5):await process_frame
	await capture("menu-fresh")
	await touch(ui.main_menu.reactor_button)
	check(ui.screen=="reactor","native reactor")
	await capture("reactor-fresh")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="menu","reactor Back")
	await touch(ui.main_menu.daily_button)
	check(ui.screen=="daily","native daily")
	await capture("daily")
	await touch(ui.retention_view.get_child(ui.retention_view.get_child_count()-1))
	check(ui.screen=="game" and not ui.game.daily_date.is_empty(),"native daily play")
	ui.show_pause();ui.show_main_menu()
	await touch(ui.main_menu.continue_button)
	check(ui.game.daily_date.is_empty() and ui.game.current==0,"native campaign return")
	# Explicit screenshot fixture only: all shipped content completed.
	for id in range(1,101):ui.game.progress.complete(id,3)
	ui.show_main_menu()
	await capture("menu-complete")
	await touch(ui.main_menu.reactor_button)
	await capture("reactor-complete")
	await touch(ui.retention_view.get_child(3))
	check(ui.game.progress.data.reactor.pulse_style=="braided","native earned pulse cosmetic")
	await touch(ui.retention_view.get_child(4))
	check(ui.game.progress.data.reactor.reactor_style=="prismatic","native earned core cosmetic")
	await capture("reactor-prismatic")
	ui.back_overlay();ui.show_chapters()
	await capture("chapters")
	ui.selected_chapter=4;ui.screen="chapters";ui.show_levels()
	await capture("levels-iv")
	var grid:GridContainer=ui.modal.get_child(1)
	await touch(grid.get_child(24))
	check(ui.game.current==99 and ui.screen=="game","native finallevel grid")
	for id in [51,57,63,69,80,90,100]:
		ui.close_overlay();ui.game.select_level(id-1)
		await capture("level-%d"%id)
		for action in ui.game.grid.level.author_solution:
			await process_frame;await process_frame
			var point:Vector2=root.get_screen_transform()*(ui.board.get_global_transform_with_canvas()*ui.board.center(int(action.index)))
			await pointer(point)
			if action.type=="launch":await settle()
		check(ui.game.grid.status()=="won","native authored win%d"%id)
		if id==100:await capture("final-victory")
	ui.close_overlay();ui.show_information()
	for page in range(9,13):
		ui.guide_page=page;ui.show_information()
		await capture("guide-%s"%ui.Guide.CARDS[page].type)
	ui.back_overlay();ui.show_main_menu()
	await measure("menu-full")
	ui.game.settings.set_reduced_effects(true)
	await process_frame;await RenderingServer.frame_post_draw
	await measure("menu-reduced")
	check(metrics["menu-reduced"].cosmetic_redraws==0,"reduced cosmetic zero repeated redraws")
	metrics["environment"]={"renderer":RenderingServer.get_video_adapter_name(),"scope":"Linux llvmpipe desktop debug; no phone/GPU/thermal claims","resolution":prefix}
	metrics["checks"]=checks;metrics["failures"]=failed
	var file:=FileAccess.open("res://docs/screenshots/v6-%s-report.json"%prefix,FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	ui.queue_free();await process_frame
	print("V6 rendered/native %s: %d checks,%d failures"%[prefix,checks,failed]);quit(1 if failed else 0)

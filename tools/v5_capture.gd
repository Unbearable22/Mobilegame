extends SceneTree
const Save = preload("res://scripts/core/save_manager.gd")
var ui: Control
var prefix: String
var failed: int = 0
var metrics: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:
		failed += 1
		push_error(label)
func touch(control: Control) -> void:
	await process_frame
	await process_frame
	var point: Vector2 = root.get_screen_transform()*control.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func collect(node: Node,output: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Label or node is BaseButton: output.append(node)
	for child in node.get_children(): collect(child,output)
func capture(label: String) -> void:
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	var controls: Array = []
	collect(ui.main_menu if ui.screen == "menu" else (ui.modal if ui.overlay.visible else ui.margin),controls)
	if ui.gear.visible: controls.append(ui.gear)
	if ui.info.visible: controls.append(ui.info)
	for control in controls:
		check(ui.get_viewport_rect().encloses(control.get_global_rect()),"clipped %s in %s" % [control,label])
		if control is Label:
			check(control.size.x+1 >= control.get_minimum_size().x,"text clipped %s in %s" % [control.text,label])
	if ui.screen == "menu":
		check(not ui.gear.get_global_rect().intersects(ui.main_menu.chapter_label.get_global_rect()),"menu gear overlap")
		check(ui.main_menu.reaction.get_global_rect().end.y <= ui.main_menu.continue_button.get_global_rect().position.y,"decoration overlaps CTA")
		check(ui.main_menu.continue_button.size.y >= 144 and ui.main_menu.chapters_button.size.y >= 144,"finger target minimum")
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == DisplayServer.window_get_size(),"exact image pixels")
	image.save_png("res://docs/screenshots/v5-%s-%s.png" % [prefix,label])
func measure(label: String,frames: int = 60) -> void:
	var time_sum: float = 0
	var draw_calls: float = 0
	var began: int = Time.get_ticks_usec()
	var draws_before: int = ui.main_menu.reaction.draw_count
	for i in range(frames):
		await process_frame
		time_sum += Performance.get_monitor(Performance.TIME_PROCESS)*1000
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	metrics[label] = {"cosmetic_draws_during_sample":ui.main_menu.reaction.draw_count-draws_before,"frames":frames,"process_ms_mean":time_sum/frames,"draw_calls_mean":draw_calls/frames,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.0}
func idle() -> void:
	var count: int=0
	while ui.game.busy and count<600:
		await process_frame
		count+=1
	check(not ui.game.busy,"reaction completes")
func run() -> void:
	prefix="%dx%d"%[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	var save_path: String="user://v5-capture-%s.json"%prefix
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	ui=load("res://scenes/main.tscn").instantiate()
	ui.save_path=save_path
	ui.statistics_export_path="user://v5-statistics-%s.json"%prefix
	root.add_child(ui)
	ui.game.settings.set_sound(false)
	ui.game.frame_seconds=.02
	for i in range(8): await process_frame
	await capture("menu")
	await measure("menu_full")
	await touch(ui.info)
	check(ui.screen=="guide","native guide")
	await capture("guide")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await touch(ui.main_menu.achievements_button)
	check(ui.screen=="achievements","native achievements")
	await capture("achievements-locked")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await touch(ui.main_menu.themes_button)
	check(ui.screen=="themes","native themes")
	await capture("themes-locked")
	await touch(ui.retention_view.theme_buttons.solar_gold)
	check(ui.game.settings.theme_id()=="neon","locked native theme cannot be selected")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await touch(ui.main_menu.continue_button)
	# Source occupies cell0; use the actual scaled native pointer route.
	if ui.game.grid.used==0:
		var point: Vector2=root.get_screen_transform()*(ui.board.get_global_transform_with_canvas()*ui.board.center(0))
		for down in [true,false]:
			var event:=InputEventScreenTouch.new()
			event.position=point
			event.pressed=down
			Input.parse_input_event(event)
			Input.flush_buffered_events()
			await process_frame
	await idle()
	check(ui.game.grid.status()=="won","native source wins")
	await capture("victory-achievement")
	ui.close_overlay()
	ui.game.select_level(2)
	ui.show_levels()
	await capture("levels-i")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="chapters","minimal list Back")
	ui.selected_chapter=5
	ui.screen="chapters"
	ui.show_levels()
	await capture("levels-locked")
	ui.close_overlay()
	ui.game.select_level(5)
	ui.game.tap(0)
	await idle()
	await capture("battery-partial")
	ui.game.frame_seconds=.1
	ui.game.tap(0)
	await create_timer(.2).timeout
	ui.game.paused=true
	if ui.board.tween: ui.board.tween.pause()
	await capture("reaction")
	ui.game.paused=false
	if ui.board.tween: ui.board.tween.play()
	await idle()
	ui.close_overlay()
	await touch(ui.gear)
	await touch(ui.buttons.reduced_effects)
	check(ui.game.settings.reduced_effects_enabled(),"native reduced setting")
	await capture("settings-reduced")
	await touch(ui.buttons.statistics)
	check(ui.screen=="statistics","native statistics button")
	await capture("statistics")
	await touch(ui.retention_view.export_button)
	check(ui.screen=="statistics_export","native export")
	await capture("statistics-export")
	await touch(ui.modal.get_child(3))
	check(DisplayServer.clipboard_get()==ui.statistics_export_text,"native copy JSON")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen=="settings","stats Back returns settings")
	ui.close_settings()
	await create_timer(.2).timeout
	ui.show_main_menu()
	await RenderingServer.frame_post_draw
	await process_frame
	var before: int=ui.main_menu.reaction.draw_count
	await measure("menu_reduced")
	check(before==ui.main_menu.reaction.draw_count,"reduced menu does zero repeated drawing")
	# Full campaign is a screenshot fixture, never an unlock shortcut in product.
	for id in range(1,51): ui.game.progress.complete(id,3)
	ui.show_themes()
	await capture("themes-unlocked")
	for id in ["neon","electric_blue","violet_pulse","emerald_circuit","solar_gold"]:
		if ui.screen!="themes": ui.show_themes()
		await touch(ui.retention_view.theme_buttons[id])
		check(ui.game.settings.theme_id()==id,"native theme "+id)
		ui.close_overlay()
		ui.game.select_level(49)
		await capture("theme-"+id)
		if id=="solar_gold": await measure("board_reduced")
	ui.show_achievements()
	for i in range(3): await touch(ui.retention_view.next_button)
	await touch(ui.retention_view.get_child(ui.retention_view.get_child_count()-1).get_child(0))
	check(ui.achievement_page==2,"native previous achievements page")
	await touch(ui.retention_view.next_button)
	await capture("achievements-complete")
	ui.show_main_menu()
	await capture("menu-complete")
	ui.selected_chapter=5
	ui.screen="chapters"
	ui.show_levels()
	await capture("levels-v")
	metrics["environment"]={"renderer":RenderingServer.get_video_adapter_name(),"resolution":prefix,"scope":"Linux debug llvmpipe; not mobile FPS, GPU or thermals"}
	var file:=FileAccess.open("res://docs/screenshots/v5-%s-performance.json"%prefix,FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t")+"\n")
	file.close()
	ui.queue_free()
	await create_timer(.3).timeout
	print("V5 visual/native %s: %d failures"%[prefix,failed])
	quit(1 if failed else 0)

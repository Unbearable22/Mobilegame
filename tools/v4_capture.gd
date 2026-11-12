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
	image.save_png("res://docs/screenshots/v4-%s-%s.png" % [prefix,label])
func measure(label: String,frames: int = 120) -> void:
	var time_sum: float = 0
	var draw_calls: float = 0
	var draw_usec: float = 0
	var began: int = Time.get_ticks_usec()
	var draws_before: int = ui.main_menu.reaction.draw_count
	for i in range(frames):
		await process_frame
		time_sum += Performance.get_monitor(Performance.TIME_PROCESS)*1000
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		draw_usec += ui.main_menu.reaction.last_draw_usec
	metrics[label] = {"cosmetic_draws_during_sample":ui.main_menu.reaction.draw_count-draws_before,"frames":frames,"process_ms_mean":time_sum/frames,"draw_calls_mean":draw_calls/frames,"cosmetic_draw_recording_usec_mean":draw_usec/frames,"elapsed_ms":(Time.get_ticks_usec()-began)/1000.0}
func run() -> void:
	prefix = "%dx%d" % [DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	ui = load("res://scenes/main.tscn").instantiate()
	ui.save_path = "user://v4-capture-%s.json" % prefix
	root.add_child(ui)
	ui.game.progress.data = Save.defaults()
	ui.game.select_level(0)
	ui.game.settings.set_sound(false)
	ui.show_main_menu()
	for i in range(8): await process_frame
	await capture("menu-fresh")
	var image_before: Image = root.get_texture().get_image()
	await create_timer(.7).timeout
	await RenderingServer.frame_post_draw
	var image_after: Image = root.get_texture().get_image()
	check(image_before.get_data() != image_after.get_data(),"rendered animation actually changes pixels")
	await measure("animated_menu")
	await touch(ui.info)
	check(ui.screen == "guide","menu info receives native touch")
	await capture("guide")
	var frozen: float = ui.main_menu.reaction.phase
	await create_timer(.1).timeout
	check(ui.main_menu.reaction.phase == frozen,"decoration stops behind guide")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "menu","guide Back restores menu")
	await touch(ui.gear)
	check(ui.screen == "settings","menu settings native touch")
	await capture("settings")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(.25).timeout
	check(ui.screen == "menu","settings Back restores menu")
	await touch(ui.main_menu.chapters_button)
	check(ui.screen == "chapters","menu chapters native touch")
	await capture("chapters")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await touch(ui.main_menu.continue_button)
	check(ui.screen == "game" and not ui.game.paused,"menu Continue native touch")
	await capture("game")
	var draws: int = ui.main_menu.reaction.draw_count
	await measure("static_game")
	check(draws == ui.main_menu.reaction.draw_count,"zero menu draw work during gameplay")
	# Explicit QA progress fixture; never a normal player startup path.
	for id in range(1,11): ui.game.progress.complete(id,2)
	ui.game.select_level(18)
	ui.show_main_menu()
	await capture("menu-partial")
	ui.close_overlay()
	ui.game.progress.data.unlocked_chapters = [1,2,3,4,5]
	for id in [19,49]:
		ui.game.select_level(id-1)
		await capture("level-%d" % id)
	for id in range(1,51): ui.game.progress.complete(id,3)
	ui.show_main_menu()
	await capture("menu-complete")
	metrics["environment"] = {"renderer":RenderingServer.get_video_adapter_name(),"resolution":prefix,"scope":"Linux debug software renderer; not mobile FPS or thermal measurements"}
	var file := FileAccess.open("res://docs/screenshots/v4-%s-performance.json" % prefix,FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t"))
	file.close()
	ui.queue_free()
	await create_timer(.3).timeout
	print("V4 visual/native %s: %d failures" % [prefix,failed])
	quit(1 if failed else 0)

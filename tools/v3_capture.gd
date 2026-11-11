extends SceneTree
var ui: Control
var prefix: String
var failed: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		push_error(label)
func touch(control: Control, local: Vector2 = Vector2(-1,-1)) -> void:
	var point: Vector2 = control.get_global_rect().get_center() if local.x < 0 else control.get_global_transform_with_canvas() * local
	point = root.get_screen_transform() * point
	for down in [true,false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func collect(node: Node, output: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Label or node is BaseButton: output.append(node)
	for child in node.get_children(): collect(child,output)
func capture(label: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var controls: Array = []
	collect(ui.modal if ui.overlay.visible else ui.margin,controls)
	if ui.gear.visible: controls.append(ui.gear)
	if ui.info.visible: controls.append(ui.info)
	for c in controls:
		check(ui.get_viewport_rect().encloses(c.get_global_rect()),"clipped %s in %s" % [c,label])
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == DisplayServer.window_get_size(),"actual pixels")
	image.save_png("res://docs/screenshots/v3-%s-%s.png" % [prefix,label])
func run() -> void:
	prefix = "%dx%d" % [DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	ui = load("res://scenes/main.tscn").instantiate()
	ui.save_path = "user://v3-visual-%s.json" % prefix
	root.add_child(ui)
	ui.game.progress.data = preload("res://scripts/core/save_manager.gd").defaults()
	ui.game.select_level(0)
	ui.show_main_menu()
	for i in range(8): await process_frame
	await capture("menu")
	await touch(ui.info)
	check(ui.screen == "guide","native info")
	await capture("guide")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(ui.screen == "menu","guide Back")
	ui.show_chapters()
	await capture("chapters-locked")
	# QA fixture only: completed campaign, never changes normal unlock rules.
	for id in range(1,51): ui.game.progress.complete(id,3)
	ui.screen = "chapters"
	ui.show_chapters()
	await capture("chapters-complete")
	ui.selected_chapter = 5
	ui.show_levels()
	await capture("levels-v")
	ui.close_overlay()
	ui.game.select_level(49)
	await capture("game")
	check(not ui.hint_label.visible,"no permanent hints")
	check(ui.board.geometry().extent.x >= 950,"near full-width puzzle")
	check(ui.board.get_global_rect().size.y >= 1200,"increased puzzle space")
	ui.game.select_level(2)
	await touch(ui.board,ui.board.center(1))
	check(ui.game.grid.state.rotations[1] == 1,"native scaled node tap")
	await touch(ui.gear)
	check(ui.screen == "settings","native gear")
	await capture("settings")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(0.3).timeout
	check(ui.screen == "game","settings Back")
	ui.game.select_level(0)
	ui.game.frame_seconds = 0.06
	ui.game.tap(0)
	ui.info.pressed.emit()
	await create_timer(0.15).timeout
	check(ui.game.busy,"guide freezes reaction")
	ui.back_overlay()
	while ui.game.busy: await process_frame
	await capture("victory")
	ui.close_overlay()
	ui.game.select_level(2)
	ui.game.tap(0)
	while ui.game.busy: await process_frame
	await capture("loss")
	ui.game.settings.set_sound(false)
	ui.queue_free()
	await create_timer(0.3).timeout
	print("V3 visual/native %s: %d failures" % [prefix,failed])
	quit(1 if failed else 0)

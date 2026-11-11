extends SceneTree
var ui: Control
var failed: int = 0
var prefix: String
func _initialize() -> void: call_deferred("run")
func touch(control: Control, local: Vector2 = Vector2(-1,-1)) -> void:
	var position: Vector2 = control.get_global_rect().get_center() if local.x < 0 else control.get_global_transform_with_canvas() * local
	position = root.get_screen_transform() * position
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = position
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func check(ok: bool, why: String) -> void:
	if not ok:
		failed += 1
		push_error(why)
func capture(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == DisplayServer.window_get_size(), "exact screen dimensions")
	image.save_png("res://docs/screenshots/settings-%s-%s.png" % [prefix,label])
	var controls: Array = []
	collect(ui.modal if ui.overlay.visible else ui.margin, controls)
	for control in controls:
		check(ui.get_viewport_rect().encloses(control.get_global_rect()), "clipped " + str(control))
	if ui.gear.visible:
		check(ui.get_viewport_rect().encloses(ui.gear.get_global_rect()), "gear clipped")
		if ui.margin.visible: check(not ui.gear.get_global_rect().intersects(ui.stars_label.get_global_rect()), "gear overlaps score")
func collect(node: Node, controls: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Label or node is BaseButton: controls.append(node)
	for child in node.get_children(): collect(child, controls)
func run() -> void:
	prefix = "%dx%d" % [DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	ui = load("res://scenes/main.tscn").instantiate()
	ui.save_path = "user://settings-capture-%s.json" % prefix
	root.add_child(ui)
	for i in range(6): await process_frame
	await capture("menu")
	await touch(ui.gear)
	check(ui.screen == "settings", "native menu gear")
	await capture("panel")
	var old: bool = ui.game.settings.sound_enabled()
	await touch(ui.modal.get_child(2))
	check(ui.game.settings.sound_enabled() != old, "native effects toggle")
	ui.game.settings.set_touch_diagnostics(true)
	await touch(ui.modal.get_child(ui.modal.get_child_count()-1))
	await create_timer(0.3).timeout
	check(ui.screen == "menu", "native close returns menu")
	await touch(ui.modal.get_child(2))
	ui.game.select_level(2)
	await capture("game")
	await touch(ui.board,ui.board.center(1))
	check(ui.game.grid.state.rotations[1] == 1, "native scaled touch rotation")
	await capture("rotation")
	await touch(ui.gear)
	check(ui.screen == "settings" and ui.game.paused, "native game gear pauses")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(0.3).timeout
	check(ui.screen == "game" and not ui.game.paused, "Back resumes")
	ui.game.settings.set_sound(false)
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Settings visual/native %s: %d failures" % [prefix,failed])
	quit(1 if failed else 0)

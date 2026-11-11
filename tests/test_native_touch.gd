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
func touch(point: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func run() -> void:
	var ui := Main.instantiate()
	ui.start_in_menu = false
	ui.save_path = "user://test-native-touch.json"
	root.add_child(ui)
	for frame in range(3): await process_frame
	for resolution in [Vector2i(720,1280), Vector2i(1080,1920), Vector2i(1440,3200)]:
		root.size = resolution
		for frame in range(4): await process_frame
		ui.game.select_level(2)
		var point: Vector2 = root.get_screen_transform() * (ui.board.get_global_transform_with_canvas() * ui.board.center(1))
		for i in range(4):
			await touch(point)
			check(ui.game.grid.state.rotations[1] == (i + 1) % 4, "native once/90deg %s tap%d" % [resolution,i])
		check(ui.game.grid.used == 0, "rotation does not spend launch")
		# Mouse-only GUI stream is the route ordinary Android buttons already use.
		for down in [true, false]:
			var mouse := InputEventMouseButton.new()
			mouse.device = InputEvent.DEVICE_ID_EMULATION
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = down
			mouse.position = ui.board.global_position + ui.board.center(1)
			root.push_input(mouse, true)
			await process_frame
		check(ui.game.grid.state.rotations[1] == 1, "emulated mouse-only route rotates once")
		ui.game.undo()
		check(ui.game.grid.state.rotations[1] == 0, "undo restores touch rotation")
		var history_size: int = ui.game.grid.history.size()
		await touch(root.get_screen_transform() * (ui.board.global_position + Vector2(4,4)))
		check(ui.game.grid.history.size() == history_size, "outside node produces no action")
		await touch(root.get_screen_transform() * (ui.board.global_position + ui.board.center(3)))
		check(ui.game.grid.history.size() == history_size, "target does not rotate")
		await touch(root.get_screen_transform() * (ui.board.global_position + ui.board.center(2)))
		check(ui.game.grid.history.size() == history_size, "normal does not rotate")
		await touch(point)
		ui.game.restart()
		check(ui.game.grid.state.rotations[1] == 0, "restart resets")
		# Correct three clockwise turns send the pulse up to the goal.
		for i in range(3): await touch(point)
		ui.game.frame_seconds = 0.12
		await touch(root.get_screen_transform() * (ui.board.global_position + ui.board.center(0)))
		check(ui.game.grid.used == 1, "source touch launches")
		check(ui.game.busy, "touch test reached active animation")
		var rotations: int = ui.game.grid.state.rotations[1]
		await touch(point)
		check(ui.game.grid.state.rotations[1] == rotations, "busy touch cannot rotate")
		while ui.game.busy: await process_frame
		check(ui.game.grid.status() == "won", "visual direction matches real route")
		ui.close_overlay()
		ui.game.select_level(5)
		ui.game.tap(0)
		while ui.game.busy: await process_frame
		check(not ui.game.grid.rotate(1), "post-launch rotation remains forbidden")
		ui.game.select_level(8)
		point = root.get_screen_transform() * (ui.board.global_position + ui.board.center(1))
		await touch(point)
		check(ui.game.grid.state.rotations[1] == 1, "splitter rotates")
		ui.show_pause()
		await touch(point)
		check(ui.game.grid.state.rotations[1] == 1, "modal blocks background touch")
		ui.close_overlay()
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Native touch: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

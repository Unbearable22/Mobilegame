extends SceneTree
const Main = preload("res://scenes/main.tscn")
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var ui := Main.instantiate()
	ui.start_in_menu = false
	ui.save_path = "user://test_input-progress.json"
	root.add_child(ui)
	await process_frame
	ui.game.select_level(2)
	check(not quit_on_go_back, "Android Back must not automatically quit")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = ui.board.center(1)
	ui.board._gui_input(touch)
	check(ui.game.grid.state.rotations[1] == 1, "touch rotates once")
	var dispatched := InputEventScreenTouch.new()
	dispatched.pressed = true
	dispatched.index = 1
	dispatched.position = ui.board.global_position + ui.board.center(1)
	root.push_input(dispatched, true)
	await process_frame
	check(ui.game.grid.state.rotations[1] == 2, "viewport dispatch reaches board")
	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = ui.board.center(1)
	ui.board._gui_input(mouse)
	check(ui.game.grid.state.rotations[1] == 2, "emulated mouse not double applied")
	ui.game.select_level(0)
	ui.game.frame_seconds = 0.3
	ui.game.tap(0)
	ui.show_pause()
	var visual: float = ui.board.animation
	await create_timer(0.04).timeout
	check(ui.game.busy and ui.board.animation == visual, "pause freezes reaction visuals")
	ui.close_overlay()
	check(ui.board.tween.is_running(), "all resume routes resume visual tween")
	await create_timer(0.04).timeout
	ui.game.restart()
	await create_timer(0.02).timeout
	check(ui.board.tween == null or not ui.board.tween.is_running(), "restart stops old tween")
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Input: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Validator = preload("res://scripts/core/level_validator.gd")
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func wait_idle(game: Node) -> void:
	var timeout: int = 0
	while game.busy and timeout < 600:
		await process_frame
		timeout += 1
	check(not game.busy, "animation finishes within frame budget")
func run() -> void:
	var ui := Main.instantiate()
	ui.start_in_menu = false
	ui.save_path = "user://test_ui-progress.json"
	root.add_child(ui)
	await process_frame
	var game: Node = ui.game
	game.frame_seconds = 0.001
	check(game.levels.size() == 10, "UI loads ten levels")
	ui.buttons["levels"].pressed.emit()
	check(ui.overlay.visible, "level selector button opens")
	ui.close_overlay()
	game.select_level(0)
	ui.buttons["pause"].pressed.emit()
	check(game.paused and ui.overlay.visible, "pause button freezes game")
	game.tap(0)
	check(game.grid.used == 0, "paused taps ignored")
	ui.close_overlay()
	check(not game.paused, "resume unpauses")
	for id in range(10):
		game.select_level(id)
		var solution: Dictionary = Validator.new().solve(game.grid.level)
		for action in solution.actions:
			game.tap(action.index)
			if action.type == "launch": await wait_idle(game)
		check(game.grid.status() == "won", "UI can win level %d" % (id + 1))
		check(ui.overlay.visible, "win dialog level %d" % (id + 1))
		ui.close_overlay()
	game.select_level(0)
	game.tap(0)
	await wait_idle(game)
	(ui.modal.get_child(2) as Button).pressed.emit()
	check(game.current == 1 and not ui.overlay.visible, "next level button advances")
	game.select_level(0)
	game.tap(0)
	ui.buttons["restart"].pressed.emit()
	await create_timer(0.05).timeout
	check(game.grid.used == 0 and game.grid.status() == "playing", "restart cancels stale animation")
	game.select_level(2)
	game.tap(1)
	ui.buttons["undo"].pressed.emit()
	check(game.grid.state.rotations[1] == 0, "undo button restores orientation")
	var sound: bool = game.progress.data.sound
	ui.toggle_sound()
	check(game.progress.data.sound != sound, "sound button persists setting")
	ui.toggle_sound()
	for viewport_size in [Vector2i(360, 640), Vector2i(390, 844), Vector2i(768, 1024)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		var view: Rect2 = ui.get_viewport_rect()
		check(view.encloses(ui.board.get_global_rect()), "board inside viewport at %s" % viewport_size)
		check(view.encloses(ui.buttons["sound"].get_global_rect()), "toolbar inside viewport at %s" % viewport_size)
	ui.sound_player.stop()
	ui.queue_free()
	await create_timer(0.3).timeout
	print("UI: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

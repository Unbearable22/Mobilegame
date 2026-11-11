extends SceneTree
const Main = preload("res://scenes/main.tscn")
const Validator = preload("res://scripts/core/level_validator.gd")
var ui: Control
var failed: int = 0
var prefix: String
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error(message)
func settle() -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	await create_timer(0.3).timeout
	await settle()
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == DisplayServer.window_get_size(), "actual screenshot pixels match window")
	check(image.save_png("res://docs/screenshots/%s-%s.png" % [prefix, label]) == OK, "screenshot written")
	var visible_controls: Array = []
	collect_controls(ui.modal if ui.overlay.visible else ui.margin, visible_controls)
	var viewport: Rect2 = ui.get_viewport_rect()
	for control in visible_controls:
		check(viewport.encloses(control.get_global_rect()), "%s clipped: %s" % [label, control])
		if control is Button:
			check(control.size.y >= 144, "%s button target too small" % label)
	print("CAPTURE %s %s: %s" % [prefix, label, image.get_size()])
func collect_controls(node: Node, result: Array) -> void:
	if node is Control and not node.is_visible_in_tree(): return
	if node is Button or node is Label: result.append(node)
	for child in node.get_children(): collect_controls(child, result)
func idle() -> void:
	var elapsed: float = 0.0
	while ui.game.busy and elapsed < 10.0:
		await process_frame
		elapsed += ui.get_process_delta_time()
	check(not ui.game.busy, "reaction timeout")
func run() -> void:
	prefix = "%dx%d" % [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
	ui = Main.instantiate()
	ui.save_path = "user://visual-acceptance-%s.json" % prefix
	root.add_child(ui)
	ui.game.progress.data = preload("res://scripts/core/save_manager.gd").defaults()
	ui.game.select_level(0)
	ui.show_main_menu()
	await capture("menu")
	ui.close_overlay()
	ui.game.select_level(9)
	if OS.get_cmdline_user_args().has("menus-only"):
		ui.show_levels()
		await capture("levels")
		ui.queue_free()
		await create_timer(0.3).timeout
		quit(1 if failed else 0)
		return
	await capture("gameplay")
	ui.show_pause()
	await capture("pause")
	ui.close_overlay()
	ui.show_levels()
	await capture("levels")
	ui.close_overlay()
	ui.game.select_level(2)
	ui.game.frame_seconds = 0.05
	ui.game.tap(0)
	await idle()
	check(ui.game.grid.status() == "lost", "real loss reached")
	await capture("loss")
	ui.close_overlay()
	for id in range(10):
		ui.game.select_level(id)
		var solution: Dictionary = Validator.new().solve(ui.game.grid.level)
		check(solution.solved, "level solvable")
		for action in solution.actions:
			ui.game.tap(action.index)
			if action.type == "launch": await idle()
		check(ui.game.grid.status() == "won", "level %d played through scene" % (id + 1))
		print("PLAYED %s level %02d: %d actions" % [prefix, id + 1, solution.actions.size()])
		if id == 9: await capture("victory")
		ui.close_overlay()
	ui.game.select_level(6)
	ui.game.frame_seconds = 0.25
	ui.game.tap(0)
	await create_timer(0.6).timeout
	ui.show_pause()
	ui.overlay.hide()
	# Preserve an in-flight wave for repeatable visual inspection.
	await capture("reaction-paused")
	ui.sound_player.stop()
	ui.queue_free()
	await create_timer(0.3).timeout
	print("VISUAL ACCEPTANCE %s: %d failures" % [prefix, failed])
	quit(1 if failed else 0)

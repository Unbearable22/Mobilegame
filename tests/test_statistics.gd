extends SceneTree
const Game = preload("res://scripts/core/game_manager.gd")
const Save = preload("res://scripts/core/save_manager.gd")
const Stats = preload("res://scripts/core/statistics_manager.gd")
var failed: int = 0
var passed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func row(game: Node, id: int) -> Dictionary:
	return game.statistics.summary().levels.get(str(id),Stats.empty_level())
func run() -> void:
	var path: String = "user://test-statistics.json"
	DirAccess.remove_absolute(path)
	var game := Game.new(path)
	root.add_child(game)
	game.set_process(false)
	game.frame_seconds = 0.0
	check(game.statistics.summary().levels.is_empty() and game.statistics.summary().last_played_level == 0, "startup selection creates no played attempt")
	game.select_level(2)
	game.select_level(0)
	game._process(100)
	check(game.statistics.summary().levels.is_empty(), "navigation and idle untouched board create no attempts or time")
	game.restart()
	check(row(game,1).restarts == 1 and row(game,1).attempts == 0 and game.statistics.summary().last_played_level == 0, "empty restart counted independently without played attempt")
	game.tap(-1)
	game.tap(1)
	check(row(game,1).attempts == 0, "rejected and inspect actions excluded")
	game.frame_seconds = 0.02
	game.tap(0)
	game._process(2.0)
	game.paused = true
	game._process(100.0)
	game.flush_statistics()
	check(row(game,1).attempts == 1 and row(game,1).launches == 1 and row(game,1).active_seconds == 2.0, "accepted launch starts attempt and includes animation while excluding paused time")
	check(Save.new(path).read().statistics.levels["1"].active_seconds == 2.0, "pause flush persists active duration")
	game.paused = false
	while game.busy: await process_frame
	check(row(game,1).wins == 1 and row(game,1).best_stars == 3 and row(game,1).best_launches == 1 and row(game,1).best_seconds == 2.0, "win tracks best result and duration")
	game._process(100)
	check(row(game,1).active_seconds == 2.0, "terminal screen time excluded")
	game.undo()
	game._process(3)
	game.frame_seconds = 0.0
	game.tap(0)
	check(row(game,1).attempts == 1 and row(game,1).wins == 1 and row(game,1).launches == 2 and row(game,1).undos == 1 and row(game,1).active_seconds == 5.0, "Undo then rewin continues real work without inflating attempts or outcome")
	game.restart()
	game.tap(0)
	check(row(game,1).attempts == 2 and row(game,1).wins == 2 and row(game,1).best_seconds == 0.0, "restart arms new attempt with independently minimal best win time")
	game.select_level(2)
	game.tap(0)
	check(row(game,3).losses == 1, "terminal loss records once")
	game.undo()
	game.tap(0)
	check(row(game,3).attempts == 1 and row(game,3).losses == 1 and row(game,3).launches == 2, "Undo after loss resumes same attempt and preserves first outcome")
	game.select_level(9)
	var rotatable: int = -1
	for i in range(game.grid.level.nodes.size()):
		if game.grid.level.nodes[i].get("rotatable",false): rotatable = i
	check(rotatable >= 0, "fixture offers accepted rotation")
	game.tap(rotatable)
	game._process(4.0)
	check(row(game,10).attempts == 1 and row(game,10).rotations == 1 and row(game,10).active_seconds == 4.0, "rotation starts played attempt and counts thinking time")
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._process(100)
	check(row(game,10).active_seconds == 4.0, "foreground focus loss excludes active time")
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	game._process(100)
	check(row(game,10).active_seconds == 4.0 and Save.new(path).read().statistics.last_played_level == 10, "background excludes time and flushes actual played level")
	game.paused = false
	game.select_level(0)
	game.frame_seconds = 0.05
	game.tap(0)
	game.restart()
	var prior_wins: int = row(game,1).wins
	await create_timer(0.2).timeout
	check(not game.busy and game.grid.used == 0 and row(game,1).wins == prior_wins, "restart cancels stale animation without recording stale outcome")
	game.flush_statistics()
	var before: Dictionary = game.statistics.summary()
	game.queue_free()
	await process_frame
	game = Game.new(path)
	root.add_child(game)
	game.set_process(false)
	check(game.statistics.summary() == before, "aggregate statistics survive recreation without phantom attempts")
	var export_path: String = "user://chain-statistics-test.json"
	check(game.statistics.export_json(export_path) == OK and game.statistics.last_export_path == export_path, "atomic local export succeeds")
	var exported := FileAccess.open(export_path,FileAccess.READ)
	check(JSON.parse_string(exported.get_as_text()) == JSON.parse_string(JSON.stringify(before)), "export JSON matches sanitized aggregate only")
	exported.close()
	check(not FileAccess.file_exists(export_path+".tmp"), "export rename leaves no temporary file")
	check(game.statistics.export_json("user://missing-statistics-dir/export.json") != OK, "unwritable export returns concrete error")
	var bests := Stats.new(game.progress)
	bests.select(2)
	bests.action("launches")
	bests.tick(6.0)
	bests.finish(true,2,3)
	bests.undo()
	bests.action("launches")
	bests.tick(4.0)
	bests.finish(true,3,2)
	var improved: Dictionary = bests.summary().levels["2"]
	check(improved.wins == 1 and improved.best_stars == 3 and improved.best_launches == 2 and improved.best_seconds == 6.0, "Undo rewin improves best result without duplicate outcome")
	game.queue_free()
	await process_frame
	print("Statistics: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)

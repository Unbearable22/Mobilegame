extends SceneTree
## Integration regression: real GameManager taps, signals, Undo, Restart and wave snapshots.
const Game = preload("res://scripts/core/game_manager.gd")
const Model = preload("res://scripts/core/reaction_engine.gd")
const Grid = preload("res://scripts/core/grid_manager.gd")
const Validator = preload("res://scripts/core/level_validator.gd")
const Diagnostics = preload("res://tools/diagnose_levels.gd")
var passed: int = 0
var failed: int = 0
var game: Node
var frames: Array = []
var results: Array = []
var save_path: String = "user://test-v4-level-regressions.json"

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	var deadline: int = Time.get_ticks_msec() + 5000
	while game.busy and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not game.busy, "reaction finishes within five seconds")

func run() -> void:
	game = Game.new(save_path)
	root.add_child(game)
	await process_frame
	game.frame_seconds = 0.001
	game.progress.data.unlocked_chapters = [1, 2, 3, 4, 5]
	game.reaction_frame.connect(func(frame: Dictionary): frames.append(frame.duplicate(true)))
	game.finished.connect(func(won: bool, stars: int): results.append([won, stars]))
	check(game.levels.size() == 50, "campaign remains fifty levels")
	for id in [19, 49]:
		await check_level(id)
	game.queue_free()
	await process_frame
	for suffix in ["", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	print("Level regressions: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func check_level(id: int) -> void:
	game.select_level(id - 1)
	var level: Dictionary = game.grid.level.duplicate(true)
	var initial: Dictionary = game.grid.state.duplicate(true)
	results.clear()
	var before_actions: Array = []
	var launch_number: int = 0
	for action in level.author_solution:
		before_actions.append({"state": game.grid.state.duplicate(true), "used": game.grid.used})
		frames.clear()
		game.tap(int(action.index))
		if action.type == "launch":
			launch_number += 1
			check(game.busy, "%d launch %d uses async GameManager" % [id, launch_number])
			var during: Dictionary = game.grid.state.duplicate(true)
			var used: int = game.grid.used
			game.undo()
			game.tap(int(action.index))
			check(game.grid.state == during and game.grid.used == used, "busy input and Undo cannot add or remove a launch")
		await settle()
		if action.type == "rotate":
			check(int(game.grid.state.rotations[int(action.index)]) == 1 and game.grid.used == 0, "author rotation is clockwise before launches")
		else:
			check_wave_edges(level)
			check_launch(id, launch_number)
	check(game.grid.status() == "won", "%d author solution wins" % id)
	check(results == [[true, 3]], "%d GameManager awards three stars once" % id)
	check(int(game.progress.data.completed[str(id)]) == 3, "%d three stars saved" % id)
	for i in range(level.nodes.size()):
		check(bool(game.grid.state.active[i]) == (level.nodes[i].type != "blocker"), "%d important node %d activation" % [id, i])
	# Undo every action: charging, target activation, used launches and rotations must all rewind.
	for i in range(before_actions.size() - 1, -1, -1):
		game.undo()
		check(game.grid.state == before_actions[i].state and game.grid.used == before_actions[i].used,
			"%d Undo restores exact state before action %d" % [id, i + 1])
	check(game.grid.state == initial and game.grid.history.is_empty(), "%d full Undo restores initial board" % id)
	# Replay after full Undo, then undo and replay just the last launch.
	for action in level.author_solution:
		game.tap(int(action.index))
		await settle()
	game.undo()
	check(game.grid.status() == "playing" and game.grid.used == int(level.par_launches) - 1, "%d Undo final win returns to playing" % id)
	game.tap(int(level.author_solution[-1].index))
	await settle()
	check(game.grid.status() == "won" and results[-1] == [true, 3], "%d final launch after Undo earns three stars" % id)
	game.restart()
	check(game.grid.state == initial and game.grid.used == 0 and game.grid.history.is_empty(), "%d Restart clears all gameplay state" % id)
	# Restart while a reaction is awaiting frames must invalidate the old coroutine.
	for action in level.author_solution:
		game.tap(int(action.index))
		if action.type == "launch": break
	var result_count: int = results.size()
	game.restart()
	await process_frame
	await process_frame
	check(not game.busy and game.grid.state == initial and game.grid.used == 0 and results.size() == result_count,
		"%d Restart cancels pending reaction without stale win" % id)
	for action in level.author_solution:
		game.tap(int(action.index))
		await settle()
	check(game.grid.status() == "won" and results[-1] == [true, 3], "%d fresh author replay after Restart wins three stars" % id)
	check_search(level)

func check_wave_edges(level: Dictionary) -> void:
	for frame in frames:
		for edge in frame.edges:
			var source: Dictionary = level.nodes[int(edge.from)]
			var destination: Dictionary = level.nodes[int(edge.to)]
			var delta := Vector2i(int(destination.x - source.x), int(destination.y - source.y))
			var direction: int = Model.DIRECTIONS.find(delta)
			check(direction >= 0, "every wave edge joins orthogonally adjacent visible nodes")
			check(direction in Diagnostics.directions(level, frame.state, int(edge.from)), "every wave follows the shown rotated exit")
			check(source.type != "blocker" and source.type != "target", "blockers and targets never forward energy")

func check_launch(id: int, number: int) -> void:
	var active_targets: Array = []
	var new_target_order: Array = []
	var previous: Dictionary = frames[0].state
	for frame in frames:
		var new_targets: Array = []
		for index in range(game.grid.level.nodes.size()):
			if game.grid.level.nodes[index].type == "target" and frame.state.active[index] and not previous.active[index]:
				new_targets.append(index)
		if not new_targets.is_empty(): new_target_order.append(new_targets)
		previous = frame.state
	for index in range(game.grid.level.nodes.size()):
		if game.grid.level.nodes[index].type == "target" and game.grid.state.active[index]: active_targets.append(index)
	if id == 19:
		check(active_targets == ([2, 9, 10] if number == 1 else [2, 5, 9, 10]), "19 independent source branch and shared targets")
		check(new_target_order == ([[2], [9, 10]] if number == 1 else [[5]]), "19 target order per launch")
		var shared_edges: Array = frames[-1].edges
		check(shared_edges == [{"from": 8, "to": 9}, {"from": 8, "to": 10}], "19 shared splitter sends up and down in both launches")
	else:
		var charges: Array = game.grid.state.charges
		check([charges[6], charges[9]] == [[1, 0], [2, 1], [2, 2]][number - 1], "49 batteries charge in launch order")
		check(active_targets == [[], [0, 3, 15], [0, 1, 3, 15]][number - 1], "49 upper targets, lower bypass, then far target")
		check(new_target_order == [[], [[0, 3], [15]], [[1]]][number - 1], "49 wave target activation order")
		check(not game.grid.state.active[11], "49 lower blocker stays inactive")
		if number == 2:
			check(not game.grid.state.active[9] and not game.grid.state.active[4], "49 far battery cannot emit on one charge")
			check(game.grid.state.active[12] and game.grid.state.active[13] and game.grid.state.active[14], "49 lower bypass traverses fixed elbow and normal node")
			check(frames[4].state.charges[9] == 1 and frames[1].state.charges[6] == 2, "49 battery thresholds occur at expected waves")

func check_search(level: Dictionary) -> void:
	var id: int = int(level.id)
	var alternatives: Dictionary = Diagnostics.exhaustive_alternatives(level)
	check(alternatives.orientation_count == (64 if id == 19 else 1024), "%d all orientations enumerated" % id)
	check(alternatives.simulations == (384 if id == 19 else 3072), "%d all source sequences enumerated" % id)
	check(alternatives.minimum_launches == int(level.par_launches), "%d no shorter bypass" % id)
	check(alternatives.winning_paths.size() == (4 if id == 19 else 1), "%d only justified alternatives" % id)
	check(alternatives.all_wins_require_all_non_blockers_active, "%d every winning path uses every important node" % id)
	for budget in range(1, int(level.launches) + 1):
		var candidate: Dictionary = level.duplicate(true)
		candidate.launches = budget
		candidate.par_launches = budget
		var solution: Dictionary = Validator.new().solve(candidate)
		check(solution.solved == (budget == int(level.launches)) and solution.error.is_empty(), "%d existing solver minimum at %d launches" % [id, budget])
	# Deliberately leave each required rotatable unchanged: no author shortcut may win.
	for index in range(level.nodes.size()):
		if not level.nodes[index].get("rotatable", false): continue
		var grid := Grid.new()
		grid.load_level(level)
		for action in level.author_solution:
			if action.type == "rotate":
				if int(action.index) != index: grid.rotate(int(action.index))
			else: grid.launch(int(action.index))
		check(grid.status() == "lost", "%d required rotation %d cannot be omitted" % [id, index])

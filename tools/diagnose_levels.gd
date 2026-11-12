extends SceneTree
## Reproducible offline report. Runs real asynchronous GameManager and exhaustive model audit.
const Game = preload("res://scripts/core/game_manager.gd")
const Model = preload("res://scripts/core/reaction_engine.gd")
const Validator = preload("res://scripts/core/level_validator.gd")
const Auditor = preload("res://scripts/core/level_auditor.gd")
var reports: Array = []
var observed_frames: Array = []
var observed_results: Array = []

func _initialize() -> void:
	call_deferred("run")

static func snapshot(game: Node) -> Dictionary:
	return {"state": game.grid.state.duplicate(true), "used": game.grid.used,
		"status": game.grid.status(), "busy": game.busy, "history_size": game.grid.history.size()}

static func directions(level: Dictionary, state: Dictionary, index: int) -> Array:
	var node: Dictionary = level.nodes[index]
	var exits: Array = [0, 1, 2, 3] if node.type in ["normal", "battery"] else node.get("dirs", [])
	var result: Array = []
	for direction in exits:
		result.append((int(direction) + int(state.rotations[index])) % 4)
	return result

static func describe_frame(level: Dictionary, frame: Dictionary, before: Dictionary) -> Dictionary:
	var result: Dictionary = frame.duplicate(true)
	var names: Array = ["up", "right", "down", "left"]
	for edge in result.edges:
		var a: Dictionary = level.nodes[int(edge.from)]
		var b: Dictionary = level.nodes[int(edge.to)]
		var delta := Vector2i(int(b.x - a.x), int(b.y - a.y))
		var direction: int = Model.DIRECTIONS.find(delta)
		edge.direction = names[direction] if direction >= 0 else "invalid"
		edge.legal = direction >= 0 and direction in directions(level, frame.state, int(edge.from))
	result.new_targets = []
	result.battery_changes = []
	for i in range(level.nodes.size()):
		if level.nodes[i].type == "target" and frame.state.active[i] and not before.active[i]:
			result.new_targets.append(i)
		if level.nodes[i].type == "battery" and frame.state.charges[i] != before.charges[i]:
			result.battery_changes.append({"index": i, "before": before.charges[i], "after": frame.state.charges[i]})
	return result

func run() -> void:
	var game := Game.new("user://v4-level-diagnostics.json")
	root.add_child(game)
	await process_frame
	game.frame_seconds = 0.001
	game.progress.data.unlocked_chapters = [1, 2, 3, 4, 5]
	game.reaction_frame.connect(func(frame: Dictionary): observed_frames.append(frame.duplicate(true)))
	game.finished.connect(func(won: bool, stars: int): observed_results.append({"won": won, "stars": stars}))
	var failed: bool = game.levels.size() != 50
	for id in [19, 49]:
		game.select_level(id - 1)
		var level: Dictionary = game.grid.level.duplicate(true)
		var report: Dictionary = {"id": id, "name": level.name, "objective": level.objective,
			"nodes": level.nodes, "initial": snapshot(game), "actions": [], "finish": []}
		observed_results.clear()
		for action in level.author_solution:
			var before: Dictionary = game.grid.state.duplicate(true)
			observed_frames.clear()
			game.tap(int(action.index))
			var deadline: int = Time.get_ticks_msec() + 5000
			while game.busy and Time.get_ticks_msec() < deadline:
				await process_frame
			var frames: Array = []
			for frame in observed_frames:
				frames.append(describe_frame(level, frame, before))
				before = frame.state
			var entry: Dictionary = {"action": action, "after": snapshot(game), "frames": frames}
			report.actions.append(entry)
			if game.busy: failed = true
		report.finish = observed_results.duplicate(true)
		report.solver_first = Validator.new().solve(level)
		report.solver_by_launch_budget = []
		for budget in range(1, int(level.launches) + 1):
			var candidate: Dictionary = level.duplicate(true)
			candidate.launches = budget
			candidate.par_launches = budget
			var solved: Dictionary = Validator.new().solve(candidate)
			solved.budget = budget
			report.solver_by_launch_budget.append(solved)
		report.existing_exhaustive_audit = Auditor.new().audit(level)
		report.alternatives = exhaustive_alternatives(level)
		failed = failed or game.grid.status() != "won" or not report.existing_exhaustive_audit.valid
		reports.append(report)
		print("LEVEL %d: %s; exhaustive %s" % [id, report.finish, report.alternatives])
	var file := FileAccess.open("res://docs/v4-level-diagnostics.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "physical_android_tested": false,
			"node_indexing": "zero based; coordinates x,y; directions 0 up,1 right,2 down,3 left", "levels": reports}, "\t"))
	else:
		failed = true
	game.queue_free()
	await process_frame
	for suffix in ["", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://v4-level-diagnostics.json" + suffix))
	quit(1 if failed else 0)

static func exhaustive_alternatives(level: Dictionary) -> Dictionary:
	var rotatable: Array = []
	var sources: Array = []
	for i in range(level.nodes.size()):
		if level.nodes[i].get("rotatable", false): rotatable.append(i)
		if level.nodes[i].type == "source": sources.append(i)
	var ctx: Dictionary = {"orientation_count": 0, "simulations": 0, "winning_paths": [], "minimum_launches": 999,
		"winning_rotation_values": {}, "winning_source_sequences": {}, "all_wins_require_all_non_blockers_active": true}
	for index in rotatable: ctx.winning_rotation_values[str(index)] = []
	_enumerate_rotations(level, Model.initial_state(level), rotatable, sources, 0, ctx)
	return ctx

static func _enumerate_rotations(level: Dictionary, state: Dictionary, rotatable: Array, sources: Array, cursor: int, ctx: Dictionary) -> void:
	if cursor == rotatable.size():
		ctx.orientation_count += 1
		_enumerate_launches(level, state, sources, [], rotatable, ctx)
		return
	for rotation in range(4):
		state.rotations[rotatable[cursor]] = rotation
		_enumerate_rotations(level, state, rotatable, sources, cursor + 1, ctx)

static func _enumerate_launches(level: Dictionary, state: Dictionary, sources: Array, sequence: Array, rotatable: Array, ctx: Dictionary) -> void:
	if Model.has_won(level, state):
		ctx.minimum_launches = mini(ctx.minimum_launches, sequence.size())
		var rotations: Dictionary = {}
		for index in rotatable:
			rotations[str(index)] = state.rotations[index]
			if not state.rotations[index] in ctx.winning_rotation_values[str(index)]:
				ctx.winning_rotation_values[str(index)].append(state.rotations[index])
		ctx.winning_paths.append({"rotations": rotations, "sources": sequence.duplicate()})
		ctx.winning_source_sequences[JSON.stringify(sequence)] = true
		for i in range(level.nodes.size()):
			if level.nodes[i].type != "blocker" and not state.active[i]:
				ctx.all_wins_require_all_non_blockers_active = false
		return
	if sequence.size() >= int(level.launches): return
	for source in sources:
		ctx.simulations += 1
		var result: Dictionary = Model.new().simulate(level, state, int(source))
		var next_sequence: Array = sequence.duplicate()
		next_sequence.append(source)
		_enumerate_launches(level, result.state, sources, next_sequence, rotatable, ctx)

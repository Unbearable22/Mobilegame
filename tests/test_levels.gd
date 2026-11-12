extends SceneTree
const Loader = preload("res://scripts/core/level_loader.gd")
const Validator = preload("res://scripts/core/level_validator.gd")
const Grid = preload("res://scripts/core/grid_manager.gd")
var failed: int = 0
var passed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void:
	var levels: Array = Loader.new().load_all()
	check(levels.size() == 100, "hundred levels loaded")
	for data in levels:
		var report: Dictionary = Validator.new().validate(data)
		check(report.valid, "schema %s: %s" % [data.id, report.get("error", "")])
		var solution: Dictionary = Validator.new().solve(data)
		check(solution.solved, "level %s has solution" % data.id)
		var grid := Grid.new()
		grid.load_level(data)
		for action in solution.get("actions", []):
			if action.type == "rotate": grid.rotate(action.index)
			else: grid.launch(action.index)
		check(grid.status() == "won", "solution replays level %s" % data.id)
		print("Level %02d: solution %s (%d states)" % [int(data.id), solution.get("actions", []), solution.get("visited", 0)])
	var bad: Dictionary = levels[0].duplicate(true)
	bad.nodes.append(bad.nodes[0].duplicate(true))
	check(not Validator.new().validate(bad).valid, "duplicate cells rejected")
	bad = levels[0].duplicate(true)
	bad.nodes[0].x = -1
	check(not Validator.new().validate(bad).valid, "outside grid rejected")
	bad = levels[0].duplicate(true)
	bad.nodes[0].dirs = [9]
	check(not Validator.new().validate(bad).valid, "invalid directions rejected")
	bad = levels[0].duplicate(true)
	bad.nodes[0].type = "mystery"
	check(not Validator.new().validate(bad).valid, "unknown type rejected")
	bad = levels[0].duplicate(true)
	bad.nodes = bad.nodes.filter(func(n: Dictionary): return n.type != "target")
	check(not Validator.new().validate(bad).valid, "missing target rejected")
	bad = levels[0].duplicate(true)
	bad.nodes[0].dirs = [0]
	check(not Validator.new().solve(bad).solved, "unsolvable level detected")
	bad = levels[0].duplicate(true)
	bad.erase("name")
	check(not Validator.new().validate(bad).valid, "missing name rejected")
	bad = levels[0].duplicate(true)
	bad.hint = 42
	check(not Validator.new().validate(bad).valid, "invalid hint rejected")
	print("Levels: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

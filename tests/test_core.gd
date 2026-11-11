extends SceneTree

const EngineModel = preload("res://scripts/core/reaction_engine.gd")
const Grid = preload("res://scripts/core/grid_manager.gd")
var passed: int = 0
var failed: int = 0

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error(label)

func node_at(x: int, y: int, type: String, dirs: Array = [], rotatable: bool = false) -> Dictionary:
	return {"x": x, "y": y, "type": type, "dirs": dirs, "rotatable": rotatable}

func level(nodes: Array, launches: int = 1) -> Dictionary:
	return {"width": 5, "height": 5, "launches": launches, "nodes": nodes}

func run_model(data: Dictionary, source: int = 0) -> Dictionary:
	return EngineModel.new().simulate(data, EngineModel.initial_state(data), source)

func _initialize() -> void:
	var line := level([node_at(0, 2, "source", [1]), node_at(1, 2, "normal"), node_at(2, 2, "target")])
	var result := run_model(line)
	check(result.won, "normal forwards to target")
	check(result == run_model(line), "simulation deterministic including frames")
	check(result.frames.size() == 3, "one cell per wave")
	for direction in range(4):
		var p: Vector2i = Vector2i(2, 2) + EngineModel.DIRECTIONS[direction]
		var data := level([node_at(2, 2, "source", [direction]), node_at(p.x, p.y, "target")])
		check(run_model(data).won, "source direction %d" % direction)
	var turn := level([node_at(0, 2, "source", [1]), node_at(1, 2, "directional", [0], true), node_at(1, 1, "target"), node_at(2, 2, "target")])
	check(not run_model(turn).won, "directional does not leak sideways")
	var split := level([node_at(1, 3, "source", [0]), node_at(1, 2, "splitter", [0, 1]), node_at(1, 1, "target"), node_at(2, 2, "target")])
	check(run_model(split).won, "splitter activates both branches")
	var blocked := level([node_at(0, 2, "source", [1]), node_at(1, 2, "blocker"), node_at(2, 2, "target")])
	check(not run_model(blocked).won, "blocker absorbs")
	var battery := level([node_at(0, 2, "source", [1]), node_at(1, 2, "battery"), node_at(2, 2, "target")], 2)
	var first := run_model(battery)
	check(first.state.charges[1] == 1 and not first.won, "battery stores first hit")
	check(EngineModel.new().simulate(battery, first.state, 0).won, "battery retains charge across launches")
	var simultaneous := level([node_at(2, 3, "source", [0]), node_at(2, 2, "splitter", [1, 3]), node_at(1, 2, "directional", [0]), node_at(3, 2, "directional", [0]), node_at(1, 1, "directional", [1]), node_at(3, 1, "directional", [3]), node_at(2, 1, "battery"), node_at(2, 0, "target")])
	check(run_model(simultaneous).won, "two same-wave hits charge battery")
	var cyclic := level([node_at(0, 2, "source", [1]), node_at(1, 2, "normal"), node_at(2, 2, "normal"), node_at(2, 1, "normal"), node_at(1, 1, "normal"), node_at(4, 4, "target")])
	check(run_model(cyclic).frames.size() <= 7, "cycles terminate")
	var grid := Grid.new()
	grid.load_level(battery)
	var original: Dictionary = grid.state.duplicate(true)
	check(grid.launch(0).accepted, "launch accepted")
	check(grid.undo() and grid.state == original and grid.used == 0, "undo restores complete state")
	grid.launch(0)
	grid.launch(0)
	check(not grid.launch(0).accepted, "budget enforced")
	grid.load_level(blocked)
	grid.launch(0)
	check(grid.status() == "lost", "loss after budget exhausted")
	grid.load_level(turn)
	check(grid.rotate(1), "allowed rotation")
	check(grid.state.rotations[1] == 1 and grid.undo() and grid.state.rotations[1] == 0, "rotation undo")
	grid.launch(0)
	check(not grid.rotate(1), "rotation locked after first launch")
	print("Core: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

class_name LevelValidator
extends RefCounted
const Catalog = preload("res://scripts/core/chapter_catalog.gd")
const Model = preload("res://scripts/core/reaction_engine.gd")
const MAX_STATES: int = 200000

func validate(data: Dictionary) -> Dictionary:
	for field in ["id", "name", "hint", "width", "height", "launches", "nodes"]:
		if not data.has(field): return _invalid("Missing " + field)
	for field in ["name", "hint"]:
		if not data[field] is String or data[field].strip_edges().is_empty():
			return _invalid("Invalid " + field)
	if not _integer(data.id) or data.id < 1 or data.id > Catalog.LEVEL_COUNT: return _invalid("Invalid id")
	for field in ["width", "height", "launches"]:
		if not _integer(data[field]) or data[field] < 1 or data[field] > 8:
			return _invalid("Invalid " + field)
	if not data.nodes is Array or data.nodes.is_empty(): return _invalid("Empty nodes")
	if data.has("par_launches") and (not _integer(data.par_launches) or data.par_launches < 1 or data.par_launches > data.launches):
		return _invalid("Invalid par_launches")
	if int(data.id) > 10:
		if not data.get("objective") is String or data.objective.strip_edges().is_empty(): return _invalid("Missing design objective")
		if not data.get("author_solution") is Array or data.author_solution.is_empty(): return _invalid("Missing author solution")
		if not _integer(data.get("minimum_rotated_nodes", -1)) or data.minimum_rotated_nodes < 0: return _invalid("Invalid rotation design bound")
		for action in data.author_solution:
			if not action is Dictionary or not action.get("type") in ["rotate","launch"] or not _integer(action.get("index",-1)) or action.index < 0 or action.index >= data.nodes.size():
				return _invalid("Invalid author action")
	if int(data.id)>50:
		if data.get("schema_version",0)!=2 or not data.get("design_goal") is String or not data.get("difficulty") is Dictionary: return _invalid("Missing authored design metadata")
		if not data.get("required_nodes") is Array or not data.get("required_events") is Array: return _invalid("Missing interaction proof")
		for index in data.required_nodes:
			if not _integer(index) or index<0 or index>=data.nodes.size(): return _invalid("Invalid required node")
		for event in data.required_events:
			if not event is Dictionary or not event.get("kind") in ["reflect","portal","and","delay_release"]: return _invalid("Invalid interaction event")
	var cells: Dictionary = {}
	var sources: int = 0
	var targets: int = 0
	var pairs: Dictionary = {}
	if data.nodes.size()>64: return _invalid("Too many nodes")
	for n in data.nodes:
		if not n is Dictionary: return _invalid("Node must be an object")
		for field in ["x", "y", "type"]:
			if not n.has(field): return _invalid("Missing node " + field)
		if not _integer(n.x) or not _integer(n.y): return _invalid("Non-integer position")
		if n.x < 0 or n.y < 0 or n.x >= data.width or n.y >= data.height: return _invalid("Outside board")
		var cell: Vector2i = Vector2i(n.x, n.y)
		if cells.has(cell): return _invalid("Duplicate cell")
		cells[cell] = true
		if not n.type in Model.TYPES: return _invalid("Unknown node type")
		if n.type == "source": sources += 1
		if n.type == "target": targets += 1
		if n.has("rotatable") and not n.rotatable is bool: return _invalid("Invalid rotation flag")
		if n.get("rotatable", false) and not n.type in ["directional", "splitter", "reflector", "and_gate", "delay"]:
			return _invalid("Unsupported rotatable type")
		if n.type in ["source", "directional", "splitter", "portal", "and_gate", "delay"]:
			if not n.get("dirs") is Array or n.dirs.is_empty(): return _invalid("Missing directions")
			if n.type == "directional" and n.dirs.size() != 1: return _invalid("Directional needs one exit")
			var seen: Array = []
			for d in n.dirs:
				if not _integer(d) or d < 0 or d > 3 or d in seen: return _invalid("Invalid direction")
				seen.append(d)
		if n.type=="portal":
			if not n.get("pair_id") is String: return _invalid("Missing portal pair_id")
			var pattern:=RegEx.new()
			pattern.compile("^[A-Za-z0-9_-]{1,32}$")
			if pattern.search(n.pair_id)==null: return _invalid("Invalid portal pair_id")
			pairs[n.pair_id]=int(pairs.get(n.pair_id,0))+1
		if n.type=="delay" and (not _integer(n.get("delay_ticks")) or n.delay_ticks<1 or n.delay_ticks>3): return _invalid("Invalid delay ticks")
	for count in pairs.values():
		if count!=2: return _invalid("Portal needs exactly two endpoints")
	if sources == 0 or targets == 0: return _invalid("Source and target required")
	return {"valid": true}

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

func _invalid(message: String) -> Dictionary:
	return {"valid": false, "error": message}

func solve(data: Dictionary) -> Dictionary:
	var schema: Dictionary = validate(data)
	if not schema.valid: return {"solved": false, "error": schema.error, "visited": 0}
	var rotations: Array = []
	var sources: Array = []
	for i in range(data.nodes.size()):
		if data.nodes[i].get("rotatable", false): rotations.append(i)
		if data.nodes[i].type == "source": sources.append(i)
	var context: Dictionary = {"visited": 0, "seen": {}, "actions": []}
	var solved: bool = _orient(data, Model.initial_state(data), rotations, sources, 0, [], context)
	return {"solved": solved, "actions": context.actions, "visited": context.visited,
		"error": "Search limit reached" if context.visited >= MAX_STATES else ""}

func _orient(data: Dictionary, state: Dictionary, rotations: Array, sources: Array, cursor: int, actions: Array, ctx: Dictionary) -> bool:
	if ctx.visited >= MAX_STATES: return false
	if cursor == rotations.size():
		return _launch_search(data, state, sources, 0, actions, ctx)
	var index: int = rotations[cursor]
	for r in range(4):
		var next: Dictionary = state.duplicate(true)
		next.rotations[index] = r
		var next_actions: Array = actions.duplicate(true)
		for unused in range(r): next_actions.append({"type": "rotate", "index": index})
		if _orient(data, next, rotations, sources, cursor + 1, next_actions, ctx): return true
	return false

func _launch_search(data: Dictionary, state: Dictionary, sources: Array, used: int, actions: Array, ctx: Dictionary) -> bool:
	if Model.has_won(data, state):
		ctx.actions = actions
		return true
	if used >= int(data.launches) or ctx.visited >= MAX_STATES: return false
	var key: String = JSON.stringify([state, used])
	if ctx.seen.has(key): return false
	ctx.seen[key] = true
	ctx.visited += 1
	for source in sources:
		var result: Dictionary = Model.new().simulate(data, state, source)
		var next_actions: Array = actions.duplicate(true)
		next_actions.append({"type": "launch", "index": source})
		if _launch_search(data, result.state, sources, used + 1, next_actions, ctx): return true
	return false

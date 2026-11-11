class_name ReactionEngine
extends RefCounted
## Pure orthogonal wave simulation. No scene tree, clocks or random values.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const TYPES: Array[String] = ["source", "normal", "directional", "splitter", "blocker", "battery", "target"]

static func initial_state(level: Dictionary) -> Dictionary:
	var count: int = level.nodes.size()
	var rotations: Array = []
	var charges: Array = []
	var active: Array = []
	rotations.resize(count)
	rotations.fill(0)
	charges.resize(count)
	charges.fill(0)
	active.resize(count)
	active.fill(false)
	return {"rotations": rotations, "charges": charges, "active": active}

static func has_won(level: Dictionary, state: Dictionary) -> bool:
	var targets: int = 0
	for i in range(level.nodes.size()):
		if level.nodes[i].type == "target":
			targets += 1
			if not state.active[i]:
				return false
	return targets > 0

func simulate(level: Dictionary, before: Dictionary, source: int) -> Dictionary:
	var state: Dictionary = before.duplicate(true)
	if source < 0 or source >= level.nodes.size() or level.nodes[source].type != "source":
		return {"accepted": false, "state": state, "frames": [], "won": has_won(level, state)}
	var lookup: Dictionary = {}
	for i in range(level.nodes.size()):
		lookup[Vector2i(level.nodes[i].x, level.nodes[i].y)] = i
	var emitted: Dictionary = {source: true}
	state.active[source] = true
	var frames: Array = [{"nodes": [source], "edges": [], "state": state.duplicate(true)}]
	var wave: Array = _emit(level, state, source, lookup)
	# At most N emitters each enqueue four edges. Every wave consumes >=1 edge.
	var remaining: int = level.nodes.size() * 4 + 1
	while not wave.is_empty() and remaining > 0:
		remaining -= 1
		var hits: Dictionary = {}
		for edge in wave:
			var target: int = edge.to
			hits[target] = int(hits.get(target, 0)) + 1
		var indices: Array = hits.keys()
		indices.sort()
		var activated: Array = []
		var next_wave: Array = []
		for i in indices:
			var kind: String = level.nodes[i].type
			if kind == "blocker" or kind == "source" or emitted.has(i):
				continue
			if kind == "battery":
				state.charges[i] = mini(2, int(state.charges[i]) + int(hits[i]))
				if state.charges[i] < 2:
					continue
			state.active[i] = true
			activated.append(i)
			emitted[i] = true
			next_wave.append_array(_emit(level, state, i, lookup))
		frames.append({"nodes": activated, "edges": wave.duplicate(true), "state": state.duplicate(true)})
		wave = next_wave
	return {"accepted": true, "state": state, "frames": frames, "won": has_won(level, state)}

func _emit(level: Dictionary, state: Dictionary, index: int, lookup: Dictionary) -> Array:
	var node: Dictionary = level.nodes[index]
	var dirs: Array = []
	match node.type:
		"normal", "battery": dirs = [0, 1, 2, 3]
		"source", "directional", "splitter": dirs = node.dirs
	var edges: Array = []
	for direction in dirs:
		var rotated: int = (int(direction) + int(state.rotations[index])) % 4
		var cell: Vector2i = Vector2i(node.x, node.y) + DIRECTIONS[rotated]
		if lookup.has(cell):
			edges.append({"from": index, "to": lookup[cell]})
	return edges

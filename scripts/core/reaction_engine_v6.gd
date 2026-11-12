class_name ExpandedReactionEngine
extends RefCounted
## Pure, transactional discrete-tick simulation; presentation never drives timing.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const TYPES: Array[String] = ["source", "normal", "directional", "splitter", "blocker", "battery", "target", "reflector", "portal", "and_gate", "delay"]
const MAX_TICKS: int = 128
const MAX_EVENTS: int = 4096
# Larger than authored boards so offline budget probes remain possible, but bounded.
const MAX_RUNTIME_NODES: int = 4096
const MAX_RUNTIME_AXIS: int = 4096
var _tick_limit: int
var _event_limit: int

## Offline consumers may impose smaller budgets; safety maxima cannot be raised.
func _init(tick_limit: int = MAX_TICKS, event_limit: int = MAX_EVENTS) -> void:
	_tick_limit = clampi(tick_limit, 1, MAX_TICKS)
	_event_limit = clampi(event_limit, 1, MAX_EVENTS)

static func initial_state(level: Dictionary) -> Dictionary:
	var definitions: Variant = level.get("nodes",[])
	var count: int = definitions.size() if definitions is Array and definitions.size() <= MAX_RUNTIME_NODES else 0
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
	var definitions: Variant = level.get("nodes")
	var active: Variant = state.get("active")
	if not definitions is Array or not active is Array or definitions.size() > MAX_RUNTIME_NODES or active.size() != definitions.size(): return false
	var targets: int = 0
	for i in range(definitions.size()):
		if not definitions[i] is Dictionary: return false
		if definitions[i].get("type","") == "target":
			targets += 1
			if not active[i] is bool or not active[i]: return false
	return targets > 0

func simulate(level: Dictionary, before: Dictionary, source: int) -> Dictionary:
	var lookup: Dictionary = {}
	var pairs: Dictionary = {}
	if not _configuration(level, before, lookup, pairs):
		return _rejected(level, before, "invalid_reaction")
	if source < 0 or source >= level.nodes.size() or level.nodes[source].type != "source":
		return _rejected(level, before, "invalid_source")
	var state: Dictionary = before.duplicate(true)
	var consumed: Dictionary = {source:true}
	var consumed_pairs: Dictionary = {}
	var context: Dictionary = {"arrivals":{}, "releases":{}, "events":0, "error":""}
	state.active[source] = true
	var frames: Array = [_frame(0,[source],[],state,[],[])]
	_enqueue(context, "arrivals", 1, _emit(level,state,source,level.nodes[source].dirs,lookup))
	var tick: int = 0
	while (not context.arrivals.is_empty() or not context.releases.is_empty()) and context.error.is_empty():
		tick += 1
		if tick >= _tick_limit:
			context.error = "reaction_tick_limit"
			break
		var wave: Array = context.arrivals.get(tick, [])
		context.arrivals.erase(tick)
		var releases: Array = context.releases.get(tick, [])
		context.releases.erase(tick)
		var hits: Dictionary = {}
		for edge in wave:
			if not hits.has(edge.to): hits[edge.to] = []
			hits[edge.to].append(edge)
		var indices: Array = hits.keys()
		indices.sort()
		var activated: Array = []
		var outgoing: Array = []
		var transports: Array = []
		var trace: Array = []
		for i in indices:
			var definition: Dictionary = level.nodes[i]
			var kind: String = definition.type
			if kind in ["blocker","source"] or consumed.has(i): continue
			if kind == "battery":
				state.charges[i] = mini(2,int(state.charges[i])+hits[i].size())
				if state.charges[i] < 2: continue
			if kind == "and_gate":
				var neighbors: Array = []
				for edge in hits[i]:
					if not edge.from in neighbors: neighbors.append(edge.from)
				if neighbors.size() < 2: continue
				neighbors.sort()
				trace.append({"kind":"and","node":i,"neighbors":neighbors,"minimum_distinct_neighbors":neighbors.size()})
			if kind == "portal":
				var pair_id: String = definition.pair_id
				if consumed_pairs.has(pair_id): continue
				consumed_pairs[pair_id] = true
				var endpoints: Array = pairs[pair_id]
				for endpoint in endpoints:
					consumed[endpoint] = true
					state.active[endpoint] = true
					activated.append(endpoint)
				for entry in endpoints:
					if not hits.has(entry): continue
					var partner: int = int(endpoints[1] if entry == endpoints[0] else endpoints[0])
					if not _spend(context): break
					var transport: Dictionary = {"from":entry,"to":partner,"kind":"portal","direction":-1,"pair_id":pair_id}
					transports.append(transport)
					trace.append(transport.duplicate(true))
					outgoing.append_array(_emit(level,state,partner,level.nodes[partner].dirs,lookup))
				continue
			state.active[i] = true
			consumed[i] = true
			activated.append(i)
			if kind == "reflector":
				var mapping: Array = [1,0,3,2] if int(state.rotations[i]) % 2 == 0 else [3,2,1,0]
				var reflected: Array = []
				for edge in hits[i]:
					var direction: int = int(mapping[edge.direction])
					trace.append({"kind":"reflect","node":i,"incoming_direction":edge.direction,"outgoing_direction":direction})
					if not direction in reflected: reflected.append(direction)
				reflected.sort()
				# Mapping already includes surface rotation; do not rotate directions twice.
				outgoing.append_array(_edges(level,i,reflected,lookup))
			elif kind == "delay":
				var delayed_edges: Array = _emit(level,state,i,definition.dirs,lookup)
				if not delayed_edges.is_empty():
					_enqueue(context,"releases",tick+int(definition.delay_ticks),[{"node":i,"edges":delayed_edges,"arrival_tick":tick,"delay_ticks":int(definition.delay_ticks)}])
			else:
				var dirs: Array = []
				if kind in ["normal","battery"]: dirs = [0,1,2,3]
				elif kind in ["directional","splitter","and_gate"]: dirs = definition.dirs
				outgoing.append_array(_emit(level,state,i,dirs,lookup))
		var released: Array = []
		for release in releases:
			released.append(release.node)
			outgoing.append_array(release.edges)
			trace.append({"kind":"delay_release","node":release.node,"arrival_tick":release.arrival_tick,"delay_ticks":release.delay_ticks})
		_enqueue(context,"arrivals",tick+1,outgoing)
		activated.sort()
		var display_edges: Array = wave.duplicate(true)
		display_edges.append_array(transports)
		frames.append(_frame(tick,activated,display_edges,state,released,trace))
	if not context.error.is_empty(): return _rejected(level,before,context.error)
	return {"accepted":true,"state":state,"frames":frames,"won":has_won(level,state)}

func _frame(tick: int, activated: Array, edges: Array, state: Dictionary, released: Array, events: Array) -> Dictionary:
	return {"tick":tick,"nodes":activated.duplicate(),"edges":edges.duplicate(true),"state":state.duplicate(true),"released":released.duplicate(),"events":events.duplicate(true)}

func _rejected(level: Dictionary, before: Dictionary, reason: String) -> Dictionary:
	return {"accepted":false,"state":before.duplicate(true),"frames":[],"won":has_won(level,before),"error":reason}

func _spend(context: Dictionary) -> bool:
	if not context.error.is_empty(): return false
	if context.events >= _event_limit:
		context.error = "reaction_event_limit"
		return false
	context.events += 1
	return true

func _enqueue(context: Dictionary, queue: String, tick: int, events: Array) -> void:
	if events.is_empty() or not context.error.is_empty(): return
	if tick >= _tick_limit:
		context.error = "reaction_tick_limit"
		return
	for event in events:
		if not _spend(context): return
		if not context[queue].has(tick): context[queue][tick] = []
		context[queue][tick].append(event)

func _emit(level: Dictionary, state: Dictionary, index: int, dirs: Array, lookup: Dictionary) -> Array:
	var rotated: Array = []
	for direction in dirs: rotated.append((int(direction)+int(state.rotations[index]))%4)
	return _edges(level,index,rotated,lookup)

func _edges(level: Dictionary, index: int, dirs: Array, lookup: Dictionary) -> Array:
	var definition: Dictionary = level.nodes[index]
	var edges: Array = []
	for direction in dirs:
		var cell: Vector2i = Vector2i(definition.x,definition.y)+DIRECTIONS[int(direction)]
		if lookup.has(cell): edges.append({"from":index,"to":lookup[cell],"direction":int(direction)})
	return edges

func _configuration(level: Dictionary, state: Dictionary, lookup: Dictionary, pairs: Dictionary) -> bool:
	var definitions: Variant=level.get("nodes")
	if not definitions is Array or definitions.is_empty() or definitions.size()>MAX_RUNTIME_NODES: return false
	for axis in ["width","height"]:
		if not _integer(level.get(axis)) or level[axis]<1 or level[axis]>MAX_RUNTIME_AXIS: return false
	for key in ["rotations","charges","active"]:
		if not state.get(key) is Array or state[key].size() != level.nodes.size(): return false
	var pair_pattern := RegEx.new()
	pair_pattern.compile("^[A-Za-z0-9_-]{1,32}$")
	for i in range(level.nodes.size()):
		if not level.nodes[i] is Dictionary: return false
		var definition: Dictionary = level.nodes[i]
		if not definition.get("type","") in TYPES: return false
		if not _integer(definition.get("x")) or not _integer(definition.get("y")): return false
		if definition.x<0 or definition.y<0 or definition.x>=level.width or definition.y>=level.height: return false
		if definition.has("rotatable") and not definition.rotatable is bool: return false
		var cell := Vector2i(int(definition.x),int(definition.y))
		if lookup.has(cell): return false
		lookup[cell] = i
		if not _integer(state.rotations[i]) or state.rotations[i] < 0 or state.rotations[i] > 3: return false
		if not _integer(state.charges[i]) or state.charges[i] < 0 or state.charges[i] > 2: return false
		if not state.active[i] is bool: return false
		if definition.type in ["source","directional","splitter","portal","and_gate","delay"]:
			if not definition.get("dirs") is Array or definition.dirs.is_empty(): return false
			for direction in definition.dirs:
				if not _integer(direction) or direction < 0 or direction > 3: return false
		if definition.type == "portal":
			if not definition.get("pair_id") is String or pair_pattern.search(definition.pair_id) == null: return false
			if definition.get("rotatable",false) or int(state.rotations[i]) != 0: return false
			if not pairs.has(definition.pair_id): pairs[definition.pair_id] = []
			pairs[definition.pair_id].append(i)
		if definition.type == "delay":
			if not _integer(definition.get("delay_ticks")) or definition.delay_ticks < 1 or definition.delay_ticks > 3: return false
	for endpoints in pairs.values():
		if endpoints.size() != 2: return false
	return true

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

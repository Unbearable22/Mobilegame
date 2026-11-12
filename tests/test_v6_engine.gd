extends SceneTree
## Exact event-time contracts; each fixture catches a routing/grouping/rollback error.
const Model = preload("res://scripts/core/reaction_engine_v6.gd")
const Legacy = preload("res://tests/fixtures/reaction_engine_v5.gd")
var passed: int = 0
var failed: int = 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)

func board(nodes: Array) -> Dictionary:
	var width:int=8
	var height:int=8
	for definition in nodes:
		width=maxi(width,int(definition.x)+1)
		height=maxi(height,int(definition.y)+1)
	return {"nodes":nodes,"width":width,"height":height,"launches":4}

func node(x: int, y: int, kind: String, extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"x":x,"y":y,"type":kind}
	result.merge(extra)
	return result

func activated_tick(result: Dictionary, index: int) -> int:
	for t in range(result.frames.size()):
		if index in result.frames[t].nodes: return t
	return -1

func portal_edges(result: Dictionary) -> Array:
	var found: Array = []
	for frame in result.frames:
		for edge in frame.edges:
			if edge.get("kind", "") == "portal": found.append(edge)
	return found

func _initialize() -> void:
	test_reflector_table()
	test_reflector_simultaneous()
	test_portals()
	test_and_same_tick()
	test_and_no_memory()
	test_delays()
	test_battery_persistence()
	test_malformed_inputs()
	test_budgets()
	test_cycles_and_rotation()
	test_legacy_replays()
	print("Expanded engine: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func test_reflector_table() -> void:
	var directions: Array = [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
	var mappings: Array = [[1,0,3,2],[3,2,1,0]]
	for rotation in range(4):
		for incoming in range(4):
			var origin: Vector2i = Vector2i(3,3) - directions[incoming]
			var goal: Vector2i = Vector2i(3,3) + directions[mappings[rotation % 2][incoming]]
			var level: Dictionary = board([node(origin.x,origin.y,"source",{"dirs":[incoming]}),node(3,3,"reflector"),node(goal.x,goal.y,"target")])
			var state: Dictionary = Model.initial_state(level)
			state.rotations[1] = rotation
			var result: Dictionary = Model.new().simulate(level,state,0)
			check(result.accepted and result.won, "reflector mapping r%d in%d" % [rotation,incoming])
			check(activated_tick(result,2) == 2,"mirror target arrives tick2")
			check(not state.active[0] and not state.active[1],"simulate does not mutate caller")

func test_reflector_simultaneous() -> void:
	var level: Dictionary = board([
		node(0,2,"source",{"dirs":[0,1]}),node(0,1,"directional",{"dirs":[1]}),
		node(1,2,"directional",{"dirs":[0]}),node(1,1,"reflector"),
		node(1,0,"target"),node(2,1,"target")])
	var result: Dictionary = Model.new().simulate(level,Model.initial_state(level),0)
	check(result.won,"same tick mirror inputs route to both targets")
	check(activated_tick(result,4) == 3 and activated_tick(result,5) == 3,"simultaneous reflected targets tick3")

func test_portals() -> void:
	var level: Dictionary = board([
		node(0,1,"source",{"dirs":[1]}),node(1,1,"portal",{"pair_id":"p1","dirs":[3]}),
		node(5,5,"portal",{"pair_id":"p1","dirs":[1]}),node(6,5,"target")])
	var initial: Dictionary = Model.initial_state(level)
	var result: Dictionary = Model.new().simulate(level,initial,0)
	check(result.won and activated_tick(result,3) == 2,"single portal entry emits partner exits tick2")
	check(result.state.active[1] and result.state.active[2],"both portal endpoints active")
	check(portal_edges(result).size() == 1,"single entry records one virtual transport")
	for edge in portal_edges(result): check(edge.get("direction",0) == -1,"portal display direction sentinel")
	check(JSON.stringify(result) == JSON.stringify(Model.new().simulate(level,initial,0)),"portal full trace deterministic")
	var second: Dictionary = Model.new().simulate(level,result.state,0)
	check(portal_edges(second).size() == 1,"pair reusable in later launch")
	var both: Dictionary = board([
		node(1,1,"source",{"dirs":[0,1]}),node(1,0,"portal",{"pair_id":"both","dirs":[3]}),
		node(2,1,"portal",{"pair_id":"both","dirs":[2]}),node(0,0,"target"),node(2,2,"target")])
	var simultaneous: Dictionary = Model.new().simulate(both,Model.initial_state(both),0)
	check(simultaneous.won,"simultaneous portal entries emit both exit sets")
	check(portal_edges(simultaneous).size() == 2,"both entries transport once without recursion")
	check(activated_tick(simultaneous,3) == 2 and activated_tick(simultaneous,4) == 2,"both portal targets tick2")
	var malformed: Dictionary = level.duplicate(true)
	malformed.nodes[2].pair_id = "missing"
	var rejected: Dictionary = Model.new().simulate(malformed,Model.initial_state(malformed),0)
	check(not rejected.accepted,"unpaired portal rejected without partial result")

func and_board(delayed: bool) -> Dictionary:
	var second: Dictionary = node(2,2,"directional",{"dirs":[0]})
	if delayed: second = node(2,2,"delay",{"dirs":[0],"delay_ticks":1})
	return board([node(1,2,"source",{"dirs":[0,1]}),node(1,1,"directional",{"dirs":[1]}),second,
		node(2,1,"and_gate",{"dirs":[1]}),node(3,1,"target")])

func test_and_same_tick() -> void:
	var level: Dictionary = and_board(false)
	var result: Dictionary = Model.new().simulate(level,Model.initial_state(level),0)
	check(result.won and activated_tick(result,3) == 2,"AND groups distinct neighbors same tick")
	check(activated_tick(result,4) == 3,"AND target next tick")
	level = and_board(true)
	result = Model.new().simulate(level,Model.initial_state(level),0)
	check(not result.won and activated_tick(result,3) == -1,"AND does not accumulate across ticks")

func test_and_no_memory() -> void:
	var level: Dictionary = board([node(0,1,"source",{"dirs":[1]}),node(1,0,"source",{"dirs":[2]}),
		node(1,1,"and_gate",{"dirs":[1]}),node(2,1,"target")])
	var first: Dictionary = Model.new().simulate(level,Model.initial_state(level),0)
	var second: Dictionary = Model.new().simulate(level,first.state,1)
	check(not first.won and not second.won and not second.state.active[2],"AND no latch across launches")
	# Duplicated source dirs deliberately probe runtime grouping even though schema rejects duplicates.
	level.nodes[0].dirs = [1,1]
	var duplicate: Dictionary = Model.new().simulate(level,Model.initial_state(level),0)
	check(not duplicate.won and not duplicate.state.active[2],"same neighbor twice cannot satisfy AND")

func test_delays() -> void:
	for duration in range(1,4):
		var level: Dictionary = board([node(0,0,"source",{"dirs":[1]}),node(1,0,"delay",{"dirs":[1],"delay_ticks":duration}),node(2,0,"target")])
		var result: Dictionary = Model.new().simulate(level,Model.initial_state(level),0)
		check(result.won and activated_tick(result,2) == duration+2,"delay%d exact target arrival" % duration)
		check(activated_tick(result,1) == 1,"delay activates before waiting")
		check(result.frames.size() == duration+3,"delay retains every tick")
		if result.frames.size() > 2:
			check(result.frames[2].nodes.is_empty() and result.frames[2].edges.is_empty(),"empty waiting frame remains")
		var repeated: Dictionary = Model.new().simulate(level,result.state,0)
		check(activated_tick(repeated,2) == duration+2,"new launch resets delay schedule")

func test_battery_persistence() -> void:
	var level: Dictionary = board([node(0,0,"source",{"dirs":[1]}),node(1,0,"battery"),node(2,0,"target")])
	var state: Dictionary = Model.initial_state(level)
	var first: Dictionary = Model.new().simulate(level,state,0)
	var second: Dictionary = Model.new().simulate(level,first.state,0)
	check(not first.won and first.state.charges[1] == 1,"battery first charge persists")
	check(second.won and second.state.charges[1] == 2,"battery second launch emits")
	check(state.charges[1] == 0 and not state.active[0],"working state deep copied")

func legacy_frames(frames: Array) -> Array:
	var cleaned: Array = []
	for frame in frames:
		var edges: Array = []
		for edge in frame.edges: edges.append({"from":edge.from,"to":edge.to})
		cleaned.append({"nodes":frame.nodes,"edges":edges,"state":frame.state})
	return cleaned

func test_legacy_replays() -> void:
	for id in range(1,51):
		var level: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/%02d.json" % id))
		var old_state: Dictionary = Legacy.initial_state(level)
		var state: Dictionary = Model.initial_state(level)
		for action in level.get("author_solution",[{"type":"launch","index":0}]):
			if action.type == "rotate":
				old_state.rotations[action.index] = (old_state.rotations[action.index]+1)%4
				state.rotations[action.index] = (state.rotations[action.index]+1)%4
			else:
				var old_result: Dictionary = Legacy.new().simulate(level,old_state,int(action.index))
				var result: Dictionary = Model.new().simulate(level,state,int(action.index))
				check(result.state == old_result.state and result.won == old_result.won,"legacy state id%d" % id)
				check(legacy_frames(result.frames) == old_result.frames,"legacy waves id%d" % id)
				old_state = old_result.state
				state = result.state

func test_budgets() -> void:
	var level: Dictionary = board([node(0,0,"source",{"dirs":[1]}),node(1,0,"delay",{"dirs":[1],"delay_ticks":1}),node(2,0,"target")])
	var before: Dictionary = Model.initial_state(level)
	before.charges[0] = 1
	var at_boundary: Dictionary = Model.new(4,3).simulate(level,before,0)
	check(at_boundary.accepted and at_boundary.won,"all three delay events allowed at exact event/tick budget")
	for engine in [Model.new(3,4096),Model.new(128,2)]:
		var rejected: Dictionary = engine.simulate(level,before,0)
		check(not rejected.accepted,"budget overflow rejects launch")
		check(rejected.state == before and rejected.frames.is_empty() and not rejected.won,"budget rejection rolls back source/delay state and trace")
		check(rejected.get("error","") in ["reaction_tick_limit","reaction_event_limit"],"budget rejection reason retained")
	check(not before.active[0],"rejection leaves caller untouched")
	# Synthetic boards exceed campaign dimensions to exercise the immutable safety maxima.
	var long_nodes: Array = [node(0,0,"source",{"dirs":[1]})]
	for x in range(1,128): long_nodes.append(node(x,0,"directional",{"dirs":[1]}))
	long_nodes.append(node(128,0,"target"))
	var long_level: Dictionary = board(long_nodes)
	var long_before: Dictionary = Model.initial_state(long_level)
	var too_long: Dictionary = Model.new().simulate(long_level,long_before,0)
	check(not too_long.accepted and too_long.error == "reaction_tick_limit" and too_long.state == long_before,"default tick128 rejected atomically")
	long_level.nodes.remove_at(127)
	long_level.nodes[127].x = 127
	var boundary: Dictionary = Model.new().simulate(long_level,Model.initial_state(long_level),0)
	check(boundary.accepted and boundary.frames.size() == 128 and activated_tick(boundary,127) == 127,"default tick127 accepted")
	var dense_nodes: Array = []
	for y in range(33):
		for x in range(33): dense_nodes.append(node(x,y,"normal"))
	dense_nodes[0].type = "source"
	dense_nodes[0].dirs = [1,2]
	var dense: Dictionary = board(dense_nodes)
	var dense_before: Dictionary = Model.initial_state(dense)
	var crowded: Dictionary = Model.new().simulate(dense,dense_before,0)
	check(not crowded.accepted and crowded.error == "reaction_event_limit" and crowded.state == dense_before,"default event4097 rejected atomically")
	var invalid: Dictionary = Model.new().simulate(level,before,2)
	check(not invalid.accepted and invalid.state == before and invalid.frames.is_empty(),"invalid selected source rejected atomically")

func test_cycles_and_rotation() -> void:
	var level: Dictionary = board([
		node(0,1,"source",{"dirs":[1]}),node(1,1,"delay",{"dirs":[1],"delay_ticks":3}),
		node(2,1,"normal"),node(3,1,"target")])
	var result: Dictionary = Model.new().simulate(level,Model.initial_state(level),0)
	var releases: int = 0
	for frame in result.frames:
		for event in frame.events:
			if event.kind == "delay_release": releases += 1
	check(result.won and releases == 1 and result.frames.size() == 7,"feedback into delay never schedules a second release")
	var rotated: Dictionary = board([node(0,1,"source",{"dirs":[1]}),node(1,1,"delay",{"dirs":[1],"delay_ticks":1,"rotatable":true}),node(1,2,"target")])
	var state: Dictionary = Model.initial_state(rotated)
	state.rotations[1] = 1
	result = Model.new().simulate(rotated,state,0)
	check(result.won and activated_tick(result,2) == 3,"delay rotated exits honored once")
	var gate: Dictionary = and_board(false)
	gate.nodes[4].x = 2
	gate.nodes[4].y = 0
	state = Model.initial_state(gate)
	state.rotations[3] = 3
	result = Model.new().simulate(gate,state,0)
	check(result.won,"AND rotated exits honored")

func test_malformed_inputs() -> void:
	var valid: Dictionary = board([node(0,0,"source",{"dirs":[1]}),node(1,0,"target")])
	var before: Dictionary = Model.initial_state(valid)
	var cases: Array = [{"level":{},"state":before},{"level":{"nodes":null},"state":before},{"level":{"nodes":"bad"},"state":before}]
	for definition in [null,"node",{"type":"source","x":"left","y":0,"dirs":[1]},{"type":"source","x":NAN,"y":0,"dirs":[1]},{"type":"source","x":-1,"y":0,"dirs":[1]},{"type":"source","x":8,"y":0,"dirs":[1]},{"type":"source","x":0,"y":0,"dirs":[1],"rotatable":"yes"}]:
		var malformed: Dictionary = valid.duplicate(true)
		malformed.nodes[0]=definition
		cases.append({"level":malformed,"state":before})
	for key in ["rotations","charges","active"]:
		var missing: Dictionary=before.duplicate(true)
		missing.erase(key)
		cases.append({"level":valid,"state":missing})
		missing=before.duplicate(true)
		missing[key]=[]
		cases.append({"level":valid,"state":missing})
	for axis in ["width","height"]:
		var invalid_axis:Dictionary=valid.duplicate(true)
		invalid_axis[axis]=4097
		cases.append({"level":invalid_axis,"state":before})
		invalid_axis=valid.duplicate(true)
		invalid_axis.erase(axis)
		cases.append({"level":invalid_axis,"state":before})
	var huge: Dictionary=valid.duplicate(true)
	huge.nodes.resize(4097)
	cases.append({"level":huge,"state":before})
	for item in cases:
		var response: Variant=Model.new().simulate(item.level,item.state,0)
		check(response is Dictionary,"malformed input returns a dictionary")
		if response is Dictionary:
			check(response.get("accepted",true)==false and response.get("state")==item.state and response.get("frames")==[],"malformed input rejection is transactional")
	check(not Model.has_won(valid,{"active":[]}),"malformed outcome check is false")

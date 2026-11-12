class_name LevelAuditor
extends RefCounted
## Offline QA only. Exhaustive orientations and launch sequences through ReactionEngine.
const Model = preload("res://scripts/core/reaction_engine.gd")
const Grid = preload("res://scripts/core/grid_manager.gd")
const LIMIT: int = 500000
func audit(data: Dictionary) -> Dictionary:
	var ctx: Dictionary = {"calls":0,"complete":true,"wins":0,"minimum_launches":999,"minimum_rotated":999,"wrong_order":false,"design_bypassed":false}
	var rotatable: Array = []
	var sources: Array = []
	for i in range(data.nodes.size()):
		if data.nodes[i].get("rotatable",false): rotatable.append(i)
		if data.nodes[i].type == "source": sources.append(i)
	_orient(data,Model.initial_state(data),rotatable,sources,0,0,ctx)
	var grid := Grid.new()
	grid.load_level(data)
	var author_ok: bool = true
	var author_events: Array=[]
	for action in data.get("author_solution",[]):
		if action.type == "rotate": author_ok = grid.rotate(int(action.index)) and author_ok
		else:
			var reaction: Dictionary=grid.launch(int(action.index))
			author_ok=reaction.get("accepted",false) and author_ok
			author_events.append_array(_events(reaction.get("frames",[]),grid.used-1))
	ctx.author_won = author_ok and grid.status() == "won" and grid.used <= int(data.get("par_launches",1)) and _required(data,grid.state,author_events)
	ctx.valid = ctx.complete and ctx.wins > 0 and ctx.minimum_launches <= int(data.get("par_launches",1)) and ctx.minimum_rotated >= int(data.get("minimum_rotated_nodes",0)) and not ctx.wrong_order and not ctx.design_bypassed
	if int(data.id)>50: ctx.valid=ctx.valid and ctx.minimum_launches==int(data.par_launches)
	if data.has("author_solution"): ctx.valid = ctx.valid and ctx.author_won
	return ctx
func _orient(data: Dictionary, state: Dictionary, nodes: Array, sources: Array, index: int, rotated: int, ctx: Dictionary) -> void:
	if not ctx.complete: return
	if index == nodes.size():
		_launch(data,state,sources,0,[],rotated,ctx,[])
		return
	for r in range(4):
		state.rotations[nodes[index]] = r
		_orient(data,state,nodes,sources,index+1,rotated+(1 if r > 0 else 0),ctx)
func _launch(data: Dictionary, state: Dictionary, sources: Array, used: int, sequence: Array, rotated: int, ctx: Dictionary, events: Array) -> void:
	if Model.has_won(data,state):
		ctx.wins += 1
		if not _required(data,state,events): ctx.design_bypassed=true
		ctx.minimum_launches = mini(ctx.minimum_launches,used)
		ctx.minimum_rotated = mini(ctx.minimum_rotated,rotated)
		if data.has("required_source_order"):
			var expected: Array[int] = []
			for i in data.required_source_order: expected.append(int(i))
			var actual: Array[int] = []
			for i in sequence: actual.append(int(i))
			if expected != actual: ctx.wrong_order = true
		return
	if used >= int(data.launches) or not ctx.complete: return
	for source in sources:
		ctx.calls += 1
		if ctx.calls > LIMIT:
			ctx.complete = false
			return
		var next: Dictionary = Model.new().simulate(data,state,int(source))
		var seq: Array = sequence.duplicate()
		seq.append(source)
		if not next.accepted: continue
		var trace: Array=events.duplicate(true)
		trace.append_array(_events(next.frames,used))
		_launch(data,next.state,sources,used+1,seq,rotated,ctx,trace)

func _events(frames: Array, launch: int) -> Array:
	var result: Array = []
	for frame in frames:
		for event in frame.get('events',[]):
			var item: Dictionary = event.duplicate(true)
			item.tick = frame.tick
			item.launch = launch
			result.append(item)
	return result

func _required(data: Dictionary, state: Dictionary, events: Array) -> bool:
	for index in data.get("required_nodes",[]):
		if not state.active[int(index)]: return false
	for expected in data.get("required_events",[]):
		var found: bool = false
		for actual in events:
			var matches: bool = true
			for field in expected:
				if not actual.has(field): matches = false
				elif field == 'minimum_distinct_neighbors': matches = matches and int(actual[field]) >= int(expected[field])
				elif actual[field] != expected[field]: matches = false
			if matches: found = true
		if not found: return false
	return true

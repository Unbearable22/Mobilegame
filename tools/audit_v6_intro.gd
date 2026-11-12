extends SceneTree
## Authored-content proof for levels 51–75 using the exact expanded gameplay engine.
const Model = preload('res://scripts/core/reaction_engine_v6.gd')
const CALL_LIMIT: int = 500000
var _failures: Array = []

func _initialize() -> void:
	var reports: Array = []
	var shapes: Dictionary = {}
	for number in range(51, 76):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string('res://levels/%02d.json' % number))
		var report: Dictionary = _audit(data)
		var shape: String = _shape(data)
		if shapes.has(shape):
			_failures.append('Levels %d and %d have equivalent occupied-cell topology' % [shapes[shape],number])
		shapes[shape] = number
		reports.append(report)
		print('%d: author=%s complete=%s wins=%d launches=%d rotated=%d required=%s calls=%d' % [
			number,report.author_won,report.complete,report.wins,report.minimum_launches,
			report.minimum_rotated_nodes,report.all_wins_require_design,report.calls])
	var output: Dictionary = {'engine':'scripts/core/reaction_engine_v6.gd', 'range':[51,75],
		'complete':_failures.is_empty(), 'levels':reports, 'failures':_failures,
		'difficulty_status':'design hypotheses; human playtesting pending'}
	DirAccess.make_dir_recursive_absolute('res://build')
	var file := FileAccess.open('res://build/v6-intro-audit.json',FileAccess.WRITE)
	file.store_string(JSON.stringify(output,'\t')+'\n')
	for failure in _failures: push_error(failure)
	quit(0 if _failures.is_empty() else 1)

func _audit(data: Dictionary) -> Dictionary:
	var rotatable: Array = []
	var sources: Array = []
	var cells: Dictionary = {}
	var valid: bool = data.schema_version == 2 and data.nodes.size() <= 30 and data.launches <= 3
	for i in range(data.nodes.size()):
		var node: Dictionary = data.nodes[i]
		var cell := Vector2i(node.x,node.y)
		valid = valid and not cells.has(cell) and cell.x >= 0 and cell.y >= 0 and cell.x < data.width and cell.y < data.height
		cells[cell] = true
		if node.get('rotatable',false): rotatable.append(i)
		if node.type == 'source': sources.append(i)
	valid = valid and rotatable.size() <= 4 and sources.size() <= 2 and not sources.is_empty()
	var ctx: Dictionary = {'id':data.id,'calls':0,'complete':true,'wins':0,'minimum_launches':999,
		'minimum_rotated_nodes':999,'minimum_rotation_taps':999,'all_wins_require_design':true,
		'source_order_valid':true,'author_won':false,'nodes':data.nodes.size(),'rotatables':rotatable.size(),'sources':sources.size()}
	if not valid:
		_failures.append('Level %d violates authoring bounds' % data.id)
		return ctx
	var author: Dictionary = _author(data)
	ctx.author_won = author.won and author.accepted and _required(data,author.state,author.events)
	ctx.author_ticks = author.ticks
	_orient(data,Model.initial_state(data),rotatable,sources,0,0,0,ctx)
	if not ctx.complete or ctx.wins == 0 or not ctx.author_won or not ctx.all_wins_require_design or not ctx.source_order_valid:
		_failures.append('Level %d fails authored interaction proof' % data.id)
	if ctx.minimum_rotated_nodes != int(data.minimum_rotated_nodes) or ctx.minimum_launches != int(data.par_launches):
		_failures.append('Level %d has incorrect rotation/par bound' % data.id)
	return ctx

func _author(data: Dictionary) -> Dictionary:
	var state: Dictionary = Model.initial_state(data)
	var events: Array = []
	var ticks: Array = []
	var accepted: bool = true
	var launched: bool = false
	for action in data.author_solution:
		var index: int = int(action.index)
		if action.type == 'rotate':
			if launched or not data.nodes[index].get('rotatable',false): accepted = false
			state.rotations[index] = (int(state.rotations[index])+1)%4
		else:
			launched = true
			var result: Dictionary = Model.new().simulate(data,state,index)
			accepted = accepted and result.accepted
			state = result.state
			events.append_array(_events(result.frames,ticks.size()))
			ticks.append(result.frames.size()-1)
	return {'state':state,'accepted':accepted,'events':events,'ticks':ticks,'won':Model.has_won(data,state)}

func _orient(data: Dictionary, state: Dictionary, indices: Array, sources: Array, cursor: int, changed: int, taps: int, ctx: Dictionary) -> void:
	if not ctx.complete: return
	if cursor == indices.size():
		_search(data,state,sources,[],[],changed,taps,ctx)
		return
	for rotation in range(4):
		var next: Dictionary = state.duplicate(true)
		next.rotations[indices[cursor]] = rotation
		_orient(data,next,indices,sources,cursor+1,changed+(1 if rotation else 0),taps+rotation,ctx)

func _search(data: Dictionary, state: Dictionary, sources: Array, sequence: Array, events: Array, changed: int, taps: int, ctx: Dictionary) -> void:
	if Model.has_won(data,state):
		ctx.wins += 1
		ctx.minimum_launches = mini(ctx.minimum_launches,sequence.size())
		ctx.minimum_rotated_nodes = mini(ctx.minimum_rotated_nodes,changed)
		ctx.minimum_rotation_taps = mini(ctx.minimum_rotation_taps,taps)
		ctx.all_wins_require_design = ctx.all_wins_require_design and _required(data,state,events)
		if data.has('required_source_order'):
			var expected_order: Array = []
			for source in data.required_source_order: expected_order.append(int(source))
			if sequence != expected_order: ctx.source_order_valid = false
		return
	if sequence.size() >= int(data.launches) or not ctx.complete: return
	for source in sources:
		ctx.calls += 1
		if ctx.calls > CALL_LIMIT:
			ctx.complete = false
			return
		var result: Dictionary = Model.new().simulate(data,state,int(source))
		if not result.accepted: continue
		var next_sequence: Array = sequence.duplicate()
		next_sequence.append(source)
		var next_events: Array = events.duplicate(true)
		next_events.append_array(_events(result.frames,sequence.size()))
		_search(data,result.state,sources,next_sequence,next_events,changed,taps,ctx)

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
	for index in data.required_nodes:
		if not state.active[int(index)]: return false
	for expected in data.required_events:
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

func _shape(data: Dictionary) -> String:
	# Ignore types, labels and directions: identical occupied geometry under D4 is disallowed.
	var variants: Array[String] = []
	for mirrored in [false,true]:
		for rotation in range(4):
			var points: Array[Vector2i] = []
			var low := Vector2i(1000,1000)
			for node in data.nodes:
				var point := Vector2i(-int(node.x) if mirrored else int(node.x),int(node.y))
				for unused in range(rotation): point = Vector2i(-point.y,point.x)
				points.append(point)
				low = Vector2i(mini(low.x,point.x),mini(low.y,point.y))
			var encoded: Array[String] = []
			for point in points: encoded.append('%d,%d' % [point.x-low.x,point.y-low.y])
			encoded.sort()
			variants.append('|'.join(encoded))
	variants.sort()
	return variants[0]

extends SceneTree
const Loader = preload("res://scripts/core/level_loader.gd")
const Model = preload("res://scripts/core/reaction_engine.gd")
func _initialize() -> void:
	var level: Dictionary = Loader.new().load_all()[49]
	var configured: Dictionary = Model.initial_state(level)
	var sources: Array = []
	for action in level.author_solution:
		if action.type == "rotate": configured.rotations[int(action.index)] = (int(configured.rotations[int(action.index)])+1)%4
		else: sources.append(int(action.index))
	var engine := Model.new()
	var start: int = Time.get_ticks_usec()
	for i in range(1000):
		var state: Dictionary = configured.duplicate(true)
		for source in sources: state = engine.simulate(level,state,source).state
	var elapsed: int = Time.get_ticks_usec()-start
	print("CPU level50 configured winning sequence (%d launches),1000 runs: %.3f ms, %.3f ms/sequence" % [sources.size(),elapsed/1000.0,elapsed/1000000.0])
	quit()

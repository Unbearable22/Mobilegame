extends SceneTree
const Loader = preload("res://scripts/core/level_loader.gd")
const Model = preload("res://scripts/core/reaction_engine.gd")
func _initialize() -> void:
	var level: Dictionary = Loader.new().load_all()[9]
	var initial: Dictionary = Model.initial_state(level)
	var engine := Model.new()
	var start: int = Time.get_ticks_usec()
	for i in range(1000): engine.simulate(level, initial, 0)
	var elapsed: int = Time.get_ticks_usec() - start
	print("CPU simulation, level 10, 1000 runs: %.3f ms; average %.3f ms/run" % [elapsed / 1000.0, elapsed / 1000000.0])
	quit()

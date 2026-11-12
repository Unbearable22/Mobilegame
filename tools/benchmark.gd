extends SceneTree
const Loader=preload("res://scripts/core/level_loader.gd")
const Grid=preload("res://scripts/core/grid_manager.gd")
func _initialize()->void:
	var levels:Array=Loader.new().load_all()
	var rows:Array=[]
	for id in [50,68,88,100]:
		var level:Dictionary=levels[id-1]
		var samples:Array=[]
		for iteration in range(100):
			var grid=Grid.new();grid.load_level(level)
			var began:int=Time.get_ticks_usec()
			for action in level.author_solution:
				if action.type=="rotate":grid.rotate(int(action.index))
				else:grid.launch(int(action.index))
			samples.append((Time.get_ticks_usec()-began)/1000.0)
		samples.sort()
		var sum:float=0
		for value in samples:sum+=value
		rows.append({"id":id,"runs":100,"mean_sequence_ms":sum/100,"p95_sequence_ms":samples[94],"nodes":level.nodes.size()})
	var file:=FileAccess.open("res://docs/v6-engine-benchmark.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope":"Desktop headless Godot debug CPU; not Android FPS/thermals","sequences":rows},"\t")+"\n")
	print(JSON.stringify(rows));quit()

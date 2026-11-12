extends SceneTree
# QA ablation only: remove one non-target node and replay the remapped author actions.
const Loader = preload("res://scripts/core/level_loader.gd")
const Grid = preload("res://scripts/core/grid_manager.gd")
func _initialize() -> void:
	var levels: Array = Loader.new().load_all()
	var report: Array = []
	for id in [19,49]:
		var level: Dictionary = levels[id-1]
		var sources: Array = []
		for i in range(level.nodes.size()):
			if level.nodes[i].type == "source": sources.append(i)
		var row: Dictionary = {"id":id,"sources":sources,"ablations":[]}
		for removed in range(level.nodes.size()):
			if level.nodes[removed].type == "target": continue
			var copy: Dictionary = level.duplicate(true)
			copy.nodes.remove_at(removed)
			var grid := Grid.new()
			grid.load_level(copy)
			for action in level.author_solution:
				var index: int = int(action.index)
				if index == removed: continue
				if index > removed: index -= 1
				if action.type == "rotate": grid.rotate(index)
				else: grid.launch(index)
			row.ablations.append({"index":removed,"type":level.nodes[removed].type,"position":[level.nodes[removed].x,level.nodes[removed].y],"author_still_wins":grid.status()=="won"})
		report.append(row)
	var file := FileAccess.open("res://docs/v4-node-necessity.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	print(JSON.stringify(report))
	# Level19 deliberately has two symmetric ingress routes;49 has exactly one source.
	var source_counts_valid: bool = report[0].sources.size()==2 and report[1].sources.size()==1
	quit(0 if source_counts_valid else 1)

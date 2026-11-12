extends SceneTree
## Controlled ablation of authored witnesses; this is not an exhaustive solve of
## modified puzzles. Full winning-space interaction proof is LevelAuditor's job.
const Grid=preload("res://scripts/core/grid_manager.gd")
var failed:int=0
var checked:int=0
func _initialize()->void:
	var rows:Array=[]
	for id in range(51,101):
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/%02d.json"%id))
		var pairs:Dictionary={}
		for index in range(data.nodes.size()):
			var type:String=data.nodes[index].type
			if type=="portal":
				var pair:String=data.nodes[index].pair_id
				if not pairs.has(pair):pairs[pair]=[]
				pairs[pair].append(index)
			elif type not in ["target","blocker"]:
				probe(data,[index],rows)
		for indices in pairs.values():probe(data,indices,rows)
	DirAccess.make_dir_recursive_absolute("res://build")
	var file:=FileAccess.open("res://build/v6-redundancy.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checked":checked,"failures":failed,"scope":"blocked-node/source/pair witness replay; not re-solving modified boards","intentional_teaching_decoy":{"level":51,"node":3},"results":rows},"\t")+"\n")
	print("V6 redundancy: %d mutations,%d failures"%[checked,failed]);quit(1 if failed else 0)
func probe(data:Dictionary,indices:Array,rows:Array)->void:
	var altered:Dictionary=data.duplicate(true)
	for index in indices:
		var old:Dictionary=altered.nodes[index]
		altered.nodes[index]={"x":old.x,"y":old.y,"type":"blocker"}
	var grid=Grid.new()
	grid.load_level(altered)
	for action in data.author_solution:
		if int(action.index) in indices:continue
		if action.type=="rotate":grid.rotate(int(action.index))
		else:grid.launch(int(action.index))
	var redundant:bool=grid.status()=="won"
	checked+=1
	rows.append({"id":int(data.id),"blocked":indices,"author_witness_still_wins":redundant})
	if redundant:
		failed+=1
		push_error("Redundant witness detail level%d nodes%s"%[data.id,indices])

extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Progress=preload("res://scripts/core/progression_manager.gd")
const Daily=preload("res://scripts/core/daily_catalog.gd")
const Reactor=preload("res://scripts/core/reactor_catalog.gd")
var passed:int=0
var failed:int=0
func check(ok:bool,label:String)->void:
	if ok: passed+=1
	else: failed+=1;push_error(label)
func _initialize()->void:
	var path:String="user://v6-daily-reactor-test.json"
	DirAccess.remove_absolute(path)
	var progress=Progress.new(Save.new(path))
	check(Daily.level_for_date("2026-11-12")==Daily.level_for_date("2026-11-12"),"daily deterministic")
	check(Daily.valid_date("2024-02-29") and not Daily.valid_date("2026-02-29") and not Daily.valid_date("2026-13-01"),"calendar validation")
	var seen:Dictionary={}
	for day in range(1,29): seen[Daily.level_for_date("2026-11-%02d"%day)]=true
	check(seen.size()>10,"daily pool varies")
	var date:String="2026-11-12"
	var level:int=Daily.level_for_date(date)
	check(Daily.record(progress,date,level,3,1),"daily result saves")
	check(progress.data.completed.is_empty() and progress.data.last_level==1 and progress.data.achievements.is_empty(),"daily does not grant campaign progression")
	check(Daily.record(progress,date,level,2,2) and progress.data.daily[date].stars==3,"daily replay retains best")
	check(not Daily.record(progress,date,level+1,3,1),"daily rejects wrong authored puzzle")
	var restored=Progress.new(Save.new(path))
	check(restored.data.daily==progress.data.daily,"daily survives recreation")
	check(not Reactor.select(progress,"pulse_style","braided"),"future/unearned reward denied")
	for id in range(1,76): progress.complete(id,3)
	check(progress.data.reactor.sectors==[1,2,3] and progress.data.reactor.rewards.braided,"sectors from actual completions")
	check(Reactor.select(progress,"pulse_style","braided") and not Reactor.select(progress,"reactor_style","prismatic"),"chapter3 reward only")
	for id in range(76,101): progress.complete(id,3)
	check(Reactor.select(progress,"reactor_style","prismatic"),"chapter4 reward")
	check(progress.data.reactor.sectors==[1,2,3,4] and not 5 in progress.data.unlocked_chapters,"future sectors cannot complete or unlock")
	check(progress.data.achievements.get("hundred_levels",false) and progress.data.achievements.get("three_hundred_stars",false),"100level milestones")
	var again=Progress.new(Save.new(path))
	check(again.data.reactor==progress.data.reactor and again.data.daily==progress.data.daily,"rewards/daily independent persistence")
	var rotated_date:String="2026-11-12"
	var grid=Daily.replay(rotated_date,[])
	var rotatable:int=-1
	for i in range(grid.level.nodes.size()):
		if grid.level.nodes[i].get("rotatable",false):rotatable=i;break
	check(rotatable>=0,"resume fixture has planning action")
	var actions:Array=[{"type":"rotate","index":rotatable}]
	check(Daily.save_run(progress,rotated_date,actions),"accepted planning persisted")
	var recreated=Progress.new(Save.new(path))
	var resumed=Daily.replay(rotated_date,recreated.data.daily_runs[rotated_date].actions)
	check(resumed.state.rotations[rotatable]==1 and resumed.history.size()==1,"process recreation reconstructs state and Undo history")
	check(recreated.data.daily_runs[rotated_date].has("snapshot") and recreated.data.daily_runs[rotated_date].content_sha256.length()==64,"daily content pinned with snapshot and fingerprint")
	var cache_input:Dictionary=recreated.data.daily_runs.duplicate(true)
	var cached:Dictionary=Daily.sanitize_runs(cache_input)
	cached[rotated_date].snapshot.name="mutated output"
	check(Daily.sanitize_runs(cache_input)[rotated_date].snapshot.name!="mutated output","cache returns defensive snapshots")
	cache_input[rotated_date].snapshot.name="changed board with stale fingerprint"
	check(Daily.sanitize_runs(cache_input).is_empty(),"cache cannot accept altered content under old checksum")
	check(resumed.undo() and resumed.state.rotations[rotatable]==0,"restored action can Undo")
	check(Daily.save_run(recreated,rotated_date,[]) and not recreated.data.daily_runs.has(rotated_date),"explicit restart clears saved run")
	check(Daily.sanitize_runs({rotated_date:{"level":Daily.level_for_date(rotated_date),"actions":[{"type":"launch","index":-1}]}}).is_empty(),"malformed resumable actions rejected")
	print("V6 daily/reactor: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)

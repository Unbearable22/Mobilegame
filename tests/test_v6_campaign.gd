extends SceneTree
const Game=preload("res://scripts/core/game_manager.gd")
const Daily=preload("res://scripts/core/daily_catalog.gd")
var passed:int=0
var failed:int=0
var awards:Array=[]
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	if ok: passed+=1
	else: failed+=1; push_error(label)
func run()->void:
	var path:String="user://v6-real-campaign-test.json"
	DirAccess.remove_absolute(path)
	var game=Game.new(path)
	game.frame_seconds=0.0
	game.finished.connect(func(won:bool,stars:int): awards.append({"won":won,"stars":stars}))
	root.add_child(game)
	check(game.error_message.is_empty() and game.levels.size()==100,"all100 admitted")
	for data in game.levels:
		game.select_level(int(data.id)-1)
		check(game.current==int(data.id)-1,"sequential chapter access %d"%data.id)
		for action in data.author_solution: game.tap(int(action.index))
		check(game.grid.status()=="won" and game.progress.data.completed.get(str(int(data.id)),0)==3,"real GameManager3stars %d"%data.id)
		check(not game.busy and not game.paused,"reaction settles %d"%data.id)
		var stars:int=game.progress.total_stars()
		game.undo()
		check(game.grid.status()=="playing","Undo restores final launch %d"%data.id)
		game.tap(int(data.author_solution[-1].index))
		check(game.grid.status()=="won" and game.progress.total_stars()==stars,"Undo replay retains best %d"%data.id)
		game.restart()
		check(game.grid.used==0 and game.grid.history.is_empty(),"Restart resets %d"%data.id)
	check(awards.size()==200 and awards.all(func(row:Dictionary): return row.won and row.stars==3),"200 genuine terminal win events")
	var campaign:Dictionary=game.progress.data.completed.duplicate(true)
	var statistics:Dictionary=game.statistics.summary().duplicate(true)
	var last:int=game.progress.data.last_level
	var date:String="2026-11-12"
	check(game.start_daily(date),"daily loads validated pool puzzle")
	for action in game.grid.level.author_solution: game.tap(int(action.index))
	check(game.grid.status()=="won" and game.progress.data.daily.get(date,{}).get("stars",0)==3,"daily real3star result")
	check(game.progress.data.completed==campaign and game.progress.data.last_level==last and game.statistics.summary()==statistics,"daily never mutates campaign/stats")
	game.restart()
	check(game.daily_date==date and game.grid.used==0,"daily restart keeps date")
	game.select_level(last-1)
	check(game.daily_date.is_empty() and game.current==last-1,"campaign return clearsdaily")
	game.queue_free();await process_frame
	print("V6 real campaign: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)

class_name GameManager
extends Node
const Loader = preload("res://scripts/core/level_loader.gd")
const Grid = preload("res://scripts/core/grid_manager.gd")
const Progress = preload("res://scripts/core/progression_manager.gd")
signal changed
signal reaction_frame(frame: Dictionary)
signal finished(won: bool, stars: int)
signal feedback(kind: String)
var levels: Array = []
var grid: RefCounted = Grid.new()
var progress: RefCounted
var statistics: RefCounted
var settings: RefCounted
var current: int = 0
var daily_date: String=""
var daily_actions: Array=[]
var busy: bool = false
var paused: bool = false
var frame_seconds: float = 0.16
var epoch: int = 0
var error_message: String = ""

func _init(save_path: String = "user://progress.json") -> void:
	progress = Progress.new(preload("res://scripts/core/save_manager.gd").new(save_path))
	statistics = preload("res://scripts/core/statistics_manager.gd").new(progress)
	settings = preload("res://scripts/core/settings_manager.gd").new(progress)

func _ready() -> void:
	var loader := Loader.new()
	levels = loader.load_all()
	if not loader.errors.is_empty():
		error_message = "\n".join(loader.errors)
		changed.emit()
		return
	select_level(int(progress.data.last_level) - 1)

func select_level(index: int) -> void:
	if levels.is_empty(): return
	if not progress.chapter_unlocked(preload("res://scripts/core/chapter_catalog.gd").chapter_for_level(index + 1)): return
	flush_statistics()
	daily_date=""
	daily_actions=[]
	epoch += 1
	busy = false
	paused = false
	current = clampi(index, 0, levels.size() - 1)
	grid.load_level(levels[current])
	statistics.select(current+1)
	progress.select_level(current + 1)
	changed.emit()

func start_daily(date: String="") -> bool:
	var Daily=preload("res://scripts/core/daily_catalog.gd")
	if date.is_empty(): date=Time.get_date_string_from_system(false)
	var id: int=Daily.level_for_date(date)
	if id<1 or id>levels.size(): return false
	flush_statistics()
	epoch+=1
	busy=false
	paused=false
	daily_date=date
	current=id-1
	daily_actions=progress.data.daily_runs.get(date,{}).get("actions",[]).duplicate(true)
	var restored: RefCounted=Daily.replay(date,daily_actions,progress.data.daily_runs.get(date,{}).get("snapshot",{}))
	if restored==null:
		daily_actions=[]
		grid.load_level(levels[current])
	else: grid=restored
	changed.emit()
	if grid.status()=="won":
		var stars: int=3 if grid.used<=int(grid.level.get("par_launches",1)) else 2
		Daily.record(progress,daily_date,current+1,stars,grid.used)
		call_deferred("_restored_daily_win",epoch,stars)
	return true
func _restored_daily_win(ticket: int,stars: int) -> void:
	if ticket==epoch and not daily_date.is_empty() and grid.status()=="won": finished.emit(true,stars)
func restart() -> void:
	if not daily_date.is_empty():
		if not preload("res://scripts/core/daily_catalog.gd").save_run(progress,daily_date,[]):
			changed.emit()
			return
		start_daily(daily_date)
		return
	statistics.restart()
	select_level(current)

func undo() -> void:
	if busy or paused: return
	var before: Dictionary={"state":grid.state.duplicate(true),"history":grid.history.duplicate(true),"used":grid.used,"actions":daily_actions.duplicate(true)} if not daily_date.is_empty() else {}
	if grid.undo():
		if daily_date.is_empty(): statistics.undo()
		else:
			if not daily_actions.is_empty(): daily_actions.pop_back()
			if not preload("res://scripts/core/daily_catalog.gd").save_run(progress,daily_date,daily_actions):
				grid.state=before.state;grid.history=before.history;grid.used=before.used;daily_actions=before.actions
				changed.emit()
				return
		feedback.emit("undo")
		changed.emit()

func tap(index: int) -> void:
	if busy or paused or grid.level.is_empty() or grid.status() != "playing": return
	if index < 0 or index >= grid.level.nodes.size(): return
	if not daily_date.is_empty() and daily_actions.size()>=preload("res://scripts/core/daily_catalog.gd").MAX_ACTIONS: return
	if grid.level.nodes[index].type != "source":
		if grid.rotate(index):
			if daily_date.is_empty(): statistics.action("rotations")
			elif not _save_daily_action("rotate",index): return
			feedback.emit("rotate")
			changed.emit()
		else:
			feedback.emit("inspect")
		return
	var result: Dictionary = grid.launch(index)
	if not result.accepted: return
	if daily_date.is_empty(): statistics.action("launches")
	elif not _save_daily_action("launch",index): return
	busy = true
	var ticket: int = epoch
	# Visuals read immutable snapshots; the model already knows the final result.
	feedback.emit("launch")
	changed.emit()
	for frame in result.frames:
		if ticket != epoch: return
		reaction_frame.emit(frame)
		var elapsed: float = 0.0
		while elapsed < frame_seconds:
			await get_tree().process_frame
			if ticket != epoch: return
			if not paused: elapsed += get_process_delta_time()
	busy = false
	changed.emit()
	var status: String = grid.status()
	if status == "won":
		var stars: int = 3 if grid.used <= int(grid.level.get("par_launches", 1)) else 2
		if daily_date.is_empty():
			statistics.finish(true,stars,grid.used)
			flush_statistics()
			progress.complete(current + 1, stars)
		else:
			preload("res://scripts/core/daily_catalog.gd").record(progress,daily_date,current+1,stars,grid.used)
		feedback.emit("win")
		finished.emit(true, stars)
	elif status == "lost":
		if daily_date.is_empty(): statistics.finish(false,0,grid.used)
		flush_statistics()
		feedback.emit("lose")
		finished.emit(false, 0)

func next_level() -> void:
	select_level((current + 1) % levels.size())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		paused = true
		flush_statistics()
		changed.emit()

func action_rejection(index: int) -> String:
	if paused: return "Игра на паузе."
	if busy: return "Дождитесь завершения цепной реакции."
	if index < 0 or index >= grid.level.nodes.size(): return "Касание вне узлов."
	if grid.level.nodes[index].type != "source":
		if not grid.level.nodes[index].get("rotatable", false): return "Этот узел не поворачивается."
		if grid.used > 0: return "Повороты доступны только до первого запуска. Нажмите Restart или Undo, чтобы изменить решение."
	if not daily_date.is_empty() and daily_actions.size()>=preload("res://scripts/core/daily_catalog.gd").MAX_ACTIONS: return "История задачи дня заполнена. Отмените действие или начните заново."
	if grid.status() != "playing": return "Уровень завершён. Выберите следующий уровень, Restart или Undo."
	return ""

func _process(delta: float) -> void:
	if not paused and daily_date.is_empty(): statistics.tick(delta)
func flush_statistics() -> Error:
	return statistics.flush()

func _save_daily_action(kind: String,index: int) -> bool:
	daily_actions.append({"type":kind,"index":index})
	if not preload("res://scripts/core/daily_catalog.gd").save_run(progress,daily_date,daily_actions):
		daily_actions.pop_back()
		grid.undo()
		changed.emit()
		return false
	return true

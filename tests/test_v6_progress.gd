extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Catalog=preload("res://scripts/core/chapter_catalog.gd")
var failed:int=0
var passed:int=0
func check(ok:bool,message:String)->void:
	if ok: passed+=1
	else: failed+=1; push_error(message)
func _initialize()->void:
	check(Save.VERSION==4,"v6 schema4")
	check(Catalog.LEVEL_COUNT==100 and Catalog.LEVELS_PER_CHAPTER==25 and Catalog.CHAPTERS.size()==20,"100 shipped within 20x25 plan")
	var old:Dictionary={"version":3,"last_level":29,"completed":{"1":3,"19":2},"unlocked_chapters":[1,2,3],"sound":false,"reduced_effects":true,"achievements":{"first_light":true},"theme":"neon","statistics":{"levels":{"19":{"attempts":7}},"last_played_level":19}}
	var clean:Dictionary=Save.sanitize(old)
	check(clean.completed==old.completed and clean.last_level==29 and not clean.sound and clean.reduced_effects,"old progress/preferences retained")
	check(clean.unlocked_chapters==[1,2],"old chapter3 access maps to both newchapters")
	check(clean.statistics.levels["19"].attempts==7 and clean.achievements.first_light,"statistics/achievements retained")
	check(Save.sanitize(clean)==clean,"migration idempotent")
	var future:Dictionary=Save.sanitize({"version":4,"last_level":100,"unlocked_chapters":[1,2,3,4,20],"completed":{"101":3,"500":3}})
	check(not 20 in future.unlocked_chapters and future.completed.is_empty(),"future content cannot grant progress")
	var complete:Dictionary=old.duplicate(true)
	for id in range(1,51): complete.completed[str(id)]=3
	complete.theme="solar_gold"
	var migrated:Dictionary=Save.sanitize(complete)
	check(migrated.theme=="solar_gold" and migrated.unlocked_chapters==[1,2,3],"legacy campaign grants earned cosmetics and next available chapter")
	var save=Save.new("user://test-v6-migration.json")
	DirAccess.remove_absolute(save.path+".v3.bak")
	var file=FileAccess.open(save.path,FileAccess.WRITE)
	file.store_string(JSON.stringify(complete));file.close()
	var restored:Dictionary=save.read()
	check(restored.completed==complete.completed and FileAccess.file_exists(save.path+".v3.bak"),"actual version3 migration backs up original")
	print("V6 progress: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)

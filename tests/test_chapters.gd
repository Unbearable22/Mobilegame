extends SceneTree
const Save = preload("res://scripts/core/save_manager.gd")
const Progress = preload("res://scripts/core/progression_manager.gd")
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void:
	var save := Save.new("user://test-chapters.json")
	var file := FileAccess.open(save.path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"last_level":10,"completed":{"1":3,"10":2},"sound":false}))
	file.close()
	var old: Dictionary = save.read()
	check(old.version == Save.VERSION and old.completed["10"] == 2 and not old.sound and old.last_level == 10, "v1 migrates preserving all progress/settings")
	check(FileAccess.file_exists(save.path + ".v1.bak"), "v1 migration preserves backup")
	var p := Progress.new(save)
	check(p.chapter_unlocked(1) and not p.chapter_unlocked(2), "only first chapter initially")
	for id in range(1,11): p.complete(id,3)
	check(p.chapter_unlocked(2) and not p.chapter_unlocked(3), "next chapter unlocks only after ten wins")
	p.select_level(20)
	check(p.data.last_level == 20, "unlocked chapter levels selectable")
	p.select_level(21)
	check(p.data.last_level == 20, "locked selection refused")
	for id in range(11,51): p.complete(id,3)
	check(p.chapter_unlocked(5) and p.total_stars() == 150, "all five chapters and 150 stars")
	p.select_level(50)
	check(save.read().last_level == 50 and save.read().unlocked_chapters.size() == 5, "last chapter persists")
	var legacy: Dictionary = Save.sanitize({"version":2,"last_level":1,"completed":{"31":2},"unlocked_chapters":[1],"sound":true})
	check(4 in legacy.unlocked_chapters and legacy.completed["31"] == 2, "never relock already completed levels")
	print("Chapters: %d passed, %d failed" % [passed,failed])
	quit(1 if failed else 0)

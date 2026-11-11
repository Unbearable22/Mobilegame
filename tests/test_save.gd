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
func put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
func _initialize() -> void:
	var save := Save.new("user://test-progress.json")
	var data: Dictionary = Save.defaults()
	data.last_level = 7
	data.sound = false
	data.completed = {"1": 3, "7": 2}
	check(save.write(data) == OK, "save writes")
	check(save.read() == data, "save round trip")
	put(save.path, "{corrupt")
	check(save.read() == Save.defaults(), "corrupt save resets")
	check(FileAccess.file_exists(save.path + ".corrupt"), "corrupt file preserved")
	put(save.path, '{"version":999,"last_level":8}')
	check(save.read() == Save.defaults(), "unsupported save version resets")
	put(save.path, '{"version":1,"last_level":-3,"sound":"no","completed":{"1":100,"2":-1,"999":2}}')
	var clean: Dictionary = save.read()
	check(clean.last_level == 1 and clean.sound and clean.completed.is_empty(), "save values sanitized")
	var progress := Progress.new(save)
	progress.data = Save.defaults()
	progress.complete(1, 3)
	progress.complete(1, 2)
	check(progress.data.completed["1"] == 3, "best stars never decrease")
	check(progress.total_stars() == 3, "total stars")
	progress.select_level(10)
	check(save.read().last_level == 10, "selected level persists")
	for suffix in ["", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(save.path + suffix): DirAccess.remove_absolute(save.path + suffix)
	print("Save: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

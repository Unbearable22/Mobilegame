extends SceneTree
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	check(ProjectSettings.get_setting("display/window/handheld/orientation") == 1, "portrait config")
	check(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile") == "gl_compatibility", "mobile Compatibility renderer")
	for id in range(1, 11):
		check(FileAccess.file_exists("res://levels/%02d.json" % id), "packaged level %d exists" % id)
	var main: PackedScene = load("res://scenes/main.tscn")
	check(main != null, "packaged scene loads")
	if main:
		var ui: Control = main.instantiate()
		ui.save_path = "user://apk-smoke-progress.json"
		root.add_child(ui)
		for frame in range(5): await process_frame
		check(ui.game.levels.size() == 10 and ui.screen == "menu", "packaged game opens menu with 10 levels")
		ui.queue_free()
		await create_timer(0.3).timeout
	print("APK resource smoke: %d failures (desktop engine, not Android device)" % failed)
	quit(1 if failed else 0)

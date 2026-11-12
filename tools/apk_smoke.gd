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
	for id in range(1, 101):
		check(FileAccess.file_exists("res://levels/%02d.json" % id), "packaged level %d exists" % id)
	var main: PackedScene = load("res://scenes/main.tscn")
	check(main != null, "packaged scene loads")
	if main:
		var ui: Control = main.instantiate()
		ui.save_path = "user://apk-smoke-progress.json"
		root.add_child(ui)
		for frame in range(5): await process_frame
		check(ui.game.levels.size() == 100 and ui.screen == "menu", "packaged game opens menu with100levels")
		check(ui.main_menu.visible and ui.main_menu.reaction.is_processing(), "packaged menu animation starts")
		ui.main_menu.achievements_button.pressed.emit()
		check(ui.screen=="achievements" and ui.game.progress.achievement_status().size()==13,"packaged achievements screen")
		ui.back_overlay()
		ui.main_menu.themes_button.pressed.emit()
		check(ui.screen=="themes" and ui.retention_view.theme_buttons.size()==5,"packaged themes screen")
		ui.back_overlay()
		ui.show_reactor()
		check(ui.screen=="reactor","packaged reactor")
		ui.back_overlay()
		ui.show_daily()
		check(ui.screen=="daily","packaged daily")
		ui.back_overlay()
		ui.show_statistics()
		ui.statistics_export_path="user://apk-smoke-statistics.json"
		ui._export_statistics()
		check(ui.screen=="statistics_export" and FileAccess.file_exists(ui.statistics_export_path),"packaged local JSON export")
		ui.back_overlay()
		ui.back_overlay()
		ui.main_menu.continue_button.pressed.emit()
		check(ui.screen == "game" and not ui.main_menu.reaction.is_processing(), "packaged Continue stops decoration and opens game")
		ui.queue_free()
		await create_timer(0.3).timeout
	print("APK resource smoke: %d failures (desktop engine, not Android device)" % failed)
	quit(1 if failed else 0)

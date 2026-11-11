extends SceneTree
const Main = preload("res://scenes/main.tscn")
var passed: int = 0
var failed: int = 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func touch_control(control: Control) -> void:
	var point: Vector2 = root.get_screen_transform() * control.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.pressed = down
		event.position = point
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame

func run() -> void:
	var ui := Main.instantiate()
	ui.save_path = "user://test-settings.json"
	root.add_child(ui)
	await process_frame
	await touch_control(ui.buttons.settings)
	check(ui.screen == "settings" and ui.game.paused, "menu gear opens settings")
	var effects: CheckButton = ui.modal.get_child(2)
	effects.button_pressed = true
	ui._on_feedback("launch")
	await touch_control(effects)
	check(not ui.game.settings.sound_enabled() and not ui.sound_player.playing, "disable stops sound immediately")
	ui._on_feedback("win")
	check(not ui.sound_player.playing, "disabled effects stay silent")
	ui.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await create_timer(0.25).timeout
	check(ui.screen == "menu" and ui.game.paused, "Android Back settings restores menu")
	ui.close_overlay()
	await process_frame
	check(not ui.gear.get_global_rect().intersects(ui.stars_label.get_global_rect()), "gear does not cover stars")
	check(ui.get_viewport_rect().encloses(ui.gear.get_global_rect()), "gear within screen")
	ui.game.select_level(2)
	ui.buttons.settings.pressed.emit()
	check(ui.screen == "settings" and ui.game.paused, "in-game gear pauses")
	ui.close_settings()
	await create_timer(0.25).timeout
	check(ui.screen == "game" and not ui.game.paused, "close resumes game")
	ui.show_settings()
	ui.close_settings()
	ui.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ui.game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await create_timer(0.25).timeout
	check(ui.screen == "pause" and ui.game.paused, "background during close cannot resume game")
	ui.show_settings()
	ui.close_settings()
	await create_timer(0.25).timeout
	check(ui.screen == "pause" and ui.game.paused, "settings from pause stays paused")
	ui.close_overlay()
	ui.game.select_level(0)
	ui.game.frame_seconds = 0.08
	ui.game.tap(0)
	ui.show_settings()
	var state: Dictionary = ui.board.state.duplicate(true)
	await create_timer(0.1).timeout
	check(ui.game.busy and ui.board.state == state, "settings freeze animation")
	ui.close_settings()
	await create_timer(0.25).timeout
	while ui.game.busy: await process_frame
	check(ui.screen == "won", "settings resume reaches victory")
	ui.show_settings()
	ui.close_settings()
	await create_timer(0.25).timeout
	check(ui.screen == "won", "result restored")
	var storage: String = ui.save_path
	ui.queue_free()
	await create_timer(0.3).timeout
	ui = Main.instantiate()
	ui.save_path = storage
	root.add_child(ui)
	await process_frame
	check(not ui.game.settings.sound_enabled(), "sound setting survives app recreation/v1 save")
	ui.game.select_level(9)
	check(not ui.game.settings.sound_enabled(), "setting shared between levels")
	ui.game.settings.set_sound(true)
	ui._on_feedback("rotate")
	check(ui.sound_player.playing, "enable restores effects")
	ui.game.settings.set_sound(false)
	ui.queue_free()
	await create_timer(0.3).timeout
	print("Settings: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

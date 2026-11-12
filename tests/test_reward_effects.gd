extends SceneTree
var passed: int=0
var failed: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if ok: passed+=1
	else:
		failed+=1
		push_error(label)
func run() -> void:
	var path: String="user://test-reward-effects.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var ui: Control=load("res://scenes/main.tscn").instantiate()
	ui.start_in_menu=false
	ui.save_path=path
	root.add_child(ui)
	ui.game.frame_seconds=0
	ui.game.tap(0)
	var stars: Label=ui.modal.get_child(1)
	check(ui.screen=="won" and stars.revealed<3,"normal win starts sequential reveal")
	ui.game.settings.set_reduced_effects(true)
	check(stars.revealed==3 and not stars.reveal_tween.is_running(),"live reduced effects settles all stars")
	check(ui.modal.modulate.a==1 and not ui.modal_tween.is_running(),"live reduced effects settles modal fade")
	check(ui.achievement_toast.visible and ui.achievement_toast.modulate.a==1,"live reduced effects settles award fade")
	var state: Dictionary=ui.game.grid.state.duplicate(true)
	await create_timer(.25).timeout
	check(stars.revealed==3 and ui.game.grid.state==state,"settled reward never changes gameplay")
	ui.show_settings()
	ui.game.settings.set_reduced_effects(false)
	ui.close_settings()
	ui.game.settings.set_reduced_effects(true)
	check(ui.screen=="won" and not ui.settings_closing,"effect change during settings close restores parent")
	ui.queue_free()
	await create_timer(.2).timeout
	print("Reward effects: %d passed, %d failed"%[passed,failed])
	quit(1 if failed else 0)

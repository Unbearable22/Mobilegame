extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.save_path = "user://capture-progress.json"
	root.add_child(scene)
	scene.game.progress.data = preload("res://scripts/core/save_manager.gd").defaults()
	scene.game.select_level(9)
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshot.png")
	quit()

extends SceneTree
const Themes=preload("res://scripts/core/theme_catalog.gd")
var ui:Control
var failed:int=0
var checks:int=0
var prefix:String
var save_path:String
var report:Dictionary={"themes":{},"scope":"Real Godot OpenGL on Linux; physical Android not used"}
func _initialize()->void: call_deferred("run")
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:
		failed+=1
		push_error(label)
func touch(control:Control)->void:
	await process_frame
	await process_frame
	var point:Vector2=root.get_screen_transform()*control.get_global_rect().get_center()
	for down in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.position=point
		event.pressed=down
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
func boot()->void:
	ui=load("res://scenes/main.tscn").instantiate()
	ui.save_path=save_path
	root.add_child(ui)
	ui.game.settings.set_sound(false)
	ui.game.settings.set_reduced_effects(true)
	for i in range(5): await process_frame
func colors_match(image:Image,palette:Dictionary)->bool:
	# Sample actual framebuffer, not style/variable values. Background occupies
	# large regions; accent covers button borders and canonical node symbols.
	var background:int=0
	var accent:int=0
	for y in range(0,image.get_height(),3):
		for x in range(0,image.get_width(),3):
			var pixel:Color=image.get_pixel(x,y)
			if pixel.is_equal_approx(palette.background): background+=1
			if pixel.is_equal_approx(palette.accent): accent+=1
	return background>image.get_width()*image.get_height()/900 and accent>10
func region_count(image:Image,rect:Rect2,color:Color)->int:
	var count:int=0
	var pixels:Rect2i=Rect2i(root.get_screen_transform()*rect).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	for y in range(pixels.position.y,pixels.end.y,2):
		for x in range(pixels.position.x,pixels.end.x,2):
			if image.get_pixel(x,y).is_equal_approx(color): count+=1
	return count
func capture(id:String,screen:String)->Image:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	var image:Image=root.get_texture().get_image()
	var palette:Dictionary=Themes.palette(id)
	check(colors_match(image,palette),id+" real pixels "+screen)
	check(image.get_pixel(4,4).is_equal_approx(palette.background),id+" outer background region "+screen)
	if screen=="game":
		var area:Rect2=ui.board.get_global_rect()
		check(region_count(image,area,palette.surface)>100,id+" node surfaces in board region")
		check(region_count(image,area,palette.target)>3,id+" target symbols in board region")
		check(region_count(image,area,palette.battery)>3,id+" battery symbols in board region")
	else:
		check(region_count(image,ui.main_menu.continue_button.get_global_rect(),palette.surface)>100,id+" menu button surface region")
	check(image.get_size()==DisplayServer.window_get_size(),"native image size")
	image.save_png("res://docs/screenshots/v6theme-%s-%s-%s.png"%[prefix,screen,id])
	return image
func run()->void:
	prefix="%dx%d"%[DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	save_path="user://v6theme-render-%s.json"%prefix
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	await boot()
	for id in range(1,51): ui.game.progress.complete(id,3)
	var baseline:Image
	for entry in Themes.THEMES:
		ui.show_themes()
		await touch(ui.retention_view.theme_buttons[entry.id])
		check(ui.game.settings.theme_id()==entry.id,"native button selected "+entry.id)
		await RenderingServer.frame_post_draw
		check(region_count(root.get_texture().get_image(),ui.modal_panel.get_global_rect(),Themes.palette(entry.id).surface)>100,"rendered modal surface "+entry.id)
		ui.close_overlay()
		ui.game.select_level(49)
		var image:Image=await capture(entry.id,"game")
		if entry.id=="neon": baseline=image
		else: check(not colors_match(baseline,Themes.palette(entry.id)),"negative control rejects frozen Neon framebuffer for "+entry.id)
		ui.show_main_menu()
		await capture(entry.id,"menu")
		var selected:String=ui.game.settings.theme_id()
		ui.queue_free()
		await process_frame
		await boot()
		check(ui.game.settings.theme_id()==selected,"cold scene reload persisted "+selected)
		check(colors_match(root.get_texture().get_image(),Themes.palette(selected)),"recreated menu rendered "+selected)
		report.themes[entry.id]={"persisted":ui.game.settings.theme_id(),"palette":str(Themes.palette(selected))}
	ui.show_statistics()
	ui._export_statistics()
	await touch(ui.modal.get_child(3))
	check(DisplayServer.clipboard_get()==ui.statistics_export_text,"JSON copied")
	check(ui.modal.get_child(3).text.contains("Скопировано"),"visible copy confirmation")
	report.checks=checks
	report.failures=failed
	var file:=FileAccess.open("res://docs/screenshots/v6theme-%s-report.json"%prefix,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	ui.queue_free()
	await process_frame
	print("V6 theme rendered/native %s: %d checks, %d failures"%[prefix,checks,failed])
	quit(1 if failed else 0)

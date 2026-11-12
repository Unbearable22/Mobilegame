extends SceneTree
const Themes=preload("res://scripts/core/theme_catalog.gd")
const Settings=preload("res://scripts/core/settings_manager.gd")
class FailingSave extends RefCounted:
	func write(_data:Dictionary)->Error: return ERR_CANT_CREATE
class Progress extends RefCounted:
	var data:Dictionary={"theme":"neon","completed":{}}
	var save=FailingSave.new()
	var last_error:Error=OK
var failures:int=0
func _initialize()->void:
	var backgrounds:Dictionary={}
	for entry in Themes.THEMES:
		var colors:Dictionary=Themes.palette(entry.id)
		for role in ["background","surface","accent","secondary","border","energy","active_node","inactive_node","target","battery","text"]:
			if not colors.get(role) is Color:
				failures+=1
				push_error(entry.id+" missing palette role "+role)
		backgrounds[colors.background.to_html()]=true
	if backgrounds.size()!=5:
		failures+=1
		push_error("Each theme must have a distinct rendered background")
	var progress=Progress.new()
	for id in range(1,51): progress.data.completed[str(id)]=3
	var settings=Settings.new(progress)
	if settings.set_theme("electric_blue") or settings.theme_id()!="neon" or settings.active_palette!=Themes.palette("neon"):
		failures+=1
		push_error("Failed persistence must preserve theme and palette")
	print("Theme contract: %d failures"%failures)
	quit(1 if failures else 0)

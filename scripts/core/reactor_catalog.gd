class_name ReactorCatalog
extends RefCounted
const Catalog=preload("res://scripts/core/chapter_catalog.gd")
static func sectors(data:Dictionary)->Array:
	var result:Array=[]
	var completed:Dictionary=data.get("completed",{})
	for chapter in range(1,Catalog.AVAILABLE_CHAPTERS+1):
		var full:bool=true
		for id in range((chapter-1)*25+1,chapter*25+1):
			if not completed.has(str(id)): full=false
		if full: result.append(chapter)
	return result
static func sanitize(raw:Variant,data:Dictionary)->Dictionary:
	var earned:Array=sectors(data)
	var pulse:String="standard"
	var style:String="orbital"
	if raw is Dictionary:
		if raw.get("pulse_style")=="braided" and 3 in earned: pulse="braided"
		if raw.get("reactor_style")=="prismatic" and 4 in earned: style="prismatic"
	return {"sectors":earned,"pulse_style":pulse,"reactor_style":style,
		"rewards":{"legacy_themes":1 in earned,"solar_gold":2 in earned,"braided":3 in earned,"prismatic":4 in earned}}
static func select(progress:RefCounted,key:String,value:String)->bool:
	if not key in ["pulse_style","reactor_style"]: return false
	var candidate:Dictionary=progress.data.duplicate(true)
	candidate.reactor[key]=value
	var sanitized:Dictionary=sanitize(candidate.reactor,candidate)
	if sanitized[key]!=value: return false
	candidate.reactor=sanitized
	progress.last_error=progress.save.write(candidate)
	if progress.last_error!=OK: return false
	progress.data.reactor=sanitized
	return true

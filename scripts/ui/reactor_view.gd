extends Control
const Catalog=preload("res://scripts/core/reactor_catalog.gd")
var palette:Dictionary
var completed:Array=[]
var prismatic:bool=false
func _init(colors:Dictionary,data:Dictionary)->void:
	palette=colors
	completed=Catalog.sectors(data)
	prismatic=data.reactor.reactor_style=="prismatic"
	custom_minimum_size=Vector2(0,500)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _ready()->void: resized.connect(queue_redraw)
func _draw()->void:
	var center:Vector2=size*.5
	var radius:float=minf(size.x*.38,size.y*.43)
	for sector in range(20):
		var start:float=-PI*.5+TAU*sector/20+.035
		var end:float=start+TAU/20-.07
		var color:Color=palette.energy if sector+1 in completed else palette.border
		var thickness:float=22 if sector+1 in completed else 12
		draw_arc(center,radius,start,end,12,color,thickness,true)
		if prismatic: draw_arc(center,radius-28,start,end,12,palette.secondary,3,true)
	var label:String="%d / 20"%completed.size()
	var font:Font=ThemeDB.fallback_font
	var extent:Vector2=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,48)
	draw_string(font,center-Vector2(extent.x*.5,-16),label,HORIZONTAL_ALIGNMENT_LEFT,-1,48,palette.text)

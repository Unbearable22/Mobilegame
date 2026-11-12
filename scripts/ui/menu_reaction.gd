class_name MenuReaction
extends Control
# Cosmetic only: no GameManager, save, input or solver references.
var CYAN: Color = Color("4de6f5")
var node_surface: Color=Color("142137")
var energy: Color=Color("e4fdff")
var VIOLET: Color = Color("aa8bfa")
const POINTS: Array[Vector2] = [Vector2(.13,.50),Vector2(.37,.50),Vector2(.37,.20),Vector2(.63,.20),Vector2(.63,.50),Vector2(.63,.80),Vector2(.87,.50)]
const LINKS: Array[Vector2i] = [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(1,4),Vector2i(4,5),Vector2i(4,6)]
var active: bool = false
var reduced_effects: bool = false
var phase: float = 0.0
var draw_count: int = 0
var last_draw_usec: int = 0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	set_process(false)
func configure_visuals(palette: Dictionary,reduced: bool) -> void:
	CYAN = palette.accent
	node_surface=palette.surface
	energy=palette.energy
	VIOLET = palette.secondary
	reduced_effects = reduced
	set_process(active and not reduced_effects)
	queue_redraw()
func set_active(value: bool) -> void:
	active = value
	set_process(active and not reduced_effects)
func _process(delta: float) -> void:
	phase += delta
	queue_redraw()
func point(index: int) -> Vector2:
	# Preserve diagram proportions on extra-tall phones.
	var extent := Vector2(size.x,minf(size.y,660.0))
	return (size-extent)*0.5 + POINTS[index]*extent
func _draw() -> void:
	var began: int = Time.get_ticks_usec()
	var radius: float = minf(size.x*.043,43)
	var center := size*.5
	var orbit: float = minf(size.x*.37,size.y*.46)
	draw_arc(center,orbit,0,TAU,96,Color(CYAN,.055),1.5,true)
	draw_arc(center,orbit*1.10,-.6,.2,16,Color(VIOLET,.25),2,true)
	draw_arc(center,orbit*1.10,PI-.6,PI+.2,16,Color(CYAN,.25),2,true)
	for i in range(LINKS.size()):
		var edge: Vector2i = LINKS[i]
		var a: Vector2 = point(edge.x)
		var b: Vector2 = point(edge.y)
		var color: Color = VIOLET if i in [2,3,5] else CYAN
		draw_line(a,b,Color(color,.15),3,true)
		var t: float = fposmod(phase*.38-float(i)*.17,1.5)
		if t <= 1.0 and not reduced_effects:
			var head: Vector2 = a.lerp(b,t)
			draw_line(a.lerp(b,maxf(0,t-.22)),head,Color(color,.65),4,true)
			draw_circle(head,12,Color(color,.07))
			draw_circle(head,7,Color(color,.19))
			draw_circle(head,3.5,energy)
	for i in range(POINTS.size()):
		var p: Vector2 = point(i)
		var color: Color = VIOLET if i in [2,3,5] else CYAN
		var intensity: float = .35 if reduced_effects else .5+.5*sin(phase*2.3-i*.8)
		for layer in range(0 if reduced_effects else 3,0,-1):
			draw_circle(p,radius*(1+layer*.24),Color(color,(.018+intensity*.012)))
		draw_circle(p,radius,node_surface)
		draw_arc(p,radius,0,TAU,40,Color(color,.55+intensity*.4),2.5,true)
		if i == 0:
			draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-15),p+Vector2(17,0),p+Vector2(-10,15)]),color)
		elif i == 6:
			var diamond := PackedVector2Array([p+Vector2(0,-17),p+Vector2(17,0),p+Vector2(0,17),p+Vector2(-17,0),p+Vector2(0,-17)])
			draw_polyline(diamond,color,3,true)
		else:
			draw_circle(p,7,color)
			for direction in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
				draw_line(p+direction*17,p+direction*24,Color(color,.75),2,true)
	# Eight deterministic motes: fixed memory and no particles/shader/fullscreen blur.
	for i in range(0 if reduced_effects else 8):
		var t: float = phase*.16+i*.7854
		var p: Vector2 = center+Vector2(cos(t)*size.x*.42,sin(t*1.7+i)*minf(size.y,660)*.43)
		draw_circle(p,1.5,Color(CYAN,.18))
	draw_count += 1
	last_draw_usec = Time.get_ticks_usec()-began

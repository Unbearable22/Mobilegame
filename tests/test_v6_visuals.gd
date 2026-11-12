extends SceneTree
## Render the production Board; fail on missing timing feedback or identical new glyphs.
const Board = preload("res://scripts/ui/board.gd")
const Guide = preload("res://scripts/ui/node_guide.gd")
const Model = preload("res://scripts/core/reaction_engine_v6.gd")
const Themes = preload("res://scripts/core/theme_catalog.gd")
var passed: int = 0
var failed: int = 0
var rendered: int = 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error(label)

func _initialize() -> void: call_deferred("run")

func fixture() -> Dictionary:
	return {"width":4,"height":2,"nodes":[
		{"x":0,"y":0,"type":"reflector","rotatable":true},
		{"x":1,"y":0,"type":"portal","pair_id":"same","dirs":[1]},
		{"x":3,"y":1,"type":"portal","pair_id":"same","dirs":[0,3]},
		{"x":2,"y":0,"type":"and_gate","dirs":[1],"rotatable":true},
		{"x":0,"y":1,"type":"delay","dirs":[1],"delay_ticks":3}]}

func run() -> void:
	var board = Board.new()
	root.add_child(board)
	board.show_frame({"tick":0,"nodes":[0],"edges":[],"state":{"rotations":[0],"charges":[0],"active":[true]}})
	check(board.reaction_tick == -1 and board.level.is_empty(),"unconfigured/hidden Board ignores frames safely")
	check(board.has_method("configure_cosmetics"),"Board supports earned pulse appearance")
	if board.has_method("configure_cosmetics"):
		board.call("configure_cosmetics","braided")
		check(board.get("pulse_style") == "braided","earned braided pulse style accepted")
		board.call("configure_cosmetics","unknown")
		check(board.get("pulse_style") == "standard","unknown pulse style falls back safely")
	var level: Dictionary = fixture()
	var state: Dictionary = Model.initial_state(level)
	board.show_state(level,state,false)
	for resolution in [Vector2(720,1280),Vector2(1080,1920),Vector2(1440,3200)]:
		board.size = Vector2(resolution.x*0.92,resolution.y*0.50)
		var geometry: Dictionary = board.geometry()
		for i in range(level.nodes.size()):
			var p: Vector2 = board.center(i)
			check(Rect2(Vector2.ZERO,board.size).has_point(p),"new glyph center fits %s node%d" % [resolution,i])
			check(p.x >= geometry.cell*0.4 and p.y >= geometry.cell*0.4,"glyph including exit arrows has edge margin")
	var found: Dictionary = {}
	for card in Guide.CARDS:
		if card.type in ["reflector","portal","and_gate","delay"]: found[card.type] = true
	check(found.size() == 4,"guide documents exactly four implemented new types")
	var guide = Guide.new()
	check(guide.has_method("preview_level"),"guide supplies canonical per-type Board fixture")
	if guide.has_method("preview_level"):
		for kind in ["reflector","portal","and_gate","delay"]:
			var preview: Dictionary = guide.call("preview_level",kind)
			check(preview.nodes[0].type == kind,"preview first glyph agrees with guide type")
			if kind == "portal": check(preview.nodes.size() == 2 and preview.nodes[0].pair_id == preview.nodes[1].pair_id,"guide portal has a real matching pair")
			if kind == "delay": check(preview.nodes[0].delay_ticks in [1,2,3],"guide delay has explicit duration")
	# One real arrival lights only one AND input; virtual transport never counts as an input.
	board.size = Vector2(800,500)
	board.show_frame({"tick":1,"state":state,"nodes":[],"edges":[{"from":0,"to":3,"direction":1},{"from":2,"to":3,"direction":-1,"kind":"portal"}]})
	var inputs: Variant = board.get("and_inputs")
	check(inputs is Dictionary and inputs.get(3,0) == 1,"AND shows a real one-input partial state")
	state.active[4] = true
	board.show_frame({"tick":2,"state":state,"nodes":[4],"edges":[],"released":[]})
	var waits: Variant = board.get("delay_waits")
	check(waits is Dictionary and waits.get(4,-1) == 3,"delay activation displays full pending duration")
	board.show_frame({"tick":3,"state":state,"nodes":[],"edges":[],"released":[]})
	waits = board.get("delay_waits")
	check(waits is Dictionary and waits.get(4,-1) == 2,"empty tick decrements visible delay countdown")
	board.configure_visuals(Themes.palette("neon"),true)
	waits = board.get("delay_waits")
	check(waits is Dictionary and waits.get(4,-1) == 2,"reduced effects retain logical countdown")
	board.show_frame({"tick":5,"state":state,"nodes":[],"edges":[],"released":[4]})
	waits = board.get("delay_waits")
	check(waits is Dictionary and not waits.has(4),"release clears pending countdown")
	check(board.tween == null,"reduced effects create no animation timer")
	board.show_state(level,Model.initial_state(level),false)
	waits = board.get("delay_waits")
	inputs = board.get("and_inputs")
	check(waits is Dictionary and waits.is_empty() and inputs is Dictionary and inputs.is_empty(),"Undo/Restart clears transient new-node state")
	for step in range(25):
		var point: Vector2 = board._portal_point(board.center(1),board.center(2),float(step)/24.0)
		check(Rect2(Vector2.ZERO,board.size).has_point(point),"portal curve stays inside Board bounds")
	if DisplayServer.get_name() != "headless":
		await check_rendered_glyphs(board)
		await check_pulse_render(board)
	board.queue_free()
	await process_frame
	print("V6 visuals: %d passed, %d failed; %d rendered glyphs (%s)" % [passed,failed,rendered,DisplayServer.get_name()])
	quit(1 if failed else 0)

func check_rendered_glyphs(board: Control) -> void:
	board.size = Vector2(500,500)
	board.position = Vector2(20,20)
	for theme in Themes.THEMES:
		var signatures: Dictionary = {}
		for kind in ["normal","reflector","portal","and_gate","delay"]:
			var n: Dictionary = {"x":0,"y":0,"type":kind,"dirs":[1],"delay_ticks":2,"pair_id":"p1"}
			var level: Dictionary = {"width":1,"height":1,"nodes":[n]}
			board.configure_visuals(Themes.palette(theme.id),true)
			board.show_state(level,Model.initial_state(level),false)
			await process_frame
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var center: Vector2 = board.position+board.center(0)
			# Root is stretched to reference size; map canvas coordinates to texture pixels.
			var scale: Vector2 = Vector2(image.get_size())/root.get_visible_rect().size
			var rect := Rect2i((center-Vector2(180,180))*scale,Vector2(360,360)*scale)
			var glyph: Image = image.get_region(rect)
			var signature: int = hash(glyph.get_data())
			check(not signatures.has(signature),"actual %s glyph differs in theme %s" % [kind,theme.id])
			signatures[signature] = kind
			if kind != "normal":
				var role: String = "target" if kind == "and_gate" else "secondary"
				var wanted: Color = Themes.palette(theme.id)[role]
				var colored: int = 0
				for y in range(glyph.get_height()):
					for x in range(glyph.get_width()):
						var pixel: Color = glyph.get_pixel(x,y)
						if absf(pixel.r-wanted.r)+absf(pixel.g-wanted.g)+absf(pixel.b-wanted.b) < 0.04: colored += 1
				check(colored > 3,"actual %s glyph uses %s palette in %s" % [kind,role,theme.id])
			rendered += 1


func check_pulse_render(board: Control) -> void:
	var level: Dictionary = {"width":2,"height":1,"nodes":[{"x":0,"y":0,"type":"source","dirs":[1]},{"x":1,"y":0,"type":"target"}]}
	var snapshot: Dictionary = Model.initial_state(level)
	board.size = Vector2(800,400)
	board.configure_visuals(Themes.palette("neon"),true)
	board.show_state(level,snapshot,false)
	var signatures: Array = []
	for style in ["standard","braided"]:
		board.configure_cosmetics(style)
		board.show_frame({"tick":1,"state":snapshot,"nodes":[],"edges":[{"from":0,"to":1,"direction":1}]})
		await process_frame
		await RenderingServer.frame_post_draw
		signatures.append(hash(root.get_texture().get_image().get_data()))
		check(board.tween == null and board.state == snapshot,"cosmetic pulse respects reduced effects and state")
	check(signatures[0] != signatures[1],"earned braided pulse changes actual rendered strands")

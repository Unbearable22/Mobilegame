class_name UIManager
extends Control
const Game = preload("res://scripts/core/game_manager.gd")
const Board = preload("res://scripts/ui/board.gd")
var CYAN: Color = Color("4de6f5")
const Catalog = preload("res://scripts/core/chapter_catalog.gd")
const Icons = preload("res://scripts/ui/icon_library.gd")
const Guide = preload("res://scripts/ui/node_guide.gd")
const Themes = preload("res://scripts/core/theme_catalog.gd")
const Retention = preload("res://scripts/ui/retention_view.gd")
const Stars = preload("res://scripts/ui/reward_stars.gd")
const Menu = preload("res://scripts/ui/main_menu.gd")
var MUTED: Color = Color("92a7c2")
@export var save_path: String = "user://progress.json"
var game: Node
var board: Control
var buttons: Dictionary = {}
var overlay: ColorRect
var modal: VBoxContainer
var title_label: Label
var phase_label: Label
var count_label: Label
var targets_label: Label
var hint_label: Label
var stars_label: Label
var margin: MarginContainer
var sound_player: AudioStreamPlayer
var sounds: Dictionary = {}
var screen: String = "game"
var return_screen: String = "game"
var result_stars: int = 0
var settings_return_screen: String = "game"
var settings_closing: bool = false
var modal_tween: Tween
var gear: Button
var info: Button
var selected_chapter: int = 1
var levels_parent: String = "game"
var guide_page: int = 0
var guide_parent: String = "game"
var guide_preview: Control
var notice_tween: Tween
var main_menu: Control
var retention_view: Control
var retention_parent: String = "menu"
var achievement_page: int = 0
var statistics_export_path: String = "user://chain-react-statistics.json"
var statistics_export_text: String = ""
var pending_achievements: Array = []
var achievement_toast: PanelContainer
var achievement_message: Label
var achievement_tween: Tween
var palette: Dictionary = Themes.palette("neon")
@export var start_in_menu: bool = true

func _ready() -> void:
	get_tree().quit_on_go_back = false
	_build_theme()
	_build_screen()
	_build_overlay()
	_build_main_menu()
	_build_audio()
	_build_gear()
	_build_achievement_toast()
	game = Game.new(save_path)
	game.changed.connect(refresh)
	game.reaction_frame.connect(_show_reaction_frame)
	game.finished.connect(show_result)
	game.feedback.connect(_on_feedback)
	board.node_pressed.connect(_tap_node)
	board.pointer_observed.connect(_pointer_observed)
	game.settings.changed.connect(_settings_changed)
	game.progress.achievements_unlocked.connect(_queue_achievements)
	add_child(game)
	_apply_visuals()
	get_viewport().size_changed.connect(_safe_area)
	_safe_area()
	buttons.levels.grab_focus()
	if start_in_menu and game.error_message.is_empty(): show_main_menu()

func _build_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 42
	t.set_color("icon_normal_color","Button",CYAN)
	t.set_color("icon_hover_color","Button",palette.energy)
	t.set_color("icon_focus_color","Button",CYAN)
	t.set_color("icon_pressed_color","Button",palette.energy)
	t.set_color("icon_disabled_color","Button",palette.muted.darkened(.5))
	t.set_color("font_color","Label",palette.text)
	t.set_color("font_color", "Label", Color("edf6ff"))
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = palette.surface if state_name != "pressed" else palette.surface.lightened(.1)
		box.border_color = CYAN if state_name in ["hover", "focus"] else palette.muted.darkened(.6)
		box.set_border_width_all(2)
		box.set_corner_radius_all(22)
		box.content_margin_left = 22
		box.content_margin_right = 22
		box.content_margin_top = 15
		box.content_margin_bottom = 15
		t.set_stylebox(state_name, "Button", box)
	t.set_color("font_color", "Button", Color("e4f5ff"))
	t.set_color("font_disabled_color", "Button", Color("52657e"))
	theme = t

func _label(text: String, font_size: int, color: Color = Color("edf6ff")) -> Label:
	var label := Label.new()
	label.text = text
	var role: String = "accent" if color==CYAN else ("muted" if color==MUTED else ("target" if color in [Color("b5f3a0"),Color("a5f3a3")] else "text"))
	label.set_meta("palette_role",role)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, action: Callable, key: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 144
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.button_down.connect(func(): button.modulate = Color("a3eafa"))
	button.button_up.connect(func(): button.modulate = Color.WHITE)
	button.pressed.connect(action)
	if not key.is_empty(): buttons[key] = button
	return button

func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	return row

func _icon_button(symbol: String, label: String, action: Callable, key: String = "") -> Button:
	var button: Button = _button("", action, key)
	button.icon = Icons.icon(symbol)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 64)
	button.custom_minimum_size = Vector2(144,144)
	button.tooltip_text = label
	button.set_meta("semantic_label", label)
	return button

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("080f20")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var header := _row()
	header.custom_minimum_size.y = 144
	phase_label = _label("", 44)
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(phase_label)
	stars_label = _label("", 34, Color("b5f3a0"))
	header.add_child(stars_label)
	var reserved := Control.new()
	reserved.custom_minimum_size.x = 312
	header.add_child(reserved)
	column.add_child(header)
	title_label = _label("", 36, MUTED)
	title_label.hide()
	column.add_child(title_label)
	var stats := _row()
	count_label = _label("", 42, CYAN)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(count_label)
	targets_label = _label("", 42, Color("b5f3a0"))
	stats.add_child(targets_label)
	column.add_child(stats)
	board = Board.new()
	board.custom_minimum_size = Vector2(0,550)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(board)
	hint_label = _label("", 36, MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.hide()
	column.add_child(hint_label)
	var actions := _row()
	actions.add_child(_icon_button("undo", "Отменить действие", func(): game.undo(), "undo"))
	actions.add_child(_icon_button("restart", "Начать заново", func(): close_overlay(); game.restart(), "restart"))
	actions.add_child(_icon_button("pause", "Пауза", show_pause, "pause"))
	actions.add_child(_icon_button("chapters", "Главы", show_chapters, "levels"))
	column.add_child(actions)

func _build_main_menu() -> void:
	main_menu = Menu.new()
	overlay.add_child(main_menu)
	main_menu.continued.connect(_continue_from_menu)
	main_menu.chapters_requested.connect(show_chapters)
	main_menu.achievements_requested.connect(show_achievements)
	main_menu.themes_requested.connect(show_themes)

func _continue_from_menu() -> void:
	var selected: int = int(game.progress.data.last_level)-1
	if selected != game.current: game.select_level(selected)
	close_overlay()

func _safe_area() -> void:
	var left: int = 48
	var right: int = 48
	var top: int = 44
	var bottom: int = 36
	if OS.has_feature("android") or OS.has_feature("ios"):
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var window: Vector2i = DisplayServer.window_get_size()
		var logical: Vector2 = get_viewport_rect().size
		if window.x > 0 and window.y > 0 and safe.size.x > 0:
			left += int(safe.position.x * logical.x / window.x)
			right += int((window.x - safe.end.x) * logical.x / window.x)
			top += int(safe.position.y * logical.y / window.y)
			bottom += int((window.y - safe.end.y) * logical.y / window.y)
	for pair in [["left", left], ["right", right], ["top", top], ["bottom", bottom]]:
		margin.add_theme_constant_override("margin_" + pair[0], pair[1])
	if main_menu: main_menu.apply_insets(left,top,right,bottom)
	if achievement_toast:
		achievement_toast.offset_left = left
		achievement_toast.offset_right = -right
		achievement_toast.offset_top = -bottom-240
		achievement_toast.offset_bottom = -bottom-32
	if gear:
		gear.offset_left = -right - 144
		gear.offset_right = -right
		gear.offset_top = top
		gear.offset_bottom = top + 144
	if info:
		info.offset_left = -right - 300
		info.offset_right = -right - 156
		info.offset_top = top
		info.offset_bottom = top + 144

func refresh() -> void:
	if main_menu and game: main_menu.update_progress(game.progress.data,game.progress.total_stars())
	if not game.error_message.is_empty():
		_open_modal("Не удалось загрузить уровни")
		modal.add_child(_label(game.error_message, 24))
		return
	if game.grid.level.is_empty(): return
	var level: Dictionary = game.grid.level
	title_label.text = level.name
	var chapter: int = Catalog.chapter_for_level(game.current + 1)
	phase_label.text = "%s · %02d / 10" % [Catalog.CHAPTERS[chapter-1].number,game.current % 10 + 1]
	phase_label.add_theme_color_override("font_color", Color(Catalog.CHAPTERS[chapter-1].color))
	count_label.text = "▶ %d / %d" % [int(level.launches)-game.grid.used,int(level.launches)]
	var total: int = 0
	var active: int = 0
	for i in range(level.nodes.size()):
		if level.nodes[i].type == "target":
			total += 1
			if (board.state if game.busy and not board.state.is_empty() else game.grid.state).active[i]: active += 1
	targets_label.text = "◇  %d / %d" % [active, total]
	stars_label.text = "★ %d" % game.progress.total_stars()
	if game.progress.last_error != OK: _notice("Не удалось сохранить прогресс.")
	elif not game.progress.save.warning.is_empty(): _notice(game.progress.save.warning)
	buttons.undo.disabled = game.busy or game.grid.history.is_empty() or game.paused

	if not game.busy:
		board.rotation_available = game.grid.used == 0
		board.show_state(level, game.grid.state, game.paused)
	else:
		board.locked = true
	if game.paused and not overlay.visible: show_pause()

func _tap_node(index: int) -> void:
	var kind: String = game.grid.level.nodes[index].type
	var before: Array = _directions(index)
	var rejection: String = game.action_rejection(index)
	game.tap(index)
	_trace({"stage": "action", "index": index, "type": kind, "rotation_allowed": rejection.is_empty() and kind != "source", "before": before, "after": _directions(index), "reason": rejection if not rejection.is_empty() else "accepted"})
	if not rejection.is_empty(): _notice(rejection)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.015, 0.025, 0.06, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var center_container := CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_container)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 850
	var box := StyleBoxFlat.new()
	box.bg_color = Color("101e33")
	box.border_color = Color("385774")
	box.set_border_width_all(2)
	box.set_corner_radius_all(36)
	box.content_margin_left = 44
	box.content_margin_right = 44
	box.content_margin_top = 44
	box.content_margin_bottom = 44
	panel.add_theme_stylebox_override("panel", box)
	center_container.add_child(panel)
	modal = VBoxContainer.new()
	modal.add_theme_constant_override("separation", 24)
	panel.add_child(modal)
	overlay.hide()

func _open_modal(title: String) -> void:
	_hide_achievement_toast()
	if main_menu: main_menu.set_active(false)
	overlay.get_child(0).show()
	gear.hide()
	info.hide()
	if modal_tween: modal_tween.kill()
	modal.modulate.a = 1.0
	for button in buttons.values():
		if is_instance_valid(button): button.focus_mode = Control.FOCUS_NONE
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	var heading := _label(title, 48, CYAN)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.add_child(heading)
	overlay.show()

func close_overlay() -> void:
	_hide_achievement_toast()
	if main_menu: main_menu.set_active(false)
	for button in buttons.values():
		if is_instance_valid(button): button.focus_mode = Control.FOCUS_ALL
	screen = "game"
	gear.show()
	info.show()
	margin.show()
	if board.tween: board.tween.play()
	overlay.hide()
	if game:
		game.paused = false
		refresh()

func show_pause() -> void:
	screen = "pause"
	game.paused = true
	game.flush_statistics()
	board.locked = true
	if board.tween: board.tween.pause()
	_open_modal("Пауза")
	modal.add_child(_label("Ваша цепь подождёт.", 32, MUTED))
	var resume := _icon_button("play", "Продолжить", func():
		if board.tween: board.tween.play()
		close_overlay())
	modal.add_child(resume)
	modal.add_child(_icon_button("restart", "Начать заново", func(): close_overlay(); game.restart()))
	modal.add_child(_icon_button("settings", "Настройки", show_settings))
	modal.add_child(_icon_button("home", "Главное меню", show_main_menu))
	resume.grab_focus()

func show_chapters() -> void:
	if screen != "chapters": return_screen = screen
	screen = "chapters"
	_pause_for_panel()
	_open_modal("Главы")
	for index in range(5):
		var chapter: Dictionary = Catalog.CHAPTERS[index]
		var progress: Dictionary = game.progress.chapter_progress(index+1)
		var text: String = "%s · %s\n%d / 10   ·   ★ %d / 30" % [chapter.number,chapter.name,progress.completed,progress.stars]
		var button: Button = _button(text, func(): selected_chapter = index+1; show_levels())
		button.disabled = not progress.unlocked
		if not progress.unlocked:
			button.text += "   ·   Закрыта"
			button.tooltip_text = "Пройдите предыдущую главу"
		else: button.add_theme_color_override("font_color",Color(chapter.color))
		modal.add_child(button)
	var back: Button = _icon_button("back", "Назад", back_overlay)
	modal.add_child(back)
	back.grab_focus()

func show_levels() -> void:
	if screen != "levels" and screen != "chapters":
		return_screen = screen
		selected_chapter = Catalog.chapter_for_level(game.current+1)
	levels_parent = "chapters"
	screen = "levels"
	_pause_for_panel()
	var chapter: Dictionary = Catalog.CHAPTERS[selected_chapter-1]
	_open_modal(chapter.number+" · "+chapter.name)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	modal.add_child(grid)
	for local_id in range(10):
		var index: int = (selected_chapter-1)*10+local_id
		var stars: int = int(game.progress.data.completed.get(str(index+1),0))
		var locked: bool = not game.progress.chapter_unlocked(selected_chapter)
		var button: Button = _button("%02d"%(index+1),func(): close_overlay(); game.select_level(index))
		button.custom_minimum_size = Vector2(144,168)
		button.add_theme_font_size_override("font_size",46)
		button.disabled = locked
		button.set_meta("current_level",game.current==index)
		button.set_meta("locked",locked)
		grid.add_child(button)
		if game.current==index:
			for state_name in ["normal","hover","focus"]:
				var style: StyleBoxFlat = button.get_theme_stylebox(state_name).duplicate()
				style.border_color = CYAN
				style.set_border_width_all(4)
				button.add_theme_stylebox_override(state_name,style)
		if locked:
			var icon := TextureRect.new()
			icon.texture = Icons.icon("lock")
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			icon.position = Vector2(-12,-32)
			icon.size = Vector2(24,24)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.modulate = palette.muted
			button.add_child(icon)
		elif stars>0:
			var badge: Label = _label("★".repeat(stars),24,palette.secondary)
			badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			badge.offset_top = -34
			badge.offset_bottom = -4
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(badge)
	var back: Button = _icon_button("back","К выбору глав",func(): screen="chapters"; show_chapters())
	modal.add_child(back)
	back.grab_focus()

func _pause_for_panel() -> void:
	game.paused = true
	game.flush_statistics()
	board.locked = true
	if board.tween: board.tween.pause()

func show_result(won: bool, stars: int) -> void:
	screen = "won" if won else "lost"
	result_stars = stars
	_open_modal("Цепь замкнулась!" if won else "Попробуем иначе?")
	var text: Label = Stars.new() if won else _label("Не все цели зажглись.",42,MUTED)
	text.add_theme_font_size_override("font_size",60 if won else 42)
	text.add_theme_color_override("font_color",palette.secondary if won else MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.add_child(text)
	if won:
		var next_index: int = (game.current+1) % game.levels.size()
		var can_next: bool = game.progress.chapter_unlocked(Catalog.chapter_for_level(next_index+1))
		var next: Button
		if can_next:
			next = _icon_button("next", "Следующий уровень" if game.current < 49 else "В начало", func(): close_overlay(); game.next_level())
		else:
			text.suffix = "\nЗавершите остальные уровни главы"
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			next = _icon_button("chapters","Завершить главу",show_chapters)
		modal.add_child(next)
		next.grab_focus()
	else:
		var undo := _icon_button("undo", "Отменить запуск", func(): close_overlay(); game.undo())
		modal.add_child(undo)
		undo.grab_focus()
	modal.add_child(_icon_button("restart", "Начать заново", func(): close_overlay(); game.restart()))
	modal.add_child(_icon_button("chapters", "Главы", show_chapters))
	stars_label.text = "★ %d" % game.progress.total_stars()
	if won: text.begin(stars,game.settings.reduced_effects_enabled())
	modal.modulate.a = 1.0 if game.settings.reduced_effects_enabled() else 0.0
	if not game.settings.reduced_effects_enabled():
		modal_tween = create_tween()
		modal_tween.tween_property(modal,"modulate:a",1.0,.22)
	if won: _show_achievement_toast()

func toggle_sound() -> void:
	game.settings.set_sound(not game.settings.sound_enabled())
	if game.settings.sound_enabled(): _on_feedback("rotate")

func _settings_changed(key: String) -> void:
	if key in ["theme","reduced_effects"]:
		_apply_visuals()
		if screen=="themes": show_themes()
	if key == "sound" and not game.settings.sound_enabled(): sound_player.stop()
	refresh()

func _build_audio() -> void:
	sound_player = AudioStreamPlayer.new()
	sound_player.volume_db = -17
	add_child(sound_player)
	for pair in [["rotate", 460.0], ["launch", 660.0], ["win", 880.0], ["lose", 220.0], ["undo", 330.0]]:
		var wave := AudioStreamWAV.new()
		wave.format = AudioStreamWAV.FORMAT_16_BITS
		wave.mix_rate = 22050
		var bytes := PackedByteArray()
		var count: int = 4410
		bytes.resize(count * 2)
		for i in range(count):
			var envelope: float = sin(PI * float(i) / count) * exp(-4.0 * float(i) / count)
			var sample: int = int(sin(TAU * float(pair[1]) * i / 22050.0) * envelope * 15000)
			bytes.encode_s16(i * 2, sample)
		wave.data = bytes
		sounds[pair[0]] = wave

func _on_feedback(kind: String) -> void:
	if game.settings.sound_enabled() and sounds.has(kind):
		sound_player.stream = sounds[kind]
		sound_player.play()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if screen != "game": back_overlay()
		else: show_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and game and screen in ["achievements","themes","statistics","statistics_export"] and retention_parent=="game": retention_parent="pause"
	if main_menu and what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]: main_menu.set_suspended(true)
	if main_menu and what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN]: main_menu.set_suspended(false)
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and game and settings_return_screen == "game" and (screen == "settings" or (screen in ["statistics","statistics_export"] and retention_parent=="settings")):
		settings_return_screen = "pause"
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and game and screen == "guide" and guide_parent == "game": guide_parent = "pause"
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and game:
		if screen != "game": back_overlay()
		else: show_pause()

func show_main_menu() -> void:
	screen = "menu"
	_pause_for_panel()
	margin.hide()
	_open_modal("")
	overlay.get_child(0).hide()
	main_menu.update_progress(game.progress.data,game.progress.total_stars())
	main_menu.set_active(true)
	gear.show()
	gear.focus_mode = Control.FOCUS_ALL
	info.show()
	info.focus_mode = Control.FOCUS_ALL
	main_menu.continue_button.grab_focus()

func back_overlay() -> void:
	if screen == "settings":
		close_settings()
	elif screen == "guide":
		_restore_panel_parent(guide_parent)
	elif screen in ["achievements","themes","statistics"]:
		_restore_panel_parent(retention_parent)
	elif screen == "statistics_export":
		screen="statistics"
		show_statistics()
	elif screen == "levels":
		_restore_panel_parent(levels_parent)
	elif screen == "chapters":
		match return_screen:
			"menu": show_main_menu()
			"won": show_result(true, result_stars)
			"lost": show_result(false, 0)
			"pause": show_pause()
			_: close_overlay()
	elif screen == "menu":
		return
	else:
		close_overlay()
		buttons.pause.grab_focus()

func _show_reaction_frame(frame: Dictionary) -> void:
	board.show_frame(frame)
	var total: int = 0
	var active: int = 0
	for i in range(game.grid.level.nodes.size()):
		if game.grid.level.nodes[i].type == "target":
			total += 1
			if frame.state.active[i]: active += 1
	targets_label.text = "◇  %d / %d" % [active, total]

func _build_gear() -> void:
	gear = _icon_button("settings","Настройки",show_settings,"settings")
	gear.anchor_left = 1.0
	gear.anchor_right = 1.0
	add_child(gear)
	info = _icon_button("info","Справочник",show_information,"info")
	info.anchor_left = 1.0
	info.anchor_right = 1.0
	add_child(info)

func show_settings(restoring: bool = false) -> void:
	if screen == "settings" and not restoring: return
	if not restoring: settings_return_screen = screen
	screen = "settings"
	settings_closing = false
	_pause_for_panel()
	_open_modal("Настройки")
	var emblem := TextureRect.new()
	emblem.texture = preload("res://assets/gear.svg")
	emblem.custom_minimum_size = Vector2(64, 64)
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(emblem)
	var effects := CheckButton.new()
	effects.text = "Звуковые эффекты: " + ("Вкл" if game.settings.sound_enabled() else "Выкл")
	effects.custom_minimum_size = Vector2(0, 144)
	effects.button_pressed = game.settings.sound_enabled()
	effects.toggled.connect(func(enabled: bool):
		game.settings.set_sound(enabled)
		effects.text = "Звуковые эффекты: " + ("Вкл" if enabled else "Выкл"))
	modal.add_child(effects)
	if OS.is_debug_build():
		var diagnostic := CheckButton.new()
		diagnostic.text = "Диагностика: " + ("Вкл" if game.settings.touch_diagnostics_enabled else "Выкл")
		diagnostic.custom_minimum_size.y = 144
		diagnostic.button_pressed = game.settings.touch_diagnostics_enabled
		diagnostic.toggled.connect(func(enabled: bool):
			game.settings.set_touch_diagnostics(enabled)
			diagnostic.text = "Диагностика: " + ("Вкл" if enabled else "Выкл"))
		modal.add_child(diagnostic)
	var reduced := CheckButton.new()
	reduced.text = "Уменьшить эффекты"
	reduced.custom_minimum_size.y = 144
	reduced.button_pressed = game.settings.reduced_effects_enabled()
	reduced.toggled.connect(func(enabled: bool): game.settings.set_reduced_effects(enabled))
	buttons["reduced_effects"] = reduced
	modal.add_child(reduced)
	modal.add_child(_button("Локальная статистика",show_statistics,"statistics"))
	var about := _label("ОБ ИГРЕ\nChain React! · " + str(ProjectSettings.get_setting("application/config/version", "0.2.0")), 36, MUTED)
	modal.add_child(about)
	modal.add_child(_icon_button("back", "Закрыть настройки", close_settings))
	modal.modulate.a = 1.0 if game.settings.reduced_effects_enabled() else 0.0
	if not game.settings.reduced_effects_enabled():
		modal_tween = create_tween()
		modal_tween.tween_property(modal,"modulate:a",1.0,.16)
	effects.grab_focus()

func close_settings() -> void:
	if settings_closing or screen != "settings": return
	settings_closing = true
	if game.settings.reduced_effects_enabled():
		_restore_settings_parent()
		return
	if modal_tween: modal_tween.kill()
	modal_tween = create_tween()
	modal_tween.tween_property(modal, "modulate:a", 0.0, 0.12)
	modal_tween.tween_callback(_restore_settings_parent)

func _restore_settings_parent() -> void:
	settings_closing = false
	_restore_panel_parent(settings_return_screen)

func _restore_panel_parent(parent: String) -> void:
	match parent:
		"menu": show_main_menu()
		"pause": show_pause()
		"won": show_result(true,result_stars)
		"lost": show_result(false,0)
		"chapters": screen = "chapters"; show_chapters()
		"levels": screen = "levels"; show_levels()
		"achievements": screen="achievements"; show_achievements()
		"themes": screen="themes"; show_themes()
		"statistics": screen="statistics"; show_statistics()
		"settings": show_settings(true)
		_:
			modal.modulate.a = 1.0
			close_overlay()
	if gear.visible: gear.grab_focus()

func show_information() -> void:
	if screen != "guide":
		guide_parent = screen
		guide_page = 0
	screen = "guide"
	_pause_for_panel()
	_open_modal("Справочник · %d / %d" % [guide_page+1,Guide.CARDS.size()])
	var card: Dictionary = Guide.CARDS[guide_page]
	modal.add_child(_label(card.title,40,CYAN))
	guide_preview = Board.new()
	guide_preview.custom_minimum_size = Vector2(240,240)
	guide_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(guide_preview)
	var node: Dictionary = {"x":0,"y":0,"type":card.type,"dirs":[1,3] if card.type == "splitter" else [1],"rotatable":card.type in ["directional","splitter"]}
	var preview_level: Dictionary = {"width":1,"height":1,"nodes":[node]}
	guide_preview.configure_visuals(palette,game.settings.reduced_effects_enabled())
	guide_preview.show_state(preview_level,preload("res://scripts/core/reaction_engine.gd").initial_state(preview_level),false)
	var text := _label(card.text,38,MUTED)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.y = 280
	modal.add_child(text)
	var row := _row()
	var previous: Button = _icon_button("back","Предыдущая страница",func(): guide_page -= 1; show_information())
	previous.disabled = guide_page == 0
	row.add_child(previous)
	var next: Button = _icon_button("next","Следующая страница",func(): guide_page += 1; show_information())
	next.disabled = guide_page == Guide.CARDS.size()-1
	row.add_child(next)
	modal.add_child(row)
	var close: Button = _icon_button("close","Закрыть справочник",back_overlay)
	modal.add_child(close)
	close.grab_focus()

func _notice(message: String) -> void:
	hint_label.text = message
	hint_label.show()
	if notice_tween: notice_tween.kill()
	notice_tween = create_tween()
	notice_tween.tween_interval(3.0)
	notice_tween.tween_callback(func(): hint_label.hide())

func _directions(index: int) -> Array:
	var output: Array = []
	for d in game.grid.level.nodes[index].get("dirs", []):
		output.append((int(d) + int(game.grid.state.rotations[index])) % 4)
	return output

func _trace(data: Dictionary) -> void:
	if OS.is_debug_build() and game.settings.touch_diagnostics_enabled:
		print("[TouchDebug] " + JSON.stringify(data))

func _input(event: InputEvent) -> void:
	if game and event is InputEventScreenTouch and event.pressed:
		_trace({"stage": "native-touch", "position": str(event.position), "finger": event.index, "screen": screen})

func _pointer_observed(point: Vector2, index: int, device: int) -> void:
	var reason: String = game.action_rejection(index)
	_trace({"stage": "board-gui", "local_position": str(point), "viewport_position": str(board.get_global_transform_with_canvas() * point), "board_rect": str(board.get_global_rect()), "cell": board.geometry().cell, "index": index, "device": device, "locked": board.locked, "reason": reason})
	if board.locked and not reason.is_empty(): _notice(reason)

func _exit_tree() -> void:
	Icons.cache.clear()

func _apply_visuals() -> void:
	palette = Themes.palette(game.settings.theme_id())
	CYAN = palette.accent
	MUTED = palette.muted
	_build_theme()
	board.configure_visuals(palette,game.settings.reduced_effects_enabled())
	main_menu.configure_visuals(palette,game.settings.reduced_effects_enabled())
	if is_instance_valid(guide_preview): guide_preview.configure_visuals(palette,game.settings.reduced_effects_enabled())
	_apply_label_palette(self)
	var toast_style: StyleBoxFlat=achievement_toast.get_theme_stylebox("panel").duplicate()
	toast_style.border_color=CYAN
	toast_style.bg_color=palette.surface
	achievement_toast.add_theme_stylebox_override("panel",toast_style)
	if game.settings.reduced_effects_enabled():
		if modal_tween: modal_tween.kill()
		modal.modulate.a=1.0
		for child in modal.get_children():
			if child.get_script()==Stars: child.begin(child.reward_total,true)
		if achievement_toast.visible:
			if achievement_tween: achievement_tween.kill()
			achievement_toast.modulate.a=1.0
			achievement_tween=create_tween()
			achievement_tween.tween_interval(2.8)
			achievement_tween.tween_callback(func(): achievement_toast.hide())
		if settings_closing: _restore_settings_parent()
func _apply_label_palette(node: Node) -> void:
	if node is Label and node.has_meta("palette_role"):
		node.add_theme_color_override("font_color",palette[node.get_meta("palette_role")])
	for child in node.get_children(): _apply_label_palette(child)
func _retention_screen(name: String,title: String) -> void:
	if screen!=name and screen!="statistics_export": retention_parent=screen
	screen=name
	_pause_for_panel()
	_open_modal(title)
	retention_view=Retention.new(palette)
	modal.add_child(retention_view)
func _retention_back() -> void:
	var back: Button=_icon_button("back","Назад",back_overlay)
	modal.add_child(back)
	back.grab_focus()
func show_achievements() -> void:
	_retention_screen("achievements","Достижения")
	var rows: Array=game.progress.achievement_status()
	achievement_page=clampi(achievement_page,0,ceili(rows.size()/3.0)-1)
	retention_view.build_achievements(rows,achievement_page)
	retention_view.achievement_page_requested.connect(func(page: int): achievement_page=page; show_achievements())
	_retention_back()
func show_themes() -> void:
	_retention_screen("themes","Оформление")
	retention_view.build_themes(game.progress.data,game.settings.theme_id())
	retention_view.theme_requested.connect(func(id: String): game.settings.set_theme(id))
	_retention_back()
func show_statistics() -> void:
	_retention_screen("statistics","Локальная статистика")
	retention_view.build_statistics(game.statistics.summary(),game.current+1)
	retention_view.export_requested.connect(_export_statistics)
	_retention_back()
func _export_statistics() -> void:
	game.flush_statistics()
	var error: Error=game.statistics.export_json(statistics_export_path)
	if error!=OK:
		var message: Label=_label("Не удалось записать JSON. Код %d"%error,28,MUTED)
		retention_view.add_child(message)
		return
	statistics_export_text=FileAccess.get_file_as_string(statistics_export_path)
	screen="statistics_export"
	_open_modal("Экспорт JSON")
	var caption: Label=_label("Файл сохранён на устройстве.
JSON можно скопировать.",30,MUTED)
	caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	modal.add_child(caption)
	var text:=TextEdit.new()
	text.text=statistics_export_text
	text.editable=false
	text.custom_minimum_size=Vector2(0,660)
	text.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	text.add_theme_font_size_override("font_size",26)
	modal.add_child(text)
	modal.add_child(_button("Скопировать JSON",func(): DisplayServer.clipboard_set(statistics_export_text)))
	_retention_back()
func _build_achievement_toast() -> void:
	achievement_toast=PanelContainer.new()
	achievement_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	achievement_toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var box:=StyleBoxFlat.new()
	box.bg_color=Color("152d3e")
	box.border_color=CYAN
	box.set_border_width_all(2)
	box.set_corner_radius_all(24)
	box.set_content_margin_all(24)
	achievement_toast.add_theme_stylebox_override("panel",box)
	achievement_message=_label("",34,CYAN)
	achievement_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	achievement_message.mouse_filter=Control.MOUSE_FILTER_IGNORE
	achievement_toast.add_child(achievement_message)
	add_child(achievement_toast)
	achievement_toast.hide()
func _queue_achievements(ids: Array) -> void:
	for id in ids:
		if not id in pending_achievements: pending_achievements.append(id)
func _hide_achievement_toast() -> void:
	if achievement_tween: achievement_tween.kill()
	if achievement_toast: achievement_toast.hide()
func _show_achievement_toast() -> void:
	if pending_achievements.is_empty(): return
	var title: String=""
	for row in game.progress.achievement_status():
		if row.id==pending_achievements[0]: title=row.title
	achievement_message.text="Достижение открыто
"+title+("  +%d"%(pending_achievements.size()-1) if pending_achievements.size()>1 else "")
	pending_achievements.clear()
	achievement_toast.show()
	achievement_toast.modulate.a=1.0 if game.settings.reduced_effects_enabled() else 0.0
	achievement_tween=create_tween()
	if not game.settings.reduced_effects_enabled(): achievement_tween.tween_property(achievement_toast,"modulate:a",1.0,.25)
	achievement_tween.tween_interval(2.8)
	if not game.settings.reduced_effects_enabled(): achievement_tween.tween_property(achievement_toast,"modulate:a",0.0,.25)
	achievement_tween.tween_callback(func(): achievement_toast.hide())

class_name UIManager
extends Control
const Game = preload("res://scripts/core/game_manager.gd")
const Board = preload("res://scripts/ui/board.gd")
const CYAN: Color = Color("4de6f5")
const MUTED: Color = Color("92a7c2")
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
@export var start_in_menu: bool = true

func _ready() -> void:
	get_tree().quit_on_go_back = false
	_build_theme()
	_build_screen()
	_build_overlay()
	_build_audio()
	_build_gear()
	game = Game.new(save_path)
	game.changed.connect(refresh)
	game.reaction_frame.connect(_show_reaction_frame)
	game.finished.connect(show_result)
	game.feedback.connect(_on_feedback)
	board.node_pressed.connect(_tap_node)
	board.pointer_observed.connect(_pointer_observed)
	game.settings.changed.connect(_settings_changed)
	add_child(game)
	get_viewport().size_changed.connect(_safe_area)
	_safe_area()
	buttons.levels.grab_focus()
	if start_in_menu and game.error_message.is_empty(): show_main_menu()

func _build_theme() -> void:
	var t := Theme.new()
	t.default_font_size = 42
	t.set_color("font_color", "Label", Color("edf6ff"))
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("17273e") if state_name != "pressed" else Color("25455b")
		box.border_color = CYAN if state_name in ["hover", "focus"] else Color("304560")
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
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var brand := _row()
	brand.add_child(_label("◈  CHAIN REACT!", 46, CYAN))
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(space)
	brand.custom_minimum_size.y = 144
	var gear_space := Control.new()
	gear_space.custom_minimum_size.x = 144
	stars_label = _label("", 32, Color("b5f3a0"))
	brand.add_child(stars_label)
	brand.add_child(gear_space)
	column.add_child(brand)
	phase_label = _label("ONE TAP PUZZLE   /   01—10", 26, MUTED)
	column.add_child(phase_label)
	title_label = _label("", 56)
	column.add_child(title_label)
	var stats := _row()
	count_label = _label("", 34, CYAN)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(count_label)
	targets_label = _label("", 34, Color("b5f3a0"))
	stats.add_child(targets_label)
	column.add_child(stats)
	board = Board.new()
	board.custom_minimum_size = Vector2(0, 550)
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(board)
	hint_label = _label("", 42, MUTED)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size.y = 144
	column.add_child(hint_label)
	var legend := _label("▶ запуск    • передача    ◇ цель\nСтрелки с дугой можно повернуть до запуска", 32, MUTED)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(legend)
	var actions := _row()
	actions.add_child(_button("Отмена", func(): game.undo(), "undo"))
	actions.add_child(_button("Заново", func(): close_overlay(); game.restart(), "restart"))
	actions.add_child(_button("Пауза", show_pause, "pause"))
	column.add_child(actions)
	var footer := _row()
	footer.add_child(_button("Уровни", show_levels, "levels"))

	column.add_child(footer)

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
	if gear:
		gear.offset_left = -right - 144
		gear.offset_right = -right
		gear.offset_top = top
		gear.offset_bottom = top + 144

func refresh() -> void:
	if not game.error_message.is_empty():
		_open_modal("Не удалось загрузить уровни")
		modal.add_child(_label(game.error_message, 24))
		return
	if game.grid.level.is_empty(): return
	var level: Dictionary = game.grid.level
	title_label.text = level.name
	phase_label.text = "УРОВЕНЬ %02d / 10     ·     %s" % [game.current + 1, "ЦЕПНАЯ РЕАКЦИЯ" if game.busy else "СПЛАНИРУЙТЕ СВОЙ ХОД"]
	count_label.text = "▶  Запуски: %d / %d" % [int(level.launches) - game.grid.used, int(level.launches)]
	var total: int = 0
	var active: int = 0
	for i in range(level.nodes.size()):
		if level.nodes[i].type == "target":
			total += 1
			if (board.state if game.busy and not board.state.is_empty() else game.grid.state).active[i]: active += 1
	targets_label.text = "◇  %d / %d" % [active, total]
	stars_label.text = "★ %d" % game.progress.total_stars()
	hint_label.text = level.hint
	if game.grid.used > 0 and not game.busy and level.nodes.any(func(n: Dictionary): return n.get("rotatable", false)):
		hint_label.text = "Повороты доступны только до первого запуска. Нажмите Restart или Undo, чтобы изменить решение."
	if game.progress.last_error != OK:
		hint_label.text = "Не удалось сохранить прогресс. Проверьте доступное место."
	elif not game.progress.save.warning.is_empty():
		hint_label.text = game.progress.save.warning
	buttons.undo.disabled = game.busy or game.grid.history.is_empty() or game.paused

	if not game.busy:
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
	if not rejection.is_empty(): hint_label.text = rejection
	if kind not in ["source", "directional", "splitter"]:
		var descriptions: Dictionary = {
			"normal": "Передатчик: отправляет энергию четырём соседям.",
			"battery": "Батарея: нужны два импульса. Заряд сохраняется между запусками.",
			"blocker": "Блок: поглощает импульсы.",
			"target": "Цель: должна получить хотя бы один импульс."
		}
		hint_label.text = descriptions.get(kind, "")

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
	gear.hide()
	if modal_tween: modal_tween.kill()
	modal.modulate.a = 1.0
	for button in buttons.values(): button.focus_mode = Control.FOCUS_NONE
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	var heading := _label(title, 48, CYAN)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.add_child(heading)
	overlay.show()

func close_overlay() -> void:
	for button in buttons.values(): button.focus_mode = Control.FOCUS_ALL
	screen = "game"
	gear.show()
	margin.show()
	if board.tween: board.tween.play()
	overlay.hide()
	if game:
		game.paused = false
		refresh()

func show_pause() -> void:
	screen = "pause"
	game.paused = true
	board.locked = true
	if board.tween: board.tween.pause()
	_open_modal("Пауза")
	modal.add_child(_label("Ваша цепь подождёт.", 32, MUTED))
	var resume := _button("Продолжить", func():
		if board.tween: board.tween.play()
		close_overlay())
	modal.add_child(resume)
	modal.add_child(_button("Начать заново", func(): close_overlay(); game.restart()))
	modal.add_child(_button("Настройки", show_settings))
	modal.add_child(_button("Главное меню", show_main_menu))
	resume.grab_focus()

func show_levels() -> void:
	if screen != "levels": return_screen = screen
	screen = "levels"
	if board.tween: board.tween.pause()
	game.paused = true
	board.locked = true
	_open_modal("Выберите уровень")
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	modal.add_child(grid)
	for i in range(game.levels.size()):
		var stars: int = game.progress.data.completed.get(str(i + 1), 0)
		var label: String = "%02d\n%s" % [i + 1, "★".repeat(stars) if stars > 0 else "—"]
		var button := _button(label, func(): close_overlay(); game.select_level(i))
		button.custom_minimum_size = Vector2(144, 144)
		grid.add_child(button)
	var back := _button("Вернуться", back_overlay)
	modal.add_child(back)
	back.grab_focus()

func show_result(won: bool, stars: int) -> void:
	screen = "won" if won else "lost"
	result_stars = stars
	_open_modal("Цепь замкнулась!" if won else "Попробуем иначе?")
	var text := _label("★".repeat(stars) if won else "Не все цели зажглись.", 42, Color("b5f3a0") if won else MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.add_child(text)
	if won:
		var next := _button("Следующий уровень" if game.current < 9 else "Пройдено! В начало", func(): close_overlay(); game.next_level())
		modal.add_child(next)
		next.grab_focus()
	else:
		var undo := _button("Отменить запуск", func(): close_overlay(); game.undo())
		modal.add_child(undo)
		undo.grab_focus()
	modal.add_child(_button("Заново", func(): close_overlay(); game.restart()))
	modal.add_child(_button("Уровни", show_levels))
	stars_label.text = "★ %d" % game.progress.total_stars()
	modal.modulate.a = 0.0
	modal_tween = create_tween()
	modal_tween.tween_property(modal, "modulate:a", 1.0, 0.22)

func toggle_sound() -> void:
	game.settings.set_sound(not game.settings.sound_enabled())
	if game.settings.sound_enabled(): _on_feedback("rotate")

func _settings_changed(key: String) -> void:
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
		if overlay.visible: back_overlay()
		else: show_pause()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and game and screen == "settings" and settings_return_screen == "game":
		settings_return_screen = "pause"
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and game:
		if overlay.visible: back_overlay()
		else: show_pause()

func show_main_menu() -> void:
	screen = "menu"
	game.paused = true
	board.locked = true
	if board.tween: board.tween.pause()
	margin.hide()
	_open_modal("◈  CHAIN REACT!")
	var subtitle := _label("ONE TAP PUZZLE\nПланируй. Запускай. Зажигай.", 36, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.add_child(subtitle)
	var play := _button("Продолжить · %02d" % (game.current + 1), close_overlay)
	modal.add_child(play)
	modal.add_child(_button("Выбрать уровень", show_levels))
	gear.show()
	gear.focus_mode = Control.FOCUS_ALL
	play.grab_focus()

func back_overlay() -> void:
	if screen == "settings":
		close_settings()
	elif screen == "levels":
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
	gear = _button("", show_settings, "settings")
	gear.icon = preload("res://assets/gear.svg")
	gear.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gear.expand_icon = true
	gear.add_theme_constant_override("icon_max_width", 64)
	gear.tooltip_text = "Настройки"
	gear.custom_minimum_size = Vector2(144, 144)
	gear.anchor_left = 1.0
	gear.anchor_right = 1.0
	add_child(gear)

func show_settings() -> void:
	if screen == "settings": return
	settings_return_screen = screen
	screen = "settings"
	settings_closing = false
	game.paused = true
	board.locked = true
	if board.tween: board.tween.pause()
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
	var about := _label("ОБ ИГРЕ\nChain React! · " + str(ProjectSettings.get_setting("application/config/version", "0.2.0")), 36, MUTED)
	modal.add_child(about)
	modal.add_child(_button("Закрыть", close_settings))
	modal.modulate.a = 0.0
	modal_tween = create_tween()
	modal_tween.tween_property(modal, "modulate:a", 1.0, 0.16)
	effects.grab_focus()

func close_settings() -> void:
	if settings_closing or screen != "settings": return
	settings_closing = true
	if modal_tween: modal_tween.kill()
	modal_tween = create_tween()
	modal_tween.tween_property(modal, "modulate:a", 0.0, 0.12)
	modal_tween.tween_callback(_restore_settings_parent)

func _restore_settings_parent() -> void:
	settings_closing = false
	match settings_return_screen:
		"menu": show_main_menu()
		"pause": show_pause()
		"won": show_result(true, result_stars)
		"lost": show_result(false, 0)
		"levels":
			screen = "levels"
			show_levels()
		_:
			modal.modulate.a = 1.0
			close_overlay()
			gear.grab_focus()
	if gear.visible: gear.grab_focus()

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
	if board.locked and not reason.is_empty(): hint_label.text = reason

class_name Hud
extends CanvasLayer

signal resume_requested

var _font: SystemFont
var _hp_fill: ColorRect
var _hp_text: Label
var _day_label: Label
var _wave_label: Label
var _coins_label: Label
var _weapon_label: Label
var _ammo_label: Label
var _slot_cards: Array[ColorRect] = []
var _slot_icons: Array[TextureRect] = []
var _slot_keys: Array[Label] = []
var _slot_ammo: Array[Label] = []
var _kick_label: Label
var _pause_label: Label
var _pause_panel: ColorRect
var _guide_panel: ColorRect
var _is_paused := false

static func make_cjk_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei",
		"SimHei",
		"PingFang SC",
		"Noto Sans CJK SC",
	])
	return font

func _ready() -> void:
	layer = 5
	_font = make_cjk_font()
	_build_top_status()
	_build_bottom_loadout()
	_build_pause_overlay()

func _build_top_status() -> void:
	var status_back := ColorRect.new()
	status_back.position = Vector2(0, 0)
	status_back.size = Vector2(Config.W, 72)
	status_back.color = Color(0.04, 0.06, 0.05, 0.42)
	add_child(status_back)

	var hp_back := ColorRect.new()
	hp_back.position = Vector2(28, 20)
	hp_back.size = Vector2(232, 26)
	hp_back.color = Color(0.10, 0.08, 0.07, 0.88)
	add_child(hp_back)

	_hp_fill = ColorRect.new()
	_hp_fill.position = Vector2(32, 24)
	_hp_fill.size = Vector2(224, 18)
	_hp_fill.color = Color("#e85842")
	add_child(_hp_fill)

	_hp_text = _mk_label(Vector2(38, 18), 18)
	_day_label = _mk_label(Vector2(420, 18), 22)
	_wave_label = _mk_label(Vector2(610, 20), 18)
	_coins_label = _mk_label(Vector2(1010, 18), 20)

	var pause_hint := _mk_label(Vector2(1194, 17), 24)
	pause_hint.text = "Ⅱ"
	pause_hint.tooltip_text = "按 Esc 暂停"

func _build_bottom_loadout() -> void:
	var tray := ColorRect.new()
	tray.position = Vector2(0, Config.H - 112)
	tray.size = Vector2(Config.W, 112)
	tray.color = Color(0.13, 0.10, 0.07, 0.76)
	add_child(tray)

	var edge := ColorRect.new()
	edge.position = Vector2(0, Config.H - 116)
	edge.size = Vector2(Config.W, 4)
	edge.color = Color(0.82, 0.76, 0.48, 0.85)
	add_child(edge)

	_weapon_label = _mk_label(Vector2(28, Config.H - 92), 19)
	_weapon_label.size = Vector2(205, 28)
	_ammo_label = _mk_label(Vector2(28, Config.H - 61), 15)

	for index in range(4):
		var card := ColorRect.new()
		card.position = Vector2(246 + index * 154, Config.H - 101)
		card.size = Vector2(142, 88)
		card.color = Color(0.06, 0.055, 0.045, 0.9)
		add_child(card)
		_slot_cards.append(card)

		var key := _mk_label(card.position + Vector2(8, 4), 14)
		key.text = "%d  %s" % [index + 1, WeaponData.SLOT_NAMES[index]]
		_slot_keys.append(key)

		var icon := TextureRect.new()
		icon.position = card.position + Vector2(10, 25)
		icon.size = Vector2(122, 42)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(icon)
		_slot_icons.append(icon)

		var ammo := _mk_label(card.position + Vector2(8, 65), 11)
		ammo.size = Vector2(126, 18)
		ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_slot_ammo.append(ammo)

	var controls := _mk_label(Vector2(880, Config.H - 72), 13)
	controls.text = "Esc  暂停与操作指南"
	controls.modulate = Color(1, 1, 1, 0.72)

	_kick_label = _mk_label(Vector2(1080, Config.H - 76), 18)
	_kick_label.size = Vector2(160, 36)
	_kick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _build_pause_overlay() -> void:
	_pause_panel = ColorRect.new()
	_pause_panel.position = Vector2(Config.W / 2.0 - 230, 214)
	_pause_panel.size = Vector2(460, 292)
	_pause_panel.color = Color(0.055, 0.045, 0.035, 0.96)
	add_child(_pause_panel)

	_pause_label = _mk_label(Vector2(Config.W / 2.0 - 210, 238), 34)
	_pause_label.size = Vector2(420, 74)
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause_label.text = "游戏暂停"
	_pause_label.add_theme_color_override("font_color", Color("#ffe37a"))

	var resume_button := _mk_button(Vector2(Config.W / 2.0 - 150, 330), Vector2(300, 50), "继续游戏")
	resume_button.pressed.connect(_request_resume)
	var guide_button := _mk_button(Vector2(Config.W / 2.0 - 150, 398), Vector2(300, 50), "操作指南")
	guide_button.pressed.connect(_toggle_guide)

	_guide_panel = ColorRect.new()
	_guide_panel.position = Vector2(Config.W / 2.0 - 280, 126)
	_guide_panel.size = Vector2(560, 468)
	_guide_panel.color = Color(0.045, 0.04, 0.035, 0.985)
	add_child(_guide_panel)

	var guide_title := _mk_label(Vector2(Config.W / 2.0 - 250, 150), 30)
	guide_title.size = Vector2(500, 48)
	guide_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide_title.text = "操作指南"
	guide_title.add_theme_color_override("font_color", Color("#ffe37a"))

	var guide_text := _mk_label(Vector2(Config.W / 2.0 - 220, 214), 19)
	guide_text.size = Vector2(440, 270)
	guide_text.text = (
		"WASD / 方向键    移动\n"
		+ "鼠标              瞄准\n"
		+ "鼠标左键          射击\n"
		+ "R                 换弹\n"
		+ "空格 / F          踢击与击退\n"
		+ "Q / 数字键 1-4    切换四个武器槽\n"
		+ "Esc               暂停 / 继续\n\n"
		+ "白天购买装备，夜晚抵御尸潮。\n"
		+ "每天进入夜晚前可从仓库配置出战装备。\n"
		+ "坚持 10 天即可获胜。"
	)
	var close_guide := _mk_button(Vector2(Config.W / 2.0 - 110, 518), Vector2(220, 46), "返回暂停菜单")
	close_guide.pressed.connect(_toggle_guide)

	_pause_panel.visible = false
	_pause_label.visible = false
	resume_button.visible = false
	guide_button.visible = false
	_pause_panel.set_meta("resume_button", resume_button)
	_pause_panel.set_meta("guide_button", guide_button)
	_guide_panel.visible = false
	guide_title.visible = false
	guide_text.visible = false
	close_guide.visible = false
	_guide_panel.set_meta("title", guide_title)
	_guide_panel.set_meta("text", guide_text)
	_guide_panel.set_meta("close_button", close_guide)

func _mk_label(pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label

func _mk_button(pos: Vector2, size: Vector2, text: String) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = size
	button.text = text
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 20)
	add_child(button)
	return button

func set_paused(paused: bool) -> void:
	_is_paused = paused
	_pause_panel.visible = paused
	_pause_label.visible = paused
	_pause_panel.get_meta("resume_button").visible = paused
	_pause_panel.get_meta("guide_button").visible = paused
	if not paused:
		_set_guide_visible(false)

func _request_resume() -> void:
	resume_requested.emit()

func _toggle_guide() -> void:
	_set_guide_visible(not _guide_panel.visible)

func _set_guide_visible(show: bool) -> void:
	_guide_panel.visible = show
	_guide_panel.get_meta("title").visible = show
	_guide_panel.get_meta("text").visible = show
	_guide_panel.get_meta("close_button").visible = show
	_pause_label.visible = not show and _is_paused
	_pause_panel.visible = not show and _is_paused
	_pause_panel.get_meta("resume_button").visible = not show and _is_paused
	_pause_panel.get_meta("guide_button").visible = not show and _is_paused

func update_hud(main) -> void:
	var player: Player = main.player
	var hp_ratio := clampf(player.hp / player.max_hp(), 0.0, 1.0)
	_hp_fill.size.x = 224.0 * hp_ratio
	_hp_text.text = "体力  %d / %d" % [
		int(ceil(maxf(0.0, player.hp))),
		int(player.max_hp()),
	]
	_day_label.text = "第 %d 夜" % main.day
	_wave_label.text = "尸潮剩余  %d" % (main.spawn_remaining + main.zombies.size())
	_coins_label.text = "金币  %d" % main.coins

	var weapon: Dictionary = player.weapon()
	_weapon_label.text = str(weapon["def"]["name"])
	if weapon["def"]["category"] == "melee":
		_ammo_label.text = "近战武器"
		_ammo_label.modulate = Color.WHITE
	elif player.reload_timer > 0.0:
		_ammo_label.text = "换弹中…"
		_ammo_label.modulate = Color("#ffe37a")
	else:
		var reserve := "∞" if weapon["def"]["infinite_reserve"] else str(weapon["reserve"])
		_ammo_label.text = "弹药  %d / %s" % [weapon["mag"], reserve]
		_ammo_label.modulate = Color.WHITE

	for index in range(player.weapons.size()):
		var item = player.weapons[index]
		var active := index == player.weapon_index
		_slot_cards[index].color = Color(0.34, 0.25, 0.08, 0.96) if active else Color(0.06, 0.055, 0.045, 0.9)
		_slot_keys[index].add_theme_color_override("font_color", Color("#ffe37a") if active else Color.WHITE)
		if item == null:
			_slot_icons[index].texture = null
			_slot_ammo[index].text = "空槽"
			continue
		var definition: Dictionary = item["def"]
		_slot_icons[index].texture = load("res://assets/weapons/%s.png" % definition["id"])
		if definition["category"] == "melee":
			_slot_ammo[index].text = definition["name"]
		else:
			var slot_reserve := "∞" if definition["infinite_reserve"] else str(item["reserve"])
			_slot_ammo[index].text = "%d / %s" % [item["mag"], slot_reserve]

	if player.kick_timer > 0.0:
		_kick_label.text = "近战  %.1fs" % player.kick_timer
		_kick_label.modulate = Color(0.65, 0.65, 0.65)
	else:
		_kick_label.text = "近战  就绪"
		_kick_label.modulate = Color("#ffe37a")

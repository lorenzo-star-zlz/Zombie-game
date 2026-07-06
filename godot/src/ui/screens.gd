# 覆盖层界面：主菜单 / 白天商店 / 夜晚结算+肉鸽三选一 / 失败 / 胜利。
# 全部代码动态构建 Control，不含游戏逻辑（逻辑通过 Callable 回调给 main）。
class_name Screens
extends CanvasLayer

var _font: SystemFont
var _root: Control = null

func _ready() -> void:
	layer = 10
	_font = Hud.make_cjk_font()

func clear() -> void:
	if _root != null:
		_root.queue_free()
		_root = null

# ---------- 面板骨架 ----------
func _begin_panel() -> VBoxContainer:
	clear()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.14, 0.96)
	sb.border_color = Color(0.29, 0.25, 0.4)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	return vbox

func _mk_label(parent: Node, text: String, font_size: int, color := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _mk_button(parent: Node, text: String, font_size := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b

const GOLD := Color(1.0, 0.82, 0.4)
const GREEN := Color(0.49, 0.91, 0.53)
const DIM := Color(1, 1, 1, 0.7)

# ---------- 主菜单 ----------
func show_menu(on_start: Callable) -> void:
	var v := _begin_panel()
	_mk_label(v, "🧟 街区死守", 42, GOLD)
	_mk_label(v, "白天备战，夜晚守住街区。撑过 %d 天就是胜利。" % WaveData.TOTAL_DAYS, 15, DIM)
	_mk_label(v, "WASD 移动 · 鼠标射击 · R 换弹 · 空格/F 快速近战 · Q 或 1-4 切换武器槽", 15, DIM)
	var b := _mk_button(v, "开始游戏")
	b.pressed.connect(on_start)

# ---------- 白天商店 ----------
func show_shop(m, on_night: Callable) -> void:
	var v := _begin_panel()
	_mk_label(v, "☀️ 第 %d 天 · 白天" % m.day, 28, GOLD)
	_mk_label(v, "💰 金币：%d" % m.coins, 20, GOLD)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)

	for item in ShopData.ITEMS:
		var price: int = ShopData.price_of(m, item)
		var can_show: bool = ShopData.is_available(m, item["id"])
		var afford: bool = m.coins >= price
		var price_txt: String = ("$%d" % price) if can_show else "—"
		var b := _mk_button(grid, "%s · %s   %s\n%s" % [item["icon"], item["name"], price_txt, item["desc"]], 13)
		b.custom_minimum_size = Vector2(270, 62)
		if item.has("weapon"):
			b.icon = load("res://assets/weapons/%s.png" % item["weapon"])
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 52)
		b.disabled = not can_show or not afford
		b.pressed.connect(_on_buy.bind(m, item, on_night))

	var p: Player = m.player
	var inventory := []
	for index in range(p.weapons.size()):
		var weapon = p.weapons[index]
		var weapon_name := "空" if weapon == null else str(weapon["def"]["name"])
		inventory.append("%s：%s" % [WeaponData.SLOT_NAMES[index], weapon_name])
	_mk_label(v, "装备：" + "  ·  ".join(inventory), 14, DIM)
	_mk_label(v, "仓库：%d 件武器，进入夜晚前可重新配置" % p.owned_weapon_ids.size(), 13, DIM)
	_mk_label(v, "❤ 生命：%d/%d" % [int(ceil(p.hp)), int(p.max_hp())], 14, DIM)

	var night_btn := _mk_button(v, "配置装备并进入第 %d 夜" % m.day)
	night_btn.pressed.connect(show_loadout.bind(m, on_night))

func _on_buy(m, item: Dictionary, on_night: Callable) -> void:
	var price: int = ShopData.price_of(m, item)
	if not ShopData.is_available(m, item["id"]) or m.coins < price:
		return
	m.coins -= price
	m.purchase_counts[item["id"]] = m.purchase_counts.get(item["id"], 0) + 1
	ShopData.buy(m, item["id"])
	show_shop(m, on_night)  # 刷新界面

func show_loadout(m, on_confirm: Callable) -> void:
	var v := _begin_panel()
	_mk_label(v, "第 %d 天 · 出战装备" % m.day, 30, GOLD)
	_mk_label(v, "商店购买的枪会进入仓库；每个固定槽位从仓库中独立选择装备", 15, DIM)

	var slots := HBoxContainer.new()
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.add_theme_constant_override("separation", 12)
	v.add_child(slots)
	for index in range(4):
		_build_loadout_slot(slots, m, index, on_confirm)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	v.add_child(actions)
	var back := _mk_button(actions, "返回商店", 18)
	back.pressed.connect(show_shop.bind(m, on_confirm))
	var confirm := _mk_button(actions, "确认装备，进入夜晚", 18)
	confirm.disabled = not m.player.is_loadout_valid()
	confirm.pressed.connect(on_confirm)

func _build_loadout_slot(parent: Node, m, slot: int, on_confirm: Callable) -> void:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(190, 150)
	parent.add_child(card)
	_mk_label(card, "%d  %s" % [slot + 1, WeaponData.SLOT_NAMES[slot]], 16, GOLD)
	var equipped = m.player.weapons[slot]
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(180, 72)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if equipped != null:
		icon.texture = load("res://assets/weapons/%s.png" % equipped["def"]["id"])
	card.add_child(icon)
	var picker := OptionButton.new()
	picker.add_theme_font_override("font", _font)
	picker.add_theme_font_size_override("font_size", 14)
	var category := "primary" if slot < 2 else ("secondary" if slot == 2 else "melee")
	var selected := 0
	var option_index := 0
	if category == "primary":
		picker.add_item("空槽")
		picker.set_item_metadata(0, "")
		option_index = 1
	for id in m.player.owned_weapon_ids:
		var definition: Dictionary = m.player.weapon_instances[id]["def"]
		if definition["category"] != category:
			continue
		picker.add_item(definition["name"])
		picker.set_item_metadata(option_index, id)
		if equipped != null and equipped["def"]["id"] == id:
			selected = option_index
		option_index += 1
	picker.select(selected)
	picker.item_selected.connect(_on_loadout_slot_selected.bind(m, slot, picker, on_confirm))
	card.add_child(picker)

func _on_loadout_slot_selected(option: int, m, slot: int, picker: OptionButton, on_confirm: Callable) -> void:
	var id: String = picker.get_item_metadata(option)
	m.player.equip_to_slot(id, slot)
	show_loadout(m, on_confirm)

# ---------- 夜晚结算 + 肉鸽三选一 ----------
func show_night_reward(m, perks: Array, bonus: int, on_pick: Callable) -> void:
	var v := _begin_panel()
	_mk_label(v, "🌙 第 %d 晚 · 防守成功！" % m.day, 28, GOLD)
	_mk_label(v, "击杀 %d 只僵尸 · 通宵奖励 +%d 金币" % [m.night_kills, bonus], 17, GREEN)
	_mk_label(v, "选择一个强化（本局永久生效）：", 14, DIM)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(hbox)

	for perk in perks:
		var b := _mk_button(hbox, "%s\n%s\n\n%s" % [perk["icon"], perk["name"], perk["desc"]], 16)
		b.custom_minimum_size = Vector2(210, 190)
		b.pressed.connect(on_pick.bind(perk))

# ---------- 失败 / 胜利 ----------
func show_game_over(m, on_restart: Callable) -> void:
	var v := _begin_panel()
	_mk_label(v, "💀 街区失守", 32, Color(1.0, 0.4, 0.4))
	_mk_label(v, "你撑到了第 %d 天" % m.day, 17)
	_mk_label(v, "总击杀：%d 只僵尸" % m.total_kills, 17)
	var b := _mk_button(v, "再来一局")
	b.pressed.connect(on_restart)

func show_win(m, on_restart: Callable) -> void:
	var v := _begin_panel()
	_mk_label(v, "🏆 守住了！", 32, GOLD)
	_mk_label(v, "你成功撑过了 %d 天尸潮！" % WaveData.TOTAL_DAYS, 17)
	_mk_label(v, "总击杀：%d 只僵尸 · 剩余金币：%d" % [m.total_kills, m.coins], 17)
	var b := _mk_button(v, "再来一局")
	b.pressed.connect(on_restart)

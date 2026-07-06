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
	_mk_label(v, "选择最多两把主武器、一把副武器和一把近战武器", 15, DIM)
	_mk_label(v, "主武器槽满时，先点击已装备主武器卸下", 13, DIM)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	v.add_child(grid)

	for id in m.player.owned_weapon_ids:
		var item: Dictionary = m.player.weapon_instances[id]
		var definition: Dictionary = item["def"]
		var slot: int = m.player.equipped_slot(id)
		var status := "已装备：%s" % WeaponData.SLOT_NAMES[slot] if slot >= 0 else "点击装备"
		var button := _mk_button(grid, "%s\n%s" % [definition["name"], status], 14)
		button.custom_minimum_size = Vector2(260, 62)
		button.icon = load("res://assets/weapons/%s.png" % id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 56)
		button.disabled = (
			definition["category"] == "primary"
			and slot < 0
			and not m.player.can_equip_category("primary")
		)
		button.pressed.connect(_on_toggle_loadout.bind(m, id, on_confirm))

	var active := []
	for index in range(m.player.weapons.size()):
		var equipped = m.player.weapons[index]
		active.append("%s：%s" % [
			WeaponData.SLOT_NAMES[index],
			"空" if equipped == null else equipped["def"]["name"],
		])
	_mk_label(v, "当前带入\n" + "\n".join(active), 14, DIM)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	v.add_child(actions)
	var back := _mk_button(actions, "返回商店", 18)
	back.pressed.connect(show_shop.bind(m, on_confirm))
	var confirm := _mk_button(actions, "确认装备，进入夜晚", 18)
	confirm.disabled = not m.player.is_loadout_valid()
	confirm.pressed.connect(on_confirm)

func _on_toggle_loadout(m, id: String, on_confirm: Callable) -> void:
	m.player.toggle_loadout_weapon(id)
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

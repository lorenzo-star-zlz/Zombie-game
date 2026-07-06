class_name ShopData

const ITEMS := [
	{ "id": "medkit", "icon": "医疗", "name": "急救包", "desc": "生命完全恢复", "base_price": 40, "growth": 1.0 },
	{ "id": "ammo", "icon": "弹药", "name": "弹药补给", "desc": "所有枪械备弹补满", "base_price": 25, "growth": 1.0 },
	{ "id": "buy_kar98k", "weapon": "kar98k", "icon": "主武器", "name": "Kar98k", "desc": "高伤、慢射速、可穿透", "base_price": 180, "growth": 1.0 },
	{ "id": "buy_shotgun", "weapon": "shotgun", "icon": "主武器", "name": "雷明顿 870", "desc": "近距离霰弹爆发", "base_price": 150, "growth": 1.0 },
	{ "id": "buy_ak47", "weapon": "ak47", "icon": "主武器", "name": "AK-47", "desc": "高威力全自动步枪", "base_price": 260, "growth": 1.0 },
	{ "id": "buy_m4", "weapon": "m4", "icon": "主武器", "name": "M4A1", "desc": "稳定精准的全能步枪", "base_price": 340, "growth": 1.0 },
	{ "id": "buy_m249", "weapon": "m249", "icon": "主武器", "name": "M249", "desc": "百发弹箱持续压制", "base_price": 520, "growth": 1.0 },
	{ "id": "buy_uzi", "weapon": "uzi", "icon": "副武器", "name": "UZI", "desc": "替换副武器槽的高射速武器", "base_price": 180, "growth": 1.0 },
	{ "id": "buy_machete", "weapon": "machete", "icon": "近战", "name": "开山刀", "desc": "替换匕首，扩大攻击范围", "base_price": 120, "growth": 1.0 },
	{ "id": "gunsmith", "icon": "改装", "name": "枪匠保养", "desc": "所有武器伤害永久 +5%", "base_price": 70, "growth": 1.5 },
]

static func price_of(main, item: Dictionary) -> int:
	var count: int = main.purchase_counts.get(item["id"], 0)
	return int(round(item["base_price"] * pow(item["growth"], count)))

static func is_available(main, id: String) -> bool:
	if id == "medkit":
		return main.player.hp < main.player.max_hp()
	if id == "ammo":
		for weapon in main.player.weapons:
			if weapon != null and weapon["def"]["category"] != "melee":
				if not weapon["def"]["infinite_reserve"] and weapon["reserve"] < weapon["def"]["reserve_max"]:
					return true
		return false
	if id == "gunsmith":
		return true
	var item := item_by_id(id)
	if item.is_empty() or not item.has("weapon"):
		return false
	var weapon_id: String = item["weapon"]
	if main.player.has_weapon(weapon_id):
		return false
	return main.player.can_equip_category(WeaponData.WEAPONS[weapon_id]["category"])

static func buy(main, id: String) -> void:
	if id == "medkit":
		main.player.hp = main.player.max_hp()
		return
	if id == "ammo":
		for weapon in main.player.weapons:
			if weapon != null and weapon["def"]["category"] != "melee":
				if not weapon["def"]["infinite_reserve"]:
					weapon["reserve"] = weapon["def"]["reserve_max"]
		return
	if id == "gunsmith":
		main.player.mods["dmg_mult"] *= 1.05
		return
	var item := item_by_id(id)
	if item.has("weapon"):
		main.player.add_weapon(item["weapon"])

static func item_by_id(id: String) -> Dictionary:
	for item in ITEMS:
		if item["id"] == id:
			return item
	return {}

# 商店条目。GDScript 常量里不方便放函数，效果统一在 buy()/is_available() 里按 id 分发。
class_name ShopData

const ITEMS := [
	{ "id": "medkit",      "icon": "🩹", "name": "急救包",     "desc": "生命完全恢复",                                "base_price": 40,  "growth": 1.0 },
	{ "id": "ammo",        "icon": "🔋", "name": "弹药补给",   "desc": "所有武器备弹补满",                            "base_price": 25,  "growth": 1.0 },
	{ "id": "buy_shotgun", "icon": "🔫", "name": "购买霰弹枪", "desc": "雷明顿 870：近距离一炮糊脸（Q 或 2 切换）",   "base_price": 150, "growth": 1.0 },
	{ "id": "gunsmith",    "icon": "🔧", "name": "枪匠保养",   "desc": "所有武器伤害永久 +5%（可重复，价格递增）",    "base_price": 70,  "growth": 1.5 },
]

static func price_of(main, item: Dictionary) -> int:
	var count: int = main.purchase_counts.get(item["id"], 0)
	return int(round(item["base_price"] * pow(item["growth"], count)))

static func is_available(main, id: String) -> bool:
	match id:
		"medkit":
			return main.player.hp < main.player.max_hp()
		"ammo":
			for w in main.player.weapons:
				if not w["def"]["infinite_reserve"] and w["reserve"] < w["def"]["reserve_max"]:
					return true
			return false
		"buy_shotgun":
			return not main.player.has_weapon("shotgun")
		"gunsmith":
			return true
	return false

static func buy(main, id: String) -> void:
	match id:
		"medkit":
			main.player.hp = main.player.max_hp()
		"ammo":
			for w in main.player.weapons:
				if not w["def"]["infinite_reserve"]:
					w["reserve"] = w["def"]["reserve_max"]
		"buy_shotgun":
			main.player.add_weapon("shotgun")
		"gunsmith":
			main.player.mods["dmg_mult"] *= 1.05

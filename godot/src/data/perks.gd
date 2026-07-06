# 肉鸽奖励数据表。effects 为声明式修改：
#   { "stat": "dmg_mult", "mul": 1.15 }  → mods["dmg_mult"] *= 1.15
#   { "stat": "max_hp_add", "add": 25 }  → mods["max_hp_add"] += 25
class_name PerkData

const PERKS := [
	{ "id": "dmg",      "icon": "💥", "name": "强力弹头", "desc": "所有武器伤害 +15%",        "effects": [{ "stat": "dmg_mult", "mul": 1.15 }] },
	{ "id": "firerate", "icon": "🔥", "name": "快速扳机", "desc": "射速 +12%",               "effects": [{ "stat": "fire_rate_mult", "mul": 1.12 }] },
	{ "id": "reload",   "icon": "⚡", "name": "战术换弹", "desc": "换弹速度 +20%",            "effects": [{ "stat": "reload_speed_mult", "mul": 1.2 }] },
	{ "id": "kick_cd",  "icon": "🦵", "name": "铁腿功",   "desc": "踹击冷却 -25%",            "effects": [{ "stat": "kick_cd_mult", "mul": 0.75 }] },
	{ "id": "kick_pow", "icon": "👢", "name": "重靴",     "desc": "踹击伤害与击退 +40%",      "effects": [{ "stat": "kick_power_mult", "mul": 1.4 }] },
	{ "id": "mag",      "icon": "📦", "name": "弹匣扩容", "desc": "所有武器弹匣 +25%",        "effects": [{ "stat": "mag_mult", "mul": 1.25 }] },
	{ "id": "hp",       "icon": "❤", "name": "强化体魄", "desc": "生命上限 +25（并回复25）", "effects": [{ "stat": "max_hp_add", "add": 25.0 }] },
	{ "id": "speed",    "icon": "👟", "name": "跑鞋",     "desc": "移动速度 +10%",            "effects": [{ "stat": "move_speed_mult", "mul": 1.1 }] },
	{ "id": "coin",     "icon": "💰", "name": "生意头脑", "desc": "金币收益 +20%",            "effects": [{ "stat": "coin_mult", "mul": 1.2 }] },
	{ "id": "pierce",   "icon": "🎯", "name": "穿甲弹",   "desc": "子弹额外穿透 1 个敌人",    "effects": [{ "stat": "pierce_add", "add": 1 }] },
	{ "id": "vampire",  "icon": "🩸", "name": "肾上腺素", "desc": "每次击杀回复 2 点生命",    "effects": [{ "stat": "heal_on_kill", "add": 2.0 }] },
]

# 随机抽取 n 个不重复奖励
static func roll(n: int) -> Array:
	var pool := PERKS.duplicate()
	pool.shuffle()
	return pool.slice(0, n)

# 武器数据表。新增武器只需要在这里加一条，不用改逻辑代码。
class_name WeaponData

const WEAPONS := {
	"pistol": {
		"id": "pistol",
		"name": "M1911 手枪",
		"damage": 14.0,        # 单颗弹丸伤害
		"pellets": 1,          # 每次开火弹丸数
		"spread_deg": 3.0,     # 散布角度
		"fire_interval": 0.22, # 开火间隔（秒）
		"auto": false,         # false = 点一下打一发
		"mag_size": 12,
		"reload_time": 1.1,
		"bullet_speed": 950.0,
		"pierce": 0,           # 可穿透敌人数
		"range": 1600.0,       # 射程
		"infinite_reserve": true,
		"reserve_max": 0,
		"price": 0,
		"desc": "可靠的老伙计，备弹无限，永远不会让你空手。",
	},
	"shotgun": {
		"id": "shotgun",
		"name": "雷明顿 870 霰弹枪",
		"damage": 9.0,
		"pellets": 7,
		"spread_deg": 16.0,
		"fire_interval": 0.85,
		"auto": false,
		"mag_size": 6,
		"reload_time": 2.4,
		"bullet_speed": 800.0,
		"pierce": 0,
		"range": 420.0,
		"infinite_reserve": false,
		"reserve_max": 48,
		"price": 150,
		"desc": "近距离一炮糊脸，7 颗弹丸撕碎贴脸的僵尸。射程短。",
	},
}

# 敌人数据表。后续新增僵尸类型（坦克/自爆/远程）都在这里加。
# sprite = assets/sprites/ 下的贴图前缀；anim_fps = 走路动画帧率。
class_name EnemyData

const ENEMIES := {
	"walker": {
		"id": "walker",
		"name": "蹒跚者",
		"sprite": "walker",
		"anim_fps": 6.0,
		"hp": 32.0,
		"speed": 62.0,
		"damage": 10.0,
		"attack_interval": 1.0,
		"radius": 36.0,
		"coin": 6,
	},
	"runner": {
		"id": "runner",
		"name": "奔跑者",
		"sprite": "runner",
		"anim_fps": 12.0,
		"hp": 20.0,
		"speed": 150.0,
		"damage": 8.0,
		"attack_interval": 0.9,
		"radius": 34.0,
		"coin": 9,
	},
}

# 全局配置：画面尺寸、街道可行走带、玩家基础属性
class_name Config

const W := 1280.0
const H := 720.0

# 街道可行走区域（伪纵深横板）
const BAND_TOP := 480.0
const BAND_BOTTOM := 660.0

const PLAYER := {
	"base_max_hp": 100.0,
	"base_speed": 230.0,
	"radius": 16.0,
	"kick_cooldown": 1.3,   # 踹击冷却（秒）
	"kick_radius": 85.0,    # 踹击范围
	"kick_damage": 10.0,    # 踹击伤害
	"kick_knockback": 320.0,# 击退力度
	"kick_stun": 0.5,       # 硬直时间（秒）
}

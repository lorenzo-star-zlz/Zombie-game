# 全局配置：画面尺寸、街道可行走带、玩家基础属性
class_name Config

const W := 1280.0
const H := 720.0

# 角色渲染：40x36 画布 × 8 倍 = 288px 高（约占屏高 40%，对齐概念截图）
const SPRITE_SCALE := 1.5
const SPRITE_OFFSET_Y := -144.0   # 画布脚底在最后一行 → 精灵中心在脚底上方 144px
const AIM_HEIGHT := 200.0         # 持枪高度（脚底上方），子弹从这里射出

# 街道可行走区域（伪纵深横板，按截图：马路 312~552，脚底活动带取中上段）
const BAND_TOP := 370.0
const BAND_BOTTOM := 540.0

const PLAYER := {
	"base_max_hp": 100.0,
	"base_speed": 200.0,    # 写实向机动性；再乘当前武器 move_mult（枪越大越慢）
	"radius": 38.0,
	"kick_cooldown": 1.3,   # 踹击冷却（秒）
	"kick_radius": 180.0,   # 踹击范围
	"kick_damage": 10.0,    # 踹击伤害
	"kick_knockback": 420.0,# 击退力度
	"kick_stun": 0.5,       # 硬直时间（秒）
}

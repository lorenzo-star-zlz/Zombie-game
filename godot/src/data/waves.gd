# 天数/波次数据。第 N 天夜晚的尸潮强度由这里决定。
class_name WaveData

const TOTAL_DAYS := 10

static func night_config(day: int) -> Dictionary:
	return {
		"count": 8 + day * 5,                              # 当晚僵尸总数
		"spawn_interval": maxf(0.35, 1.5 - day * 0.1),     # 出怪间隔
		"hp_mult": 1.0 + (day - 1) * 0.22,
		"speed_mult": 1.0 + (day - 1) * 0.05,
		"dmg_mult": 1.0 + (day - 1) * 0.12,
		"clear_bonus": 40 + day * 15,                      # 通宵奖励金币
		"pool": ["walker"],                                # 本晚僵尸类型池
	}

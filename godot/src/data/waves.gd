# 天数/波次数据。第 N 天夜晚的尸潮强度由这里决定。
class_name WaveData

const TOTAL_DAYS := 10

# pool 用重复条目做权重：第 2 天起混入奔跑者，逐晚增多（最多约 4 成）
static func night_config(day: int) -> Dictionary:
	var pool: Array = []
	for i in range(6):
		pool.append("walker")
	for i in range(clampi(day - 1, 0, 4)):
		pool.append("runner")
	return {
		"count": 8 + day * 5,                              # 当晚僵尸总数
		"spawn_interval": maxf(0.35, 1.5 - day * 0.1),     # 出怪间隔
		"hp_mult": 1.0 + (day - 1) * 0.22,
		"speed_mult": 1.0 + (day - 1) * 0.05,
		"dmg_mult": 1.0 + (day - 1) * 0.12,
		"clear_bonus": 40 + day * 15,                      # 通宵奖励金币
		"pool": pool,                                      # 本晚僵尸类型池
	}

// 天数/波次数据。第 N 天夜晚的尸潮强度由这里决定。
export const TOTAL_DAYS = 10;

export function getNightConfig(day) {
  return {
    // 当晚僵尸总数
    count: 8 + day * 5,
    // 出怪间隔（秒），随天数缩短
    spawnInterval: Math.max(0.35, 1.5 - day * 0.1),
    // 属性缩放
    hpMult: 1 + (day - 1) * 0.22,
    speedMult: 1 + (day - 1) * 0.05,
    dmgMult: 1 + (day - 1) * 0.12,
    // 通宵奖励金币
    clearBonus: 40 + day * 15,
    // 本晚出现的僵尸类型池（后续扩展：按天解锁新类型）
    pool: ['walker'],
  };
}

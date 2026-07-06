// 全局配置：画面尺寸、可行走区域、基础参数
export const CONFIG = {
  W: 1280,
  H: 720,

  // 街道可行走区域（伪纵深横板：玩家/僵尸只能在这条带里上下移动）
  BAND_TOP: 430,
  BAND_BOTTOM: 660,

  // 玩家基础属性（可被肉鸽奖励修改）
  PLAYER: {
    baseMaxHp: 100,
    baseSpeed: 230,
    radius: 16,
    kickCooldown: 1.3,   // 踹击冷却（秒）
    kickRadius: 85,      // 踹击范围
    kickDamage: 10,      // 踹击伤害
    kickKnockback: 320,  // 击退力度
    kickStun: 0.5,       // 硬直时间（秒）
  },
};

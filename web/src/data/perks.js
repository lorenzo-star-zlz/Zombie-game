// 肉鸽奖励数据表。effects 为声明式修改：
//   { stat: 'dmgMult', mul: 1.15 }  → mods.dmgMult *= 1.15
//   { stat: 'maxHpAdd', add: 25 }   → mods.maxHpAdd += 25
// 玩家 mods 字段一览（在 player.js 中初始化）：
//   dmgMult / fireRateMult / reloadSpeedMult / moveSpeedMult / coinMult
//   kickCdMult / kickPowerMult / magMult / pierceAdd / maxHpAdd / healOnKill
export const PERKS = [
  { id: 'dmg',      icon: '💥', name: '强力弹头', desc: '所有武器伤害 +15%',        effects: [{ stat: 'dmgMult', mul: 1.15 }] },
  { id: 'firerate', icon: '🔥', name: '快速扳机', desc: '射速 +12%',               effects: [{ stat: 'fireRateMult', mul: 1.12 }] },
  { id: 'reload',   icon: '⚡', name: '战术换弹', desc: '换弹速度 +20%',            effects: [{ stat: 'reloadSpeedMult', mul: 1.2 }] },
  { id: 'kick_cd',  icon: '🦵', name: '铁腿功',   desc: '踹击冷却 -25%',            effects: [{ stat: 'kickCdMult', mul: 0.75 }] },
  { id: 'kick_pow', icon: '👢', name: '重靴',     desc: '踹击伤害与击退 +40%',      effects: [{ stat: 'kickPowerMult', mul: 1.4 }] },
  { id: 'mag',      icon: '📦', name: '弹匣扩容', desc: '所有武器弹匣 +25%',        effects: [{ stat: 'magMult', mul: 1.25 }] },
  { id: 'hp',       icon: '❤️', name: '强化体魄', desc: '生命上限 +25（并回复25）', effects: [{ stat: 'maxHpAdd', add: 25 }] },
  { id: 'speed',    icon: '👟', name: '跑鞋',     desc: '移动速度 +10%',            effects: [{ stat: 'moveSpeedMult', mul: 1.1 }] },
  { id: 'coin',     icon: '💰', name: '生意头脑', desc: '金币收益 +20%',            effects: [{ stat: 'coinMult', mul: 1.2 }] },
  { id: 'pierce',   icon: '🎯', name: '穿甲弹',   desc: '子弹额外穿透 1 个敌人',    effects: [{ stat: 'pierceAdd', add: 1 }] },
  { id: 'vampire',  icon: '🩸', name: '肾上腺素', desc: '每次击杀回复 2 点生命',    effects: [{ stat: 'healOnKill', add: 2 }] },
];

// 随机抽取 n 个不重复奖励
export function rollPerks(n) {
  const pool = [...PERKS];
  const out = [];
  while (out.length < n && pool.length > 0) {
    const i = Math.floor(Math.random() * pool.length);
    out.push(pool.splice(i, 1)[0]);
  }
  return out;
}

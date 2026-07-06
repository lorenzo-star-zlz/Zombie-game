// 商店条目。available(game) 决定是否显示可买；buy(game) 执行购买效果。
// priceGrowth：每买一次价格乘以该系数（用于可重复升级）。
export const SHOP_ITEMS = [
  {
    id: 'medkit',
    icon: '🩹',
    name: '急救包',
    desc: '生命完全恢复',
    basePrice: 40,
    available: (g) => g.player.hp < g.player.maxHp,
    buy: (g) => { g.player.hp = g.player.maxHp; },
  },
  {
    id: 'ammo',
    icon: '🔋',
    name: '弹药补给',
    desc: '所有武器备弹补满',
    basePrice: 25,
    available: (g) => g.player.weapons.some(w => !w.def.infiniteReserve && w.reserve < w.def.reserveMax),
    buy: (g) => {
      for (const w of g.player.weapons) {
        if (!w.def.infiniteReserve) w.reserve = w.def.reserveMax;
      }
    },
  },
  {
    id: 'buy_shotgun',
    icon: '🔫',
    name: '购买霰弹枪',
    desc: '雷明顿 870：近距离一炮糊脸（按 Q 或 2 切换）',
    basePrice: 150,
    available: (g) => !g.player.hasWeapon('shotgun'),
    buy: (g) => { g.player.addWeapon('shotgun'); },
  },
  {
    id: 'gunsmith',
    icon: '🔧',
    name: '枪匠保养',
    desc: '所有武器伤害永久 +5%（可重复购买，价格递增）',
    basePrice: 70,
    priceGrowth: 1.5,
    available: () => true,
    buy: (g) => { g.player.mods.dmgMult *= 1.05; },
  },
];

// 敌人数据表。后续新增僵尸类型（快速/坦克/自爆/远程）都在这里加。
export const ENEMIES = {
  walker: {
    id: 'walker',
    name: '蹒跚者',
    hp: 32,
    speed: 55,
    damage: 10,
    attackInterval: 1.0, // 攻击间隔（秒）
    radius: 16,
    coin: 6,             // 击杀掉落金币
    color: '#6faa4f',
    darkColor: '#4c7a35',
  },
};

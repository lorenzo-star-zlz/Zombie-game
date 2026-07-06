// 武器数据表。新增武器只需要在这里加一条，不用改任何逻辑代码。
// 字段说明：
//   damage        单发/单颗弹丸伤害
//   pellets       每次开火发射的弹丸数（霰弹枪 > 1）
//   spreadDeg     散布角度（度）
//   fireInterval  开火间隔（秒），受"射速"加成影响
//   auto          true = 按住连发；false = 点一下打一发
//   magSize       弹匣容量，受"弹匣"加成影响
//   reloadTime    换弹时间（秒），受"换弹"加成影响
//   bulletSpeed   子弹飞行速度（像素/秒）
//   pierce        可穿透敌人数量，受"穿透"加成影响
//   range         射程（像素），超出后子弹消失（霰弹枪短）
//   infiniteReserve  备弹是否无限（保底武器 = true，防止卡死）
//   reserveMax    备弹上限
//   price         商店价格（0 = 初始武器）
export const WEAPONS = {
  pistol: {
    id: 'pistol',
    name: 'M1911 手枪',
    damage: 14,
    pellets: 1,
    spreadDeg: 3,
    fireInterval: 0.22,
    auto: false,
    magSize: 12,
    reloadTime: 1.1,
    bulletSpeed: 950,
    pierce: 0,
    range: 1600,
    infiniteReserve: true,
    reserveMax: Infinity,
    price: 0,
    desc: '可靠的老伙计，备弹无限，永远不会让你空手。',
  },
  shotgun: {
    id: 'shotgun',
    name: '雷明顿 870 霰弹枪',
    damage: 9,
    pellets: 7,
    spreadDeg: 16,
    fireInterval: 0.85,
    auto: false,
    magSize: 6,
    reloadTime: 2.4,
    bulletSpeed: 800,
    pierce: 0,
    range: 420,
    infiniteReserve: false,
    reserveMax: 48,
    price: 150,
    desc: '近距离一炮糊脸，7 颗弹丸撕碎贴脸的僵尸。射程短。',
  },
};

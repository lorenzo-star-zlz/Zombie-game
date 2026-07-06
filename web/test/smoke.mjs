// 无头冒烟测试：不开浏览器验证核心逻辑（node test/smoke.mjs）
import { CONFIG } from '../src/config.js';
import { WEAPONS } from '../src/data/weapons.js';
import { ENEMIES } from '../src/data/enemies.js';
import { getNightConfig, TOTAL_DAYS } from '../src/data/waves.js';
import { PERKS, rollPerks } from '../src/data/perks.js';
import { SHOP_ITEMS } from '../src/data/shop.js';
import { Player } from '../src/entities/player.js';
import { Zombie } from '../src/entities/zombie.js';
import { Bullet } from '../src/entities/bullet.js';
import { Particles } from '../src/systems/particles.js';
// 仅验证模块可加载（不实例化，构造函数才碰 DOM）
import '../src/render.js';
import '../src/ui/hud.js';
import '../src/ui/screens.js';
import '../src/game.js';

let passed = 0, failed = 0;
function check(name, cond) {
  if (cond) { passed++; console.log(`  ✓ ${name}`); }
  else { failed++; console.error(`  ✗ ${name}`); }
}

const stubInput = (over = {}) => ({
  keys: new Set(), mouseX: 640, mouseY: 400,
  mouseDown: false, mousePressed: false,
  isDown: (k) => over.down?.includes(k) ?? false,
  wasPressed: (k) => over.pressed?.includes(k) ?? false,
  ...over,
});

console.log('数据表:');
check('至少 2 把武器', Object.keys(WEAPONS).length >= 2);
check('手枪备弹无限', WEAPONS.pistol.infiniteReserve === true);
check('霰弹枪多弹丸', WEAPONS.shotgun.pellets > 1);
check('至少 1 种僵尸', Object.keys(ENEMIES).length >= 1);
check('至少 8 种肉鸽奖励', PERKS.length >= 8);
check('商店至少 3 项', SHOP_ITEMS.length >= 3);
for (let d = 1; d <= TOTAL_DAYS; d++) {
  const c = getNightConfig(d);
  if (c.count <= 0 || c.spawnInterval <= 0 || c.hpMult <= 0) {
    check(`第 ${d} 天波次配置有效`, false);
  }
}
check(`1-${TOTAL_DAYS} 天波次配置有效`, true);
check('第10天比第1天更难', getNightConfig(10).count > getNightConfig(1).count);
const rolled = rollPerks(3);
check('抽 3 个奖励不重复', new Set(rolled.map(p => p.id)).size === 3);

console.log('玩家:');
const p = new Player();
check('初始满血', p.hp === p.maxHp);
check('初始只有手枪', p.weapons.length === 1 && p.weapon.def.id === 'pistol');
p.update(1, stubInput({ down: ['d'] }));
check('向右移动生效', p.x > CONFIG.W / 2);
p.update(20, stubInput({ down: ['d'] }));
check('移动不出右边界', p.x <= CONFIG.W - 30);
p.update(20, stubInput({ down: ['w'] }));
check('上移被限制在街道带内', p.y === CONFIG.BAND_TOP);

const shots = p.tryFire(stubInput({ mousePressed: true }));
check('手枪开火返回 1 颗子弹', shots && shots.length === 1);
check('开火消耗弹匣', p.weapon.mag === WEAPONS.pistol.magSize - 1);
check('开火后进入射击冷却', p.fireTimer > 0);
check('冷却中不能开火', p.tryFire(stubInput({ mousePressed: true })) === null);

p.addWeapon('shotgun');
check('购买霰弹枪后有 2 把武器', p.weapons.length === 2);
p.switchWeapon(1);
p.fireTimer = 0;
const pellets = p.tryFire(stubInput({ mousePressed: true }));
check('霰弹枪一次打出 7 颗弹丸', pellets && pellets.length === 7);

p.weapon.mag = 0;
p.startReload();
check('空弹匣可以换弹', p.reloadTimer > 0);
p.update(10, stubInput());
check('换弹完成后弹匣补满', p.weapon.mag === p.magSizeOf(p.weapon));
check('换弹消耗备弹', p.weapon.reserve < WEAPONS.shotgun.reserveMax);

const kick = p.tryKick(stubInput({ pressed: [' '] }));
check('踹击返回参数', kick && kick.radius > 0);
check('踹击进入冷却', p.kickTimer > 0);
check('冷却中不能踹', p.tryKick(stubInput({ pressed: [' '] })) === null);

console.log('肉鸽加成:');
const p2 = new Player();
const dmgPerk = PERKS.find(x => x.id === 'dmg');
const before = p2.mods.dmgMult;
p2.applyPerk(dmgPerk);
check('伤害加成生效', p2.mods.dmgMult > before);
const hpPerk = PERKS.find(x => x.id === 'hp');
p2.applyPerk(hpPerk);
check('生命上限加成生效', p2.maxHp === 125);
const magPerk = PERKS.find(x => x.id === 'mag');
p2.applyPerk(magPerk);
check('弹匣加成生效', p2.magSizeOf(p2.weapon) === Math.round(12 * 1.25));

console.log('僵尸与子弹:');
const scale = getNightConfig(1);
const z = new Zombie(ENEMIES.walker, 100, 500, scale);
const target = new Player();
target.x = 600; target.y = 500;
const zx0 = z.x;
z.update(0.5, target);
check('僵尸朝玩家移动', z.x > zx0);
const hp0 = target.hp;
z.x = target.x - z.radius - target.radius; z.y = target.y; z.attackTimer = 0;
z.update(0.1, target);
check('近身攻击造成伤害', target.hp < hp0);

const b = new Bullet({ x: 0, y: 500, vx: 900, vy: 0, damage: 14, pierce: 0, maxDist: 400 });
b.update(0.2);
check('子弹飞行', b.x > 100);
b.update(0.3);
check('超射程后消失', b.dead === true);

const ps = new Particles();
ps.burst(100, 100, '#fff', 5);
ps.text(100, 100, '+6');
ps.update(0.1);
check('粒子系统运行', ps.list.length > 0 && ps.texts.length > 0);
ps.update(5);
check('粒子过期清理', ps.list.length === 0 && ps.texts.length === 0);

console.log(`\n结果: ${passed} 通过, ${failed} 失败`);
process.exit(failed > 0 ? 1 : 0);

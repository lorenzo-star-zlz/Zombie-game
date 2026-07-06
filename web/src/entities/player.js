import { CONFIG } from '../config.js';
import { WEAPONS } from '../data/weapons.js';

// 玩家：移动、生命、武器背包、换弹、踹击冷却。
// 所有肉鸽加成集中在 this.mods，数值计算时统一乘上。
export class Player {
  constructor() {
    const P = CONFIG.PLAYER;
    this.x = CONFIG.W / 2;
    this.y = (CONFIG.BAND_TOP + CONFIG.BAND_BOTTOM) / 2;
    this.radius = P.radius;
    this.baseMaxHp = P.baseMaxHp;
    this.baseSpeed = P.baseSpeed;

    this.mods = {
      dmgMult: 1,
      fireRateMult: 1,
      reloadSpeedMult: 1,
      moveSpeedMult: 1,
      coinMult: 1,
      kickCdMult: 1,
      kickPowerMult: 1,
      magMult: 1,
      pierceAdd: 0,
      maxHpAdd: 0,
      healOnKill: 0,
    };

    this.weapons = [this._makeWeapon('pistol')];
    this.weaponIndex = 0;

    this.hp = this.maxHp;
    this.reloadTimer = 0;   // >0 表示正在换弹
    this.fireTimer = 0;     // >0 表示开火冷却中
    this.kickTimer = 0;     // >0 表示踹击冷却中
    this.aimAngle = 0;
    this.hurtFlash = 0;     // 受击红闪
  }

  get maxHp() { return this.baseMaxHp + this.mods.maxHpAdd; }
  get speed() { return this.baseSpeed * this.mods.moveSpeedMult; }
  get weapon() { return this.weapons[this.weaponIndex]; }

  _makeWeapon(id) {
    const def = WEAPONS[id];
    return { def, mag: def.magSize, reserve: def.infiniteReserve ? Infinity : def.reserveMax };
  }

  hasWeapon(id) { return this.weapons.some(w => w.def.id === id); }

  addWeapon(id) {
    if (this.hasWeapon(id)) return;
    this.weapons.push(this._makeWeapon(id));
  }

  // 弹匣容量（受加成影响）
  magSizeOf(w) { return Math.round(w.def.magSize * this.mods.magMult); }

  switchWeapon(index) {
    if (index === this.weaponIndex || index < 0 || index >= this.weapons.length) return;
    this.weaponIndex = index;
    this.reloadTimer = 0; // 切枪打断换弹
  }

  cycleWeapon() {
    this.switchWeapon((this.weaponIndex + 1) % this.weapons.length);
  }

  startReload() {
    const w = this.weapon;
    if (this.reloadTimer > 0) return;
    if (w.mag >= this.magSizeOf(w) || w.reserve <= 0) return;
    this.reloadTimer = w.def.reloadTime / this.mods.reloadSpeedMult;
  }

  takeDamage(dmg) {
    this.hp -= dmg;
    this.hurtFlash = 0.25;
  }

  applyPerk(perk) {
    for (const e of perk.effects) {
      if (e.mul !== undefined) this.mods[e.stat] *= e.mul;
      if (e.add !== undefined) this.mods[e.stat] += e.add;
    }
    // 加生命上限时同步回复等量生命
    if (perk.effects.some(e => e.stat === 'maxHpAdd')) {
      this.hp = Math.min(this.maxHp, this.hp + perk.effects.find(e => e.stat === 'maxHpAdd').add);
    }
  }

  update(dt, input) {
    // 移动（WASD + 方向键）
    let dx = 0, dy = 0;
    if (input.isDown('a') || input.isDown('arrowleft')) dx -= 1;
    if (input.isDown('d') || input.isDown('arrowright')) dx += 1;
    if (input.isDown('w') || input.isDown('arrowup')) dy -= 1;
    if (input.isDown('s') || input.isDown('arrowdown')) dy += 1;
    if (dx !== 0 && dy !== 0) { dx *= 0.7071; dy *= 0.7071; }
    this.x += dx * this.speed * dt;
    this.y += dy * this.speed * dt;
    this.x = Math.max(30, Math.min(CONFIG.W - 30, this.x));
    this.y = Math.max(CONFIG.BAND_TOP, Math.min(CONFIG.BAND_BOTTOM, this.y));

    // 瞄准
    this.aimAngle = Math.atan2(input.mouseY - this.y, input.mouseX - this.x);

    // 计时器
    if (this.fireTimer > 0) this.fireTimer -= dt;
    if (this.kickTimer > 0) this.kickTimer -= dt;
    if (this.hurtFlash > 0) this.hurtFlash -= dt;

    // 换弹进度
    if (this.reloadTimer > 0) {
      this.reloadTimer -= dt;
      if (this.reloadTimer <= 0) {
        const w = this.weapon;
        const need = this.magSizeOf(w) - w.mag;
        const take = Math.min(need, w.reserve);
        w.mag += take;
        if (!w.def.infiniteReserve) w.reserve -= take;
      }
    }
  }

  // 尝试开火：返回子弹参数数组（由 game 负责生成子弹），不能开火返回 null
  tryFire(input) {
    const w = this.weapon;
    if (this.reloadTimer > 0 || this.fireTimer > 0) return null;

    const wantFire = w.def.auto ? input.mouseDown : input.mousePressed;
    if (!wantFire) return null;

    if (w.mag <= 0) {
      this.startReload();
      return null;
    }

    w.mag -= 1;
    this.fireTimer = w.def.fireInterval / this.mods.fireRateMult;
    if (w.mag <= 0) this.startReload(); // 打空自动换弹

    const shots = [];
    for (let i = 0; i < w.def.pellets; i++) {
      const spread = (Math.random() - 0.5) * w.def.spreadDeg * Math.PI / 180;
      const ang = this.aimAngle + spread;
      shots.push({
        x: this.x + Math.cos(this.aimAngle) * 24,
        y: this.y + Math.sin(this.aimAngle) * 24 - 6,
        vx: Math.cos(ang) * w.def.bulletSpeed,
        vy: Math.sin(ang) * w.def.bulletSpeed,
        damage: w.def.damage * this.mods.dmgMult,
        pierce: w.def.pierce + this.mods.pierceAdd,
        maxDist: w.def.range,
      });
    }
    return shots;
  }

  // 尝试踹击：返回踹击参数，冷却中返回 null
  tryKick(input) {
    if (this.kickTimer > 0) return null;
    if (!input.wasPressed(' ') && !input.wasPressed('f')) return null;
    const P = CONFIG.PLAYER;
    this.kickTimer = P.kickCooldown * this.mods.kickCdMult;
    return {
      radius: P.kickRadius,
      damage: P.kickDamage * this.mods.kickPowerMult,
      knockback: P.kickKnockback * this.mods.kickPowerMult,
      stun: P.kickStun,
    };
  }
}

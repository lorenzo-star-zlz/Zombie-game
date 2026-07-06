import { CONFIG } from '../config.js';

// 僵尸：朝玩家移动，近身攻击。支持击退与硬直（被踹击时）。
export class Zombie {
  constructor(def, x, y, scale) {
    this.def = def;
    this.x = x;
    this.y = y;
    this.radius = def.radius;
    this.maxHp = def.hp * scale.hpMult;
    this.hp = this.maxHp;
    // 每只僵尸速度略有随机，避免叠成一条直线
    this.speed = def.speed * scale.speedMult * (0.85 + Math.random() * 0.3);
    this.damage = def.damage * scale.dmgMult;
    this.attackTimer = 0;
    this.kbVx = 0;        // 击退速度
    this.stun = 0;        // 硬直剩余时间
    this.wobble = Math.random() * Math.PI * 2; // 走路摇摆相位
    this.hitFlash = 0;    // 受击白闪
  }

  update(dt, player) {
    this.wobble += dt * 8;
    if (this.attackTimer > 0) this.attackTimer -= dt;
    if (this.hitFlash > 0) this.hitFlash -= dt;
    if (this.stun > 0) this.stun -= dt;

    // 击退位移（指数衰减）
    this.x += this.kbVx * dt;
    this.kbVx *= Math.pow(0.002, dt);

    if (this.stun <= 0) {
      const dx = player.x - this.x;
      const dy = player.y - this.y;
      const d = Math.hypot(dx, dy) || 1;
      if (d > this.radius + player.radius + 2) {
        this.x += (dx / d) * this.speed * dt;
        this.y += (dy / d) * this.speed * dt * 0.8;
      } else if (this.attackTimer <= 0) {
        player.takeDamage(this.damage);
        this.attackTimer = this.def.attackInterval;
      }
    }

    this.y = Math.max(CONFIG.BAND_TOP, Math.min(CONFIG.BAND_BOTTOM, this.y));
  }

  takeDamage(dmg) {
    this.hp -= dmg;
    this.hitFlash = 0.1;
  }
}

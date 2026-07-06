// 子弹：直线飞行，支持穿透与射程限制。
export class Bullet {
  constructor({ x, y, vx, vy, damage, pierce, maxDist }) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.damage = damage;
    this.pierce = pierce;       // 还能穿透几个敌人
    this.maxDist = maxDist || 2000;
    this.traveled = 0;
    this.dead = false;
    this.hitSet = new Set();    // 已命中的敌人（避免同一子弹重复命中）
  }

  update(dt) {
    const mx = this.vx * dt;
    const my = this.vy * dt;
    this.x += mx;
    this.y += my;
    this.traveled += Math.hypot(mx, my);
    if (this.traveled > this.maxDist) this.dead = true;
  }
}

// 极简粒子系统：命中火花、死亡血雾、踹击冲击圈、飘字。
export class Particles {
  constructor() {
    this.list = [];
    this.texts = [];
  }

  burst(x, y, color, count = 6, speed = 120) {
    for (let i = 0; i < count; i++) {
      const a = Math.random() * Math.PI * 2;
      const s = speed * (0.4 + Math.random() * 0.8);
      this.list.push({
        x, y,
        vx: Math.cos(a) * s,
        vy: Math.sin(a) * s - 40,
        life: 0.35 + Math.random() * 0.25,
        maxLife: 0.5,
        size: 2 + Math.random() * 3,
        color,
      });
    }
  }

  ring(x, y, radius, color) {
    this.list.push({ x, y, ring: true, radius: 10, targetRadius: radius, life: 0.25, maxLife: 0.25, color });
  }

  text(x, y, str, color = '#fff') {
    this.texts.push({ x, y, str, color, life: 0.8 });
  }

  update(dt) {
    for (const p of this.list) {
      p.life -= dt;
      if (p.ring) {
        p.radius += (p.targetRadius - p.radius) * dt * 18;
      } else {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 300 * dt;
      }
    }
    this.list = this.list.filter(p => p.life > 0);

    for (const t of this.texts) { t.life -= dt; t.y -= 40 * dt; }
    this.texts = this.texts.filter(t => t.life > 0);
  }

  render(ctx) {
    for (const p of this.list) {
      ctx.globalAlpha = Math.max(0, p.life / p.maxLife);
      if (p.ring) {
        ctx.strokeStyle = p.color;
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        ctx.stroke();
      } else {
        ctx.fillStyle = p.color;
        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fill();
      }
    }
    ctx.globalAlpha = 1;
    ctx.font = 'bold 15px sans-serif';
    ctx.textAlign = 'center';
    for (const t of this.texts) {
      ctx.globalAlpha = Math.min(1, t.life * 2);
      ctx.fillStyle = t.color;
      ctx.fillText(t.str, t.x, t.y);
    }
    ctx.globalAlpha = 1;
  }
}

import { CONFIG } from './config.js';

// 占位卡通渲染：全部用几何图形画，后续换美术资源只需改这个文件。

// 背景建筑剪影（随机但固定：启动时生成一次）
const buildings = [];
(function genBuildings() {
  let x = -20;
  while (x < CONFIG.W + 40) {
    const w = 90 + Math.random() * 130;
    const h = 120 + Math.random() * 200;
    const windows = [];
    for (let wx = 14; wx < w - 22; wx += 30) {
      for (let wy = 16; wy < h - 24; wy += 38) {
        if (Math.random() < 0.55) windows.push([wx, wy]);
      }
    }
    buildings.push({ x, w, h, windows, hue: 230 + Math.random() * 40 });
    x += w + 8 + Math.random() * 24;
  }
})();

export function drawBackground(ctx, phase) {
  const W = CONFIG.W, H = CONFIG.H;
  const night = phase === 'night';

  // 天空
  const sky = ctx.createLinearGradient(0, 0, 0, CONFIG.BAND_TOP);
  if (night) {
    sky.addColorStop(0, '#0d0b26');
    sky.addColorStop(1, '#2a1f4d');
  } else {
    sky.addColorStop(0, '#7ec8f2');
    sky.addColorStop(1, '#cfeaf7');
  }
  ctx.fillStyle = sky;
  ctx.fillRect(0, 0, W, CONFIG.BAND_TOP);

  // 太阳 / 月亮
  ctx.beginPath();
  ctx.arc(W - 180, 90, 38, 0, Math.PI * 2);
  ctx.fillStyle = night ? '#e8e6d8' : '#ffd93b';
  ctx.fill();
  if (night) {
    // 月亮阴影
    ctx.beginPath();
    ctx.arc(W - 195, 82, 32, 0, Math.PI * 2);
    ctx.fillStyle = '#0d0b26';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(W - 180, 90, 38, -0.6, 1.2);
  }

  // 建筑剪影
  for (const b of buildings) {
    ctx.fillStyle = night ? `hsl(${b.hue}, 30%, 12%)` : `hsl(${b.hue}, 22%, 62%)`;
    ctx.fillRect(b.x, CONFIG.BAND_TOP - b.h, b.w, b.h);
    ctx.fillStyle = night ? '#ffd166' : 'rgba(255,255,255,0.5)';
    for (const [wx, wy] of b.windows) {
      ctx.fillRect(b.x + wx, CONFIG.BAND_TOP - b.h + wy, 14, 18);
    }
  }

  // 马路（可行走区域）
  ctx.fillStyle = night ? '#2b2b34' : '#565660';
  ctx.fillRect(0, CONFIG.BAND_TOP, W, H - CONFIG.BAND_TOP);

  // 人行道边缘
  ctx.fillStyle = night ? '#3d3d48' : '#75757f';
  ctx.fillRect(0, CONFIG.BAND_TOP, W, 14);

  // 马路虚线
  ctx.strokeStyle = night ? 'rgba(255,255,255,0.25)' : 'rgba(255,255,255,0.5)';
  ctx.lineWidth = 4;
  ctx.setLineDash([36, 28]);
  ctx.beginPath();
  const midY = (CONFIG.BAND_TOP + CONFIG.BAND_BOTTOM) / 2 + 20;
  ctx.moveTo(0, midY);
  ctx.lineTo(W, midY);
  ctx.stroke();
  ctx.setLineDash([]);
}

export function drawPlayer(ctx, p) {
  const flip = Math.cos(p.aimAngle) < 0 ? -1 : 1;

  // 阴影
  drawShadow(ctx, p.x, p.y, 20);

  ctx.save();
  ctx.translate(p.x, p.y);

  // 受击红闪
  const bodyColor = p.hurtFlash > 0 ? '#ff6b6b' : '#4d96ff';

  // 腿
  ctx.strokeStyle = '#2b3a67';
  ctx.lineWidth = 6;
  ctx.lineCap = 'round';
  ctx.beginPath();
  ctx.moveTo(-6, 6); ctx.lineTo(-7, 22);
  ctx.moveTo(6, 6); ctx.lineTo(7, 22);
  ctx.stroke();

  // 身体（胶囊）
  ctx.fillStyle = bodyColor;
  ctx.strokeStyle = '#1d2b52';
  ctx.lineWidth = 3;
  roundRect(ctx, -12, -14, 24, 26, 10);
  ctx.fill(); ctx.stroke();

  // 头
  ctx.beginPath();
  ctx.arc(0, -26, 11, 0, Math.PI * 2);
  ctx.fillStyle = '#ffd8b5';
  ctx.fill(); ctx.stroke();
  // 眼睛看向瞄准方向
  ctx.fillStyle = '#222';
  ctx.beginPath();
  ctx.arc(4 * flip, -27, 2.2, 0, Math.PI * 2);
  ctx.fill();

  // 枪（一条粗线指向鼠标）
  ctx.save();
  ctx.rotate(p.aimAngle);
  ctx.fillStyle = '#2f2f2f';
  ctx.strokeStyle = '#111';
  ctx.lineWidth = 2;
  roundRect(ctx, 8, -4 - 6, 26, 8, 3);
  ctx.fill(); ctx.stroke();
  ctx.restore();

  // 换弹提示圈
  if (p.reloadTimer > 0) {
    const total = p.weapon.def.reloadTime / p.mods.reloadSpeedMult;
    const t = 1 - p.reloadTimer / total;
    ctx.strokeStyle = '#ffd166';
    ctx.lineWidth = 4;
    ctx.beginPath();
    ctx.arc(0, -48, 10, -Math.PI / 2, -Math.PI / 2 + t * Math.PI * 2);
    ctx.stroke();
  }

  ctx.restore();
}

export function drawZombie(ctx, z) {
  drawShadow(ctx, z.x, z.y, 18);

  ctx.save();
  ctx.translate(z.x, z.y);
  ctx.rotate(Math.sin(z.wobble) * 0.08); // 走路摇摆

  const body = z.hitFlash > 0 ? '#ffffff' : z.def.color;
  const dark = z.hitFlash > 0 ? '#dddddd' : z.def.darkColor;

  // 腿
  ctx.strokeStyle = dark;
  ctx.lineWidth = 6;
  ctx.lineCap = 'round';
  const step = Math.sin(z.wobble) * 5;
  ctx.beginPath();
  ctx.moveTo(-5, 6); ctx.lineTo(-6 + step, 22);
  ctx.moveTo(5, 6); ctx.lineTo(6 - step, 22);
  ctx.stroke();

  // 身体
  ctx.fillStyle = body;
  ctx.strokeStyle = '#2d4a1e';
  ctx.lineWidth = 3;
  roundRect(ctx, -12, -14, 24, 26, 10);
  ctx.fill(); ctx.stroke();

  // 前伸的手臂（僵尸经典姿势）
  ctx.strokeStyle = body;
  ctx.lineWidth = 5;
  ctx.beginPath();
  ctx.moveTo(0, -6); ctx.lineTo(16, -8 + Math.sin(z.wobble * 1.3) * 3);
  ctx.stroke();

  // 头
  ctx.beginPath();
  ctx.arc(0, -26, 11, 0, Math.PI * 2);
  ctx.fillStyle = body;
  ctx.fill();
  ctx.strokeStyle = '#2d4a1e';
  ctx.lineWidth = 3;
  ctx.stroke();
  // 眼睛（红点）
  ctx.fillStyle = '#c1121f';
  ctx.beginPath();
  ctx.arc(-4, -27, 2.5, 0, Math.PI * 2);
  ctx.arc(4, -27, 2.5, 0, Math.PI * 2);
  ctx.fill();

  ctx.restore();

  // 血条（受伤才显示）
  if (z.hp < z.maxHp) {
    const w = 30;
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(z.x - w / 2, z.y - 48, w, 5);
    ctx.fillStyle = '#7ee787';
    ctx.fillRect(z.x - w / 2, z.y - 48, w * Math.max(0, z.hp / z.maxHp), 5);
  }
}

export function drawBullet(ctx, b) {
  const ang = Math.atan2(b.vy, b.vx);
  ctx.save();
  ctx.translate(b.x, b.y);
  ctx.rotate(ang);
  ctx.fillStyle = '#ffd93b';
  roundRect(ctx, -8, -2, 14, 4, 2);
  ctx.fill();
  ctx.restore();
}

export function drawCrosshair(ctx, x, y) {
  ctx.strokeStyle = 'rgba(255,255,255,0.9)';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(x, y, 10, 0, Math.PI * 2);
  ctx.moveTo(x - 16, y); ctx.lineTo(x - 6, y);
  ctx.moveTo(x + 6, y); ctx.lineTo(x + 16, y);
  ctx.moveTo(x, y - 16); ctx.lineTo(x, y - 6);
  ctx.moveTo(x, y + 6); ctx.lineTo(x, y + 16);
  ctx.stroke();
}

function drawShadow(ctx, x, y, r) {
  ctx.fillStyle = 'rgba(0,0,0,0.3)';
  ctx.beginPath();
  ctx.ellipse(x, y + 24, r, r * 0.35, 0, 0, Math.PI * 2);
  ctx.fill();
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

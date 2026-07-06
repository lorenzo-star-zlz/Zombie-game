// 像素美术生成器（零依赖）：node tools/gen_sprites.mjs [preview.png输出路径]
// 严格参照概念截图：角色约占屏高 40%（40x36 画布 × 8 倍缩放 = 288px @720p），
// 玩家=灰帽+胡子+蓝衬衫+黑背包+卡其裤，双手前伸持枪；
// 蹒跚者=橙发绿皮+破灰衣+红裤白鞋；奔跑者=前倾裸上身绿皮+深色短裤；
// home.png=画面最左的家园建筑（混凝土墙+木窗+石基）。
import zlib from 'zlib';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(__dirname, '..', 'godot', 'assets', 'sprites');
fs.mkdirSync(OUT, { recursive: true });

// ---------- 极简 PNG 编码 ----------
const CRC_TABLE = (() => {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c;
  }
  return t;
})();
function crc32(buf) {
  let c = -1;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}
function writePNG(file, w, h, rgba) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // RGBA
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0; // filter none
    rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
  }
  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
  fs.writeFileSync(file, png);
  console.log(`  ${path.basename(file)} (${w}x${h})`);
}

// ---------- 画布工具 ----------
const hex = (c) => [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)];
function canvas(w, h) {
  const buf = Buffer.alloc(w * h * 4);
  return {
    w, h, buf,
    px(x, y, c) {
      if (x < 0 || y < 0 || x >= w || y >= h) return;
      const [r, g, b] = hex(c);
      const i = (y * w + x) * 4;
      buf[i] = r; buf[i + 1] = g; buf[i + 2] = b; buf[i + 3] = 255;
    },
    rect(x, y, rw, rh, c) {
      for (let j = y; j < y + rh; j++) for (let i = x; i < x + rw; i++) this.px(i, j, c);
    },
    save(name) { writePNG(path.join(OUT, name), w, h, buf); },
  };
}

// 角色画布统一 40x36，脚底在最后一行 → Godot 里 scale=8、偏移 (0,-144)
const CW = 40, CH = 36;

// ---------- 幸存者（面朝右→，双手前伸持手枪，写实身材比例） ----------
const P = {
  hat: '#7d838c', hatDark: '#5c6169',
  skin: '#e5b88f', skinDark: '#c99a72', beard: '#8a5a33', eye: '#26262e',
  shirt: '#7b93b4', shirtDark: '#617a9c',
  pack: '#33343c', packHi: '#4a4c56',
  pants: '#d8c8a4', pantsDark: '#b5a582',
  shoe: '#4c3226', gun: '#c9cdd2', gunDark: '#8e939a',
};
function drawSurvivorBody(c) {
  // 帽子：帽冠 + 前伸帽檐
  c.rect(16, 0, 7, 2, P.hat);
  c.rect(14, 2, 12, 1, P.hatDark);
  // 脸 + 眼睛（朝右）
  c.rect(15, 3, 8, 3, P.skin);
  c.px(21, 4, P.eye);
  // 络腮胡
  c.rect(15, 6, 8, 2, P.beard);
  c.rect(16, 8, 7, 1, P.beard);
  // 背包（身后=左侧）
  c.rect(11, 10, 5, 9, P.pack);
  c.rect(11, 10, 5, 2, P.packHi);
  // 躯干（衬衫）
  c.rect(16, 9, 9, 10, P.shirt);
  c.rect(16, 17, 9, 2, P.shirtDark);
  // 双臂前伸：袖子 + 前臂 + 托枪副手
  c.rect(25, 10, 6, 2, P.shirtDark);
  c.rect(31, 10, 3, 3, P.skin);
  c.rect(25, 12, 6, 1, P.skin);
  // 手枪：套筒在手上方，枪口伸到 col38（离身体中心 col20 → 144px@8x）
  c.rect(31, 8, 8, 2, P.gun);
  c.rect(34, 10, 2, 2, P.gunDark);
  // 腰带 + 胯
  c.rect(16, 19, 9, 1, P.shoe);
  c.rect(16, 20, 9, 3, P.pants);
}
function drawSurvivor(frame) {
  const c = canvas(CW, CH);
  drawSurvivorBody(c);
  if (frame === 0) {
    // 大跨步剪刀腿（参照截图站姿）：后腿向左下、前腿向右下
    c.rect(15, 23, 3, 2, P.pantsDark); c.rect(21, 23, 3, 2, P.pants);
    c.rect(14, 25, 3, 2, P.pantsDark); c.rect(22, 25, 3, 2, P.pants);
    c.rect(13, 27, 3, 2, P.pantsDark); c.rect(23, 27, 3, 2, P.pants);
    c.rect(12, 29, 3, 2, P.pantsDark); c.rect(24, 29, 3, 2, P.pants);
    c.rect(11, 31, 3, 2, P.pantsDark); c.rect(25, 31, 3, 2, P.pants);
    c.rect(9, 33, 5, 3, P.shoe); c.rect(25, 33, 6, 3, P.shoe);
  } else {
    // 双腿并拢过渡帧
    c.rect(17, 23, 3, 10, P.pantsDark);
    c.rect(20, 23, 3, 10, P.pants);
    c.rect(15, 33, 5, 3, P.shoe);
    c.rect(20, 33, 6, 3, P.shoe);
  }
  c.save(`player_${frame}.png`);
}

// ---------- 蹒跚者（面朝左←）：橙发绿皮、破灰衣、红裤白鞋 ----------
const Z = {
  hair: '#b8542c', skin: '#7ca86a', skinDark: '#5e8650',
  shirt: '#a8adb2', shirtDark: '#878c92',
  pants: '#c1272d', pantsDark: '#8f1d22', patch: '#d8d4c8',
  shoe: '#e8e6df', eye: '#cf3838',
};
function drawWalkerBody(c) {
  // 乱蓬橙发
  c.rect(15, 0, 9, 2, Z.hair);
  c.rect(14, 1, 1, 2, Z.hair); c.px(24, 1, Z.hair); c.px(13, 2, Z.hair);
  c.rect(15, 2, 9, 1, Z.hair);
  // 绿脸（朝左）：红眼 + 暗色嘴
  c.rect(15, 3, 9, 5, Z.skin);
  c.rect(16, 4, 2, 1, Z.eye);
  c.rect(16, 6, 3, 1, Z.skinDark);
  c.rect(15, 8, 9, 1, Z.skinDark);
  // 双臂前伸（朝左）+ 残破袖口 + 垂爪
  c.rect(4, 10, 12, 3, Z.skin);
  c.rect(13, 10, 3, 2, Z.shirtDark);
  c.rect(3, 12, 2, 2, Z.skinDark);
  // 破烂灰衣（破洞露绿皮）
  c.rect(16, 9, 9, 10, Z.shirt);
  c.rect(16, 17, 9, 2, Z.shirtDark);
  c.px(18, 12, Z.skin); c.px(22, 15, Z.skin); c.px(17, 16, Z.skin);
  // 红裤 + 磨白补丁
  c.rect(16, 19, 9, 4, Z.pants);
  c.rect(18, 21, 2, 1, Z.patch);
}
function drawWalker(frame) {
  const c = canvas(CW, CH);
  drawWalkerBody(c);
  if (frame === 0) {
    // 前腿向左迈、后腿在右（面朝左）
    c.rect(15, 23, 3, 2, Z.pants); c.rect(21, 23, 3, 2, Z.pantsDark);
    c.rect(14, 25, 3, 2, Z.pants); c.rect(22, 25, 3, 2, Z.pantsDark);
    c.rect(13, 27, 3, 2, Z.pants); c.rect(23, 27, 3, 2, Z.pantsDark);
    c.rect(12, 29, 3, 2, Z.pants); c.rect(24, 29, 3, 2, Z.pantsDark);
    c.rect(11, 31, 3, 2, Z.pants); c.rect(25, 31, 3, 2, Z.pantsDark);
    c.rect(8, 33, 6, 3, Z.shoe); c.rect(25, 33, 5, 3, Z.shoe);
  } else {
    c.rect(17, 23, 3, 10, Z.pants);
    c.rect(20, 23, 3, 10, Z.pantsDark);
    c.rect(15, 33, 6, 3, Z.shoe);
    c.rect(21, 33, 5, 3, Z.shoe);
  }
  c.save(`zombie_${frame}.png`);
}

// ---------- 奔跑者（面朝左←）：前倾冲刺、黑发、裸上身绿皮、深色短裤、赤脚 ----------
const R = {
  hair: '#2e2622', skin: '#6f9c5b', skinDark: '#527844',
  shorts: '#6b4a2e', shortsDark: '#523823', eye: '#cf3838',
};
function drawRunnerBody(c) {
  // 前倾的头（更低、更靠前）
  c.rect(11, 2, 8, 2, R.hair);
  c.px(10, 3, R.hair);
  c.rect(11, 4, 8, 4, R.skin);
  c.rect(12, 5, 2, 1, R.eye);
  c.rect(12, 7, 3, 1, R.skinDark);
  // 前倾躯干（上窄下移，逐行右移形成倾斜）
  c.rect(13, 8, 9, 2, R.skin);
  c.rect(14, 10, 9, 2, R.skin);
  c.rect(15, 12, 9, 2, R.skin);
  c.rect(16, 14, 9, 2, R.skin);
  c.rect(17, 16, 9, 2, R.skin);
  // 肋骨阴影
  c.px(16, 11, R.skinDark); c.px(17, 13, R.skinDark); c.px(18, 15, R.skinDark);
  // 双臂向前下探 + 爪
  c.rect(3, 9, 10, 2, R.skin);
  c.rect(2, 11, 2, 2, R.skinDark);
  // 破短裤
  c.rect(17, 18, 9, 3, R.shorts);
  c.rect(17, 20, 9, 1, R.shortsDark);
}
function drawRunner(frame) {
  const c = canvas(CW, CH);
  drawRunnerBody(c);
  if (frame === 0) {
    // 大跨步：前腿远探触地，后腿后蹬小腿抬起
    c.rect(15, 21, 3, 3, R.skin);
    c.rect(13, 24, 3, 3, R.skin);
    c.rect(11, 27, 3, 3, R.skin);
    c.rect(9, 30, 3, 3, R.skinDark);
    c.rect(6, 33, 6, 3, R.skinDark);          // 前脚（赤脚）
    c.rect(23, 21, 3, 3, R.skinDark);
    c.rect(25, 24, 3, 3, R.skinDark);
    c.rect(27, 26, 4, 2, R.skinDark);          // 后小腿抬起
    c.rect(30, 25, 3, 2, R.skin);
  } else {
    // 收腿过渡帧
    c.rect(17, 21, 3, 7, R.skin);
    c.rect(15, 28, 3, 3, R.skinDark);
    c.rect(13, 31, 5, 2, R.skinDark);          // 前脚抬起
    c.rect(20, 21, 3, 9, R.skinDark);
    c.rect(19, 30, 3, 3, R.skin);
    c.rect(17, 33, 6, 3, R.skinDark);
  }
  c.save(`runner_${frame}.png`);
}

// ---------- 家园建筑（画面最左）：32x30，scale=8 → 256x240 ----------
const H = {
  roof: '#565b62', roofHi: '#6d7278',
  wall: '#b3b8be', wallDark: '#989da4',
  frame: '#4a3524', wood: '#6b4a2e', woodHi: '#7d5a3a',
  stone: '#8a8f96', stoneDark: '#71767d',
  grass: '#86ac35', grassDark: '#79992b',
};
function drawHome() {
  const c = canvas(32, 30);
  drawHomeInto(c);
  c.save('home.png');
}

// ---------- 预览合成图（对照概念截图检查比例用，不进 git） ----------
function drawPreview(file) {
  const W = 1280, Hh = 720;
  const c = canvas(W, Hh);
  c.rect(0, 0, W, 100, '#a7dbe3');                       // 天空
  for (let x = 0; x < W; x += 4) {                        // 远山
    const mh = 34 + 26 * Math.sin(x * 0.021) + 18 * Math.sin(x * 0.006 + 2);
    c.rect(x, Math.round(100 - mh), 4, Math.round(mh + 8), '#2f6038');
  }
  c.rect(0, 100, W, 190, '#86ac35');                      // 草场
  c.rect(0, 290, W, 22, '#a8adb4');                       // 路缘
  c.rect(0, 312, W, 240, '#666a73');                      // 马路
  for (let x = 20; x < W; x += 96) c.rect(x, 424, 46, 7, '#dbc23a');
  c.rect(0, 552, W, Hh - 552, '#4d3b28');                 // 泥土
  // 直接在预览里重画角色/建筑（复用绘制函数），8x 最近邻放大，feetX/feetY=脚底中心
  const stamp = (drawFn, args, feetX, feetY, cw, ch) => {
    const s = canvas(cw, ch);
    drawFn(s, ...args);
    for (let y = 0; y < ch; y++) for (let x = 0; x < cw; x++) {
      const i = (y * cw + x) * 4;
      if (s.buf[i + 3] === 0) continue;
      const col = '#' + [s.buf[i], s.buf[i + 1], s.buf[i + 2]].map(v => v.toString(16).padStart(2, '0')).join('');
      c.rect(feetX - cw * 4 + x * 8, feetY - ch * 8 + y * 8, 8, 8, col);
    }
  };
  stamp((s) => drawHomeInto(s), [], 128, 312, 32, 30);
  stamp((s) => { drawSurvivorBody(s);
    s.rect(15, 23, 3, 2, P.pantsDark); s.rect(21, 23, 3, 2, P.pants);
    s.rect(14, 25, 3, 2, P.pantsDark); s.rect(22, 25, 3, 2, P.pants);
    s.rect(13, 27, 3, 2, P.pantsDark); s.rect(23, 27, 3, 2, P.pants);
    s.rect(12, 29, 3, 2, P.pantsDark); s.rect(24, 29, 3, 2, P.pants);
    s.rect(11, 31, 3, 2, P.pantsDark); s.rect(25, 31, 3, 2, P.pants);
    s.rect(9, 33, 5, 3, P.shoe); s.rect(25, 33, 6, 3, P.shoe);
  }, [], 420, 440, CW, CH);
  stamp((s) => { drawWalkerBody(s);
    s.rect(15, 23, 3, 2, Z.pants); s.rect(21, 23, 3, 2, Z.pantsDark);
    s.rect(14, 25, 3, 2, Z.pants); s.rect(22, 25, 3, 2, Z.pantsDark);
    s.rect(13, 27, 3, 2, Z.pants); s.rect(23, 27, 3, 2, Z.pantsDark);
    s.rect(12, 29, 3, 2, Z.pants); s.rect(24, 29, 3, 2, Z.pantsDark);
    s.rect(11, 31, 3, 2, Z.pants); s.rect(25, 31, 3, 2, Z.pantsDark);
    s.rect(8, 33, 6, 3, Z.shoe); s.rect(25, 33, 5, 3, Z.shoe);
  }, [], 950, 430, CW, CH);
  stamp((s) => { drawRunnerBody(s);
    s.rect(15, 21, 3, 3, R.skin);
    s.rect(13, 24, 3, 3, R.skin);
    s.rect(11, 27, 3, 3, R.skin);
    s.rect(9, 30, 3, 3, R.skinDark);
    s.rect(6, 33, 6, 3, R.skinDark);
    s.rect(23, 21, 3, 3, R.skinDark);
    s.rect(25, 24, 3, 3, R.skinDark);
    s.rect(27, 26, 4, 2, R.skinDark);
    s.rect(30, 25, 3, 2, R.skin);
  }, [], 1180, 480, CW, CH);
  writePNG(file, W, Hh, c.buf);
}
function drawHomeInto(c) {
  c.rect(0, 0, 32, 1, H.roofHi);
  c.rect(0, 1, 32, 2, H.roof);
  c.rect(1, 3, 30, 22, H.wall);
  c.rect(1, 8, 30, 1, H.wallDark);
  c.rect(1, 14, 30, 1, H.wallDark);
  c.rect(1, 20, 30, 1, H.wallDark);
  for (let i = 0; i < 5; i++) {
    c.px(4 + i * 6, 5, H.wallDark); c.px(7 + i * 6, 11, H.wallDark); c.px(4 + i * 6, 17, H.wallDark);
  }
  c.rect(4, 6, 11, 10, H.frame);
  c.rect(5, 7, 9, 8, H.wood);
  c.rect(5, 7, 9, 2, H.woodHi);
  c.rect(3, 16, 13, 1, H.stone);
  c.rect(0, 25, 32, 5, H.stone);
  for (let i = 0; i < 8; i++) c.rect(i * 4 + (i % 2), 26 + (i % 2) * 2, 3, 1, H.stoneDark);
  c.px(2, 24, H.grass); c.px(3, 24, H.grassDark); c.rect(2, 25, 3, 1, H.grass);
  c.px(20, 24, H.grassDark); c.rect(19, 25, 3, 1, H.grass);
  c.px(29, 24, H.grass); c.rect(28, 25, 2, 1, H.grassDark);
}

console.log('生成像素美术:');
drawSurvivor(0);
drawSurvivor(1);
drawWalker(0);
drawWalker(1);
drawRunner(0);
drawRunner(1);
drawHome();
console.log('完成 →', OUT);

const previewPath = process.argv[2];
if (previewPath) {
  drawPreview(previewPath);
  console.log('预览 →', previewPath);
}

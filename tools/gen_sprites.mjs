// 像素占位美术生成器（零依赖）：node tools/gen_sprites.mjs
// 生成 godot/assets/sprites/ 下的角色 PNG（参考像素风：戴帽子的幸存者 + 灰衣红裤僵尸）
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
function canvas(w, h) {
  const buf = Buffer.alloc(w * h * 4);
  const hex = (c) => [parseInt(c.slice(1, 3), 16), parseInt(c.slice(3, 5), 16), parseInt(c.slice(5, 7), 16)];
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

// ---------- 幸存者（面朝右，24x32，两帧走路） ----------
// 配色参考截图：灰帽、肤色+胡子、蓝衬衫、黑背包、卡其裤、深色鞋
const P = {
  hat: '#8a8f96', hatDark: '#6d7278',
  skin: '#e8b98c', beard: '#7a5233', eye: '#26262e',
  shirt: '#5b7fa6', shirtDark: '#48678a',
  pack: '#3c3c44', packHi: '#52525c',
  pants: '#d9c9a3', pantsDark: '#bfae87',
  shoe: '#4a3226', gun: '#9aa0a6', gunDark: '#70767c',
};
function drawSurvivor(frame) {
  const c = canvas(24, 32);
  // 帽子
  c.rect(7, 0, 7, 2, P.hat);
  c.rect(5, 2, 11, 2, P.hatDark);
  // 头 + 胡子 + 眼睛
  c.rect(7, 4, 7, 4, P.skin);
  c.rect(7, 8, 7, 2, P.beard);
  c.px(12, 5, P.eye);
  // 背包（背在身后 = 左侧）
  c.rect(3, 11, 4, 8, P.pack);
  c.rect(3, 11, 4, 2, P.packHi);
  // 身体（衬衫）
  c.rect(7, 10, 8, 9, P.shirt);
  c.rect(7, 17, 8, 2, P.shirtDark);
  // 前伸手臂（袖子 + 手）
  c.rect(13, 11, 5, 3, P.shirtDark);
  c.rect(18, 11, 2, 3, P.skin);
  // 手枪
  c.rect(19, 9, 5, 2, P.gun);
  c.rect(19, 11, 2, 3, P.gunDark);
  // 裤子 + 走路两帧
  c.rect(7, 19, 8, 4, P.pants);
  if (frame === 0) {
    c.rect(7, 23, 3, 6, P.pants);   // 后腿
    c.rect(12, 23, 3, 6, P.pantsDark); // 前腿
    c.rect(6, 29, 4, 3, P.shoe);
    c.rect(12, 29, 4, 3, P.shoe);
  } else {
    c.rect(8, 23, 3, 6, P.pantsDark);
    c.rect(11, 23, 3, 6, P.pants);
    c.rect(8, 29, 3, 3, P.shoe);
    c.rect(11, 29, 4, 3, P.shoe);
  }
  c.save(`player_${frame}.png`);
}

// ---------- 僵尸（面朝左←，24x32，两帧）----------
// 配色参考截图：橙发、绿皮肤、灰衣、红裤、白鞋
const Z = {
  hair: '#c25a2e', skin: '#7fb069', skinDark: '#5f8a4c',
  shirt: '#9aa0a6', shirtDark: '#7c8288',
  pants: '#c1272d', pantsDark: '#9c1f24',
  shoe: '#e8e6e0', eye: '#d43a3a',
};
function drawZombie(frame) {
  const c = canvas(24, 32);
  // 头发
  c.rect(8, 0, 8, 3, Z.hair);
  c.px(7, 1, Z.hair); c.px(16, 1, Z.hair);
  // 头（绿皮肤）朝左
  c.rect(8, 3, 8, 5, Z.skin);
  c.px(9, 5, Z.eye); c.px(13, 5, Z.eye);
  c.rect(8, 8, 8, 1, Z.skinDark);
  // 前伸手臂（朝左）
  c.rect(1, 11, 7, 3, Z.skin);
  c.rect(1, 11, 2, 3, Z.skinDark);
  // 身体（破烂灰衣）
  c.rect(8, 9, 8, 10, Z.shirt);
  c.rect(8, 16, 8, 2, Z.shirtDark);
  c.px(10, 12, Z.skin); c.px(14, 15, Z.skin); // 破洞露皮肤
  // 红裤 + 两帧
  c.rect(8, 19, 8, 4, Z.pants);
  if (frame === 0) {
    c.rect(8, 23, 3, 6, Z.pantsDark);
    c.rect(13, 23, 3, 6, Z.pants);
    c.rect(7, 29, 4, 3, Z.shoe);
    c.rect(13, 29, 4, 3, Z.shoe);
  } else {
    c.rect(9, 23, 3, 6, Z.pants);
    c.rect(12, 23, 3, 6, Z.pantsDark);
    c.rect(9, 29, 3, 3, Z.shoe);
    c.rect(12, 29, 4, 3, Z.shoe);
  }
  c.save(`zombie_${frame}.png`);
}

console.log('生成像素占位美术:');
drawSurvivor(0);
drawSurvivor(1);
drawZombie(0);
drawZombie(1);
console.log('完成 →', OUT);

// Import Meowa weapon sprites by the names returned by the art job.
// This deliberately does not rely on prompt order or sprite index assumptions.
// Usage: node tools/import_meowa_weapons.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outputDir = path.join(root, 'godot', 'assets', 'weapons');

const packs = [
  {
    dir: path.join(root, 'art', 'meowa', 'realistic_firearm_overlays'),
    expected: {
      'M1911手枪': 'pistol',
      'UZI冲锋枪': 'uzi',
      'Kar98k栓动步枪': 'kar98k',
      '雷明顿870霰弹枪': 'shotgun',
      'AK47突击步枪': 'ak47',
      'M4A1卡宾枪': 'm4',
      'M249轻机枪': 'm249',
    },
  },
  {
    dir: path.join(root, 'art', 'meowa', 'realistic_melee_overlays'),
    expected: {
      '战术格斗刀': 'knife',
      '农用大砍刀': 'machete',
    },
  },
];

fs.mkdirSync(outputDir, { recursive: true });
for (const pack of packs) {
  const response = JSON.parse(fs.readFileSync(path.join(pack.dir, 'job_response.json'), 'utf8'));
  const names = response?.output?.sprite_pack_names;
  if (!Array.isArray(names)) throw new Error(`Missing sprite_pack_names: ${pack.dir}`);

  for (const [index, sourceName] of names.entries()) {
    const weaponId = pack.expected[sourceName];
    if (!weaponId) continue;
    const source = path.join(pack.dir, `sprite_${String(index).padStart(2, '0')}.png`);
    const target = path.join(outputDir, `${weaponId}.png`);
    if (!fs.existsSync(source)) throw new Error(`Missing generated sprite: ${source}`);
    fs.copyFileSync(source, target);
    console.log(`${sourceName} -> ${weaponId}.png`);
  }

  for (const [sourceName, weaponId] of Object.entries(pack.expected)) {
    if (!names.includes(sourceName)) throw new Error(`Art job did not return "${sourceName}" for ${weaponId}`);
  }
}

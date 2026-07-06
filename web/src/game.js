import { CONFIG } from './config.js';
import { Player } from './entities/player.js';
import { Zombie } from './entities/zombie.js';
import { Bullet } from './entities/bullet.js';
import { Particles } from './systems/particles.js';
import { ENEMIES } from './data/enemies.js';
import { getNightConfig, TOTAL_DAYS } from './data/waves.js';
import { rollPerks } from './data/perks.js';
import { Hud } from './ui/hud.js';
import { Screens } from './ui/screens.js';
import { drawBackground, drawPlayer, drawZombie, drawBullet, drawCrosshair } from './render.js';

// 游戏状态机：menu → (day → night → reward)×10 → win / gameover
export class Game {
  constructor(canvas, input) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.input = input;
    this.hud = new Hud();
    this.screens = new Screens();
    this.state = 'menu';
    this.reset();
    this.screens.showMenu(() => this.startRun());
  }

  // 开新的一局
  reset() {
    this.player = new Player();
    this.zombies = [];
    this.bullets = [];
    this.particles = new Particles();
    this.day = 1;
    this.coins = 60;              // 开局资金
    this.totalKills = 0;
    this.nightKills = 0;
    this.purchaseCounts = {};     // 商店递增价格计数
    this.spawnRemaining = 0;
    this.spawnTimer = 0;
    this.nightConfig = null;
    this.paused = false;
  }

  startRun() {
    this.reset();
    this.enterDay();
  }

  enterDay() {
    this.state = 'day';
    this.hud.hide();
    this.canvas.style.cursor = 'default';
    this.screens.showShop(this, () => this.enterNight());
  }

  enterNight() {
    this.state = 'night';
    this.screens.clear();
    this.hud.show();
    this.canvas.style.cursor = 'none';
    this.nightConfig = getNightConfig(this.day);
    this.spawnRemaining = this.nightConfig.count;
    this.spawnTimer = 0.8; // 给玩家一点反应时间
    this.nightKills = 0;
    this.zombies = [];
    this.bullets = [];
    this.paused = false;
    // 玩家回到街区中央，弹匣补满（备弹不变）
    this.player.x = CONFIG.W / 2;
    this.player.y = (CONFIG.BAND_TOP + CONFIG.BAND_BOTTOM) / 2;
    for (const w of this.player.weapons) {
      const need = this.player.magSizeOf(w) - w.mag;
      const take = Math.min(need, w.reserve);
      w.mag += take;
      if (!w.def.infiniteReserve) w.reserve -= take;
    }
  }

  endNight() {
    this.hud.hide();
    this.canvas.style.cursor = 'default';
    const bonus = Math.round(this.nightConfig.clearBonus * this.player.mods.coinMult);
    this.coins += bonus;

    if (this.day >= TOTAL_DAYS) {
      this.state = 'win';
      this.screens.showWin(this, () => this.startRun());
      return;
    }

    this.state = 'reward';
    const perks = rollPerks(3);
    this.screens.showNightReward(this, perks, bonus, (perk) => {
      this.player.applyPerk(perk);
      this.day += 1;
      this.enterDay();
    });
  }

  gameOver() {
    this.state = 'gameover';
    this.hud.hide();
    this.canvas.style.cursor = 'default';
    this.screens.showGameOver(this, () => this.startRun());
  }

  // ---------- 主循环 ----------
  update(dt) {
    if (this.state !== 'night') return;

    if (this.input.wasPressed('escape')) this.paused = !this.paused;
    if (this.paused) { this.hud.update(this); return; }

    const p = this.player;
    const input = this.input;

    // 玩家
    p.update(dt, input);

    // 换弹 / 切枪
    if (input.wasPressed('r')) p.startReload();
    if (input.wasPressed('q')) p.cycleWeapon();
    for (let i = 1; i <= 9; i++) {
      if (input.wasPressed(String(i))) p.switchWeapon(i - 1);
    }

    // 开火
    const shots = p.tryFire(input);
    if (shots) {
      for (const s of shots) this.bullets.push(new Bullet(s));
      this.particles.burst(shots[0].x, shots[0].y, '#ffd93b', 3, 80); // 枪口火花
    }

    // 踹击
    const kick = p.tryKick(input);
    if (kick) {
      this.particles.ring(p.x, p.y, kick.radius, '#ffffff');
      for (const z of this.zombies) {
        const d = Math.hypot(z.x - p.x, z.y - p.y);
        if (d < kick.radius + z.radius) {
          z.takeDamage(kick.damage);
          z.stun = kick.stun;
          z.kbVx = Math.sign(z.x - p.x || 1) * kick.knockback;
          this.particles.burst(z.x, z.y - 20, '#ffffff', 4, 100);
        }
      }
    }

    // 出怪
    if (this.spawnRemaining > 0) {
      this.spawnTimer -= dt;
      if (this.spawnTimer <= 0) {
        this.spawnTimer = this.nightConfig.spawnInterval;
        this.spawnRemaining -= 1;
        this.spawnZombie();
      }
    }

    // 僵尸
    for (const z of this.zombies) z.update(dt, p);

    // 子弹与命中
    for (const b of this.bullets) {
      b.update(dt);
      if (b.dead) continue;
      for (const z of this.zombies) {
        if (z.hp <= 0 || b.hitSet.has(z)) continue;
        // 僵尸躯干中心在脚底坐标上方约 15px
        if (Math.hypot(z.x - b.x, (z.y - 15) - b.y) < z.radius + 8) {
          b.hitSet.add(z);
          z.takeDamage(b.damage);
          this.particles.burst(b.x, b.y, '#9b2226', 4, 90);
          if (z.hp <= 0) this.onKill(z);
          if (b.pierce > 0) b.pierce -= 1;
          else { b.dead = true; break; }
        }
      }
      if (b.x < -40 || b.x > CONFIG.W + 40 || b.y < -40 || b.y > CONFIG.H + 40) b.dead = true;
    }
    this.bullets = this.bullets.filter(b => !b.dead);
    this.zombies = this.zombies.filter(z => z.hp > 0);

    this.particles.update(dt);

    // 玩家死亡
    if (p.hp <= 0) { this.gameOver(); return; }

    // 夜晚结束：怪出完且清完
    if (this.spawnRemaining <= 0 && this.zombies.length === 0) {
      this.endNight();
      return;
    }

    this.hud.update(this);
  }

  spawnZombie() {
    const pool = this.nightConfig.pool;
    const def = ENEMIES[pool[Math.floor(Math.random() * pool.length)]];
    const fromLeft = Math.random() < 0.5;
    const x = fromLeft ? -30 : CONFIG.W + 30;
    const y = CONFIG.BAND_TOP + Math.random() * (CONFIG.BAND_BOTTOM - CONFIG.BAND_TOP);
    this.zombies.push(new Zombie(def, x, y, this.nightConfig));
  }

  onKill(z) {
    this.totalKills += 1;
    this.nightKills += 1;
    const gain = Math.round(z.def.coin * this.player.mods.coinMult);
    this.coins += gain;
    const heal = this.player.mods.healOnKill;
    if (heal > 0) this.player.hp = Math.min(this.player.maxHp, this.player.hp + heal);
    this.particles.burst(z.x, z.y - 15, z.def.color, 10, 150);
    this.particles.text(z.x, z.y - 50, `+${gain}`, '#ffd166');
  }

  // ---------- 渲染 ----------
  render() {
    const ctx = this.ctx;
    const phase = this.state === 'night' ? 'night' : 'day';
    drawBackground(ctx, phase);

    if (this.state === 'night' || this.state === 'reward') {
      // 按 y 排序实现伪纵深遮挡
      const drawables = [
        { y: this.player.y, draw: () => drawPlayer(ctx, this.player) },
        ...this.zombies.map(z => ({ y: z.y, draw: () => drawZombie(ctx, z) })),
      ];
      drawables.sort((a, b) => a.y - b.y);
      for (const d of drawables) d.draw();

      for (const b of this.bullets) drawBullet(ctx, b);
      this.particles.render(ctx);

      if (this.state === 'night' && !this.paused) {
        drawCrosshair(ctx, this.input.mouseX, this.input.mouseY);
      }
    }
  }
}

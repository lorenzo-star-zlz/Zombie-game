// 战斗 HUD：直接更新 DOM，不走 canvas。
export class Hud {
  constructor() {
    this.root = document.getElementById('hud');
    this.hpFill = document.getElementById('hp-fill');
    this.day = document.getElementById('hud-day');
    this.wave = document.getElementById('hud-wave');
    this.coins = document.getElementById('hud-coins');
    this.weapon = document.getElementById('hud-weapon');
    this.kick = document.getElementById('hud-kick');
    this.pauseBanner = document.getElementById('pause-banner');
  }

  show() { this.root.classList.remove('hidden'); }
  hide() { this.root.classList.add('hidden'); }

  update(game) {
    const p = game.player;
    this.hpFill.style.width = Math.max(0, (p.hp / p.maxHp) * 100) + '%';
    this.day.textContent = `第 ${game.day} 天 · 夜晚`;

    const remain = game.spawnRemaining + game.zombies.length;
    this.wave.textContent = `尸潮：剩余 ${remain}`;
    this.coins.textContent = `💰 ${game.coins}`;

    const w = p.weapon;
    const reserve = w.def.infiniteReserve ? '∞' : w.reserve;
    if (p.reloadTimer > 0) {
      this.weapon.textContent = `${w.def.name} 换弹中…`;
      this.weapon.classList.add('reloading');
    } else {
      this.weapon.textContent = `${w.def.name} ${w.mag}/${reserve}`;
      this.weapon.classList.remove('reloading');
    }

    if (p.kickTimer > 0) {
      this.kick.textContent = `踹击 ${p.kickTimer.toFixed(1)}s`;
      this.kick.classList.add('cooling');
    } else {
      this.kick.textContent = '踹击 就绪';
      this.kick.classList.remove('cooling');
    }

    this.pauseBanner.classList.toggle('hidden', !game.paused);
  }
}

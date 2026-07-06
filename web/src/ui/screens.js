import { SHOP_ITEMS } from '../data/shop.js';
import { TOTAL_DAYS } from '../data/waves.js';

// 覆盖层界面：主菜单 / 白天商店 / 夜晚结算+肉鸽三选一 / 失败 / 胜利
// 全部是 DOM，负责展示与点击回调，不含游戏逻辑。
export class Screens {
  constructor() {
    this.overlay = document.getElementById('overlay');
  }

  clear() { this.overlay.innerHTML = ''; }

  showMenu(onStart) {
    this.overlay.innerHTML = `
      <div class="panel">
        <h1>🧟 街区死守</h1>
        <p class="sub">白天备战，夜晚守住街区。撑过 ${TOTAL_DAYS} 天就是胜利。</p>
        <p class="sub">WASD 移动 · 鼠标瞄准射击 · R 换弹 · 空格/F 踹开僵尸 · Q 切换武器</p>
        <button class="btn" id="btn-start">开始游戏</button>
      </div>`;
    this.overlay.querySelector('#btn-start').onclick = onStart;
  }

  // 白天商店。onNight：点击"进入夜晚"
  showShop(game, onNight) {
    const p = game.player;
    const itemsHtml = SHOP_ITEMS.map((item, i) => {
      const price = this._priceOf(game, item);
      const canShow = item.available(game);
      const canAfford = game.coins >= price;
      const disabled = !canShow || !canAfford;
      const label = !canShow ? '—' : `$${price}`;
      return `
        <div class="shop-item ${disabled ? 'disabled' : ''}" data-idx="${i}">
          <div class="item-name">${item.icon} ${item.name}<span class="item-price">${label}</span></div>
          <div class="item-desc">${item.desc}</div>
        </div>`;
    }).join('');

    const weaponsLine = p.weapons.map(w => {
      const reserve = w.def.infiniteReserve ? '∞' : `${w.reserve}`;
      return `${w.def.name}（备弹 ${reserve}）`;
    }).join(' · ');

    this.overlay.innerHTML = `
      <div class="panel">
        <h2>☀️ 第 ${game.day} 天 · 白天</h2>
        <div class="shop-coins">💰 金币：${game.coins}</div>
        <div class="shop-grid">${itemsHtml}</div>
        <div class="inventory-line">🎒 持有：${weaponsLine}</div>
        <div class="inventory-line">❤️ 生命：${Math.ceil(p.hp)}/${p.maxHp}</div>
        <button class="btn" id="btn-night">🌙 进入夜晚（第 ${game.day} 晚）</button>
      </div>`;

    this.overlay.querySelectorAll('.shop-item').forEach(el => {
      el.onclick = () => {
        const item = SHOP_ITEMS[+el.dataset.idx];
        const price = this._priceOf(game, item);
        if (!item.available(game) || game.coins < price) return;
        game.coins -= price;
        game.purchaseCounts[item.id] = (game.purchaseCounts[item.id] || 0) + 1;
        item.buy(game);
        this.showShop(game, onNight); // 刷新界面
      };
    });
    this.overlay.querySelector('#btn-night').onclick = onNight;
  }

  _priceOf(game, item) {
    const count = game.purchaseCounts[item.id] || 0;
    const growth = item.priceGrowth || 1;
    return Math.round(item.basePrice * Math.pow(growth, count));
  }

  // 夜晚结算 + 肉鸽三选一。onPick(perk)
  showNightReward(game, perks, bonus, onPick) {
    const cards = perks.map((perk, i) => `
      <div class="perk-card" data-idx="${i}">
        <div class="perk-icon">${perk.icon}</div>
        <div class="perk-name">${perk.name}</div>
        <div class="perk-desc">${perk.desc}</div>
      </div>`).join('');

    this.overlay.innerHTML = `
      <div class="panel">
        <h2>🌙 第 ${game.day} 晚 · 防守成功！</h2>
        <div class="reward-line">击杀 ${game.nightKills} 只僵尸 · 通宵奖励 +${bonus} 金币</div>
        <p class="sub">选择一个强化（本局永久生效）：</p>
        <div class="perk-cards">${cards}</div>
      </div>`;

    this.overlay.querySelectorAll('.perk-card').forEach(el => {
      el.onclick = () => onPick(perks[+el.dataset.idx]);
    });
  }

  showGameOver(game, onRestart) {
    this.overlay.innerHTML = `
      <div class="panel">
        <h2>💀 街区失守</h2>
        <div class="stats-line">你撑到了第 ${game.day} 天</div>
        <div class="stats-line">总击杀：${game.totalKills} 只僵尸</div>
        <button class="btn" id="btn-restart">再来一局</button>
      </div>`;
    this.overlay.querySelector('#btn-restart').onclick = onRestart;
  }

  showWin(game, onRestart) {
    this.overlay.innerHTML = `
      <div class="panel">
        <h2>🏆 守住了！</h2>
        <div class="stats-line">你成功撑过了 ${TOTAL_DAYS} 天尸潮！</div>
        <div class="stats-line">总击杀：${game.totalKills} 只僵尸 · 剩余金币：${game.coins}</div>
        <button class="btn" id="btn-restart">再来一局</button>
      </div>`;
    this.overlay.querySelector('#btn-restart').onclick = onRestart;
  }
}

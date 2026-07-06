import { Game } from './game.js';
import { Input } from './input.js';
import { CONFIG } from './config.js';

const canvas = document.getElementById('game');
const input = new Input(canvas);
const game = new Game(canvas, input);

// 按窗口大小等比缩放画布
function fitCanvas() {
  const scale = Math.min(
    window.innerWidth / CONFIG.W,
    window.innerHeight / CONFIG.H,
  ) * 0.98;
  const root = document.getElementById('game-root');
  root.style.width = CONFIG.W * scale + 'px';
  root.style.height = CONFIG.H * scale + 'px';
  canvas.style.width = CONFIG.W * scale + 'px';
  canvas.style.height = CONFIG.H * scale + 'px';
}
window.addEventListener('resize', fitCanvas);
fitCanvas();

// 主循环（dt 上限防止切后台后跳帧）
let last = performance.now();
function loop(now) {
  const dt = Math.min(0.05, (now - last) / 1000);
  last = now;
  game.update(dt);
  game.render();
  input.endFrame();
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);

// 输入管理：键盘状态 + 鼠标位置/按键，支持"按下瞬间"检测
export class Input {
  constructor(canvas) {
    this.canvas = canvas;
    this.keys = new Set();        // 当前按住的键
    this.pressed = new Set();     // 本帧刚按下的键
    this.mouseX = 640;
    this.mouseY = 360;
    this.mouseDown = false;
    this.mousePressed = false;    // 本帧刚按下鼠标

    window.addEventListener('keydown', (e) => {
      const k = e.key.toLowerCase();
      if (!this.keys.has(k)) this.pressed.add(k);
      this.keys.add(k);
      // 防止空格滚动页面
      if ([' ', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright'].includes(k)) e.preventDefault();
    });
    window.addEventListener('keyup', (e) => this.keys.delete(e.key.toLowerCase()));
    window.addEventListener('blur', () => { this.keys.clear(); this.mouseDown = false; });

    canvas.addEventListener('mousemove', (e) => this._updateMouse(e));
    canvas.addEventListener('mousedown', (e) => {
      if (e.button === 0) { this.mouseDown = true; this.mousePressed = true; }
      this._updateMouse(e);
    });
    window.addEventListener('mouseup', (e) => { if (e.button === 0) this.mouseDown = false; });
    canvas.addEventListener('contextmenu', (e) => e.preventDefault());
  }

  _updateMouse(e) {
    const rect = this.canvas.getBoundingClientRect();
    this.mouseX = (e.clientX - rect.left) * (this.canvas.width / rect.width);
    this.mouseY = (e.clientY - rect.top) * (this.canvas.height / rect.height);
  }

  isDown(k) { return this.keys.has(k); }
  wasPressed(k) { return this.pressed.has(k); }

  // 每帧结束时调用，清除"刚按下"状态
  endFrame() {
    this.pressed.clear();
    this.mousePressed = false;
  }
}

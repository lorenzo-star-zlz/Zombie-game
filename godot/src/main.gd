# 游戏主控：状态机 menu → (day → night → reward)×10 → win / gameover
# 实体更新顺序由这里统一驱动（player → 出怪 → 僵尸 → 子弹碰撞），不用物理引擎。
extends Node2D

var state := "menu"
var day := 1
var coins := 60
var total_kills := 0
var night_kills := 0
var purchase_counts := {}
var spawn_remaining := 0
var spawn_timer := 0.0
var night_cfg := {}
var paused := false

var bg: StreetBackground
var world: Node2D          # y 排序容器（玩家+僵尸，伪纵深遮挡）
var shots_layer: Node2D    # 子弹层
var fx: FxLayer
var hud: Hud
var screens: Screens
var player: Player = null
var zombies: Array = []
var bullets: Array = []

func _ready() -> void:
	randomize()
	_register_actions()

	bg = StreetBackground.new()
	add_child(bg)
	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	shots_layer = Node2D.new()
	shots_layer.z_index = 5
	add_child(shots_layer)
	fx = FxLayer.new()
	add_child(fx)
	hud = Hud.new()
	add_child(hud)
	hud.visible = false
	screens = Screens.new()
	add_child(screens)

	screens.show_menu(start_run)

# ---------- 输入注册（代码注册，免去编辑器配置） ----------
func _register_actions() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("move_up", [KEY_W, KEY_UP])
	_add_keys("move_down", [KEY_S, KEY_DOWN])
	_add_keys("reload", [KEY_R])
	_add_keys("kick", [KEY_SPACE, KEY_F])
	_add_keys("switch", [KEY_Q])
	_add_keys("pause", [KEY_ESCAPE])
	for i in range(9):
		_add_keys("weapon_%d" % (i + 1), [KEY_1 + i])
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", mb)

func _add_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

# ---------- 状态流转 ----------
func start_run() -> void:
	_reset()
	_enter_day()

func _reset() -> void:
	for z in zombies:
		z.queue_free()
	for b in bullets:
		b.queue_free()
	zombies.clear()
	bullets.clear()
	if player != null:
		player.queue_free()
	player = Player.new()
	player.position = Vector2(Config.W / 2.0, (Config.BAND_TOP + Config.BAND_BOTTOM) / 2.0)
	world.add_child(player)
	day = 1
	coins = 60
	total_kills = 0
	night_kills = 0
	purchase_counts = {}
	paused = false

func _enter_day() -> void:
	state = "day"
	hud.visible = false
	fx.show_crosshair = false
	bg.set_phase("day")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	screens.show_shop(self, _enter_night)

func _enter_night() -> void:
	state = "night"
	screens.clear()
	hud.visible = true
	bg.set_phase("night")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	fx.show_crosshair = true
	night_cfg = WaveData.night_config(day)
	spawn_remaining = night_cfg["count"]
	spawn_timer = 0.8  # 给玩家一点反应时间
	night_kills = 0
	paused = false
	hud.set_paused(false)
	# 玩家回到街区中央，弹匣补满（备弹不变）
	player.position = Vector2(Config.W / 2.0, (Config.BAND_TOP + Config.BAND_BOTTOM) / 2.0)
	for w in player.weapons:
		var need: int = player.mag_size_of(w) - w["mag"]
		if w["def"]["infinite_reserve"]:
			w["mag"] += need
		else:
			var take: int = mini(need, w["reserve"])
			w["mag"] += take
			w["reserve"] -= take

func _end_night() -> void:
	hud.visible = false
	fx.show_crosshair = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var bonus := int(round(night_cfg["clear_bonus"] * player.mods["coin_mult"]))
	coins += bonus

	if day >= WaveData.TOTAL_DAYS:
		state = "win"
		screens.show_win(self, start_run)
		return

	state = "reward"
	var perks := PerkData.roll(3)
	screens.show_night_reward(self, perks, bonus, _on_perk_picked)

func _on_perk_picked(perk: Dictionary) -> void:
	player.apply_perk(perk)
	day += 1
	_enter_day()

func _game_over() -> void:
	state = "gameover"
	hud.visible = false
	fx.show_crosshair = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	screens.show_game_over(self, start_run)

# ---------- 夜晚主循环 ----------
func _process(delta: float) -> void:
	if state != "night":
		return

	if Input.is_action_just_pressed("pause"):
		paused = not paused
		hud.set_paused(paused)
	if paused:
		return

	player.tick(delta)

	# 换弹 / 切枪
	if Input.is_action_just_pressed("reload"):
		player.start_reload()
	if Input.is_action_just_pressed("switch"):
		player.cycle_weapon()
	for i in range(9):
		if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
			player.switch_weapon(i)

	# 开火
	var shots := player.try_fire()
	if shots.size() > 0:
		for s in shots:
			var b := Bullet.new()
			b.setup(s)
			shots_layer.add_child(b)
			bullets.append(b)
		fx.burst(shots[0]["pos"], Color(1.0, 0.85, 0.23), 3, 80.0)

	# 踹击
	var kick := player.try_kick()
	if not kick.is_empty():
		var center := player.position + Vector2(0, -26)
		fx.ring(center, kick["radius"], Color.WHITE)
		for z in zombies:
			if z.position.distance_to(player.position) < kick["radius"] + z.radius:
				z.take_damage(kick["damage"])
				z.stun = kick["stun"]
				var dir := signf(z.position.x - player.position.x)
				z.kb_vx = (dir if dir != 0.0 else 1.0) * kick["knockback"]
				fx.burst(z.position + Vector2(0, -40), Color.WHITE, 4, 100.0)
				if z.hp <= 0.0:
					_on_kill(z)

	# 出怪
	if spawn_remaining > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = night_cfg["spawn_interval"]
			spawn_remaining -= 1
			_spawn_zombie()

	# 僵尸
	for z in zombies:
		z.tick(delta, player)

	# 子弹与命中（躯干中心在脚底坐标上方约 40px）
	for b in bullets:
		b.tick(delta)
		if b.dead:
			continue
		for z in zombies:
			if z.hp <= 0.0 or b.hit_list.has(z):
				continue
			if b.position.distance_to(z.position + Vector2(0, -40)) < z.radius * 2.0:
				b.hit_list.append(z)
				z.take_damage(b.damage)
				fx.burst(b.position, Color(0.61, 0.13, 0.15), 4, 90.0)
				if z.hp <= 0.0:
					_on_kill(z)
				if b.pierce > 0:
					b.pierce -= 1
				else:
					b.dead = true
					break

	# 清理
	for z in zombies.duplicate():
		if z.hp <= 0.0:
			zombies.erase(z)
			z.queue_free()
	for b in bullets.duplicate():
		if b.dead:
			bullets.erase(b)
			b.queue_free()

	fx.tick(delta)

	# 玩家死亡
	if player.hp <= 0.0:
		_game_over()
		return

	# 夜晚结束：怪出完且清完
	if spawn_remaining <= 0 and zombies.is_empty():
		_end_night()
		return

	hud.update_hud(self)

func _spawn_zombie() -> void:
	var pool: Array = night_cfg["pool"]
	var def: Dictionary = EnemyData.ENEMIES[pool.pick_random()]
	var from_left := randf() < 0.5
	var x := -30.0 if from_left else Config.W + 30.0
	var y := randf_range(Config.BAND_TOP, Config.BAND_BOTTOM)
	var z := Zombie.new()
	z.setup(def, Vector2(x, y), night_cfg)
	world.add_child(z)
	zombies.append(z)

func _on_kill(z: Zombie) -> void:
	total_kills += 1
	night_kills += 1
	var gain := int(round(z.def["coin"] * player.mods["coin_mult"]))
	coins += gain
	var heal: float = player.mods["heal_on_kill"]
	if heal > 0.0:
		player.hp = minf(player.max_hp(), player.hp + heal)
	fx.burst(z.position + Vector2(0, -30), Color("#7fb069"), 10, 150.0)
	fx.add_text(z.position + Vector2(0, -100), "+%d" % gain, Color(1.0, 0.82, 0.4))

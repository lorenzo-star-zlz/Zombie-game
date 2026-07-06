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
	hud.resume_requested.connect(_resume_from_hud)
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
	player.position = Vector2(320.0, (Config.BAND_TOP + Config.BAND_BOTTOM) / 2.0)  # 出生在左侧家园旁
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
	spawn_timer = 0.8
	night_kills = 0
	paused = false
	hud.set_paused(false)
	player.position = Vector2(320.0, (Config.BAND_TOP + Config.BAND_BOTTOM) / 2.0)
	for w in player.weapons:
		if w == null or w["def"]["category"] == "melee":
			continue
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

func _resume_from_hud() -> void:
	if state != "night" or not paused:
		return
	paused = false
	hud.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

# ---------- 夜晚主循环 ----------
func _process(delta: float) -> void:
	if state != "night":
		return
	if Input.is_action_just_pressed("pause"):
		paused = not paused
		hud.set_paused(paused)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_HIDDEN
	if paused:
		return

	player.tick(delta)
	if Input.is_action_just_pressed("reload"):
		player.start_reload()
	if Input.is_action_just_pressed("switch"):
		player.cycle_weapon()
	for i in range(4):
		if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
			player.switch_weapon(i)

	var shots := player.try_fire()
	if shots.size() > 0:
		for shot in shots:
			var bullet := Bullet.new()
			bullet.setup(shot)
			shots_layer.add_child(bullet)
			bullets.append(bullet)
		fx.burst(shots[0]["pos"], Color(1.0, 0.85, 0.23), 3, 80.0)

	var melee_attack := player.try_selected_melee()
	if melee_attack.is_empty():
		melee_attack = player.try_kick()
	if not melee_attack.is_empty():
		_apply_melee_attack(melee_attack)

	if spawn_remaining > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = night_cfg["spawn_interval"]
			spawn_remaining -= 1
			_spawn_zombie()

	for zombie in zombies:
		zombie.tick(delta, player)
	for bullet in bullets:
		bullet.tick(delta)
		if bullet.dead:
			continue
		for zombie in zombies:
			if zombie.hp <= 0.0 or bullet.hit_list.has(zombie):
				continue
			if bullet.position.distance_to(zombie.position + Vector2(0, -150)) < zombie.radius * 2.2:
				bullet.hit_list.append(zombie)
				zombie.take_damage(bullet.damage)
				fx.burst(bullet.position, Color(0.61, 0.13, 0.15), 4, 90.0)
				if zombie.hp <= 0.0:
					_on_kill(zombie)
				if bullet.pierce > 0:
					bullet.pierce -= 1
				else:
					bullet.dead = true
					break

	for zombie in zombies.duplicate():
		if zombie.hp <= 0.0:
			zombies.erase(zombie)
			zombie.queue_free()
	for bullet in bullets.duplicate():
		if bullet.dead:
			bullets.erase(bullet)
			bullet.queue_free()
	fx.tick(delta)

	if player.hp <= 0.0:
		_game_over()
		return
	if spawn_remaining <= 0 and zombies.is_empty():
		_end_night()
		return
	hud.update_hud(self)

func _apply_melee_attack(attack: Dictionary) -> void:
	var center := player.position + Vector2(0, -140)
	fx.ring(center, attack["radius"], Color.WHITE)
	for zombie in zombies:
		if zombie.position.distance_to(player.position) < attack["radius"] + zombie.radius:
			zombie.take_damage(attack["damage"])
			zombie.stun = attack["stun"]
			var direction := signf(zombie.position.x - player.position.x)
			zombie.kb_vx = (direction if direction != 0.0 else 1.0) * attack["knockback"]
			fx.burst(zombie.position + Vector2(0, -150), Color.WHITE, 4, 100.0)
			if zombie.hp <= 0.0:
				_on_kill(zombie)

func _spawn_zombie() -> void:
	var pool: Array = night_cfg["pool"]
	var def: Dictionary = EnemyData.ENEMIES[pool.pick_random()]
	var x := Config.W + 170.0  # 整个精灵（半宽160）在屏外
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
	fx.burst(z.position + Vector2(0, -150), Color("#7fb069"), 10, 150.0)
	fx.add_text(z.position + Vector2(0, -310), "+%d" % gain, Color(1.0, 0.82, 0.4))

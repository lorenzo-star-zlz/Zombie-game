# 无头端到端测试：
#   godot --headless --path godot --script res://test/headless_test.gd
# 加载主场景，模拟输入跑完 夜晚战斗 → 结算 流程，验证核心逻辑无错误。
extends SceneTree

var main
var frame := 0
var failed := 0
var fired_bullets := false
var zombie_moved := false

func check(name: String, cond: bool) -> void:
	if cond:
		print("  ✓ ", name)
	else:
		failed += 1
		printerr("  ✗ ", name)

func _initialize() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	main = scene

func _process(_delta: float) -> bool:
	frame += 1

	# 第 1 帧场景树才 ready，状态机测试放这里
	if frame == 1:
		print("状态机:")
		check("初始为菜单", main.state == "menu")
		main.start_run()
		check("开始游戏进入白天", main.state == "day")
		check("开局金币 60", main.coins == 60)
		main._enter_night()
		check("进入夜晚", main.state == "night")
		check("尸潮数量按波次表", main.spawn_remaining == WaveData.night_config(1)["count"])

	# 模拟移动（第 5~30 帧按住 D）
	if frame == 5:
		Input.action_press("move_right")
		main.player.set_meta("x0", main.player.position.x)
	if frame == 30:
		Input.action_release("move_right")
		check("玩家向右移动", main.player.position.x > float(main.player.get_meta("x0")) + 10.0)

	# 模拟点射（每 12 帧点一下鼠标）
	if frame > 30 and frame < 150:
		if frame % 12 == 0:
			Input.action_press("fire")
		if frame % 12 == 2:
			Input.action_release("fire")
		if main.bullets.size() > 0:
			fired_bullets = true

	if frame == 150:
		print("战斗:")
		check("模拟点射产生子弹", fired_bullets)
		check("消耗了弹匣", main.player.weapon()["mag"] < WeaponData.WEAPONS["pistol"]["mag_size"])
		check("夜晚出怪", main.zombies.size() > 0)
		var all_right := true
		for z in main.zombies:
			if z.position.x < Config.W * 0.55:
				all_right = false
		check("僵尸只从右侧进场", all_right)
		check("后期波次池包含奔跑者", WaveData.night_config(5)["pool"].has("runner"))

	# 僵尸移动检测
	if frame == 160 and main.zombies.size() > 0:
		var z = main.zombies[0]
		z.set_meta("x0", z.position.x)
	if frame == 190 and main.zombies.size() > 0:
		var z = main.zombies[0]
		if z.has_meta("x0"):
			var moved: float = absf(z.position.x - z.get_meta("x0"))
			check("僵尸在移动", moved > 1.0)

	# 踹击测试：放一只僵尸在玩家旁边
	if frame == 200 and main.zombies.size() > 0:
		var z = main.zombies[0]
		z.position = main.player.position + Vector2(40, 0)
		Input.action_press("kick")
	if frame == 203:
		Input.action_release("kick")
		print("踹击:")
		check("踹击进入冷却", main.player.kick_timer > 0.0)
		if main.zombies.size() > 0:
			var z = main.zombies[0]
			check("僵尸被击退/硬直", z.kb_vx != 0.0 or z.stun > 0.0)

	# 换弹测试
	if frame == 220:
		main.player.weapon()["mag"] = 0
		main.player.start_reload()
		check("空弹匣可换弹", main.player.reload_timer > 0.0)

	# 肉鸽加成测试
	if frame == 240:
		print("肉鸽:")
		var before: float = main.player.mods["dmg_mult"]
		main.player.apply_perk(PerkData.PERKS[0])
		check("强化生效", main.player.mods["dmg_mult"] > before)
		var perks = PerkData.roll(3)
		var ids := {}
		for p in perks:
			ids[p["id"]] = true
		check("三选一不重复", ids.size() == 3)

	# 商店测试
	if frame == 260:
		print("商店:")
		main.coins = 2000
		check("初始拥有一把副武器", main.player.weapons[2]["def"]["id"] == "pistol")
		check("初始拥有一把近战武器", main.player.weapons[3]["def"]["id"] == "knife")
		check("霰弹枪可购买", ShopData.is_available(main, "buy_shotgun"))
		ShopData.buy(main, "buy_shotgun")
		check("购买后拥有霰弹枪", main.player.has_weapon("shotgun"))
		check("购买后先进入仓库", not main.player.is_equipped("shotgun"))
		check("购买后商店下架", not ShopData.is_available(main, "buy_shotgun"))
		ShopData.buy(main, "buy_kar98k")
		main.player.equip_to_slot("shotgun", 0)
		main.player.equip_to_slot("kar98k", 1)
		check("可装备两把主武器", main.player.weapons[0] != null and main.player.weapons[1] != null)
		check("主武器槽满后仍可购买到仓库", ShopData.is_available(main, "buy_ak47"))
		ShopData.buy(main, "buy_ak47")
		check("AK-47 已进入仓库", main.player.has_weapon("ak47"))
		check("主武器槽满时 AK-47 不会强制替换", not main.player.is_equipped("ak47"))
		main.player.equip_to_slot("", 0)
		main.player.equip_to_slot("ak47", 0)
		check("卸下一把后可带入 AK-47", main.player.is_equipped("ak47"))
		ShopData.buy(main, "buy_uzi")
		check("UZI 购买后留在仓库", main.player.weapons[2]["def"]["id"] == "pistol")
		main.player.equip_to_slot("uzi", 2)
		check("副武器槽可选择 UZI", main.player.weapons[2]["def"]["id"] == "uzi")
		ShopData.buy(main, "buy_machete")
		main.player.equip_to_slot("machete", 3)
		check("近战槽可选择开山刀", main.player.weapons[3]["def"]["id"] == "machete")
		check("当前出战配置有效", main.player.is_loadout_valid())
		main.screens.show_loadout(main, main._enter_night)
		check("每天可打开装备选择界面", main.screens._root != null)
		main.screens.clear()
		var v_pistol: float = main.player.speed()
		main.player.switch_weapon(0)
		check("大枪持有时移速更慢", main.player.speed() < v_pistol)
		main.player.switch_weapon(2)
		main.player.hp = 10.0
		ShopData.buy(main, "medkit")
		check("急救包回满血", main.player.hp == main.player.max_hp())

	# 强制结束夜晚 → 应进入奖励界面
	if frame == 280:
		main.spawn_remaining = 0
		for z in main.zombies:
			z.take_damage(99999.0)
	if frame == 285:
		print("结算:")
		check("夜晚结束进入奖励界面", main.state == "reward")
		check("发放通宵奖励金币", main.coins > 500)

	if frame == 300:
		print("")
		if failed == 0:
			print("全部通过 ✓")
		else:
			printerr("%d 项失败" % failed)
		quit(1 if failed > 0 else 0)
		return true

	return false

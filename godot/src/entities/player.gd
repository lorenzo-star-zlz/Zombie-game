class_name Player
extends Node2D

const TEX_0 := preload("res://assets/sprites/survivor_realistic_0.png")
const TEX_1 := preload("res://assets/sprites/survivor_realistic_1.png")
const WEAPON_TEXTURES := {
	"pistol": preload("res://assets/weapons/pistol.png"),
	"uzi": preload("res://assets/weapons/uzi.png"),
	"kar98k": preload("res://assets/weapons/kar98k.png"),
	"shotgun": preload("res://assets/weapons/shotgun.png"),
	"ak47": preload("res://assets/weapons/ak47.png"),
	"m4": preload("res://assets/weapons/m4.png"),
	"m249": preload("res://assets/weapons/m249.png"),
	"knife": preload("res://assets/weapons/knife.png"),
	"machete": preload("res://assets/weapons/machete.png"),
}

var mods := {
	"dmg_mult": 1.0, "fire_rate_mult": 1.0, "reload_speed_mult": 1.0,
	"move_speed_mult": 1.0, "coin_mult": 1.0, "kick_cd_mult": 1.0,
	"kick_power_mult": 1.0, "mag_mult": 1.0, "pierce_add": 0,
	"max_hp_add": 0.0, "heal_on_kill": 0.0,
}

# Active loadout: primary 1, primary 2, secondary, melee.
var weapons: Array = [null, null, null, null]
var weapon_instances := {}
var owned_weapon_ids: Array[String] = []
var weapon_index := 2
var hp := 0.0
var reload_timer := 0.0
var fire_timer := 0.0
var kick_timer := 0.0
var aim_angle := 0.0
var hurt_flash := 0.0
var radius: float = Config.PLAYER["radius"]

var _sprite: Sprite2D
var _weapon_sprite: Sprite2D
var _rear_arm: Line2D
var _front_arm: Line2D
var _rear_sleeve: Line2D
var _front_sleeve: Line2D
var _rear_hand: Polygon2D
var _front_hand: Polygon2D
var _anim_time := 0.0
var _moving := false
var _muzzle_flash_timer := 0.0
var _recoil := 0.0
var _melee_swing_timer := 0.0
var _quick_melee_timer := 0.0

func _init() -> void:
	_register_owned_weapon("pistol")
	_register_owned_weapon("knife")
	weapons[2] = weapon_instances["pistol"]
	weapons[3] = weapon_instances["knife"]
	hp = max_hp()

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEX_0
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(Config.SPRITE_SCALE, Config.SPRITE_SCALE)
	_sprite.position = Vector2(0, Config.SPRITE_OFFSET_Y)
	add_child(_sprite)

	_weapon_sprite = Sprite2D.new()
	_weapon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_weapon_sprite.z_index = 2
	add_child(_weapon_sprite)
	_rear_sleeve = _make_arm(1, 11.0, Color("#617a9c"))
	_front_sleeve = _make_arm(3, 11.0, Color("#7b93b4"))
	_rear_arm = _make_arm(1, 7.0, Color("#c99a72"))
	_front_arm = _make_arm(3, 7.0, Color("#e5b88f"))
	_rear_hand = _make_hand(1)
	_front_hand = _make_hand(3)
	_update_weapon_visual()

func _make_arm(layer: int, width: float, color: Color) -> Line2D:
	var arm := Line2D.new()
	arm.width = width
	arm.default_color = color
	arm.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arm.end_cap_mode = Line2D.LINE_CAP_ROUND
	arm.antialiased = false
	arm.z_index = layer
	add_child(arm)
	return arm

func _make_hand(layer: int) -> Polygon2D:
	var hand := Polygon2D.new()
	hand.polygon = PackedVector2Array([
		Vector2(-4, -3), Vector2(4, -3), Vector2(5, 3), Vector2(0, 5), Vector2(-5, 3),
	])
	hand.color = Color("#e5b88f")
	hand.z_index = layer
	add_child(hand)
	return hand

func max_hp() -> float:
	return Config.PLAYER["base_max_hp"] + mods["max_hp_add"]

func speed() -> float:
	return Config.PLAYER["base_speed"] * mods["move_speed_mult"] * weapon()["def"].get("move_mult", 1.0)

func weapon() -> Dictionary:
	return weapons[weapon_index]

func melee_weapon() -> Dictionary:
	return weapons[3]

func _register_owned_weapon(id: String) -> void:
	if weapon_instances.has(id):
		return
	weapon_instances[id] = _make_weapon(id)
	owned_weapon_ids.append(id)

func _make_weapon(id: String) -> Dictionary:
	var definition: Dictionary = WeaponData.WEAPONS[id]
	if definition["category"] == "melee":
		return { "def": definition }
	var reserve: int = 0 if definition["infinite_reserve"] else definition["reserve_max"]
	return { "def": definition, "mag": definition["mag_size"], "reserve": reserve }

func has_weapon(id: String) -> bool:
	return weapon_instances.has(id)

func is_equipped(id: String) -> bool:
	for item in weapons:
		if item != null and item["def"]["id"] == id:
			return true
	return false

func equipped_slot(id: String) -> int:
	for index in range(weapons.size()):
		if weapons[index] != null and weapons[index]["def"]["id"] == id:
			return index
	return -1

func can_equip_category(category: String) -> bool:
	if category == "primary":
		return weapons[0] == null or weapons[1] == null
	return category == "secondary" or category == "melee"

func add_weapon(id: String) -> bool:
	if has_weapon(id):
		return false
	_register_owned_weapon(id)
	return true

func equip_to_slot(id: String, slot: int) -> bool:
	if slot < 0 or slot >= weapons.size():
		return false
	if id.is_empty() and slot < 2:
		weapons[slot] = null
		if weapon_index == slot:
			weapon_index = 2
		_update_weapon_visual()
		return true
	if not weapon_instances.has(id):
		return false
	var item: Dictionary = weapon_instances[id]
	var expected_category := "primary" if slot < 2 else ("secondary" if slot == 2 else "melee")
	if item["def"]["category"] != expected_category:
		return false
	var previous_slot := equipped_slot(id)
	if previous_slot >= 0 and previous_slot != slot:
		weapons[previous_slot] = null
	weapons[slot] = item
	if weapon_index == previous_slot or weapons[weapon_index] == null:
		weapon_index = slot
	_update_weapon_visual()
	return true

func equip_owned_weapon(id: String) -> bool:
	if not weapon_instances.has(id):
		return false
	if is_equipped(id):
		weapon_index = equipped_slot(id)
		return true
	var item: Dictionary = weapon_instances[id]
	match item["def"]["category"]:
		"primary":
			for index in [0, 1]:
				if weapons[index] == null:
					weapons[index] = item
					weapon_index = index
					return true
		"secondary":
			weapons[2] = item
			weapon_index = 2
			return true
		"melee":
			weapons[3] = item
			weapon_index = 3
			return true
	return false

func toggle_loadout_weapon(id: String) -> bool:
	if not weapon_instances.has(id):
		return false
	var category: String = weapon_instances[id]["def"]["category"]
	if category == "primary" and is_equipped(id):
		var slot := equipped_slot(id)
		weapons[slot] = null
		if weapon_index == slot:
			weapon_index = 2
		return true
	return equip_owned_weapon(id)

func is_loadout_valid() -> bool:
	return weapons[2] != null and weapons[3] != null

func mag_size_of(item: Dictionary) -> int:
	if item["def"]["category"] == "melee":
		return 0
	return int(round(item["def"]["mag_size"] * mods["mag_mult"]))

func switch_weapon(index: int) -> void:
	if index == weapon_index or index < 0 or index >= weapons.size() or weapons[index] == null:
		return
	weapon_index = index
	reload_timer = 0.0
	_update_weapon_visual()

func cycle_weapon() -> void:
	for offset in range(1, weapons.size() + 1):
		var candidate := (weapon_index + offset) % weapons.size()
		if weapons[candidate] != null:
			switch_weapon(candidate)
			return

func start_reload() -> void:
	var item := weapon()
	if item["def"]["category"] == "melee" or reload_timer > 0.0:
		return
	if item["mag"] >= mag_size_of(item):
		return
	if not item["def"]["infinite_reserve"] and item["reserve"] <= 0:
		return
	reload_timer = item["def"]["reload_time"] / mods["reload_speed_mult"]

func take_damage(damage: float) -> void:
	hp -= damage
	hurt_flash = 0.25

func apply_perk(perk: Dictionary) -> void:
	for effect in perk["effects"]:
		if effect.has("mul"):
			mods[effect["stat"]] *= effect["mul"]
		if effect.has("add"):
			mods[effect["stat"]] += effect["add"]
		if effect["stat"] == "max_hp_add":
			hp = minf(max_hp(), hp + effect["add"])

func tick(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += direction * speed() * delta
	position.x = clampf(position.x, 60.0, Config.W - 60.0)
	position.y = clampf(position.y, Config.BAND_TOP, Config.BAND_BOTTOM)
	_moving = direction.length_squared() > 0.01

	var mouse := get_global_mouse_position()
	var aim_vector := mouse - global_position + Vector2(0, Config.AIM_HEIGHT)
	# 敌人从右侧进攻：人物始终面向右侧。向左移动时保持朝向，形成后退步态。
	aim_vector.x = maxf(aim_vector.x, 1.0)
	aim_angle = clampf(aim_vector.angle(), -PI * 0.48, PI * 0.48)
	var frame_index := 0 if int(_anim_time * 8.0) % 2 == 0 else 1
	_sprite.flip_h = false

	fire_timer = maxf(0.0, fire_timer - delta)
	kick_timer = maxf(0.0, kick_timer - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)
	_muzzle_flash_timer = maxf(0.0, _muzzle_flash_timer - delta)
	_melee_swing_timer = maxf(0.0, _melee_swing_timer - delta)
	_quick_melee_timer = maxf(0.0, _quick_melee_timer - delta)
	_recoil = move_toward(_recoil, 0.0, delta * 9.0)

	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			var item := weapon()
			var need: int = mag_size_of(item) - item["mag"]
			if item["def"]["infinite_reserve"]:
				item["mag"] += need
			else:
				var take: int = mini(need, item["reserve"])
				item["mag"] += take
				item["reserve"] -= take

	_anim_time += delta
	_sprite.texture = TEX_0 if not _moving or frame_index == 0 else TEX_1
	_sprite.modulate = Color(1, 0.4, 0.4) if hurt_flash > 0.0 else Color.WHITE
	_update_weapon_visual()
	queue_redraw()

func _displayed_weapon() -> Dictionary:
	if _quick_melee_timer > 0.0:
		return melee_weapon()
	return weapon()

func _update_weapon_visual() -> void:
	if _weapon_sprite == null:
		return
	var item := _displayed_weapon()
	var definition: Dictionary = item["def"]
	_weapon_sprite.texture = WEAPON_TEXTURES[definition["id"]]
	var scale_value: float = (
		float(definition["world_length"])
		/ float(definition["asset_width"])
		* Config.WEAPON_VISUAL_SCALE
	)
	_weapon_sprite.scale = Vector2(scale_value, scale_value)
	var direction := Vector2(cos(aim_angle), sin(aim_angle))
	var reload_phase := 0.0
	if reload_timer > 0.0 and weapon()["def"]["category"] != "melee":
		var total: float = weapon()["def"]["reload_time"] / mods["reload_speed_mult"]
		reload_phase = sin(clampf(1.0 - reload_timer / total, 0.0, 1.0) * PI)
	var swing := 0.0
	if _melee_swing_timer > 0.0:
		var duration: float = definition.get("cooldown", 0.7)
		swing = sin(clampf(1.0 - _melee_swing_timer / duration, 0.0, 1.0) * PI) * 1.1
	var side := 1.0
	var grip_to_center := (0.5 - float(definition["grip_x_ratio"])) * float(definition["world_length"])
	_weapon_sprite.position = (
		Vector2(0, -Config.AIM_HEIGHT)
		+ direction * (10.0 + grip_to_center - _recoil * 8.0)
		+ Vector2(0, reload_phase * 26.0)
	)
	_weapon_sprite.rotation = aim_angle + side * (reload_phase * 0.8 - swing)
	_weapon_sprite.flip_v = false
	_update_hold_pose(definition, direction)

func _update_hold_pose(definition: Dictionary, direction: Vector2) -> void:
	var perpendicular := Vector2(-direction.y, direction.x)
	var weapon_base := Vector2(0, -Config.AIM_HEIGHT)
	var pose: String = definition["hold_pose"]
	var rear_shoulder := Vector2(-8, -Config.AIM_HEIGHT - 18)
	var front_shoulder := Vector2(5, -Config.AIM_HEIGHT - 9)
	var rear_grip := weapon_base + direction * 10.0 + perpendicular * 4.0
	var front_grip := rear_grip
	if pose == "rifle":
		front_grip = weapon_base + direction * float(definition["front_grip"]) - perpendicular * 2.0
	elif pose == "pistol":
		# 人物底图已包含双手合拢姿势；副武器直接落在双手中心，避免多画一对手臂。
		_rear_sleeve.visible = false
		_front_sleeve.visible = false
		_rear_arm.visible = false
		_front_arm.visible = false
		_rear_hand.visible = false
		_front_hand.visible = false
		return
	else:
		_rear_sleeve.visible = false
		_front_sleeve.visible = false
		_rear_arm.visible = false
		_front_arm.visible = false
		_rear_hand.visible = false
		_front_hand.visible = false
		return
	# 人物底图的后手负责扳机/握把，仅补绘伸向护木的前手。
	_rear_sleeve.visible = false
	_front_sleeve.visible = true
	_rear_arm.visible = false
	_front_arm.visible = true
	_rear_hand.visible = false
	_front_hand.visible = true
	var rear_elbow := rear_shoulder.lerp(rear_grip, 0.42) + perpendicular * 4.0
	var front_elbow := front_shoulder.lerp(front_grip, 0.45) - perpendicular * 3.0
	_front_sleeve.points = PackedVector2Array([front_shoulder, front_elbow])
	_front_arm.points = PackedVector2Array([front_elbow, front_grip])
	_front_hand.position = front_grip
	_front_hand.rotation = aim_angle

func try_fire() -> Array:
	var item := weapon()
	if item["def"]["category"] == "melee":
		return []
	if reload_timer > 0.0 or fire_timer > 0.0:
		return []
	var wants_fire: bool = Input.is_action_pressed("fire") if item["def"]["auto"] else Input.is_action_just_pressed("fire")
	if not wants_fire:
		return []
	if item["mag"] <= 0:
		start_reload()
		return []

	item["mag"] -= 1
	fire_timer = item["def"]["fire_interval"] / mods["fire_rate_mult"]
	_muzzle_flash_timer = 0.065
	_recoil = 1.0
	if item["mag"] <= 0:
		start_reload()

	var shots := []
	var muzzle: Vector2 = global_position + Vector2(0, -Config.AIM_HEIGHT) + Vector2(cos(aim_angle), sin(aim_angle)) * float(item["def"]["muzzle_distance"]) * Config.WEAPON_VISUAL_SCALE
	for _pellet in range(item["def"]["pellets"]):
		var spread: float = (randf() - 0.5) * deg_to_rad(item["def"]["spread_deg"])
		var angle := aim_angle + spread
		shots.append({
			"pos": muzzle,
			"vel": Vector2(cos(angle), sin(angle)) * item["def"]["bullet_speed"],
			"damage": item["def"]["damage"] * mods["dmg_mult"],
			"pierce": item["def"]["pierce"] + mods["pierce_add"],
			"max_dist": item["def"]["range"],
		})
	return shots

func try_selected_melee() -> Dictionary:
	if weapon()["def"]["category"] != "melee" or not Input.is_action_just_pressed("fire"):
		return {}
	return _try_melee_attack(false)

func try_kick() -> Dictionary:
	if not Input.is_action_just_pressed("kick"):
		return {}
	return _try_melee_attack(true)

func _try_melee_attack(quick: bool) -> Dictionary:
	if kick_timer > 0.0:
		return {}
	var definition: Dictionary = melee_weapon()["def"]
	kick_timer = definition["cooldown"] * mods["kick_cd_mult"]
	_melee_swing_timer = definition["cooldown"]
	if quick:
		_quick_melee_timer = minf(0.32, definition["cooldown"])
	return {
		"radius": definition["radius"],
		"damage": definition["damage"] * mods["kick_power_mult"] * mods["dmg_mult"],
		"knockback": definition["knockback"] * mods["kick_power_mult"],
		"stun": definition["stun"],
	}

func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 52.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _muzzle_flash_timer > 0.0 and weapon()["def"]["category"] != "melee":
		var direction := Vector2(cos(aim_angle), sin(aim_angle))
		var perpendicular := Vector2(-direction.y, direction.x)
		var muzzle: Vector2 = Vector2(0, -Config.AIM_HEIGHT) + direction * float(weapon()["def"]["muzzle_distance"]) * Config.WEAPON_VISUAL_SCALE
		draw_colored_polygon(PackedVector2Array([
			muzzle - perpendicular * 9.0,
			muzzle + direction * 38.0,
			muzzle + perpendicular * 9.0,
			muzzle + direction * 17.0,
		]), Color(1.0, 0.83, 0.2, 0.95))
	if reload_timer > 0.0 and weapon()["def"]["category"] != "melee":
		var total: float = weapon()["def"]["reload_time"] / mods["reload_speed_mult"]
		var progress := 1.0 - reload_timer / total
		draw_arc(Vector2(0, -320), 16.0, -PI / 2, -PI / 2 + progress * TAU, 24, Color(1.0, 0.82, 0.4), 5.0)

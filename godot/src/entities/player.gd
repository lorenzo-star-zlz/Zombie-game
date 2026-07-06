class_name Player
extends Node2D

const TEX_0 := preload("res://assets/sprites/survivor_realistic_0.png")
const TEX_1 := preload("res://assets/sprites/survivor_realistic_1.png")

var mods := {
	"dmg_mult": 1.0,
	"fire_rate_mult": 1.0,
	"reload_speed_mult": 1.0,
	"move_speed_mult": 1.0,
	"coin_mult": 1.0,
	"kick_cd_mult": 1.0,
	"kick_power_mult": 1.0,
	"mag_mult": 1.0,
	"pierce_add": 0,
	"max_hp_add": 0.0,
	"heal_on_kill": 0.0,
}

# Fixed loadout: primary 1, primary 2, secondary, melee.
var weapons: Array = [null, null, null, null]
var weapon_index := 2
var hp := 0.0
var reload_timer := 0.0
var fire_timer := 0.0
var kick_timer := 0.0
var aim_angle := 0.0
var hurt_flash := 0.0
var radius: float = Config.PLAYER["radius"]

var _sprite: Sprite2D
var _anim_time := 0.0
var _moving := false

func _init() -> void:
	weapons[2] = _make_weapon("pistol")
	weapons[3] = _make_weapon("knife")
	hp = max_hp()

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEX_0
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(Config.SPRITE_SCALE, Config.SPRITE_SCALE)
	_sprite.position = Vector2(0, Config.SPRITE_OFFSET_Y)
	add_child(_sprite)

func max_hp() -> float:
	return Config.PLAYER["base_max_hp"] + mods["max_hp_add"]

func speed() -> float:
	return Config.PLAYER["base_speed"] * mods["move_speed_mult"] * weapon()["def"].get("move_mult", 1.0)

func weapon() -> Dictionary:
	return weapons[weapon_index]

func melee_weapon() -> Dictionary:
	return weapons[3]

func _make_weapon(id: String) -> Dictionary:
	var def: Dictionary = WeaponData.WEAPONS[id]
	if def["category"] == "melee":
		return { "def": def }
	var reserve: int = 0 if def["infinite_reserve"] else def["reserve_max"]
	return { "def": def, "mag": def["mag_size"], "reserve": reserve }

func has_weapon(id: String) -> bool:
	for item in weapons:
		if item != null and item["def"]["id"] == id:
			return true
	return false

func can_equip_category(category: String) -> bool:
	match category:
		"primary":
			return weapons[0] == null or weapons[1] == null
		"secondary", "melee":
			return true
	return false

func add_weapon(id: String) -> bool:
	if has_weapon(id):
		return false
	var category: String = WeaponData.WEAPONS[id]["category"]
	match category:
		"primary":
			for index in [0, 1]:
				if weapons[index] == null:
					weapons[index] = _make_weapon(id)
					weapon_index = index
					return true
		"secondary":
			weapons[2] = _make_weapon(id)
			weapon_index = 2
			return true
		"melee":
			weapons[3] = _make_weapon(id)
			weapon_index = 3
			return true
	return false

func mag_size_of(item: Dictionary) -> int:
	if item["def"]["category"] == "melee":
		return 0
	return int(round(item["def"]["mag_size"] * mods["mag_mult"]))

func switch_weapon(index: int) -> void:
	if index == weapon_index or index < 0 or index >= weapons.size() or weapons[index] == null:
		return
	weapon_index = index
	reload_timer = 0.0

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
	aim_angle = (mouse - global_position + Vector2(0, Config.AIM_HEIGHT)).angle()
	var frame_index := 0 if int(_anim_time * 8.0) % 2 == 0 else 1
	var faces_left := mouse.x < global_position.x
	_sprite.flip_h = faces_left != (frame_index == 1)

	fire_timer = maxf(0.0, fire_timer - delta)
	kick_timer = maxf(0.0, kick_timer - delta)
	hurt_flash = maxf(0.0, hurt_flash - delta)

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
	queue_redraw()

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
	if item["mag"] <= 0:
		start_reload()

	var shots := []
	var muzzle := global_position + Vector2(cos(aim_angle), sin(aim_angle)) * 145.0 + Vector2(0, -Config.AIM_HEIGHT)
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
	return _try_melee_attack()

func try_kick() -> Dictionary:
	if not Input.is_action_just_pressed("kick"):
		return {}
	return _try_melee_attack()

func _try_melee_attack() -> Dictionary:
	if kick_timer > 0.0:
		return {}
	var definition: Dictionary = melee_weapon()["def"]
	kick_timer = definition["cooldown"] * mods["kick_cd_mult"]
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
	if reload_timer > 0.0 and weapon()["def"]["category"] != "melee":
		var total: float = weapon()["def"]["reload_time"] / mods["reload_speed_mult"]
		var progress := 1.0 - reload_timer / total
		draw_arc(Vector2(0, -320), 16.0, -PI / 2, -PI / 2 + progress * TAU, 24, Color(1.0, 0.82, 0.4), 5.0)

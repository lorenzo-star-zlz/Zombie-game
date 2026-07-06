# 玩家：移动、生命、武器背包、换弹、踹击冷却。
# 所有肉鸽加成集中在 mods 字典，数值计算时统一乘上。
class_name Player
extends Node2D

const TEX_0 := preload("res://assets/sprites/player_0.png")
const TEX_1 := preload("res://assets/sprites/player_1.png")

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

var weapons: Array = []
var weapon_index := 0
var hp := 0.0
var reload_timer := 0.0   # >0 表示正在换弹
var fire_timer := 0.0     # >0 表示开火冷却中
var kick_timer := 0.0     # >0 表示踹击冷却中
var aim_angle := 0.0
var hurt_flash := 0.0
var radius: float = Config.PLAYER["radius"]

var _sprite: Sprite2D
var _anim_time := 0.0
var _moving := false

func _init() -> void:
	# 在 _init 初始化数据（而非 _ready），保证节点入树前逻辑就可用
	weapons = [_make_weapon("pistol")]
	hp = max_hp()

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEX_0
	_sprite.scale = Vector2(3, 3)
	_sprite.position = Vector2(0, -26)  # 脚底对齐节点原点附近
	add_child(_sprite)

func max_hp() -> float:
	return Config.PLAYER["base_max_hp"] + mods["max_hp_add"]

func speed() -> float:
	return Config.PLAYER["base_speed"] * mods["move_speed_mult"]

func weapon() -> Dictionary:
	return weapons[weapon_index]

func _make_weapon(id: String) -> Dictionary:
	var def: Dictionary = WeaponData.WEAPONS[id]
	var reserve: int = 0 if def["infinite_reserve"] else def["reserve_max"]
	return { "def": def, "mag": def["mag_size"], "reserve": reserve }

func has_weapon(id: String) -> bool:
	for w in weapons:
		if w["def"]["id"] == id:
			return true
	return false

func add_weapon(id: String) -> void:
	if not has_weapon(id):
		weapons.append(_make_weapon(id))

# 弹匣容量（受加成影响）
func mag_size_of(w: Dictionary) -> int:
	return int(round(w["def"]["mag_size"] * mods["mag_mult"]))

func switch_weapon(index: int) -> void:
	if index == weapon_index or index < 0 or index >= weapons.size():
		return
	weapon_index = index
	reload_timer = 0.0  # 切枪打断换弹

func cycle_weapon() -> void:
	switch_weapon((weapon_index + 1) % weapons.size())

func start_reload() -> void:
	var w := weapon()
	if reload_timer > 0.0:
		return
	if w["mag"] >= mag_size_of(w):
		return
	if not w["def"]["infinite_reserve"] and w["reserve"] <= 0:
		return
	reload_timer = w["def"]["reload_time"] / mods["reload_speed_mult"]

func take_damage(dmg: float) -> void:
	hp -= dmg
	hurt_flash = 0.25

func apply_perk(perk: Dictionary) -> void:
	for e in perk["effects"]:
		if e.has("mul"):
			mods[e["stat"]] *= e["mul"]
		if e.has("add"):
			mods[e["stat"]] += e["add"]
		# 加生命上限时同步回复等量生命
		if e["stat"] == "max_hp_add":
			hp = minf(max_hp(), hp + e["add"])

func tick(delta: float) -> void:
	# 移动
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += dir * speed() * delta
	position.x = clampf(position.x, 30.0, Config.W - 30.0)
	position.y = clampf(position.y, Config.BAND_TOP, Config.BAND_BOTTOM)
	_moving = dir.length_squared() > 0.01

	# 瞄准
	var mouse := get_global_mouse_position()
	aim_angle = (mouse - global_position + Vector2(0, 26)).angle()
	_sprite.flip_h = mouse.x < global_position.x

	# 计时器
	if fire_timer > 0.0: fire_timer -= delta
	if kick_timer > 0.0: kick_timer -= delta
	if hurt_flash > 0.0: hurt_flash -= delta

	# 换弹进度
	if reload_timer > 0.0:
		reload_timer -= delta
		if reload_timer <= 0.0:
			var w := weapon()
			var need: int = mag_size_of(w) - w["mag"]
			if w["def"]["infinite_reserve"]:
				w["mag"] += need
			else:
				var take: int = mini(need, w["reserve"])
				w["mag"] += take
				w["reserve"] -= take

	# 走路动画 + 受击红闪
	_anim_time += delta
	if _moving:
		_sprite.texture = TEX_0 if int(_anim_time * 8.0) % 2 == 0 else TEX_1
	else:
		_sprite.texture = TEX_0
	_sprite.modulate = Color(1, 0.4, 0.4) if hurt_flash > 0.0 else Color.WHITE

	queue_redraw()

# 尝试开火：返回子弹参数数组，不能开火返回空数组
func try_fire() -> Array:
	var w := weapon()
	if reload_timer > 0.0 or fire_timer > 0.0:
		return []
	var want: bool = Input.is_action_pressed("fire") if w["def"]["auto"] else Input.is_action_just_pressed("fire")
	if not want:
		return []
	if w["mag"] <= 0:
		start_reload()
		return []

	w["mag"] -= 1
	fire_timer = w["def"]["fire_interval"] / mods["fire_rate_mult"]
	if w["mag"] <= 0:
		start_reload()  # 打空自动换弹

	var shots := []
	var muzzle := global_position + Vector2(cos(aim_angle), sin(aim_angle)) * 30.0 + Vector2(0, -26)
	for i in range(w["def"]["pellets"]):
		var spread: float = (randf() - 0.5) * deg_to_rad(w["def"]["spread_deg"])
		var ang := aim_angle + spread
		shots.append({
			"pos": muzzle,
			"vel": Vector2(cos(ang), sin(ang)) * w["def"]["bullet_speed"],
			"damage": w["def"]["damage"] * mods["dmg_mult"],
			"pierce": w["def"]["pierce"] + mods["pierce_add"],
			"max_dist": w["def"]["range"],
		})
	return shots

# 尝试踹击：返回踹击参数，冷却中或未按键返回空字典
func try_kick() -> Dictionary:
	if kick_timer > 0.0:
		return {}
	if not Input.is_action_just_pressed("kick"):
		return {}
	var P: Dictionary = Config.PLAYER
	kick_timer = P["kick_cooldown"] * mods["kick_cd_mult"]
	return {
		"radius": P["kick_radius"],
		"damage": P["kick_damage"] * mods["kick_power_mult"],
		"knockback": P["kick_knockback"] * mods["kick_power_mult"],
		"stun": P["kick_stun"],
	}

func _draw() -> void:
	# 脚下阴影
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 换弹进度环
	if reload_timer > 0.0:
		var total: float = weapon()["def"]["reload_time"] / mods["reload_speed_mult"]
		var t := 1.0 - reload_timer / total
		draw_arc(Vector2(0, -95), 10.0, -PI / 2, -PI / 2 + t * TAU, 24, Color(1.0, 0.82, 0.4), 4.0)

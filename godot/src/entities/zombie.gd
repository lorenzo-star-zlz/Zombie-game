# 僵尸：朝玩家移动，近身攻击。支持击退与硬直（被踹击时）。
class_name Zombie
extends Node2D

const TEX_0 := preload("res://assets/sprites/zombie_0.png")
const TEX_1 := preload("res://assets/sprites/zombie_1.png")

var def: Dictionary
var hp := 1.0
var max_hp := 1.0
var speed := 50.0
var damage := 10.0
var attack_timer := 0.0
var kb_vx := 0.0        # 击退速度
var stun := 0.0         # 硬直剩余时间
var hit_flash := 0.0
var radius := 16.0

var _sprite: Sprite2D
var _anim_time := 0.0

func setup(p_def: Dictionary, pos: Vector2, scale_cfg: Dictionary) -> void:
	def = p_def
	position = pos
	radius = def["radius"]
	max_hp = def["hp"] * scale_cfg["hp_mult"]
	hp = max_hp
	# 每只僵尸速度略有随机，避免叠成一条直线
	speed = def["speed"] * scale_cfg["speed_mult"] * randf_range(0.85, 1.15)
	damage = def["damage"] * scale_cfg["dmg_mult"]
	_anim_time = randf() * 10.0

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = TEX_0
	_sprite.scale = Vector2(3, 3)
	_sprite.position = Vector2(0, -26)
	add_child(_sprite)

func tick(delta: float, player: Player) -> void:
	_anim_time += delta
	if attack_timer > 0.0: attack_timer -= delta
	if hit_flash > 0.0: hit_flash -= delta
	if stun > 0.0: stun -= delta

	# 击退位移（指数衰减）
	position.x += kb_vx * delta
	kb_vx *= pow(0.002, delta)

	if stun <= 0.0:
		var to_player := player.position - position
		var d := to_player.length()
		if d > radius + player.radius + 2.0:
			var dir := to_player / d
			position.x += dir.x * speed * delta
			position.y += dir.y * speed * delta * 0.8
		elif attack_timer <= 0.0:
			player.take_damage(damage)
			attack_timer = def["attack_interval"]

	position.y = clampf(position.y, Config.BAND_TOP, Config.BAND_BOTTOM)

	# 面朝玩家（贴图默认朝左）
	_sprite.flip_h = player.position.x > position.x
	_sprite.texture = TEX_0 if int(_anim_time * 6.0) % 2 == 0 else TEX_1
	_sprite.modulate = Color(2.0, 2.0, 2.0) if hit_flash > 0.0 else Color.WHITE
	if stun > 0.0:
		_sprite.modulate = Color(1.0, 1.0, 0.6)

	queue_redraw()

func take_damage(dmg: float) -> void:
	hp -= dmg
	hit_flash = 0.1

func _draw() -> void:
	# 脚下阴影
	draw_set_transform(Vector2(0, 24), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 血条（受伤才显示）
	if hp < max_hp:
		draw_rect(Rect2(-15, -100, 30, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-15, -100, 30.0 * maxf(0.0, hp / max_hp), 5), Color(0.49, 0.91, 0.53))

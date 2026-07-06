# 子弹：直线飞行，支持穿透与射程限制。碰撞由 main.gd 统一处理。
class_name Bullet
extends Node2D

var vel := Vector2.ZERO
var damage := 10.0
var pierce := 0         # 还能穿透几个敌人
var max_dist := 2000.0
var traveled := 0.0
var dead := false
var hit_list: Array = []  # 已命中的敌人（避免同一子弹重复命中）

func setup(shot: Dictionary) -> void:
	position = shot["pos"]
	vel = shot["vel"]
	damage = shot["damage"]
	pierce = shot["pierce"]
	max_dist = shot["max_dist"]
	rotation = vel.angle()

func tick(delta: float) -> void:
	var mv := vel * delta
	position += mv
	traveled += mv.length()
	if traveled > max_dist:
		dead = true
	if position.x < -40.0 or position.x > Config.W + 40.0 or position.y < -40.0 or position.y > Config.H + 40.0:
		dead = true

func _draw() -> void:
	draw_rect(Rect2(-8, -2, 14, 4), Color(1.0, 0.85, 0.23))

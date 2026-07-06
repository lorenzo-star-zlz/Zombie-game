# 特效层：命中火花、死亡血雾、踹击冲击圈、金币飘字、准星。
class_name FxLayer
extends Node2D

var list := []
var texts := []
var show_crosshair := false

func _ready() -> void:
	z_index = 10

func burst(pos: Vector2, color: Color, count := 6, speed := 120.0) -> void:
	for i in range(count):
		var a := randf() * TAU
		var s := speed * randf_range(0.4, 1.2)
		list.append({
			"pos": pos,
			"vel": Vector2(cos(a) * s, sin(a) * s - 40.0),
			"life": randf_range(0.35, 0.6),
			"max_life": 0.5,
			"size": randf_range(2.0, 5.0),
			"color": color,
			"ring": false,
		})

func ring(pos: Vector2, target_radius: float, color: Color) -> void:
	list.append({
		"pos": pos, "ring": true, "radius": 10.0,
		"target_radius": target_radius,
		"life": 0.25, "max_life": 0.25, "color": color,
	})

func add_text(pos: Vector2, s: String, color := Color.WHITE) -> void:
	texts.append({ "pos": pos, "str": s, "color": color, "life": 0.8 })

func tick(delta: float) -> void:
	for p in list:
		p["life"] -= delta
		if p["ring"]:
			p["radius"] += (p["target_radius"] - p["radius"]) * delta * 18.0
		else:
			p["pos"] += p["vel"] * delta
			p["vel"].y += 300.0 * delta
	list = list.filter(func(p): return p["life"] > 0.0)

	for t in texts:
		t["life"] -= delta
		t["pos"].y -= 40.0 * delta
	texts = texts.filter(func(t): return t["life"] > 0.0)

	queue_redraw()

func _draw() -> void:
	for p in list:
		var alpha: float = clampf(p["life"] / p["max_life"], 0.0, 1.0)
		var col: Color = p["color"]
		col.a = alpha
		if p["ring"]:
			draw_arc(p["pos"], p["radius"], 0.0, TAU, 32, col, 3.0)
		else:
			draw_rect(Rect2(p["pos"].x - p["size"] / 2.0, p["pos"].y - p["size"] / 2.0, p["size"], p["size"]), col)

	var font := ThemeDB.fallback_font
	for t in texts:
		var col: Color = t["color"]
		col.a = clampf(t["life"] * 2.0, 0.0, 1.0)
		draw_string(font, t["pos"] + Vector2(-60.0, 0.0), t["str"], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 16, col)

	if show_crosshair:
		var m := get_global_mouse_position()
		var col := Color(1, 1, 1, 0.9)
		draw_arc(m, 10.0, 0.0, TAU, 24, col, 2.0)
		draw_line(m + Vector2(-16, 0), m + Vector2(-6, 0), col, 2.0)
		draw_line(m + Vector2(6, 0), m + Vector2(16, 0), col, 2.0)
		draw_line(m + Vector2(0, -16), m + Vector2(0, -6), col, 2.0)
		draw_line(m + Vector2(0, 6), m + Vector2(0, 16), col, 2.0)

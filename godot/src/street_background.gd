# 像素风街景背景（按概念截图比例：青空 + 山脉剪影 + 大片草场 + 马路 + 泥土）
# 全部程序化绘制，布局用固定种子生成，白天/夜晚只换配色。
# 画面最左是家园建筑（home.png），僵尸只会从右侧进场。
class_name StreetBackground
extends Node2D

const PX := 4.0          # 像素块大小
const SKY_BOTTOM := 100.0
const GRASS_BOTTOM := 290.0
const CURB_BOTTOM := 312.0
const ROAD_BOTTOM := 552.0
const DASH_Y := 424.0

const HOME_TEX := preload("res://assets/sprites/home.png")

const PALETTE := {
	"day": {
		"sky": "#a7dbe3", "cloud": "#f4fbfd",
		"mountain": "#2f6038",
		"grass": ["#86ac35", "#7da22e", "#90b73f", "#79992b"],
		"curb": "#a8adb4", "curb_shadow": "#8a8f96",
		"road": "#666a73", "speck": "#5a5e66", "dash": "#dbc23a",
		"dirt": "#4d3b28", "dirt_speck": "#3c2e1f",
		"home_tint": Color.WHITE,
	},
	"night": {
		"sky": "#10122e", "cloud": "#2c3054",
		"mountain": "#16281c",
		"grass": ["#2c3d18", "#26350f", "#31431d", "#223010"],
		"curb": "#4a4e55", "curb_shadow": "#3a3d43",
		"road": "#2e3038", "speck": "#26282f", "dash": "#6f652f",
		"dirt": "#241c12", "dirt_speck": "#1a140d",
		"home_tint": Color(0.42, 0.46, 0.62),
	},
}

var phase := "day"
var _home: Sprite2D
var _grass_cols := []
var _mount_h := []
var _clouds := []
var _road_specks := []
var _dirt_specks := []
var _stars := []

func _ready() -> void:
	z_index = -10
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260706
	var n := int(Config.W / PX) + 1
	for i in range(n):
		_grass_cols.append({
			"top": 96.0 + rng.randf_range(-8.0, 8.0),
			"ci": rng.randi_range(0, 3),
		})
		_mount_h.append(34.0 + 26.0 * sin(i * 0.085) + 18.0 * sin(i * 0.023 + 2.0) + rng.randf_range(-4.0, 4.0))
	for i in range(7):
		_clouds.append(Vector2(rng.randf_range(20.0, Config.W - 60.0), rng.randf_range(10.0, 60.0)))
	for i in range(300):
		_road_specks.append(Vector2(rng.randf_range(0.0, Config.W), rng.randf_range(CURB_BOTTOM + 6.0, ROAD_BOTTOM - 6.0)))
	for i in range(160):
		_dirt_specks.append(Vector2(rng.randf_range(0.0, Config.W), rng.randf_range(ROAD_BOTTOM + 4.0, Config.H - 4.0)))
	for i in range(60):
		_stars.append(Vector2(rng.randf_range(0.0, Config.W), rng.randf_range(4.0, 90.0)))

	# 家园建筑：贴在画面最左，坐在路缘上（32x30 画布 × 8 = 256x240）
	_home = Sprite2D.new()
	_home.texture = HOME_TEX
	_home.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_home.scale = Vector2(8, 8)
	_home.position = Vector2(128.0, CURB_BOTTOM - 120.0)
	add_child(_home)

	queue_redraw()

func set_phase(p: String) -> void:
	phase = p
	if _home != null:
		_home.modulate = PALETTE[phase]["home_tint"]
	queue_redraw()

func _draw() -> void:
	var c: Dictionary = PALETTE[phase]
	var night := phase == "night"

	# 天空
	draw_rect(Rect2(0, 0, Config.W, SKY_BOTTOM + 20.0), Color(c["sky"]))

	if night:
		for s in _stars:
			draw_rect(Rect2(s.x, s.y, 3, 3), Color("#cdd3e8"))
		# 月亮
		draw_circle(Vector2(Config.W - 170.0, 48.0), 26.0, Color("#e8e6d8"))
		draw_circle(Vector2(Config.W - 181.0, 41.0), 22.0, Color(c["sky"]))
	else:
		# 像素云（三块矩形一朵）
		for cl in _clouds:
			draw_rect(Rect2(cl.x, cl.y, 56, 10), Color(c["cloud"]))
			draw_rect(Rect2(cl.x + 10.0, cl.y - 8.0, 32, 8), Color(c["cloud"]))
			draw_rect(Rect2(cl.x + 16.0, cl.y + 10.0, 28, 6), Color(c["cloud"]))

	# 远山剪影（逐列矩形）
	for i in range(_mount_h.size()):
		var h: float = _mount_h[i]
		draw_rect(Rect2(i * PX, SKY_BOTTOM - h, PX, h + 24.0), Color(c["mountain"]))

	# 大片草场（逐列竖条，颜色/高度微差 → 草丛质感）
	var grass: Array = c["grass"]
	for i in range(_grass_cols.size()):
		var col: Dictionary = _grass_cols[i]
		draw_rect(
			Rect2(i * PX, col["top"], PX, GRASS_BOTTOM - col["top"]),
			Color(grass[col["ci"]])
		)

	# 路缘石
	draw_rect(Rect2(0, GRASS_BOTTOM, Config.W, CURB_BOTTOM - GRASS_BOTTOM), Color(c["curb"]))
	draw_rect(Rect2(0, CURB_BOTTOM - 5.0, Config.W, 5.0), Color(c["curb_shadow"]))

	# 柏油路
	draw_rect(Rect2(0, CURB_BOTTOM, Config.W, ROAD_BOTTOM - CURB_BOTTOM), Color(c["road"]))
	for s in _road_specks:
		draw_rect(Rect2(s.x, s.y, PX, PX), Color(c["speck"]))
	# 黄色虚线
	var x := 20.0
	while x < Config.W:
		draw_rect(Rect2(x, DASH_Y, 46.0, 7.0), Color(c["dash"]))
		x += 96.0

	# 底部泥土
	draw_rect(Rect2(0, ROAD_BOTTOM, Config.W, Config.H - ROAD_BOTTOM), Color(c["dirt"]))
	for s in _dirt_specks:
		draw_rect(Rect2(s.x, s.y, PX, PX), Color(c["dirt_speck"]))

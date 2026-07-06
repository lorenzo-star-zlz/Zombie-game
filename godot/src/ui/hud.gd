# 战斗 HUD：血条、天数、尸潮余量、金币、武器弹药、踹击冷却。
class_name Hud
extends CanvasLayer

var _font: SystemFont
var _hp_fill: ColorRect
var _hp_text: Label
var _day_label: Label
var _wave_label: Label
var _coins_label: Label
var _weapon_label: Label
var _kick_label: Label
var _pause_label: Label

# 中文字体：用系统字体，避免默认字体缺 CJK 字形
static func make_cjk_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Microsoft YaHei", "SimHei", "PingFang SC", "Noto Sans CJK SC"])
	return f

func _ready() -> void:
	layer = 5
	_font = make_cjk_font()

	# 血条
	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(16, 14)
	hp_bg.size = Vector2(220, 18)
	hp_bg.color = Color(0.16, 0.1, 0.14, 0.85)
	add_child(hp_bg)
	_hp_fill = ColorRect.new()
	_hp_fill.position = Vector2(18, 16)
	_hp_fill.size = Vector2(216, 14)
	_hp_fill.color = Color(0.9, 0.28, 0.3)
	add_child(_hp_fill)
	_hp_text = _mk_label(Vector2(244, 12), 16)

	_day_label = _mk_label(Vector2(420, 12), 18)
	_wave_label = _mk_label(Vector2(600, 12), 18)
	_coins_label = _mk_label(Vector2(820, 12), 18)

	_weapon_label = _mk_label(Vector2(16, Config.H - 40), 18)
	_kick_label = _mk_label(Vector2(300, Config.H - 40), 18)
	var hint := _mk_label(Vector2(560, Config.H - 36), 13)
	hint.text = "WASD移动 · 鼠标射击 · R换弹 · 空格踹击 · Q切枪 · Esc暂停"
	hint.modulate = Color(1, 1, 1, 0.65)

	_pause_label = _mk_label(Vector2(Config.W / 2.0 - 200, 300), 36)
	_pause_label.size = Vector2(400, 60)
	_pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pause_label.text = "已暂停 - 按 Esc 继续"
	_pause_label.visible = false

func _mk_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l

func set_paused(p: bool) -> void:
	_pause_label.visible = p

func update_hud(m) -> void:
	var p: Player = m.player
	_hp_fill.size.x = 216.0 * clampf(p.hp / p.max_hp(), 0.0, 1.0)
	_hp_text.text = "%d/%d" % [int(ceil(maxf(0.0, p.hp))), int(p.max_hp())]
	_day_label.text = "第 %d 天 · 夜晚" % m.day
	_wave_label.text = "尸潮：剩余 %d" % (m.spawn_remaining + m.zombies.size())
	_coins_label.text = "💰 %d" % m.coins

	var w: Dictionary = p.weapon()
	if p.reload_timer > 0.0:
		_weapon_label.text = "%s 换弹中…" % w["def"]["name"]
		_weapon_label.modulate = Color(1.0, 0.82, 0.4)
	else:
		var reserve: String = "∞" if w["def"]["infinite_reserve"] else str(w["reserve"])
		_weapon_label.text = "%s %d/%s" % [w["def"]["name"], w["mag"], reserve]
		_weapon_label.modulate = Color.WHITE

	if p.kick_timer > 0.0:
		_kick_label.text = "踹击 %.1fs" % p.kick_timer
		_kick_label.modulate = Color(0.6, 0.6, 0.6)
	else:
		_kick_label.text = "踹击 就绪"
		_kick_label.modulate = Color.WHITE

extends SceneTree

var main
var frame := 0

func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		main.start_run()
		main.player.add_weapon("kar98k")
		main.player.equip_to_slot("kar98k", 0)
		main.player.switch_weapon(0)
		main._enter_night()
		main.player.weapon()["mag"] = 0
		main.player.start_reload()
		main.player.reload_timer *= 0.5
	if frame == 4:
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("res://test/reload_capture.png")
		quit()
		return true
	return false

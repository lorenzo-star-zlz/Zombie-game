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
		main.coins = 2000
		main.screens.show_shop(main, main._enter_night)
	if frame == 18:
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("res://test/shop_capture.png")
		quit()
		return true
	return false

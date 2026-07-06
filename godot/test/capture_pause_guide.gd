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
		main._enter_night()
		main.paused = true
		main.hud.set_paused(true)
		main.hud._toggle_guide()
	if frame == 18:
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("res://test/pause_guide_capture.png")
		quit()
		return true
	return false

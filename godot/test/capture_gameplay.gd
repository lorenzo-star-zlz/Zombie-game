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
		main.player.add_weapon("m4")
		main.player.equip_to_slot("m4", 0)
		main.player.switch_weapon(0)
		main._enter_night()
	if frame == 3:
		main._spawn_zombie()
		main.zombies[0].position = Vector2(990, 455)
	if frame == 4:
		Input.action_press("fire")
	if frame == 18:
		Input.action_release("fire")
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("res://test/gameplay_capture.png")
		quit()
		return true
	return false

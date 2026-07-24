extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# changing the mouse mode when the game is paused & Pausing the game
func open():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	$Control/MarginContainer/VBoxContainer/Resume.grab_focus()
func close():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			close()
		else:
			open()

# Buttons actions
func _on_resume_pressed():
	close()

func _on_options_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/menus/options_menu.tscn")

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/UI/lobby.tscn")

func _on_exitto_desktop_pressed():
	get_tree().quit()

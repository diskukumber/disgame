extends Node3D

# handling exit from the game with the escape button
func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

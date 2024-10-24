extends CanvasLayer

func _on_start_game_pressed():
	get_tree().change_scene_to_file("res://scenes/test.tscn")


func _on_settings_pressed():
	pass # Replace with function body.


func _on_quit_pressed():
	get_tree().quit()

extends Control



func _on_graphics_pressed():
	# TODO: Add graphics settings here
	pass



func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/lobby.tscn")

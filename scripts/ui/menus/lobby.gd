extends CanvasLayer

func _on_start_game_pressed():
	get_tree().change_scene_to_file("res://scenes/levels/main_level.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/options_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()

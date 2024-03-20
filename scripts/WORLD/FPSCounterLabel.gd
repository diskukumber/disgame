extends Label


# for debugging

# FPS Counter
func _process(_delta):
	var FPSCounterLabel = Engine.get_frames_per_second()
	text = "FPS: "+str(FPSCounterLabel)

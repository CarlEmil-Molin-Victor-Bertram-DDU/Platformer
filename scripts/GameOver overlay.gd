extends CanvasLayer



func _ready():
	self.hide()

func _on_retry_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")

func game_over():
	get_tree().paused = true
	self.show()
	
	
func _on_button_pressed():
	get_tree().quit()
	

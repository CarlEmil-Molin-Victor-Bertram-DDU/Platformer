extends CanvasLayer

@export var camera: Camera2D

func _process(delta):
	if camera:
		# Follow the camera's position
		offset = -camera.position

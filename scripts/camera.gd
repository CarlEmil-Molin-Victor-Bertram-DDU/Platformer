extends Camera2D

# The player node to follow
@export var player: Node2D

# Offset from the player position
@export var custom_offset: Vector2 = Vector2.ZERO

# The speed at which the camera follows the player
@export var follow_speed: float = 5.0

func _ready():
	if player == null:
		print("Player node not assigned!")

func _process(delta: float):
	if player:
		# Calculate the target position for the camera
		var target_position = player.position + offset
		
		# Smoothly move the camera to the target position
		position = lerp(position, target_position, follow_speed * delta)

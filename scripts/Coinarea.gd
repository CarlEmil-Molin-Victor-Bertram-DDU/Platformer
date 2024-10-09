extends Area2D

@export var value: int = 1  # Amount of coins this coin gives when collected
signal coin_collected(value: int)

func _ready():
	# Connect the body_entered signal to the _on_body_entered method
	self.body_entered.connect(Callable(self, "_on_body_entered"))
	print("CoinArea is ready. Coin value:", value)
	
	# Manually connect the coin_collected signal to the UI node
	# Adjust the path based on your scene hierarchy if needed
	var ui_node = get_tree().root.get_node("Node2D/UI")  # Adjust the path accordingly
	if ui_node:
		coin_collected.connect(Callable(ui_node, "_on_coin_collected"))
		print("Connected coin_collected signal to UI.")
	else:
		print("UI node not found for signal connection.")

func _on_body_entered(body):
	print("Collision detected with:", body.name)
	if body.name == "Player":
		print("Player entered. Emitting coin_collected signal with value:", value)
		coin_collected.emit(value)
		queue_free()
		print("Coin collected and removed from the scene.")
	else:
		print("Collision ignored. Body is not the player.")

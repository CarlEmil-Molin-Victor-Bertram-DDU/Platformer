extends Control

@export var camera: Camera2D
@onready var coin_label: Label = $CoinLabel
@onready var coin_sound: AudioStreamPlayer = $CoinPickup
var coins_to_win = 7
var win=false

var coin_count: int = 0
@export var ui_smooth_speed: float = 4
@export var offset: Vector2 = Vector2(-183, -104)


func _ready():
	if coin_label:
		print("Coin label found.")
	else:
		print("Coin label not found.")
	update_coin_count()
	print("UI is ready. Initial coin count:", coin_count)

func update_coin_count():
	if coin_label:
		coin_label.text = ": %d" % coin_count
		print("Updated coin label to:", coin_label.text)
	else:
		print("errror")

func increment_coin_count(amount: int):
	# Increase the coin count and update the label
	coin_count += amount
	print("Incrementing coin count by:", amount)
	update_coin_count()

func _on_coin_collected(value: int):
	# This function will be connected to the coin_collected signal from CoinArea
	print("Signal received: Coin collected with value:", value)
	increment_coin_count(value)
	coin_sound.play()

func _process(delta: float):
	if camera:
		# Smoothly move the UI element to match the camera's position
		position = lerp(position, camera.position + offset, ui_smooth_speed * delta)
	if coin_count>=coins_to_win:
		win=true
		print("win")
		get_tree().change_scene_to_file("res://Scenes/victory_screen.tscn")

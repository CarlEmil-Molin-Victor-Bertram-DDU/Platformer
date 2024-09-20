extends CharacterBody2D

@export var health = 50


@onready var animated_sprite = $AnimatedSprite2D
@onready var healthbar = $Healthbar
@onready var damage_numbers_origin = $DamageNumbers

var speed = 100  
var player_chase = false
var player = null

func _ready():
	healthbar.init_health(health)


func _set_health(_value):
	healthbar.health = health
	
	
	
func Health_damage(damage):
	health -= damage
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)
	if health <=0:
		self.queue_free()

func _physics_process(delta):
	if player_chase and player:
		var distance_to_player = position.distance_to(player.position)

		
		if distance_to_player > 1:  
			position = position.move_toward(player.position, speed * delta)
		else:
			player_chase = false  

		if player.position < position:
			animated_sprite.flip_h = false
		elif player.position > position:
			animated_sprite.flip_h = true


func _on_detection_body_entered(body):
	if body.name == "Player":  
		player = body
		player_chase = true
		print("detected body")


func _on_detection_body_exited(body):
	if body == player:
		player = null
		player_chase = false

func _on_hit_body_entered(body):
	if body.name == "Player":
		print("hit")

func _on_damage_button_pressed():
	Health_damage(20)
	_set_health(health)

extends CharacterBody2D 

@export var health = 50

@onready var animated_sprite = $AnimatedSprite2D
@onready var healthbar = $Healthbar
@onready var damage_numbers_origin = $DamageNumbers  # Assuming this node handles displaying damage numbers.

var speed = 60  
var player_chase = false
var player = null

func _ready():
	healthbar.init_health(health)

func _set_health(value):
	health = value
	healthbar.update_health(health)  # Assuming `update_health()` is the correct method for updating the healthbar.

func Health_damage(damage):
	health -= damage
	damage_numbers_origin.display_number(damage, damage_numbers_origin.global_position)  # Correctly use the `damage_numbers_origin` variable.
	_set_health(health)
	
	if health <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	if player_chase and player:
		var direction = (player.position - position).normalized()
		velocity.x = direction.x * speed
		velocity.y = direction.y * speed
		animated_sprite.flip_h = direction.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		velocity.y = move_toward(velocity.y, 0, speed * delta)
	move_and_slide()

func _on_detection_body_entered(body: Node) -> void:
	if body.name == "Player":  
		player = body
		player_chase = true

func _on_detection_body_exited(body: Node) -> void:
	if body == player:
		player = null
		player_chase = false
		
func _on_hit_body_entered(body):
	if body.name == "Player":
		print("hit")

func _on_damage_button_pressed():
	Health_damage(20)

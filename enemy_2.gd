extends CharacterBody2D

@export var health = 20

@onready var sprite = $Sprite2D
@onready var healthbar = $Healthbar
@onready var damage_numbers_origin = $DamageNumbers

var speed = 100  
var player_chase = false
var player = null
const JUMP_VELOCITY = 20.0


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	healthbar.init_health(health)


func _set_health(_value):
	healthbar.health = health
	
	
	
func Health_damage(damage):
	health -= damage
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)
	if health <=0:
		self.queue_free()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY


	if player_chase and player:
		var direction = (player.position - position).normalized()
		 
		velocity.x = direction.x * speed

		
		sprite.flip_h = direction.x < 0

	else:
		velocity.x = move_toward(velocity.x, 0, speed * delta)

	move_and_slide()

func _on_detect_body_entered(body: Node) -> void:
	if body.name == "Player":  
		player = body
		player_chase = true

func _on_detect_body_exited(body: Node) -> void:
	if body == player:
		player = null
		player_chase = false




func _on_damage_button_pressed():
	Health_damage(20)
	_set_health(health)

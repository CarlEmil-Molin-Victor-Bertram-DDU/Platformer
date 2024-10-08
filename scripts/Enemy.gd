extends CharacterBody2D 

@export var health = 50
@export var enemy_tag = "basic_enemy"  # Example of tagging enemies

@onready var animated_sprite = $AnimatedSprite2D
@onready var healthbar = $Healthbar
@onready var damage_numbers_origin = $DamageNumbers

var speed = 60  
var player_chase = false
var has_been_hit = false  # Track if the enemy has been hit
var player = null
var damage
signal hurt

var immunity_duration = 0.5  # Immunity duration in seconds
var immunity_timer = 0.0  # Timer to track immunity state
var knockback = false  # Track if knockback is occurring
var knockback_duration = 1  # Knockback duration
var knockback_timer = 0.0  # Timer to track knockback state
var dir

func _ready():
	add_to_group("enemies")
	healthbar.init_health(health)

func _set_health(_value):
	healthbar.health = health

func Health_damage(damage):
	# Only apply damage if the enemy is not immune
	if immunity_timer <= 0:
		health -= damage
		DamageNumbers.display_number(damage, damage_numbers_origin.global_position)
		_set_health(health)

		immunity_timer = immunity_duration

	if health <= 0:
		self.queue_free()

func reset_hit_status():
	has_been_hit = false  # Call this to reset the hit status

func _physics_process(delta: float) -> void:
	# Decrease the immunity timer
	if immunity_timer > 0:
		immunity_timer -= delta

	# Handle knockback
	if knockback:
		knockback_timer -= delta
		if knockback_timer > 0:
			if dir < 0:
				velocity.x = move_toward(velocity.x, 300, 300 * delta)
			else:
				velocity.x = move_toward(velocity.x, -300, 300 * delta)
		else:
			knockback = false  # Stop knockback after the duration is over

	# Only allow movement if knockback is not happening
	if not knockback:
		if player_chase and player:
			var direction = (player.position - position).normalized()
			velocity.x = direction.x * speed
			velocity.y = direction.y * speed
			animated_sprite.flip_h = direction.x < 0
			dir = direction.x
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
		emit_signal("hurt")

func _on_player_hit(hit_body: Node):
	if hit_body == self and immunity_timer <= 0:  # Only apply knockback if this enemy was the one hit
		velocity.x = dir * -1  # Apply knockback direction
		knockback = true
		knockback_timer = knockback_duration  # Reset the knockback timer
		damage = get_parent().get_node("Player").damage
		Health_damage(damage)

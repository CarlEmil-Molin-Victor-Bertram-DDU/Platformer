extends CharacterBody2D

@export var health = 100
@export var base_speed = 150.0
@export var sprint_speed = 300.0
@export var jump_force = -400.0
@export var acceleration = 50.0
@export var weapon = "stick"
@export var arrows = 1

@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var jump_sound: AudioStreamPlayer = $jump
@onready var landing_sound: AudioStreamPlayer = $LandingSound
@onready var sprint_sound: AudioStreamPlayer = $Sprint
@onready var walk_sound: AudioStreamPlayer = $walk
@onready var blink: AudioStreamPlayer = $blink
@onready var damage_sound: AudioStreamPlayer = $damage
@onready var death_sound: AudioStreamPlayer = $death
@onready var music: AudioStreamPlayer = get_tree().root.get_node("Node2D/AudioStreamPlayer")
@onready var coin_scene: PackedScene = preload("res://Scenes/coin.tscn")

signal hit

var speed = base_speed
var is_sprinting = false
var was_moving = false
var was_on_floor = false
var has_jumped = false
var is_jumping = false
var has_played = false
var damage
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var last_direction = 1  # 1 for right, -1 for left (default to right)
var knockback_dir = Vector2()
var knocked_back = false

var immunity_duration = 2  # Immunity duration in seconds
var immunity_timer = 0.0  # Timer to track immunity state
var is_flashing = false  # Track if the player is currently flashing
var flash_timer = 0.0  # Timer for controlling the flash interval
var flash_interval = 0.1  # Time between flashes

# Variables for weapon swing
var is_swinging = false
var swing_timer = 0.0
var swing_duration = 0.2
var hit_delay = 0.1
var post_hit_delay = 0.2
var cooldown_timer = 0.0  # Weapon cooldown timer

var swing_state = 0 # 0 = not swinging, 1 = delay before hit, 2 = hitting, 3 = post-hit delay

@export var weapon_stats = {
	"stick": {"damage": 5, "range": 30, "attack_speed": 0.8, "type": "melee"},
	"sword": {"damage": 10, "range": 50, "attack_speed": 1.0, "type": "melee"},
	"bow": {"damage": 8, "range": 200, "attack_speed": 0.8, "type": "ranged"},
	"axe": {"damage": 15, "range": 40, "attack_speed": 1.2, "type": "melee"},
	"fish": {"damage": 100, "range": 50, "attack_speed": 1.4, "type": "melee"},
	"banana": {"damage": 100, "range": 50, "attack_speed": 1.0, "type": "melee"},
}


@onready var sprint_explosion_particles = $SprintExplosionParticles
@onready var land_particles = $landparticles
@onready var sprint_trail_particles = $SprintParticles
@onready var weapon_swing_particles = $Stick/WeaponSwingParticles
@onready var animated_sprite = $AnimatedSprite2D
@onready var stick = $Stick # Reference to the stick sprite node
@onready var healthbar = $Healthbar
@onready var damage_numbers_origin = $DamageNumbers


func _ready():
	healthbar.init_health(health)
	if coin_scene == null:
		print("Error: coin_scene not loaded correctly")

func _input(event):
	if event is InputEventKey and event.keycode == KEY_SHIFT:
		if event.pressed and is_on_floor():
			start_sprinting()
		else:
			stop_sprinting()
			
	# Check for weapon swing (e.g., pressing spacebar)
	if event.is_action_pressed("ui_attack"):
		swing_weapon()
	
	if event.is_action_pressed("ui_accept"):
		for i in range(7):  # Loop to create 7 instances
			var coin_instance = coin_scene.instantiate()  # Create an instance of coin.tscn (use instantiate() in Godot 4.x)
			add_child(coin_instance)  # Add the instance to the player (self)
			# Optionally, set the position or properties relative to the player

func start_sprinting():
	if not is_sprinting:
		is_sprinting = true
		speed = sprint_speed
		trigger_sprint_explosion()
		sprint_trail_particles.emitting = true

func stop_sprinting():
	if is_sprinting:
		is_sprinting = false
		speed = base_speed
		sprint_trail_particles.emitting = false

func trigger_sprint_explosion():
	sprint_explosion_particles.emitting = true
	sprint_explosion_particles.restart()

func swing_weapon():
	if not is_swinging and cooldown_timer <= 0:
		is_swinging = true
		swing_state = 1  # Start with delay before hitting
		swing_timer = hit_delay  # Set the initial delay before the hit
		stick.visible = true  # Show the weapon before the hit
		stick.rotation_degrees = -41  # Start rotation

		# Set the cooldown timer based on the weapon's attack speed
		cooldown_timer = weapon_stats[weapon].attack_speed

func get_input():
	var input_direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = input_direction * speed
	
	# Update the animation based on movement
	if input_direction != 0:
		if is_sprinting:
			animated_sprite.play("run")
		else:
			animated_sprite.play("walk")
		# Update the last direction
		last_direction = sign(input_direction)
	else:
		animated_sprite.play("idle")
		if animated_sprite.frame == 2 and randi() % 5 == 0:
			animated_sprite.frame = 3
		elif animated_sprite.frame==2:
			animated_sprite.frame=0
		
	if is_on_floor():
		is_jumping = false
		if animated_sprite.frame == 0:
			has_played = false
			if not is_sprinting:
				speed = base_speed - 80
			elif is_sprinting:
				speed = sprint_speed - 80
		elif animated_sprite.frame == 1:
			if not is_sprinting:
				if input_direction != 0 and not has_played:
					walk_sound.play()
					has_played=true
				speed = base_speed
			elif is_sprinting:
				if input_direction != 0 and not has_played:
					sprint_sound.play()
					walk_sound.play()
					has_played=true
				speed = sprint_speed
		elif animated_sprite.frame ==3 and not has_played:
			blink.play()
			has_played=true

	# Flip the sprite based on movement direction
	if input_direction < 0:
		animated_sprite.flip_h = true
	elif input_direction > 0:
		animated_sprite.flip_h = false

	# Adjust stick position based on flip direction
	stick.position.x = 10 * last_direction  # Adjust the offset as needed

	# Trigger sprint explosion if started moving
	var is_moving = input_direction != 0
	if is_sprinting and not was_moving and is_moving:
		trigger_sprint_explosion()
	was_moving = is_moving

func _physics_process(delta: float) -> void:
	damage=weapon_stats[weapon].damage
	get_input()
	
		# Process damage immunity timer
	if immunity_timer > 0:
		immunity_timer -= delta
	
		# Handle flashing effect if player is hurt and in the immunity phase
		if is_flashing:
			flash_timer += delta
			if flash_timer >= flash_interval:
				flash_timer = 0.0
				
				# Toggle between red and normal color
				if animated_sprite.modulate == Color(1, 0.2, 0.2, 0.7):
					animated_sprite.modulate = Color(1, 1, 1, 1)  # Reset to normal color
				else:
					animated_sprite.modulate = Color(1, 0.2, 0.2, 0.7)  # Flash red and semi-transparent
		
		# Stop flashing after immunity ends
		if immunity_timer <= 0:
			stop_flashing()
	
	if not is_swinging:
		stick.visible = false
	
	if is_swinging:
		swing_timer -= delta
		if swing_state == 1:
			if swing_timer <= 0:
				swing_state = 2
				swing_timer = swing_duration
				weapon_swing_particles.emitting = true
		
		elif swing_state == 2:
			for body in $Stick/hit.get_overlapping_bodies():
				if swing_state == 2 and body.is_in_group("enemies"):
					print("knockback")
					knocked_back = true
					print("Enemy hit:", body.name)
					emit_signal("hit", body)  # Emit the hit signal

			if last_direction == 1:
				stick.rotation_degrees = lerp(-41, 180, (swing_duration - swing_timer) / swing_duration)
			else:
				stick.rotation_degrees = lerp(-41, -270, (swing_duration - swing_timer) / swing_duration)
			
			if swing_timer <= 0:
				swing_state = 3
				swing_timer = post_hit_delay
				if last_direction == 1:
					stick.rotation_degrees = 180
				else:
					stick.rotation_degrees = -270
				weapon_swing_particles.emitting = false
				knocked_back=false
		
		elif swing_state == 3: # Post-hit delay
			# Weapon stays in the final position during this phase
			if swing_timer <= 0:
				# End the swing process
				is_swinging = false
				swing_state = 0
				stick.visible = false # Hide the weapon

	# Update cooldown timer
	if cooldown_timer > 0:
		cooldown_timer -= delta

	if not is_on_floor():
		was_on_floor=true
		if is_jumping==true:
			has_jumped=true
		velocity.y += gravity * delta
		animated_sprite.play("walk")
		animated_sprite.frame = 1
		animated_sprite.pause()
		sprint_trail_particles.emitting = false
		sprint_explosion_particles.emitting = false
		if is_sprinting:
			speed = sprint_speed
		elif not is_sprinting:
			speed = base_speed
	elif is_on_floor() and is_sprinting:
		sprint_trail_particles.emitting = true
		sprint_explosion_particles.emitting = true
	else:
		velocity.y = max(velocity.y, 0)

	# Handle jump
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force
		jump_sound.play()
		walk_sound.play()
		is_jumping=true
	# Check if the character has just landed
	if is_on_floor() and was_on_floor and has_jumped:
		landing_sound.play()  # Play the landing sound
		land_particles.emitting=true
		animated_sprite.frame = 0  # Set the sprite frame to 0
		print("landed")
		was_on_floor = false
		has_jumped = false

	# Move the character
	move_and_slide()

func _set_health(_value):
	if health <= 0:
		attack_sound.stop()
		blink.stop()
		jump_sound.stop()
		sprint_sound.stop()
		walk_sound.stop()
		landing_sound.stop()
		music.stop()
		death_sound.play()
		
	healthbar.health = health

func Health_damage(damage):
	damage_sound.play()
	health -= damage
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)

func _on_death_finished() -> void:
	self.queue_free()
	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")

var coin_count: int = 0

# This function should be connected to the coin_collected signal
func _on_coin_collected(value: int):
	coin_count += value
	print("Coins collected: t nh", coin_count)  # Update UI or other logic

func on_coin_area_entered(coin: Area2D):
	# Connect the coin_collected signal to the _on_coin_collected function
	coin.coin_collected.connect(Callable(self, "_on_coin_collected"))
	print("Coin signal connected to player.")

func _on_enemy_hurt() -> void:
	if immunity_timer <= 0:
		Health_damage(5)
		_set_health(health)
		
		immunity_timer = immunity_duration
		start_flashing()

func _on_enemy_2_hurt() -> void:
	if immunity_timer <= 0:
		Health_damage(5)
		_set_health(health)
		
		immunity_timer = immunity_duration
		start_flashing()

func _on_enemy_3_hurt() -> void:
	if immunity_timer <= 0:
		Health_damage(5)
		_set_health(health)
		
		immunity_timer = immunity_duration
		start_flashing()

# Start the flashing effect
func start_flashing():
	is_flashing = true
	flash_timer = 0.0  # Reset the flash timer

# Function to stop flashing after immunity ends
func stop_flashing():
	is_flashing = false
	animated_sprite.modulate = Color(1, 1, 1, 1)  # Reset to normal color

extends CharacterBody2D

@export var speed = 300
@export var gravity = 500
@export var air_resistance = 0.98

signal hit

func _ready() -> void:
	velocity.x=speed

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Apply gravity to the Y component of velocity
	velocity.y += gravity * delta
	
	# Update the X velocity with air resistance
	velocity.x *= air_resistance
	
	# Rotate the arrow to match its direction of flight
	if velocity.length() > 0:
		rotation = velocity.angle()
	
	if is_on_floor():
		queue_free()
		
	move_and_slide()

func _on_hit_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		emit_signal("hit")
		queue_free()

extends CharacterBody2D

@export var wall_slide_ray_cast: RayCast2D
@export var animated_sprite: AnimatedSprite2D

enum STATE {
	FALL,
	FLOOR,
	JUMP,
	WALL_SLIDE,
	WALL_JUMP
}

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var active_state := STATE.FALL
var facing_direction := 1.0
var saved_position := Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func switch_state(to_state: STATE):
	var previous_state := active_state
	active_state = to_state

func process_state(delta: float):
	pass

func handle_movement(input_direction: float):
	if input_direction == 0:
		input_direction = signf(Input.get_axis("move_left", "move_right"))
	set_facing_direction(input_direction)
	velocity.x = move_toward(velocity.x, input_direction * SPEED, SPEED)

func set_facing_direction(direction: float) -> void:
	if direction:
		animated_sprite.flip_h = direction < 0
		facing_direction = direction
		wall_slide_ray_cast.position.x = direction * absf(wall_slide_ray_cast.position.x)
		wall_slide_ray_cast.target_position.x = direction * absf(wall_slide_ray_cast.target_position.x)
		wall_slide_ray_cast.force_raycast_update()

func can_wall_slide() -> bool:
	return is_on_wall_only() and wall_slide_ray_cast.is_colliding()

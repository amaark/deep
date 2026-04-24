extends CharacterBody2D

@export var jump_height: float
@export var jump_time_to_peak: float
@export var jump_time_to_descent: float

@onready var jump_velocity: float = (-2 * jump_height) / jump_time_to_peak
@onready var jump_gravity: float = (2 * jump_height) / (jump_time_to_peak ** 2)
@onready var fall_gravity: float = (2 * jump_height) / (jump_time_to_descent ** 2)
@onready var fall_velocity: float = (2 * jump_height) / jump_time_to_descent

@onready var wall_slide_ray_cast: RayCast2D = $WallSlideRayCast
@onready var animated_sprite: AnimatedSprite2D = $Sprite
@onready var coyote_timer: Timer = $CoyoteTimer

enum STATE {
	FALL,
	FLOOR,
	JUMP,
	WALL_SLIDE,
	WALL_JUMP
}

const WALK_VELOCITY := 100.0
const JUMP_VELOCITY := -300.0
const JUMP_DECELERATION := 1000.0
const FALL_VELOCITY := 400.0
const FALL_GRAVITY := 1000.0
const WALL_SLIDE_GRAVITY := 300.0
const WALL_SLIDE_VELOCITY := 500.0
const WALL_JUMP_VELOCITY := -300.0
const WALL_JUMP_LENGTH := 15.0

var active_state := STATE.FALL
var facing_direction := -1.0
var saved_position := Vector2.ZERO

func _ready() -> void:
	switch_state(active_state)

func _physics_process(delta: float) -> void:
	process_state(delta)
	move_and_slide()

func switch_state(to_state: STATE) -> void:
	var previous_state := active_state
	active_state = to_state
	
	match active_state:
		STATE.FALL:
			animated_sprite.play("fall")
			# If we just fell off a ledge, start the coyote timer
			if previous_state == STATE.FLOOR:
				coyote_timer.start()
				
		STATE.JUMP:
			animated_sprite.play("jump")
			velocity.y = jump_velocity
			#velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
		
		STATE.WALL_SLIDE:
			animated_sprite.play("wall_slide")
			velocity.y = 0
			
		STATE.WALL_JUMP:
			animated_sprite.play("jump")
			velocity.y = jump_velocity
			#velocity.y = WALL_JUMP_VELOCITY
			set_facing_direction(-facing_direction)
			saved_position = position

func process_state(delta: float) -> void:
	match active_state:
		STATE.FALL:
			velocity.y = move_toward(velocity.y, fall_velocity, fall_gravity * delta)
			#velocity.y = move_toward(velocity.y, FALL_VELOCITY, FALL_GRAVITY * delta)
			handle_movement()
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif Input.is_action_just_pressed("jump"):
				if coyote_timer.time_left > 0:
					switch_state(STATE.JUMP)
			elif is_input_toward_facing() and can_wall_slide():
				switch_state(STATE.WALL_SLIDE)
		
		STATE.FLOOR:
			if Input.get_axis("move_left", "move_right"):
				animated_sprite.play("walk")
			else:
				animated_sprite.play("idle")
			handle_movement()
			if not is_on_floor():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.JUMP)
				
		STATE.JUMP:
			velocity.y = move_toward(velocity.y, 0, jump_gravity * delta)
			#velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			handle_movement()
			if Input.is_action_just_released("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)
		
		STATE.WALL_JUMP:
			velocity.y = move_toward(velocity.y, 0, jump_gravity * delta)
			#velocity.y = move_toward(velocity.y, 0, JUMP_DECELERATION * delta)
			var distance_jumped := absf(position.x - saved_position.x)
			if distance_jumped >= WALL_JUMP_LENGTH or can_wall_slide():
				# Transition into normal jumping state, carrying the momentum upward
				active_state = STATE.JUMP
			else:
				# Force player to continue their trajectory away from the wall
				handle_movement(facing_direction)
			if Input.is_action_just_released("jump") or velocity.y >= 0:
				velocity.y = 0
				switch_state(STATE.FALL)
		
		STATE.WALL_SLIDE:
			velocity.y = move_toward(velocity.y, WALL_SLIDE_VELOCITY, WALL_SLIDE_GRAVITY * delta)
			handle_movement()
			if is_on_floor():
				switch_state(STATE.FLOOR)
			elif not can_wall_slide():
				switch_state(STATE.FALL)
			elif Input.is_action_just_pressed("jump"):
				switch_state(STATE.WALL_JUMP)

func handle_movement(input_direction: float = 0) -> void:
	if input_direction == 0:
		input_direction = signf(Input.get_axis("move_left", "move_right"))
	set_facing_direction(input_direction)
	velocity.x = move_toward(velocity.x, input_direction * WALK_VELOCITY, WALK_VELOCITY)

func set_facing_direction(direction: float) -> void:
	if direction:
		animated_sprite.flip_h = direction > 0
		facing_direction = direction
		wall_slide_ray_cast.position.x = direction * absf(wall_slide_ray_cast.position.x)
		wall_slide_ray_cast.target_position.x = direction * absf(wall_slide_ray_cast.target_position.x)
		wall_slide_ray_cast.force_raycast_update()

func can_wall_slide() -> bool:
	return is_on_wall_only() and wall_slide_ray_cast.is_colliding()

func is_input_toward_facing() -> bool:
	return signf(Input.get_axis("move_left", "move_right")) == facing_direction

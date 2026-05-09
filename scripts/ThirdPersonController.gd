extends CharacterBody3D
class_name ThirdPersonController

# Movement constants - Tunable for feel
const WALK_SPEED = 3.0
const RUN_SPEED = 6.0
const ACCELERATION = 8.0
const DECELERATION = 10.0
const JUMP_VELOCITY = 5.0
const ROTATION_SPEED = 10.0
const COYOTE_TIME = 0.15
const JUMP_BUFFER_TIME = 0.1
const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 20.0
const STAMINA_REGEN = 10.0
const SLIDE_SPEED = 8.0
const SLIDE_DURATION = 1.0
const CROUCH_SPEED_MULTIPLIER = 0.5

# Camera and input
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var visuals: Node3D = $Visuals
@onready var animation_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# State variables
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_grounded: bool = false
var current_speed: float = WALK_SPEED
var target_rotation: float = 0.0
var stamina: float = MAX_STAMINA
var is_sliding: bool = false
var slide_timer: float = 0.0
var standing_height: float = 1.8
var crouch_height: float = 0.9

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		camera.make_current()
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		standing_height = collision_shape.shape.height
		crouch_height = standing_height * 0.5

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Handle camera orbit
		if camera_pivot:
			camera_pivot.rotate_y(-event.relative.x * 0.005)
			var pitch = camera_pivot.rotation.x - event.relative.y * 0.005
			camera_pivot.rotation.x = clamp(pitch, -PI/3, PI/3)

func _physics_process(delta: float) -> void:
	# Ground check and coyote time - Allows jumping slightly after falling
	is_grounded = is_on_floor()
	if is_grounded:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# Jump buffer - Registers jump input even if pressed slightly early
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	jump_buffer_timer -= delta

	# Apply gravity - Delta-time based for consistency
	if not is_grounded:
		velocity.y -= gravity * delta

	# Handle jump - Responsive with coyote and buffer
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0

	# Variable jump height - Release jump for shorter hops
	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.5

	# Movement input (camera-relative) - Direction based on camera orientation
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var camera_basis = camera.global_transform.basis
	var forward = camera_basis.z.normalized()  # Camera's backward direction
	var right = camera_basis.x.normalized()
	
	var move_dir = (forward * input_dir.y + right * input_dir.x).normalized()
	move_dir.y = 0  # Keep movement horizontal

	# Handle crouch - Adjusts speed and collision height
	var is_crouching = Input.is_action_pressed("crouch")
	if is_crouching:
		current_speed *= CROUCH_SPEED_MULTIPLIER
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			collision_shape.shape.height = crouch_height
	else:
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			collision_shape.shape.height = standing_height

	# Handle sprint with stamina - Drains on sprint, regenerates otherwise
	var is_sprinting = Input.is_action_pressed("sprint") and stamina > 0 and not is_crouching
	if is_sprinting:
		current_speed = RUN_SPEED
		stamina -= STAMINA_DRAIN * delta
		stamina = max(stamina, 0)
	else:
		current_speed = WALK_SPEED
		stamina += STAMINA_REGEN * delta
		stamina = min(stamina, MAX_STAMINA)

	# Handle slide - Sprint + crouch for short boost
	if is_crouching and is_sprinting and is_grounded and not is_sliding and move_dir.length() > 0.1:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		velocity.x = move_dir.x * SLIDE_SPEED
		velocity.z = move_dir.z * SLIDE_SPEED

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			is_sliding = false
		# Keep sliding velocity, no input during slide
	else:
		# Smooth acceleration/deceleration - Lerp for polished feel
		var target_velocity = move_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)

	# Character rotation smoothing - Faces movement direction smoothly
	if move_dir.length() > 0.1 and not is_sliding:
		target_rotation = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)

	# Animation - Switches based on state
	if is_grounded:
		if move_dir.length() > 0.1 and not is_sliding:
			if animation_player.current_animation != "walk":
				animation_player.play("walk")
		else:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
	else:
		if animation_player.current_animation != "jump":
			animation_player.play("jump")

	# Visuals rotation - Smooth sync with body
	if visuals:
		visuals.rotation.y = lerp_angle(visuals.rotation.y, rotation.y, ROTATION_SPEED * delta)

	move_and_slide()
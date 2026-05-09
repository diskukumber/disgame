extends CharacterBody3D
class_name DualCameraPlayer

# Movement constants
const SPEED = 4.8
const JUMP_VELOCITY = 4.5
const SPRINT_MULTIPLIER = 2.0
const CROUCH_SPEED_MULTIPLIER = 0.5
const sensitivity = 0.01
const HEAD_BOB_FREQUENCY = 2.0
const HEAD_BOB_AMPLITUDE = 0.05
const ACCELERATION = 10.0
const DECELERATION = 15.0
const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 20.0
const STAMINA_REGEN = 10.0
const SLIDE_SPEED = 8.0
const SLIDE_DURATION = 1.0
const COYOTE_TIME = 0.1

# State variables
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var head_bob_time = 0.0
var initial_camera_y = 0.0
var stamina = MAX_STAMINA
var is_sliding = false
var slide_timer = 0.0
var coyote_timer = 0.0
var standing_height = 1.8
var crouch_height = 0.9

# Nodes
@onready var visuals = $Visuals
@onready var animation_player = $Visuals/AnimationPlayer
@onready var collision_shape = $CollisionShape3D
@onready var camera_manager: CameraManager = $CameraManager

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera_manager and camera_manager.first_person_camera:
		initial_camera_y = camera_manager.first_person_camera.position.y
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		standing_height = collision_shape.shape.height
		crouch_height = standing_height * 0.5

func _input(event):
	if event is InputEventMouseMotion:
		# Yaw rotation (body)
		rotate_y(-event.relative.x * sensitivity)
		
		# Pitch rotation (camera)
		if camera_manager:
			if camera_manager.current_mode == CameraManager.CameraMode.FIRST_PERSON:
				if camera_manager.first_person_camera:
					var pitch = camera_manager.first_person_camera.rotation.x - event.relative.y * sensitivity
					camera_manager.first_person_camera.rotation.x = clamp(pitch, deg_to_rad(-70), deg_to_rad(70))
			else:
				if camera_manager.third_person_pivot:
					var pitch = camera_manager.third_person_pivot.rotation.x - event.relative.y * sensitivity
					camera_manager.third_person_pivot.rotation.x = clamp(pitch, deg_to_rad(-10), deg_to_rad(10))

func _physics_process(delta):
	# Gravity and coyote
	if not is_on_floor():
		velocity.y -= gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME

	# Jump
	if Input.is_action_just_pressed("jump") and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("jump") and velocity.y > 0:
		velocity.y *= 0.5

	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPEED
	var is_crouching = Input.is_action_pressed("crouch")
	var is_sprinting = Input.is_action_pressed("sprint") and stamina > 0 and not is_crouching

	# Crouch
	if is_crouching:
		current_speed *= CROUCH_SPEED_MULTIPLIER
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			collision_shape.shape.height = crouch_height
		if camera_manager and camera_manager.current_mode == CameraManager.CameraMode.FIRST_PERSON:
			if camera_manager.first_person_camera:
				camera_manager.first_person_camera.position.y = initial_camera_y * 0.5
	else:
		if collision_shape and collision_shape.shape is CapsuleShape3D:
			collision_shape.shape.height = standing_height
		if camera_manager and camera_manager.current_mode == CameraManager.CameraMode.FIRST_PERSON:
			if camera_manager.first_person_camera:
				camera_manager.first_person_camera.position.y = initial_camera_y

	# Sprint
	if is_sprinting:
		current_speed *= SPRINT_MULTIPLIER
		stamina -= STAMINA_DRAIN * delta
		stamina = max(stamina, 0)
	else:
		stamina += STAMINA_REGEN * delta
		stamina = min(stamina, MAX_STAMINA)

	# Slide
	if is_crouching and is_sprinting and is_on_floor() and not is_sliding and direction:
		is_sliding = true
		slide_timer = SLIDE_DURATION
		velocity.x = direction.x * SLIDE_SPEED
		velocity.z = direction.z * SLIDE_SPEED

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			is_sliding = false
	else:
		var target_velocity = direction * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)

	# Animation
	if direction and not is_sliding:
		if animation_player.current_animation != "player/Walking":
			animation_player.play("player/Walking")
		visuals.look_at(position + direction)
	else:
		if animation_player.current_animation != "player/Idle":
			animation_player.play("player/Idle")

	# Head bob for first-person
	if camera_manager and camera_manager.current_mode == CameraManager.CameraMode.FIRST_PERSON and direction and not is_sliding:
		head_bob_time += delta * HEAD_BOB_FREQUENCY
		var bob_offset = sin(head_bob_time) * HEAD_BOB_AMPLITUDE
		if camera_manager.first_person_camera:
			camera_manager.first_person_camera.position.y = initial_camera_y + bob_offset
	else:
		head_bob_time = 0.0
		if camera_manager and camera_manager.first_person_camera:
			camera_manager.first_person_camera.position.y = initial_camera_y

	move_and_slide()
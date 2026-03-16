extends CharacterBody3D

# Constants
const SPEED = 4.8
const JUMP_VELOCITY = 4.5
const SPRINT_MULTIPLIER = 2.0
const CROUCH_SPEED_MULTIPLIER = 0.5
const sensitivity = 0.01
const HEAD_BOB_FREQUENCY = 2.0
const HEAD_BOB_AMPLITUDE = 0.05

# Variables
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var head_bob_time = 0.0
var initial_camera_y = 0.0

# Camera nodes
@onready var FirstPersonCameraController = $FirstPersonCameraController
@onready var ThirdPersonCameraController = $ThirdPersonCameraController
@onready var FirstPersonCamera = $FirstPersonCameraController/FirstPersonCamera
@onready var ThirdPersonCamera = $ThirdPersonCameraController/ThirdPersonCamera
@onready var animation_player = $Visuals/YBot/AnimationPlayer
@onready var visuals = $Visuals

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	initial_camera_y = FirstPersonCameraController.position.y

func _input(event):
	if event.is_action_pressed("SwitchCamera"):
		if FirstPersonCamera.is_current():
			FirstPersonCamera.clear_current()
			ThirdPersonCamera.make_current()
		else:
			ThirdPersonCamera.clear_current()
			FirstPersonCamera.make_current()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		if FirstPersonCamera.is_current():
			FirstPersonCameraController.rotate_x(-event.relative.y * sensitivity)
			FirstPersonCameraController.rotation.x = clamp(FirstPersonCameraController.rotation.x, deg_to_rad(-70), deg_to_rad(70))
		elif ThirdPersonCamera.is_current():
			ThirdPersonCameraController.rotate_x(-event.relative.y * sensitivity)
			ThirdPersonCameraController.rotation.x = clamp(ThirdPersonCameraController.rotation.x, deg_to_rad(-10), deg_to_rad(10))

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed = SPEED
	if Input.is_action_pressed("sprint"):
		current_speed *= SPRINT_MULTIPLIER
	if Input.is_action_pressed("crouch"):
		current_speed *= CROUCH_SPEED_MULTIPLIER
		# Note: Add collision shape adjustment for crouch if needed

	if direction:
		if animation_player.current_animation != "player/Walking":
			animation_player.play("player/Walking")
		visuals.look_at(position + direction)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		# Head bob
		head_bob_time += delta * HEAD_BOB_FREQUENCY
		var bob_offset = sin(head_bob_time) * HEAD_BOB_AMPLITUDE
		if FirstPersonCamera.is_current():
			FirstPersonCameraController.position.y = initial_camera_y + bob_offset
	else:
		if animation_player.current_animation != "player/Idle":
			animation_player.play("player/Idle")
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		head_bob_time = 0.0
		if FirstPersonCamera.is_current():
			FirstPersonCameraController.position.y = initial_camera_y

	move_and_slide()

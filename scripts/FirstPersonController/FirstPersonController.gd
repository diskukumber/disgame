extends CharacterBody3D

# speed
const SPEED = 4.8
# jump
const JUMP_VELOCITY = 4.5
# mouse sensitivity
const sensitivity = 0.01



# gravity
var gravity = 9.8
# camera
@onready var FirstPersonCameraController = $FirstPersonCameraController
@onready var ThirdPersonCameraController = $ThirdPersonCameraController

@onready var FirstPersonCamera = $FirstPersonCameraController/FirstPersonCamera
@onready var ThirdPersonCamera = $ThirdPersonCameraController/ThirdPersonCamera


@onready var animation_player = $Visuals/YBot/AnimationPlayer
@onready var visuals = $Visuals


func _input(event):
	if event.is_action_pressed("SwitchCamera"):
		if FirstPersonCamera.is_current():
			FirstPersonCamera.clear_current(true)
		else:
			ThirdPersonCamera.clear_current(true)


# Handling mouse Camera control
func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		FirstPersonCameraController.rotate_x(-event.relative.y * sensitivity)
		FirstPersonCameraController.rotation.x = clamp(FirstPersonCameraController.rotation.x, deg_to_rad(-70), deg_to_rad(70))



# Handling mouse Camera control
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)

		ThirdPersonCameraController.rotate_x(-event.relative.y * sensitivity)
		ThirdPersonCameraController.rotation.x = clamp(ThirdPersonCameraController.rotation.x, deg_to_rad(-10), deg_to_rad(10))


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if animation_player.current_animation != "player/Walking":
			animation_player.play("player/Walking")
			visuals.look_at(position + direction)

		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		if animation_player.current_animation != "player/Idle":
			animation_player.play("player/Idle")
			
		velocity.x = 0.0
		velocity.z = 0.0
		
	move_and_slide()

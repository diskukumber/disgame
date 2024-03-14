extends CharacterBody3D

# speed
const SPEED = 8.0
# jump
const JUMP_VELOCITY = 4.5
# mouse sensitivity
const sensitivity = 0.01


# gravity
var gravity = 9.8
# camera
@onready var head = $head
@onready var camera = $head/Camera3D


# Handling mouse Camera control
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))


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
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()

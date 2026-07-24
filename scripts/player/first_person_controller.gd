extends CharacterBody3D

const SPEED: float = 4.5
const SPRINT_MULTIPLIER: float = 1.8
const CROUCH_MULTIPLIER: float = 0.5
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.003
const MIN_PITCH: float = deg_to_rad(-70)
const MAX_PITCH: float = deg_to_rad(70)
const FIRST_PERSON_FOV: float = 75.0
const THIRD_PERSON_FOV: float = 75.0

@onready var visuals: Node3D = get_node_or_null("Visuals") as Node3D
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
@onready var head: Node3D = get_node_or_null("CameraController/Head") as Node3D
@onready var first_person_camera: Camera3D = get_node_or_null("FirstPersonCamera") as Camera3D
@onready var third_person_camera: Camera3D = get_node_or_null("CameraController/SpringArm3D/ThirdPersonCamera") as Camera3D
@onready var camera_controller: Node3D = get_node_or_null("CameraController") as Node3D

const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/menus/pause_menu.tscn")
var pause_menu: CanvasLayer = null

var yaw: float = 0.0
var pitch: float = 0.0
var is_first_person: bool = true
var is_crouching: bool = false
var is_sprinting: bool = false
var standing_height: float = 1.8
var crouch_height: float = 0.9

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		standing_height = collision_shape.shape.height
		crouch_height = standing_height * 0.5
	if not first_person_camera:
		first_person_camera = find_child("FirstPersonCamera", true, false) as Camera3D
	if not third_person_camera and camera_controller:
		third_person_camera = camera_controller.get_node_or_null("SpringArm3D/ThirdPersonCamera") as Camera3D
	if not third_person_camera:
		third_person_camera = find_child("ThirdPersonCamera", true, false) as Camera3D
	if not camera_controller:
		camera_controller = get_node_or_null("CameraController") as Node3D
	if not head and camera_controller:
		head = camera_controller.get_node_or_null("Head") as Node3D
	if not head:
		head = find_child("Head", true, false) as Node3D
	_setup_pause_menu()
	_update_camera_mode()
	_update_camera_positions()

func _setup_pause_menu() -> void:
	if not pause_menu:
		pause_menu = PAUSE_MENU_SCENE.instantiate() as CanvasLayer
		if pause_menu:
			pause_menu.name = "PauseMenu"
			add_child(pause_menu)
			pause_menu.hide()

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	if event is InputEventMouseMotion:
		yaw -= event.relative.x * MOUSE_SENSITIVITY
		pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
		rotation.y = yaw
		if is_first_person:
			if head:
				head.rotation.x = pitch
		else:
			if camera_controller:
				camera_controller.rotation.y = yaw
			if head:
				head.rotation.x = 0.0

	if event.is_action_pressed("switch_view"):
		is_first_person = not is_first_person
		_update_camera_mode()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_process_movement(delta)
	_update_camera_positions()
	_update_animations()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

func _process_movement(delta: float) -> void:
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis = head.global_transform.basis if head else transform.basis
	if not is_first_person and camera_controller:
		camera_basis = camera_controller.global_transform.basis
	var forward = -camera_basis.z
	var right = camera_basis.x
	var move_dir = (forward * input_vec.y + right * input_vec.x)
	move_dir.y = 0.0
	if move_dir.length() > 0.0:
		move_dir = move_dir.normalized()

	is_crouching = Input.is_action_pressed("crouch")
	is_sprinting = Input.is_action_pressed("sprint") and move_dir.length() > 0.1 and not is_crouching
	var target_speed = SPEED
	if is_sprinting:
		target_speed *= SPRINT_MULTIPLIER
	if is_crouching:
		target_speed *= CROUCH_MULTIPLIER

	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = crouch_height if is_crouching else standing_height

	var target_velocity = move_dir * target_speed
	velocity.x = lerp(velocity.x, target_velocity.x, 10.0 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 10.0 * delta)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()

func _update_camera_mode() -> void:
	if first_person_camera:
		first_person_camera.current = is_first_person
		first_person_camera.fov = FIRST_PERSON_FOV
	if third_person_camera:
		third_person_camera.current = not is_first_person
		third_person_camera.fov = THIRD_PERSON_FOV
	if visuals:
		visuals.visible = not is_first_person

func _update_camera_positions() -> void:
	if first_person_camera and head:
		first_person_camera.global_transform = head.global_transform

func _update_animations() -> void:
	var animation_player = visuals.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if not animation_player:
		return

	var moving = Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.1
	if moving and not is_crouching:
		if animation_player.current_animation != "player/Walking":
			animation_player.play("player/Walking")
	elif animation_player.current_animation != "player/Idle":
		animation_player.play("player/Idle")

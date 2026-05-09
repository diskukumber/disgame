class_name Player
extends CharacterBody3D

signal health_changed(current: float, max: float)
signal died()
signal respawned()
signal state_changed(state: String)

@onready var head: Node3D = $Head
@onready var fps_camera: Camera3D = $Head/FPS_Camera
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var tps_camera: Camera3D = $SpringArm3D/TPS_Camera
@onready var model: Node3D = $Model
@onready var ui: CanvasLayer = $UI

@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_force: float = 8.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.002
@export var normal_fov: float = 75.0
@export var sprint_fov: float = 85.0

var is_invulnerable: bool = false
var is_paused: bool = false
var is_input_enabled: bool = true
var is_first_person: bool = false
var yaw: float = 0.0
var pitch: float = 0.0
var target_fov: float = 75.0
var mouse_captured: bool = false

var is_crouching: bool = false
var is_sprinting: bool = false
var is_jumping: bool = false
var is_attacking: bool = false
var is_aiming: bool = false
var is_on_ground: bool = false

var current_weapon: String = "Fists"
var combo_index: int = 0
var combo_timer: float = 0.0

enum PlayerState { IDLE, MOVING, SPRINTING, CROUCHING, JUMPING, ATTACKING, AIMING, DEAD }
var current_state: PlayerState = PlayerState.IDLE

func _ready() -> void:
	_setup_collision_shape()
	if tps_camera:
		tps_camera.current = true
		tps_camera.fov = normal_fov
	if spring_arm:
		spring_arm.spring_length = 4.0
	print("Player initialized")

func _setup_collision_shape() -> void:
	if not has_node("CollisionShape3D"):
		var collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var shape = $CollisionShape3D.shape
	if shape == null:
		shape = CylinderShape3D.new()
		$CollisionShape3D.shape = shape
		shape.height = 1.8
		shape.position.y = 0.9

func _input(event: InputEvent) -> void:
	if not is_input_enabled or is_paused:
		return
	
	if event is InputEventMouseMotion and mouse_captured:
		_process_look(event.relative)
	
	if event.is_action_pressed("switch_view"):
		_switch_camera_mode()
	
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_captured = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true
	
	if event.is_action_pressed("attack_light") or event.is_action_pressed("attack_heavy"):
		_perform_attack()
	
	if event.is_action_pressed("aim"):
		_start_aim()
	elif event.is_action_pressed("aim_release"):
		_stop_aim()

func _process(_delta: float) -> void:
	if is_paused:
		return
	
	var gamepad_input := Vector2(
		Input.get_axis("look_right", "look_left"),
		Input.get_axis("look_down", "look_up")
	)
	if gamepad_input.length() > 0.1:
		_process_look(gamepad_input * 0.05)
	
	_update_fov(_delta)

func _physics_process(_delta: float) -> void:
	if is_paused:
		return
	
	_process_movement_input()
	_apply_gravity(_delta)
	_apply_movement(_delta)
	_update_player_state()

func _process_look(movement: Vector2) -> void:
	yaw -= movement.x * mouse_sensitivity
	pitch -= movement.y * mouse_sensitivity
	pitch = clamp(pitch, -1.4, 1.4)
	
	var player = self
	if is_first_person:
		if head:
			head.rotation.x = pitch
		player.rotation.y = yaw
	else:
		player.rotation.y = yaw
		if spring_arm:
			spring_arm.rotation.x = -pitch

func _switch_camera_mode() -> void:
	is_first_person = not is_first_person
	
	if is_first_person:
		if fps_camera:
			fps_camera.current = true
			fps_camera.fov = normal_fov
		if tps_camera:
			tps_camera.current = false
		if model:
			model.visible = false
	else:
		if tps_camera:
			tps_camera.current = true
			tps_camera.fov = normal_fov
		if fps_camera:
			fps_camera.current = false
		if model:
			model.visible = true
	
	target_fov = normal_fov

func _update_fov(delta: float) -> void:
	var lerp_speed = 10.0 * delta
	if fps_camera and is_first_person:
		fps_camera.fov = lerp(fps_camera.fov, target_fov, lerp_speed)
	elif tps_camera:
		tps_camera.fov = lerp(tps_camera.fov, target_fov, lerp_speed)

func _start_aim() -> void:
	is_aiming = true
	target_fov = 50.0

func _stop_aim() -> void:
	is_aiming = false
	target_fov = normal_fov

func _process_movement_input() -> void:
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_z: float = Input.get_axis("move_forward", "move_back")
	var input_dir = Vector3(input_x, 0.0, input_z).normalized()
	
	if Input.is_action_pressed("sprint") and not is_crouching:
		is_sprinting = true
		target_fov = sprint_fov
	else:
		is_sprinting = false
		if not is_aiming:
			target_fov = normal_fov
	
	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching

func _apply_gravity(delta: float) -> void:
	is_on_ground = is_on_floor()
	
	if is_on_ground:
		if velocity.y < 0:
			velocity.y = 0.0
		is_jumping = false
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			is_jumping = true
			is_on_ground = false
	else:
		velocity.y -= gravity * delta
		if velocity.y < -50.0:
			velocity.y = -50.0

func _apply_movement(delta: float) -> void:
	var target_speed: float = 0.0
	
	if is_crouching:
		target_speed = crouch_speed
	elif is_sprinting:
		target_speed = sprint_speed
	else:
		target_speed = walk_speed
	
	var input_x: float = Input.get_axis("move_left", "move_right")
	var input_z: float = Input.get_axis("move_forward", "move_back")
	var input_dir = Vector3(input_x, 0.0, input_z).normalized()
	
	if input_dir.length() > 0.1:
		var forward = -transform.basis.z
		var right = transform.basis.x
		var world_dir = (forward * input_z + right * input_x)
		world_dir.y = 0.0
		world_dir = world_dir.normalized()
		
		var current_horiz = Vector3(velocity.x, 0.0, velocity.z)
		var target_vel = world_dir * target_speed
		var accel = 10.0 if is_on_ground else 2.0
		current_horiz = current_horiz.lerp(target_vel, accel * delta)
		velocity.x = current_horiz.x
		velocity.z = current_horiz.z
	else:
		if is_on_ground:
			var current_horiz = Vector3(velocity.x, 0.0, velocity.z)
			var new_horiz = current_horiz.lerp(Vector3.ZERO, 8.0 * delta)
			velocity.x = new_horiz.x
			velocity.z = new_horiz.z
	
	move_and_slide()

func _perform_attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	combo_index = (combo_index + 1) % 3
	await get_tree().create_timer(0.3).timeout
	is_attacking = false

func _update_player_state() -> void:
	var prev_state = current_state
	
	if current_health <= 0:
		current_state = PlayerState.DEAD
	elif is_attacking:
		current_state = PlayerState.ATTACKING
	elif is_aiming:
		current_state = PlayerState.AIMING
	elif is_crouching:
		current_state = PlayerState.CROUCHING
	elif is_jumping:
		current_state = PlayerState.JUMPING
	elif is_sprinting:
		current_state = PlayerState.SPRINTING
	else:
		var input_x: float = Input.get_axis("move_left", "move_right")
		var input_z: float = Input.get_axis("move_forward", "move_back")
		if abs(input_x) > 0.1 or abs(input_z) > 0.1:
			current_state = PlayerState.MOVING
		else:
			current_state = PlayerState.IDLE
	
	if prev_state != current_state:
		state_changed.emit(_get_state_name(current_state))

func _get_state_name(state: PlayerState) -> String:
	match state:
		PlayerState.IDLE: return "idle"
		PlayerState.MOVING: return "moving"
		PlayerState.SPRINTING: return "sprinting"
		PlayerState.CROUCHING: return "crouching"
		PlayerState.JUMPING: return "jumping"
		PlayerState.ATTACKING: return "attacking"
		PlayerState.AIMING: return "aiming"
		PlayerState.DEAD: return "dead"
		_: return "unknown"

func take_damage(amount: float) -> void:
	if is_invulnerable or current_health <= 0:
		return
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	if current_health <= 0:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die() -> void:
	current_state = PlayerState.DEAD
	died.emit()
	is_input_enabled = false
	print("Player died!")

func respawn(spawn_position: Vector3) -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	global_position = spawn_position
	is_input_enabled = true
	current_state = PlayerState.IDLE
	respawned.emit()
	print("Player respawned!")

func get_active_camera() -> Camera3D:
	return fps_camera if is_first_person else tps_camera

func is_alive() -> bool:
	return current_health > 0

func get_health_percentage() -> float:
	return current_health / max_health

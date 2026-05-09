extends Node
class_name CameraManager

# Camera switching
@export var transition_duration: float = 0.5
@export var third_person_distance: float = 4.0
@export var third_person_height: float = 1.5
@export var zoom_speed: float = 2.0
@export var min_distance: float = 2.0
@export var max_distance: float = 8.0
# Advanced
@export var lock_on_distance: float = 10.0
@export var cinematic_rotation_speed: float = 0.2
@export var dynamic_fov_speed_factor: float = 0.1
@export var base_fov: float = 75.0

@onready var player: CharacterBody3D = get_parent()
@onready var first_person_camera: Camera3D = player.get_node("FirstPersonCamera")
@onready var third_person_pivot: Node3D = player.get_node("ThirdPersonPivot")
@onready var third_person_camera: Camera3D = third_person_pivot.get_node("ThirdPersonCamera")

enum CameraMode {FIRST_PERSON, THIRD_PERSON}
var current_mode: CameraMode = CameraMode.FIRST_PERSON
var transitioning: bool = false
var transition_timer: float = 0.0
var start_transform: Transform3D
var target_transform: Transform3D
# Advanced
var lock_target: Node3D = null
var cinematic_timer: float = 0.0
var idle_threshold: float = 5.0

func _ready() -> void:
	# Set initial camera
	first_person_camera.make_current()
	third_person_distance = third_person_camera.position.z  # Assume initial

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("SwitchCamera") and not transitioning:
		switch_camera()
	
	# Zoom for third-person
	if current_mode == CameraMode.THIRD_PERSON and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			third_person_distance = max(min_distance, third_person_distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			third_person_distance = min(max_distance, third_person_distance + zoom_speed)
		update_third_person_position()
	
	# Lock-on
	if event.is_action_pressed("lock_on"):
		toggle_lock_on()

func switch_camera() -> void:
	transitioning = true
	transition_timer = 0.0
	start_transform = get_current_camera_transform()
	
	if current_mode == CameraMode.FIRST_PERSON:
		current_mode = CameraMode.THIRD_PERSON
		target_transform = get_third_person_transform()
	else:
		current_mode = CameraMode.FIRST_PERSON
		target_transform = get_first_person_transform()

func toggle_lock_on():
	if lock_target:
		lock_target = null
	else:
		var targets = get_tree().get_nodes_in_group("enemies")
		var closest: Node3D = null
		var min_dist = lock_on_distance
		for target in targets:
			var dist = player.global_position.distance_to(target.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = target
		lock_target = closest

func _process(delta: float) -> void:
	if transitioning:
		transition_timer += delta
		var t = clamp(transition_timer / transition_duration, 0.0, 1.0)
		t = smoothstep(0.0, 1.0, t)  # Smooth easing
		
		var current_camera = get_current_camera()
		current_camera.global_transform = start_transform.interpolate_with(target_transform, t)
		
		if t >= 1.0:
			transitioning = false
			current_camera.make_current()
			if current_mode == CameraMode.THIRD_PERSON:
				update_third_person_position()
	
	# Lock-on camera adjustment
	if lock_target and is_instance_valid(lock_target) and current_mode == CameraMode.THIRD_PERSON:
		var target_pos = lock_target.global_position + Vector3(0, 1, 0)
		var camera_pos = third_person_camera.global_position
		var direction = (target_pos - camera_pos).normalized()
		var target_basis = Basis.looking_at(direction, Vector3.UP)
		third_person_pivot.global_transform.basis = third_person_pivot.global_transform.basis.slerp(target_basis, 5.0 * delta)
	
	# Cinematic rotation when idle
	if player.velocity.length() < 0.1 and current_mode == CameraMode.THIRD_PERSON and not lock_target:
		cinematic_timer += delta
		if cinematic_timer > idle_threshold:
			third_person_pivot.rotate_y(cinematic_rotation_speed * delta)
	else:
		cinematic_timer = 0.0
	
	# Dynamic FOV based on speed
	var speed_factor = player.velocity.length() / 4.8  # Assuming SPEED
	var target_fov = base_fov + (speed_factor * dynamic_fov_speed_factor * 20.0)
	get_current_camera().fov = lerp(get_current_camera().fov, target_fov, 5.0 * delta)

func get_current_camera() -> Camera3D:
	return first_person_camera if current_mode == CameraMode.FIRST_PERSON else third_person_camera

func get_current_camera_transform() -> Transform3D:
	return get_current_camera().global_transform

func get_first_person_transform() -> Transform3D:
	return first_person_camera.global_transform

func get_third_person_transform() -> Transform3D:
	var transform = third_person_pivot.global_transform
	transform.origin = player.global_transform.origin + Vector3(0, third_person_height, third_person_distance)
	return transform

func update_third_person_position() -> void:
	if current_mode == CameraMode.THIRD_PERSON and not transitioning:
		# Collision handling: raycast from player to desired camera position
		var space_state = player.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = player.global_position + Vector3(0, third_person_height, 0)
		query.to = player.global_position + Vector3(0, third_person_height, third_person_distance)
		query.exclude = [player.get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			third_person_camera.position.z = (result.position - player.global_position).length() - 0.5  # Slight offset
		else:
			third_person_camera.position.z = third_person_distance

# Smoothstep function for easing
func smoothstep(edge0: float, edge1: float, x: float) -> float:
	x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
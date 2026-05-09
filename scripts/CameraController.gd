extends Node3D
class_name CameraController

# Lock-on system
@onready var player: ThirdPersonController = get_parent()
var lock_target: Node3D = null
var lock_distance: float = 10.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lock_on"):
		toggle_lock_on()

func toggle_lock_on() -> void:
	if lock_target:
		lock_target = null
	else:
		# Find nearest target (placeholder - replace with actual enemy detection)
		var targets = get_tree().get_nodes_in_group("enemies")
		var closest: Node3D = null
		var min_dist = lock_distance
		for target in targets:
			var dist = player.global_position.distance_to(target.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = target
		lock_target = closest

func _process(delta: float) -> void:
	if lock_target and is_instance_valid(lock_target):
		# Smooth camera to look at target
		var target_pos = lock_target.global_position + Vector3(0, 1, 0)  # Aim at center
		var camera_pos = global_position
		var direction = (target_pos - camera_pos).normalized()
		var target_rotation = Basis.looking_at(direction, Vector3.UP)
		global_transform.basis = global_transform.basis.slerp(target_rotation, 5.0 * delta)
	else:
		# Normal orbit (handled in player script)
		pass
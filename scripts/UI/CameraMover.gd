extends Camera3D

@export var orbit_speed = 0.5
@export var orbit_radius = 10.0
@export var orbit_height = 2.0
@export var look_at_point = Vector3(0, 1, -5)

var angle = 0.0

func _ready():
	# Initial position
	transform.origin = look_at_point + Vector3(orbit_radius, orbit_height, 0)
	look_at(look_at_point)

func _process(delta):
	angle += delta * orbit_speed
	var offset = Vector3(cos(angle) * orbit_radius, orbit_height, sin(angle) * orbit_radius)
	transform.origin = look_at_point + offset
	look_at(look_at_point)

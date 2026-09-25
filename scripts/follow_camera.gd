extends Camera3D

@export var target: Node3D
@export var distance: float = 6.2
@export var height: float = 2.4
@export var follow_speed: float = 12.0
@export var look_speed: float = 10.0

func _ready() -> void:
	if target:
		var target_fwd: Vector3 = -target.global_transform.basis.z
		global_position = target.global_position - target_fwd * distance + Vector3.UP * height
		look_at(target.global_position + Vector3.UP * 0.8, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return

	var target_fwd: Vector3 = -target.global_transform.basis.z
	var desired_pos: Vector3 = target.global_position - target_fwd * distance + Vector3.UP * height
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	var look_target: Vector3 = target.global_position + Vector3.UP * 0.8
	var cur_basis: Basis = global_transform.basis
	var target_basis: Basis = Basis.looking_at(look_target - global_position, Vector3.UP)
	global_transform.basis = cur_basis.slerp(target_basis, look_speed * delta).orthonormalized()

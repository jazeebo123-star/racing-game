extends CharacterBody3D

# Arcade Drift Car Controller (Low-Poly Initial D / Inertial Drift Style)

@export var max_speed: float = 34.0
@export var reverse_speed: float = 14.0
@export var acceleration: float = 24.0
@export var braking_force: float = 32.0
@export var grip_friction: float = 8.0
@export var drift_friction: float = 3.0
@export var base_steer_speed: float = 2.4
@export var drift_steer_speed: float = 3.6
@export var gravity: float = 24.0

# Current physics state
var current_speed: float = 0.0
var visual_steer: float = 0.0
var slide_velocity: Vector3 = Vector3.ZERO

# Drift state
var is_drifting: bool = false
var drift_direction: float = 0.0 # -1 = drifting left, +1 = drifting right
var drift_angle: float = 0.0 # visual & physical yaw offset in radians
var drift_time: float = 0.0

# Visual & Particle nodes
@onready var wheel_fl: Node3D = get_node_or_null("Visuals/WheelFL")
@onready var wheel_fr: Node3D = get_node_or_null("Visuals/WheelFR")
@onready var wheel_rl: Node3D = get_node_or_null("Visuals/WheelRL")
@onready var wheel_rr: Node3D = get_node_or_null("Visuals/WheelRR")
@onready var chassis: Node3D = get_node_or_null("Visuals/Chassis")
@onready var smoke_left: CPUParticles3D = get_node_or_null("Visuals/SmokeLeft")
@onready var smoke_right: CPUParticles3D = get_node_or_null("Visuals/SmokeRight")

var start_transform: Transform3D

func _ready() -> void:
	start_transform = global_transform
	_set_smoke_emitting(false)

func _physics_process(delta: float) -> void:
	# Quick reset key
	if Input.is_key_pressed(KEY_R):
		global_transform = start_transform
		current_speed = 0.0
		velocity = Vector3.ZERO
		slide_velocity = Vector3.ZERO
		is_drifting = false
		drift_angle = 0.0
		_set_smoke_emitting(false)
		return

	# 1. Inputs
	var throttle: float = 0.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		throttle += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		throttle -= 1.0

	var steer_input: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_input += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_input -= 1.0

	var drift_button: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT)

	# 2. Acceleration / Deceleration
	var active_friction = drift_friction if is_drifting else grip_friction
	if throttle > 0.0:
		if current_speed >= 0.0:
			current_speed = move_toward(current_speed, max_speed, acceleration * delta)
		else:
			current_speed = move_toward(current_speed, 0.0, braking_force * delta)
	elif throttle < 0.0:
		if current_speed > 0.0:
			current_speed = move_toward(current_speed, 0.0, braking_force * delta)
		else:
			current_speed = move_toward(current_speed, -reverse_speed, acceleration * 0.9 * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, active_friction * delta)

	# 3. Drift Entry & Handling
	if is_on_floor() and current_speed > 10.0:
		if drift_button and abs(steer_input) > 0.1 and not is_drifting:
			# Enter drift
			is_drifting = true
			drift_direction = sign(steer_input)
			drift_time = 0.0
		elif not drift_button and is_drifting:
			# Exit drift -> small boost if held long enough
			if drift_time > 0.8:
				current_speed = min(current_speed + 4.5, max_speed * 1.15)
			is_drifting = false
	else:
		if is_drifting and current_speed < 6.0:
			is_drifting = false

	# 4. Steering & Slide Mechanics
	var steer_rate = drift_steer_speed if is_drifting else base_steer_speed
	var speed_ratio = clamp(abs(current_speed) / max_speed, 0.25, 1.0)

	if abs(current_speed) > 0.4:
		var dir_factor = 1.0 if current_speed >= 0.0 else -1.0
		if is_drifting:
			# While drifting: turn into drift direction, counter-steer modulates the slide
			drift_time += delta
			var drift_turn = drift_direction * 1.5 + steer_input * 0.8
			rotation.y += drift_turn * steer_rate * delta
			# Angle chassis visually into the slide
			var target_drift_angle = -drift_direction * deg_to_rad(32.0)
			drift_angle = lerp(drift_angle, target_drift_angle, 8.0 * delta)
		else:
			rotation.y += steer_input * steer_rate * dir_factor * speed_ratio * delta
			drift_angle = lerp(drift_angle, 0.0, 12.0 * delta)

	# 5. Velocity Calculation
	var forward: Vector3 = -transform.basis.z
	var right: Vector3 = transform.basis.x

	var forward_velocity = forward * current_speed

	if is_drifting:
		# Apply lateral sliding momentum
		var slide_force = right * (drift_direction * current_speed * 0.45)
		slide_velocity = slide_velocity.lerp(slide_force, 6.0 * delta)
	else:
		slide_velocity = slide_velocity.lerp(Vector3.ZERO, 10.0 * delta)

	velocity.x = forward_velocity.x + slide_velocity.x
	velocity.z = forward_velocity.z + slide_velocity.z

	if is_on_floor():
		velocity.y = -1.2
	else:
		velocity.y -= gravity * delta

	move_and_slide()

	# 6. Visual Updates (Wheel Steer, Body Roll, Smoke)
	visual_steer = lerp(visual_steer, steer_input * deg_to_rad(28.0), 16.0 * delta)
	if wheel_fl:
		wheel_fl.rotation.y = visual_steer
	if wheel_fr:
		wheel_fr.rotation.y = visual_steer

	var wheel_spin = (current_speed / 0.3) * delta
	for wheel in [wheel_fl, wheel_fr, wheel_rl, wheel_rr]:
		if wheel:
			var spin_pivot = wheel.get_node_or_null("Spin")
			if spin_pivot:
				spin_pivot.rotation.x += wheel_spin

	# Body roll and drift angle
	if chassis:
		var roll = -steer_input * deg_to_rad(5.0) if not is_drifting else -drift_direction * deg_to_rad(6.5)
		chassis.rotation.z = lerp(chassis.rotation.z, roll, 12.0 * delta)
		chassis.rotation.y = drift_angle

	# Smoke emission
	_set_smoke_emitting(is_drifting and is_on_floor() and current_speed > 8.0)

func _set_smoke_emitting(emitting: bool) -> void:
	if smoke_left:
		smoke_left.emitting = emitting
	if smoke_right:
		smoke_right.emitting = emitting

extends CanvasLayer

# Retro Arcade Drift HUD matching reference image

@export var car: CharacterBody3D
@export var track_node: Node3D

# Lap Timing State
var current_lap: int = 1
var current_lap_time: float = 0.0
var last_lap_time: float = 0.0
var best_lap_time: float = 0.0

var passed_midpoint: bool = false
var last_car_z: float = 0.0

# UI Labels
@onready var lap_label: Label = $TopBar/LapLabel
@onready var last_lap_label: Label = $TopBar/LastLapLabel
@onready var current_lap_label: Label = $TopBar/CurrentLapLabel
@onready var best_lap_label: Label = $TopBar/BestLapLabel
@onready var speed_label: Label = $BottomRight/SpeedLabel
@onready var drift_banner: Label = $DriftBanner

func _ready() -> void:
	if car:
		last_car_z = car.global_position.z

func _process(delta: float) -> void:
	current_lap_time += delta
	_update_lap_detection()
	_update_ui()

func _update_lap_detection() -> void:
	if not car or not is_instance_valid(car):
		return

	var pos = car.global_position

	# Checkpoint midpoint: car reaches far side of circuit (e.g. X > 100 or Z < -40)
	if pos.x > 80.0 or pos.z < -40.0:
		passed_midpoint = true

	# Cross finish line at X ~= 0, passing Z = 0 from negative to positive
	if passed_midpoint and abs(pos.x) < 14.0:
		if last_car_z < 0.0 and pos.z >= 0.0:
			_complete_lap()

	last_car_z = pos.z

func _complete_lap() -> void:
	passed_midpoint = false
	current_lap += 1
	last_lap_time = current_lap_time

	if best_lap_time == 0.0 or last_lap_time < best_lap_time:
		best_lap_time = last_lap_time

	current_lap_time = 0.0

func _update_ui() -> void:
	# Top bar labels (bold red italic style matching reference)
	lap_label.text = "LAP: %d" % current_lap
	current_lap_label.text = "CURRENT LAP: %s" % _format_time(current_lap_time)

	if last_lap_time > 0.0:
		last_lap_label.text = "LAST LAP: %s" % _format_time(last_lap_time)
	else:
		last_lap_label.text = "LAST LAP: --:--.---"

	if best_lap_time > 0.0:
		best_lap_label.text = "BEST LAP: %s" % _format_time(best_lap_time)
	else:
		best_lap_label.text = "BEST LAP: --:--.---"

	# Speed readout
	if car and is_instance_valid(car):
		var kmh = int(clamp(car.current_speed * 3.6, -100.0, 300.0))
		speed_label.text = "%d KM/H" % abs(kmh)
		if car.is_drifting:
			drift_banner.visible = true
			drift_banner.text = "DRIFT!"
		else:
			drift_banner.visible = false

func _format_time(t: float) -> String:
	var mins = int(t / 60.0)
	var secs = int(fmod(t, 60.0))
	var millis = int(fmod(t * 1000.0, 1000.0))
	return "%d:%02d.%03d" % [mins, secs, millis]

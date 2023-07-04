@tool
@icon("dynamics.svg")
class_name SecondOrderDynamics extends Resource

## Implements second-order dynamics in GDScript
##
## An implementation of second-order dynamics in GDScript for procedural animation.

enum Preset {
	NONE, ## No preset
	SMOOTH, ## Motion will be smooth, with no vibration
	OVERSHOOT, ## Motion will vibrate at the end
	ANTICIPATE, ## Motion will start slowly, vibrating at the beginning
	ROBOTIC,
}

## If selected, changes [member frequency], [member damping], and [member initial_response]
## to create the effect described by the preset.
## [br][b]Note:[/b] only works in-editor.
@export var preset: Preset = Preset.NONE:
	set(value):
		preset = value
		match preset:
			Preset.SMOOTH:
				frequency = 1.0
				damping = 1.0
				initial_response = 0.5
			Preset.OVERSHOOT:
				initial_response = 1.0
				damping = 0.5
				frequency = 3.0
			Preset.ANTICIPATE:
				initial_response = -0.75
				damping = 0.5
				frequency = 3.0
			Preset.ROBOTIC:
				initial_response = -1.0
				damping = 0.5
				frequency = 7.0


## Describes the speed in which the system will respond to changes in the input.
## This is also the speed of vibrations.
@export var frequency: float = 1.0:
	set(value):
		if is_zero_approx(frequency): frequency = 0.01
		else: frequency = value
		compute_constants()

## Describes how the system will come to settle at the _target.
## When [code]0[/code], vibration never dies down.
## When [code]>=1[/code], the system will never vibrate.
@export_range(0.0, 1.0) var damping: float = 1.0:
	set(value):
		damping = value
		compute_constants()

## Describes how the system reacts to a change in _target.
## When [code]<0[/code], the system will anticipate the motion.
## When [code]0[/code], the system will take time to begin accelerating towards the _target.
## When between [code]0[/code] and [code]1[/code], the system will immediately react.
## When [code]>1[/code], the system will overshoot the response.
@export var initial_response: float = 0:
	set(value):
		initial_response = value
		compute_constants()

## If [code]true[/code], enables the use of pole matching which helps with accuracy
## if the motion is super fast. This comes with a very minor performance hit from the
## extra calculations.
@export var enable_pole_matching: bool = false

## Dynamics constant 1, calculated by:
## [br][code]damping / (PI * frequency)[/code]
var k1: float = 0

## Dynamic constant 2, calculated by:
## [br][code]1 / ((2 * PI * frequency) * (2 * PI * frequency))[/code]
var k2: float = 0

## Dynamic constant 3, calculated by:
## [br][code]initial_response * damping / (2 * PI * frequency)[/code]
var k3: float = 0

var _w: float
var _z: float
var _d: float

## Can be [float], [Vector2], [Vector3], [Vector4]
var _target

## Can be [float], [Vector2], [Vector3], [Vector4]
var prev_target

## Can be [float], [Vector2], [Vector3], [Vector4]
var start_position

## Can be [float], [Vector2], [Vector3], [Vector4]
var position

## Can be [float], [Vector2], [Vector3], [Vector4]
var velocity


func _init() -> void:
	compute_constants()


## Computes [member k1], [member k2], and [member k3], and updates [member prev_target] and [member position]
func compute_constants() -> void:
	if enable_pole_matching:
		_w = 2 * PI * frequency
		_z = damping
		_d = _w * sqrt(abs(damping * damping - 1.0))
	
	k1 = damping / (PI * frequency)
	k2 = 1 / ((2 * PI * frequency) * (2 * PI * frequency))
	k3 = initial_response * damping / (2 * PI * frequency)
	_target = start_position
	prev_target = start_position
	position = start_position


## Updates the position and velocity based on the [member _target] position.
## [br]• [b]delta[/b] ([float]) - the time since the last frame (see [method Node._physics_process])
func update(delta: float):
	
	# make sure all state variables are set
	if prev_target == null or position == null: compute_constants()

	# estimate velocity
	var target_time_derivative = (_target - prev_target) / delta
	prev_target = _target
	
	var k1_stable: float = k1
	var k2_stable: float = k2
	
	if enable_pole_matching and not (_w * delta < _z):
		var t1: float = exp(-_z * _w * delta)
		var alpha: float = 2 * t1 * (cos(delta * _d) if _z <= 1 else cosh(delta * _d))
		var beta: float = t1 * t1
		var t2: float = delta / (1.0 + beta - alpha)
		k1_stable = (1 - beta) * t2
		k2_stable = delta * t2
	else:
		# clamp k2 to guarantee stability without jitter
		k2_stable = maxf(
			maxf(k2, delta * delta / 2 + delta * k1 / 2), 
			delta * k1
		)

	# integrate position by velocity
	position = position + delta * velocity

	# integrate velocity by acceleration
	velocity = velocity + delta * (_target + k3 * target_time_derivative - position - k1_stable * velocity) / k2_stable

	return position


## Sets the target position to the given value.
## [code]value[/code] can be [float], [Vector2], [Vector3], or [Vector4]
func set_target(value) -> void:
	_target = value

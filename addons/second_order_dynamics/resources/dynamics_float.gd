@tool
class_name SecondOrderDynamicsFloat extends SecondOrderDynamics

## If [code]true[/code], the system will smoothly wrap the angle
@export var is_angle: bool = false


func _init() -> void:
	_target = 0.0
	position = 0.0
	velocity = 0.0
	super._init()


## Updates the position and velocity based on the input target position.
## [br]• [b]delta[/b] ([float]) - the time since the last frame (see [method Node._physics_process])
func update(delta: float) -> float:
	return super.update(delta)


## Sets the target position to the given value.
func set_target(value: float) -> void:
	if is_angle: super.set_target(lerp_angle(_target, value, 1))
	else: super.set_target(value)

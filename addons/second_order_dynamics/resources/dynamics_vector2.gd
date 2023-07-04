@tool
class_name SecondOrderDynamicsVector2 extends SecondOrderDynamics

## If [code]true[/code], the system will smoothly wrap the angle
@export var is_angle: bool = false


func _init() -> void:
	_target = Vector2.ZERO
	position = Vector2.ZERO
	velocity = Vector2.ZERO
	super._init()


## Updates the position and velocity based on the input target position.
## [br]• [b]delta[/b] ([float]) - the time since the last frame (see [method Node._physics_process])
func update(delta: float) -> Vector2:
	return super.update(delta)


## Sets the target position to the given value.
func set_target(value: Vector2) -> void:
	if is_angle: super.set_target(Vector2(
		lerp_angle(_target.x, value.x, 1.0),
		lerp_angle(_target.y, value.y, 1.0),
	))
	else: super.set_target(value)

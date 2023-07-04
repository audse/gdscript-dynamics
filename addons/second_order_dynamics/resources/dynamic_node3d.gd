class_name DynamicNode3D extends Node3D

@export var dynamics: SecondOrderDynamics


func _enter_tree() -> void:
	if dynamics: 
		dynamics.start_position = 0.0
		dynamics.velocity = 0.0


func _physics_process(delta: float) -> void:
	if dynamics: rotation.y = dynamics.update(delta)


func set_target(value: float) -> void:
	dynamics.set_target(value)

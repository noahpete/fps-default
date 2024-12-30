class_name CameraController
extends Node3D


@export var look_sensitivity: float = 0.006
@export var headbob_amplitude: float = 0.06
@export var headbob_frequency: float = 2.4

var headbob_time: float = 0.0

## Handle mouse movement input and camera movement.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			$"..".rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))


## Add headbob to the camera.
func headbob_effect(delta: float) -> void:
	headbob_time += delta * $"..".velocity.length()
	%Camera3D.transform.origin = Vector3(cos(headbob_time * headbob_frequency * 0.5) * headbob_amplitude, sin(headbob_time * headbob_frequency) * headbob_amplitude, 0)

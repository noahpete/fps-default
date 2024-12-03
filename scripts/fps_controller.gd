extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var SPEED_DEFAULT: float = 5.0
@export var SPEED_CROUCH: float = 2.0
@export_range(5, 10, 0.1) var CROUCH_SPEED: float = 7.0
@export var TOGGLE_CROUCH: bool = true
@export var MOUSE_SENSITIVITY: float = 0.5
@export var TILT_LOWER_LIMIT := deg_to_rad(-90.0)
@export var TILT_UPPER_LIMIT := deg_to_rad(90.0)
@export var CAMERA_CONTROLLER: Camera3D
@export var ANIMATIONPLAYER: AnimationPlayer
@export var CROUCH_SHAPECAST: Node3D

var _speed: float
var _mouse_input: bool = false
var _mouse_rotation: Vector3
var _rotation_input: float
var _tilt_input: float
var _player_rotation: Vector3
var _camera_rotation: Vector3

var _is_crouching: bool = false

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("crouch") and is_on_floor() and TOGGLE_CROUCH:
		toggle_crouch()
	if event.is_action_pressed("crouch") and !_is_crouching and is_on_floor() and !TOGGLE_CROUCH:
		crouching(true)
	if event.is_action_released("crouch") and !TOGGLE_CROUCH:
		if CROUCH_SHAPECAST.is_colliding():
			uncrouch_check()
		else:
			crouching(false)
		
func _unhandled_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * MOUSE_SENSITIVITY
		_tilt_input = -event.relative.y * MOUSE_SENSITIVITY
		print(Vector2(_rotation_input, _tilt_input))
		
func _update_camera(delta):
	_mouse_rotation.x += _tilt_input * delta
	_mouse_rotation.x = clamp(_mouse_rotation.x, TILT_LOWER_LIMIT, TILT_UPPER_LIMIT)
	_mouse_rotation.y += _rotation_input * delta
	
	_player_rotation = Vector3(0.0, _mouse_rotation.y, 0.0)
	_camera_rotation = Vector3(_mouse_rotation.x, 0.0, 0.0)
	
	CAMERA_CONTROLLER.transform.basis = Basis.from_euler(_camera_rotation)
	CAMERA_CONTROLLER.rotation.z = 0.0
	
	global_transform.basis = Basis.from_euler(_player_rotation)
	
	_rotation_input = 0.0
	_tilt_input = 0.0
		
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_speed = SPEED_DEFAULT
	CROUCH_SHAPECAST.add_exception($".")	

func _physics_process(delta: float) -> void:
	# Example debug property
	Global.debug.add_property("MovementSpeed", _speed, 1)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	_update_camera(delta)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and !_is_crouching:
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		velocity.x = move_toward(velocity.x, 0, _speed)
		velocity.z = move_toward(velocity.z, 0, _speed)

	move_and_slide()
	
func toggle_crouch():
	if _is_crouching and !CROUCH_SHAPECAST.is_colliding():
		crouching(false)
	else:
		crouching(true)

func uncrouch_check():
	if CROUCH_SHAPECAST.is_colliding():
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()
	else:
		crouching(false)

func crouching(state: bool) -> void:
	if state:
		ANIMATIONPLAYER.play("Crouch", 0, CROUCH_SPEED)
		set_movement_speed("crouching")
	else:
		ANIMATIONPLAYER.play("Crouch", 0, -CROUCH_SPEED, true)
		set_movement_speed("default")

func _on_animation_player_animation_started(anim_name: StringName) -> void:
	if anim_name == "Crouch":
		_is_crouching = !_is_crouching

func set_movement_speed(state: String):
	match state:
		"default":
			_speed = SPEED_DEFAULT
		"crouching":
			_speed = SPEED_CROUCH

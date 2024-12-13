extends CharacterBody3D

@export var look_sensitivity : float = 0.006

# Ground movement settings
@export var walk_speed := 7.0
@export var sprint_speed := 8.5
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

# Air movement settings
@export var jump_velocity := 6.0
@export var auto_bhop := true
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0

const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

var wish_dir := Vector3.ZERO
var cam_aligned_wish_dir := Vector3.ZERO

var noclip_speed_mult := 3.0
var noclip := false

func _ready() -> void:
	for child in %WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	cam_aligned_wish_dir = %Camera3D.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	if not handle_noclip(delta):
		if is_on_floor():
			if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
				self.velocity.y = jump_velocity
			handle_ground_physics(delta)
		else:
			handle_air_physics(delta)
		move_and_slide()
		
func handle_noclip(delta: float) -> bool:
	if Input.is_action_just_pressed("noclip") and OS.has_feature("debug"):
		noclip = !noclip
		
	$CollisionShape3D.disabled = noclip
	
	if not noclip:
		return false
	
	var speed = get_move_speed() * noclip_speed_mult
	if Input.is_action_pressed("sprint"):
		speed *= 3.0
	
	self.velocity = cam_aligned_wish_dir * speed
	global_position += self.velocity * delta
	
	return true

func handle_ground_physics(delta: float) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_til_cap = get_move_speed() - cur_speed_in_wish_dir
	if add_speed_til_cap > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, add_speed_til_cap)
		self.velocity += accel_speed * wish_dir
	
	# Apply friction
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
		
	headbob_effect(delta)
	
func handle_air_physics(delta: float) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	# Classic source/quake air movement
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_til_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_til_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_til_cap)
		self.velocity += accel_speed * wish_dir
	

func get_move_speed() -> float:
	return sprint_speed if Input.is_action_just_pressed("sprint") else walk_speed

func headbob_effect(delta: float) -> void:
	headbob_time += delta * self.velocity.length()
	%Camera3D.transform.origin = Vector3(cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT, sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT, 0)

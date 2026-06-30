extends CharacterBody3D

@export var speed := 2.0
@export var jumpForce := 4.5
@export var fly_speed := 10.0
@export var mouse_sensitivity := 0.001

var camera: Camera3D
var noclip := false

func _ready():
	camera = $Camera3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# Toggle noclip with G
		if event.keycode == KEY_N:
			noclip = !noclip
			print("Noclip:", noclip)

	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if noclip:
		_process_noclip(delta)
	else:
		_process_normal(delta)

	move_and_slide()

func _process_normal(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jumpForce

	# Movement input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var forward = -global_transform.basis.z
	var right = -global_transform.basis.x
	var direction = (forward * input_dir.y + right * input_dir.x).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func _process_noclip(delta):
	# No gravity, no collision restrictions
	velocity = Vector3.ZERO

	# Movement input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var forward = -global_transform.basis.z
	var right = -global_transform.basis.x
	var direction = (forward * input_dir.y + right * input_dir.x).normalized()

	# Horizontal flight
	if direction != Vector3.ZERO:
		velocity.x = direction.x * fly_speed
		velocity.z = direction.z * fly_speed

	# Vertical flight (Space = up, Shift = down)
	if Input.is_action_pressed("ui_accept"): # Space
		velocity.y = fly_speed
	elif Input.is_action_pressed("sprint"):
		velocity.y = -fly_speed

extends CharacterBody3D


const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 6
const SENSITIVITY = 0.003
const CONTROLLER_SENS = 2
const FOV = 75
const FOV_CHANGE = 4.0
const HEAD_STAGGER = 1.5

var gravity = 14
var speed
var health = 5

var bullet = load("res://scenes/bullet.tscn")
var instance

@onready var head = $Head
@onready var camera = $Head/Camera
@onready var gun_anim = $Head/Camera/Gun/AnimationPlayer
@onready var gun_barrel = $Head/Camera/Gun/RayCast3D


signal player_hit

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	
	apply_controller_rotation()
	
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))
		
	if event.is_action_pressed("click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if event.is_action_pressed("escape"):
		get_tree().quit()

func _physics_process(delta):
	
	if health < 1:
		world.score = 0
		get_tree().reload_current_scene()
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
		var current_fov = FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, current_fov, delta * 8.0)
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)

	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
		var current_fov = FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, current_fov, delta * 8.0)

	move_and_slide()
	
	if Input.is_action_pressed("shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("shoot")
			instance = bullet.instantiate()
			instance.position = gun_barrel.global_position
			instance.transform.basis = gun_barrel.global_transform.basis
			get_parent().add_child(instance)
			
func hit(dir):
	emit_signal("player_hit")
	velocity += dir * HEAD_STAGGER
	health -= 1
	
func apply_controller_rotation():
	var axis_vector = Vector3.ZERO
	axis_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	axis_vector.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	if InputEventJoypadMotion:
		head.rotate_y(deg_to_rad(-axis_vector.x) * CONTROLLER_SENS)
		camera.rotate_x(deg_to_rad(-axis_vector.y) * CONTROLLER_SENS)
	
	


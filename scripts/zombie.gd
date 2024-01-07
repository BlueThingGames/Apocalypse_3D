extends CharacterBody3D

const SPEED = 4.0
const ATTACK_RANGE = 2.0

var player = null
var state_machine
var health = 6

@export var player_path := "/root/World/Map/NavigationRegion3D/Player"

@onready var navigation_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree

func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	
func _process(delta):
	velocity = Vector3.ZERO
	
	match state_machine.get_current_node():
		"walk":
			navigation_agent.set_target_position(player.global_transform.origin)
			var next_navigation_point = navigation_agent.get_next_path_position()
			velocity = (next_navigation_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10)
		"attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
#	if !is_on_floor():
#		while !is_on_floor():
#			global_position.y -= 1
	
	
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	anim_tree.get("parameters/playback")
	
	move_and_slide()
	
func _target_in_range():
	if anim_tree.get("parameters/conditions/attack"):
		return global_position.distance_to(player.global_position) < 2 * ATTACK_RANGE
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
	
	


func _on_area_3d_body_part_hit(dam):
	health -= dam
	if health <= 0:
		world.score += 1
		queue_free()

extends Node2D

export var accel = 500
export var lifeTime = 10
export var startingSpeed = 200
export var lateralDrag = 10

var velocity = Vector2()
var facingAngle = 0
var flightTimer = 0

onready var sprite = get_node("sprite")
onready var particles = get_node("particles")
onready var sounds = get_node("sounds")

func _ready():
	sounds.play("rocket_launch")
	sounds.voice_set_pitch_scale(0, 2)
	sounds.play("boost_loop")
	velocity += get_forward_direction() * startingSpeed
	set_process(true)

func _process(delta):
	flightTimer += delta
	if(flightTimer > lifeTime):
		queue_free()
	
	var forwardDirection = get_forward_direction()
	velocity += forwardDirection * accel * delta
	var right = get_right_direction()
	velocity -= velocity.dot(right) * right * lateralDrag * delta
	sprite.set_rot(facingAngle)
	particles.set_pos(forwardDirection * -15)
	set_pos(get_pos() + velocity * delta)

func get_forward_direction():
	return -Vector2(sin(facingAngle), cos(facingAngle))

func get_right_direction():
	var forward = get_forward_direction()
	return Vector2(-forward.y, forward.x)

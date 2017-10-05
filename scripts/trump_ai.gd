extends "res://scripts/car/car_base.gd"

const startingTaunts = [
	"Ah yeeaaah...\nracetime...fun.",
	"Woo im drunk :D",
	"*hic*",
	"zzzz.. oh uh, wha?",
]

const collisionTaunts = [
	"Watch it!",
	"Moron!",
	"Learn to drive!",
	"Ugh!"
]

const winTaunts = [
	"I'm drunk, you\ndon't have an excuse.",
	"Could do this in my... zzzz",
	"This calls for a drink!",
	"Whoo, ah... yeah... *hic*"
]

const loseTaunts = [
	"Oh I'm gonna need\na drink after this.",
	"Who was my dedicated\ndriver again?",
	"Ah, whatever.  ...zzzz",
	"Yeah, I did it! *hic*\nWait, no I didn't."
]

onready var playerCar = rootNode.get_node("player_car")


func _ready():
	set_process(true)

func _process(delta):
	#if(rootNode.raceState == rootNode.RACE_STATES.COUNTDOWN):
		#_taunt_random(startingTaunts, 4)
		
	if(rootNode.raceState == rootNode.RACE_STATES.WIN):
		_taunt_random(loseTaunts, 600)
	
	if(rootNode.raceState != rootNode.RACE_STATES.IN_PROGRESS):
		return
	
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	#steering
	#currentVertex = pathPoints[int(currentVertIndex)%pathPointCount]
	#currentVertex += get_tree().get_current_scene().get_node("track_loop").get_pos()
	
	#if(get_pos().distance_squared_to(currentVertex) < indexIncDistSq):
	#	currentVertIndex += 1
	
	var bearingToPlayer = get_forward_direction().angle_to(playerCar.get_global_pos() - get_global_pos())
	steerAngle = bearingToPlayer

	#steerAngle = clamp(steerAngle, -maxSteerAngle, maxSteerAngle)
	facingAngle += steerAngle * steerSpeed * delta
	spriteNode.set_rot(facingAngle)
	
	#particles.set_pos(forwardDirection * -15)

	#accel/reverse/brake
	#var myPathIndex = path.get_closest_point_on_track(get_global_pos())
	#var playerPathIndex = path.get_closest_point_on_track(playerCar.get_global_pos())
	#var balanceMultiplier = playerPathIndex - myPathIndex
	#balanceMultiplier = clamp(balanceMultiplier, -3, 10)
	#balanceMultiplier += 10
	#balanceMultiplier /= 10.0
	var currentMaxSpeed = maxForwardSpeed
	var currentAccelPower = accelPower
	if(forwardSpeed < currentMaxSpeed):
		velocity += forwardDirection * currentAccelPower * delta
	
	update()

func _handle_car_collision(otherCar):
	var diff = get_pos() - otherCar.get_pos()
	var collisionNormal = diff.normalized()
	var penetrationDepth = colliderRadius - diff.length()
	if(penetrationDepth > 0):
		_taunt_random(collisionTaunts, 2)


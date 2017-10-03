extends "res://scripts/car/car_base.gd"

const debug = true
const vertIndexInc = 0
const indexIncDistSq = 200 * 200
const pathVertInterval = 10

const startingTaunts = [
	"Ooh, racing is so stressful :(",
	"Please be careful...",
	"I don't like going fast...",
	"Oh no oh my oh dear...",
]

const collisionTaunts = [
	"Sorry!",
	"Excuse me!",
	"Whoa Nelly!",
	"Eee!"
]

const winTaunts = [
	"Did I do it?  I think I did it!",
	"Wow, what a rush!",
	"Yay!  Never doing that again!",
	"Maybe someone will\nsponsor me now!"
]

const loseTaunts = [
	"It's not about winning,\nit's about being scared.",
	"It's okay, at least\nwe're still alive.",
	"Oh well, practice\nmakes perfect.",
	"I'll get you next time,\nif that's alright."
]

var path
var currentVertIndex = 0.0
var pathPoints
var pathPointCount

onready var playerCar = rootNode.get_node("player_car")

func _ready():
	path = rootNode.get_node("track_loop")
	var pathCurve = path.get_curve()
	pathCurve.set_bake_interval(pathVertInterval)
	pathPoints = pathCurve.get_baked_points()
	pathPointCount = pathPoints.size()
	
	set_process(true)

var currentVertex
func _process(delta):
	if(rootNode.raceState == rootNode.RACE_STATES.COUNTDOWN):
		_taunt_random(startingTaunts, 4)
	
	if(rootNode.raceState == rootNode.RACE_STATES.WIN):
		_taunt_random(loseTaunts, 600)
	
	if(rootNode.raceState != rootNode.RACE_STATES.IN_PROGRESS):
		return
	
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	currentVertIndex += vertIndexInc * delta
	
	
	#steering
	currentVertex = pathPoints[int(currentVertIndex)%pathPointCount]
	currentVertex += rootNode.get_node("track_loop").get_pos()
	
	if(get_pos().distance_squared_to(currentVertex) < indexIncDistSq):
		currentVertIndex += 1
	
	var bearingToNext = get_forward_direction().angle_to(currentVertex - get_pos())
	steerAngle = bearingToNext

	steerAngle = clamp(steerAngle, -maxSteerAngle, maxSteerAngle)
	facingAngle += steerAngle * steerSpeed * delta
	spriteNode.set_rot(facingAngle)
	
	#particles.set_pos(forwardDirection * -15)

	#accel/reverse/brake
	var myPathIndex = path.get_closest_point_on_track(get_global_pos())
	var playerPathIndex = path.get_closest_point_on_track(playerCar.get_global_pos())
	var balanceMultiplier = playerPathIndex - myPathIndex
	balanceMultiplier = clamp(balanceMultiplier, -3, 10)
	balanceMultiplier += 10
	balanceMultiplier /= 10.0
	var currentMaxSpeed = maxForwardSpeed * (1.0 - min(1, abs(steerAngle)))
	currentMaxSpeed *= balanceMultiplier
	var currentAccelPower = accelPower * 2
	if(forwardSpeed < currentMaxSpeed):
		velocity += forwardDirection * currentAccelPower * delta
	
	update()
	
	if(lapsCompleted == 3):
		if(rootNode.raceState == rootNode.RACE_STATES.IN_PROGRESS):
			rootNode.set_race_state(rootNode.RACE_STATES.LOSE)
			_taunt_random(winTaunts, 600)

func _handle_car_collision(otherCar):
	var diff = get_pos() - otherCar.get_pos()
	var collisionNormal = diff.normalized()
	var penetrationDepth = colliderRadius - diff.length()
	if(penetrationDepth > 0):
		_taunt_random(collisionTaunts, 2)

func _draw():
	if(debug && currentVertex != null):
		draw_set_transform(-get_pos(), -get_rot(), Vector2(1, 1))
		draw_circle(currentVertex, 10, Color(1, 1, 1, 1))

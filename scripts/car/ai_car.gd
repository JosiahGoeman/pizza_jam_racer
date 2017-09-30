extends "res://scripts/car/car_base.gd"

const vertIndexInc = 25
const pathVertInterval = 10

var currentVertIndex = 0.0
var pathPoints
var pathPointCount

func _ready():
	var pathCurve = get_parent().get_parent().get_node("track_loop").get_curve()
	pathCurve.set_bake_interval(pathVertInterval)
	pathPoints = pathCurve.get_baked_points()
	pathPointCount = pathPoints.size()
	
	set_process(true)

var currentVertex
func _process(delta):
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	currentVertIndex += vertIndexInc * delta
	
	#steering
	currentVertex = pathPoints[int(currentVertIndex)%pathPointCount]
	currentVertex += get_parent().get_parent().get_node("track_loop").get_pos()
	var bearingToNext = get_forward_direction().angle_to(currentVertex - get_pos())
	steerAngle = bearingToNext
	print(bearingToNext)

	steerAngle = clamp(steerAngle, -maxSteerAngle * velocity.length() / 50, maxSteerAngle * velocity.length() / 50)
	facingAngle += steerAngle * delta
	spriteNode.set_rot(facingAngle)
	
	#particles.set_pos(forwardDirection * -15)

	#accel/reverse/brake
	var currentMaxSpeed = maxForwardSpeed
	var currentAccelPower = accelPower
	if(forwardSpeed < currentMaxSpeed):
		velocity += forwardDirection * currentAccelPower * delta
	
	update()

func _draw():
	if(currentVertex != null):
		draw_set_transform(-get_pos(), -get_rot(), Vector2(1, 1))
		draw_circle(currentVertex, 10, Color(1, 1, 1, 1))

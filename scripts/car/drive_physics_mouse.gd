extends Node2D

#constants
const maxForwardSpeed = 300
const maxBoostSpeed = 500
const maxReverseSpeed = 100
const accelPower = 500
const reversePower = 500
const brakePower = 500
const steerSpeed = 5			#how fast car's steering turns to face nub
const maxSteerAngle = 2.5		#how far the car can steer
const skidBeginForce = 25		#how much lateral force the car withstands before sliding
const skidGrip = 3				#how much the car resists lateral movement while sliding
const rollingFriction = 50		#how quickly the car slows down when not accelerating
const minSkidmarkSpeed = 150	#how fast the car needs to be sliding to leave skidmarks
const colliderRadius = 10
const offRoadSpeedReduction = 0.5

var velocity = Vector2()
var facingAngle = 0		#direction car is facing
var steerAngle = 0
var isOnRoad = false
var framePhase = 0.0
onready var spriteNode = get_node("sprites")				#reference to the sprite so we don't have to look it up every time
onready var leftFrontWheel = spriteNode.get_node("left_front_wheel")
onready var rightFrontWheel = spriteNode.get_node("right_front_wheel")
onready var tireMarks = get_parent().get_node("tire_marks")
onready var controlCircle = get_node("control_circle")
onready var wallCollider = get_node("wall_collider")
onready var roadChecker = get_node("road_checker")

func _ready():
	set_process(true)
	set_fixed_process(true)

#direction car is facing
func get_forward_direction():
	return -Vector2(sin(facingAngle), cos(facingAngle))

#direction to car's right
func get_right_direction():
	var forward = get_forward_direction()
	return Vector2(-forward.y, forward.x)
	
func _process(delta):
	#grab input
	var brake = Input.is_key_pressed(KEY_SHIFT)
	var boost = Input.is_key_pressed(KEY_SPACE)
	
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	#check if car is on track or not
	isOnRoad = false	#default to false
	var overlapped = roadChecker.get_overlapping_bodies()
	for i in range(0, overlapped.size()):
		if(overlapped[i].get_name().begins_with("road_")):
			isOnRoad = true
			break
	
	#mouse control
	if(Input.is_mouse_button_pressed(BUTTON_LEFT)):
		#steer
		var nub = controlCircle.get_nub_pos()
		steerAngle = forwardDirection.angle_to(nub) * steerSpeed
		steerAngle = clamp(steerAngle, -maxSteerAngle * velocity.length() / 50, maxSteerAngle * velocity.length() / 50)
		facingAngle += steerAngle * delta
		spriteNode.set_rot(facingAngle)
	
		#accel/reverse/brake
		var currentMaxSpeed = maxForwardSpeed
		if(boost):
			currentMaxSpeed = maxBoostSpeed
		if(!isOnRoad):
			currentMaxSpeed *= offRoadSpeedReduction
		if(!brake && forwardSpeed < currentMaxSpeed):
			velocity += forwardDirection * accelPower * nub.length() * delta
		if(brake && forwardSpeed > -maxReverseSpeed):
			velocity -= forwardDirection * reversePower * nub.length() * delta
	elif(brake):
		var speedReductionAmount = brakePower * delta
		if(forwardSpeed < speedReductionAmount):
			velocity -= forwardDirection * forwardSpeed
		else:
			velocity -= sign(forwardSpeed) * forwardDirection * brakePower * delta
	
	spriteNode.get_node("sprite_body_wheels").set_frame(0)
	framePhase += delta * forwardSpeed/10
	if(framePhase > 3):
		framePhase = 0
	print(framePhase)
	for i in spriteNode.get_children():
		i.set_frame(int(framePhase))
	leftFrontWheel.set_rot(steerAngle/10)
	rightFrontWheel.set_rot(steerAngle/10)
	
	#lateral friction (traction)
	var right = get_right_direction()
	var lateralForce = velocity.dot(right)
	var currentTireGrip = skidBeginForce
	var lateralCounterForce = -lateralForce#clamp(-lateralForce, -currentTireGrip, currentTireGrip)
	if(abs(lateralForce) < skidBeginForce):
		velocity += right * lateralCounterForce
	else:
		velocity += right * lateralCounterForce * skidGrip * delta
	
	if(abs(lateralForce) > minSkidmarkSpeed):
		tireMarks.leave_marks(true)
	else:
		tireMarks.leave_marks(brake && forwardSpeed > 0)
	
	#rolling friction
	var slowAmount = rollingFriction * delta
	if(velocity.length_squared() < slowAmount * slowAmount):
		velocity = Vector2(0, 0)
	else:
		velocity -= velocity.normalized() * slowAmount
	
	#make move based on velocity
	set_pos(get_pos() + velocity * delta)
	
	#solve collisions
	var overlapped = wallCollider.get_overlapping_bodies()
	for i in range(0, overlapped.size()):
		if(overlapped[i].get_name().begins_with("wall_")):
			handle_wall_collision(overlapped[i])
	
	#debug drawing
	#update()

var closestpont
func _draw():
	if(closestpont != null):
		draw_circle(closestpont - get_pos(), 5, Color(100, 100, 0))

func handle_wall_collision(wall):
	var polygon = wall.get_node("collision_polygon").get_polygon()
	var wallMatrix = wall.get_relative_transform_to_parent(get_tree().get_root().get_node("root"))
	var collisionPoint = _get_closest_point_on_polygon(polygon, wallMatrix, get_pos())
	#closestpont = collisionPoint
	var pos = get_pos()
	var collisionNormal = (collisionPoint-pos).normalized()
	var penetrationDist = colliderRadius - (collisionPoint-pos).length()
	if(penetrationDist > 0):
		set_pos(pos - collisionNormal * penetrationDist)
		velocity -= collisionNormal * velocity.dot(collisionNormal)

#returns the closest point on the surface of "polygon" to a given point "to"
func _get_closest_point_on_polygon(polygon, polyTransMatrix, to):
	#transform to polygon space (this accounts for the wall's position, rotation, and scale)
	var polySpaceTo = to - polyTransMatrix.get_origin()
	polySpaceTo = polySpaceTo.rotated(-polyTransMatrix.get_rotation())
	polySpaceTo = polySpaceTo / polyTransMatrix.get_scale()
	
	#find the closest point on each line segment, and pick the closest of them
	var closestPoint
	var distSqToClosest = 3.402823e+38
	for i in range(0, polygon.size()):
		var potentialPoint = _get_closest_point_on_line_segment(polygon[i], polygon[(i+1)%polygon.size()], polySpaceTo)
		var distSq = polySpaceTo.distance_squared_to(potentialPoint)
		if(distSq < distSqToClosest):
			closestPoint = potentialPoint
			distSqToClosest = distSq
	
	#transform result back to world space
	closestPoint = closestPoint * polyTransMatrix.get_scale()
	closestPoint = closestPoint.rotated(polyTransMatrix.get_rotation())
	closestPoint = closestPoint + polyTransMatrix.get_origin()
	
	return closestPoint
	
#returns the closest point on line segment "p1" - "p2" to point "to"
func _get_closest_point_on_line_segment(p1, p2, to):
	var difference = p2 - p1
	var diffNorm = difference.normalized()
	var dotProduct = diffNorm.dot(to-p1)
	
	if(dotProduct < 0):
		return p1
	if(dotProduct*dotProduct > difference.length_squared()):
		return p2
		
	var projectedPoint = p1 + diffNorm * dotProduct
	return projectedPoint

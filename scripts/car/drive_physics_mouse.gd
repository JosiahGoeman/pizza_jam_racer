extends Node2D

#constants
const maxForwardSpeed = 500
const maxBoostSpeed = 650
const maxReverseSpeed = 100
const accelPower = 500
const boostAccelPower = 1000
const offRoadDrag = 2
const reversePower = 500
const brakePower = 500
const steerSpeed = 5			#how fast car's steering turns to face nub
const maxSteerAngle = 2.5		#how far the car can steer
const skidBeginForce = 1200		#how much lateral force the car withstands before sliding
const skidGrip = 3				#how much the car resists lateral movement while sliding
const rollingFriction = 100		#how quickly the car slows down when not accelerating
const minSkidmarkSpeed = skidBeginForce	#how fast the car needs to be sliding to leave skidmarks
const colliderRadius = 10
const boostConsumeRate = 0.15
const minLoopPitch = 0.5
const maxLoopPitch = 3

var velocity = Vector2()
var facingAngle = 0		#direction car is facing
var steerAngle = 0
var boostJuice = 1
var onRoad = false
var usingBoost = false
var framePhase = 0.0
onready var spriteNode = get_node("sprites")				#reference to the sprite so we don't have to look it up every time
onready var leftFrontWheel = spriteNode.get_node("left_front_wheel")
onready var rightFrontWheel = spriteNode.get_node("right_front_wheel")
onready var boostEffect = spriteNode.get_node("boost_effect")
onready var tireMarks = get_parent().get_node("tire_marks")
onready var controlCircle = get_node("control_circle")
onready var wallCollider = get_node("wall_collider")
onready var roadChecker = get_node("road_checker")
onready var boostMeter = get_tree().get_root().get_node("root").get_node("hud_overlay").get_node("boost_meter")
onready var samplePlayer = get_node("sample_player")
onready var engineLoop = get_node("engine_loop")
onready var boostLoop = get_node("boost_loop")
onready var squealLoop = get_node("squeal_loop")
onready var particles = get_node("particles")
onready var camera = get_node("camera")

func _ready():
	engineLoop.play("engine_loop")
	squealLoop.play("tire_squeal_loop")
	set_process(true)

#direction car is facing
func get_forward_direction():
	return -Vector2(sin(facingAngle), cos(facingAngle))

#direction to car's right
func get_right_direction():
	var forward = get_forward_direction()
	return Vector2(-forward.y, forward.x)

func _set_boosting(val):
	if(val):
		samplePlayer.stop_all()
		samplePlayer.play("boost_start")
		boostLoop.play("boost")
		boostEffect.play()
		particles.set_emitting(true)
		camera.set_shake_amount(5)
		usingBoost = true
	else:
		samplePlayer.stop_all()
		samplePlayer.play("boost_end")
		boostLoop.stop_all()
		boostEffect.play()
		particles.set_emitting(false)
		camera.set_shake_amount(0)
		usingBoost = false

var boostKeyPrev = false
var leftMousePrev = false
func _process(delta):
	#grab input
	var brake = Input.is_key_pressed(KEY_SHIFT)
	var boostKey = Input.is_key_pressed(KEY_SPACE)
	var leftMouse = Input.is_mouse_button_pressed(BUTTON_LEFT)
	
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	#check what things we're driving over
	onRoad = false	#default to false
	var overlapped = roadChecker.get_overlapping_bodies()
	for i in range(0, overlapped.size()):
		if(overlapped[i].get_name().begins_with("road_")):
			onRoad = true
		if(overlapped[i].get_name().begins_with("boost_refill")):
			if(overlapped[i].try_pickup()):
				if(boostKey && boostJuice < 0):
					_set_boosting(true)
				boostJuice = 1
				boostMeter.set_boost_level(boostJuice)
	
	#mouse control
	steerAngle = 0
	if(leftMouse):
		#steer
		var nub = controlCircle.get_nub_pos()
		steerAngle = forwardDirection.angle_to(nub) * steerSpeed
		steerAngle = clamp(steerAngle, -maxSteerAngle * velocity.length() / 50, maxSteerAngle * velocity.length() / 50)
		facingAngle += steerAngle * delta
		spriteNode.set_rot(facingAngle)
		particles.set_pos(forwardDirection * -15)
	
		#turn boost on/off
		if(boostKey && (!boostKeyPrev || !leftMousePrev)):
			if(boostJuice >= 0):
				_set_boosting(true)
			else:
				samplePlayer.play("boost_fail")
		if(!boostKey && boostKeyPrev && boostJuice >= 0):
			_set_boosting(false)
	
		#accel/reverse/brake
		var currentMaxSpeed = maxForwardSpeed
		var currentAccelPower = accelPower
		if(usingBoost && boostJuice >= 0):
			boostJuice -= boostConsumeRate * delta
			particles.set_emitting(true)
			if(boostJuice < 0):
				_set_boosting(false)
			boostMeter.set_boost_level(boostJuice)
			currentMaxSpeed = maxBoostSpeed
			currentAccelPower = boostAccelPower
		if(!brake && forwardSpeed < currentMaxSpeed):
			velocity += forwardDirection * currentAccelPower * nub.length() * delta
		if(brake && forwardSpeed > -maxReverseSpeed):
			velocity -= forwardDirection * reversePower * nub.length() * delta
	else:
		if(usingBoost && boostJuice >= 0):
			_set_boosting(false)
		if(brake):
			var speedReductionAmount = brakePower * delta
			if(forwardSpeed < speedReductionAmount):
				velocity -= forwardDirection * forwardSpeed
			else:
				velocity -= sign(forwardSpeed) * forwardDirection * brakePower * delta
	boostKeyPrev = boostKey
	leftMousePrev = leftMouse
	
	#animation
	framePhase += delta * forwardSpeed/10
	if(framePhase > 2):
		framePhase = 0
	if(framePhase < 0):
		framePhase = 2
	for i in spriteNode.get_children():
		i.set_frame(int(framePhase))
	var wheelAngle = sign(forwardSpeed) * (steerAngle / 10)
	leftFrontWheel.set_rot(wheelAngle)
	rightFrontWheel.set_rot(wheelAngle)
	
	#loop pitch
	var pitch = lerp(minLoopPitch, maxLoopPitch, abs(forwardSpeed)/maxForwardSpeed)
	engineLoop.voice_set_pitch_scale(0, pitch)
	
	#lateral friction (traction)
	var right = get_right_direction()
	var lateralForce = velocity.dot(right)
	var currentTireGrip = skidBeginForce
	var lateralCounterForce = -lateralForce#clamp(-lateralForce, -currentTireGrip, currentTireGrip)
	if(abs(lateralForce) < skidBeginForce * delta):
		print("ok")
		velocity += right * lateralCounterForce
	else:
		print("skidding")
		velocity += right * lateralCounterForce * skidGrip * delta
	
	#rolling friction
	var slowAmount = rollingFriction * delta
	if(velocity.length_squared() < slowAmount * slowAmount):
		velocity = Vector2(0, 0)
	else:
		velocity -= velocity.normalized() * slowAmount
	if(!onRoad):
		velocity -= velocity * offRoadDrag * delta
	
	#tire marks
	var leaveMarks = false
	if(abs(lateralForce) > minSkidmarkSpeed * delta && onRoad):
		var volume = clamp(-40 + abs(lateralForce) / 6, -40, 0)
		squealLoop.voice_set_volume_scale_db(0, volume)
		leaveMarks = true
	else:
		squealLoop.voice_set_volume_scale_db(0, -60)
	#if(brake && forwardSpeed > 0):
		#leaveMarks = true
	if(!onRoad):
		leaveMarks = true
	tireMarks.leave_marks(leaveMarks)
	
	#make move based on velocity
	set_pos(get_pos() + velocity * delta)
	
	#solve collisions
	var overlapped = wallCollider.get_overlapping_bodies()
	for i in range(0, overlapped.size()):
		if(overlapped[i].get_name().begins_with("wall_")):
			handle_wall_collision(overlapped[i])

func handle_wall_collision(wall):
	var polygon = wall.get_node("collision_polygon").get_polygon()
	var wallMatrix = wall.get_relative_transform_to_parent(get_tree().get_root().get_node("root"))
	var collisionPoint = _get_closest_point_on_polygon(polygon, wallMatrix, get_pos())
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

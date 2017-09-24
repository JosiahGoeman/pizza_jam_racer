extends Node2D

#constants
const maxForwardSpeed = 300
const maxBoostSpeed = 500
const maxReverseSpeed = 100		
const accelPower = 500			#how fast the car accelerates
const reversePower = 500		#how fast the car reverses (and brakes)
const brakePower = 1000
const baseSteerPower = 0.015	#steering power at starting speed
const minSteerPower = 0.005		#steering power at end of intercal
const steerInterval = 400		#speed at which steer is most restricted
const steerSpeed = 0.075
const rtcSpeed = 0.075
const tireGrippiness = 420		#how much lateral force the car withstands before sliding
const rollingFriction = 50		#how quickly the car slows down
const minSkidmarkSpeed = 150

var velocity = Vector2()
var facingAngle = 0		#direction car is facing
var steerAngle = 0
var angularVelocity = 0
var hasTraction = true
var sprite				#reference to the sprite so we don't have to look it up every time
onready var tireMarks = get_parent().get_node("tire_marks")
var camera

func _ready():
	sprite = get_node("sprite")
	camera = get_parent().get_node("camera")
	set_process(true)
	pass

#direction car is facing
func get_forward_direction():
	return -Vector2(sin(facingAngle), cos(facingAngle))

#direction to car's right
func get_right_direction():
	var forward = get_forward_direction()
	return Vector2(-forward.y, forward.x)
	
func _process(delta):
	#grab input
	var forward = Input.is_key_pressed(KEY_W)
	var backward = Input.is_key_pressed(KEY_S)
	var brake = Input.is_key_pressed(KEY_SHIFT)
	var left = Input.is_key_pressed(KEY_A)
	var right = Input.is_key_pressed(KEY_D)
	var boost = Input.is_key_pressed(KEY_SPACE)
	
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	#steer
	steerAngle += (left - right) * steerSpeed * delta
	if(!left && !right):
		var steerReductionAmount = rtcSpeed * delta
		if(abs(steerAngle) < steerReductionAmount):
			steerAngle = 0
		else:
			steerAngle -= sign(steerAngle) * steerReductionAmount

	var lerpFrac = forwardSpeed / steerInterval
	var steerPower = lerp(baseSteerPower, minSteerPower, lerpFrac)
	steerPower = clamp(steerPower, minSteerPower, baseSteerPower)
	if(boost):
		steerPower = minSteerPower
	steerAngle = clamp(steerAngle, -steerPower, steerPower)
	
	angularVelocity += (steerAngle * forwardSpeed) * delta
	facingAngle += (steerAngle * forwardSpeed) * delta
	sprite.set_rot(facingAngle)
	
	#accel/reverse/brake
	var currentMaxSpeed = maxForwardSpeed
	if(boost):
		currentMaxSpeed = maxBoostSpeed
	if(forward && !brake && forwardSpeed < currentMaxSpeed):
		velocity += forwardDirection * accelPower * delta
	if(backward && !brake && forwardSpeed > -maxReverseSpeed):
		velocity -= forwardDirection * reversePower * delta
	if(brake):
		velocity -= sign(forwardSpeed) * forwardDirection * brakePower * delta
	
	#lateral friction (traction)
	var right = get_right_direction()
	var lateralForce = velocity.dot(right)
	var currentTireGrip = tireGrippiness
	var lateralCounterForce = clamp(-lateralForce, -currentTireGrip, currentTireGrip)
	velocity += right * lateralCounterForce * delta
	
	if(abs(lateralForce) > minSkidmarkSpeed):
		facingAngle += angularVelocity * 0.5 * delta
		tireMarks.leave_marks(true)
	else:
		angularVelocity = 0
		tireMarks.leave_marks(brake)
	
	#rolling friction
	var slowAmount = rollingFriction * delta
	if(velocity.length_squared() < slowAmount * slowAmount):
		velocity = Vector2(0, 0)
	else:
		velocity -= velocity.normalized() * slowAmount
	
	set_pos(get_pos() + velocity * delta)

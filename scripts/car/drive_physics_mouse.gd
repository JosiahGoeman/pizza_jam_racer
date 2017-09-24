extends Node2D

#constants
const maxForwardSpeed = 300
const maxBoostSpeed = 500
#const maxReverseSpeed = 100		
const accelPower = 500
#const reversePower = 500
const brakePower = 1000
const steerSpeed = 5			#how fast car's steering turns to face nub
const maxSteerAngle = 2.5		#how far the car can steer
const skidBeginForce = 25		#how much lateral force the car withstands before sliding
const skidGrip = 3				#how much the car resists lateral movement while sliding
const rollingFriction = 50		#how quickly the car slows down when not accelerating
const minSkidmarkSpeed = 150	#how fast the car needs to be sliding to leave skidmarks

var velocity = Vector2()
var facingAngle = 0		#direction car is facing
var steerAngle = 0
onready var sprite = get_node("sprite_body_primary")				#reference to the sprite so we don't have to look it up every time
onready var tireMarks = get_parent().get_node("tire_marks")
onready var controlCircle = get_node("control_circle")

func _ready():
	set_process(true)

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
	
	#mouse control
	if(Input.is_mouse_button_pressed(BUTTON_LEFT)):
		#steer
		var nub = controlCircle.get_nub_pos()
		steerAngle = forwardDirection.angle_to(nub) * steerSpeed
		steerAngle = clamp(steerAngle, -maxSteerAngle * velocity.length() / 50, maxSteerAngle * velocity.length() / 50)
		facingAngle += steerAngle * delta
		sprite.set_rot(facingAngle)
	
		#accel/reverse/brake
		var currentMaxSpeed = maxForwardSpeed
		if(boost):
			currentMaxSpeed = maxBoostSpeed
		if(forwardSpeed < currentMaxSpeed):
			velocity += forwardDirection * accelPower * nub.length() * delta
	#if(backward && !brake && forwardSpeed > -maxReverseSpeed):
		#velocity -= forwardDirection * reversePower * delta
	#if(brake):
		#velocity -= sign(forwardSpeed) * forwardDirection * brakePower * delta
	
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
		tireMarks.leave_marks(brake)
	
	#rolling friction
	var slowAmount = rollingFriction * delta
	if(velocity.length_squared() < slowAmount * slowAmount):
		velocity = Vector2(0, 0)
	else:
		velocity -= velocity.normalized() * slowAmount
	
	set_pos(get_pos() + velocity * delta)

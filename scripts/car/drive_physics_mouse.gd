extends "res://scripts/car/car_base.gd"

const maxBoostSpeed = 650
const boostAccelPower = 1000
const boostConsumeRate = 0.25

var usingBoost = false
var boostJuice = 1

onready var controlCircle = get_node("control_circle")
onready var camera = get_node("camera")
onready var boostMeter = get_node("hud_overlay").get_node("boost_meter")
onready var winScreen = get_node("hud_overlay").get_node("win_screen")
onready var loseScreen = get_node("hud_overlay").get_node("lose_screen")

func _ready():
	engineLoop.play("engine_loop")
	squealLoop.play("tire_squeal_loop")
	set_process(true)

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
	#print(get_parent())
	#print(get_parent().get_node("hud_overlay"))
	#for i in get_parent().get_node("hud_overlay").get_children():
		#print(i.get_name())
	#print(get_parent().get_node("hud_overlay").get_node("win_screen"))
	if(rootNode.raceState == rootNode.RACE_STATES.STARTING ||
	rootNode.raceState == rootNode.RACE_STATES.COUNTDOWN):
		return
	
	if(rootNode.raceState == rootNode.RACE_STATES.TUTORIAL):
		boostJuice = 1
	
	#grab input
	var brake = Input.is_key_pressed(KEY_SHIFT)
	var boostKey = Input.is_mouse_button_pressed(BUTTON_RIGHT)
	var leftMouse = Input.is_mouse_button_pressed(BUTTON_LEFT)
	
	var forwardDirection = get_forward_direction()
	var forwardSpeed = velocity.dot(forwardDirection)
	
	#check for item pickups
	var touchedRefills = _get_touched_nodes("boost_refill")
	for i in touchedRefills:
		if(i.try_pickup()):
			if(boostKey && boostJuice < 0):
				_set_boosting(true)
			samplePlayer.play("pickup")
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
	
	if(lapsCompleted == 1):
		if(rootNode.raceState == rootNode.RACE_STATES.IN_PROGRESS):
			rootNode.set_race_state(rootNode.RACE_STATES.WIN)
			winScreen.show()
			
	if(rootNode.raceState == rootNode.RACE_STATES.LOSE_STILL_FINISHING):
		rootNode.set_race_state(rootNode.RACE_STATES.LOSE)
		loseScreen.show()

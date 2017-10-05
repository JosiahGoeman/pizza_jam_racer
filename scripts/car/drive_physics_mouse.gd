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
onready var lapCounter = get_node("hud_overlay").get_node("lap_counter")
onready var rocketPrefab = load("res://prefabs/rocket.tscn")

func _ready():
	engineLoop.play("engine_loop")
	squealLoop.play("tire_squeal_loop")
	set_process(true)

func _set_boosting(val):
	if(val):
		samplePlayer.stop_all()
		samplePlayer.play("boost_start")
		boostLoop.play("boost_loop")
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
var rocketKeyPrev = false
func _process(delta):
	if(rootNode.raceState == rootNode.RACE_STATES.STARTING ||
	rootNode.raceState == rootNode.RACE_STATES.COUNTDOWN):
		return
	
	#grab input
	var brake = Input.is_key_pressed(KEY_SHIFT)
	var boostKey = Input.is_mouse_button_pressed(BUTTON_RIGHT)
	var leftMouse = Input.is_mouse_button_pressed(BUTTON_LEFT)
	var rocketKey = Input.is_key_pressed(KEY_SPACE)
	
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
	
	#here's my one-step plan...
	if(rocketKey && !rocketKeyPrev):
		var cuteLittleRocket = rocketPrefab.instance()
		cuteLittleRocket.set_global_pos(get_global_pos())
		cuteLittleRocket.facingAngle = facingAngle
		cuteLittleRocket.velocity = velocity
		rootNode.add_child(cuteLittleRocket)

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
			var currentScene = get_tree().get_current_scene().get_name()
			if(currentScene != "tutorial" &&
			currentScene != "boss_arena"):
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
	rocketKeyPrev = rocketKey
	
	lapCounter.set_bbcode("Lap: "+str(lapsCompleted)+" / 3")
	if(lapsCompleted == 3):
		if(rootNode.raceState == rootNode.RACE_STATES.IN_PROGRESS):
			rootNode.set_race_state(rootNode.RACE_STATES.WIN)
			winScreen.show()
	
	if(rootNode.raceState == rootNode.RACE_STATES.WIN):
		if(Input.is_key_pressed(KEY_SPACE)):
			if(get_tree().get_current_scene().get_name() == "race_1"):
				get_tree().change_scene("res://rooms/race_2.tscn")
			if(get_tree().get_current_scene().get_name() == "race_2"):
				get_tree().change_scene("res://rooms/a_challenger_appears.tscn")
			
	if(rootNode.raceState == rootNode.RACE_STATES.LOSE):
		loseScreen.show()
		if(Input.is_key_pressed(KEY_SPACE)):
			get_tree().reload_current_scene()

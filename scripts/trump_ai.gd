extends "res://scripts/car/car_base.gd"

export var bombPeriod = 1

var bombTimer = 0

onready var playerCar = rootNode.get_node("player_car")
onready var rocketPrefab = load("res://prefabs/bomb.tscn")

func _ready():
	collisionTaunts = [
		"I'm HUGE!!!",
		"I think we have a great relationship!",
		"Fight back!  Be brutal, be tough!",
		"Enough is enough!"
	]
	
	winTaunts = [
		"You fought me and lost so badly you just don’t know what to do. Love!",
		"You're not sending your best.",
		"A lot of good things are happening.",
		"We have had tremendous success, but we don't talk about it."
	]
	
	loseTaunts = [
		"That's fake news.",
		"I thought it would be easier...",
		"I like to drive.  I can't drive anymore.",
		"Sometimes you have to give up the fight and move on to something more productive."
	]
	
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
	
	#bombs
	bombTimer += delta
	if(bombTimer > bombPeriod):
		bombTimer = 0
		var cuteLittleRocket = rocketPrefab.instance()
		cuteLittleRocket.targetPos = Vector2(randi()%1000-500, randi()%1000-500)
		cuteLittleRocket.set_global_pos(get_global_pos())
		#cuteLittleRocket.facingAngle = facingAngle
		#cuteLittleRocket.velocity = velocity
		rootNode.add_child(cuteLittleRocket)
	
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

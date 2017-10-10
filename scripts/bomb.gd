extends Node2D

export var period = 5
export var growShrinkSpeed = 5

var timer = 0
var shakePeriod = 0.05
var shakeTimer = 0
var exploded = false
var startingPos
var targetPos = Vector2()
var phase = 0

onready var sprite = get_node("sprite")
onready var explosion = get_node("explosion")
onready var sound = get_node("sound")

func _ready():
	startingPos = get_global_pos()
	set_process(true)

func _process(delta):
	timer += delta
	if(timer < period * 0.25):
		set_pos(startingPos.linear_interpolate(targetPos, timer/(period*0.25)))
	
	if(timer > period * 0.75):
		shakeTimer += delta
		sprite.set_modulate(Color(1, 0, 0))
		if(shakeTimer > shakePeriod):
			shakeTimer = 0
			sprite.set_pos(Vector2(randf() * 5-2.5, randf() * 5-2.5))
	
	growShrinkSpeed += timer * 0.01
	var scaleMultiplier = sin(timer * growShrinkSpeed) * 0.1
	set_scale(Vector2(1+scaleMultiplier, 1+scaleMultiplier))
	if(timer > period):
		var overlapped = get_node("collider").get_overlapping_bodies()
		for i in range(0, overlapped.size()):
			if(overlapped[i].get_parent().get_name().begins_with("player_")):
				#print("you wrecked yourself!")
				pass
			elif(overlapped[i].get_parent().get_name().begins_with("trump_")):
				#print("you wrecked trump!")
				pass
		
		explosion.play()
		if(!sound.is_voice_active(0)):
			if(!exploded):
				sprite.hide()
				sound.play("bomb")
				exploded = true
			else:
				queue_free()
		

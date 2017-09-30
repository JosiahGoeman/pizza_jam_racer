extends Node2D

enum RACE_STATES{
	STARTING,
	COUNTDOWN,
	IN_PROGRESS,
	WIN,
	LOSE
}

const startingPeriod = 3
const countdownPeriod = 3

var timer = 0
var countDownCounter = 4
var raceState = RACE_STATES.STARTING

onready var chimePlayer = get_node("starting_chime")

func _ready():
	set_process(true)

func _process(delta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()
	if(Input.is_key_pressed(KEY_F11)):
		OS.set_window_fullscreen(!OS.is_window_fullscreen())
	
	timer += delta
	if(raceState == RACE_STATES.STARTING):
		if(timer > startingPeriod):
			timer = 0
			raceState = RACE_STATES.COUNTDOWN
	elif(raceState == RACE_STATES.COUNTDOWN):
		if(int(timer - delta) != int(timer)):
			countDownCounter -= 1
			if(countDownCounter == 0):
				timer = 0
				chimePlayer.play("go")
				raceState = RACE_STATES.IN_PROGRESS
			else:
				chimePlayer.play("3-2-1")

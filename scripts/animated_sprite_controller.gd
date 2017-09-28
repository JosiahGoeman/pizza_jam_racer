extends Sprite

export var frameCount = 1
export var animSpeed = 1
export var loop = false

var framePhase = 0.0
var oneShot = false

func _ready():
	set_process(true)

func _process(delta):
	if(loop || oneShot):
		framePhase += animSpeed * delta
		
	if(framePhase > frameCount - 1):
		if(!loop):
			hide()
		oneShot = false
		framePhase = 0
	set_frame(int(framePhase))

func play():
	show()
	oneShot = true

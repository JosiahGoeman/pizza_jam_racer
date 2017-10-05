extends Sprite

export var frameCount = 1
export var animSpeed = 1
export var loop = false

var framePhase = 0.0
var oneShot = false
var caller
var callback

func _ready():
	set_process(true)

func _process(delta):
	if(loop || oneShot):
		framePhase += animSpeed * delta
	
	if(framePhase > frameCount - 1):
		if(!loop):
			hide()
		if(caller != null):
			caller.call(callback)
		oneShot = false
		framePhase = 0
	set_frame(int(framePhase))

func play():
	show()
	oneShot = true

func playWithCallback(caller, callback):
	self.caller = caller
	self.callback = callback
	play()

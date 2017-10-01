extends RichTextLabel

export var blinkSpeed = 1

var timer = 0

func _ready():
	set_process(true)

func _process(delta):
	timer += delta
	if(timer > 0.5/blinkSpeed):
		show()
	if(timer > blinkSpeed):
		hide()
		timer = 0

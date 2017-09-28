extends StaticBody2D

export var respawnTime = 10

var taken = false
var respawnTimer = 0
onready var sprite = get_node("sprite")

func _ready():
	set_process(true)

func _process(delta):
	if(taken):
		respawnTimer += delta
		if(respawnTimer > respawnTime):
			taken = false
			respawnTimer = 0
			sprite.show()

func try_pickup():
	if(!taken):
		taken = true
		sprite.hide()
		return true
	else:
		return false

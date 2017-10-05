extends Node2D

onready var rootNode = get_tree().get_current_scene()
onready var explosion = get_node("explosion")
onready var sprite = get_node("sprite")

func _ready():
	set_process(true)

func _process(delta):
	if(rootNode.raceState == rootNode.RACE_STATES.IN_PROGRESS):
		explosion.playWithCallback(self, "onAnimEnd")
		sprite.hide()

func onAnimEnd():
	queue_free()

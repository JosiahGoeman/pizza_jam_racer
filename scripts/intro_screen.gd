extends CanvasLayer

onready var rootNode =get_tree().get_current_scene()

func _ready():
	set_process(true)

func _process(delta):
	if(rootNode.raceState != rootNode.RACE_STATES.STARTING):
		for i in get_children():
			i.hide()

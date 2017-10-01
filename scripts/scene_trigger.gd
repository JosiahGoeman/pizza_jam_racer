extends Area2D

export var triggerName = ""
export var scenePath = ""
export var delay = 0

var timer = 0

func _ready():
	set_process(true)

func _process(delta):
	if(timer > 0):
		timer += delta
	var overlapped = get_overlapping_bodies()
	for i in range(0, overlapped.size()):
		if(overlapped[i].get_name().begins_with(triggerName)):
			timer += delta
	if(timer > delay):
		get_tree().change_scene(scenePath)

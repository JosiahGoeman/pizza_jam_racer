extends Node2D

func _ready():
	set_process(true)

func _process(dekta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()

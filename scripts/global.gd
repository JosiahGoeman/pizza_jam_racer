extends Node2D

func _ready():
	set_process(true)
	OS.set_window_size( Vector2(1024, 576) )

func _process(dekta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()

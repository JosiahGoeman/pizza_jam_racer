extends Node2D

func _ready():
	get_tree().connect("screen_resized", self, "_on_window_resize")
	set_process(true)

func _on_window_resize():
	pass
	#var newWindowSize = OS.get_window_size()
	#get_tree().get_root().set_rect(newWindowSize)

func _process(delta):
	if(Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()

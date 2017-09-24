extends Node2D

export var zoom = 1.0

onready var screen_size = Vector2(1024, 576)
onready var target = get_parent()

func _ready():
	set_process(true)

func _process(delta):
	var canvasTransform = get_viewport().get_canvas_transform()
	canvasTransform[2] = (-target.get_pos() + screen_size / 2)
	canvasTransform[0] = Vector2(zoom, 0)
	canvasTransform[1] = Vector2(0, zoom)
	get_viewport().set_canvas_transform(canvasTransform)

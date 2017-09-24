extends Node2D

export var zoom = 1.0

onready var screenSize = get_viewport().get_rect().size
onready var target = get_parent()

func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	set_process(true)

func _on_resize():
	screenSize = get_viewport().get_rect().size

func _process(delta):
	var canvasTransform = get_viewport().get_canvas_transform()
	canvasTransform[2] = (-target.get_pos()*zoom + screenSize / 2)
	canvasTransform[0] = Vector2(zoom, 0)
	canvasTransform[1] = Vector2(0, zoom)
	get_viewport().set_canvas_transform(canvasTransform)

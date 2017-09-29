extends Node2D

export var zoom = 1.0

onready var screenSize = get_viewport().get_rect().size
onready var target = get_parent()
var screenShakeAmount = 0
var shakeInterval = 0.01
var shakePhase = 0
var shakeOffset = Vector2()

func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_resize")
	set_process(true)

func _on_resize():
	screenSize = get_viewport().get_rect().size

func set_shake_amount(val):
	screenShakeAmount = val

func _process(delta):
	shakePhase += delta
	if(shakePhase > shakeInterval):
		shakePhase = 0
		shakeOffset.x = randf() * screenShakeAmount - screenShakeAmount / 2
		shakeOffset.y = randf() * screenShakeAmount - screenShakeAmount / 2
	
	var canvasTransform = get_viewport().get_canvas_transform()
	canvasTransform[2] = ((-target.get_pos()+shakeOffset)*zoom + screenSize / 2)
	canvasTransform[0] = Vector2(zoom, 0)
	canvasTransform[1] = Vector2(0, zoom)
	get_viewport().set_canvas_transform(canvasTransform)

extends Node2D

export var circleRadius = 100
const circleRes = 50
export var circleColor = Color(100, 100, 100, 0.05)
export var circleThinkness = 2
export var nubSize = 10
export var nubColor = Color(0, 0, 0, 0.2)

onready var car = get_parent()
var circlePoints

func _ready():
	circlePoints = []
	for i in range(0, circleRes):
		var angle = (i/float(circleRes)) * PI*2
		circlePoints.append(Vector2(sin(angle), cos(angle)) * circleRadius)
	
	set_process(true)

func _process(delta):
	update()

func _get_clipped_mouse_pos():
	var mousePos = get_global_mouse_pos() - get_global_pos()
	if(mousePos.length_squared() > circleRadius * circleRadius):
		mousePos = mousePos.normalized() * circleRadius
	return mousePos

func get_nub_pos():
	return _get_clipped_mouse_pos() / (circleRadius)

func _draw():
	for i in range(0, circleRes):
		draw_line(circlePoints[i], circlePoints[(i+1)%circleRes], circleColor, circleThinkness)
	
	if(Input.is_mouse_button_pressed(BUTTON_LEFT)):
		draw_circle(_get_clipped_mouse_pos(), nubSize, nubColor)

extends Node2D

const minSegmentLength = 10
const maxPoints = 1000
const lineThickness = 2
const lineFadeIntensity = 500.0
const lineFadeMax = .5
const p1Offset = Vector2(-5, -10)
const p2Offset = Vector2(5, -10)
const p3Offset = Vector2(-5, 10)
const p4Offset = Vector2(5, 10)

onready var car = get_parent().get_node("car")
var prevCarPos
var prevPoints
var leavingMarks

onready var points = Vector2Array()

func _ready():
	set_process(true)

func leave_marks(doIt):
	if(doIt && !leavingMarks):
		prevCarPos = car.get_pos()
		prevPoints = _get_points()
	leavingMarks = doIt

func _get_points():
	var pos = car.get_pos()
	var forward = car.get_forward_direction()
	var right = car.get_right_direction()
	return ([
		pos + forward * p1Offset.y + right * p1Offset.x,
		pos + forward * p2Offset.y + right * p2Offset.x,
		pos + forward * p3Offset.y + right * p3Offset.x,
		pos + forward * p4Offset.y + right * p4Offset.x,
	])

func _process(delta):
	var currentCarPos = car.get_pos()
	if(leavingMarks
	&& (currentCarPos-prevCarPos).length_squared() > minSegmentLength * minSegmentLength):
		var points = _get_points()
		var difference = currentCarPos - prevCarPos
		add_point(prevPoints[0])
		add_point(points[0])
		add_point(prevPoints[1])
		add_point(points[1])
		add_point(prevPoints[2])
		add_point(points[2])
		add_point(prevPoints[3])
		add_point(points[3])
		prevCarPos = currentCarPos
		prevPoints = points
		update()

func add_point(point):
	points.append(point)
	if(points.size() > maxPoints):
		points.remove(0)

func _draw():
	for i in range(0, points.size()-1, 2):
		draw_line(points[i], points[i+1], Color(0, 0, 0, min(lineFadeMax, (i + maxPoints - points.size()) / lineFadeIntensity)), lineThickness)

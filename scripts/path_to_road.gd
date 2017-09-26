tool
extends Path2D

export var roadWidth = 100 setget _update_road_width
export(Texture) var roadTexture = preload("res://textures/road.png") setget _change_texture
export var textureInterval = 5 setget _set_texture_interval
export var drawBakeInterval = 64
export var colliderBakeInterval = 128
export var PRESS_ME_TO_REBUILD_COLLIDER = false setget _update_collision_polygon

func _ready():
	pass

func _change_texture(texture):
	#get_curve().set_bake_interval(texture.get_height())
	update()

func _update_road_width(val):
	roadWidth = val
	update()

func _set_texture_interval(val):
	textureInterval = val
	update()

#create the polygon for the collider
#this can't be the same as the drawing because it has to all be one piece
func _update_collision_polygon(val):
	PRESS_ME_TO_REBUILD_COLLIDER = val
	if(get_tree() == null || !get_tree().is_editor_hint()):
		return
	
	var curve = get_curve()
	curve.set_bake_interval(colliderBakeInterval)
	var curvePoints = curve.get_baked_points()
	var curvePointCount = curvePoints.size()
	
	var leftPoints = Vector2Array()
	var rightPoints = Vector2Array()
	
	var colliderShape = get_node("road_collider").get_node("road_shape")
	for i in range(0, curvePointCount):
		var thisPoint = curvePoints[i]
		
		var thisNormal = _get_path_normal(curve, i)
		var nextNormal = _get_path_normal(curve, (i+1)%curvePointCount)
		
		leftPoints.append(thisPoint + -thisNormal * roadWidth)
		rightPoints.append(thisPoint + thisNormal * roadWidth)
	rightPoints.invert()
	leftPoints.append_array(rightPoints)
	colliderShape.set_polygon(leftPoints)

func _draw():
	var curve = get_curve()
	curve.set_bake_interval(drawBakeInterval)
	var curvePoints = curve.get_baked_points()
	var curvePointCount = curvePoints.size()
	
	#draw the road in quad segments
	#if done the same way as the collider, the segments are automatic and can't
	#be textured
	var roadPoints = Vector2Array()
	for i in range(0, curvePointCount-1):
		var thisPoint = curvePoints[i]
		var nextPoint = curvePoints[(i+1) % curvePointCount]
		
		var thisNormal = _get_path_normal(curve, i)
		var nextNormal = _get_path_normal(curve, (i+1) % curvePointCount)
		
		roadPoints.resize(0)
		roadPoints.append(nextPoint + -nextNormal * roadWidth)
		roadPoints.append(nextPoint + nextNormal * roadWidth)
		roadPoints.append(thisPoint + thisNormal * roadWidth)
		roadPoints.append(thisPoint + -thisNormal * roadWidth)
		
		var v = (i+1%textureInterval+1) * (1.0 / textureInterval)
		var roadUVs = [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
		draw_colored_polygon(roadPoints, Color(1, 1, 1, 1), roadUVs,  roadTexture)
		
		draw_circle(thisPoint + thisNormal * roadWidth, 5, Color(100, 0, 0))
		draw_circle(thisPoint + -thisNormal * roadWidth, 5, Color(100, 0, 0))

func _get_path_normal(curve, index):
	var curvePoints = curve.get_baked_points()
	var curvePointCount = curvePoints.size()
	
	var prevPoint = curvePoints[index-1]
	if(index == 0):
		prevPoint = curvePoints[curvePointCount-1]
	var thisPoint = curvePoints[index]
	var nextPoint = curvePoints[(index+1) % curvePointCount]
	
	var prevForward = (thisPoint - prevPoint).normalized()
	var forward = (nextPoint - thisPoint).normalized()
	
	var prevRight = Vector2(-prevForward.y, prevForward.x)
	var right = Vector2(-forward.y, forward.x)
	
	if(index == 0):
		prevRight = right
	if(index == curvePointCount-1):
		right = prevRight
		
	return (prevRight + right).normalized()

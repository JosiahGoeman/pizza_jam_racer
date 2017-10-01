tool
extends CollisionPolygon2D

export var wallHeight = 25
export var topHeight = 25
export var wallTextureScale = 50
export var topTextureScale = 50
export(Texture) var wallTexture
export(Texture) var topTexture

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _draw():
	#draw walls
	var polygon = get_polygon()
	for i in range(0, polygon.size()):
		var thisVert = polygon[i]
		var nextVert = polygon[(i+1)%polygon.size()]
		var aboveThis = thisVert + Vector2(0, -wallHeight)
		var aboveNext = nextVert + Vector2(0, -wallHeight)
		var segmentPolygon = [thisVert, aboveThis, aboveNext, nextVert]
		var segmentColors = [Color(1, 1, 1, 1),Color(1, 1, 1, 1),Color(1, 1, 1, 1),Color(1, 1, 1, 1)]
		var segmentUVs = [
		thisVert/wallTextureScale,
		aboveThis/wallTextureScale,
		aboveNext/wallTextureScale,
		nextVert/wallTextureScale]
		draw_polygon(segmentPolygon, segmentColors, segmentUVs, wallTexture)
	
	#draw top polygon
	var topPolygon = get_polygon()
	var topColors = []
	var topUVs = []
	for i in range(0, topPolygon.size()):
		topPolygon[i] += Vector2(0, -topHeight)
		topColors.append(Color(1, 1, 1, 1))
		topUVs.append(topPolygon[i] / topTextureScale)
		#draw_circle(polygon[i], 10, Color(1, 1, 1, 1))
	draw_polygon(topPolygon, topColors, topUVs, topTexture)

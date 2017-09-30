extends Node2D

#constants
const maxForwardSpeed = 500
const maxReverseSpeed = 100
const accelPower = 500
const offRoadDrag = 2
const reversePower = 500
const brakePower = 500
const steerSpeed = 5			#how fast car's steering turns to face nub
const maxSteerAngle = 2.5		#how far the car can steer
const skidBeginForce = 1200		#how much lateral force the car withstands before sliding
const skidGrip = 3				#how much the car resists lateral movement while sliding
const rollingFriction = 100		#how quickly the car slows down when not accelerating
const minSkidmarkSpeed = skidBeginForce	#how fast the car needs to be sliding to leave skidmarks
const colliderRadius = 20
const minLoopPitch = 0.5
const maxLoopPitch = 3
const tauntPeriod = 2
const speedForImpactSount = 50
const minImpactSoundTime = 0.25

var velocity = Vector2()
export var facingAngle = 0 setget _change_face_angle		#direction car is facing
var steerAngle = 0
var onRoad = false
var framePhase = 0.0
var tauntTimer = tauntPeriod
var impactSoundTimer = 0

#node references
onready var rootNode = get_tree().get_root().get_node("root")
onready var spriteNode = get_node("sprites")				#reference to the sprite so we don't have to look it up every time
onready var leftFrontWheel = spriteNode.get_node("left_front_wheel")
onready var rightFrontWheel = spriteNode.get_node("right_front_wheel")
onready var boostEffect = spriteNode.get_node("boost_effect")
onready var tireMarks = get_parent().get_node("tire_marks")
onready var wallCollider = get_node("wall_collider")
onready var roadChecker = get_node("road_checker")
onready var boostMeter = rootNode.get_node("hud_overlay").get_node("boost_meter")
onready var samplePlayer = get_node("sample_player")
onready var engineLoop = get_node("engine_loop")
onready var boostLoop = get_node("boost_loop")
onready var squealLoop = get_node("squeal_loop")
onready var particles = get_node("particles")
onready var tauntLabel = get_node("taunt_label")

func _change_face_angle(val):
	facingAngle = val * 0.0174533

func _on_ready():
	set_process(true)

func _process(delta):
	tauntTimer += delta
	if(tauntTimer > tauntPeriod):
		tauntLabel.hide()
	
	impactSoundTimer += delta
	
	onRoad = _check_road()
	
	#rolling friction
	var slowAmount = rollingFriction * delta
	if(velocity.length_squared() < slowAmount * slowAmount):
		velocity = Vector2(0, 0)
	else:
		velocity -= velocity.normalized() * slowAmount
	if(!onRoad):
		velocity -= velocity * offRoadDrag * delta
	
	var forwardSpeed = velocity.dot(get_forward_direction())
	
	#animation
	spriteNode.set_rot(facingAngle)
	framePhase += delta * forwardSpeed/10
	if(framePhase > 2):
		framePhase = 0
	if(framePhase < 0):
		framePhase = 2
	#for i in spriteNode.get_children():
		#i.set_frame(int(framePhase))	#bug! creates errors on sprites with one frame
	var wheelAngle = sign(forwardSpeed) * (steerAngle / 10)
	leftFrontWheel.set_rot(wheelAngle)
	rightFrontWheel.set_rot(wheelAngle)
	
	#lateral friction (traction)
	var right = get_right_direction()
	var lateralForce = velocity.dot(right)
	var currentTireGrip = skidBeginForce
	var lateralCounterForce = -lateralForce#clamp(-lateralForce, -currentTireGrip, currentTireGrip)
	if(abs(lateralForce) < skidBeginForce * delta):
		velocity += right * lateralCounterForce
	else:
		velocity += right * lateralCounterForce * skidGrip * delta
		
	#tire marks
	var leaveMarks = false
	if(abs(lateralForce) > minSkidmarkSpeed * delta && onRoad):
		var volume = clamp(-40 + abs(lateralForce) / 6, -40, 0)
		squealLoop.voice_set_volume_scale_db(0, volume)
		leaveMarks = true
	else:
		squealLoop.voice_set_volume_scale_db(0, -60)
	#if(brake && forwardSpeed > 0):
		#leaveMarks = true
	if(!onRoad):
		leaveMarks = true
	tireMarks.leave_marks(leaveMarks)
	
	#make move based on velocity
	set_pos(get_pos() + velocity * delta)
	
	#solve collisions
	var overlapped = wallCollider.get_overlapping_bodies()
	for i in range(0, overlapped.size()):
		if(overlapped[i].get_name().begins_with("wall_")):
			_handle_wall_collision(overlapped[i])
		if(overlapped[i].get_name().begins_with("car_")):
			var otherCar = overlapped[i].get_parent()
			if(otherCar != self):
				_handle_car_collision(otherCar)

func _taunt(message):
	tauntTimer = 0
	tauntLabel.set_bbcode("[center]" + message + "[/center]")
	tauntLabel.show()

func _taunt_random(messages):
	if(tauntTimer < tauntPeriod):
		return
	randomize()
	_taunt(messages[randi()%messages.size()])

func _get_touched_nodes(name):
	var nodes = []
	var overlappedBodies = roadChecker.get_overlapping_bodies()
	for i in range(0, overlappedBodies.size()):
		if(overlappedBodies[i].get_name().begins_with(name)):
			nodes.append(overlappedBodies[i])
	return nodes

func _check_road():
	return _get_touched_nodes("road_").size() > 0

#direction car is facing
func get_forward_direction():
	return -Vector2(sin(facingAngle), cos(facingAngle))

#direction to car's right
func get_right_direction():
	var forward = get_forward_direction()
	return Vector2(-forward.y, forward.x)

func _handle_car_collision(otherCar):
	var diff = otherCar.get_pos() - get_pos()
	var collisionNormal = diff.normalized()
	var penetrationDepth = colliderRadius - diff.length()
	if(penetrationDepth > 0):
		set_pos(get_pos() - collisionNormal * penetrationDepth)
		var vellDiff = velocity - otherCar.velocity
		velocity -= collisionNormal * vellDiff.dot(collisionNormal) * 1.5
		if(impactSoundTimer > minImpactSoundTime):
			impactSoundTimer = 0
			samplePlayer.play("impact")

#push car out of walls
func _handle_wall_collision(wall):
	var polygonNode = wall.get_node("collision_polygon")
	var polygon = polygonNode.get_polygon()
	var wallMatrix = polygonNode.get_relative_transform_to_parent(get_tree().get_root().get_node("root"))
	var collisionPoint = _get_closest_point_on_polygon(polygon, wallMatrix, get_pos())
	var pos = get_pos()
	var collisionNormal = (collisionPoint-pos).normalized()
	var penetrationDist = colliderRadius - (collisionPoint-pos).length()
	if(penetrationDist > 0):
		set_pos(pos - collisionNormal * penetrationDist)
		velocity -= collisionNormal * velocity.dot(collisionNormal) * 1.5	#bounce a little
		
		if(abs(velocity.dot(collisionNormal)) > speedForImpactSount):
			samplePlayer.play("impact")

#returns the closest point on the surface of "polygon" to a given point "to"
func _get_closest_point_on_polygon(polygon, polyTransMatrix, to):
	#transform to polygon space (this accounts for the wall's position, rotation, and scale)
	var polySpaceTo = to - polyTransMatrix.get_origin()
	polySpaceTo = polySpaceTo.rotated(-polyTransMatrix.get_rotation())
	polySpaceTo = polySpaceTo / polyTransMatrix.get_scale()
	
	#find the closest point on each line segment, and pick the closest of them
	var closestPoint
	var distSqToClosest = 3.402823e+38
	for i in range(0, polygon.size()):
		var potentialPoint = _get_closest_point_on_line_segment(polygon[i], polygon[(i+1)%polygon.size()], polySpaceTo)
		var distSq = polySpaceTo.distance_squared_to(potentialPoint)
		if(distSq < distSqToClosest):
			closestPoint = potentialPoint
			distSqToClosest = distSq
	
	#transform result back to world space
	closestPoint = closestPoint * polyTransMatrix.get_scale()
	closestPoint = closestPoint.rotated(polyTransMatrix.get_rotation())
	closestPoint = closestPoint + polyTransMatrix.get_origin()
	
	return closestPoint
	
#returns the closest point on line segment "p1" - "p2" to point "to"
func _get_closest_point_on_line_segment(p1, p2, to):
	var difference = p2 - p1
	var diffNorm = difference.normalized()
	var dotProduct = diffNorm.dot(to-p1)
	
	if(dotProduct < 0):
		return p1
	if(dotProduct*dotProduct > difference.length_squared()):
		return p2
		
	var projectedPoint = p1 + diffNorm * dotProduct
	return projectedPoint

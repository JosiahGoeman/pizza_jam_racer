extends CanvasLayer

export var backgroundSpinSpeed = 1
export var lightnessInc = 2

onready var spinnyBackground = get_node("spinny_background")
onready var music = get_node("music")
onready var trumpSprite = get_node("drumpf")

var spriteLightness = -3

func _ready():
	music.play("fight")
	trumpSprite.set_modulate(Color(spriteLightness, spriteLightness, spriteLightness))
	set_process(true)

func _process(delta):
	spinnyBackground.set_rot(spinnyBackground.get_rot() + backgroundSpinSpeed * delta)
	
	spriteLightness += lightnessInc * delta
	if(spriteLightness > 1):
		spriteLightness = 1
	trumpSprite.set_modulate(Color(spriteLightness, spriteLightness, spriteLightness))

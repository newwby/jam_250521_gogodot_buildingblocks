
class_name GameTile
extends GameCell

var tile_size = Vector2(320,320)

onready var tile_collision = $TileArea/CollisionArea
onready var test_tile_sprite = $DebugSprite


###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_setup()
	tile_setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


###############################################################################


func _on_TileArea_mouse_entered():
	cell_highlight(true, false)


func _on_TileArea_mouse_exited():
	cell_highlight(false, false)


###############################################################################


# all basic blocks follow the same setup
func tile_setup():
	var tile_center = tile_size/2
	test_tile_sprite.rect_size = tile_size
	tile_collision.position = tile_center
	tile_collision.shape.set("extents", tile_center)


func sprite_setup():
	sprites = [
		test_tile_sprite,
	]
	for i in sprites:
		i.color = Color(0,0.5,0,1)

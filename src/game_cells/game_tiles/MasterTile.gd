
class_name GameTile
extends GameCell

signal highlight_new_tile(identity)

var array_pos = Vector2(150,150)
var tile_size = Vector2(320,320)

var block_child

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
	cell_highlight(true, true, false, true)
	global_var.last_highlighted_tile = self
	emit_signal("highlight_new_tile", self)

func _on_TileArea_mouse_exited():
	cell_highlight(false, true, false, true)


# need to end highlighting if a new tile is highlighted
func _on_Tile_highlight_new_tile(identity):
	if identity != self:
		_on_TileArea_mouse_exited()


# need to end highlighting if a block is grabbed
func _on_Tile_block_grabbed():
		_on_TileArea_mouse_exited()

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
		i.color = Color(0,0.5,0,0)

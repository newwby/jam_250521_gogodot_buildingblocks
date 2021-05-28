extends Node2D

class_name GameBlock

var array_pos = Vector2(150,150)
var block_size = Vector2(100,100)

var use_debug_sprite = true
var show_debug_array_label = true

var ghost_image = true

onready var test_block_sprite = $ColorRect
#onready var block_sprite = $ColorRect
onready var block_collision = $BlockArea/CollisionArea

onready var debug_label_array_pos = $DebugHandler/DebugLabel_ArrayPos

###############################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	block_setup()

func block_setup():
	var block_center = block_size/2
	test_block_sprite.color = Color(1,0,0,1)
	# set block size
	test_block_sprite.rect_size = block_size
	block_collision.position = block_center
	block_collision.shape.set("extents", block_center)
	if show_debug_array_label:
		# set and center debug label
		debug_label_array_pos.text = str(array_pos)
		debug_label_array_pos.rect_scale *= (block_size/100)
		debug_label_array_pos.rect_position = block_center
		debug_label_array_pos.rect_position.x -= debug_label_array_pos.rect_position.x/2
		debug_label_array_pos.rect_position.y -= debug_label_array_pos.rect_position.y/8
	debug_label_array_pos.visible = show_debug_array_label
	test_block_sprite.visible = use_debug_sprite

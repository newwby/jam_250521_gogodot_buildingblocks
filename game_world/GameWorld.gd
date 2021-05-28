class_name GameWorld
extends Node

const TestBlock = preload("res://game_blocks/master_block.tscn")

var tile_pixel_size = 100
var block_pixel_buffer = tile_pixel_size/10
var world_origin = Vector2(0,0)
var world_boundary = Vector2(2000,2000)
var horizontal_edge = fmod(world_boundary.x, tile_pixel_size)
var vertical_edge = fmod(world_boundary.y, tile_pixel_size)
var world_tile_dict = {}
var world_block_dict = {}

var block_size = tile_pixel_size - block_pixel_buffer
var block_row_length = (world_boundary.x/tile_pixel_size)
var block_column_length = (world_boundary.y/tile_pixel_size)
var total_blocks = block_row_length * block_column_length

onready var background = $Background
onready var block_parent = $block_parent


###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	establish_background()
	if global_var.enable_world_spawn_log: print("total blocks ", total_blocks)
	add_all_blocks()


func _input(event):
	if event is InputEventMouseMotion and global_var.grabbed_block is GameBlock:
		global_var.grabbed_block.position = event.position

###############################################################################


func _on_BlockGrabbed():
	pass


func _on_BlockReleased():
	pass


###############################################################################


func establish_background():
	background.rect_size = world_boundary
	background.color = Color( 0, 0.39, 0, 1 )

func add_all_blocks():
	var base_horizontal_buffer = horizontal_edge/2
	var base_vertical_buffer = vertical_edge/2
	var spawn_at = Vector2(base_horizontal_buffer, base_vertical_buffer)
	var final_row_cell = world_boundary.x-tile_pixel_size
	var final_column_cell = world_boundary.y-tile_pixel_size
	var total_blocks_spawned = 0
	var current_array_pos = Vector2(0,0)
	
	while (current_array_pos.x*tile_pixel_size) <= final_row_cell:
		while spawn_at.y <= final_column_cell:
			add_new_block(spawn_at, current_array_pos)
			total_blocks_spawned += 1
			current_array_pos.y += 1
			spawn_at.y += tile_pixel_size
		current_array_pos.x += 1
		spawn_at.x += tile_pixel_size
		spawn_at.y = base_vertical_buffer
		current_array_pos.y = 0
	
	if global_var.enable_world_spawn_log: print("done! spawned ", total_blocks_spawned, " blocks!")

func add_new_block(spawn_loc, given_array_pos):
	var NewBlockInstance = TestBlock.instance()
	NewBlockInstance.block_size = Vector2(block_size, block_size)
	NewBlockInstance.array_pos = given_array_pos
	NewBlockInstance.position = Vector2(spawn_loc.x+(block_pixel_buffer/2), spawn_loc.y+(block_pixel_buffer/2))
	NewBlockInstance.connect("block_grabbed",self,"_on_BlockGrabbed")
	NewBlockInstance.connect("block_released",self,"_on_BlockReleased")
	block_parent.add_child(NewBlockInstance)
	world_block_dict[given_array_pos] = NewBlockInstance


###############################################################################


func _on_GameViewCamera_camera_movement(movement_vector):
	if global_var.grabbed_block is GameBlock:
		global_var.grabbed_block.position += movement_vector

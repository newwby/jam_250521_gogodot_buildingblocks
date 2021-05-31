class_name GameWorld
extends Node

const TestBlock = preload("res://src/game_cells/game_blocks/MasterBlock.tscn")
const BasicTile = preload("res://src/game_cells/game_tiles/MasterTile.tscn")

enum BlockSpawnType {
	AT_VECTOR,POSITION,
	AT_RANDOM_TILE,
}

enum BlockType {
	DEBUG_BASIC_BLOCK,
}

var cell_pixel_size = 100
var block_pixel_buffer = cell_pixel_size/10
var world_origin = Vector2(0,0)
var world_boundary = Vector2(2000,2000)
var horizontal_edge = fmod(world_boundary.x, cell_pixel_size)
var vertical_edge = fmod(world_boundary.y, cell_pixel_size)
var world_tile_dict = {}
var world_block_dict = {}

var cell_size = cell_pixel_size - block_pixel_buffer
var cell_tile_size = cell_pixel_size
var cell_row_length = (world_boundary.x/cell_pixel_size)
var cell_column_length = (world_boundary.y/cell_pixel_size)
var total_cells = cell_row_length * cell_column_length

onready var background = $Background
onready var tile_parent = $tile_parent
onready var block_parent = $block_parent


###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	if global_var.enable_world_spawn_log: print("total cells to spawn:", total_cells)
	add_all_tiles_at_vector_position()
	#add_random_block_loop(4)
	add_random_block_loop(4, BlockSpawnType.AT_RANDOM_TILE)


func _process(delta):
	_process_debug_check(delta)


# game world handles the debug command if accessed
func _process_debug_check(_dt):
	if Input.is_action_just_released("debugging_command")\
	and global_var.enable_debug_command_button():
		print("debug!")
		get_random_array_pos()


func _input(event):
	if event is InputEventMouseMotion and global_var.grabbed_block is GameBlock:
		global_var.grabbed_block.position = event.position

###############################################################################


##########################################################################


# generates a random array position and returns the game tile at that position
func get_random_array_pos() -> GameTile:
	var random_row = global_var.return_new_random(0, cell_row_length)
	var random_column = global_var.return_new_random(0, cell_column_length)
	return get_array_pos(random_row, random_column)


# returns the game tile at the array position given
func get_array_pos(x: int, y: int) -> GameTile:
	return world_tile_dict[Vector2(x,y)]


# function that spawns a new block at a specific tile
func add_new_block_at_tile(spawn_tile: GameTile, block_type):
	var tile_array_pos = spawn_tile.array_pos
	var NewBlockInstance = TestBlock.instance()
	
	match BlockType:
		BlockType.DEBUG_BASIC_BLOCK:
			pass
			# already set NewBlockInstance = TestBlock.instance() so skip
			# just retained for code structure/my own reference
	
	# set the dimensions of the newly spawned block
	# TODO configure block size handling for sprites
	NewBlockInstance.block_size = Vector2(cell_size, cell_size)
	
	# Set block's tile parent and then position block accordingly
	NewBlockInstance.tile_parent = spawn_tile
	spawn_tile.block_child = NewBlockInstance
	block_parent.add_child(NewBlockInstance)
	NewBlockInstance.connect("block_grabbed",spawn_tile,"_on_Tile_block_grabbed")
	NewBlockInstance.update_position_on_move()


# function to spawn in tile cells
func add_new_tile_at_position(spawn_loc, given_array_pos):
	var NewTileInstance = BasicTile.instance()
	NewTileInstance.tile_size = Vector2(cell_tile_size, cell_tile_size)
	NewTileInstance.array_pos = given_array_pos
	NewTileInstance.position = Vector2(spawn_loc.x, spawn_loc.y)
	#NewTileInstance.position = Vector2(spawn_loc.x+(block_pixel_buffer/2), spawn_loc.y+(block_pixel_buffer/2))
	
	block_parent.add_child(NewTileInstance)
	world_tile_dict[given_array_pos] = NewTileInstance


# populate entire game field with tiles
func add_all_tiles_at_vector_position():
	var spawn_at = Vector2.ZERO
	var final_row_cell = world_boundary.x-cell_pixel_size
	var final_column_cell = world_boundary.y-cell_pixel_size
	var total_cells_spawned = 0
	var current_array_pos = Vector2(0,0)
	
	while (current_array_pos.x*cell_pixel_size) <= final_row_cell:
		while spawn_at.y <= final_column_cell:
			add_new_tile_at_position(spawn_at, current_array_pos)
			total_cells_spawned += 1
			current_array_pos.y += 1
			spawn_at.y += cell_pixel_size
		current_array_pos.x += 1
		spawn_at.x += cell_pixel_size
		spawn_at.y = 0
		current_array_pos.y = 0
	
	if global_var.enable_world_spawn_log: print("done! spawned ", total_cells_spawned, " tiles!")


# function to add a number of blocks
func add_random_block_loop(number_of_blocks_to_spawn, spawn_type = BlockSpawnType.AT_VECTOR):
	var blocks_remaining_to_spawn = number_of_blocks_to_spawn
	
	# TODO need to add code for checking the blocks aren't overlapping
	
	while blocks_remaining_to_spawn > 0:
		if spawn_type == BlockSpawnType.AT_VECTOR:
			add_random_block_at_position()
		elif spawn_type == BlockSpawnType.AT_RANDOM_TILE:
			add_new_block_at_tile(get_random_array_pos(), BlockType.DEBUG_BASIC_BLOCK)
			#TODO write new func to spawn block as child of given node
		blocks_remaining_to_spawn -= 1
	
###############################################################################

# generates a random vector position to spawn block
# used for testing, now defunct
func add_random_block_at_position():
		var random_row = global_var.return_new_random(0, cell_row_length)
		var random_column = global_var.return_new_random(0, cell_column_length)
		# TODO need to add different global files for preload (string/debug/func)
	
		var base_horizontal_buffer = horizontal_edge/2
		var base_vertical_buffer = vertical_edge/2
		var spawn_at = Vector2(\
		(random_row*cell_size)+base_horizontal_buffer,\
		(random_column*cell_size)+base_vertical_buffer)
	
		add_new_block_at_position(spawn_at, Vector2(random_row, random_column))

# function to spawn in block cells
# used for testing, now defunct
func add_new_block_at_position(spawn_loc, given_array_pos):
	var NewBlockInstance = TestBlock.instance()
	NewBlockInstance.block_size = Vector2(cell_size, cell_size)
	NewBlockInstance.array_pos = given_array_pos
	NewBlockInstance.position = Vector2(spawn_loc.x+(block_pixel_buffer/2), spawn_loc.y+(block_pixel_buffer/2))
	
	# defunct code, set on node in ui instead
	# NewBlockInstance.connect("block_grabbed",self,"_on_BlockGrabbed")
	# NewBlockInstance.connect("block_released",self,"_on_BlockReleased")
	
	block_parent.add_child(NewBlockInstance)
	world_block_dict[given_array_pos] = NewBlockInstance


# populate entire game field with only blocks
# this function was for prototyping and is now defunct
func add_all_blocks_by_vector_position():
	var base_horizontal_buffer = horizontal_edge/2
	var base_vertical_buffer = vertical_edge/2
	var spawn_at = Vector2(base_horizontal_buffer, base_vertical_buffer)
	var final_row_cell = world_boundary.x-cell_pixel_size
	var final_column_cell = world_boundary.y-cell_pixel_size
	var total_cells_spawned = 0
	var current_array_pos = Vector2(0,0)
	
	while (current_array_pos.x*cell_pixel_size) <= final_row_cell:
		while spawn_at.y <= final_column_cell:
			add_new_block_at_position(spawn_at, current_array_pos)
			total_cells_spawned += 1
			current_array_pos.y += 1
			spawn_at.y += cell_pixel_size
		current_array_pos.x += 1
		spawn_at.x += cell_pixel_size
		spawn_at.y = base_vertical_buffer
		current_array_pos.y = 0
	
	if global_var.enable_world_spawn_log: print("done! spawned ", total_cells_spawned, " blocks!")

# adjusts the debug background
# this function was for prototyping and is now defunct
func establish_background():
	background.rect_size = world_boundary
	background.color = Color( 0, 0.39, 0, 1 )

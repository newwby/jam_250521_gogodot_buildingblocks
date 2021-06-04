class_name GameWorld
extends Node

signal update_time(current_hour, current_minute, day_phase)
signal update_speed(new_speed)
signal block_update()
signal pass_mulch_score(new_score)

# TODO temp delete me
var total_mulch_score = 0

const TestBlock = preload("res://src/game_cells/game_blocks/MasterBlock.tscn")
const BasicTile = preload("res://src/game_cells/game_tiles/MasterTile.tscn")

const BoundaryBlock = preload("res://src/game_cells/game_blocks/technical_blocks/GameBoundaryBlock.tscn")
const ShrubBlock = preload("res://src/game_cells/game_blocks/ShrubBlock.tscn")
const BranchBlock = preload("res://src/game_cells/game_blocks/BranchBlock.tscn")
const LeafBlock = preload("res://src/game_cells/game_blocks/LeafBlock.tscn")

# hour, minute
const INITIAL_GAME_TIME = Vector2(6,0)
# no need for day or night constants
# for day we just use upper bound of morning and lower bound of evening
# for night we just use upper bound of evening and lower bound of morning
const DAY_BOUNDS_MORNING = Vector2(5,7)
const DAY_BOUNDS_EVENING = Vector2(19,21)
# weather variability modifiers
const SUN_INTENSITY_GAIN_OR_LOSS = 0.0075
const NORMAL_WEATHER_VARIABILITY_FLOOR = 0.5
const NORMAL_WEATHER_VARIABILITY_CEILING = 1.0
# game speed is the wait time of GameTimeTimer
const GAME_SPEED_NORMAL = 0.2
const GAME_SPEED_ACCELERATED = GAME_SPEED_NORMAL/5
const GAME_SPEED_MAXIMUM = GAME_SPEED_NORMAL/10
const GAME_SPEED_DEVELOPER = GAME_SPEED_NORMAL/30

enum DayPhase {
	MORNING,
	DAY,
	EVENING,
	NIGHT,
}

enum GameSpeed {
	NORMAL,
	ACCELERATED,
	MAXIMUM,
	DEVELOPER,
}

enum BlockSpawnType {
	AT_VECTOR,POSITION,
	AT_RANDOM_TILE,
}

var world_hour = 0
var world_minute = 0
var current_day_phase
var current_game_speed
var sun_intensity = 1.0
var sun_intensity_variability = 1.0

var cell_pixel_size = 64
var block_pixel_buffer = cell_pixel_size/10
var world_origin = Vector2(0,0)
var world_boundary = Vector2(2000,1500)
var horizontal_edge = fmod(world_boundary.x, cell_pixel_size)
var vertical_edge = fmod(world_boundary.y, cell_pixel_size)
var world_tile_dict = {}
var world_block_dict = {}

var cell_size = cell_pixel_size - block_pixel_buffer
var cell_tile_size = cell_pixel_size
var cell_row_length = (world_boundary.x/cell_pixel_size)
var cell_column_length = (world_boundary.y/cell_pixel_size)
var cell_row_midpoint = int(cell_row_length/2)
var cell_column_midpoint = int(cell_column_length/2)
var total_cells = cell_row_length * cell_column_length

var is_game_time_setup = false

onready var background = $Background
onready var tile_parent = $tile_parent
onready var block_parent = $block_parent
onready var GameTimer = $GameTimeTimer
onready var GameTimeCooldownTimer = $SpeedChangeCooldownTimer

onready var AudioHandler = $AudioSE

###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	if global_var.enable_world_spawn_log: print("total cells to spawn:", total_cells)
	add_all_tiles_at_vector_position()
	starter_block_setup()
	
	# defunct testing conditions
	#add_random_block_loop(4)
	#add_random_block_loop(4, BlockSpawnType.AT_RANDOM_TILE)
	
	# relies on parent being GameViewCamera (though nothing would happen if so?)
	yield(get_parent(), "ready")
	GameTime_setup()


func _process(delta):
	_process_debug_check(delta)
	_process_speed_input_check()


# game world handles the debug command if accessed
func _process_debug_check(_dt):
	if Input.is_action_pressed("debugging_command")\
	and global_var.enable_debug_command_button:
		_on_GameTimeTimer_timeout()


# check if player has tried to update game time
func _process_speed_input_check():
	if GameTimeCooldownTimer.is_stopped():
		if Input.is_action_just_released("game_speed_1x"):
			update_game_speed(GameSpeed.NORMAL)
			GameTimeCooldownTimer.start()
		elif Input.is_action_just_released("game_speed_2x"):
			update_game_speed(GameSpeed.ACCELERATED)
			GameTimeCooldownTimer.start()
		elif Input.is_action_just_released("game_speed_3x"):
			update_game_speed(GameSpeed.MAXIMUM)
			GameTimeCooldownTimer.start()
		# only allow if developer speed mode is enabled
		elif global_var.enable_developer_speed_mode\
		and Input.is_action_just_released("game_speed_4x_devonly"):
			update_game_speed(GameSpeed.DEVELOPER)
			GameTimeCooldownTimer.start()


func _input(event):
	if event is InputEventMouseMotion and global_var.grabbed_block is GameBlock:
		global_var.grabbed_block.position = event.position

###############################################################################


# update the game time
func _on_GameTimeTimer_timeout():	
	# update progression of time
	update_time()
	# set day phase according to value of world hour
	update_day_phase()
	# pass all this information to GameViewCamera
	emit_signal("update_time", world_hour, world_minute, current_day_phase)

##########################################################################


func starter_block_setup():
	# SPAWN A CENTER MAP BLOCK
	add_new_block_at_tile( \
	world_tile_dict[Vector2(cell_row_midpoint,cell_column_midpoint)], \
	global_var.BlockType.SHRUB_BLOCK)


func GameTime_setup():
	world_hour = INITIAL_GAME_TIME.x
	world_minute = INITIAL_GAME_TIME.y
	update_game_speed(GameSpeed.ACCELERATED)
	_on_GameTimeTimer_timeout()


# progress time as GameTime timer expires
func update_time():
	# hour increases unless the day is finished (at 24, aka reset to 0)
	world_minute += 1
	# update the sun every minute
	update_sun()
	# if its a new hour update blocks
	if world_minute >= 60:
		world_minute = 0
		emit_signal("block_update")
		if world_hour >= 24:
			world_hour = 0
			# new day, set new weather
			set_random_daily_weather()
		else:
			world_hour += 1


func update_day_phase():
	# set day phase according to value of world hour
	# hour 0 to 4 is night time
	if world_hour < DAY_BOUNDS_MORNING.x:
		current_day_phase = DayPhase.NIGHT
	# hour 5 to 7 is morning
	elif world_hour >= DAY_BOUNDS_MORNING.x and world_hour <= DAY_BOUNDS_MORNING.y:
		current_day_phase = DayPhase.MORNING
	# hour 8 to 18 is day time
	elif world_hour > DAY_BOUNDS_MORNING.y and world_hour < DAY_BOUNDS_EVENING.x:
		current_day_phase = DayPhase.DAY
	# hour 19 to 21 is evening
	elif world_hour >= DAY_BOUNDS_EVENING.x and world_hour <= DAY_BOUNDS_EVENING.y:
		current_day_phase = DayPhase.EVENING
	# after hour 22 is night time
	elif world_hour > DAY_BOUNDS_EVENING.y:
		current_day_phase = DayPhase.NIGHT
	
	# NOTE
	# for day we just use upper bound of morning and lower bound of evening
	# for night we just use upper bound of evening and lower bound of morning


# the sun is a key game mechanic with a measured 'intensity'
# from morning onward the intensity grows
# from evening onward the intensity falls
# it has a maximum ceiling of 1.0 and a minimum floor of 0.0
# sun is modified by weather (see set_random_daily_weather func)
# sun is updated every passed minute
func update_sun():
	# the day phase affects the gain/loss of sun intensity
	# day and night have twice the effect
	# weather influences the rate of gain/loss
	match current_day_phase:
		DayPhase.MORNING:
			sun_intensity += (SUN_INTENSITY_GAIN_OR_LOSS) * sun_intensity_variability
		DayPhase.DAY:
			sun_intensity += (SUN_INTENSITY_GAIN_OR_LOSS*2) * sun_intensity_variability
		DayPhase.EVENING:
			sun_intensity -= (SUN_INTENSITY_GAIN_OR_LOSS) / sun_intensity_variability
		DayPhase.NIGHT:
			sun_intensity -= (SUN_INTENSITY_GAIN_OR_LOSS*2) / sun_intensity_variability
	
	# TODO just look up how to add limits to the variable
	if sun_intensity > 1.0:
		sun_intensity = 1.0
	elif sun_intensity < 0:
		sun_intensity = 0
		


# pass a new speed value from GameSpeed enum to this function
# sets the gametimer wait time according to constants
func update_game_speed(new_speed):
	# for each speed
	# update GameTimer cycling speed
	# update variable record of speed
	# emit a signal so UI can update
	if new_speed == GameSpeed.NORMAL:
		GameTimer.wait_time = GAME_SPEED_NORMAL
		current_game_speed = GameSpeed.NORMAL
		emit_signal("update_speed", GameSpeed.NORMAL)
	elif new_speed == GameSpeed.ACCELERATED:
		GameTimer.wait_time = GAME_SPEED_ACCELERATED
		current_game_speed = GameSpeed.ACCELERATED
		emit_signal("update_speed", GameSpeed.ACCELERATED)
	elif new_speed == GameSpeed.MAXIMUM:
		GameTimer.wait_time = GAME_SPEED_MAXIMUM
		current_game_speed = GameSpeed.MAXIMUM
		emit_signal("update_speed", GameSpeed.MAXIMUM)
	# speed settings for dev mode only
	elif global_var.enable_developer_speed_mode\
	and new_speed == GameSpeed.DEVELOPER:
		GameTimer.wait_time = GAME_SPEED_DEVELOPER
		current_game_speed = GameSpeed.DEVELOPER
		emit_signal("update_speed", GameSpeed.DEVELOPER)


# there is some randomness to sun intensity based on the day's weather
# it skews toward maximum effect though
# weather effects slow gain of sun intensity and speed loss of sun intensity
func set_random_daily_weather():
	var weather_variability_modifier = global_var.return_new_random(5, 15)
	# make sure it doesn't fault and divide by 0
	weather_variability_modifier /= 10 \
	if weather_variability_modifier > 0 else 0
	# check values are within expected bounds and set if not
	if weather_variability_modifier > NORMAL_WEATHER_VARIABILITY_CEILING:
		weather_variability_modifier = NORMAL_WEATHER_VARIABILITY_CEILING
	elif weather_variability_modifier < NORMAL_WEATHER_VARIABILITY_FLOOR:
		weather_variability_modifier = NORMAL_WEATHER_VARIABILITY_FLOOR
	sun_intensity_variability = weather_variability_modifier


# generates a random array position and returns the game tile at that position
func get_random_array_pos() -> GameTile:
	var random_row = global_var.return_new_random(0, cell_row_length)
	var random_column = global_var.return_new_random(0, cell_column_length)
	return get_array_pos(random_row, random_column)


# returns the game tile at the array position given
func get_array_pos(x: int, y: int):
	if not x < 0 or not y < 0:
		return world_tile_dict[Vector2(x,y)]
	else:
		return world_tile_dict[Vector2(0,0)]


func block_request_to_add_new_block(array_position, block_type):
	var tile_position = get_array_pos(array_position.x, array_position.y)
	if validate_tile_is_empty(tile_position):
		add_new_block_at_tile(tile_position, block_type)


func validate_tile_is_empty(tile_to_check: GameTile):
	if tile_to_check.block_child == null:
		return true
	else:
		return false


# function that spawns a new block at a specific tile
func add_new_block_at_tile(spawn_tile: GameTile, given_block_type):
	var NewBlockInstance = TestBlock.instance()
	
	match given_block_type:
		# basic blocks use a color rect and show array position
		global_var.BlockType.DEBUG_BASIC_BLOCK:
			NewBlockInstance.use_debug_sprite = true
			NewBlockInstance.show_debug_array_label = true
			# already set NewBlockInstance = TestBlock.instance() so skip
			# just retained for code structure/my own reference
		global_var.BlockType.BOUNDARY_BLOCK:
			NewBlockInstance = BoundaryBlock.instance()
		global_var.BlockType.SHRUB_BLOCK:
			NewBlockInstance = ShrubBlock.instance()
		global_var.BlockType.BRANCH_BLOCK:
			NewBlockInstance = BranchBlock.instance()
		global_var.BlockType.LEAF_BLOCK:
			NewBlockInstance = LeafBlock.instance()
			var temp_var = NewBlockInstance.connect("mulch_score", self, "_on_Mulch_Score")
	
	# set the dimensions of the newly spawned block
	# TODO configure block size handling for sprites
	NewBlockInstance.block_size = Vector2(cell_size, cell_size)
	
	# Set block's tile parent and then position block accordingly
	NewBlockInstance.set_new_tile_parent(spawn_tile)
	var _discard = self.connect("block_update", NewBlockInstance,"_on_BlockUpdate")
	_discard = NewBlockInstance.connect("spawn_new_block", self, "block_request_to_add_new_block")
	block_parent.add_child(NewBlockInstance)
	play_random_audio()

# function to spawn in tile cells
func add_new_tile_at_position(spawn_loc, given_array_pos):
	var NewTileInstance = BasicTile.instance()
	NewTileInstance.tile_size = Vector2(cell_tile_size, cell_tile_size)
	NewTileInstance.array_pos = given_array_pos
	NewTileInstance.position = Vector2(spawn_loc.x, spawn_loc.y)
	#NewTileInstance.position = Vector2(spawn_loc.x+(block_pixel_buffer/2), spawn_loc.y+(block_pixel_buffer/2))
	
	tile_parent.add_child(NewTileInstance)
	world_tile_dict[given_array_pos] = NewTileInstance
	# if the game world's parent is WorldCamera then additionally
	# connected gameTile highlight function to the label on viewport UI
	var CurrentWorldCamera = self.get_parent() if self.get_parent() is WorldCamera else null
	if CurrentWorldCamera != null:
		NewTileInstance.connect("highlight_new_tile", \
		CurrentWorldCamera, "_onUpdateArrayPosLabel")


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
			# defunct, remove
			#add_random_block_at_position()
			pass
		elif spawn_type == BlockSpawnType.AT_RANDOM_TILE:
			add_new_block_at_tile(get_random_array_pos(), global_var.BlockType.DEBUG_BASIC_BLOCK)
			#TODO write new func to spawn block as child of given node
		blocks_remaining_to_spawn -= 1


func _on_Mulch_Score():
		total_mulch_score += 1
		emit_signal("pass_mulch_score", total_mulch_score)
	
	
func play_random_audio():
	var audio_log = AudioHandler.get_children()
	var random_choice = global_var.return_new_random(0, audio_log.size())
	if global_var.enable_audio_debug_logging: print("full audio log: ", audio_log)
	if global_var.enable_audio_debug_logging: print("categories are: ", audio_log.size())
	if global_var.enable_audio_debug_logging: print("numberwang is: ", random_choice)
	audio_log[random_choice].play()
	
###############################################################################



## generates a random vector position to spawn block
## used for testing, now defunct
#func add_random_block_at_position():
#		var random_row = global_var.return_new_random(0, cell_row_length)
#		var random_column = global_var.return_new_random(0, cell_column_length)
#		# TODO need to add different global files for preload (string/debug/func)
#
#		var base_horizontal_buffer = horizontal_edge/2
#		var base_vertical_buffer = vertical_edge/2
#		var spawn_at = Vector2( \
#		(random_row*cell_size)+base_horizontal_buffer, \
#		(random_column*cell_size)+base_vertical_buffer)
#
#		add_new_block_at_position(spawn_at, Vector2(random_row, random_column))
#
#
## function to spawn in block cells
## used for testing, now defunct
#func add_new_block_at_position(spawn_loc, given_array_pos):
#	var NewBlockInstance = TestBlock.instance()
#	NewBlockInstance.block_size = Vector2(cell_size, cell_size)
#	NewBlockInstance.array_pos = given_array_pos
#	NewBlockInstance.position = Vector2(spawn_loc.x+(block_pixel_buffer/2), spawn_loc.y+(block_pixel_buffer/2))
#
#	# defunct code, set on node in ui instead
#	# NewBlockInstance.connect("block_grabbed",self,"_on_BlockGrabbed")
#	# NewBlockInstance.connect("block_released",self,"_on_BlockReleased")
#
#	block_parent.add_child(NewBlockInstance)
#	world_block_dict[given_array_pos] = NewBlockInstance
#
## populate entire game field with only blocks
## this function was for prototyping and is now defunct
#func add_all_blocks_by_vector_position():
#	var base_horizontal_buffer = horizontal_edge/2
#	var base_vertical_buffer = vertical_edge/2
#	var spawn_at = Vector2(base_horizontal_buffer, base_vertical_buffer)
#	var final_row_cell = world_boundary.x-cell_pixel_size
#	var final_column_cell = world_boundary.y-cell_pixel_size
#	var total_cells_spawned = 0
#	var current_array_pos = Vector2(0,0)
#
#	while (current_array_pos.x*cell_pixel_size) <= final_row_cell:
#		while spawn_at.y <= final_column_cell:
#			add_new_block_at_position(spawn_at, current_array_pos)
#			total_cells_spawned += 1
#			current_array_pos.y += 1
#			spawn_at.y += cell_pixel_size
#		current_array_pos.x += 1
#		spawn_at.x += cell_pixel_size
#		spawn_at.y = base_vertical_buffer
#		current_array_pos.y = 0
#
#	if global_var.enable_world_spawn_log: print("done! spawned ", total_cells_spawned, " blocks!")
#
## adjusts the debug background
## this function was for prototyping and is now defunct
#func establish_background():
#	background.rect_size = world_boundary
#	background.color = Color( 0, 0.39, 0, 1 )

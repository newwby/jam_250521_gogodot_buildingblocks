extends Node

signal set_camera_bounding(new_bounding, fixed_bounds)

var current_camera_bounding = CameraBounds.BOUNDING_VIEWPORT
var camera_bounding_fixed = Vector2(0,0)
enum CameraBounds {
	BOUNDING_VIEWPORT,
	BOUNDING_FIXED,
	}


onready var World = $InterfaceMaster/GameView_Container/Viewport/GameViewCamera/World
onready var GameCamera = $InterfaceMaster/GameView_Container/Viewport/GameViewCamera
onready var DebugLabel1 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel1
onready var DebugLabel2 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel2
onready var DebugLabel3 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel3

###############################################################################
	
# Called when the node enters the scene tree for the first time.
func _ready():
	#set_camera_limits()
	#set_camera_starting_pos()
	_on_Game_MainLoop_set_camera_bounding()
	#pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_var.enable_debug_mode:
		debug_process_camera_coords()
	mouse_drag_input()
	mouse_press_input()
	

func _input(event):
	
	if event is InputEventMouseMotion:
		global_var.button_held_ticks = 0
		global_var.mouse_moving = true
	else:
		global_var.mouse_moving = false


func _unhandled_input(event):
	pass


###############################################################################

func mouse_drag_input():
	pass


###############################################################################

# update debug labels for camera co-ordinates
func debug_process_camera_coords():
	DebugLabel1.text = "Camera Position X = " + str(GameCamera.position.x)
	DebugLabel2.text = "Camera Position Y = " + str(GameCamera.position.y)
	DebugLabel3.text = "Camera Zoom Level = " + str(GameCamera.zoom)


###############################################################################

# CAMERA HANDLING FUNCTIONS

# signal is set up to handle on-the-fly changing of camera bounds
func _on_Game_MainLoop_set_camera_bounding(new_bounding = null, fixed_bounds = null):
	if typeof(new_bounding) == TYPE_INT:
		current_camera_bounding = CameraBounds[new_bounding]
	match current_camera_bounding:
		0: # BOUNDING_VIEWPORT
			initialise_viewport_cam()
		1: # BOUNDING_FIXED
			print("Not set up fixed bounding yet")


func initialise_viewport_cam():
	var GameCameraView = $InterfaceMaster/GameView_Container
	#GameCamera.GameViewport = Vector2(GameCameraView.rect_size.x/2, GameCameraView.rect_size.y/2)
	pass
	#GameViewport = 

##############

#45,55 = 1800,2200 pos

func mouse_press_input():
	if Input.is_action_pressed("mouse_click"):
		global_var.button_held_ticks += 1
		if global_var.button_held_ticks == 10 and not global_var.mouse_moving:
			get_block_at_location()
	else:
		global_var.button_held_ticks = 0


func get_block_at_location():
	var mouse_loc = global_var.mouse_last_click_position
	print("position at mouse location is ", mouse_loc)
	print("divided by tile size that is ", mouse_loc/World.tile_pixel_size)
	print("which as an integer becomes ", int(mouse_loc.x/World.tile_pixel_size), ", ", int(mouse_loc.y/World.tile_pixel_size))

func grab_block():
	pass


# ORIGINAL NOTES BELOW
"""
###############################################################################
## MY NOTES
###############################################################################

#########################
## VIEWPORT CONTAINER CALCULATIONS
##################################################
Game view should be Vector2(TL, S) on 16:9 aspect ratio
where:
	TL is true long (S+(L-S/2))
	L is long axis (x desktop, y mobile)
	S is short axis (y desktop, x mobile)
equivalencies:
 Desktop assuming (1920, 1080) resolution (16:9 aspect ratio)
	= GameView (1500, 1080) << left 2/3rds almost-square
	= UIView (420, 1080) << vertical UI/information box

Mobile assuming (750, 1334) resolution (16:9 aspect ratio)
	= GameView (750, 1042) << top 2/3rds almost-square
	= UIView (750, 292) << horizontal UI/information box

#########################
## GAME CONTROLS
##################################################

Menu/Pause/Options = ESC Key on Desktop, Corner Menu Button on Mobile
Move Block = Click and Drag on Desktop, Tap and Hold (0.4s) then Drag on Mobile
Activate Block = Double Click on Desktop, Double Tap on Mobile
Zoom In = Q/PgUp on Desktop, Pinch in on Mobile
Zoom Out = E/PgDown on Desktop, Pinch out on Mobile
Scroll = WASD/ArrowKeys on Desktop, Single Tap Canmera Scroll on Mobile

"""

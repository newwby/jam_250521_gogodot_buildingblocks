extends Node

signal set_camera_bounding(new_bounding, fixed_bounds)

var current_camera_bounding = CameraBounds.BOUNDING_VIEWPORT
var camera_bounding_fixed = Vector2(0,0)
enum CameraBounds {
	BOUNDING_VIEWPORT,
	BOUNDING_FIXED,
	}


onready var World = $GameViewCamera/World
onready var GameCamera = $GameViewCamera
onready var DebugLabel1 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel1
onready var DebugLabel2 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel2
onready var DebugLabel3 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel3
onready var DebugLabel4 = $InterfaceMaster/HBoxContainer/VBoxContainer/CenterContainer/VBoxContainer/debuglabel4

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


###############################################################################

func mouse_drag_input():
	pass


###############################################################################

# update debug labels for camera co-ordinates
func debug_process_camera_coords():
	DebugLabel1.text = "Camera Position X = " + str(GameCamera.position.x)
	DebugLabel2.text = "Camera Position Y = " + str(GameCamera.position.y)
	DebugLabel3.text = "Camera Zoom Level = " + str(GameCamera.zoom)
	#DebugLabel4.text = str($MouseCollider.overlapping)
	#print($MouseCollider.overlapping)

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

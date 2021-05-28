#v1
extends Camera2D
var cam_bounds = {}

const BASE_SCROLL_STRENGTH = 12
var mouse_scroll_strength = BASE_SCROLL_STRENGTH * 2.0
var keyboard_scroll_strength = BASE_SCROLL_STRENGTH

var GameViewport = Vector2(0,0) # this is set/updated when called

var clicked = false
var mouse_last_click_position = Vector2(0,0)
var camera_control_settings = {
	"WASD" : true,
	"Drag" : true,
}
	
onready var GameCamera = self
onready var GameBoundaries = $World/TileMap

###############################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	set_camera_limits()
	set_camera_starting_pos()
	#pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_camera_control_input()
	#pass

###############################################################################

# FUNCTIONS TO HANDLE CAMERA CONTROL


func _input(event):
   # Mouse in viewport coordinates.
	var printstring = ""
	
	# HANDLING MOUSE CLICKS (SO WE KNOW IF BUTTON IS BEING HELD)
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				clicked = true
				if global_var.enable_debug_mode: print("Left button was clicked at ", event.position)
				mouse_last_click_position = event.position
			else:
				clicked = false
				if global_var.enable_debug_mode: print("Left button was released")
			
			printstring = "Mouse Click at: " if clicked else "Mouse Unclick at: "
		
		if global_var.enable_debug_mode: print(printstring, event.position)
	
	# HANDLING MOUSE MOTION WHILST BUTTON IS HELD, FOR DRAGGING THE CAMERA
	elif event is InputEventMouseMotion:
		#print("Mouse Motion at: ", event.position)
		if global_var.is_mouse_clicked and camera_control_settings["Drag"]:
			var viewport = get_viewport()
			var viewport_center = viewport.size / 2
			var direction = mouse_last_click_position - viewport_center
			var scroll_strength = mouse_scroll_strength# * zoom
			#GameCamera.position += scroll_strength * direction.normalized() * zoom
			var position_adjustment = scroll_strength * direction.normalized() * zoom
			GameCamera.position.x = clamp(GameCamera.position.x + position_adjustment.x, cam_bounds["left"]+GameViewport.x, cam_bounds["right"]-GameViewport.x)
			GameCamera.position.y = clamp(GameCamera.position.y + position_adjustment.y, cam_bounds["top"]+GameViewport.y, cam_bounds["bottom"]-GameViewport.y)


func check_camera_control_input():
	if camera_control_settings["WASD"]:
		check_camera_control_wasd_input()


func check_camera_control_wasd_input():
	var scroll_strength = keyboard_scroll_strength * zoom.x
	if Input.is_action_pressed("ui_left"):
		GameCamera.position.x = clamp(GameCamera.position.x - scroll_strength, cam_bounds["left"]+GameViewport.x, cam_bounds["right"]-GameViewport.x)
	if Input.is_action_pressed("ui_right"):
		GameCamera.position.x = clamp(GameCamera.position.x + scroll_strength, cam_bounds["left"]+GameViewport.x, cam_bounds["right"]-GameViewport.x)
	if Input.is_action_pressed("ui_up"):
		GameCamera.position.y = clamp(GameCamera.position.y - scroll_strength, cam_bounds["top"]+GameViewport.y, cam_bounds["bottom"]-GameViewport.y)
	if Input.is_action_pressed("ui_down"):
		GameCamera.position.y = clamp(GameCamera.position.y + scroll_strength, cam_bounds["top"]+GameViewport.y, cam_bounds["bottom"]-GameViewport.y)


func set_camera_limits():
	var map_limits = GameBoundaries.get_used_rect()
	var map_cellsize = GameBoundaries.cell_size
	cam_bounds = {
		"left" : map_limits.position.x * map_cellsize.x,
		"right" : map_limits.end.x * map_cellsize.x,
		"top" : map_limits.position.y * map_cellsize.y,
		"bottom" : map_limits.end.y * map_cellsize.y,
		}
	for cam in [GameCamera]:
		cam.limit_left = cam_bounds["left"]
		cam.limit_right = cam_bounds["right"]
		cam.limit_top = cam_bounds["top"]
		cam.limit_bottom = cam_bounds["bottom"]


func set_camera_starting_pos():
	GameCamera.position.x = cam_bounds["right"]/2
	GameCamera.position.y = cam_bounds["bottom"]/2


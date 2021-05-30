class_name WorldCamera
extends Camera2D

signal camera_movement(movement_vector)

const BASE_SCROLL_STRENGTH = 12
var mouse_scroll_strength = BASE_SCROLL_STRENGTH * 2.0
var keyboard_scroll_strength = BASE_SCROLL_STRENGTH

# Lower cap for the `_zoom_level`.
export var min_zoom := 0.25
# Upper cap for the `_zoom_level`.
export var max_zoom := 2.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
export var zoom_factor := 0.02
# Duration of the zoom's tween animation.
export var zoom_duration := 0.3
# The camera's target zoom level.
var _zoom_level := 1.0 setget _set_zoom_level

var GameViewport = Vector2(0,0) # this is set/updated when called

var camera_control_settings = {
	"WASD" : true,
	"Drag_RMB" : true,
	"Drag_LMB" : false,
}

var game_boundaries_set = false

# these two vars must be initialised or else the camera script will have issues
var scroll_limit_buffer = Vector2(0,0)
var GameBoundaries = {
		"left" : 0,
		"right" : 0,
		"top" : 0,
		"bottom" : 0,
}
	
onready var GameCamera = self
onready var GameWorld = $World
onready var CameraTween = $Tween

###############################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	initialise_gameworld()
	set_camera_limits()
	set_camera_starting_pos()
	#pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	check_camera_control_input()

###############################################################################

# handle camera inputs for control
func _input(event):

   # Mouse in viewport coordinates.
	
	# mouse click handling
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				global_var.is_rmb_held = true
				if global_var.enable_debug_camera_click_updates: print("Left button was clicked at ", event.position)
				global_var.mouse_last_right_click_position = event.position
			else:
				global_var.is_rmb_held = false
				if global_var.enable_debug_camera_click_updates: print("Left button was released at ", event.position)
			
			if global_var.enable_debug_camera_click_updates: print ("event.position * zoom = ", event.position * zoom)
			if global_var.enable_debug_camera_click_updates: print ("event.position = ", event.position)
			if global_var.enable_debug_camera_click_updates: print ("estimated array position = ", (event.position / GameWorld.tile_pixel_size / (get_viewport().size/2)) )#/ zoom)
	
	# mouse movement handling
	elif event is InputEventMouseMotion:
		camera_drag(event)

func _unhandled_input(event):
	pass


###############################################################################

# zooming code taken from GDQuest
# Credit: https://www.gdquest.com/tutorial/godot/2d/camera-zoom/
# Only minor editing, largely as-is

func _set_zoom_level(value: float) -> void:
	# We limit the value between `min_zoom` and `max_zoom`
	_zoom_level = clamp(value, min_zoom, max_zoom)
	
	# FIX TO-DO THIS IT DOESNT WORK
	# We additionally limit the horizontal and vertical positions incase zooming takes us out of the playing area
	# GameCamera.position.x = clamp(GameCamera.position.x, GameBoundaries["left"]+scroll_limit_buffer.x, GameBoundaries["right"]-scroll_limit_buffer.x)
	# GameCamera.position.y = clamp(GameCamera.position.y, GameBoundaries["top"]+scroll_limit_buffer.y, GameBoundaries["bottom"]-scroll_limit_buffer.y)
	
	# Then, we ask the tween node to animate the camera's `zoom` property from its current value
	# to the target zoom level.
	CameraTween.interpolate_property(
		self, "zoom", zoom, Vector2(_zoom_level, _zoom_level), zoom_duration,
		CameraTween.TRANS_SINE, CameraTween.EASE_OUT
	)
	update_scroll_limit_buffer()
	CameraTween.start()


###############################################################################


func _on_Tween_tween_started(object, key):
	global_var.camera_moving = true

func _on_Tween_tween_all_completed():
	global_var.camera_moving = false


###############################################################################


func initialise_gameworld():
	GameBoundaries["left"] = GameWorld.world_origin.x
	GameBoundaries["right"] = GameWorld.world_boundary.x
	GameBoundaries["top"] = GameWorld.world_origin.y
	GameBoundaries["bottom"] = GameWorld.world_boundary.y
	update_scroll_limit_buffer()
	game_boundaries_set = true


func update_scroll_limit_buffer():
	scroll_limit_buffer = (get_viewport().size/2)*zoom


# initial camera location is the halfway point of the game world map
func set_camera_starting_pos():
	GameCamera.position.x = GameBoundaries["right"]/2
	GameCamera.position.y = GameBoundaries["bottom"]/2


# camera may not stray beyond these boundaries
func set_camera_limits():
	for cam in [GameCamera]:
		cam.limit_left = GameBoundaries["left"]
		cam.limit_right = GameBoundaries["right"]
		cam.limit_top = GameBoundaries["top"]
		cam.limit_bottom = GameBoundaries["bottom"]


func check_camera_zoom_input():
	if Input.is_action_pressed("zoom_in"):
		# Inside a given class, we need to either write `self._zoom_level = ...` or explicitly
		# call the setter function to use it.
		_set_zoom_level(_zoom_level - zoom_factor)
	if Input.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level + zoom_factor)

func check_camera_control_input():
	if camera_control_settings["WASD"] and game_boundaries_set:
		check_camera_control_wasd_input()
	check_camera_zoom_input()

# below are a multitude of different funcs for controlling the camera
# * check_camera_control_wasd_input is for basic WASD or arrow-key movement
# * scroll_camera_drag is for LMB-held scroll-in-direction-of-cursor
# * immediate_camera_drag pulls camera in direction of cursor (RMB)
# * tween_camera_drag functions as immediate_camera_drag, but over a duration
func check_camera_control_wasd_input():
	var scroll_strength = keyboard_scroll_strength * zoom.x
	if Input.is_action_pressed("ui_left"):
		GameCamera.position.x = clamp(GameCamera.position.x - scroll_strength, GameBoundaries["left"]+scroll_limit_buffer.x, GameBoundaries["right"]-scroll_limit_buffer.x)
	if Input.is_action_pressed("ui_right"):
		GameCamera.position.x = clamp(GameCamera.position.x + scroll_strength, GameBoundaries["left"]+scroll_limit_buffer.x, GameBoundaries["right"]-scroll_limit_buffer.x)
	if Input.is_action_pressed("ui_up"):
		GameCamera.position.y = clamp(GameCamera.position.y - scroll_strength, GameBoundaries["top"]+scroll_limit_buffer.y, GameBoundaries["bottom"]-scroll_limit_buffer.y)
	if Input.is_action_pressed("ui_down"):
		GameCamera.position.y = clamp(GameCamera.position.y + scroll_strength, GameBoundaries["top"]+scroll_limit_buffer.y, GameBoundaries["bottom"]-scroll_limit_buffer.y)


func camera_drag(event):
		if global_var.enable_debug_camera_motion_update: print("Mouse Motion at: ", event.position)
		if global_var.is_rmb_held and camera_control_settings["Drag_RMB"]:
			var viewport = get_viewport()
			var viewport_center = viewport.size / 2
			var direction = global_var.mouse_last_right_click_position - viewport_center
			var scroll_strength = mouse_scroll_strength
			
			var camera_position_adjustment = scroll_strength * direction.normalized() * zoom
			
			tween_camera_drag(camera_position_adjustment)
			#immediate_camera_drag(camera_position_adjustment)


func tween_camera_drag(position_adjustment):
			# duraion of the drag tween
			var drag_pan_duration = 0.001
			
			# To a clamped pair of new values
			# X adjustment below
			var cam_pos_update_x = clamp(GameCamera.position.x + position_adjustment.x, \
			GameBoundaries["left"]+scroll_limit_buffer.x, \
			GameBoundaries["right"]-scroll_limit_buffer.x)
			# Y adjustment below
			var cam_pos_update_y = clamp(GameCamera.position.y + position_adjustment.y, \
			GameBoundaries["top"]+scroll_limit_buffer.y, \
			GameBoundaries["bottom"]-scroll_limit_buffer.y)

			# Tween the camera's position property from its current state
			CameraTween.interpolate_property(self, "position", GameCamera.position, \
			Vector2(cam_pos_update_x, cam_pos_update_y),
			drag_pan_duration, Tween.TRANS_SINE, Tween.EASE_OUT
			)
			CameraTween.start()

			# defunct older code
func immediate_camera_drag(position_adjustment):
			GameCamera.position.x = \
			clamp(GameCamera.position.x + position_adjustment.x, \
			GameBoundaries["left"]+scroll_limit_buffer.x, \
			GameBoundaries["right"]-scroll_limit_buffer.x)
			
			GameCamera.position.y = \
			clamp(GameCamera.position.y + position_adjustment.y, \
			GameBoundaries["top"]+scroll_limit_buffer.y, \
			GameBoundaries["bottom"]-scroll_limit_buffer.y)

###############################################################################

class_name WorldCamera
extends Camera2D

signal camera_movement

var texture_day_phase_day = preload("res://art/phase_day.png")
var texture_day_phase_evening = preload("res://art/phase_evening.png")
var texture_day_phase_morning = preload("res://art/phase_morning.png")
var texture_day_phase_night = preload("res://art/phase_night.png")

const SCREEN_ALPHA_TINT_MAGNITUDE_DAY = 0.01
const SCREEN_ALPHA_TINT_MAGNITUDE_TRANSITION = 0.25
const SCREEN_ALPHA_TINT_MAGNITUDE_NIGHT = 0.55
const SCREEN_ALPHA_TINT_TRANSITION_DURATION = 2.0
const BASE_SCROLL_STRENGTH = 12
const BASE_ZOOM_DURATION = 0.3

var current_screen_alpha_tint
var mouse_scroll_strength = BASE_SCROLL_STRENGTH * 2.0
var keyboard_scroll_strength = BASE_SCROLL_STRENGTH

var total_game_hours_played = 0

# Lower cap for the `_zoom_level`.
export var min_zoom := 0.35
# Upper cap for the `_zoom_level`.
export var max_zoom := 1.0
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
	"Drag_LMB" : false, # defunct, TODO please remove all references
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
onready var DayNightPhaseSprite = $UILayer/Margin_GameTime/VBox_GameTime/HBox_GameTimeIcons/VBox_Right/DayPhaseIcon
onready var GameMinuteRadial = $UILayer/Margin_GameTime/VBox_GameTime/HBox_GameTimeIcons/VBox_Left/GameMinuteRadialProg
onready var GameHourLabel = $UILayer/Margin_GameTime/VBox_GameTime/HBox_GameTimeLabels/GameHourLabel
onready var GamePhaseLabel = $UILayer/Margin_GameTime/VBox_GameTime/GamePhaseLabel
onready var GameSpeedLabel = $UILayer/Margin_GameTime/VBox_GameTime/GameSpeedLabel
onready var ArrayPositionLabel = $UILayer/Margin_GameTime/VBox_GameTime/ArrayPositionLabel
onready var TimeScoreLabel = $UILayer/Margin_GameTime/VBox_GameTime/TimePlayedLabel
onready var LeafScoreLabel = $UILayer/Margin_GameTime/VBox_GameTime/MulchScoreLabel
onready var FullScreenTint = $UILayer/NightScreenTint
onready var ScreenTintTween = $UILayer/NightScreenTint/TintTween

###############################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	initialise_gameworld()
	set_camera_limits()
	set_camera_starting_pos()
	set_base_camera_zoom()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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


func _on_Tween_tween_started(_object, _key):
	global_var.camera_moving = true


func _on_Tween_tween_all_completed():
	global_var.camera_moving = false


# recieve signal to update ui elements relating to game speed
func _on_World_update_speed(new_speed):
	if new_speed in [GameWorld.GameSpeed.NORMAL, \
	GameWorld.GameSpeed.ACCELERATED, \
	GameWorld.GameSpeed.MAXIMUM,
	GameWorld.GameSpeed.DEVELOPER]:
		var speed_string
		if new_speed == GameWorld.GameSpeed.NORMAL:
			speed_string = "1x Speed"
		elif new_speed == GameWorld.GameSpeed.ACCELERATED:
			speed_string = "2x Speed"
		elif new_speed == GameWorld.GameSpeed.MAXIMUM:
			speed_string = "3x Speed"
		elif new_speed == GameWorld.GameSpeed.DEVELOPER:
			speed_string = "4x Speed (DevMode)"
		GameSpeedLabel.text = speed_string


# receives signal from GameWorld
# func then updates UI representations of game time
# i.e label text, radial progress value, screen tint
func _on_World_update_time(current_hour, current_minute, current_day_phase):
	var previous_hour = int(GameHourLabel.text)
	# update ui label and prog radial
	GameHourLabel.text = str(current_hour)
	GameMinuteRadial.value = current_minute
	var hour_increment = (current_hour - previous_hour)
	# is the hour incrementing or resetting?
	if hour_increment == 1 or current_hour == 0 and current_minute == 0:
		total_game_hours_played += 1
		TimeScoreLabel.text = "Hours Passed: " + str(total_game_hours_played)
	
	# update the ui element representing the day phase
	update_day_phase_sprite(current_day_phase)
	
	# pass if screen tint tween is running
	if not ScreenTintTween.is_active():
		if global_var.enable_debug_day_phase_checks: print("day-phase-tween check1")
		# get the target screen tint by phase of day
		var screen_tint_check 
		if current_day_phase == GameWorld.DayPhase.MORNING or \
		current_day_phase == GameWorld.DayPhase.EVENING:
			screen_tint_check = SCREEN_ALPHA_TINT_MAGNITUDE_TRANSITION
		elif current_day_phase == GameWorld.DayPhase.DAY:
			screen_tint_check = SCREEN_ALPHA_TINT_MAGNITUDE_DAY
		elif current_day_phase == GameWorld.DayPhase.NIGHT:
			screen_tint_check = SCREEN_ALPHA_TINT_MAGNITUDE_NIGHT
		
		# get the current screen tint
		var current_screen_tint = FullScreenTint.modulate.a
		
		if global_var.enable_debug_day_phase_checks: print("day-phase-tween check2")
		
		
		if current_screen_tint != screen_tint_check:
			tween_screen_tint(current_screen_tint, screen_tint_check)
	


# changes graphic/tint of day phase sprite
# changes text of game phase label
func update_day_phase_sprite(given_day_phase):
	# set the graphic for time of day
	if given_day_phase == GameWorld.DayPhase.MORNING:
		#DayNightPhaseSprite.modulate = Color(0.85,0.30,0.25,1.0)
		DayNightPhaseSprite.texture = texture_day_phase_morning
		GamePhaseLabel.text = "MORNING"
	elif given_day_phase == GameWorld.DayPhase.DAY:
		#DayNightPhaseSprite.modulate = Color(0.85,0.75,0.10,1.0)
		DayNightPhaseSprite.texture = texture_day_phase_day
		GamePhaseLabel.text = "DAY"
	elif given_day_phase == GameWorld.DayPhase.EVENING:
		#DayNightPhaseSprite.modulate = Color(0.45,0.20,0.75,1.0)
		DayNightPhaseSprite.texture = texture_day_phase_evening
		GamePhaseLabel.text = "EVENING"
	elif given_day_phase == GameWorld.DayPhase.NIGHT:
		#DayNightPhaseSprite.modulate = Color(0.25,0.15,0.45,1.0)
		DayNightPhaseSprite.texture = texture_day_phase_night
		GamePhaseLabel.text = "NIGHT"


# this function takes the screen tint color rect and applies a blue
# tint to it, or removes a blue tint, over 4 seconds
# under normal gametime settings should never fire more than once at a time
func tween_screen_tint(current_blue_tint, new_magnitude):
	if global_var.enable_debug_day_phase_checks: print("day-phase-tween/screen-tint current blue tint at ", current_blue_tint)
	if global_var.enable_debug_day_phase_checks: print("day-phase-tween/screen-tint magnitude changed to ", new_magnitude)
	ScreenTintTween.interpolate_property(FullScreenTint, "modulate:a", \
	current_blue_tint, new_magnitude, SCREEN_ALPHA_TINT_TRANSITION_DURATION, \
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	ScreenTintTween.start()

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


func set_base_camera_zoom():
	zoom_duration = 1.5
	_set_zoom_level(0.75)
	zoom_duration = BASE_ZOOM_DURATION

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

func _onUpdateArrayPosLabel(given_tile):
	if given_tile is GameTile:
		ArrayPositionLabel.text = str(given_tile.array_pos)


func _on_World_pass_mulch_score(new_score):
	LeafScoreLabel.text = "Mulch Score: " + str(new_score)

###############################################################################


# defunct, removed
func camera_has_moved():
	emit_signal("camera_movement")


# defunct, removed
func _on_GameViewCamera_camera_movement():
	pass # Replace with function body.

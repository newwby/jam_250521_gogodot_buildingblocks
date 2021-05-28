
class_name GameBlock
extends Node2D

signal block_grabbed(identity)
signal block_released(identity)

var array_pos = Vector2(150,150)
var block_size = Vector2(100,100)

var use_debug_sprite = true
var show_debug_array_label = true

var ghost_image = false

var _is_grabbed = false setget _set_is_grabbed
var _block_clicked = false setget _set_block_clicked
var _block_highlighted = false

var sprites = []

onready var test_block_sprite = $ColorRect
#onready var block_sprite = $ColorRect
onready var block_collision = $BlockArea/CollisionArea
onready var ClickTimer = $MouseHoldTimer
onready var ReturnBlockTransition = $ReturnTween
onready var debug_label_array_pos = $DebugHandler/DebugLabel_ArrayPos

###############################################################################

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_setup()
	block_setup()


func _process(delta):
	pass
	

###############################################################################


# on block click
func _set_block_clicked(value: bool) -> void:
	# We limit the value between `min_zoom` and `max_zoom`
	_block_clicked = value
	# defunct timer code removed
	#if not _block_clicked:
	#	ClickTimer.stop()

# defunct/removed
func _set_is_grabbed(value: bool) -> void:
	_is_grabbed = value


###############################################################################


# if double clicked within click timer wait time, activate block
func _on_BlockArea_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				_block_clicked = true
				if ClickTimer.is_stopped():
					ClickTimer.start()
				else:
					activate_block()
			if not event.pressed and _is_grabbed:
				#return_block_to_origin()
				pass

func return_block_to_origin():
				# set up and process a tween to return the block to its origin
				var return_transition_duration = 0.4
				var return_transition_delay = 0.1
				_is_grabbed = false
				ReturnBlockTransition.interpolate_property(self, "position", \
				get_viewport().get_mouse_position(), get_viewport().get_mouse_position(),
				return_transition_duration, Tween.TRANS_SINE, Tween.EASE_OUT,
				return_transition_delay)
				ReturnBlockTransition.start()

###############################################################################

# defunct
func _on_MouseHoldTimer_timeout():
	pass


# if mouse enters block apply a slight translucency to the block
func _on_BlockArea_mouse_entered():
	for i in sprites:
		i.color.a = 0.85
	_block_highlighted = true


# if mouse leaves block unset highlight var and translucency
func _on_BlockArea_mouse_exited():
	for i in sprites:
		i.color.a = 1.0
	_block_highlighted = false


func _on_BlockGrabbed():
	pass


func _on_BlockReleased():
	pass

###############################################################################


# all basic blocks followthe same setup
func block_setup():
	var block_center = block_size/2
	for i in sprites:
		i.color = Color(1,0,0,1)
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
	for i in sprites:
		i.visible = use_debug_sprite
	

func sprite_setup():
	sprites = [test_block_sprite]

func update_position():
	if _is_grabbed:
		update_position()
		position = get_viewport().get_mouse_position()


# function to run on double click
func activate_block():
	_is_grabbed = true
	if _is_grabbed:
		global_var.grabbed_block = self
		print(global_var.grabbed_block, " says hello")
	else:
		global_var.grabbed_block = null
	#var switcheroo = test_block_sprite.color.r
	#test_block_sprite.color.r = test_block_sprite.color.b
	#test_block_sprite.color.b = switcheroo

###############################################################################

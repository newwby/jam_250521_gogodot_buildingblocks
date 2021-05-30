
class_name GameBlock
extends GameCell

signal block_grabbed()
signal block_released()

const CLICK_TIMER_WAIT = 0.25
const RETURN_TIMER_WAIT = 0.05
const ACTIVATION_COOLDOWN = 2.0
const BLOCK_RETURN_TRANSITION_DURATION = 0.2
const BLOCK_RETURN_TRANSITION_DELAY = 0.05
const MOUSE_HOLD_FOR_DRAG_TICKS = 25
const RADIAL_TICK_BUFFER = 5

var mouse_hold_tick_count = 0
var array_pos = Vector2(150,150)
var block_size = Vector2(100,100)
var grabbed_position = Vector2(0,0)

var _is_grabbed = false setget _set_is_grabbed
var _block_after_image = false setget _set_block_after_image
var _block_clicked = false setget _set_block_clicked
var is_clicked_recently = false
var is_ability_on_cooldown = false
var _block_highlighted = false

var use_debug_sprite = true
var show_debug_array_label = true

onready var test_block_sprite = $DebugSprite
#onready var block_sprite = $ColorRect
onready var block_collision = $BlockArea/CollisionArea

onready var radial_prog = $MouseHoldProgRadial
onready var ClickTimer = $MouseHoldTimer
onready var ReturnBlockTimer = $ReturnTimer
onready var ReturnBlockTransition = $ReturnTween
onready var ActivationTimer = $ActivationCooldownTimer

onready var EffectHolder = $EffectGraphicHolder
onready var CooldownNotification = $EffectGraphicHolder/OnCooldown

onready var debug_label_array_pos = $DebugHolder/DebugLabel_ArrayPos

###############################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_setup()
	timer_setup()
	block_setup()
	progress_radial_setup()


func _process(_delta):
	update_position_if_grabbed()
	block_pickup_validation()
	grab_release_validation()


###############################################################################


# on block click
func _set_block_clicked(value: bool) -> void:
	# defunct timer code removed
	_block_clicked = value

# defunct/moved features to functions
func _set_is_grabbed(value: bool) -> void:
	_is_grabbed = value

func _set_block_after_image(value: bool) -> void:
	_block_after_image = value


###############################################################################


# if double clicked within click timer wait time, activate block
func _on_BlockArea_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				is_clicked_recently = true
				_block_clicked = true
				if ClickTimer.is_stopped():
					ClickTimer.start()
				else:
					#ClickTimer.stop()
					activate_block()
			else:
				is_clicked_recently = false
				block_no_longer_clicked()


###############################################################################


# on expiry of timer for checking double clicking
func _on_MouseHoldTimer_timeout():
	is_clicked_recently = false


# timer exists to catch exceptions with return block to origin logic
func _on_ReturnTimer_timeout():
	_block_clicked = false
	mouse_hold_tick_count_update(false)
	emit_signal("block_released")


# when tween finishes and block is at rest we remove the afterimage effect
func _on_ReturnTween_tween_completed(_object, _key):
	apply_after_image(false)


func _on_ActivationCooldownTimer_timeout():
	is_ability_on_cooldown = false


# if mouse enters block apply a slight translucency to the block
func _on_BlockArea_mouse_entered():
	if not _is_grabbed:
		cell_highlight(true, true)


# if mouse leaves block unset highlight var and translucency
func _on_BlockArea_mouse_exited():
	if not _is_grabbed:
		cell_highlight(false, true)
	mouse_hold_tick_count_update(false)
	if _block_clicked:
		_block_clicked = false

# on signal for grabbing a block
func _on_Block_block_grabbed():
	global_var.grabbed_block = self
	grabbed_position = position 
	apply_after_image(true)
	_is_grabbed = true


# on signal for block release
func _on_Block_block_released():
	global_var.grabbed_block = null
	return_block_to_origin()
	_is_grabbed = false

###############################################################################


# all basic blocks follow the same setup
func block_setup():
	var block_center = block_size/2
	
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
	

# list of all nodes that make up the graphical representation of the block
func sprite_setup():
	sprites = [
		test_block_sprite,
	]
	for i in sprites:
		i.color = Color(1,0,0,1)


# sets up default parameters of miscellaneous graphical effects
func graphical_effect_setup():
	#EffectHolder.position = position
	var corner_offset = block_size / 8
	CooldownNotification.position = corner_offset
	CooldownNotification.size = corner_offset
	CooldownNotification.visible = true


# setting timers to the values for their respective wait times
# these are stored by logic in case we need to reset them later
func timer_setup():
	ReturnBlockTimer.wait_time = RETURN_TIMER_WAIT
	ClickTimer.wait_time = CLICK_TIMER_WAIT


# center and set max value of the radial progress bar whilst holding mouse
func progress_radial_setup():
	var half_block_offset = block_size/2
	radial_prog.rect_size = half_block_offset
	radial_prog.rect_position = half_block_offset/4
	radial_prog.max_value = MOUSE_HOLD_FOR_DRAG_TICKS-RADIAL_TICK_BUFFER
	radial_prog.visible = false
	
	
# make block follow the mouse cursor
func update_position_if_grabbed():
	if _is_grabbed:
		position = return_adjusted_mouse_position()


# if held on block for a duration the block is picked up
func block_pickup_validation():
	if Input.is_mouse_button_pressed(BUTTON_LEFT) and _block_clicked and global_var.grabbed_block == null:
		mouse_hold_tick_count_update(true)
		if global_var._enable_all_debug_mode: print("holding, @ ", mouse_hold_tick_count)
	if mouse_hold_tick_count >= MOUSE_HOLD_FOR_DRAG_TICKS:
		_block_clicked = false
		mouse_hold_tick_count_update(false)
		emit_signal("block_grabbed")


# sometimes the block fails to tween back/sticks on the cursor
# this func exists to check if somehow the mouse button not being held
# hasn't been caught and to execute return logic
# tbf it could even replace return logic as it is more reliable
func grab_release_validation():
	if _is_grabbed:
		if Input.is_mouse_button_pressed(BUTTON_LEFT) and not ReturnBlockTimer.is_stopped():
			ReturnBlockTimer.stop()
			ReturnBlockTimer.wait_time = RETURN_TIMER_WAIT
		if not Input.is_mouse_button_pressed(BUTTON_LEFT) and ReturnBlockTimer.is_stopped():
			ReturnBlockTimer.start()


# method for interrupting hold counts
func block_no_longer_clicked():
	pass
	_block_clicked = false
	mouse_hold_tick_count_update(false)
	# if block_no longer clicked we release it so it can return to origin
	# this is now defunct, using the timer method (onReturnTimer_timeout) instead
	#if _is_grabbed:
		#emit_signal("block_released")

# logic to update mouse_hold_tick_count whilst also interfacing with progress radial
func mouse_hold_tick_count_update(is_not_reset):
	# if not reset, increment by one
	if is_not_reset and not _is_grabbed:
		mouse_hold_tick_count += 1
	else:
		mouse_hold_tick_count = 0
	radial_prog.value = mouse_hold_tick_count-RADIAL_TICK_BUFFER if mouse_hold_tick_count-RADIAL_TICK_BUFFER >= 0 else 0
	if radial_prog.value >= MOUSE_HOLD_FOR_DRAG_TICKS/8.0:
		radial_prog.visible = true
	else:
		radial_prog.visible = false


# calculate the center of the block position relative to cursor
func return_adjusted_mouse_position():
	return Vector2(
			get_global_mouse_position().x-(block_size.x/2),\
			get_global_mouse_position().y-(block_size.y/2)\
			)


# graphical function for tweening block back to where it started
func return_block_to_origin():
	# set up and process a tween to return the block to its origin
	ReturnBlockTransition.interpolate_property(self, "position", \
	return_adjusted_mouse_position(), grabbed_position,
	BLOCK_RETURN_TRANSITION_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT,
	BLOCK_RETURN_TRANSITION_DELAY)
	ReturnBlockTransition.start()



# graphical function
func apply_after_image(add_or_remove):
	if add_or_remove:
		for i in sprites:
			i.color.a = 0.15
	else:
		for i in sprites:
			i.color.a = 1.0
	global_var.can_highlight_blocks = !add_or_remove
	_block_after_image = add_or_remove


# function to run on double click
func activate_block():
	if not is_ability_on_cooldown:
		var switcheroo = test_block_sprite.color.r
		test_block_sprite.color.r = test_block_sprite.color.b
		test_block_sprite.color.b = switcheroo
		is_ability_on_cooldown = true
		ActivationTimer.start()

###############################################################################

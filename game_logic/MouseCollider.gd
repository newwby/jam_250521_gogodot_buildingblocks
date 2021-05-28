
# DEPRECATED DUE TO CONFLICT

# This class handles collision for the mouse cursor
# It is used as a workaround for detecting blocks and tiles
# Credit to Godot Card Game Framework
# https://github.com/db0/godot-card-game-framework/blob/main/src/core/MousePointer.gd
class_name MouseCollider
extends Area2D

# can change the viewport position being tracked - may be defunct
# this *is* now defunct as we're using the relevant viewport
var viewport_in_use

const MOUSE_RADIUS := 0.5

# Using array instead of get_overlapping_areas() because those are updated
# every tick, which causes glitches when the player moves the mouse too fast.
#
# Instead we populate according to signals,which are more immediate
var overlapping := []
# When set to false, prevents the player from disable interacting with the game.
var is_disabled := false

onready var CollisionShape = $MouseCollision

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# set the size of the mouse collider collision shape
	CollisionShape.shape.radius = MOUSE_RADIUS


# On mouse movement this object followss
func _input(event):
   # Mouse in viewport coordinates.
	if event is InputEventMouseMotion:
			#position = event.position
			update_position()
			pass


# the mouse collider tracks the mouse cursor
func update_position():
	var pos_viewport = viewport_in_use
	if pos_viewport == null:
		pos_viewport = get_viewport()
	position = pos_viewport.get_mouse_position()


# triggered whenever the mouse collider area passes into another area
func _on_MouseCollider_area_entered(area):
	if not is_disabled:
		if area.owner is GameBlock:
			overlapping.append(area.owner)
			if global_var.enable_debug_mode: print("entering block at", area.owner.array_pos)


# triggered whenever the mouse collider area leaves an area 
func _on_MouseCollider_area_exited(area):
	if not is_disabled:
		if area.owner is GameBlock:
			overlapping.erase(area.owner)
			if global_var.enable_debug_mode: print("leaving block at", area.owner.array_pos)

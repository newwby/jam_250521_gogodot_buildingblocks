
# This class handles collision for the mouse cursor
# It is used as a workaround for detecting blocks and tiles
# Credit to Godot Card Game Framework
# https://github.com/db0/godot-card-game-framework/blob/main/src/core/MousePointer.gd
class_name MouseCollider
extends Area2D

const MOUSE_RADIUS := 0.5

# Using array instead of get_overlapping_areas() because those are updated
# every tick, which causes glitches when the player moves the mouse too fast.
#
# Instead we populate according to signals,which are more immediate
var overlaps := []
# When set to false, prevents the player from disable interacting with the game.
var is_disabled := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CollisionShape2D.shape.radius = MOUSE_RADIUS
	# warning-ignore:return_value_discarded
	connect("area_entered",self,"_on_MousePointer_area_entered")
	# warning-ignore:return_value_discarded
	connect("area_exited",self,"_on_MousePointer_area_exited")

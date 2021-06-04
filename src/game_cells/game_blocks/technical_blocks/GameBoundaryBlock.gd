
class_name GameBoundaryBlock
extends GameBlock


func _ready():
	block_property_setup()


func block_property_setup():
	is_grabbable = false
	is_interactable = false
	is_updating = false
	is_clickable = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

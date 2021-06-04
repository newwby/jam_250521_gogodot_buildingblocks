
class_name ShrubBlock
extends GameBlock

var shrub_sprite = preload("res://art/block_shrub.png")

const BASE_SPAWN_MTTH = 20

var branch_spawn_mtth = BASE_SPAWN_MTTH
var cardinal_branches_owned = []

func sprite_setup():
	use_debug_sprite = false
	block_sprite.texture = shrub_sprite
	test_block_sprite.visible = false
	var measure_sprite_size = (block_sprite.get_rect().size)
	var scale_adjustment = measure_sprite_size/block_size
	block_sprite.scale /= scale_adjustment


func _on_BlockUpdate():
	if global_var.enable_shrub_entropy_logging: print("current mtth is ", branch_spawn_mtth)
	var generate_entropy = global_var.return_new_random(1,10)
	if global_var.enable_shrub_entropy_logging: print("new entropy is -", generate_entropy)
	branch_spawn_mtth -= generate_entropy
	if branch_spawn_mtth <= 0:
		if global_var.enable_shrub_entropy_logging: print("spawned!")
		branch_spawn_mtth = BASE_SPAWN_MTTH
		spawn_branch()


func spawn_branch():
	var own_array_position = tile_parent.array_pos
	var generate_cardinal_direction = global_var.return_new_random(1,5)
	var new_spawn_position = Vector2.ZERO
	if global_var.enable_shrub_spawning_logging: print(generate_cardinal_direction)
	match generate_cardinal_direction:
		1:
			new_spawn_position = Vector2(own_array_position.x+1, own_array_position.y)
		2:
			new_spawn_position = Vector2(own_array_position.x-1, own_array_position.y)
		3:
			new_spawn_position = Vector2(own_array_position.x, own_array_position.y+1)
		4:
			new_spawn_position = Vector2(own_array_position.x, own_array_position.y-1)
		
	emit_signal("spawn_new_block", new_spawn_position, global_var.BlockType.BRANCH_BLOCK)
	# TODO if spawning branch connect the death function to 

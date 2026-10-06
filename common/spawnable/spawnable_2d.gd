class_name Spawnable2D extends Node2D
## A spawnable component.

#region VARIABLES
## The root node of this game node.
@export var root_node: Node2D = self
@export var direction: Vector2 = Vector2.ZERO

## Has this spawnable been spawned?
var is_spawned: bool = false :
	set(s):
		if s == is_spawned:
			return
		is_spawned = s
#endregion

#region SIGNALS
## Emitted when spawned.
signal spawned(spawn_point: Vector2)
## Emitted when despawned.
signal despawned(new_position: Vector2)
#endregion

#region VARIABLES
## Used to spawn the spawnable.
func spawn(spawn_point: Vector2 = Vector2.ZERO) -> void:
	if is_spawned:
		return
	
	root_node.visible = true
	root_node.process_mode = ProcessMode.PROCESS_MODE_INHERIT
	root_node.position = spawn_point
	is_spawned = true
	spawned.emit(spawn_point)

## Used to despawn/disable the spawnable.
func despawn(new_position: Vector2 = Vector2.ZERO) -> void:
	if !is_spawned:
		return
	
	root_node.visible = false
	root_node.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	root_node.position = new_position
	is_spawned = false
	despawned.emit(new_position)
#endregion

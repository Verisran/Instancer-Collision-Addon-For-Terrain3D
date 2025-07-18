#Oskar D. - Terrain3D Instance Collision Addon Node - Godot 4.4.1 - MIT
@tool
extends Node3D
class_name Terrain3DInstanceColliders

#region Editor Properties
@export_category("Setup")
##Reference to terrain3D node, this is mandatory
@export var terrain: Terrain3D
@export_flags_3d_physics var collision_layer: int = 1

@export_category("Options")
##When true the generate_instances_collisions() method has to be manually called for the collisions to be generated.
@export var manual_start: bool = true
##Disbales instance collider generation
@export var disable: bool = false
##Enables extra details to be printed to console for debugging purposes
@export var debug_print: bool = false
#endregion

#region Physics Server Properties
var static_instance_collider: RID
var shapes: Array[Shape3D]
var transforms: Array[Transform3D]
#endregion

#region Engine Callback
func _ready() -> void:
	if(Engine.is_editor_hint() or disable):
		return
	get_collider_shapes()
	if(!manual_start):
		generate_instance_collisions()
	
#Automatically clears the physics server
func _notification(what: int) -> void:
	if(Engine.is_editor_hint()):
		return
	match what:
		NOTIFICATION_PREDELETE:
			#clear_shape_arrays() - already cleared in generate_instance_collisions
			free_instance_collisions()
#endregion

#region Extract Colliders Methods
##Returns an array containing [Shape3D, CollisionShape3D.position] for each mesh asset
##It extracts the first found CollisionShape3D.shape from the mesh_list of the referenced Terrain3D node
##The position is used to offset the transform origin correctly based on size of the CollisionShape
##If the mesh asset did not have a CollisionShape3D [null, Vector3.ZERO] is assigned
func extract_collider_shapes()->Array[Array]:
	var collider_shapes: Array[Array]
	#Loop through mesh asset list to check if they have collision attached
	for asset in terrain.assets.mesh_list:
		#instantiate mesh scene to access provided collider
		var inst_asset: Node = asset.scene_file.instantiate()
		#find collision_shape in children of root node
		var shape: Shape3D = null
		var position_offset: Vector3 = Vector3.ZERO
		#when collision shape child is found set shape and position offset, break out of loop on first match
		for child in inst_asset.get_children():
			if(child is CollisionShape3D):
				if(child.shape == null):
					if(debug_print):
						print("Warining: CollisionShape3D found for asset '", inst_asset.name, "' but has no shape, please set it in the editor")
					continue
				shape = child.shape
				position_offset = child.position
				break
		#create the nested array and free asset scene
		collider_shapes.append([shape, position_offset])
		inst_asset.queue_free()
	if(debug_print):
		print("mesh asset collider shapes and offset: ", collider_shapes)
	return collider_shapes

##For each region it checks if it has any mesh asset (only when the mesh asset has a provided collider) instances in it and saves a Shape3D and Transform3D to be used when generating the collider
func get_collider_shapes()->void:
	clear_shape_arrays()
	global_position = Vector3()
	var collider_shapes: Array[Array] = extract_collider_shapes()
	var mesh_count: int = terrain.assets.mesh_list.size()
	var regions: Array[Terrain3DRegion] = terrain.data.get_regions_active()
	for region in regions:
		#check region has any instances
		if(region.instances.is_empty()):
			continue
		#check each mesh asset, ma_id corresponds to mesh asset id
		for ma_id in range(mesh_count):
			#mesh asset doesnt have collision, continue to next
			if(collider_shapes[ma_id][0] == null):
				ma_id+=1
				continue
			#access all instances by id
			if(region.instances.has(ma_id)):
				for grid:Vector2i in region.instances[ma_id]:
					#access indiviual instances by grid
					for trans:Transform3D in region.instances[ma_id][grid][0]:
						var new_trans: Transform3D = trans
						new_trans.origin = (get_instance_global_position(region.location, trans.origin) + collider_shapes[ma_id][1])
						transforms.append(new_trans)
						shapes.append(collider_shapes[ma_id][0])
			ma_id+=1
	if(shapes.size() == 0):
		print("Warning: No shapes were assigned.")
	if(debug_print):
		print("Total of: ", shapes.size(), " Shape3Ds were assigned.")
		print("Total of: ", transforms.size(), " Transfrom3Ds were assigned.")

##Converts the region_location and position_in_region into global coordinates
func get_instance_global_position(region_location: Vector2, position_in_region: Vector3)->Vector3:
	var a: Vector2 = region_location*terrain.region_size
	return position_in_region + Vector3(a.x, 0, a.y) 

##Clears the saved shapes and transforms
func clear_shape_arrays()->void:
	shapes.clear()
	transforms.clear()
#endregion

#region Physics Server Stuff

#TODO split up into multiple body RIDs
##Creates the static physics body and assigns all collider shapes and transforms to the static body in the physics server 
func generate_instance_collisions(space: RID = get_world_3d().space)->void:
	if(disable):
		return
	static_instance_collider = PhysicsServer3D.body_create()
	for i in range(shapes.size()):
		PhysicsServer3D.body_add_shape(static_instance_collider, shapes[i].get_rid())
		PhysicsServer3D.body_set_shape_transform(static_instance_collider, i, transforms[i])
	PhysicsServer3D.body_set_mode(static_instance_collider, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_collision_layer(static_instance_collider, collision_layer)
	#https://github.com/godotengine/godot/issues/24026#issuecomment-442613911 
	#This operation used to take 11s because I was dumb...
	PhysicsServer3D.body_set_space(static_instance_collider, space)
	clear_shape_arrays()

##Cleanup method, call on scene exit or before regenerating collisions on demand
func free_instance_collisions()->void:
	if(static_instance_collider.is_valid()):
		PhysicsServer3D.free_rid(static_instance_collider)
	#Shape RIDs should be managed by the Shape3D resource they came from... Right?
#endregion

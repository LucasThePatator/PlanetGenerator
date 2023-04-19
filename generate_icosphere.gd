extends MeshInstance
tool

export(float, 2.0) var noise_scale = 0.5 setget set_noise_scale
export(int, 9) var subdivisions = 3 setget set_subvisions
export(int, 10) var octaves = 3 setget set_octaves
export(float, 5.0) var period = 0.5 setget set_period
export(float, 1.0) var persistence = 0.8 setget set_persistence
export(float, 5)  var lacunarity = 2.0 setget set_lacunarity
export var delta_norm = 0.01 setget set_delta_norm
export var simplex_seed = 0 setget set_seed

export var radius = 1
export var material : ShaderMaterial

var mid_points_cache = {}

var generated = false

var verts = PoolVector3Array()
#var uvs = PoolVector2Array()
var normals = PoolVector3Array()
var indices = PoolIntArray()

class Noise:
	var generator : OpenSimplexNoise
	var min_noise : float
	var max_noise : float
	var noise_mean : float

var noises = []

func set_noise_scale(value):
	noise_scale = value
	apply_noise()
	
func set_subvisions(value):
	var regenerate_sphere = (value != subdivisions)
	subdivisions = value
	if(regenerate_sphere):
		generate()
		
	apply_noise()
	
func set_octaves(value):
	octaves = value
	apply_noise()
	
func set_period(value):
	period = value
	apply_noise()
	
func set_persistence(value):
	persistence = value
	apply_noise()
	
func set_lacunarity(value):
	lacunarity = value
	apply_noise()
	
func set_delta_norm(value):
	delta_norm = value
	apply_noise()
	
func set_seed(value):
	for n in noises:
		n.generator.seed = value
	simplex_seed = value
	apply_noise()
	
func get_middle_point(i1, i2):
	var key = str(max(i1,i2)) + "_" + str(min(i1,i2))
	if key in mid_points_cache:
		return mid_points_cache[key]
		
	var mid = (verts[i1] + verts[i2]).normalized()
	verts.append(radius * mid)
	normals.append(mid)
	mid_points_cache[key] = len(verts) - 1
	return mid_points_cache[key]
	
func generate():
	verts.resize(0)
	normals.resize(0)
	indices.resize(0)
	mid_points_cache.clear()
	#Add basic icosahedron vertices
	var phi = (1 + sqrt(5))/2
	var a = radius/sqrt(1 + phi*phi)
	
	verts.append(Vector3(-a, a*phi, 0))
	verts.append(Vector3(+a, a*phi, 0))
	verts.append(Vector3(-a, -a*phi, 0))
	verts.append(Vector3(+a, -a*phi, 0))
	
	verts.append(Vector3(0, -a, a*phi))
	verts.append(Vector3(0, +a, a*phi))
	verts.append(Vector3(0, -a, -a*phi))
	verts.append(Vector3(0, +a, -a*phi))
	
	verts.append(Vector3(a*phi, 0, -a))
	verts.append(Vector3(a*phi, 0, +a))
	verts.append(Vector3(-a*phi, 0, -a))
	verts.append(Vector3(-a*phi, 0, +a))
	
	normals.append(Vector3(-a, a*phi, 0).normalized())
	normals.append(Vector3(+a, a*phi, 0).normalized())
	normals.append(Vector3(-a, -a*phi, 0).normalized())
	normals.append(Vector3(+a, -a*phi, 0).normalized())
	
	normals.append(Vector3(0, -a, a*phi).normalized())
	normals.append(Vector3(0, +a, a*phi).normalized())
	normals.append(Vector3(0, -a, -a*phi).normalized())
	normals.append(Vector3(0, +a, -a*phi).normalized())
	
	normals.append(Vector3(a*phi, 0, -a).normalized())
	normals.append(Vector3(a*phi, 0, +a).normalized())
	normals.append(Vector3(-a*phi, 0, -a).normalized())
	normals.append(Vector3(-a*phi, 0, +a).normalized())
	
	var current_indices = []
	current_indices.append(Vector3(0, 5, 11))
	current_indices.append(Vector3(0, 1, 5))
	current_indices.append(Vector3(0, 7, 1))
	current_indices.append(Vector3(0, 10, 7))
	current_indices.append(Vector3(0, 11, 10))
	
	current_indices.append(Vector3(1, 9, 5))
	current_indices.append(Vector3(5, 4, 11))
	current_indices.append(Vector3(11, 2, 10))
	current_indices.append(Vector3(10, 6, 7))
	current_indices.append(Vector3(7, 8, 1))
	
	current_indices.append(Vector3(3, 4, 9))
	current_indices.append(Vector3(3, 2, 4))
	current_indices.append(Vector3(3, 6, 2))
	current_indices.append(Vector3(3, 8, 6))
	current_indices.append(Vector3(3, 9, 8))
	
	current_indices.append(Vector3(4, 5, 9))
	current_indices.append(Vector3(2, 11, 4))
	current_indices.append(Vector3(6, 10, 2))
	current_indices.append(Vector3(8, 7, 6))
	current_indices.append(Vector3(9, 1, 8))
	
	for _s in range(subdivisions):
		var new_indices = []
		for i in current_indices:
			var i1 = get_middle_point(i[0], i[1])
			var i2 = get_middle_point(i[1], i[2])
			var i3 = get_middle_point(i[2], i[0])
			
			new_indices.append(Vector3(i[0], i1, i3))
			new_indices.append(Vector3(i[1], i2, i1))
			new_indices.append(Vector3(i[2], i3, i2))
			new_indices.append(Vector3(i1, i2, i3))
		
		current_indices = new_indices;
		
	for i in current_indices:
		indices.append_array([int(i[0]), int(i[1]), int(i[2])])	
		
	generated = true

func get_noise_value(position : Vector3):
	noises[n].octaves = 1
	noises[n].period = period
	noises[n].persistence = persistence
	noises[n].lacunarity = lacunarity
	
	for n in range(1, noises.size()):
		noises[n].octaves = 1
		noises[n].period = period
		noises[n].persistence = persistence
		noises[n].lacunarity = lacunarity
	
	relief_noise.octaves = octaves-1
	relief_noise.period = period*lacunarity
	relief_noise.persistence = persistence
	relief_noise.lacunarity = lacunarity
	
	var noise_value = continent_noise.get_noise_3dv(position)
	#return (1.0-2.0*abs(noise_value))
	return noise_value
	
func filter_noise(value, mean, min_val, max_val):
	var new_value = 2*(value - mean)/(max_val - min_val)
	new_value = (1.0-abs(new_value))
	return 2*new_value*new_value-1
	
func compute_noise_stats():
	pass
	
func apply_noise():
	if not generated:
		generate()
	var new_verts = PoolVector3Array()
	var new_normals = PoolVector3Array()
	
	var surface_array = []
	
	var noise_values = []

	for vert in verts:
		var noise_value = get_noise_value(vert)
		noise_values.append(noise_value)
		noise_mean += noise_value
		max_noise = max(max_noise, noise_value)
		min_noise = min(min_noise, noise_value)
		
	noise_mean /= noise_values.size()

	for vert_index in verts.size():
		var vert = verts[vert_index]
		var noise_value = noise_values[vert_index]
		
		noise_value = get_noise_value(vert)
		
		var noised_vert = vert*(1+noise_scale*noise_value);
		new_verts.append(noised_vert)
		
		var vec1 = Vector3()
		var vec2 = Vector3()
		if(vert.z < radius and vert.z > -radius):
			vec1 = vert.cross(Vector3(0, 0, 1))
			vec2 = vert.cross(vec1)
		else :
			vec1 = vert.cross(Vector3(1, 0, 0))
			vec2 = vert.cross(vec1)
			
		vec1 = vec1.normalized()
		vec2 = vec2.normalized()
		
		var v1 = (vert + delta_norm*vec1).normalized()
		var v2 = (vert + delta_norm*vec2).normalized()
			
		var nv1 = v1*(1+noise_scale* get_noise_value(v1));
		var nv2 = v2*(1+noise_scale* get_noise_value(v2));
		
		var normal = (nv1 - noised_vert).cross(nv2-noised_vert)
		new_normals.append(normal.normalized())
	

	surface_array.resize(Mesh.ARRAY_MAX)
	
	surface_array[Mesh.ARRAY_VERTEX] = new_verts
	surface_array[Mesh.ARRAY_NORMAL] = new_normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	self.set_surface_material(0, material)

func _ready():
	mesh = ArrayMesh.new()	
	generate()
	apply_noise()
	
	var continentNoise = Noise.new()
	continentNoise.genetor



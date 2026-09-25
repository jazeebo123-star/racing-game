extends Node3D

# Low-Poly Retro Drift Circuit with Curbs, Hills, Pond, Logs, and Rocks

var track_curve: Curve3D
var track_length: float = 0.0

func _ready() -> void:
	_create_curve()
	_create_lowpoly_terrain()
	_create_water_pond()
	_create_track_mesh()
	_create_scenery_props()

func _create_curve() -> void:
	track_curve = Curve3D.new()
	track_curve.bake_interval = 2.0

	# Flowing circuit with long sweeping drift corners and chicanes
	var pts = [
		# Start straight
		{"pos": Vector3(0, 0, 0), "in": Vector3(0, 0, -30), "out": Vector3(0, 0, 40)},
		{"pos": Vector3(0, 0, 80), "in": Vector3(0, 0, -30), "out": Vector3(0, 0, 40)},
		# Turn 1: Sweeping right bend
		{"pos": Vector3(45, 0, 150), "in": Vector3(-30, 0, -20), "out": Vector3(40, 0, 20)},
		{"pos": Vector3(120, 0, 160), "in": Vector3(-40, 0, 0), "out": Vector3(40, 0, -10)},
		# Turn 2: Chicane around water pond
		{"pos": Vector3(170, 0, 100), "in": Vector3(-20, 0, 30), "out": Vector3(20, 0, -30)},
		{"pos": Vector3(190, 0, 20), "in": Vector3(0, 0, 40), "out": Vector3(-10, 0, -40)},
		# Hairpin: Big drift corner
		{"pos": Vector3(140, 0, -60), "in": Vector3(30, 0, 20), "out": Vector3(-40, 0, -20)},
		{"pos": Vector3(50, 0, -80), "in": Vector3(40, 0, 0), "out": Vector3(-40, 0, 0)},
		{"pos": Vector3(-30, 0, -60), "in": Vector3(30, 0, -20), "out": Vector3(-30, 0, 20)},
		# S-curve back to start straight
		{"pos": Vector3(-60, 0, -10), "in": Vector3(-10, 0, -30), "out": Vector3(10, 0, 30)},
		{"pos": Vector3(-30, 0, -20), "in": Vector3(-20, 0, 10), "out": Vector3(20, 0, 15)}
	]

	for pt in pts:
		track_curve.add_point(pt["pos"], pt["in"], pt["out"])
	# Close loop
	track_curve.add_point(pts[0]["pos"], pts[0]["in"], pts[0]["out"])
	track_length = track_curve.get_baked_length()

func _create_track_mesh() -> void:
	var total_len = track_length
	var step: float = 2.0
	var num_steps: int = int(total_len / step)
	var half_w: float = 8.5
	var line_w: float = 0.35
	var curb_w: float = 1.6

	var road_st = SurfaceTool.new()
	road_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var line_st = SurfaceTool.new()
	line_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var curb_st = SurfaceTool.new()
	curb_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(num_steps):
		var d0 = float(i) * step
		var d1 = float(i + 1) * step
		if d1 > total_len:
			d1 = total_len

		var p0 = track_curve.sample_baked(d0)
		var p1 = track_curve.sample_baked(d1)

		var t0 = _get_tangent(d0)
		var t1 = _get_tangent(d1)

		var r0 = t0.cross(Vector3.UP).normalized()
		var r1 = t1.cross(Vector3.UP).normalized()

		# Road quad
		var r_l0 = p0 - r0 * half_w
		var r_r0 = p0 + r0 * half_w
		var r_l1 = p1 - r1 * half_w
		var r_r1 = p1 + r1 * half_w
		_add_quad(road_st, r_l0, r_r0, r_l1, r_r1)

		# White edge lines
		var wl_0_in = r_l0 + r0 * line_w + Vector3.UP * 0.015
		var wl_1_in = r_l1 + r1 * line_w + Vector3.UP * 0.015
		var wr_0_in = r_r0 - r0 * line_w + Vector3.UP * 0.015
		var wr_1_in = r_r1 - r1 * line_w + Vector3.UP * 0.015

		_add_quad(line_st, r_l0 + Vector3.UP * 0.015, wl_0_in, r_l1 + Vector3.UP * 0.015, wl_1_in)
		_add_quad(line_st, wr_0_in, r_r0 + Vector3.UP * 0.015, wr_1_in, r_r1 + Vector3.UP * 0.015)

		# Outer Red & White Curbs
		var c_l0_out = r_l0 - r0 * curb_w + Vector3.UP * 0.06
		var c_l1_out = r_l1 - r1 * curb_w + Vector3.UP * 0.06
		var c_r0_out = r_r0 + r0 * curb_w + Vector3.UP * 0.06
		var c_r1_out = r_r1 + r1 * curb_w + Vector3.UP * 0.06

		# Red and white alternating pattern based on distance
		var is_red = int(d0 / 3.0) % 2 == 0
		var curb_color = Color(0.88, 0.22, 0.18) if is_red else Color(0.95, 0.95, 0.95)

		_add_colored_quad(curb_st, c_l0_out, r_l0, c_l1_out, r_l1, curb_color)
		_add_colored_quad(curb_st, r_r0, c_r0_out, r_r1, c_r1_out, curb_color)

	# Commit Road
	road_st.generate_normals()
	var road_mesh = road_st.commit()
	var road_mat = StandardMaterial3D.new()
	road_mat.albedo_color = Color(0.24, 0.25, 0.28) # Clean asphalt gray
	road_mat.roughness = 0.8
	var road_inst = MeshInstance3D.new()
	road_inst.mesh = road_mesh
	road_inst.material_override = road_mat
	road_inst.position.y = 0.02
	add_child(road_inst)

	# Commit White Lines
	line_st.generate_normals()
	var line_mesh = line_st.commit()
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.96, 0.96, 0.98)
	line_mat.roughness = 0.3
	var line_inst = MeshInstance3D.new()
	line_inst.mesh = line_mesh
	line_inst.material_override = line_mat
	add_child(line_inst)

	# Commit Curbs
	curb_st.generate_normals()
	var curb_mesh = curb_st.commit()
	var curb_mat = StandardMaterial3D.new()
	curb_mat.vertex_color_use_as_albedo = true
	curb_mat.roughness = 0.6
	var curb_inst = MeshInstance3D.new()
	curb_inst.mesh = curb_mesh
	curb_inst.material_override = curb_mat
	add_child(curb_inst)

	# Track Collision Body
	var body = StaticBody3D.new()
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	col.shape = road_mesh.create_trimesh_shape()
	body.add_child(col)
	add_child(body)

	# Start / Finish Checkered line
	_create_start_finish_gate()

func _create_start_finish_gate() -> void:
	# White finish line at d = 0
	var line_mesh = BoxMesh.new()
	line_mesh.size = Vector3(17.0, 0.05, 1.8)
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 1.0, 1.0)
	var line_inst = MeshInstance3D.new()
	line_inst.mesh = line_mesh
	line_inst.material_override = line_mat
	line_inst.position = Vector3(0, 0.03, 0)
	add_child(line_inst)

func _create_lowpoly_terrain() -> void:
	# Faceted low-poly rolling green terrain
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var grid_size = 28
	var spacing = 18.0
	var half_extent = (grid_size * spacing) * 0.5

	for x in range(grid_size):
		for z in range(grid_size):
			var x0 = float(x) * spacing - half_extent + 60.0
			var x1 = float(x + 1) * spacing - half_extent + 60.0
			var z0 = float(z) * spacing - half_extent + 40.0
			var z1 = float(z + 1) * spacing - half_extent + 40.0

			var y00 = _get_terrain_height(x0, z0)
			var y10 = _get_terrain_height(x1, z0)
			var y01 = _get_terrain_height(x0, z1)
			var y11 = _get_terrain_height(x1, z1)

			var v0 = Vector3(x0, y00, z0)
			var v1 = Vector3(x1, y10, z0)
			var v2 = Vector3(x0, y01, z1)
			var v3 = Vector3(x1, y11, z1)

			# Triangles (flat-shaded low poly)
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)

			st.add_vertex(v1)
			st.add_vertex(v3)
			st.add_vertex(v2)

	st.generate_normals()
	var mesh = st.commit()

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.64, 0.28) # Stylized low-poly green
	mat.roughness = 0.95
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT

	var terrain = MeshInstance3D.new()
	terrain.mesh = mesh
	terrain.material_override = mat
	terrain.position.y = -0.1
	add_child(terrain)

	# Ground Collision
	var body = StaticBody3D.new()
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	var ground_box = BoxShape3D.new()
	ground_box.size = Vector3(600, 1.0, 600)
	col.shape = ground_box
	col.position.y = -0.5
	body.add_child(col)
	add_child(body)

func _get_terrain_height(x: float, z: float) -> float:
	# Keep track flat near road, create rolling hills further away
	var dist_from_center = Vector2(x - 80.0, z - 40.0).length()
	if dist_from_center < 110.0:
		return 0.0 # Flat near race track
	var hill = sin(x * 0.04) * cos(z * 0.04) * 8.0 + sin(x * 0.02) * 5.0
	return max(0.0, hill)

func _create_water_pond() -> void:
	# Low-poly faceted blue water pond next to Turn 2 chicane (matching reference image!)
	var water = MeshInstance3D.new()
	var pmesh = CylinderMesh.new()
	pmesh.top_radius = 28.0
	pmesh.bottom_radius = 28.0
	pmesh.height = 0.2
	pmesh.radial_segments = 12 # Low-poly faceted edges
	water.mesh = pmesh

	var wmat = StandardMaterial3D.new()
	wmat.albedo_color = Color(0.2, 0.65, 0.85, 0.9)
	wmat.metallic = 0.1
	wmat.roughness = 0.15
	water.material_override = wmat
	water.position = Vector3(135.0, -0.05, 50.0)
	add_child(water)

func _create_scenery_props() -> void:
	# Low-poly fallen tree logs on grass near the water (matching reference image!)
	var log_mat = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.38, 0.24, 0.14)
	log_mat.roughness = 0.85

	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.55, 0.58, 0.62)
	rock_mat.roughness = 0.8

	# Fallen logs
	_create_log(Vector3(120.0, 0.35, 82.0), Vector3(0, 25, 0), log_mat)
	_create_log(Vector3(145.0, 0.35, 85.0), Vector3(0, -15, 0), log_mat)
	_create_log(Vector3(160.0, 0.35, 18.0), Vector3(0, 45, 0), log_mat)

	# Low-poly rocks/boulders
	_create_rock(Vector3(162.0, 0.5, 78.0), 1.4, rock_mat)
	_create_rock(Vector3(105.0, 0.4, 75.0), 1.1, rock_mat)
	_create_rock(Vector3(180.0, 0.6, 35.0), 1.6, rock_mat)

	# Low-poly pine trees along hills
	for i in range(25):
		var ang = randf_range(0, TAU)
		var dist = randf_range(130.0, 190.0)
		var tx = 80.0 + cos(ang) * dist
		var tz = 40.0 + sin(ang) * dist
		var ty = _get_terrain_height(tx, tz)
		_create_pine_tree(Vector3(tx, ty, tz))

func _create_log(pos: Vector3, rot_deg: Vector3, mat: Material) -> void:
	var lmesh = CylinderMesh.new()
	lmesh.top_radius = 0.45
	lmesh.bottom_radius = 0.55
	lmesh.height = 4.8
	lmesh.radial_segments = 6 # Low-poly hexagon log
	var inst = MeshInstance3D.new()
	inst.mesh = lmesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation_degrees = Vector3(90, rot_deg.y, 0)
	add_child(inst)

func _create_rock(pos: Vector3, s: float, mat: Material) -> void:
	var rmesh = SphereMesh.new()
	rmesh.radius = s * 0.5
	rmesh.height = s * 0.8
	rmesh.radial_segments = 6
	rmesh.rings = 4 # Low poly facets
	var inst = MeshInstance3D.new()
	inst.mesh = rmesh
	inst.material_override = mat
	inst.position = pos
	inst.scale = Vector3(1.2, 0.8, 1.0)
	add_child(inst)

func _create_pine_tree(pos: Vector3) -> void:
	var tree = Node3D.new()
	tree.position = pos

	var tmesh = CylinderMesh.new()
	tmesh.top_radius = 0.3
	tmesh.bottom_radius = 0.45
	tmesh.height = 2.0
	tmesh.radial_segments = 5
	var trunk = MeshInstance3D.new()
	trunk.mesh = tmesh
	var trk_mat = StandardMaterial3D.new()
	trk_mat.albedo_color = Color(0.35, 0.22, 0.12)
	trunk.material_override = trk_mat
	trunk.position.y = 1.0
	tree.add_child(trunk)

	for layer in range(3):
		var cmesh = CylinderMesh.new()
		cmesh.top_radius = 0.05
		cmesh.bottom_radius = 2.4 - float(layer) * 0.55
		cmesh.height = 2.0
		cmesh.radial_segments = 6 # Faceted cone
		var fol = MeshInstance3D.new()
		fol.mesh = cmesh
		var fmat = StandardMaterial3D.new()
		fmat.albedo_color = Color(0.18, 0.45, 0.22)
		fol.material_override = fmat
		fol.position.y = 2.2 + float(layer) * 1.4
		tree.add_child(fol)

	add_child(tree)

func _get_tangent(offset: float) -> Vector3:
	var p0 = track_curve.sample_baked(offset)
	var p1 = track_curve.sample_baked(fposmod(offset + 1.0, track_length))
	return (p1 - p0).normalized()

func _add_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3) -> void:
	st.add_vertex(v0)
	st.add_vertex(v1)
	st.add_vertex(v2)

	st.add_vertex(v1)
	st.add_vertex(v3)
	st.add_vertex(v2)

func _add_colored_quad(st: SurfaceTool, v0: Vector3, v1: Vector3, v2: Vector3, v3: Vector3, col: Color) -> void:
	st.set_color(col)
	st.add_vertex(v0)
	st.set_color(col)
	st.add_vertex(v1)
	st.set_color(col)
	st.add_vertex(v2)

	st.set_color(col)
	st.add_vertex(v1)
	st.set_color(col)
	st.add_vertex(v3)
	st.set_color(col)
	st.add_vertex(v2)

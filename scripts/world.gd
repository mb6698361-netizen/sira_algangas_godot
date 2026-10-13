extends Node3D

var player: OpenWorldPlayer
var cars: Array[DrivableCar] = []
var active_car: DrivableCar = null
var camera: Camera3D
var status_label: Label
var hint_label: Label
var mobile_move := Vector2.ZERO
var held_left := false
var held_right := false
var held_forward := false
var held_back := false
var rng := RandomNumberGenerator.new()
var city_building_count: int = 0

func _ready() -> void:
	rng.seed = 8032026
	_build_environment()
	_build_city()
	_build_player()
	_build_cars()
	_build_camera()
	_build_hud()

func _process(delta: float) -> void:
	mobile_move = Vector2(float(held_right) - float(held_left), float(held_back) - float(held_forward)).limit_length(1.0)
	if active_car == null:
		player.set_touch_input(mobile_move)
	else:
		var keyboard_steer := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		var keyboard_drive := float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) - float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
		active_car.set_drive_input(Vector2(mobile_move.x + keyboard_steer, -mobile_move.y + keyboard_drive).limit_length(1.0))

	_update_camera(delta)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_F:
			_toggle_vehicle()

func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.14, 0.34, 0.55)
	sky_material.sky_horizon_color = Color(0.72, 0.79, 0.82)
	sky_material.ground_bottom_color = Color(0.18, 0.20, 0.18)
	sky_material.ground_horizon_color = Color(0.52, 0.55, 0.50)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.64, 0.70, 0.77)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = false # أداء أفضل على الهواتف الضعيفة
	add_child(sun)

	_add_box(self, "Ground", Vector3(0, -0.55, 0), Vector3(240, 1, 240), Color(0.22, 0.29, 0.23), true)
	_add_box(self, "CityBase", Vector3(0, -0.08, 0), Vector3(240, 0.12, 240), Color(0.30, 0.34, 0.29), false)

	# شبكة طرق رئيسية داخل المدينة.
	var asphalt := Color(0.12, 0.14, 0.16)
	for road_pos in range(-100, 101, 40):
		_add_box(self, "Road_EW", Vector3(0, -0.015, road_pos), Vector3(230, 0.12, 9.0), asphalt, false)
		_add_box(self, "Road_NS", Vector3(road_pos, -0.014, 0), Vector3(9.0, 0.12, 230), asphalt, false)
		# خطوط متقطعة صفراء بسيطة في وسط الطرق.
		for mark in range(-105, 106, 12):
			_add_box(self, "LaneMark", Vector3(mark, 0.055, road_pos), Vector3(4.0, 0.025, 0.12), Color(0.90, 0.72, 0.22), false)
			_add_box(self, "LaneMark", Vector3(road_pos, 0.056, mark), Vector3(0.12, 0.025, 4.0), Color(0.90, 0.72, 0.22), false)

func _build_city() -> void:
	var palettes := [Color(0.64, 0.65, 0.62), Color(0.54, 0.59, 0.61), Color(0.71, 0.65, 0.55), Color(0.43, 0.49, 0.53), Color(0.74, 0.73, 0.67)]
	for x in range(-90, 91, 15):
		for z in range(-90, 91, 15):
			if absf(fposmod(float(x) + 20.0, 40.0) - 20.0) < 7.0:
				continue
			if absf(fposmod(float(z) + 20.0, 40.0) - 20.0) < 7.0:
				continue
			if Vector2(x, z).length() < 15.0:
				continue
			if rng.randf() < 0.17:
				continue
			var width := rng.randf_range(8.0, 12.0)
			var depth := rng.randf_range(8.0, 12.0)
			var height := rng.randf_range(8.0, 30.0)
			if rng.randf() < 0.16:
				height = rng.randf_range(32.0, 45.0)
			var color: Color = palettes[rng.randi_range(0, palettes.size() - 1)]
			_add_box(self, "Building_%02d" % city_building_count, Vector3(x, height / 2.0, z), Vector3(width, height, depth), color, true)
			city_building_count += 1
			# مدخل داكن صغير لبعض المباني يضيف تفاصيل دون تحميل ثقيل.
			if rng.randf() < 0.55:
				_add_box(self, "Entrance", Vector3(x, 1.1, z - depth / 2.0 - 0.018), Vector3(1.5, 2.2, 0.05), Color(0.11, 0.14, 0.16), false)

	# أشجار قليلة عند أطراف بعض الشوارع.
	for i in range(22):
		var tx := rng.randf_range(-100.0, 100.0)
		var tz := rng.randf_range(-100.0, 100.0)
		if absf(fposmod(tx + 20.0, 40.0) - 20.0) < 8.0 or absf(fposmod(tz + 20.0, 40.0) - 20.0) < 8.0:
			var trunk := _add_box(self, "TreeTrunk", Vector3(tx, 1.1, tz), Vector3(0.5, 2.2, 0.5), Color(0.28, 0.18, 0.10), false)
			var crown := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 1.6
			mesh.height = 3.0
			crown.mesh = mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.12, 0.32, 0.17)
			crown.material_override = mat
			crown.position = Vector3(tx, 3.0, tz)
			add_child(crown)

func _build_player() -> void:
	player = OpenWorldPlayer.new()
	player.name = "Player"
	player.position = Vector3(0, 0.1, 7)
	add_child(player)

func _build_cars() -> void:
	var locations := [Vector3(6, 0.1, 5), Vector3(-12, 0.1, 6), Vector3(22, 0.1, -8), Vector3(-32, 0.1, 20), Vector3(48, 0.1, 12), Vector3(8, 0.1, -35)]
	for i in range(locations.size()):
		var car := DrivableCar.new()
		car.name = "DrivableCar_%d" % (i + 1)
		car.position = locations[i]
		car.rotation.y = 0.0 if i % 2 == 0 else PI / 2.0
		add_child(car)
		cars.append(car)

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.current = true
	camera.fov = 72.0
	add_child(camera)
	camera.global_position = player.global_position + Vector3(0, 4.0, 7.0)
	camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)

func _update_camera(delta: float) -> void:
	var subject: Node3D = player if active_car == null else active_car
	var yaw := subject.rotation.y
	var offset := Vector3(0, 4.2, 7.4).rotated(Vector3.UP, yaw)
	var target_position := subject.global_position + offset
	camera.global_position = camera.global_position.lerp(target_position, minf(delta * 5.0, 1.0))
	camera.look_at(subject.global_position + Vector3(0, 1.1, 0), Vector3.UP)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MobileHUD"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var title := Label.new()
	title.text = "صراع العصابات | عالم مفتوح"
	title.position = Vector2(18, 12)
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	root.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(20, 48)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	root.add_child(status_label)

	hint_label = Label.new()
	hint_label.text = "تحرك بالأسهم — اقترب من سيارة واضغط دخول/خروج"
	hint_label.anchor_left = 0.5
	hint_label.anchor_right = 0.5
	hint_label.offset_left = -300
	hint_label.offset_right = 300
	hint_label.offset_top = 15
	hint_label.offset_bottom = 48
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	root.add_child(hint_label)

	# أزرار ضغط مستمر؛ مواقعها مثبتة إلى أركان الشاشة لتناسب اللمس.
	_make_hold_button(root, "◀", Vector2(24, -146), Vector2(68, 62), "left")
	_make_hold_button(root, "▶", Vector2(170, -146), Vector2(68, 62), "right")
	_make_hold_button(root, "▲", Vector2(97, -217), Vector2(68, 62), "forward")
	_make_hold_button(root, "▼", Vector2(97, -75), Vector2(68, 62), "back")

	var enter_button := Button.new()
	enter_button.text = "دخول / خروج"
	enter_button.anchor_left = 1.0
	enter_button.anchor_right = 1.0
	enter_button.anchor_top = 1.0
	enter_button.anchor_bottom = 1.0
	enter_button.offset_left = -190
	enter_button.offset_right = -20
	enter_button.offset_top = -105
	enter_button.offset_bottom = -35
	enter_button.add_theme_font_size_override("font_size", 18)
	enter_button.add_theme_color_override("font_color", Color.WHITE)
	enter_button.add_theme_stylebox_override("normal", _button_style(Color(0.04, 0.32, 0.72, 0.92)))
	enter_button.add_theme_stylebox_override("pressed", _button_style(Color(0.02, 0.22, 0.55, 1.0)))
	enter_button.pressed.connect(_toggle_vehicle)
	root.add_child(enter_button)

func _make_hold_button(root: Control, text_value: String, bottom_left_position: Vector2, button_size: Vector2, direction_name: String) -> void:
	var button := Button.new()
	button.text = text_value
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = bottom_left_position.x
	button.offset_right = bottom_left_position.x + button_size.x
	button.offset_top = bottom_left_position.y
	button.offset_bottom = bottom_left_position.y + button_size.y
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.11, 0.15, 0.78)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.10, 0.35, 0.68, 0.95)))
	button.button_down.connect(func(): _set_direction(direction_name, true))
	button.button_up.connect(func(): _set_direction(direction_name, false))
	root.add_child(button)

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.45, 0.65, 0.88, 0.7)
	return style

func _set_direction(direction_name: String, pressed: bool) -> void:
	match direction_name:
		"left": held_left = pressed
		"right": held_right = pressed
		"forward": held_forward = pressed
		"back": held_back = pressed

func _toggle_vehicle() -> void:
	if active_car != null:
		var car := active_car
		car.set_driven(false)
		active_car = null
		player.global_position = car.global_position + car.global_transform.basis.x * 2.2 + Vector3(0, 0.1, 0)
		player.rotation.y = car.rotation.y
		player.visible = true
		player.controls_enabled = true
		player.collision_layer = 1
		player.collision_mask = 1
		return

	var nearest: DrivableCar = null
	var nearest_distance := 4.5
	for car in cars:
		var distance := player.global_position.distance_to(car.global_position)
		if distance < nearest_distance:
			nearest = car
			nearest_distance = distance
	if nearest != null:
		active_car = nearest
		player.controls_enabled = false
		player.visible = false
		player.collision_layer = 0
		player.collision_mask = 0
		nearest.set_driven(true)
	else:
		hint_label.text = "اقترب أكثر من إحدى السيارات ثم اضغط دخول / خروج"

func _update_hud() -> void:
	if status_label == null:
		return
	if active_car == null:
		status_label.text = "الوضع: مشي    |    المباني: %d    |    السيارات: %d" % [city_building_count, cars.size()]
	else:
		status_label.text = "الوضع: قيادة    |    السرعة التقريبية: %d" % int(absf(active_car.current_speed))

func _add_box(parent: Node, node_name: String, position_value: Vector3, size_value: Vector3, color: Color, solid: bool) -> Node3D:
	var container: Node3D
	if solid:
		container = StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size_value
		collider.shape = shape
		container.add_child(collider)
	else:
		container = Node3D.new()
	container.name = node_name
	container.position = position_value
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size_value
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	mesh_instance.material_override = material
	container.add_child(mesh_instance)
	parent.add_child(container)
	return container

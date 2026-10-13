class_name DrivableCar
extends CharacterBody3D

## سيارة مبسطة قابلة للقيادة، مبنية من أشكال ثلاثية الأبعاد لتجنب ملفات خارجية.
var is_driven: bool = false
var drive_input: Vector2 = Vector2.ZERO # x = توجيه، y = أمام/خلف
var current_speed: float = 0.0
var max_speed: float = 17.0
var acceleration: float = 13.0
var steering_speed: float = 1.45
var gravity_strength: float = 20.0

func _ready() -> void:
	_build_car_visuals()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.9, 1.25, 3.7)
	collider.shape = box
	collider.position.y = 0.72
	add_child(collider)
	collision_layer = 1
	collision_mask = 1

func set_drive_input(value: Vector2) -> void:
	drive_input = value.limit_length(1.0)

func set_driven(value: bool) -> void:
	is_driven = value
	if not value:
		drive_input = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_driven:
		if absf(drive_input.y) > 0.05:
			current_speed = move_toward(current_speed, drive_input.y * max_speed, acceleration * delta)
		else:
			current_speed = move_toward(current_speed, 0.0, 5.5 * delta)
		if absf(current_speed) > 0.25:
			rotation.y -= drive_input.x * steering_speed * delta * clampf(absf(current_speed) / 5.0, 0.25, 1.0) * signf(current_speed)
		var forward := -global_transform.basis.z
		velocity.x = forward.x * current_speed
		velocity.z = forward.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 2.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 2.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _build_car_visuals() -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.72, 0.12, 0.09)
	paint.metallic = 0.3
	paint.roughness = 0.38
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(1.85, 0.62, 3.55)
	body.mesh = body_mesh
	body.material_override = paint
	body.position.y = 0.75
	add_child(body)

	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.08, 0.16, 0.20)
	glass.metallic = 0.15
	glass.roughness = 0.2
	var cabin := MeshInstance3D.new()
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.35, 0.62, 1.65)
	cabin.mesh = cabin_mesh
	cabin.material_override = glass
	cabin.position = Vector3(0, 1.32, -0.12)
	add_child(cabin)

	var wheel_material := StandardMaterial3D.new()
	wheel_material.albedo_color = Color(0.035, 0.035, 0.04)
	for x in [-0.96, 0.96]:
		for z in [-1.15, 1.15]:
			var wheel := MeshInstance3D.new()
			var wheel_mesh := CylinderMesh.new()
			wheel_mesh.top_radius = 0.34
			wheel_mesh.bottom_radius = 0.34
			wheel_mesh.height = 0.22
			wheel.mesh = wheel_mesh
			wheel.material_override = wheel_material
			wheel.rotation.z = PI / 2.0
			wheel.position = Vector3(x, 0.38, z)
			add_child(wheel)

	var lamp_material := StandardMaterial3D.new()
	lamp_material.albedo_color = Color(1.0, 0.88, 0.58)
	lamp_material.emission_enabled = true
	lamp_material.emission = Color(0.8, 0.65, 0.25)
	for x in [-0.58, 0.58]:
		var lamp := MeshInstance3D.new()
		var lamp_mesh := BoxMesh.new()
		lamp_mesh.size = Vector3(0.28, 0.16, 0.06)
		lamp.mesh = lamp_mesh
		lamp.material_override = lamp_material
		lamp.position = Vector3(x, 0.82, -1.79)
		add_child(lamp)

class_name OpenWorldPlayer
extends CharacterBody3D

## لاعب منظور الشخص الثالث. يتحرك بأزرار الشاشة أو WASD/الأسهم.
var controls_enabled: bool = true
var touch_input: Vector2 = Vector2.ZERO
var move_speed: float = 5.3
var gravity_strength: float = 18.0

func _ready() -> void:
	_build_player_visuals()
	var collider := CollisionShape3D.new()
	collider.name = "PlayerCollider"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	collision_layer = 1
	collision_mask = 1

func set_touch_input(value: Vector2) -> void:
	touch_input = value.limit_length(1.0)

func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var keyboard := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		keyboard.y += 1.0

	var input_vector := (touch_input + keyboard).limit_length(1.0)
	var direction := Vector3(input_vector.x, 0.0, input_vector.y).rotated(Vector3.UP, rotation.y)
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 10.0, 1.0))
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 7.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 7.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _build_player_visuals() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.10, 0.31, 0.72)
	material.roughness = 0.8
	var body := MeshInstance3D.new()
	body.name = "PlayerBody"
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.36
	capsule_mesh.height = 1.65
	body.mesh = capsule_mesh
	body.material_override = material
	body.position.y = 0.9
	add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.22
	head_mesh.height = 0.44
	head.mesh = head_mesh
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.77, 0.57, 0.41)
	head.material_override = skin
	head.position = Vector3(0, 1.82, 0)
	add_child(head)

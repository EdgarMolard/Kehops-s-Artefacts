extends CharacterBody3D

const SPEED := 5.0
const ROTATION_SPEED := 2.5

func _physics_process(delta: float) -> void:
	# Gauche / droite : rotation sur place
	var rotation_input := Input.get_axis("ui_left", "ui_right")
	rotate_y(-rotation_input * ROTATION_SPEED * delta)

	# Haut / bas : déplacement avant / arrière
	var movement_input := Input.get_axis("ui_down", "ui_up")
	var forward_direction := -transform.basis.z

	if movement_input != 0.0:
		velocity.x = forward_direction.x * movement_input * SPEED
		velocity.z = forward_direction.z * movement_input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	velocity.y = 0.0
	move_and_slide()

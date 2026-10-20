extends CharacterBody3D

const SPEED := 5.0
const ROTATION_SPEED := 2.5

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
var movement_animation_name: String = ""

func _ready() -> void:
	if animation_player == null:
		push_warning("Aucun AnimationPlayer trouvé dans le modèle du joueur.")
		return

	for animation_name in animation_player.get_animation_list():
		if animation_name != "RESET":
			movement_animation_name = animation_name
			break

	if movement_animation_name == "":
		push_warning("Aucune animation jouable trouvée dans le modèle du joueur.")
		return

	var animation := animation_player.get_animation(movement_animation_name)
	animation.loop_mode = Animation.LOOP_LINEAR

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
		_play_movement_animation()
		
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_stop_movement_animation()

	velocity.y = 0.0
	move_and_slide()


func _play_movement_animation() -> void:
	if animation_player == null or movement_animation_name == "":
		return

	if animation_player.current_animation != movement_animation_name:
		animation_player.play(movement_animation_name)

func _stop_movement_animation() -> void:
	if animation_player == null:
		return

	if animation_player.is_playing():
		animation_player.stop()

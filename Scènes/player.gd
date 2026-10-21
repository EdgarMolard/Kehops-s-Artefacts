extends CharacterBody3D

const SPEED := 5.0
const ROTATION_SPEED := 2.5

var joystick_dir := Vector2.ZERO
var keyboard_dir := Vector2.ZERO

# Gestion des animations
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
var movement_animation_name: String = ""


func _on_arduino_message(key: String, value: String) -> void:
	match key:
		"joystick_x":
			joystick_dir.x = remap(value.to_float(), 0.0, 1023.0, -1.0, 1.0)
			if abs(joystick_dir.x) < 0.15:
				joystick_dir.x = 0.0
		"joystick_y":
			joystick_dir.y = remap(value.to_float(), 0.0, 1023.0, -1.0, 1.0)
			if abs(joystick_dir.y) < 0.15:
				joystick_dir.y = 0.0


func _ready() -> void:
	add_to_group("joueur")
	ArduinoManager.message_received.connect(_on_arduino_message)

	# Configuration des animations
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
	keyboard_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_dir := joystick_dir
	if not is_zero_approx(keyboard_dir.x):
		input_dir.x = keyboard_dir.x
	if not is_zero_approx(keyboard_dir.y):
		input_dir.y = keyboard_dir.y

	rotate_y(-input_dir.x * ROTATION_SPEED * delta)

	var forward_direction := -transform.basis.z

	if abs(input_dir.y) > 0.05:
		velocity.x = forward_direction.x * (-input_dir.y) * SPEED
		velocity.z = forward_direction.z * (-input_dir.y) * SPEED
		_play_movement_animation()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_stop_movement_animation()

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

extends CharacterBody3D

const SPEED := 5.0
const ROTATION_SPEED := 2.5

var joystick_dir := Vector2.ZERO
var keyboard_dir := Vector2.ZERO

# Gestion des animations
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var movement_sound = get_node_or_null("MovementSound")
var movement_animation_name: String = ""
var movement_sound_active := false


func _on_arduino_message(key: String, value: String) -> void:
	# Les axes Arduino sont convertis dans l'intervalle utilisé par le déplacement.
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
	# Une boucle évite que l'animation de marche ne s'arrête pendant le déplacement.
	animation.loop_mode = Animation.LOOP_LINEAR


func _physics_process(delta: float) -> void:
	# Le clavier complète le joystick et remplace seulement ses axes actifs.
	keyboard_dir = Input.get_vector("Gauche", "Droite", "Avancer", "Reculer")
	if keyboard_dir.is_zero_approx():
		keyboard_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_dir := joystick_dir
	if not is_zero_approx(keyboard_dir.x):
		input_dir.x = keyboard_dir.x
	if not is_zero_approx(keyboard_dir.y):
		input_dir.y = keyboard_dir.y


	rotate_y(-input_dir.x * ROTATION_SPEED * delta)

	# L'axe vertical avance dans la direction où regarde le personnage.
	var forward_direction := -transform.basis.z

	if abs(input_dir.y) > 0.05:
		velocity.x = forward_direction.x * (-input_dir.y) * SPEED
		velocity.z = forward_direction.z * (-input_dir.y) * SPEED
		_play_movement_animation()
		_start_movement_sound()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_stop_movement_animation()
		_stop_movement_sound()

	move_and_slide()


func _play_movement_animation() -> void:
	if animation_player == null or movement_animation_name == "":
		return

	if animation_player.current_animation != movement_animation_name:
		# Ne relance pas l'animation à chaque image, seulement lors de son changement.
		animation_player.play(movement_animation_name)


func _stop_movement_animation() -> void:
	if animation_player == null:
		return

	if animation_player.is_playing():
		animation_player.stop()


func _start_movement_sound() -> void:
	if not movement_sound_active and movement_sound != null and movement_sound.event_name != "":
		movement_sound.play()
		movement_sound_active = true


func _stop_movement_sound() -> void:
	if movement_sound_active and movement_sound != null and movement_sound.event_name != "":
		movement_sound.stop()
		movement_sound_active = false

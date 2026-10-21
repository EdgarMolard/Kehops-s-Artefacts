extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const ROTATION_SPEED := 2.5

# Gravité par défaut du projet 3D
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Gestion WebSocket pour l'Arduino
var socket = WebSocketPeer.new()
var joystick_dir := Vector2.ZERO
var button_pressed := false

# Gestion des animations
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
var movement_animation_name: String = ""

func _ready() -> void:
	add_to_group("joueur")
	
	# Connexion au serveur Python (bridge.py)
	var err = socket.connect_to_url("ws://localhost:8080")
	if err != OK:
		print("Erreur de connexion au serveur WebSocket Joystick : ", err)

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

func _process(_delta: float) -> void:
	# Récupération des données du joystick en tâche de fond (WebSocket)
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var data_str = packet.get_string_from_utf8()
			_parse_joystick_data(data_str)

func _parse_joystick_data(data: String) -> void:
	# Format reçu : "X,Y,SW" (ex: "512,508,1")
	var parts = data.split(",")
	if parts.size() == 3:
		var raw_x = parts[0].to_int()
		var raw_y = parts[1].to_int()
		var sw = parts[2].to_int()

		# Conversion de 0..1023 vers -1.0..1.0
		var dir_x = remap(raw_x, 0, 1023, -1.0, 1.0)
		var dir_y = remap(raw_y, 0, 1023, -1.0, 1.0)

		# Zone morte (Deadzone) pour éviter la dérive au repos
		if abs(dir_x) < 0.15: dir_x = 0.0
		if abs(dir_y) < 0.15: dir_y = 0.0

		joystick_dir = Vector2(dir_x, dir_y)
		button_pressed = (sw == 0) # Le bouton est actif à l'état BAS (0)

func _physics_process(delta: float) -> void:
	# 1. Gestion de la gravité
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# 2. Gestion du saut avec le bouton du joystick (SW)
	if button_pressed and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Rotation gauche / droite avec l'axe X du joystick
	# joystick_dir.x va de -1 (gauche) à 1 (droite)
	rotate_y(-joystick_dir.x * ROTATION_SPEED * delta)

	# 4. Avancer / Reculer avec l'axe Y du joystick
	# Note : Sur un joystick, pousser vers le haut donne souvent 0 ou 1023 selon le sens du câblage.
	# Ici on utilise joystick_dir.y (positif ou négatif)
	var forward_direction := -transform.basis.z

	if abs(joystick_dir.y) > 0.05:
		# joystick_dir.y inversé selon si pousser en haut avance ou recule
		velocity.x = forward_direction.x * (-joystick_dir.y) * SPEED
		velocity.z = forward_direction.z * (-joystick_dir.y) * SPEED
		_play_movement_animation()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_stop_movement_animation()

	# 5. Application du mouvement physique
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

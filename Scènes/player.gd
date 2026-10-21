extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const ROTATION_SPEED := 2.0

# Distance minimale du capteur à ultrasons pour déclencher le ramassage (en cm)
const SEUIL_DISTANCE_RAMASSAGE := 10 

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Gestion WebSocket & Capteurs
var socket = WebSocketPeer.new()
var object_distance := 999 # Distance renvoyée par le capteur en cm
var button_pressed := false

# Références aux nœuds
@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
@onready var pickup_area: Area3D = $PickupArea # Zone de détection devant le joueur

var movement_animation_name: String = ""
var objet_a_portee: Node3D = null # Contient l'objet 3D actuellement proche du joueur

func _ready() -> void:
	add_to_group("joueur")
	
	# Connexion au serveur Python (bridge.py)
	var err = socket.connect_to_url("ws://localhost:8080")
	if err != OK:
		print("Erreur de connexion WebSocket : ", err)

	# Connexion des signaux de la zone de ramassage
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_body_entered)
		pickup_area.body_exited.connect(_on_pickup_area_body_exited)

	# Configuration des animations
	if animation_player:
		for anim in animation_player.get_animation_list():
			if anim != "RESET":
				movement_animation_name = anim
				break
		if movement_animation_name != "":
			animation_player.get_animation(movement_animation_name).loop_mode = Animation.LOOP_LINEAR

func _process(_delta: float) -> void:
	# Traitement des messages WebSocket venus d'Arduino via Python
	socket.poll()
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			_parse_arduino_data(packet.get_string_from_utf8())

func _parse_arduino_data(data: String) -> void:
	# Format reçu depuis l'Arduino : "X,Y,SW,Distance" (ex: "512,508,1,8")
	var parts = data.split(",")
	if parts.size() >= 4:
		var sw = parts[2].to_int()
		object_distance = parts[3].to_int() # Distance du capteur à ultrasons en cm
		button_pressed = (sw == 0)

		# --- DÉTECTION ULTRASON ET RAMASSAGE D'OBJET ---
		# Si la main passe devant le capteur (< 10 cm) et qu'un objet 3D est devant le joueur
		if object_distance <= SEUIL_DISTANCE_RAMASSAGE and objet_a_portee != null:
			_ramasser_objet(objet_a_portee)

func _physics_process(delta: float) -> void:
	# 1. Gravité
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# 2. Saut au clavier (touche Espace) ou via le bouton du joystick si branché
	if (Input.is_action_just_pressed("ui_accept") or button_pressed) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Rotation au clavier (Touches Gauche / Droite ou Q / D)
	var rotation_input := Input.get_axis("ui_left", "ui_right")
	rotate_y(-rotation_input * ROTATION_SPEED * delta)

	# 4. Avancer / Reculer au clavier (Touches Haut / Bas ou Z / S)
	var movement_input := Input.get_axis("ui_down", "ui_up") # Ou ui_up / ui_down selon vos réglages
	var forward_direction := -transform.basis.z

	if movement_input != 0.0:
		velocity.x = forward_direction.x * movement_input * SPEED
		velocity.z = forward_direction.z * movement_input * SPEED
		_play_movement_animation()
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
		_stop_movement_animation()

	move_and_slide()

# --- LOGIQUE DE RAMASSAGE DES OBJETS 3D ---

func _on_pickup_area_body_entered(body: Node) -> void:
	if body.is_in_group("objets") or body is RigidBody3D:
		objet_a_portee = body
		print("Objet à portée détecté : ", body.name)

func _on_pickup_area_body_exited(body: Node) -> void:
	if body == objet_a_portee:
		objet_a_portee = null

func _ramasser_objet(objet: Node3D) -> void:
	print("OBJET RAMASSÉ ! Distance capteur : ", object_distance, " cm. Objet : ", objet.name)
	
	# Suppression de l'objet dans le jeu
	objet.queue_free()
	objet_a_portee = null
	
	# Envoi du signal à Python/Arduino pour allumer la LED verte
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text("V") 

func _play_movement_animation() -> void:
	if animation_player and movement_animation_name != "" and animation_player.current_animation != movement_animation_name:
		animation_player.play(movement_animation_name)

func _stop_movement_animation() -> void:
	if animation_player and animation_player.is_playing():
		animation_player.stop()

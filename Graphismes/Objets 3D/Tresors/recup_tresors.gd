class_name TresorArtefact
extends Area3D

static var _derniere_interaction_frame := -1

@export var id_tresor: int = 1

var joueur_proche := false
var recupere := false
var joueur: Node3D


func _ready() -> void:
	add_to_group("tresors")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	ArduinoManager.interaction_requested.connect(_on_interaction_requested)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = true
		joueur = body
		if not recupere:
			ArduinoManager.send_artifact_near(id_tresor, true)


func _on_body_exited(body: Node3D) -> void:
	if body == joueur:
		joueur_proche = false
		joueur = null
		if not recupere:
			ArduinoManager.send_artifact_near(id_tresor, false)


func _process(_delta: float) -> void:
	if joueur_proche and Input.is_action_just_pressed("Interagir"):
		_interagir_avec_le_plus_proche()

func _on_interaction_requested() -> void:
	if joueur_proche:
		_interagir_avec_le_plus_proche()

func _interagir_avec_le_plus_proche() -> void:
	var frame := Engine.get_process_frames()
	if _derniere_interaction_frame == frame:
		return

	var plus_proche: TresorArtefact
	var distance_min := INF
	for tresor: TresorArtefact in get_tree().get_nodes_in_group("tresors"):
		if tresor.recupere or not tresor.joueur_proche or not is_instance_valid(tresor.joueur):
			continue

		var distance := tresor.joueur.global_position.distance_squared_to(tresor.global_position)
		if distance < distance_min:
			distance_min = distance
			plus_proche = tresor

	if plus_proche == null:
		return

	_derniere_interaction_frame = frame
	plus_proche.recuperer()

func recuperer() -> void:
	if recupere:
		return

	recupere = true
	_marquer_comme_recupere()

	print("Trésor ", id_tresor, " récupéré")

	ArduinoManager.send_artifact(id_tresor)
	queue_free()
	if g_vars.tous_les_tresors_recuperes():
		print("La salle finale peut être ouverte")


func _marquer_comme_recupere() -> void:
	match id_tresor:
		1:
			g_vars.tresor_1_recupere = true
		2:
			g_vars.tresor_2_recupere = true
		3:
			g_vars.tresor_3_recupere = true
		_:
			push_error("Identifiant de trésor invalide : " + str(id_tresor))

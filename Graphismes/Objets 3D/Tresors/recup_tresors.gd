extends Area3D

@export var id_tresor: int = 1
@export var modele: PackedScene
@export var duree_son_ramassage: float = 3.0
@export var distance_froide_max: float = 45.0
@export_range(0.0, 1.0, 0.01) var volume_froid: float = 0.05
var joueur_proche := false
var recupere := false
var interaction_ui: InteractionUI
@onready var proximity_sound = get_node_or_null("ProximitySound")
@onready var pickup_sound = get_node_or_null("PickupSound")

func _ready() -> void:
	# Les connexions sont faites ici pour que chaque trésor gère seul ses interactions.
	add_to_group("tresors")
	interaction_ui = get_parent().get_node_or_null("CanvasLayer") as InteractionUI
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	ArduinoManager.interaction_requested.connect(_on_interaction_requested)
	_refresh_proximity_sound()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = true
		if interaction_ui != null:
			interaction_ui.show_prompt(self, "E/Tendre la main pour récupérer")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = false
		if interaction_ui != null:
			interaction_ui.hide_prompt(self)


func _process(_delta: float) -> void:
	# Le joueur peut utiliser le clavier ou demander l'interaction via Arduino.
	if joueur_proche and Input.is_action_just_pressed("Interagir"):
		recuperer()
	if not recupere and _is_next_treasure() and proximity_sound != null:
		_actualiser_volume_proximite()

func _on_interaction_requested() -> void:
	if joueur_proche:
		recuperer()

func recuperer() -> void:
	if recupere:
		return

	recupere = true
	# L'état est verrouillé avant les effets pour empêcher une double récupération.
	if interaction_ui != null:
		interaction_ui.hide_prompt(self)
	_marquer_comme_recupere()
	_stop_proximity_sound()
	_detacher_son_ramassage()

	print("Trésor ", id_tresor, " récupéré")

	if id_tresor >= 1 and id_tresor <= 3:
		# Les trois premiers trésors font avancer l'indication lumineuse Arduino.
		ArduinoManager.send_led(true)
	elif id_tresor == 4:
		# Le quatrième trésor lance le défi de retour vers l'entrée.
		g_vars.tresor_4_recupere = true
		g_vars.tresor_4_recupere_signal.emit()
	queue_free()
	if g_vars.tous_les_tresors_recuperes():
		print("La salle finale peut être ouverte")
	for tresor in get_tree().get_nodes_in_group("tresors"):
		if tresor != self and is_instance_valid(tresor):
			tresor._refresh_proximity_sound()


func _refresh_proximity_sound() -> void:
	# Un seul trésor à la fois signale la prochaine étape de la progression.
	if recupere:
		_stop_proximity_sound()
	elif _is_next_treasure():
		if proximity_sound != null:
			_stop_other_proximity_sounds()
			proximity_sound.play()
			_actualiser_volume_proximite()
	else:
		_stop_proximity_sound()


func _is_next_treasure() -> bool:
	# La collecte est volontairement séquentielle pour guider le joueur.
	match id_tresor:
		1:
			return not g_vars.tresor_1_recupere
		2:
			return g_vars.tresor_1_recupere and not g_vars.tresor_2_recupere
		3:
			return g_vars.tresor_2_recupere and not g_vars.tresor_3_recupere
		4:
			return g_vars.tresor_3_recupere
		_:
			return false


func _stop_other_proximity_sounds() -> void:
	for tresor in get_tree().get_nodes_in_group("tresors"):
		if tresor == self or not is_instance_valid(tresor):
			continue
		var other_sound = tresor.get_node_or_null("ProximitySound")
		if other_sound != null:
			other_sound.stop()


func _actualiser_volume_proximite() -> void:
	var joueur := get_tree().get_first_node_in_group("joueur") as Node3D
	if joueur == null:
		return
	var distance := global_position.distance_to(joueur.global_position)
	var progression := clampf(distance / maxf(distance_froide_max, 0.1), 0.0, 1.0)
	# Le son diminue progressivement lorsque le joueur s'éloigne du trésor.
	var volume := lerpf(1.0, volume_froid, progression)
	proximity_sound.set_volume(volume)


func _stop_proximity_sound() -> void:
	if proximity_sound != null:
		proximity_sound.stop()


func _marquer_comme_recupere() -> void:
	match id_tresor:
		1:
			g_vars.tresor_1_recupere = true
		2:
			g_vars.tresor_2_recupere = true
		3:
			g_vars.tresor_3_recupere = true
		4:
			g_vars.tresor_4_recupere = true
		_:
			push_error("Identifiant de trésor invalide : " + str(id_tresor))


func _detacher_son_ramassage() -> void:
	if pickup_sound == null or pickup_sound.event_name == "":
		return
	var scene = get_tree().current_scene
	if scene == null:
		return
	var sound = pickup_sound
	# Le son est déplacé dans la scène avant la suppression du trésor.
	sound.reparent(scene, true)
	sound.play()
	get_tree().create_timer(maxf(duree_son_ramassage, 0.1)).timeout.connect(
		func():
			if is_instance_valid(sound):
				sound.queue_free()
	)

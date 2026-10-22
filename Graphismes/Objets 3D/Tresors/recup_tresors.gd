extends Area3D

@export var id_tresor: int = 1

var joueur_proche := false
var recupere := false
var interaction_ui: InteractionUI

func _ready() -> void:
	interaction_ui = get_parent().get_node_or_null("CanvasLayer") as InteractionUI
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	ArduinoManager.interaction_requested.connect(_on_interaction_requested)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = true
		if interaction_ui != null:
			interaction_ui.show_prompt(self, "E — Récupérer")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = false
		if interaction_ui != null:
			interaction_ui.hide_prompt(self)


func _process(_delta: float) -> void:
	if joueur_proche and Input.is_action_just_pressed("Interagir"):
		recuperer()

func _on_interaction_requested() -> void:
	if joueur_proche:
		recuperer()

func recuperer() -> void:
	if recupere:
		return

	recupere = true
	if interaction_ui != null:
		interaction_ui.hide_prompt(self)
	_marquer_comme_recupere()

	print("Trésor ", id_tresor, " récupéré")

	ArduinoManager.send_led(true)
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

extends Node3D

@onready var zone_interaction: Area3D = $ZoneInteraction
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var door_sound = $DoorSound

var joueur_proche := false
var ouverte := false
var interaction_ui: InteractionUI

func _ready() -> void:
	interaction_ui = get_parent().get_node_or_null("CanvasLayer") as InteractionUI
	zone_interaction.body_entered.connect(_on_body_entered)
	zone_interaction.body_exited.connect(_on_body_exited)
	ArduinoManager.interaction_requested.connect(_on_interaction_requested)

	if not animation_player.has_animation("Ouvrir"):
		push_error("L'animation « ouvrir » est absente de la porte.")


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = true
		if ouverte:
			return

		if g_vars.tous_les_tresors_recuperes():
			if interaction_ui != null:
				interaction_ui.show_prompt(self, "E/Pousser la porte avec vos mains")
		else:
			if interaction_ui != null:
				interaction_ui.show_prompt(self, "Trésors requis")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = false
		if interaction_ui != null:
			interaction_ui.hide_prompt(self)


func _process(_delta: float) -> void:
	if not joueur_proche:
		return

	if ouverte:
		return

	if not Input.is_action_just_pressed("Interagir"):
		return

	if not g_vars.tous_les_tresors_recuperes():
		print("La porte est verrouillée : les trois trésors sont nécessaires.")
		return

	ouvrir()


func _on_interaction_requested() -> void:
	if joueur_proche and not ouverte:
		if not g_vars.tous_les_tresors_recuperes():
			print("La porte est verrouillée : les trois trésors sont nécessaires.")
			return

		ouvrir()


func ouvrir() -> void:
	if ouverte:
		return

	if not animation_player.has_animation("Ouvrir"):
		push_error("Impossible d'ouvrir la porte : animation « ouvrir » introuvable.")
		return

	ouverte = true
	if interaction_ui != null:
		interaction_ui.hide_prompt(self)
	if door_sound.event_name != "":
		door_sound.play()
	animation_player.play("Ouvrir")
	print("La porte s'ouvre")

extends Node3D

@onready var zone_interaction: Area3D = $ZoneInteraction
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var joueur_proche := false
var ouverte := false


func _ready() -> void:
	zone_interaction.body_entered.connect(_on_body_entered)
	zone_interaction.body_exited.connect(_on_body_exited)

	if not animation_player.has_animation("Ouvrir"):
		push_error("L'animation « ouvrir » est absente de la porte.")


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = true
		print("Le joueur est devant la porte")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		joueur_proche = false


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


func ouvrir() -> void:
	if ouverte:
		return

	if not animation_player.has_animation("Ouvrir"):
		push_error("Impossible d'ouvrir la porte : animation « ouvrir » introuvable.")
		return

	ouverte = true
	animation_player.play("Ouvrir")
	print("La porte s'ouvre")

class_name InteractionUI
extends CanvasLayer

@onready var interaction_label: Label = $InteractionLabel

var current_source: Node


func _ready() -> void:
	# Le groupe permet aux objets interactifs de retrouver cette interface.
	add_to_group("interaction_ui")
	interaction_label.hide()


func show_prompt(source: Node, message: String) -> void:
	# On mémorise l'objet affiché pour éviter qu'un autre objet ne masque son message.
	current_source = source
	interaction_label.text = message
	interaction_label.show()


func hide_prompt(source: Node) -> void:
	# Un objet ne peut retirer que sa propre invite d'interaction.
	if current_source != source:
		return

	current_source = null
	interaction_label.hide()

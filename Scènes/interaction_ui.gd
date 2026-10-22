class_name InteractionUI
extends CanvasLayer

@onready var interaction_label: Label = $InteractionLabel

var current_source: Node


func _ready() -> void:
	add_to_group("interaction_ui")
	interaction_label.hide()


func show_prompt(source: Node, message: String) -> void:
	current_source = source
	interaction_label.text = message
	interaction_label.show()


func hide_prompt(source: Node) -> void:
	if current_source != source:
		return

	current_source = null
	interaction_label.hide()

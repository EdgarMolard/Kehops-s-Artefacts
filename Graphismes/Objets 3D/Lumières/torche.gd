extends Node3D

signal activated

@export var starts_lit := false
@export var flame_light_position := Vector3(0.0, 1.5, 0.0)
@export_range(0, 1023, 1) var luminosity_threshold := 500

@onready var flame_light: OmniLight3D = $FlameLight
@onready var interaction_area: Area3D = $InteractionArea

var player_nearby := false
var is_lit := false
var interaction_ui: InteractionUI


func _ready() -> void:
	interaction_ui = get_parent().get_node_or_null("CanvasLayer") as InteractionUI
	if flame_light == null:
		push_error("Torche : le nœud FlameLight est introuvable.")
		return
	if interaction_area == null:
		push_error("Torche : le nœud InteractionArea est introuvable.")
		return

	flame_light.position = flame_light_position
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	ArduinoManager.interaction_requested.connect(_on_interaction_requested)
	ArduinoManager.luminosite_updated.connect(_on_luminosite_updated)

	if starts_lit:
		_light_torch()
	else:
		flame_light.visible = false


func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("Interagir"):
		_light_torch()


func _on_interaction_requested() -> void:
	if player_nearby:
		_light_torch()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		player_nearby = true
		_try_light_from_sensor(ArduinoManager.luminosite_value)

		if not is_lit:
			if interaction_ui != null:
				interaction_ui.show_prompt(self, "E — Allumer")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("joueur"):
		player_nearby = false
		if interaction_ui != null:
			interaction_ui.hide_prompt(self)


func _on_luminosite_updated(value: int) -> void:
	_try_light_from_sensor(value)


func _try_light_from_sensor(value: int) -> void:
	if player_nearby and value >= luminosity_threshold:
		_light_torch()


func _light_torch() -> void:
	if is_lit:
		return

	is_lit = true
	if interaction_ui != null:
		interaction_ui.hide_prompt(self)
	flame_light.visible = true
	activated.emit()

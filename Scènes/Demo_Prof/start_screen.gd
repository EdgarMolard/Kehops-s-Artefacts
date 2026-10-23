extends Node
# Called when the node enters the scene tree for the first time.
@onready var fade_overlay = %FadeOverlay
@onready var StatusDot = %StatusDot
@onready var StatusLabel = %StatusLabel
@onready var StartButton = %StartButton
func _ready() -> void:
	# L'écran attend la connexion Arduino avant d'autoriser le démarrage normal.
	ArduinoManager.arduino_connected.connect(_on_arduino_connected)
	ArduinoManager.arduino_disconnected.connect(_on_arduino_disconnected)
	
	StatusDot.modulate = Color.RED
	StatusLabel.text = "Manette Pas Connectée"
	StartButton.disabled = true
	if ArduinoManager.paired_port != "":
		# Si l'Arduino était déjà associé avant l'affichage de l'écran, on met l'UI à jour.
		_on_arduino_connected()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Cet écran ne nécessite aucun traitement continu.
	pass

func _on_arduino_connected():
	# La connexion active le bouton de démarrage avec le matériel.
	StatusDot.modulate = Color.GREEN
	StatusLabel.text = "Manette Connecté"
	StartButton.disabled = false
	
func _on_arduino_disconnected():
	# Une déconnexion bloque le démarrage pour éviter une partie incomplète.
	StatusDot.modulate = Color.RED
	StatusLabel.text = "Déconnecté"
	StartButton.disabled = true

func _on_start_button_pressed() -> void:
	# Le fondu est appliqué avant le chargement de la scène de jeu.
	fade_overlay.modulate.a = 1
	get_tree().change_scene_to_file("res://Scènes/MouvementTest.tscn")

func _on_start_button_without_arduino_pressed() -> void:
	# Le mode secours permet de jouer au clavier sans périphérique Arduino.
	fade_overlay.modulate.a = 1
	g_vars.no_arduino = true
	get_tree().change_scene_to_file("res://Scènes/MouvementTest.tscn")
	

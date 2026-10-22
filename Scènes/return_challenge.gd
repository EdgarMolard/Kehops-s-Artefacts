extends Node3D

const POLICE_DALEK: FontFile = preload("res://Graphismes/Dalek.ttf")
const DUREE_RETOUR := 60.0
const POINT_DEPART := Vector3(-0.79693127, 0.4733305, 20.576843)

@export var rayon_zone_retour := 5.0
@export var distance_froide_max := 45.0
@export_range(0.0, 2.0, 0.01) var volume_chaud := 1.2
@export_range(0.0, 1.0, 0.01) var volume_froid := 0.05

@onready var joueur: Node3D = get_node_or_null("Player")
@onready var vent = get_node_or_null("ReturnWind")

var temps_restant := 0.0
var defi_actif := false
var defi_termine := false
var chrono_message: Label
var chrono_label: Label

func _enter_tree() -> void:
	g_vars.reinitialiser_progression()

func _ready() -> void:
	g_vars.tresor_4_recupere_signal.connect(_demarrer_defi_retour)
	_creer_hud_chrono()

func _process(delta: float) -> void:
	if not defi_actif or defi_termine or joueur == null:
		return

	temps_restant = maxf(temps_restant - delta, 0.0)
	_actualiser_affichage_chrono()
	_actualiser_volume_vent()

	if joueur.global_position.distance_to(POINT_DEPART) <= rayon_zone_retour:
		_afficher_resultat(true)
	elif is_zero_approx(temps_restant):
		_afficher_resultat(false)

func _demarrer_defi_retour() -> void:
	if defi_actif:
		return
	defi_actif = true
	temps_restant = DUREE_RETOUR
	chrono_label.visible = true
	chrono_message.visible = true
	if vent != null:
		vent.play()
	_actualiser_affichage_chrono()
	_actualiser_volume_vent()

func _actualiser_volume_vent() -> void:
	if vent == null or joueur == null:
		return
	var distance := joueur.global_position.distance_to(POINT_DEPART)
	var progression := clampf(distance / maxf(distance_froide_max, 0.1), 0.0, 1.0)
	vent.set_volume(lerpf(volume_chaud, volume_froid, progression))

func _actualiser_affichage_chrono() -> void:
	if chrono_label != null:
		chrono_label.text = "%02d:%02d" % [
			int(temps_restant) / 60,
			int(temps_restant) % 60
		]

func _creer_hud_chrono() -> void:
	var couche := CanvasLayer.new()
	couche.layer = 10
	add_child(couche)

	chrono_message = Label.new()
	chrono_message.set_anchors_preset(Control.PRESET_TOP_WIDE)
	chrono_message.offset_top = 20.0
	chrono_message.offset_bottom = 85.0
	chrono_message.text = "La pyramide s'éffondre ! Retourne vite à l'entrée du labyrinthe :"
	chrono_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chrono_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chrono_message.add_theme_font_override("font", POLICE_DALEK)
	chrono_message.add_theme_font_size_override("font_size", 48)
	chrono_message.visible = false
	couche.add_child(chrono_message)

	chrono_label = Label.new()
	chrono_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	chrono_label.offset_top = 80.0
	chrono_label.offset_bottom = 155.0
	chrono_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chrono_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chrono_label.add_theme_font_override("font", POLICE_DALEK)
	chrono_label.add_theme_font_size_override("font_size", 72)
	chrono_label.visible = false
	couche.add_child(chrono_label)

func _afficher_resultat(reussi: bool) -> void:
	if defi_termine:
		return
	defi_termine = true
	defi_actif = false
	if vent != null:
		vent.stop()
	if chrono_label != null:
		chrono_label.visible = false
	if chrono_message != null:
		chrono_message.visible = false
	_creer_ecran_resultat(reussi)

func _creer_ecran_resultat(reussi: bool) -> void:
	var couche := CanvasLayer.new()
	couche.layer = 20
	add_child(couche)

	var fond := ColorRect.new()
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.color = Color8(3, 94, 123)
	couche.add_child(fond)

	var panneau := VBoxContainer.new()
	panneau.set_anchors_preset(Control.PRESET_CENTER)
	panneau.position = Vector2(-300, -80)
	panneau.size = Vector2(600, 160)
	couche.add_child(panneau)

	var titre := Label.new()
	titre.text = "Victoire" if reussi else "Défaite"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titre.add_theme_font_override("font", POLICE_DALEK)
	titre.add_theme_color_override("font_color", Color8(248, 255, 229))
	titre.add_theme_font_size_override("font_size", 96)
	panneau.add_child(titre)

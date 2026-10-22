extends Node

signal tresor_4_recupere_signal

# Référence globale au joueur, disponible pour les scripts qui en ont besoin.
var joueur:CharacterBody3D # a changer en Node3D

# Indique que la partie a été lancée sans connexion Arduino.
var no_arduino = false

# Chaque booléen représente la progression de la collecte dans l'ordre prévu.
var tresor_1_recupere := false
var tresor_2_recupere := false
var tresor_3_recupere := false
var tresor_4_recupere := false

func reinitialiser_progression() -> void:
	# Cette remise à zéro est appelée au lancement d'une nouvelle partie.
	tresor_1_recupere = false
	tresor_2_recupere = false
	tresor_3_recupere = false
	tresor_4_recupere = false

func tous_les_tresors_recuperes() -> bool:
	# Le quatrième trésor déclenche le défi final, il n'est donc pas inclus ici.
	return (
		tresor_1_recupere
		and tresor_2_recupere
		and tresor_3_recupere
	)

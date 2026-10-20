extends Node

var joueur:CharacterBody3D # a changer en Node3D

var no_arduino = false


var tresor_1_recupere := false
var tresor_2_recupere := false
var tresor_3_recupere := false

func tous_les_tresors_recuperes() -> bool:
	return (
		tresor_1_recupere
		and tresor_2_recupere
		and tresor_3_recupere
	)

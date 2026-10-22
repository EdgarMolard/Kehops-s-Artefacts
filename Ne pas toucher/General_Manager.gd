extends Node

# Gère le son des objets qui viennent de disparaitre, et d'autres choses (souvent asynchrone) de la scène
# A un "%unique name" pour y avoir accès plus simplement

func Joue_Un_Son(Son_A_Jouer:AudioStream, Position:Vector3):
	# Un lecteur temporaire permet de jouer le son sans conserver un nœud par effet.
	var audioplayer:AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	add_child(audioplayer)
	audioplayer.position = Position
	audioplayer.stream = Son_A_Jouer
	audioplayer.connect("finished", func(): audioplayer.queue_free())
	# Le lecteur est supprimé dès que la lecture est terminée.
	audioplayer.play()

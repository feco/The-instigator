extends Spatial

#Initialisation du jeu
func _ready():
	randomize() #Initialise le système de génération de nombre aléatoire
	if globals.est_serveur :
		_choix_instigateur()

#Choisir un instigateur au hasard
func _choix_instigateur():
	var instigateur_number = randi() % globals.liste_des_joueurs.size()
	var instigateur = globals.liste_des_joueurs[instigateur_number]
	#Envoie l'infos à l'instigateur sélectionné qu'il est l'instigateur
	rpc_id(instigateur["id"], "_est_instigateur")

#Fonction qui élève le joueur courant au niveau d'instigateur si le serveur lui en envoie l'ordre
remote func _est_instigateur():
	print("Vous êtes un instigateur")
	globals.est_instigateur = true
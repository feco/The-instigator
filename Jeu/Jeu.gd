extends Spatial

var enigmes = null
var enigme_actuelle

#Initialisation du jeu
func _ready():
	randomize() #Initialise le système de génération de nombre aléatoire
	_charger_enigmes()
	if globals.est_serveur :
		_choix_instigateur()
		for i in range(10):
			_poser_enigme()

#Choisir un instigateur au hasard
func _choix_instigateur():
	var instigateur_number = randi() % globals.liste_des_joueurs.size()
	var instigateur = globals.liste_des_joueurs[instigateur_number]
	#Envoie l'infos à l'instigateur sélectionné qu'il est l'instigateur
	print("Instigateur : ")
	print(instigateur["id"])
	rpc_id(instigateur["id"], "_est_instigateur")

#Fonction qui élève le joueur courant au niveau d'instigateur si le serveur lui en envoie l'ordre
remote func _est_instigateur():
	print("Vous êtes un instigateur")
	globals.est_instigateur = true



# --------- ENIGME côté serveur ---------

#Fonction qui liste les fichiers d'un dossier
func _lister_fichier_enigmes():
	var fichiers = []
	var dossier = Directory.new()
	dossier.open("res://Jeu/Enigmes")
	dossier.list_dir_begin()
	
	while true:
		var fichier = dossier.get_next()
		if fichier == "":
			break
		elif not fichier.begins_with("."):
			fichiers.append(fichier)
			
	dossier.list_dir_end()
	
	return fichiers

#Fonction pour lire le fichier de l'enigme
func _lire_json(chemin_fichier):
	var fichier = File.new()
	fichier.open(chemin_fichier, fichier.READ)
	var contenu_fichier = {}
	contenu_fichier = parse_json(fichier.get_as_text())
	fichier.close()
	return contenu_fichier

#Fonction qui charge les énigmes
func _charger_enigmes():
	print("_charger_enigme")
	var fichiers_enigmes = _lister_fichier_enigmes()
	enigmes = []
	for fichier in fichiers_enigmes:
		print(fichier)
		enigmes.append(_lire_json("res://Jeu/Enigmes/"+fichier))

#Fonction qui lance le déroulement d'une énigme
func _poser_enigme():
	var enigme = null
	_selectionner_enigme()
	_afficher_enigme(enigme)
	#_attendre_reponses()
	#_proposer_options_instigateur()

#Fonction qui choisi une énigme au hasard
func _selectionner_enigme():
	enigme_actuelle = randi()%enigmes.size()

#Fonction qui affiche l'enigme aux joueurs
func _afficher_enigme(enigme):
	#Envoie l'ordre par le réseau à tout le monde d'afficher l'énigme
	rpc("_joueurs_afficher_enigme", enigme_actuelle)


# --------- ENIGME côté client ---------

sync func _joueurs_afficher_enigme(enigme_numero):
	enigme_actuelle = enigme_numero
	$InterfaceEnigme._preparer(enigmes[enigme_actuelle])
	$InterfaceEnigme.show()
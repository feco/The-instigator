extends Spatial

var enigmes = null
var enigme_actuelle
var reponses_joueurs = []
var enigme_en_cours = false
var enigme_finie = false
var vote_en_cours = false
var votes_tour = []
var votes_total = []
var tour = 0
var instigateur
var envoyer_vote_instigateur = false

#Initialisation du jeu
func _ready():
	print(globals.liste_des_joueurs)
	print("Mon id : ")
	print(get_tree().get_network_unique_id())
	randomize() #Initialise le système de génération de nombre aléatoire
	_charger_enigmes()
	if globals.est_serveur :
		_choix_instigateur()
		_poser_enigme()


#Fonction qui s'exécute régulièrement
func _process(delta):
	if globals.est_serveur:
		if enigme_en_cours:
			if reponses_joueurs.size() >= globals.liste_des_joueurs.size():
				enigme_en_cours = false
				rpc("_proposer_options_instigateur", reponses_joueurs);
		elif vote_en_cours:
			if envoyer_vote_instigateur :
				rpc("_vote_qui_instigateur")
				envoyer_vote_instigateur = false
			var compte_vote = 0
			for vote in votes_tour:
				compte_vote += vote["compte"]
			if compte_vote >= globals.liste_des_joueurs.size():
				vote_en_cours = false
				_fusion_votes()
				tour += 1
				if tour < 10 :
					_poser_enigme()
				else :
					var gagnant = _qui_a_gagne()
					rpc("_afficher_fin_jeu", gagnant)



#Choisir un instigateur au hasard
func _choix_instigateur():
	var instigateur_number = randi() % globals.liste_des_joueurs.size()
	instigateur = globals.liste_des_joueurs[instigateur_number]
	#Envoie l'infos à l'instigateur sélectionné qu'il est l'instigateur
	print("Instigateur : ")
	print(instigateur["id"])
	if instigateur["id"] != 0 :
		rpc_id(instigateur["id"], "_est_instigateur")
	else :
		_est_instigateur()

#Fonction qui élève le joueur courant au niveau d'instigateur si le serveur lui en envoie l'ordre
remote func _est_instigateur():
	print("Vous êtes un instigateur")
	globals.est_instigateur = true

#Fonction qui trouve le nom d'un joueur en fonction de son id
func _recuperer_nom_par_id(id):
	for joueur in globals.liste_des_joueurs:
		if joueur["id"] == id:
			return joueur["pseudo"]

#Fonction qui trouve l'id d'un joueur en fonction de son pseudo
func _recuperer_id_par_nom(nom):
	for joueur in globals.liste_des_joueurs:
		if joueur["pseudo"] == nom:
			return joueur["id"]

#Fonction qui ajoute le compte des votes pour le tour au compte des votes total
func _fusion_votes():
	for vote_tour in votes_tour:
		var vote_comptabilise = false
		for vote_total in votes_total:
			if vote_total["pseudo"] == vote_tour["pseudo"]:
				vote_total["compte"] += vote_tour["compte"]
				vote_comptabilise = true
		if !vote_comptabilise:
			votes_total.append(vote_tour)


func _qui_a_gagne():
	var perdant = null
	var point_perdant = 0
	for vote in votes_total:
		if point_perdant < vote["compte"]:
			point_perdant = vote["compte"]
			perdant = vote["pseudo"]
	
	var id_perdant = _recuperer_id_par_nom(perdant)
	if id_perdant == instigateur["id"]:
		return "joueurs"
	else:
		return "instigateur"


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
	var reponses_joueurs = []
	_selectionner_enigme()
	_afficher_enigme(enigme)
	enigme_en_cours = true
	#A partir de ce moment on attend que tout le monde a répondu, c'est la fonction _process qui gère ça

#Fonction qui choisi une énigme au hasard
func _selectionner_enigme():
	enigme_actuelle = randi()%enigmes.size()

#Fonction qui affiche l'enigme aux joueurs
func _afficher_enigme(enigme):
	#Envoie l'ordre par le réseau à tout le monde d'afficher l'énigme
	rpc("_joueurs_afficher_enigme", enigme_actuelle)

#Fonction qui réceptionne les réponses des joueurs à une énigme ou réponse de l'instigateur
remote func _reponse_joueur(reponse, id_appelant):
	print("Réception de la réponse du joueur")
	if globals.est_serveur:
		print("Le récepteur est bien le serveur")
		if enigme_en_cours:
			print("Une énigme est en cours, traitement de la réponse...")
			for reponse in reponses_joueurs:
				if reponse["id_joueur"] == id_appelant:
					return
			
			reponses_joueurs.append({"id_joueur" : id_appelant, "reponse" : reponse})
		elif vote_en_cours:
			var vote_comptabiliser = false
			for vote in votes_tour:
				if vote["pseudo"] == reponse:
					vote["compte"] += 1
					vote_comptabiliser = true
			if !vote_comptabiliser:
				votes_tour.append({"pseudo":reponse, "compte":1})
		
		elif id_appelant == instigateur["id"]:
			print("Traitement du choix de l'instigateur")
			traiter_choix_instigateur(reponse)

#Fonction qui gère le choix de l'instigateur après une énigme
func traiter_choix_instigateur(reponse):
	#Ajouter le traitement des choix de l'instigateur ici
	
	vote_en_cours = true
	envoyer_vote_instigateur = true





# --------- ENIGME côté client ---------

#Fonction qui affiche l'énigme sélectionnée par le serveur aux clients
sync func _joueurs_afficher_enigme(enigme_numero):
	vote_en_cours = false
	votes_tour = []
	reponses_joueurs = []
	
	enigme_actuelle = enigme_numero
	$InterfaceEnigme._preparer(enigmes[enigme_actuelle])
	$InterfaceEnigme.show()


#Fonction qui permet d'afficher le vote à la recherche de l'instigateur
sync func _vote_qui_instigateur():
	print("Vote qui est instigateur")
	var joueurs = []
	for joueur in globals.liste_des_joueurs:
		joueurs.append(joueur["pseudo"])
	var enigme = {"question": "Qui est l'instigateur ?", "choix": joueurs}
	$InterfaceEnigme._preparer(enigme)
	$InterfaceEnigme.show()

#Fonction qui affiche à l'instigateur ses choix après une énigme
sync func _proposer_options_instigateur(reponses_joueurs):
	print("Afficher options pour l'instigateur")
	if globals.est_instigateur:
		var choix_joueurs = "Votes : "
		for reponse in reponses_joueurs :
			choix_joueurs += _recuperer_nom_par_id(reponse["id_joueur"]) + " a voté " + reponse["reponse"] + ";"
		var enigme = {"question": "En tant qu'instigateur que souhaitez-vous faire ?", "choix":["1", "2", "3", "4"]}
		print("Enigme à preparer :")
		print(enigme)
		$InterfaceEnigme._preparer(enigme, choix_joueurs)
		$InterfaceEnigme.show()

#Fonction qui traite la réponse donnée par un joueur
func _on_reponse(reponse):
	if (globals.est_serveur):
		if enigme_en_cours:
			print("Une énigme est en cours, traitement de la réponse...")
			for reponse in reponses_joueurs:
				if reponse["id_joueur"] == 0:
					return
			
			reponses_joueurs.append({"id_joueur" : 0, "reponse" : reponse})
			
			
		elif vote_en_cours:
			var vote_comptabiliser = false
			for vote in votes_tour:
				if vote["pseudo"] == reponse:
					vote["compte"] += 1
					vote_comptabiliser = true
			if !vote_comptabiliser:
				votes_tour.append({"pseudo":reponse, "compte":1})
		
		
		elif 0 == instigateur["id"]:
			print("Traitement du choix de l'instigateur")
			traiter_choix_instigateur(reponse)
	else:
		rpc("_reponse_joueur", reponse, get_tree().get_network_unique_id())


sync func _afficher_fin_jeu(gagnant):
	var message = null
	if gagnant == "instigateur":
		if globals.est_instigateur :
			message = "Victoire!"
		else : 
			message = "Défaite"
	else :
		if globals.est_instigateur:
			message = "Défaite"
		else : 
			message = "Victoire"
	$InterfaceEnigme._fin(message)
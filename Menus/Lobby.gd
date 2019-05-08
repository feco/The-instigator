extends Control

func _ready():
	#Si c'est le serveur qui viens de créer le lobby alors il met son pseudo dans la liste et se défini comme maître
	if get_tree().get_network_unique_id() == 0:
		print ("Je suis le serveur")
		globals.est_serveur = true
		globals.liste_des_joueurs[get_tree().get_network_unique_id()] = globals.mon_pseudo
		$ListeDesJoueurs.text += globals.mon_pseudo+"\n"
		#set_network_master(0)
	else : #Sinon le client va prévenir de sa connexion et envoyer son pseudo au serveur
		print("Je suis un client")
		get_tree().connect("network_peer_connected", self, "_joueur_a_rejoin")
		rpc("_definir_nom_joueur", get_tree().get_network_unique_id(), globals.mon_pseudo)



#La fonction qui se lance, sur le serveur, quand un joueur a rejoin le lobby
master func _joueur_a_rejoin(id):
	print("Un joueur a rejoin le serveur")


#Fonction pour envoyer le pseudo du joueur nouvellement connecté au serveur
master func _definir_nom_joueur(id, pseudo):
	print("Ce joueur a communiqué son id et son pseudo : " + pseudo)
	globals.liste_des_joueurs[id] = pseudo
	$ListeDesJoueurs.text += pseudo+"\n"
	rpc("_mettreAJour_joueurs", globals.liste_des_joueurs)


#Après chaque connexion de joueur le serveur transmet à tout le monde la liste des joueurs mise à jour
sync func _mettreAJour_joueurs (liste):
	print("Le serveur transmet à tous la liste des joueurs à jour")
	globals.liste_des_joueurs = liste
	$ListeDesJoueurs.text = ""
	for joueur in globals.liste_des_joueurs:
		$ListeDesJoueurs.text += globals.liste_des_joueurs[joueur]+"\n"



func _on_LancerJeuBouton_pressed():
	print("Clique sur lancer partie")
	if globals.est_serveur:
		print("Je suis le serveur")
		rpc("_lancer_jeu")

sync func _lancer_jeu():
	print("lancement de la partie")
	hide()
	var jeu = preload("res://Jeu/Jeu.tscn").instance()
	get_tree().get_root().add_child(jeu)
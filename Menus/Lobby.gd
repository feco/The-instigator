extends Control

func _ready():
	#Si c'est le serveur qui viens de créer le lobby alors il met son pseudo dans la liste et se défini comme maître
	if get_tree().get_network_unique_id() == 0:
		print ("Je suis le serveur")
		globals.est_serveur = true
		globals.liste_des_joueurs.append({"id" : get_tree().get_network_unique_id(), "pseudo" : globals.mon_pseudo})
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
	globals.liste_des_joueurs.append({"id" : id, "pseudo" : pseudo})
	$ListeDesJoueurs.text += pseudo+"\n"
	rpc("_mettreAJour_joueurs", globals.liste_des_joueurs)


#Après chaque connexion de joueur le serveur transmet à tout le monde la liste des joueurs mise à jour
sync func _mettreAJour_joueurs (liste):
	print("Le serveur transmet à tous la liste des joueurs à jour")
	globals.liste_des_joueurs = liste
	$ListeDesJoueurs.text = ""
	for joueur in globals.liste_des_joueurs:
		$ListeDesJoueurs.text += joueur["pseudo"]+"\n"


#Quand on clique sur lancer une partie, seul le serveur peut lancer la partie et seulement si au moins 3 joueurs sont présents
func _on_LancerJeuBouton_pressed():
	if globals.est_serveur && globals.liste_des_joueurs.size()  >= 3:
		print("Je suis le serveur")
		rpc("_lancer_jeu")

#Lancement de la partie pour tous les joueurs parce que le serveur l'a demandé.
sync func _lancer_jeu():
	print("lancement de la partie")
	hide()
	var jeu = preload("res://Jeu/Jeu.tscn").instance()
	get_tree().get_root().add_child(jeu)
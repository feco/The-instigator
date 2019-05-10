extends Node2D

# --------- REJOINDRE un serveur ---------

#Quand on clique sur le bouton rejoindre le joueur peut entrer l'IP de l'hote à rejoindre
func _on_RejoindreBouton_pressed():
	$Accueil.hide()
	$IPServeur.show()


func _on_RetourBouton_pressed():
	$IPServeur.hide()
	$Accueil.show()


# Quand l'IP a été rentrée, si elle semble valide le joueur peut tenter de se connecter à l'hote
func _on_ConnecterBouton_pressed():
	if $IPServeur/MargeDeInterface/ArrangementHorizontal/IPTextEdit.text.length() > 7 :
		var reseau = NetworkedMultiplayerENet.new()
		reseau.create_client($IPServeur/MargeDeInterface/ArrangementHorizontal/IPTextEdit.text, 4243)
		get_tree().set_network_peer(reseau)
		reseau.connect("connection_failed", self, "_on_echec_connexion")
		reseau.connect("connection_succeeded", self, "_on_succes_connexion")
		print("Test de la connexion...")
	else :
		$IPServeur/MargeDeInterface/ArrangementHorizontal/ErreurLabel.text = "Veuillez entrer une adresse IP valide"


#Affiche un message si le joueur n'a pas pu se connecter à l'hote
func _on_echec_connexion(erreur):
	print("Echec connexion")
	$IPServeur/MargeDeInterface/ArrangementHorizontal/ErreurLabel.text = "Erreur à la connexion : " + erreur

#Affiche le lobby si le joueur a pu se connecter
func _on_succes_connexion():
	print("Succes connexion")
	var lobby = preload("res://Menus/Lobby.tscn").instance()
	get_tree().get_root().add_child(lobby)
	hide()



# --------- CREER un serveur ---------

#Creer un serveur si le joueur appuie sur le bouton de création de serveur
func _on_CreerBouton_pressed():
	var reseau = NetworkedMultiplayerENet.new()
	var serveur = reseau.create_server(4243)
	
	if serveur != OK :#Si le serveur n'a pas pu être crée
		$Accueil/ErreurLabel.text = "Le serveur n'a pas pu être créé"
	else :
		hide() #Cache l'interface de connexion
		#Affiche le lobby
		var lobby = preload("res://Menus/Lobby.tscn").instance()
		get_tree().get_root().add_child(lobby)
		get_tree().set_network_peer(reseau)




#Quand le joueur a fini d'écrire son pseudo on l'enregistre dans le script global pour plus tard
func _on_PseudoTextEdit_focus_exited():
	globals.mon_pseudo = $Accueil/MargeDeInterface/CenterContainer/ArrangementHorizontal/VBoxContainer/PseudoTextEdit.text


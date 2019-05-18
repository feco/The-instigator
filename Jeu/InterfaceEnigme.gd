extends MarginContainer

var reponses = []

#Fonction qui sert à afficher le contenu de l'énigme
func _preparer(enigme, choix_joueurs = null):
	print("Préparation de l'énigme")
	print(enigme)
	if $"DécoupageInterfaceEn2/Enigme/Défilement/Réponses".get_child_count() == 0:
		$"DécoupageInterfaceEn2/Enigme/Question".text = enigme["question"]
		if choix_joueurs != null:
			$"DécoupageInterfaceEn2/Enigme/Votes".text = choix_joueurs
		for reponse in enigme["choix"]:
			var bouton_reponse = Button.new()
			bouton_reponse.text = reponse
			var police = DynamicFont.new()
			police.font_data = load("res://arial.ttf")
			police.size = 30
			bouton_reponse.add_font_override("font", police)
			bouton_reponse.connect("pressed", self, "_on_reponse", [bouton_reponse])
			reponses.append(bouton_reponse);
			$"DécoupageInterfaceEn2/Enigme/Défilement/Réponses".add_child(bouton_reponse)

#Fonction qui sert à réinitialiser l'interface énigme
func _vider():
	print("Vider énigme")
	$"DécoupageInterfaceEn2/Enigme/Votes".text = ""
	for child in $"DécoupageInterfaceEn2/Enigme/Défilement/Réponses".get_children():
		child.queue_free()

#Fonction qui envoie le choix du joueur au serveur
func _on_reponse(bouton):
	print("Le joueur envoie sa réponse")
	_vider()
	get_parent()._on_reponse(bouton.text)
	hide()
extends MarginContainer

func _preparer(enigme):
	$"DécoupageInterfaceEn2/Enigme/Question".text = enigme["question"]
	for reponse in enigme["choix"]:
		var bouton_reponse = Button.new()
		bouton_reponse.text = reponse
		$"DécoupageInterfaceEn2/Enigme/Défilement/Réponses".add_child(bouton_reponse)
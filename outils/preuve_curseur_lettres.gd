## PREUVE PIXEL du curseur clignotant du jeu des lettres (REQ 260930).
## Monte la VRAIE scene res://scenes/lettres.tscn dans un SubViewport 1024x768,
## ecrit un mot par le vrai chemin de code (_ajouter_au_mot / _effacer_derniere),
## rend de vrais pixels et MESURE le trait bleu dans le tableau blanc.
## Outil de preuve : non embarque dans le jeu, non commite avec la fonction.
extends Node

const LARGEUR := 1024
const HAUTEUR := 768
const SORTIE := "/tmp/preuve_curseur/"
const FEUTRE := Color(0.16, 0.22, 0.34)

var _vue: SubViewport
var _jeu: Control


func _ready() -> void:
	# Fenetre 1x1 sans focus : on ne prend pas l'ecran de Fabrice
	var f := get_window()
	f.set_flag(Window.FLAG_NO_FOCUS, true)
	f.size = Vector2i(1, 1)
	f.position = Vector2i(0, 0)

	DirAccess.make_dir_recursive_absolute(SORTIE)
	_vue = SubViewport.new()
	_vue.size = Vector2i(LARGEUR, HAUTEUR)
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vue.transparent_bg = false
	add_child(_vue)

	var paquet: PackedScene = load("res://scenes/lettres.tscn")
	_jeu = paquet.instantiate()
	_vue.add_child(_jeu)
	await _trames(12)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # le jeu l'avait masque : on rend la souris

	print("=== PREUVE CURSEUR CLIGNOTANT — jeu des lettres ===")
	print("noeud _trait_ecriture present : ", _jeu._trait_ecriture != null,
		" | parent = ", _jeu._trait_ecriture.get_parent().get_class())

	await _etat("01_vide", "")
	await _etat("02_P", "P")
	await _etat("03_PAPA", "PAPA")
	await _etat("04_PAPA_espace", "PAPA ")
	# Effacement : on revient a PAPA par le vrai bouton retour arriere
	_jeu._effacer_derniere()
	await _mesurer("05_apres_effacement")
	# Tout effacer
	_jeu._effacer_tout()
	await _mesurer("06_apres_croix")

	await _clignotement()
	print("=== FIN ===")
	get_tree().quit(0)


func _trames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## Repart d'un tableau vide puis tape le mot par le vrai chemin de code.
func _etat(nom: String, mot: String) -> void:
	_jeu._effacer_tout()
	for c in mot:
		_jeu._ajouter_au_mot(c)
	await _mesurer(nom)


func _mesurer(nom: String) -> void:
	await _trames(6)
	var image := _vue.get_texture().get_image()
	image.save_png(SORTIE + nom + ".png")
	var rect: Rect2 = _jeu._label_mot.get_global_rect()
	var colonnes := _colonnes_bleues(image, rect)
	var etiquette := "mot=\"%s\"" % _jeu._mot
	if colonnes.is_empty():
		print("  %-22s %-22s AUCUN pixel feutre" % [nom, etiquette])
		return
	# Le trait est le bloc de colonnes le plus a droite (le mot est a sa gauche)
	var fin: int = colonnes[colonnes.size() - 1]
	var debut := fin
	while colonnes.has(debut - 1):
		debut -= 1
	var avant := -1
	for x in colonnes:
		if x < debut - 1:
			avant = x
	var hauteur := _hauteur_colonne(image, rect, (debut + fin) / 2)
	print("  %-22s %-22s bloc droit x=[%d..%d] (%d px) hauteur=%d px | fin du mot x=%s | centre du tableau x=%d"
		% [nom, etiquette, debut, fin, fin - debut + 1, hauteur,
		("(rien)" if avant < 0 else str(avant)), int(rect.position.x + rect.size.x / 2.0)])


## Colonnes (x absolus) contenant au moins un pixel proche du bleu feutre.
func _colonnes_bleues(image: Image, rect: Rect2) -> Array[int]:
	var trouvees: Array[int] = []
	var x0 := int(rect.position.x)
	var y0 := int(rect.position.y)
	for x in range(x0, int(rect.position.x + rect.size.x)):
		for y in range(y0, int(rect.position.y + rect.size.y)):
			if _est_feutre(image.get_pixel(x, y)):
				trouvees.append(x)
				break
	return trouvees


func _hauteur_colonne(image: Image, rect: Rect2, x: int) -> int:
	var n := 0
	for y in range(int(rect.position.y), int(rect.position.y + rect.size.y)):
		if _est_feutre(image.get_pixel(x, y)):
			n += 1
	return n


## Assez sombre et assez bleu pour etre du feutre (le fond est blanc casse).
func _est_feutre(c: Color) -> bool:
	return c.v < 0.62 and c.b > c.r


## Prouve le clignotement : on relit la MEME colonne du trait au fil du temps.
## Le trait s'estompe (alpha) donc son pixel palit vers le blanc du tableau.
func _clignotement() -> void:
	_jeu._effacer_tout()
	await _trames(4)
	var rect: Rect2 = _jeu._label_mot.get_global_rect()
	var colonnes := _colonnes_bleues(_vue.get_texture().get_image(), rect)
	if colonnes.is_empty():
		print("  clignotement : colonne du trait introuvable")
		return
	var x: int = colonnes[colonnes.size() - 1]
	var y := int(rect.position.y + rect.size.y / 2.0)
	print("=== CLIGNOTEMENT (colonne x=%d, ligne y=%d) ===" % [x, y])
	var t := 0.0
	for pas in 16:
		var image := _vue.get_texture().get_image()
		var c := image.get_pixel(x, y)
		var barres := "#".repeat(int((1.0 - c.v) * 40.0))
		print("  t=%4.2f s  luminosite=%.3f  %s" % [t, c.v, barres])
		await _attendre(0.11)
		t += 0.11
	var img_fin := _vue.get_texture().get_image()
	img_fin.save_png(SORTIE + "07_clignotement_fin.png")


func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

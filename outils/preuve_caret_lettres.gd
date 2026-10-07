## PREUVE du caret positionnable + curseur ×2 du jeu des lettres (REQ 261007).
## Monte la VRAIE scene res://scenes/lettres.tscn dans un SubViewport 1024x768 et
## lui INJECTE de vrais evenements (touches, fleches, clics) par push_input :
## c'est le chemin _input du jeu qui travaille, comme sous les doigts de l'enfant.
## Mesure : le mot, l'index du caret, la position PIXEL du trait (difference
## image trait visible / trait masque) et la taille du curseur (echelle + pixels).
## Lancer avec --audio-driver Dummy (sinon la voix parle a chaque touche).
## Outil de preuve : non embarque dans le jeu.
extends Node

const LARGEUR := 1024
const HAUTEUR := 768
const SORTIE := "/tmp/preuve_caret/"

var _vue: SubViewport
var _jeu: Control
var _ko := 0


func _ready() -> void:
	var f := get_window()
	f.set_flag(Window.FLAG_NO_FOCUS, true)
	f.size = Vector2i(1, 1)
	f.position = Vector2i(0, 0)
	DirAccess.make_dir_recursive_absolute(SORTIE)
	_vue = SubViewport.new()
	_vue.size = Vector2i(LARGEUR, HAUTEUR)
	_vue.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vue)
	_jeu = (load("res://scenes/lettres.tscn") as PackedScene).instantiate()
	_vue.add_child(_jeu)
	await _trames(12)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	print("=== PREUVE CARET + CURSEUR x2 — jeu des lettres ===")
	await _non_regression()
	await _fleches()
	await _clic()
	await _bornes()
	await _debordement()
	await _curseur_x2()
	print("=== BILAN : %s (%d KO) ===" % ["TOUT VERT" if _ko == 0 else "ROUGE", _ko])
	get_tree().quit(0 if _ko == 0 else 1)


# --- Scenarios ----------------------------------------------------------------

## Ecrire a la suite : comportement d'avant intact (caret en fin, trait apres le mot).
func _non_regression() -> void:
	print("-- A. ecriture normale (non-regression)")
	_jeu._effacer_tout()
	_taper("papa")
	await _trames(4)
	_verifier("mot apres frappe", _jeu._mot, "PAPA")
	_verifier("caret en fin par defaut", _jeu._caret, 4)
	var x_trait := await _x_trait("A_PAPA_fin")
	var x_attendu := _x_formule_avant("PAPA")
	_verifier("trait au meme endroit qu'avant (+-2 px)", absf(x_trait - x_attendu) <= 2.0, true,
		"mesure x=%.1f, formule d'avant x=%.1f" % [x_trait, x_attendu])
	_touche(KEY_BACKSPACE)
	_verifier("retour arriere en fin = derniere lettre", _jeu._mot, "PAP")
	_jeu._effacer_tout()
	_verifier("croix = tout efface, caret 0", [_jeu._mot, _jeu._caret], ["", 0])


## Fleches : on revient dans le mot et on insere la lettre oubliee.
func _fleches() -> void:
	print("-- B. fleches gauche/droite (desktop)")
	_jeu._effacer_tout()
	_taper("mamn")
	_touche(KEY_LEFT)
	_verifier("fleche gauche -> caret 3", _jeu._caret, 3)
	var x_milieu := await _x_trait("B_MAM|N")
	var x_frontiere := _x_frontiere_globale(3)
	_verifier("trait dessine entre M et N (+-3 px)", absf(x_milieu - x_frontiere) <= 3.0, true,
		"mesure x=%.1f, frontiere x=%.1f" % [x_milieu, x_frontiere])
	_taper("a")
	_verifier("lettre inseree sans rien effacer", _jeu._mot, "MAMAN")
	_verifier("caret juste apres la lettre inseree", _jeu._caret, 4)
	_touche(KEY_RIGHT)
	_verifier("fleche droite -> fin", _jeu._caret, 5)
	_taper("s")
	_verifier("on reprend l'ecriture a la suite", _jeu._mot, "MAMANS")


## Clic (= tap Android, emule en clic gauche) entre deux lettres.
func _clic() -> void:
	print("-- C. clic / tap dans le mot")
	_jeu._effacer_tout()
	_taper("cat")
	await _trames(3)
	var rect: Rect2 = _jeu._label_mot.get_global_rect()
	var y := rect.position.y + rect.size.y / 2.0
	# Clic un peu a droite de la frontiere C|A (dans la moitie gauche du A)
	_clic_gauche(Vector2(_x_frontiere_globale(1) + 6.0, y))
	_verifier("clic entre C et A -> caret 1", _jeu._caret, 1)
	await _x_trait("C_C|AT")
	_taper("h")
	_verifier("lettre oubliee ajoutee au bon endroit", _jeu._mot, "CHAT")
	_touche(KEY_BACKSPACE)
	_verifier("retour arriere = lettre a gauche du caret", [_jeu._mot, _jeu._caret], ["CAT", 1])
	_clic_gauche(Vector2(_x_frontiere_globale(3) + 30.0, y))
	_verifier("clic apres le mot -> caret en fin", _jeu._caret, 3)
	_clic_gauche(Vector2(_x_frontiere_globale(0) - 30.0, y))
	_verifier("clic avant le mot -> caret au debut", _jeu._caret, 0)
	await _x_trait("C_|CAT")
	_clic_gauche(Vector2(rect.position.x + rect.size.x / 2.0, rect.position.y - 120.0))
	_verifier("clic hors du tableau -> caret inchange", _jeu._caret, 0)


func _bornes() -> void:
	print("-- D. bornes")
	_jeu._effacer_tout()
	_taper("lo")
	_touche(KEY_RIGHT)
	_verifier("fleche droite en fin : reste en fin", _jeu._caret, 2)
	_touche(KEY_LEFT)
	_touche(KEY_LEFT)
	_touche(KEY_LEFT)
	_verifier("fleche gauche au debut : reste a 0", _jeu._caret, 0)
	_touche(KEY_BACKSPACE)
	_verifier("retour arriere au debut : rien efface", _jeu._mot, "LO")
	_jeu._effacer_tout()
	_touche(KEY_LEFT)
	_touche(KEY_BACKSPACE)
	_verifier("tableau vide : fleche/retour sans effet", [_jeu._mot, _jeu._caret], ["", 0])


func _debordement() -> void:
	print("-- E. mot plein (14 lettres)")
	_jeu._effacer_tout()
	_taper("abcdefghijklmn")
	_taper("o")
	_verifier("a la suite : la ligne glisse comme avant", _jeu._mot, "BCDEFGHIJKLMNO")
	for i in 7:
		_touche(KEY_LEFT)
	_taper("z")
	_verifier("insertion au milieu d'un mot plein : 14 lettres", _jeu._mot.length(), 14)
	_verifier("le Z est a gauche du caret", _jeu._mot[_jeu._caret - 1], "Z")


## Curseur du jeu : echelle x2 par rapport au meme curseur sans facteur.
func _curseur_x2() -> void:
	print("-- F. curseur du jeu x2")
	var curseur: Node2D = _jeu._curseur
	await _attendre(2.0)  # rebonds des clics et effets (fleurs, etoiles) retombes
	var temoin: Node2D = (load("res://scripts/clavier/curseur.gd") as GDScript).new()
	_vue.add_child(temoin)  # facteur par defaut : ce que voient les jeux mots/chasse
	var rapport := curseur.scale.x / temoin.scale.x
	_verifier("echelle lettres / echelle temoin = 2", is_equal_approx(rapport, 2.0), true,
		"lettres=%.3f temoin=%.3f" % [curseur.scale.x, temoin.scale.x])
	_verifier("le temoin (autres jeux) garde facteur 1", temoin.facteur, 1.0)
	# Pixels : boite englobante du curseur, puis du temoin a la meme place
	curseur.position = Vector2(120, 140)
	temoin.visible = false
	var h_lettres := await _hauteur_pixels(curseur, "F_curseur_lettres")
	temoin.position = curseur.position
	temoin.visible = true
	var h_temoin := await _hauteur_pixels(temoin, "F_curseur_temoin")
	_verifier("hauteur pixels ~x2", absf(float(h_lettres) / float(h_temoin) - 2.0) < 0.1, true,
		"lettres=%d px temoin=%d px" % [h_lettres, h_temoin])
	# Clic : le rebond revient a l'echelle x2 ; molette : reste x2 du temoin
	curseur.pulser()
	await _attendre(0.4)
	_verifier("apres un clic : toujours x2", is_equal_approx(curseur.scale.x / temoin.scale.x, 2.0), true)
	temoin.queue_free()


# --- Outils -------------------------------------------------------------------

func _taper(texte: String) -> void:
	for c in texte:
		var ev := InputEventKey.new()
		ev.pressed = true
		ev.keycode = OS.find_keycode_from_string(c.to_upper())
		ev.unicode = c.unicode_at(0)
		_vue.push_input(ev, true)


func _touche(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	_vue.push_input(ev, true)


func _clic_gauche(ou: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = ou
	ev.global_position = ou
	_vue.push_input(ev, true)
	var rel := ev.duplicate()
	rel.pressed = false
	_vue.push_input(rel, true)


## Abscisse globale de la frontiere avant la lettre i (meme police que le Label).
func _x_frontiere_globale(i: int) -> float:
	var label: Label = _jeu._label_mot
	var police: Font = label.get_theme_font("font")
	var taille: int = label.get_theme_font_size("font_size")
	var l_mot := police.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
	var l_pre := police.get_string_size(label.text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
	return label.get_global_rect().position.x + label.size.x / 2.0 - l_mot / 2.0 + l_pre


## Formule du trait AVANT la balle (0e3a2a1) : bout du mot + ECART + LARGEUR/2.
func _x_formule_avant(mot: String) -> float:
	var label: Label = _jeu._label_mot
	var police: Font = label.get_theme_font("font")
	var taille: int = label.get_theme_font_size("font_size")
	var l_mot := police.get_string_size(mot, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
	return label.get_global_rect().position.x + label.size.x / 2.0 + l_mot / 2.0 + 4.0 + 2.0


## Centre (x global) du trait mesure en pixels : image trait visible - image trait masque.
func _x_trait(nom: String) -> float:
	var trait_: Control = _jeu._trait_ecriture
	trait_.reveiller()  # plein, debut de cycle
	await _trames(4)
	var avec := _vue.get_texture().get_image()
	trait_.visible = false
	await _trames(4)
	var sans := _vue.get_texture().get_image()
	trait_.visible = true
	avec.save_png(SORTIE + nom + ".png")
	var rect: Rect2 = _jeu._label_mot.get_global_rect()
	var xs: Array[int] = []
	for x in range(int(rect.position.x), int(rect.end.x)):
		for y in range(int(rect.position.y), int(rect.end.y)):
			if absf(avec.get_pixel(x, y).v - sans.get_pixel(x, y).v) > 0.2:
				xs.append(x)
				break
	if xs.is_empty():
		print("    [%s] trait INTROUVABLE" % nom)
		return -999.0
	var centre := (xs[0] + xs[xs.size() - 1] + 1) / 2.0
	print("    [%s] mot=\"%s\" caret=%d trait x=[%d..%d] centre=%.1f"
		% [nom, _jeu._mot, _jeu._caret, xs[0], xs[xs.size() - 1], centre])
	return centre


## Hauteur en pixels d'un noeud dessine (difference visible / masque).
func _hauteur_pixels(noeud: CanvasItem, nom: String) -> int:
	await _trames(4)
	var avec := _vue.get_texture().get_image()
	noeud.visible = false
	await _trames(4)
	var sans := _vue.get_texture().get_image()
	noeud.visible = true
	avec.save_png(SORTIE + nom + ".png")
	var haut := -1
	var bas := -1
	for y in range(0, 420):
		for x in range(60, 300):
			if avec.get_pixel(x, y) != sans.get_pixel(x, y):
				if haut < 0:
					haut = y
				bas = y
				break
	print("    [%s] lignes y=[%d..%d]" % [nom, haut, bas])
	return bas - haut + 1


func _verifier(quoi: String, obtenu, attendu, detail := "") -> void:
	var ok: bool = obtenu == attendu
	if not ok:
		_ko += 1
	print("  %s %s : %s%s" % ["OK" if ok else "KO", quoi, str(obtenu),
		("" if detail == "" else "  (" + detail + ")")])


func _trames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _attendre(secondes: float) -> void:
	await get_tree().create_timer(secondes).timeout

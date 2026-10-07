# Preuve CHASSE = JEU SOURIS et MOTS revenu a l'origine sur Android (REQ_261007 android_chasse_mots_correction).
# Decisions Fabrice (07-10) : « Dans [la chasse] il n'y a pas de clavier, nous utilisons la souris » ;
# « Pour le jeu des mots, on va pas mettre le curseur sur Android. Le clavier, on va le remettre a sa place. »
# Monte les VRAIS jeux en mode tactile (user:// isole), curseur a la gamme Android (x2), doigts poses par
# le vrai chemin du moteur (outils/doigt_moteur.gd : ScreenTouch → clic emule fabrique par Godot).
#   A  chasse tactile : AUCUN clavier dessine (ni noeud clavier_virtuel, ni touche-lettre) ; tableau et
#      naissance des bulles A LA MEME PLACE qu'en desktop ; visee a la pointe branchee (comme Ballons) ;
#   C  chasse tactile : pointe sur la bulle / doigt dehors → ATTRAPEE ; doigt dessus / pointe dehors → non ;
#   Q  chasse desktop : clic souris sur la bulle → attrapee ; touche PHYSIQUE de la lettre → attrapee
#      (le clavier du PC reste un 2e moyen, rien ne dependait du clavier dessine) ;
#   M  mots tactile : PAS de visee a la pointe (le doigt glisse → curseur SOUS le doigt ; la touche tapee
#      est celle SOUS LE DOIGT, la pointe etant sur une autre) ; clavier A SA PLACE D'ORIGINE (bas de
#      l'ecran, 320 px, aucune remontee) ; tuiles au-dessus comme a l'origine ; voix dite ; mot complete.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_chasse_mots_android.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")
const Voix := preload("res://scripts/voix.gd")

const ANDROID := 2.0  # AGRANDI_TAILLE_ANDROID des curseur.gd
const HAUTEUR_CLAVIER := 320.0  # clavier_virtuel.HAUTEUR d'origine
const MARGE_ORIGINE := 12      # marge basse d'origine du panneau du clavier

var _echecs := 0
var _jeu: Control
var _curseur: Node2D


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _zone() -> Rect2:
	return root.get_visible_rect()


func _monter(chemin: String, android: bool) -> void:
	_jeu = load(chemin).instantiate()
	root.add_child(_jeu)
	current_scene = _jeu
	await _trames(6)
	_curseur = _jeu.get("_curseur")
	if android:
		_curseur.gamme = ANDROID
		_curseur.set("_echelle_base", float(_curseur.get("_echelle_base")) * ANDROID)
	await _trames(4)


func _demonter() -> void:
	if is_instance_valid(_jeu):
		_jeu.queue_free()
	await _trames(4)


func _tap(d: Vector2) -> void:
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.toucher(root, d, false)
	await _trames(3)


func _doigt_pour(pointe: Vector2) -> Vector2:
	return Doigt.doigt_pour_pointe(_curseur, pointe, _zone())


func _pointe_pour(doigt: Vector2) -> Vector2:
	return _curseur.pointe_pour_doigt(doigt, _zone())


func _a_script(chemin: String) -> Array:
	var trouves := []
	for n in _jeu.find_children("*", "", true, false):
		var s: Script = n.get_script()
		if s != null and s.resource_path == chemin:
			trouves.append(n)
	return trouves


## Cherche une pointe telle que pour_pointe(pointe) et pour_doigt(doigt) soient vrais (grille 3 px).
func _chercher(autour: Vector2, pour_pointe: Callable, pour_doigt: Callable, rayon := 260.0) -> Vector2:
	var meilleur := Vector2.INF
	var meilleure_dist := INF
	var y := -rayon
	while y <= rayon:
		var x := -rayon
		while x <= rayon:
			var p := autour + Vector2(x, y)
			if _zone().has_point(p) and pour_pointe.call(p):
				var d := _doigt_pour(p)
				if _zone().has_point(d) and pour_doigt.call(d) and p.distance_to(autour) < meilleure_dist:
					meilleur = p
					meilleure_dist = p.distance_to(autour)
			x += 3.0
		y += 3.0
	return meilleur


# --- Chasse --------------------------------------------------------------------------

func _arreter_minuteries() -> void:
	for n in _jeu.get_children():
		if n is Timer:
			(n as Timer).stop()


func _bulle_fixe(ou: Vector2) -> Node2D:
	var calque: Node2D = _jeu.get("_calque_bulles")
	for b in calque.get_children():
		b.free()
	_jeu.call("_lacher_bulle")
	var bulle: Node2D = calque.get_child(calque.get_child_count() - 1)
	bulle.vitesse = 0.0
	bulle.amplitude = 0.0
	bulle.position = ou
	bulle.set("_x_base", ou.x)
	return bulle


func _tableau_chasse() -> Control:
	var label: Label = _jeu.get("_label_mot")
	return label.get_parent().get_parent().get_parent()  # label → tableau → ligne → conteneur


## Ou naissent les bulles (y) : on lache une bulle et on lit sa position avant tout mouvement.
func _naissance_bulles() -> float:
	var calque: Node2D = _jeu.get("_calque_bulles")
	for b in calque.get_children():
		b.free()
	_jeu.call("_lacher_bulle")
	return (calque.get_child(calque.get_child_count() - 1) as Node2D).position.y


func _attrapee(bulle) -> bool:
	return not is_instance_valid(bulle) or bulle.is_queued_for_deletion()


func _chasse() -> void:
	print("--- CHASSE (desktop, reference) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", false)
	await _monter("res://scenes/chasse.tscn", false)
	_arreter_minuteries()
	var tableau_desktop := _tableau_chasse().get_global_rect()
	var naissance_desktop := _naissance_bulles()
	print("  tableau %s, bulles nees a y=%.0f" % [tableau_desktop, naissance_desktop])
	# Q : clic souris de PC sur la bulle
	var bulle := _bulle_fixe(Vector2(640, 420))
	await _trames(2)
	var bord := bulle.position + Vector2(0, 40)
	Doigt.souris_mouvement(root, Vector2(600, 900), bord)
	await _trames(2)
	Doigt.souris_bouton(root, bord, true)
	await _trames(2)
	Doigt.souris_bouton(root, bord, false)
	await _trames(2)
	_verifier("Q[chasse PC] clic souris sur la bulle → ATTRAPEE, curseur au pointeur",
		_attrapee(bulle) and _curseur.position.distance_to(bord) < 0.6, "curseur %s / %s" % [_curseur.position, bord])
	# Q : touche physique de la lettre (le clavier du PC reste un 2e moyen)
	bulle = _bulle_fixe(Vector2(640, 420))
	await _trames(2)
	var lettre: String = bulle.lettre
	var touche := InputEventKey.new()
	touche.pressed = true
	touche.keycode = OS.find_keycode_from_string(lettre)
	touche.physical_keycode = touche.keycode
	touche.unicode = lettre.unicode_at(0)
	Input.parse_input_event(touche)
	Input.flush_buffered_events()
	await _trames(2)
	_verifier("Q[chasse PC] touche PHYSIQUE « %s » → bulle ATTRAPEE" % lettre, _attrapee(bulle),
		"mot « %s »" % _jeu.get("_mot"))
	var relache := touche.duplicate()
	relache.pressed = false
	Input.parse_input_event(relache)
	Input.flush_buffered_events()
	await _demonter()

	print("--- CHASSE (Android : mode tactile, curseur x2) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _monter("res://scenes/chasse.tscn", true)
	_arreter_minuteries()
	var claviers := _a_script("res://scripts/clavier/clavier_virtuel.gd")
	var touches_lettres := []
	for b in _jeu.find_children("*", "Button", true, false):
		if (b as Button).text.length() == 1:
			touches_lettres.append((b as Button).text)
	_verifier("A aucun clavier dessine (noeud clavier_virtuel)", claviers.is_empty(), "%d trouve(s)" % claviers.size())
	_verifier("A aucune touche-lettre a l'ecran", touches_lettres.is_empty(), "touches %s" % [touches_lettres])
	var tableau_tactile := _tableau_chasse().get_global_rect()
	_verifier("A tableau A LA MEME PLACE que sous Linux (desktop)", tableau_tactile.is_equal_approx(tableau_desktop),
		"tactile %s / desktop %s" % [tableau_tactile, tableau_desktop])
	var naissance_tactile := _naissance_bulles()
	_verifier("A les bulles naissent sous le bord bas, comme sous Linux (y=%.0f)" % naissance_tactile,
		is_equal_approx(naissance_tactile, naissance_desktop), "desktop y=%.0f" % naissance_desktop)
	_verifier("A visee a la pointe branchee (jeu souris, comme Ballons)",
		_a_script("res://scripts/visee_pointe.gd").size() == 1)
	bulle = _bulle_fixe(Vector2(640, 420))
	await _trames(3)
	var dedans := func(q: Vector2) -> bool: return bulle.contient(q)
	var dehors := func(q: Vector2) -> bool: return not bulle.contient(q)
	var p := _chercher(bulle.position, dehors, dedans)
	var d := _doigt_pour(p)
	await _tap(d)
	_verifier("Ca doigt sur la bulle « %s », pointe dehors → PAS attrapee" % bulle.lettre, not _attrapee(bulle),
		"doigt %s, pointe %s" % [d, p])
	p = _chercher(bulle.position, dedans, dehors)
	d = _doigt_pour(p)
	lettre = bulle.lettre
	await _tap(d)
	_verifier("Cb pointe sur la bulle « %s », doigt dehors → ATTRAPEE, au tableau" % lettre,
		_attrapee(bulle) and String(_jeu.get("_mot")).ends_with(lettre),
		"doigt %s, pointe %s, mot « %s »" % [d, p, _jeu.get("_mot")])
	await _demonter()


# --- Mots ----------------------------------------------------------------------------

func _touches_mots() -> Array:
	var clavier: Control = _jeu.get("_clavier")
	return [] if clavier == null else clavier.find_children("*", "Button", true, false)


func _touche_sous(p: Vector2) -> Button:
	for t in _touches_mots():
		if (t as Button).get_global_rect().has_point(p):
			return t
	return null


func _touche(texte: String) -> Button:
	for t in _touches_mots():
		if (t as Button).text == texte:
			return t
	return null


func _mots() -> void:
	print("--- MOTS (Android : mode tactile, curseur x2) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	seed(7)
	await _monter("res://scenes/mots.tscn", true)
	var z := _zone()
	_verifier("M pas de visee a la pointe dans Mots", _a_script("res://scripts/visee_pointe.gd").is_empty())
	var clavier: Control = _jeu.get("_clavier")
	var r := clavier.get_global_rect()
	_verifier("M clavier A SA PLACE D'ORIGINE : bas de l'ecran, %d px, aucune remontee" % int(HAUTEUR_CLAVIER),
		is_equal_approx(r.position.y, z.end.y - HAUTEUR_CLAVIER) and is_equal_approx(r.end.y, z.end.y)
			and float(clavier.get("remontee")) == 0.0,
		"clavier y%.0f→%.0f (ecran %.0f), remontee %.0f" % [r.position.y, r.end.y, z.end.y, float(clavier.get("remontee"))])
	var marge := (clavier.get_child(0) as MarginContainer).get_theme_constant("margin_bottom")
	_verifier("M marge basse du clavier d'origine (%d px)" % MARGE_ORIGINE, marge == MARGE_ORIGINE, "%d" % marge)
	var centre: Control = (_jeu.get("_ligne_tuiles") as Control).get_parent()
	_verifier("M tuiles au-dessus du clavier comme a l'origine (plein ecran, bas a -%d)" % int(HAUTEUR_CLAVIER),
		is_equal_approx(centre.offset_bottom, -HAUTEUR_CLAVIER) and is_equal_approx(centre.offset_top, 0.0),
		"offsets haut %.0f bas %.0f" % [centre.offset_top, centre.offset_bottom])
	# Le doigt glisse : le curseur suit SOUS le doigt (aucune pointe decalee)
	var de := Vector2(500, 300)
	var a := Vector2(620, 360)
	Doigt.toucher(root, de, true)
	await _trames(2)
	Doigt.glisser(root, de, a)
	await _trames(2)
	Doigt.toucher(root, a, false)
	await _trames(3)
	_verifier("M le doigt glisse : curseur SOUS le doigt (%s), pas a la pointe (%s)" % [a, _pointe_pour(a)],
		_curseur.position.distance_to(a) < 0.6 and _pointe_pour(a).distance_to(a) > 20.0, "curseur %s" % _curseur.position)
	# Touche sous le DOIGT tapee, la pointe etant sur une AUTRE touche (discriminant)
	var cible: String = String(_jeu.get("_mot_cible"))[0]
	print("  mot a ecrire « %s »" % _jeu.get("_mot_cible"))
	var tapees := []
	for t in _touches_mots():
		(t as Button).pressed.connect(func() -> void: tapees.append((t as Button).text))
	var tc := _touche(cible)
	var d := Vector2.INF
	var rc := tc.get_global_rect().grow(-4.0)
	var y := rc.end.y
	while y >= rc.position.y and d == Vector2.INF:
		var q := Vector2(rc.get_center().x, y)
		var sous_pointe := _touche_sous(_pointe_pour(q))
		if sous_pointe != tc:
			d = q
		y -= 3.0
	if d == Vector2.INF:
		_verifier("M mise en place : doigt sur « %s », pointe ailleurs" % cible, false)
	else:
		var ailleurs := _touche_sous(_pointe_pour(d))
		await _tap(d)
		await _trames(2)
		_verifier("M doigt sur « %s », pointe sur « %s » → c'est « %s » (le DOIGT) qui est tape, le mot AVANCE" \
				% [cible, "hors touche" if ailleurs == null else ailleurs.text, cible],
			tapees == [cible] and int(_jeu.get("_position")) == 1, "tapees %s, position %d" % [tapees, int(_jeu.get("_position"))])
		var lecteur: AudioStreamPlayer = _jeu.get_node_or_null(Voix.NOM_LECTEUR)
		_verifier("M la voix dit la lettre (lecteur de voix en route, flux pose)",
			lecteur != null and lecteur.stream != null and lecteur.playing)
	# Le reste du mot au doigt (centre des touches) → mot complete
	var mot: String = _jeu.get("_mot_cible")
	for i in range(int(_jeu.get("_position")), mot.length()):
		await _tap(_touche(mot[i]).get_global_rect().get_center())
		await _trames(2)
	_verifier("M mot « %s » tape au doigt jusqu'au bout → fete du mot" % mot, bool(_jeu.get("_en_transition")),
		"position %d" % int(_jeu.get("_position")))
	await create_timer(3.0).timeout
	_verifier("M mot suivant tire (deroule intact)", not bool(_jeu.get("_en_transition")) and int(_jeu.get("_position")) == 0,
		"mot « %s »" % _jeu.get("_mot_cible"))
	await _demonter()


func _derouler() -> void:
	print("=== PREUVE CHASSE = JEU SOURIS, MOTS A L'ORIGINE (doigt Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	await _chasse()
	await _mots()
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)

# Preuve de la VISEE A LA POINTE dans les JEUX NATIFS (REQ_261007 android_visee_pointe_JEUX).
# Decision Fabrice : sur Android comme sur Linux, on vise avec le doigt DU CURSEUR (la pointe),
# touches du clavier dessine comprises. Monte chaque VRAI jeu en mode tactile (user:// isole),
# passe le curseur a la gamme Android (x2, comme sur la tablette) et pose des doigts par le VRAI
# chemin du moteur (outils/doigt_moteur.gd : ScreenTouch → clic emule fabrique par Godot).
# Chaque cas est DISCRIMINANT : la pointe et le doigt tombent sur deux choses differentes.
#   T  (tous)    un tap POSE le curseur : pointe = la ou le doigt l'amene, pas sous le doigt ;
#   B  ballons   doigt sur le ballon / pointe dehors → intact ; pointe dessus / doigt dehors → eclate ;
#   S  souris    fleurs du clic nees a la pointe ; croix : pointe dessus / doigt dehors → quitte,
#                doigt dessus / pointe dehors → reste ;
#   L  lettres   touche sous la POINTE tapee (≠ touche sous le doigt), lettre affichee ; curseur sans facteur propre ;
#   C  chasse    bulle sous la pointe attrapee (doigt dehors), l'inverse → non (jeu SOURIS, sans clavier) ;
#   Mots : PLUS de visee a la pointe (decision Fabrice 07-10, retour a l'origine) — sa preuve, avec
#   Chasse sans clavier : outils/preuve_chasse_mots_android.gd ;
#   P  souris PC INCHANGEE (ballons, lettres) : clic et curseur au pointeur, aucun decalage.
#   R  (lettres) PORTEE : chaque touche du clavier dessine doit etre atteignable par la pointe
#      sur au moins la moitie de sa hauteur. Vert depuis la REMONTEE du clavier (decision Fabrice,
#      REQ_261007_android_clavier_remonte) ; portee stricte et 4 cibles : outils/preuve_clavier_remonte.gd.
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_visee_pointe_jeux.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")

const ANDROID := 2.0  # AGRANDI_TAILLE_ANDROID des curseur.gd

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


func _doigt_pour(pointe: Vector2) -> Vector2:
	return Doigt.doigt_pour_pointe(_curseur, pointe, _zone())


func _pointe_pour(doigt: Vector2) -> Vector2:
	return _curseur.pointe_pour_doigt(doigt, _zone())


func _tap_doigt(d: Vector2) -> void:
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.toucher(root, d, false)
	await _trames(3)


## Cherche une pointe telle que `pour_pointe(pointe)` et `pour_doigt(doigt)` soient vrais,
## la plus proche de `autour` (grille de 3 px). Vector2.INF si aucune.
func _chercher(autour: Vector2, pour_pointe: Callable, pour_doigt: Callable, rayon := 260.0) -> Vector2:
	var meilleur := Vector2.INF
	var meilleure_dist := INF
	var pas := 3.0
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
			x += pas
		y += pas
	return meilleur


## Monte un jeu ; `android` = passe le curseur a la gamme Android (x2), comme sur la tablette.
func _monter(chemin: String, android: bool) -> void:
	_jeu = load(chemin).instantiate()
	root.add_child(_jeu)
	current_scene = _jeu
	await _trames(6)
	_curseur = _jeu.get("_curseur")
	if android:
		_curseur.gamme = ANDROID
		_curseur.set("_echelle_base", float(_curseur.get("_echelle_base")) * ANDROID)
	await _trames(2)


func _demonter() -> void:
	if is_instance_valid(_jeu):
		_jeu.queue_free()
	if current_scene != null and current_scene != _jeu and is_instance_valid(current_scene):
		current_scene.queue_free()  # bureau charge par la croix
	await _trames(4)


func _mesurer_decalage(nom: String) -> void:
	var milieu := _zone().get_center()
	var d: Vector2 = _curseur.decalage_doigt()
	print("  [%s] decalage doigt → pointe = (%.1f, %.1f) px viewport, |%.1f| (au milieu : pointe %s pour doigt %s)" \
			% [nom, d.x, d.y, d.length(), _pointe_pour(milieu), milieu])


## T : un tap pose le curseur a la pointe (pas sous le doigt). Point neutre (milieu-haut).
func _cas_tap(nom: String, doigt: Vector2) -> void:
	var attendu := _pointe_pour(doigt)
	await _tap_doigt(doigt)
	_verifier("T[%s] un tap POSE le curseur, pointe decalee du doigt" % nom,
		_curseur.position.distance_to(attendu) < 0.6 and _curseur.position.distance_to(doigt) > 20.0,
		"curseur %s, pointe attendue %s, doigt %s" % [_curseur.position, attendu, doigt])


func _touches() -> Array:
	var clavier: Control = _jeu.get("_clavier")
	if clavier == null:
		return []
	return clavier.find_children("*", "Button", true, false)


func _touche_sous(p: Vector2) -> Button:
	for t in _touches():
		if (t as Button).get_global_rect().has_point(p):
			return t
	return null


## Touche « lettre » (texte non vide) ; `filtre` facultatif sur le texte.
## Point FRANC (4 px a l'interieur) : un point pile sur le bord d'une touche est un artefact de mesure.
func _est_lettre(p: Vector2, filtre := "") -> bool:
	var t := _touche_sous(p)
	return t != null and t.text != "" and (filtre == "" or t.text == filtre) \
		and t.get_global_rect().grow(-4.0).has_point(p)


func _espionner_touches() -> Array:
	var tapees := []
	for t in _touches():
		(t as Button).pressed.connect(func() -> void: tapees.append((t as Button).text))
	return tapees


## Clavier : pointe sur une touche-lettre, doigt sur une AUTRE touche-lettre → c'est la touche
## de la pointe qui est tapee. Rend [lettre visee, lettre sous le doigt] ou [] si echec.
func _cas_touche(nom: String, tapees: Array, cible := "") -> Array:
	var clavier: Control = _jeu.get("_clavier")
	var autour := clavier.get_global_rect().get_center()
	var p := _chercher(autour,
		func(q: Vector2) -> bool: return _est_lettre(q, cible),
		# doigt sur une AUTRE touche, ou (rangee du bas) sur la bande de remontee du clavier
		func(q: Vector2) -> bool: return clavier.contient(q) and _touche_sous(q) != _touche_sous(_pointe_pour(q)),
		clavier.size.x / 2.0)
	if p == Vector2.INF:
		_verifier("K[%s] mise en place : pointe et doigt sur deux touches differentes" % nom, false)
		return []
	var d := _doigt_pour(p)
	var visee: String = _touche_sous(p).text
	var sous_doigt: String = "(bande de remontee)" if _touche_sous(d) == null else _touche_sous(d).text
	_verifier("K[%s] mise en place : pointe sur « %s », doigt sur « %s »" % [nom, visee, sous_doigt],
		visee != sous_doigt, "pointe %s, doigt %s" % [p, d])
	tapees.clear()
	await _tap_doigt(d)
	_verifier("K[%s] la touche tapee est celle de la POINTE (« %s »), pas celle du doigt" % [nom, visee],
		tapees == [visee], "tapees %s" % [tapees])
	return [visee, sous_doigt]


## R : part de chaque rangee du clavier que la pointe peut viser (doigt au plus bas = bord de l'ecran).
func _cas_portee(nom: String) -> void:
	var bas_max: float = _pointe_pour(Vector2(_zone().get_center().x, _zone().end.y)).y
	var rangees := {}
	for t in _touches():
		var r: Rect2 = (t as Button).get_global_rect()
		var cle := int(r.position.y)
		if not rangees.has(cle):
			rangees[cle] = [r, []]
		rangees[cle][1].append((t as Button).text if (t as Button).text != "" else "⌫")
	for cle in rangees:
		var r: Rect2 = rangees[cle][0]
		var part := clampf((bas_max - r.position.y) / r.size.y, 0.0, 1.0)
		_verifier("R[%s] rangee %s visable par la pointe (%.0f %% de sa hauteur)" % [nom, "".join(rangees[cle][1]), part * 100.0],
			part >= 0.5, "pointe la plus basse y=%.0f, rangee y %.0f→%.0f" % [bas_max, r.position.y, r.end.y])


# --- Ballons --------------------------------------------------------------------

func _ballons() -> void:
	print("--- BALLONS ---")
	await _monter("res://scenes/ballons.tscn", true)
	_mesurer_decalage("ballons")
	await create_timer(1.6).timeout  # les 3 premiers ballons etages sont partis
	(_jeu.get("_minuterie") as Timer).stop()
	var calque: Node2D = _jeu.get("_calque_ballons")
	for b in calque.get_children():
		b.free()
	var ballon: Node2D = (_jeu.get("_Ballon") as GDScript).new()
	ballon.rayon = 50.0
	ballon.vitesse = 0.0
	ballon.amplitude = 0.0
	ballon.position = Vector2(640, 520)
	calque.add_child(ballon)
	await create_timer(0.5).timeout
	await _cas_tap("ballons", Vector2(400, 300))
	var dedans := func(q: Vector2) -> bool: return ballon.contient(q)
	var dehors := func(q: Vector2) -> bool: return not ballon.contient(q)
	# Ba : doigt SUR le ballon, pointe dehors → intact
	var p := _chercher(ballon.position, dehors, dedans)
	var d := _doigt_pour(p)
	await _tap_doigt(d)
	_verifier("Ba doigt sur le ballon, pointe dehors : ballon INTACT",
		is_instance_valid(ballon) and int(_jeu.get("_compteur")) == 0,
		"doigt %s, pointe %s, compteur %d" % [d, p, int(_jeu.get("_compteur"))])
	# Bb : pointe SUR le ballon, doigt dehors → eclate
	p = _chercher(ballon.position, dedans, dehors)
	d = _doigt_pour(p)
	await _tap_doigt(d)
	await _trames(2)
	_verifier("Bb pointe sur le ballon, doigt dehors : ballon ECLATE",
		int(_jeu.get("_compteur")) == 1, "doigt %s, pointe %s, compteur %d" % [d, p, int(_jeu.get("_compteur"))])
	await _demonter()

	# P : souris de PC inchangee (gamme PC, vraie souris device 0)
	await _monter("res://scenes/ballons.tscn", false)
	_mesurer_decalage("ballons PC")
	(_jeu.get("_minuterie") as Timer).stop()
	await create_timer(1.6).timeout
	calque = _jeu.get("_calque_ballons")
	for b in calque.get_children():
		b.free()
	ballon = (_jeu.get("_Ballon") as GDScript).new()
	ballon.rayon = 50.0
	ballon.vitesse = 0.0
	ballon.amplitude = 0.0
	ballon.position = Vector2(640, 520)
	calque.add_child(ballon)
	await create_timer(0.5).timeout
	var bord := ballon.position + Vector2(0, 48)  # dans le ballon, a son bord bas
	Doigt.souris_mouvement(root, Vector2(600, 900), bord)
	await _trames(2)
	_verifier("P[ballons] souris PC : curseur AU pointeur", _curseur.position.distance_to(bord) < 0.6,
		"%s / %s" % [_curseur.position, bord])
	Doigt.souris_bouton(root, bord, true)
	await _trames(2)
	Doigt.souris_bouton(root, bord, false)
	await _trames(2)
	_verifier("P[ballons] souris PC : clic au pointeur → eclate", int(_jeu.get("_compteur")) == 1)
	await _demonter()


# --- Decouverte de la souris -----------------------------------------------------

func _croix() -> Button:
	for b in _jeu.get_children():
		if b is Button:
			return b
	return null


func _souris() -> void:
	print("--- DECOUVERTE DE LA SOURIS ---")
	await _monter("res://scenes/souris.tscn", true)
	_mesurer_decalage("souris")
	await _cas_tap("souris", Vector2(400, 300))
	var effets: Node2D = _jeu.get("_calque_effets")
	await create_timer(1.5).timeout  # effets du tap precedent fanes
	var d := Vector2(500, 700)
	var p := _pointe_pour(d)
	var avant := effets.get_children()
	await _tap_doigt(d)
	var a_la_pointe := 0
	var au_doigt := 0
	for n in effets.get_children():
		if n in avant:
			continue
		if (n as Node2D).position.distance_to(p) < 0.6:
			a_la_pointe += 1
		if (n as Node2D).position.distance_to(d) < 0.6:
			au_doigt += 1
	_verifier("S clic : la fleur centrale nait a la POINTE, aucune au doigt",
		a_la_pointe >= 1 and au_doigt == 0, "a la pointe %d, au doigt %d (pointe %s, doigt %s)" % [a_la_pointe, au_doigt, p, d])
	var croix := _croix()
	var appuis := [0]
	croix.pressed.connect(func() -> void: appuis[0] += 1)
	var r := croix.get_global_rect()
	var sur := func(q: Vector2) -> bool: return r.has_point(q)
	var hors := func(q: Vector2) -> bool: return not r.grow(4.0).has_point(q)
	p = _chercher(r.get_center(), hors, sur)
	if p == Vector2.INF:
		print("  (croix : aucun point « doigt dessus / pointe dehors » — bords fondus au coin, cas sans objet)")
	else:
		d = _doigt_pour(p)
		await _tap_doigt(d)
		_verifier("Sa croix : doigt dessus, pointe dehors → le jeu RESTE", appuis[0] == 0,
			"doigt %s, pointe %s, croix %s" % [d, p, r])
	p = _chercher(r.get_center(), sur, hors)
	if p == Vector2.INF:
		_verifier("Sb mise en place : pointe sur la croix, doigt dehors", false)
	else:
		d = _doigt_pour(p)
		await _tap_doigt(d)
		_verifier("Sb croix : pointe dessus, doigt dehors → QUITTE", appuis[0] == 1,
			"doigt %s, pointe %s, croix %s" % [d, p, r])
	await _demonter()


# --- Lettres ----------------------------------------------------------------------

func _lettres() -> void:
	print("--- LETTRES ---")
	await _monter("res://scenes/lettres.tscn", true)
	_mesurer_decalage("lettres")
	_verifier("L curseur sans facteur propre (meme taille que les autres jeux)", not ("facteur" in _curseur))
	await _cas_tap("lettres", Vector2(400, 200))
	_cas_portee("lettres")
	var tapees := _espionner_touches()
	var paire := await _cas_touche("lettres", tapees)
	if not paire.is_empty():
		await _trames(3)
		var affiche: String = (_jeu.get("_label_lettre") as Label).text
		_verifier("L la bulle affiche « %s » (pointe), pas « %s » (doigt)" % [paire[0], paire[1]],
			affiche == paire[0], "bulle « %s », mot « %s »" % [affiche, _jeu.get("_mot")])
	await _demonter()

	# P : souris de PC inchangee sur une touche (gamme PC)
	await _monter("res://scenes/lettres.tscn", false)
	_mesurer_decalage("lettres PC")
	tapees = _espionner_touches()
	var t: Button = _touches()[0]
	var c := t.get_global_rect().get_center()
	Doigt.souris_mouvement(root, c + Vector2(0, -200), c)
	await _trames(2)
	Doigt.souris_bouton(root, c, true)
	await _trames(2)
	Doigt.souris_bouton(root, c, false)
	await _trames(2)
	_verifier("P[lettres] souris PC : curseur ET touche au pointeur (« %s »)" % t.text,
		_curseur.position.distance_to(c) < 0.6 and tapees == [t.text], "curseur %s / %s, tapees %s" % [_curseur.position, c, tapees])
	await _demonter()


# --- Chasse -----------------------------------------------------------------------

func _chasse() -> void:
	print("--- CHASSE ---")
	await _monter("res://scenes/chasse.tscn", true)
	_mesurer_decalage("chasse")
	for n in _jeu.get_children():
		if n is Timer:
			(n as Timer).stop()
	var calque: Node2D = _jeu.get("_calque_bulles")
	for b in calque.get_children():
		b.free()
	await _cas_tap("chasse", Vector2(400, 200))
	_jeu.call("_lacher_bulle")
	var bulle: Node2D = calque.get_child(calque.get_child_count() - 1)
	bulle.vitesse = 0.0
	bulle.amplitude = 0.0
	bulle.position = Vector2(640, 420)
	bulle.set("_x_base", 640.0)
	await _trames(3)
	var dedans := func(q: Vector2) -> bool: return bulle.contient(q)
	var dehors := func(q: Vector2) -> bool: return not bulle.contient(q)
	var p := _chercher(bulle.position, dehors, dedans)
	var d := _doigt_pour(p)
	await _tap_doigt(d)
	_verifier("Ca doigt sur la bulle « %s », pointe dehors → PAS attrapee" % bulle.lettre,
		is_instance_valid(bulle) and not bulle.is_queued_for_deletion(), "doigt %s, pointe %s" % [d, p])
	p = _chercher(bulle.position, dedans, dehors)
	d = _doigt_pour(p)
	var lettre: String = bulle.lettre
	await _tap_doigt(d)
	_verifier("Cb pointe sur la bulle « %s », doigt dehors → ATTRAPEE" % lettre,
		not is_instance_valid(bulle) or bulle.is_queued_for_deletion(), "doigt %s, pointe %s, mot « %s »" % [d, p, _jeu.get("_mot")])
	await _demonter()


func _derouler() -> void:
	print("=== PREUVE VISEE A LA POINTE — JEUX NATIFS (doigt Android) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _ballons()
	await _souris()
	await _lettres()
	await _chasse()
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)

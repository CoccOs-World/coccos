# Preuve #224 : la ROUE DES REGLAGES et le bouton ETEINDRE de la barre repondent au doigt BRUT
# (decalage doigt → pointe ANNULE sur ces deux boutons seulement — demande de Fabrice, 22-10).
# Monte le VRAI bureau en mode tactile (user:// isole), barre et curseur forces « Android »
# (hauteur_barre_pour(true), gamme x2, defaut « petit » #223 — la feature android n'est pas
# simulable sur PC), et pose des doigts par le VRAI chemin du moteur (outils/doigt_moteur.gd :
# ScreenTouch → clic emule fabrique par Godot). Chaque cas est DISCRIMINANT (doigt et pointe
# tombent sur deux choses differentes) :
#   R1 roue      : doigt brut SUR la roue, pointe dehors (au-dessus de la barre) → PRESSEE,
#                  le clic recu porte le DOIGT (pas la pointe), coccinelle posee au doigt ;
#   R2 eteindre  : idem ;
#   R3 roue      : pointe SUR la roue, doigt dessous (marge basse, hors boutons) → pressee aussi
#                  (la visee a la pointe n'est pas retiree, elle s'ajoute) ;
#   R4 derive    : appui brut sur la roue, doigt qui glisse de 10 px puis se leve → pressee
#                  (l'exception tient jusqu'au relache) ;
#   R5 Menu      : HORS exception — doigt brut sur « Menu », pointe dehors → boite FERMEE ;
#   R6 icone jeu : HORS exception — doigt brut sur l'icone, pointe dehors → AUCUN lancement ;
#                  pointe sur l'icone, doigt dehors → lancee (acquis 07-10 conserve).
# Les handlers reels des deux boutons (changement de scene / quit) sont debranches ici et
# remplaces par des compteurs : la preuve verifie le signal `pressed`, pas la suite.
# Lancement (user:// ISOLE) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_barre_doigt_brut.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Registre := preload("res://scripts/registre_jeux.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")
const Lang := preload("res://scripts/lang.gd")

const MARGE := 8.0
const TOL := 0.6

var _echecs := 0
var _bureau: Control
var _curseur: Node2D
var _presses := {}  # nom → nombre de `pressed`
var _recus := {}    # nom → positions globales des clics recus (gui_input)


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


func _pointe(doigt: Vector2) -> Vector2:
	return _curseur.pointe_pour_doigt(doigt, _zone())


func _doigt_pour(pointe: Vector2) -> Vector2:
	return Doigt.doigt_pour_pointe(_curseur, pointe, _zone())


func _tap(d: Vector2) -> void:
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.toucher(root, d, false)
	await _trames(3)


func _monter_bureau() -> void:
	_bureau = load("res://scenes/bureau.tscn").instantiate()
	_bureau.hauteur_barre = _bureau.hauteur_barre_pour(true)  # barre Android (114)
	root.add_child(_bureau)
	current_scene = _bureau
	await _trames(4)
	_curseur = _bureau.get("_curseur")
	_curseur.android = true
	_curseur.gamme = _curseur.gamme_pour(true)
	_curseur._ready()  # relit la config : gamme x2, defaut « petit » (#223)
	await _trames(2)


func _demonter() -> void:
	_bureau.queue_free()
	await _trames(3)


## Bouton de la barre portant le pictogramme `id_picto` (engrenage / eteindre).
func _bouton_picto(id_picto: String) -> Button:
	for b in _bureau.find_children("*", "Button", true, false):
		for enfant in b.get_children():
			if enfant.get("id") == id_picto:
				return b
	return null


func _bouton_menu() -> Button:
	for b in _bureau.find_children("*", "Button", true, false):
		if (b as Button).text == Lang.t("bureau_menu"):
			return b
	return null


## Debranche le vrai handler (scene / quit) et compte les `pressed` + positions recues.
func _surveiller(btn: Button, nom: String, handler: Callable) -> void:
	if btn.pressed.is_connected(handler):
		btn.pressed.disconnect(handler)
	_presses[nom] = 0
	_recus[nom] = []
	btn.pressed.connect(func() -> void: _presses[nom] += 1)
	btn.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			_recus[nom].append(e.global_position))


func _icones() -> Array:
	return _bureau.get_children().filter(func(n: Node) -> bool: return n.has_signal("deplacee"))


func _jeu_direct() -> Control:
	for ic in _icones():
		var a: Dictionary = Registre.appli(ic.id)
		if not ic.est_dossier and not a.is_empty() and a.has("scene"):
			return ic
	return null


func _cas_brut(nom: String, cle: String, btn: Button) -> void:
	var r := btn.get_global_rect()
	var d := Vector2(r.get_center().x, r.position.y + MARGE)  # doigt dans le HAUT du bouton
	var p := _pointe(d)
	var barre_haut: float = _zone().end.y - _bureau.hauteur_barre
	_verifier("%s mise en place : doigt SUR le bouton, pointe DEHORS (au-dessus de la barre)" % nom,
		r.has_point(d) and not r.has_point(p) and p.y < barre_haut,
		"doigt %s, pointe %s, bouton %s, haut de barre %.0f" % [d, p, r, barre_haut])
	var avant: int = _presses[cle]
	_recus[cle].clear()
	await _tap(d)
	_verifier("%s doigt brut sur le bouton : PRESSE" % nom, _presses[cle] == avant + 1, "pressed = %d" % _presses[cle])
	_verifier("%s le clic recu porte le DOIGT (decalage annule)" % nom,
		_recus[cle].size() == 1 and (_recus[cle][0] as Vector2).distance_to(d) < TOL, "recus %s / doigt %s" % [_recus[cle], d])
	_verifier("%s la coccinelle est posee AU DOIGT" % nom, _curseur.position.distance_to(d) < TOL,
		"%s / %s" % [_curseur.position, d])
	_verifier("%s exception levee apres le relache" % nom, _bureau.get("_doigt_sur_bouton") == false)


func _derouler() -> void:
	print("=== PREUVE #224 ROUE + ETEINDRE AU DOIGT BRUT (bureau Android force, headless) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _monter_bureau()
	print("  zone %s, barre %d px, echelle curseur %.2f, decalage doigt → pointe = %s" % [
		_zone(), _bureau.hauteur_barre, _curseur.get("_echelle_base"), _curseur.decalage_doigt()])
	_verifier("curseur Android sans reglage = « petit » x2 (#223)", is_equal_approx(_curseur.get("_echelle_base"), 0.55 * 2.0),
		"echelle = %.3f" % _curseur.get("_echelle_base"))
	var roue := _bouton_picto("engrenage")
	var eteindre := _bouton_picto("eteindre")
	var menu := _bouton_menu()
	var jeu := _jeu_direct()
	_verifier("bureau monte : roue, eteindre, Menu, une icone de jeu", roue != null and eteindre != null and menu != null and jeu != null)
	if roue == null or eteindre == null or menu == null or jeu == null:
		_fin()
		return
	_surveiller(roue, "R-roue", Callable(_bureau, "_aller_reglages"))
	_surveiller(eteindre, "R-eteindre", Callable(_bureau, "_eteindre"))
	var exception: Variant = _bureau.get("_boutons_au_doigt")  # absent sur l'origine → rouge, on continue
	_verifier("exception bornee a DEUX boutons : roue + eteindre",
		exception is Array and exception.size() == 2 and roue in exception and eteindre in exception, str(exception))

	# R1 / R2 : doigt brut sur la roue, puis sur eteindre
	await _cas_brut("R1 roue", "R-roue", roue)
	await _cas_brut("R2 eteindre", "R-eteindre", eteindre)

	# R3 : pointe SUR la roue, doigt dessous dans la marge basse de la barre (hors des deux boutons)
	var r := roue.get_global_rect()
	var d := Vector2(r.get_center().x, r.end.y + 4.0)
	var p := _pointe(d)
	_verifier("R3 mise en place : doigt sous la roue (hors boutons), pointe SUR la roue",
		not r.has_point(d) and not eteindre.get_global_rect().has_point(d) and r.has_point(p) and d.y < _zone().end.y,
		"doigt %s, pointe %s, roue %s" % [d, p, r])
	var avant: int = _presses["R-roue"]
	_recus["R-roue"].clear()
	await _tap(d)
	_verifier("R3 pointe sur la roue : PRESSEE (visee a la pointe conservee)", _presses["R-roue"] == avant + 1)
	_verifier("R3 le clic recu porte la POINTE", _recus["R-roue"].size() == 1 and (_recus["R-roue"][0] as Vector2).distance_to(p) < TOL,
		"recus %s / pointe %s" % [_recus["R-roue"], p])

	# R4 : derive de 10 px pendant l'appui brut → toujours pressee
	d = Vector2(r.get_center().x - 5.0, r.position.y + MARGE)
	avant = _presses["R-roue"]
	Doigt.toucher(root, d, true)
	await _trames(2)
	Doigt.glisser(root, d, d + Vector2(10, 0))
	await _trames(2)
	_verifier("R4 pendant la derive, l'exception tient", _bureau.get("_doigt_sur_bouton") == true)
	Doigt.toucher(root, d + Vector2(10, 0), false)
	await _trames(3)
	_verifier("R4 doigt brut + derive de 10 px sur la roue : PRESSEE", _presses["R-roue"] == avant + 1, "pressed = %d" % _presses["R-roue"])
	_verifier("R4 exception levee apres le relache", _bureau.get("_doigt_sur_bouton") == false)

	# R5 : Menu reste a la pointe — doigt brut sur Menu (haut), pointe dehors → ferme
	var rm := menu.get_global_rect()
	d = Vector2(rm.get_center().x, rm.position.y + MARGE)
	p = _pointe(d)
	_verifier("R5 mise en place : doigt SUR Menu, pointe dehors", rm.has_point(d) and not rm.has_point(p), "doigt %s, pointe %s" % [d, p])
	await _tap(d)
	_verifier("R5 Menu hors exception : boite a icones FERMEE", _bureau.get("_menu") == null)
	# et la pointe sur Menu l'ouvre bien
	p = Vector2(rm.get_center().x, rm.position.y + MARGE)
	d = _doigt_pour(p)
	await _tap(d)
	_verifier("R5 pointe SUR Menu (doigt %s) : boite OUVERTE" % [d], _bureau.get("_menu") != null)
	if _bureau.get("_menu") != null:
		_bureau.call("_fermer_menu")
		await _trames(2)

	# R6 : icone de jeu — doigt brut dessus, pointe dehors → rien ; pointe dessus → lancee
	var lancements := []
	jeu.lancee.connect(func(id: String) -> void: lancements.append(id))
	var rj: Rect2 = (jeu.get("_btn") as Control).get_global_rect()
	d = Vector2(rj.get_center().x, rj.position.y + MARGE)
	p = _pointe(d)
	_verifier("R6a mise en place : doigt SUR l'icone, pointe dehors", rj.has_point(d) and not rj.has_point(p), "doigt %s, pointe %s" % [d, p])
	await _tap(d)
	_verifier("R6a icone hors exception : AUCUN lancement au doigt brut", lancements.is_empty(), str(lancements))
	p = Vector2(rj.get_center().x, rj.end.y - MARGE)
	d = _doigt_pour(p)
	var scene_avant := current_scene
	_verifier("R6b mise en place : pointe SUR l'icone, doigt dehors", rj.has_point(p) and not rj.has_point(d), "doigt %s, pointe %s" % [d, p])
	await _tap(d)
	await _trames(4)
	_verifier("R6b pointe sur l'icone : lancee (acquis 07-10 conserve)", not lancements.is_empty() or current_scene != scene_avant,
		"lancements %s" % [lancements])
	_fin()


func _fin() -> void:
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)

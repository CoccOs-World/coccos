# Preuve MOTS sans curseur au doigt + CHASSE jamais de clavier (REQ_261007_mots_sans_curseur_chasse, §F et §E).
# Decisions Fabrice (07-10) : « Pour le jeu des mots, nous n'avons pas besoin de curseur. L'enfant clique directement
# sur les touches » ; « [Chasse] Il n'y a pas lieu d'avoir un clavier » (clavier virtuel OK pour Lettres seulement).
# Reprend le harnais de preuve_chasse_mots_android.gd (vrais jeux montes, user:// isole, doigts du moteur).
#   F  mots tactile : coccinelle-curseur MASQUEE (et le reste apres glisser + taps) ; tap au CENTRE d'une touche
#      → la lettre est saisie ; mot complete puis mot suivant ;
#   Fd mots desktop : curseur VISIBLE (inchange), aucun clavier dessine, touche physique → lettre saisie ;
#   E  chasse, mode tactile ACTIF puis INACTIF : 0 clavier dessine, 0 touche-lettre, 0 champ texte (clavier systeme) ;
#      discriminant : lettres en mode tactile = clavier dessine PRESENT (37 touches) ;
#   D  chasse : la bulle porte le galet (constantes) et s'attrape toujours (contient intact).
# Lancement :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_mots_chasse_polish.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends "res://outils/preuve_chasse_mots_android.gd"

const CURSEUR := "res://scripts/clavier/curseur.gd"


func _curseurs_visibles() -> int:
	var n := 0
	for c in _a_script(CURSEUR):
		if (c as CanvasItem).is_visible_in_tree():
			n += 1
	return n


func _touches_lettres() -> Array:
	var t := []
	for b in _jeu.find_children("*", "Button", true, false):
		if (b as Button).text.length() == 1:
			t.append((b as Button).text)
	return t


func _champs_texte() -> int:
	return _jeu.find_children("*", "LineEdit", true, false).size() + _jeu.find_children("*", "TextEdit", true, false).size()


func _touche_physique(lettre: String, appui: bool) -> void:
	var touche := InputEventKey.new()
	touche.pressed = appui
	touche.keycode = OS.find_keycode_from_string(lettre)
	touche.physical_keycode = touche.keycode
	touche.unicode = lettre.unicode_at(0)
	Input.parse_input_event(touche)
	Input.flush_buffered_events()


func _f_mots_tactile() -> void:
	print("--- F MOTS (Android : mode tactile) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	seed(11)
	await _monter("res://scenes/mots.tscn", true)
	_verifier("F coccinelle-curseur MASQUEE en tactile", _curseurs_visibles() == 0 and not _curseur.visible,
		"%d curseur(s) visible(s)" % _curseurs_visibles())
	var de := Vector2(500, 300)
	var a := Vector2(620, 360)
	Doigt.toucher(root, de, true)
	await _trames(2)
	Doigt.glisser(root, de, a)
	await _trames(2)
	Doigt.toucher(root, a, false)
	await _trames(3)
	_verifier("F toujours masquee apres un glisser du doigt", _curseurs_visibles() == 0)
	var mot: String = _jeu.get("_mot_cible")
	print("  mot a ecrire « %s »" % mot)
	var tapees := []
	for t in _touches_mots():
		(t as Button).pressed.connect(func() -> void: tapees.append((t as Button).text))
	await _tap(_touche(mot[0]).get_global_rect().get_center())
	await _trames(2)
	_verifier("F tap direct au CENTRE de « %s » → lettre saisie, le mot AVANCE" % mot[0],
		tapees == [mot[0]] and int(_jeu.get("_position")) == 1, "tapees %s, position %d" % [tapees, int(_jeu.get("_position"))])
	for i in range(1, mot.length()):
		await _tap(_touche(mot[i]).get_global_rect().get_center())
		await _trames(2)
	_verifier("F mot « %s » tape au doigt jusqu'au bout → fete du mot" % mot, bool(_jeu.get("_en_transition")))
	_verifier("F toujours masquee apres les taps", _curseurs_visibles() == 0)
	await create_timer(3.0).timeout
	_verifier("F mot suivant tire (deroule intact)", not bool(_jeu.get("_en_transition")) and int(_jeu.get("_position")) == 0,
		"mot « %s »" % _jeu.get("_mot_cible"))
	await _demonter()


func _f_mots_desktop() -> void:
	print("--- Fd MOTS (desktop) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", false)
	await _monter("res://scenes/mots.tscn", false)
	_verifier("Fd curseur VISIBLE sur PC (inchange)", _curseurs_visibles() == 1 and _curseur.visible)
	_verifier("Fd aucun clavier dessine sur PC", _jeu.get("_clavier") == null and _touches_lettres().is_empty())
	var mot: String = _jeu.get("_mot_cible")
	_touche_physique(mot[0], true)
	await _trames(2)
	_touche_physique(mot[0], false)
	await _trames(2)
	_verifier("Fd touche physique « %s » → lettre saisie" % mot[0], int(_jeu.get("_position")) == 1)
	await _demonter()


func _e_chasse(tactile: bool) -> void:
	var nom := "ACTIF" if tactile else "INACTIF"
	print("--- E CHASSE (mode tactile %s) ---" % nom)
	PinConfig.ecrire_option("interface", "mode_tactile", tactile)
	await _monter("res://scenes/chasse.tscn", tactile)
	_arreter_minuteries()
	var claviers := _a_script("res://scripts/clavier/clavier_virtuel.gd").size()
	var touches := _touches_lettres()
	_verifier("E chasse tactile %s : 0 clavier dessine, 0 touche-lettre, 0 champ texte" % nom,
		claviers == 0 and touches.is_empty() and _champs_texte() == 0,
		"claviers %d, touches %d %s, champs %d" % [claviers, touches.size(), touches, _champs_texte()])
	if tactile:
		var bulle := _bulle_fixe(Vector2(640, 420))
		var consts: Dictionary = (bulle.get_script() as GDScript).get_script_constant_map()
		_verifier("D bulle avec galet semi-opaque (rayon %.2f, alpha %.2f) + liseré %s" % [
				float(consts.get("RAYON_GALET", 0.0)), (consts.get("COULEUR_GALET", Color(0, 0, 0, 0)) as Color).a,
				str(consts.get("EPAISSEUR_LISERE", "absent"))],
			consts.has("RAYON_GALET") and (consts["COULEUR_GALET"] as Color).a > 0.5 and (consts["COULEUR_GALET"] as Color).a < 1.0)
		_verifier("D bulle : zone d'attrape intacte (rayon x 1,25)",
			bulle.contient(bulle.position + Vector2(bulle.rayon * 1.2, 0)) and not bulle.contient(bulle.position + Vector2(bulle.rayon * 1.3, 0)))
	await _demonter()


func _e_lettres_discriminant() -> void:
	print("--- E LETTRES (mode tactile ACTIF, discriminant) ---")
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	await _monter("res://scenes/lettres.tscn", true)
	var claviers := _a_script("res://scripts/clavier/clavier_virtuel.gd").size()
	var touches := _touches_lettres()
	_verifier("E lettres tactile : clavier dessine PRESENT (36 touches-caracteres)", claviers == 1 and touches.size() == 36,
		"claviers %d, touches %d" % [claviers, touches.size()])
	await _demonter()


func _derouler() -> void:
	print("=== PREUVE MOTS SANS CURSEUR + CHASSE SANS CLAVIER ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	await _f_mots_tactile()
	await _f_mots_desktop()
	await _e_chasse(true)
	await _e_chasse(false)
	await _e_lettres_discriminant()
	print("=== %s (%d echec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)

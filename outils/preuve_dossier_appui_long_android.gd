# Preuve de l'APPUI LONG au doigt DANS une fenetre-dossier (REQ_261007 android_dossier_prendre_icone).
# Monte le VRAI bureau (scenes/bureau.tscn) en MODE TACTILE (config isolee), ouvre le dossier
# « souris » au doigt et injecte des doigts par le vrai chemin du moteur (outils/doigt_moteur.gd :
# ScreenTouch/ScreenDrag → clic souris EMULE par Godot), chaque point vise etant celui de la POINTE :
#   D0 mode tactile : les jeux de la fenetre sont prenables, par appui long seulement ;
#   D1 doigt qui derive SANS appui long sur un jeu = il reste dans sa rangee (un tap reste un tap) ;
#   D2 appui long sur un jeu puis lache DANS la fenetre = souleve, suit le doigt, reprend sa place,
#      RIEN lance, toujours range ;
#   D3 appui long puis lache HORS de la fenetre = icone directe du bureau, posee la ou on l'a lache,
#      [bureau_rangement] puzzle = "" persiste, rien lance ;
#   D4 tap court sur un jeu de la fenetre = il se lance (scene changee).
# Lancement (user:// ISOLE — la sauvegarde de Fabrice n'est jamais touchee) :
#   XDG_DATA_HOME=$(mktemp -d) Godot_v4.7.2 --headless --path . --script res://outils/preuve_dossier_appui_long_android.gd
# Code de sortie 0 = tout vert, 1 = au moins un echec.
extends SceneTree

const PinConfig := preload("res://scripts/pin_config.gd")
const Doigt := preload("res://outils/doigt_moteur.gd")

var _echecs := 0
var _doigt_precedent := Vector2.ZERO


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


## Un geste de doigt comme sur Android ; `ou` = la cible de la POINTE (visee a la pointe).
func _doigt(type: String, ou: Vector2) -> void:
	var curseur: Node2D = current_scene.get("_curseur")
	var doigt := Doigt.doigt_pour_pointe(curseur, ou, root.get_visible_rect())
	if type == "glisse":
		Doigt.glisser(root, _doigt_precedent, doigt)
	else:
		Doigt.toucher(root, doigt, type == "pose")
	_doigt_precedent = doigt
	await _trames(2)


func _tap(ou: Vector2) -> void:
	await _doigt("pose", ou)
	await _doigt("leve", ou)


## Doigt pose et tenu immobile au-dela de la duree d'appui long (0,6 s).
func _appui_long(ou: Vector2) -> void:
	await _doigt("pose", ou)
	await create_timer(0.8).timeout
	await _trames(2)


func _monter_bureau() -> Control:
	var bureau: Control = load("res://scenes/bureau.tscn").instantiate()
	root.add_child(bureau)
	current_scene = bureau
	await _trames(6)
	return bureau


func _icone(bureau: Control, id: String) -> Control:
	for n in bureau.get_children():
		if n.has_signal("deplacee") and not n.is_queued_for_deletion() and n.id == id:
			return n
	return null


func _dans_fenetre(fenetre: Control, id: String) -> Control:
	for n in fenetre.contenu.get_children():
		if not n.is_queued_for_deletion() and n.has_signal("lancee") and n.id == id:
			return n
	return null


func _centre_bouton(icone: Control) -> Vector2:
	var btn: Control = icone.get("_btn")
	return btn.get_global_rect().get_center()


func _rangement(id: String) -> Variant:
	return PinConfig.lire_option("bureau_rangement", id, null)


## Un point du bureau libre : hors fenetre, hors icones, au-dessus de la barre.
func _point_libre(bureau: Control, fenetre: Control) -> Vector2:
	for p in [Vector2(bureau.size.x - 160, bureau.size.y - 260), Vector2(bureau.size.x - 160, 120),
			Vector2(160, bureau.size.y - 260)]:
		if not fenetre.get_global_rect().has_point(p):
			return p
	return Vector2(bureau.size.x - 160, 120)


func _derouler() -> void:
	print("=== PREUVE APPUI LONG DANS UNE FENETRE-DOSSIER (mode tactile) ===")
	print("  user:// = %s" % OS.get_user_data_dir())
	PinConfig.ecrire_option("interface", "mode_tactile", true)
	var bureau := await _monter_bureau()
	var dossier := _icone(bureau, "souris")
	_verifier("dossier « souris » sur le bureau", dossier != null)
	if dossier == null:
		_fin()
		return
	await _tap(_centre_bouton(dossier))
	await _trames(4)
	var fenetre: Control = bureau._fenetres_ouvertes.get("souris")
	_verifier("tap sur le dossier : fenetre ouverte", fenetre != null)
	var jeu := _dans_fenetre(fenetre, "puzzle") if fenetre else null
	_verifier("puzzle dans la fenetre « souris »", jeu != null)
	if jeu == null:
		_fin()
		return

	# D0 mode tactile : prenable, par appui long seulement
	_verifier("D0 jeu de fenetre prenable au doigt (rangeable + par_appui_long)",
		jeu.rangeable and jeu.par_appui_long)
	var lancements := []
	jeu.lancee.connect(func(id: String) -> void: lancements.append(id))

	# D1 doigt qui derive sans appui long : reste dans la rangee
	var p := _centre_bouton(jeu)
	await _doigt("pose", p)
	for i in range(1, 7):
		await _doigt("glisse", p + Vector2(15 * i, 6 * i))
	_verifier("D1 doigt qui derive (sans appui long) : jeu pas souleve",
		not jeu.top_level and jeu.scale == Vector2.ONE)
	await _doigt("leve", p + Vector2(90, 36))
	await _trames(2)
	_verifier("D1 : toujours dans la fenetre, rien ressorti",
		_dans_fenetre(fenetre, "puzzle") != null and _rangement("puzzle") == null)
	lancements.clear()

	# D2 appui long puis lache DANS la fenetre
	jeu = _dans_fenetre(fenetre, "puzzle")
	p = _centre_bouton(jeu)
	await _appui_long(p)
	_verifier("D2 appui long sur le jeu : il se souleve (echelle + opacite, hors rangee)",
		jeu.scale.x > 1.0 and jeu.modulate.a < 1.0 and jeu.top_level,
		"echelle %.2f, opacite %.2f, top_level %s" % [jeu.scale.x, jeu.modulate.a, jeu.top_level])
	var dedans := p + Vector2(30, 25)
	for i in range(1, 5):
		await _doigt("glisse", p.lerp(dedans, i / 4.0))
	_verifier("D2 en vol : il suit le doigt", _centre_bouton(jeu).distance_to(dedans) < 30.0,
		"centre %s, pointe %s" % [_centre_bouton(jeu), dedans])
	await _doigt("leve", dedans)
	await _trames(4)
	jeu = _dans_fenetre(fenetre, "puzzle")
	_verifier("D2 lache dans la fenetre : toujours dedans", jeu != null and _rangement("puzzle") == null,
		"rangement = %s" % _rangement("puzzle"))
	_verifier("D2 : reprend sa place (plus top_level, echelle 1, opaque)",
		jeu != null and not jeu.top_level and jeu.scale == Vector2.ONE and jeu.modulate.a == 1.0)
	_verifier("D2 : RIEN lance", lancements.is_empty() and current_scene == bureau, str(lancements))

	# D3 appui long puis lache HORS de la fenetre = ressorti
	p = _centre_bouton(jeu)
	var cible := _point_libre(bureau, fenetre)
	await _appui_long(p)
	_verifier("D3 appui long : souleve", jeu.scale.x > 1.0 and jeu.top_level)
	var suit := false
	for i in range(1, 9):
		await _doigt("glisse", p.lerp(cible, i / 8.0))
		if i == 6:
			suit = _centre_bouton(jeu).distance_to(p.lerp(cible, 0.75)) < 30.0
	_verifier("D3 en vol : il suit le doigt hors de la fenetre", suit)
	await _doigt("leve", cible)
	await _trames(4)
	_verifier("D3 ressorti : [bureau_rangement] puzzle = \"\"", _rangement("puzzle") == "",
		"rangement = %s" % _rangement("puzzle"))
	var direct := _icone(bureau, "puzzle")
	_verifier("D3 ressorti : icone directe sur le bureau", direct != null)
	_verifier("D3 ressorti : posee la ou on l'a lache",
		direct != null and _centre_bouton(direct).distance_to(cible) < 40.0,
		"centre %s, lache %s" % [_centre_bouton(direct) if direct else "?", cible])
	_verifier("D3 ressorti : plus dans la fenetre", _dans_fenetre(fenetre, "puzzle") == null)
	_verifier("D3 : rien lance", lancements.is_empty() and current_scene == bureau, str(lancements))
	var cfg := ConfigFile.new()
	_verifier("D3 : persiste dans user://config.cfg",
		cfg.load("user://config.cfg") == OK and cfg.get_value("bureau_rangement", "puzzle", null) == "")

	# D4 tap court sur un jeu de la fenetre = lancement (non-regression)
	var autre: Control = null
	for n in fenetre.contenu.get_children():
		if n.has_signal("lancee") and not n.is_queued_for_deletion():
			autre = n
			break
	if autre == null:
		_verifier("D4 un autre jeu reste dans la fenetre", false)
		_fin()
		return
	var id_autre: String = autre.id
	await _tap(_centre_bouton(autre))
	await _trames(6)
	_verifier("D4 tap court sur « %s » dans la fenetre : lance (scene changee)" % id_autre,
		current_scene != bureau and current_scene != null,
		"→ %s" % (current_scene.scene_file_path if current_scene else "?"))
	_fin()


func _fin() -> void:
	print("=== BILAN : %d echec(s) ===" % _echecs)
	quit(1 if _echecs > 0 else 0)

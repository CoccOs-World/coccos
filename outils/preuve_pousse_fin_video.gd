# Preuve P2 (02-11) — Pousse-Pollen : l'écran de fin = la vidéo « CoccOs World » de Ma télé, SANS TEXTE ; triangle
# rouge STOP + jauge jaune (puzzle) + pause/lecture (télé) ; pause ≠ STOP ; rejouer / maison seulement à la fin ou
# au STOP ; rejouer = dernier tableau joué ; maison = accueil ; rien ne se chevauche (3 formats × doigt/souris).
# (P4) rejouer + maison = MÊMES rectangles que Recommencer / Accueil en jeu (lus sur les nœuds du jeu) ; vidéo centrée
# en x entre la colonne de gauche et la colonne STOP + jauge (marges égales, chiffrées).
# Rendu réel (la vidéo n'avance et ne se peint qu'avec un vrai affichage) : SubViewport à la taille de l'écran
# visible, fenêtre 64×64 ; clics = vrais événements souris poussés dans le SubViewport (`push_input`).
# Captures (HORS projet, jamais dans l'APK) : <dossier>/preuve_fin_<format>_<mode>_<etape>.png
# Lancement (tour) :
#   XDG_DATA_HOME=$(mktemp -d) xvfb-run -a -s "-screen 0 1920x1080x24" Godot_v4.7.2 --rendering-driver vulkan --path . \
#       --windowed --resolution 64x64 --position 0,0 --script res://outils/preuve_pousse_fin_video.gd -- <dossier>
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const FORMATS := {"4-3": Vector2i(1024, 768), "16-9": Vector2i(1280, 720), "20-9": Vector2i(1600, 720)}
const ROUGE := Color(0.86, 0.16, 0.16)
const JAUNE := Color(0.98, 0.88, 0.25)

var _echecs := 0
var _dossier := "/tmp"


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		_dossier = args[0]
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _attendre(s: float) -> void:
	var fin := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < fin:
		await process_frame


func _capturer(sub: SubViewport) -> Image:
	await _trames(3)
	await RenderingServer.frame_post_draw
	return sub.get_texture().get_image()


func _proche(c: Color, ref: Color, tol: float = 0.08) -> bool:
	return absf(c.r - ref.r) <= tol and absf(c.g - ref.g) <= tol and absf(c.b - ref.b) <= tol


func _compter(img: Image, r: Rect2, ref: Color) -> int:
	var n := 0
	var z := Rect2i(r.position.floor(), r.size.floor()).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	for y in range(z.position.y, z.end.y):
		for x in range(z.position.x, z.end.x):
			if _proche(img.get_pixel(x, y), ref):
				n += 1
	return n


# Luminance moyenne + écart moyen entre deux images sur un rectangle (échantillonné tous les 4 px).
func _lum(img: Image, r: Rect2) -> float:
	var s := 0.0
	var n := 0
	for y in range(int(r.position.y), int(r.end.y), 4):
		for x in range(int(r.position.x), int(r.end.x), 4):
			s += img.get_pixel(x, y).get_luminance()
			n += 1
	return s / maxf(1.0, n)


func _ecart(a: Image, b: Image, r: Rect2) -> float:
	var s := 0.0
	var n := 0
	for y in range(int(r.position.y), int(r.end.y), 4):
		for x in range(int(r.position.x), int(r.end.x), 4):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			s += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	return s / maxf(1.0, n)


func _cliquer(sub: SubViewport, p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	sub.push_input(m, true)
	for appui in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = appui
		ev.position = p
		ev.global_position = p
		sub.push_input(ev, true)
		await _trames(2)


func _textes_visibles(n: Node) -> Array:
	var out := []
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return out
	if n is Label and (n as Label).text.strip_edges() != "":
		out.append("Label « %s »" % n.text)
	if n is Button and ((n as Button).text.strip_edges() != "" or (n as Button).tooltip_text != ""):
		out.append("Button %s « %s »/infobulle « %s »" % [n.name, n.text, n.tooltip_text])
	for c in n.get_children():
		out.append_array(_textes_visibles(c))
	return out


func _couches_jeu_visibles(jeu: Node) -> int:
	var n := 0
	for c in jeu._couches_jeu:
		if is_instance_valid(c) and c.visible:
			n += 1
	return n


# Monte le jeu, entre en jeu, charge le DERNIER tableau et déclenche la fin par le vrai chemin de victoire.
func _monter(sub: SubViewport) -> Node:
	var jeu: Node = load(SCENE).instantiate()
	sub.add_child(jeu)
	await _trames(6)
	jeu._quitter_accueil()
	var dernier: int = jeu.NIVEAUX.size() - 1
	jeu._aller_a_niveau(dernier)
	await _trames(3)
	jeu._a_gagne = true
	jeu._fin_victoire_niveau_suivant()
	await _trames(4)
	return jeu


func _cas(nom_f: String, tactile: bool, premier: bool) -> void:
	var reglages := ConfigFile.new()
	reglages.set_value("interface", "mode_tactile", tactile)
	reglages.save("user://config.cfg")
	var sub := SubViewport.new()
	sub.size = FORMATS[nom_f]
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.audio_listener_enable_2d = true
	root.add_child(sub)
	var mode := "doigt" if tactile else "souris"
	var et := "%s %s %s" % [nom_f, mode, sub.size]
	var base := "%s/preuve_fin_%s_%s" % [_dossier, nom_f, mode]
	var jeu: Node = await _monter(sub)
	var dernier: int = jeu.NIVEAUX.size() - 1
	print("--- %s (tactile=%s, dernier tableau = index %d) ---" % [et, str(not jeu._curseur_pc), dernier])
	_verifier("%s : écran de fin ouvert, vidéo en lecture (état « %s »)" % [et, jeu.fin_etat],
		is_instance_valid(jeu._couche_fin) and jeu.fin_etat == "joue" and jeu._fin_video.is_playing())
	var flux_ok: bool = jeu._fin_video.stream is VideoStreamTheora and jeu._fin_video.stream.file == "res://assets/tele/coccos_world.ogv"
	_verifier("%s : c'est la vidéo de Ma télé (%s)" % [et, jeu._fin_video.stream.file], flux_ok)
	var textes := _textes_visibles(jeu._couche_fin)
	_verifier("%s : AUCUN texte à lire sur l'écran de fin" % et, textes.is_empty(), str(textes))
	_verifier("%s : l'UI de jeu est retirée derrière la vidéo" % et, _couches_jeu_visibles(jeu) == 0)
	_verifier("%s : son de la vidéo non coupé (volume %.2f)" % [et, jeu._fin_video.volume], jeu._fin_video.volume > 0.99)
	# Géométrie : tout dans l'écran, aucun chevauchement entre TOUS les éléments (P4 : rejouer / maison ne sont plus sur la vidéo).
	var r: Dictionary = jeu.cadres_fin()
	var ecran := Rect2(Vector2.ZERO, Vector2(sub.size))
	var noms := ["video", "stop", "picto", "jauge", "pause", "rejouer", "maison"]
	var hors := []
	for k in noms:
		if not ecran.encloses(r[k]):
			hors.append(k)
	_verifier("%s : tout tient dans l'écran" % et, hors.is_empty(), str(hors))
	var chev := []
	for i in noms.size():
		for j in range(i + 1, noms.size()):
			if r[noms[i]].intersects(r[noms[j]]):
				chev.append(noms[i] + "×" + noms[j])
	_verifier("%s : aucun chevauchement (vidéo %s, STOP %s, jauge %s, pause %s, rejouer %s, maison %s)" % [et, r.video, r.stop, r.jauge, r.pause, r.rejouer, r.maison],
		chev.is_empty(), str(chev))
	# (P4) Place habituelle : rectangles RÉELS des nœuds de fin = rectangles RÉELS de Recommencer / Accueil en jeu.
	var g_rec: Rect2 = jeu._bouton_recommencer.get_global_rect()
	var g_acc: Rect2 = jeu._bouton_accueil.get_global_rect()
	var f_rej: Rect2 = jeu._fin_rejouer.get_global_rect()
	var f_mai: Rect2 = jeu._fin_maison.get_global_rect()
	_verifier("%s : P4 rejouer %s = Recommencer en jeu %s ; maison %s = Accueil en jeu %s" % [et, f_rej, g_rec, f_mai, g_acc],
		f_rej.position.is_equal_approx(g_rec.position) and f_rej.size.is_equal_approx(g_rec.size)
		and f_mai.position.is_equal_approx(g_acc.position) and f_mai.size.is_equal_approx(g_acc.size))
	# (P4) Place réservée dès le début : la vidéo commence à droite de la colonne de gauche.
	var bord_g: float = maxf(g_rec.end.x, g_acc.end.x)
	var bord_d: float = jeu._fin_stop.get_global_rect().position.x
	var mg: float = r.video.position.x - bord_g
	var md: float = bord_d - r.video.end.x
	print("  [mesure] %s : colonne gauche finit à x %.1f ; vidéo x %.1f → %.1f (%.0f×%.0f) ; colonne droite commence à x %.1f ; marges %.1f / %.1f" % [et, bord_g, r.video.position.x, r.video.end.x, r.video.size.x, r.video.size.y, bord_d, mg, md])
	_verifier("%s : P4 vidéo centrée entre les colonnes (marge gauche %.1f = marge droite %.1f, ≥ %.0f)" % [et, mg, md, jeu.FIN_MARGE],
		absf(mg - md) < 0.5 and mg >= jeu.FIN_MARGE - 0.01)
	var nat: Vector2 = Vector2(jeu._fin_video.get_video_texture().get_size()) if jeu._fin_video.get_video_texture() != null else Vector2(16, 9)
	_verifier("%s : P4 vidéo garde ses proportions (%.4f = flux %.4f)" % [et, r.video.size.x / r.video.size.y, nat.x / nat.y],
		absf(r.video.size.x / r.video.size.y - nat.x / nat.y) < 0.01)
	_verifier("%s : P4 pause centrée sous la vidéo (%.1f = %.1f)" % [et, r.pause.get_center().x, r.video.get_center().x],
		absf(r.pause.get_center().x - r.video.get_center().x) < 0.5)
	# Pixels pendant la lecture.
	await _attendre(1.5)
	var i1: Image = await _capturer(sub)
	await _attendre(1.0)
	var i2: Image = await _capturer(sub)
	i2.save_png(base + "_1_lecture.png")
	var lum_v := _lum(i2, r.video)
	var bouge := _ecart(i1, i2, r.video)
	_verifier("%s : la vidéo PEINT l'écran (luminance moyenne %.3f > 0,05)" % [et, lum_v], lum_v > 0.05)
	_verifier("%s : la vidéo AVANCE (écart d'image en 1 s : %.4f > 0,005 ; position %.2f s)" % [et, bouge, jeu._fin_video.stream_position], bouge > 0.005)
	var nr := _compter(i2, r.stop, ROUGE)
	var nj := _compter(i2, r.jauge, JAUNE)
	_verifier("%s : triangle ROUGE rendu dans le STOP (%d px)" % [et, nr], nr > 400)
	_verifier("%s : jauge JAUNE rendue (%d px)" % [et, nj], nj > 300)
	_verifier("%s : rejouer / maison absents pendant la lecture" % et, not jeu._fin_rejouer.visible and not jeu._fin_maison.visible)
	# Jauge : on baisse, la vidéo continue.
	jeu._fin_jauge.value = 25.0
	var p_avant: float = jeu._fin_video.stream_position
	await _attendre(1.0)
	_verifier("%s : jauge à 25 %% → volume vidéo %.2f, la vidéo continue (%.2f → %.2f s)" % [et, jeu._fin_video.volume, p_avant, jeu._fin_video.stream_position],
		absf(jeu._fin_video.volume - 0.25) < 0.01 and jeu._fin_video.stream_position > p_avant + 0.3 and jeu.fin_etat == "joue")
	# PAUSE (vrai clic) : pas de boutons de fin ; reprise.
	await _cliquer(sub, r.pause.get_center())
	var p1: float = jeu._fin_video.stream_position
	await _attendre(1.0)
	var ip: Image = await _capturer(sub)
	if premier:
		ip.save_png(base + "_2_pause.png")
	_verifier("%s : PAUSE → vidéo suspendue (%.2f → %.2f s), état « %s », AUCUN bouton de fin, STOP + jauge toujours là" % [et, p1, jeu._fin_video.stream_position, jeu.fin_etat],
		jeu._fin_video.paused and absf(jeu._fin_video.stream_position - p1) < 0.05 and jeu.fin_etat == "joue"
		and not jeu._fin_rejouer.visible and not jeu._fin_maison.visible and jeu._fin_stop.visible and jeu._fin_jauge.visible)
	await _cliquer(sub, r.pause.get_center())
	var p2: float = jeu._fin_video.stream_position
	await _attendre(1.0)
	_verifier("%s : LECTURE → la vidéo reprend (%.2f → %.2f s)" % [et, p2, jeu._fin_video.stream_position],
		not jeu._fin_video.paused and jeu._fin_video.stream_position > p2 + 0.3)
	# STOP (vrai clic).
	await _cliquer(sub, r.stop.get_center())
	var ps: float = jeu._fin_video.stream_position
	await _attendre(1.0)
	var istop: Image = await _capturer(sub)
	istop.save_png(base + "_3_stop.png")
	_verifier("%s : STOP → état « %s », vidéo arrêtée (%.2f → %.2f s), image figée gardée (lum %.3f)" % [et, jeu.fin_etat, ps, jeu._fin_video.stream_position, _lum(istop, r.video)],
		jeu.fin_etat == "stoppee" and absf(jeu._fin_video.stream_position - ps) < 0.05 and _lum(istop, r.video) > 0.05)
	_verifier("%s : STOP + jauge + pause disparus ENSEMBLE (rouge %d px, jaune %d px)" % [et, _compter(istop, r.stop, ROUGE), _compter(istop, r.jauge, JAUNE)],
		not jeu._fin_stop.visible and not jeu._fin_jauge.visible and not jeu._fin_picto.visible and not jeu._fin_pause.visible
		and _compter(istop, r.stop, ROUGE) == 0 and _compter(istop, r.jauge, JAUNE) == 0)
	_verifier("%s : rejouer + maison VISIBLES (pixels plaque claire %d / %d)" % [et, _compter(istop, r.rejouer, jeu.COL_SORTIE), _compter(istop, r.maison, jeu.COL_SORTIE)],
		jeu._fin_rejouer.visible and jeu._fin_maison.visible
		and _compter(istop, r.rejouer, jeu.COL_SORTIE) > 200 and _compter(istop, r.maison, jeu.COL_SORTIE) > 200)
	_verifier("%s : P4 après STOP, rejouer / maison aux rectangles de la colonne en jeu (%s / %s)" % [et, jeu._fin_rejouer.get_global_rect(), jeu._fin_maison.get_global_rect()],
		jeu._fin_rejouer.get_global_rect() == jeu._bouton_recommencer.get_global_rect() and jeu._fin_maison.get_global_rect() == jeu._bouton_accueil.get_global_rect())
	await _attendre(1.0)
	_verifier("%s : on reste sur l'écran jusqu'au choix (état « %s »)" % [et, jeu.fin_etat], jeu.fin_etat == "stoppee" and is_instance_valid(jeu._couche_fin))
	# REJOUER (vrai clic) → le dernier tableau joué, en jeu.
	var fin_rej: Rect2 = jeu._fin_rejouer.get_global_rect()
	var fin_mai: Rect2 = jeu._fin_maison.get_global_rect()
	await _cliquer(sub, jeu._fin_rejouer.get_global_rect().get_center())
	await _trames(4)
	_verifier("%s : P4 de retour EN JEU (tableau recadré), Recommencer %s / Accueil %s = rejouer / maison de la fin %s / %s" % [et, jeu._bouton_recommencer.get_global_rect(), jeu._bouton_accueil.get_global_rect(), fin_rej, fin_mai],
		jeu._bouton_recommencer.get_global_rect() == fin_rej and jeu._bouton_accueil.get_global_rect() == fin_mai)
	_verifier("%s : REJOUER → tableau index %d (= dernier joué %d), en jeu, écran de fin retiré, UI de jeu revenue" % [et, jeu._niveau_courant, dernier],
		jeu._niveau_courant == dernier and not is_instance_valid(jeu._couche_fin) and jeu.fin_etat == "" and not jeu._a_gagne
		and not jeu._en_accueil and _couches_jeu_visibles(jeu) == jeu._couches_jeu.size())
	var irj: Image = await _capturer(sub)
	if premier:
		irj.save_png(base + "_4_rejouer.png")
	# Fin NATURELLE → mêmes boutons ; puis MAISON (vrai clic) → accueil.
	jeu._a_gagne = true
	jeu._fin_victoire_niveau_suivant()
	await _trames(4)
	var lg: float = jeu._fin_video.get_stream_length()
	jeu._fin_video.stream_position = maxf(0.0, lg - 2.0)
	var t0 := Time.get_ticks_msec()
	while jeu.fin_etat == "joue" and Time.get_ticks_msec() - t0 < 8000:
		await process_frame
	var ifin: Image = await _capturer(sub)
	if premier:
		ifin.save_png(base + "_5_fin_naturelle.png")
	_verifier("%s : fin NATURELLE (saut à %.1f s sur %.1f) → état « %s », STOP + jauge + pause disparus, rejouer + maison visibles" % [et, maxf(0.0, lg - 2.0), lg, jeu.fin_etat],
		jeu.fin_etat == "finie" and not jeu._fin_stop.visible and not jeu._fin_jauge.visible and not jeu._fin_pause.visible
		and jeu._fin_rejouer.visible and jeu._fin_maison.visible)
	_verifier("%s : P4 après fin naturelle, rejouer / maison aux rectangles de la colonne en jeu (%s / %s)" % [et, jeu._fin_rejouer.get_global_rect(), jeu._fin_maison.get_global_rect()],
		jeu._fin_rejouer.get_global_rect() == jeu._bouton_recommencer.get_global_rect() and jeu._fin_maison.get_global_rect() == jeu._bouton_accueil.get_global_rect())
	await _cliquer(sub, jeu._fin_maison.get_global_rect().get_center())
	await _trames(4)
	var iac: Image = await _capturer(sub)
	if premier:
		iac.save_png(base + "_6_maison.png")
	_verifier("%s : MAISON → accueil affiché, écran de fin retiré, dernier tableau rechargé dessous (index %d)" % [et, jeu._niveau_courant],
		jeu._en_accueil and is_instance_valid(jeu._couche_accueil) and not is_instance_valid(jeu._couche_fin) and jeu._niveau_courant == dernier)
	# Échap pendant la vidéo = la maison.
	jeu._quitter_accueil()
	jeu._a_gagne = true
	jeu._fin_victoire_niveau_suivant()
	await _trames(3)
	jeu._retour_ou_quitter()
	await _trames(3)
	_verifier("%s : Échap / Retour Android pendant la vidéo → accueil (vidéo coupée)" % et,
		jeu._en_accueil and not is_instance_valid(jeu._couche_fin))
	sub.queue_free()
	await _trames(3)


func _derouler() -> void:
	print("=== PREUVE P2 FIN VIDÉO — POUSSE-POLLEN (SubViewport, fenêtre 64×64) ===")
	# Avant-dernier tableau : la victoire passe au suivant, PAS à l'écran de fin.
	var sub0 := SubViewport.new()
	sub0.size = Vector2i(1024, 768)
	root.add_child(sub0)
	var j0: Node = load(SCENE).instantiate()
	sub0.add_child(j0)
	await _trames(6)
	j0._quitter_accueil()
	var avant: int = j0.NIVEAUX.size() - 2
	j0._aller_a_niveau(avant)
	j0._a_gagne = true
	j0._fin_victoire_niveau_suivant()
	await _trames(3)
	_verifier("avant-dernier tableau gagné → tableau suivant (%d), pas d'écran de fin" % j0._niveau_courant,
		j0._niveau_courant == avant + 1 and not is_instance_valid(j0._couche_fin))
	sub0.queue_free()
	await _trames(3)
	var premier := true
	for nom_f in FORMATS:
		for tactile in [true, false]:
			await _cas(nom_f, tactile, premier or nom_f == "20-9")
			premier = false
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)

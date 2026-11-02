# Preuve P8 (02-11) — Pousse-Pollen : la jauge de l'écran de fin SE SOUVIENT tant qu'on reste dans Pousse-Pollen,
# revient au DÉFAUT 50 % dès qu'on en sort. Fabrice : « Il a baissé le son. […] Il décide de relancer le dernier
# tableau. Le niveau sonore aura été sauvegardé. Mais s'il sort de Pousse-Pollen, je veux que le niveau sonore soit
# réinitialisé par défaut et ce réglage par défaut serait à 50 % ».
# Parcours (le jeu est la scène COURANTE, comme lancé depuis le bureau → la vraie sortie `_quitter_coccos` marche) :
#   1re vidéo → 50 % ; jauge 25 % → STOP → rejouer → regagner → 25 % ; maison (accueil) → Jouer → regagner → 25 % ;
#   Échap pendant la vidéo (accueil) → Jouer → regagner → 25 % ; croix de l'accueil = retour au BUREAU (vrai
#   `_quitter_coccos`) → le bureau relance Pousse-Pollen (vrai `bureau.gd:_lancer_jeu("pousse")`) → fin → 50 %.
#   Phase « a » finit jauge à 25 % puis quitte ; phase « b » = appli ROUVERTE (nouveau processus, même user://) → 50 %.
#   Sauvegarde de Pousse-Pollen : md5 identique avant / après, aucune clé de volume ; unlock_all reste un fichier vide.
# Les boutons de fin sont actionnés par leur signal `pressed` (les vrais clics sur ces mêmes boutons sont prouvés par
# preuve_pousse_fin_video) ; la jauge par sa valeur (signal value_changed → `_volume_fin_change`, comme un glissé).
# Lancement (tour) : même XDG_DATA_HOME pour les deux phases —
#   XDG_DATA_HOME=<d> xvfb-run … Godot --rendering-driver vulkan --path . --windowed --resolution 64x64 \
#       --script res://outils/preuve_pousse_jauge_memoire.gd -- <dossier> a     (puis … -- <dossier> b)
extends SceneTree

const SCENE := "res://scenes/pousse_pollen.tscn"
const SAUVEGARDE := "user://pousse_pollen_progression.cfg"
const UNLOCK := "user://pousse_pollen_unlock_all"
const LancementS := preload("res://scripts/lancement.gd")

var _echecs := 0
var _phase := "a"


func _verifier(libelle: String, vrai: bool, detail: String = "") -> void:
	print("  %s %s%s" % ["ok   " if vrai else "ECHEC", libelle, (" — " + detail) if detail != "" else ""])
	if not vrai:
		_echecs += 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		_phase = args[1]
	_derouler.call_deferred()


func _trames(n: int) -> void:
	for i in n:
		await process_frame


func _jeu_courant() -> Node:
	return current_scene if is_instance_valid(current_scene) and current_scene.scene_file_path == SCENE else null


# Du jeu en cours (en jeu ou à l'accueil) jusqu'à l'écran de fin, par le vrai chemin de victoire du dernier tableau.
func _gagner_dernier(jeu: Node) -> void:
	if jeu._en_accueil:
		jeu._quitter_accueil()                          # = « Jouer »
		await _trames(3)
	var dernier: int = jeu.NIVEAUX.size() - 1
	if jeu._niveau_courant != dernier:
		jeu._aller_a_niveau(dernier)
		await _trames(3)
	jeu._a_gagne = true
	jeu._fin_victoire_niveau_suivant()
	await _trames(4)


func _relever(jeu: Node, et: String, attendu: float) -> void:
	var ok_fin: bool = is_instance_valid(jeu._couche_fin) and is_instance_valid(jeu._fin_video) and jeu.fin_etat == "joue"
	var vol: float = jeu._fin_video.volume if ok_fin else -1.0
	var jauge: float = jeu._fin_jauge.value if ok_fin else -1.0
	_verifier("%s → volume vidéo %.2f, jauge %.0f (attendu %.0f %%)" % [et, vol, jauge, attendu * 100.0],
		ok_fin and absf(vol - attendu) < 0.01 and absf(jauge - attendu * 100.0) < 0.5)


func _etat_sauvegarde() -> String:
	if not FileAccess.file_exists(SAUVEGARDE):
		return "absente"
	return FileAccess.get_md5(SAUVEGARDE)


func _derouler() -> void:
	print("=== PREUVE P8 JAUGE MÉMORISÉE — POUSSE-POLLEN (phase %s) ===" % _phase)
	print("  user:// = %s" % ProjectSettings.globalize_path("user://"))
	if _phase == "a":
		# Sauvegarde d'un enfant qui a tout débloqué + le fichier unlock_all des appareils de test.
		var cfg := ConfigFile.new()
		cfg.set_value("choix", "avatar", 1)
		cfg.set_value("progression", "niveau_max_atteint", 37)
		cfg.save(SAUVEGARDE)
		FileAccess.open(UNLOCK, FileAccess.WRITE).close()
	_verifier("lancement normal (pas de « --app »)", LancementS.app_directe() == "", LancementS.app_directe())
	# Entrée dans Pousse-Pollen comme depuis le bureau : la scène devient la scène courante.
	change_scene_to_file(SCENE)
	await _trames(8)
	var jeu := _jeu_courant()
	_verifier("Pousse-Pollen est la scène courante", jeu != null)
	if jeu == null:
		_finir()
		return
	await _gagner_dernier(jeu)
	var md5_avant := _etat_sauvegarde()                 # après l'entrée (le jeu a pu réécrire ses choix) : la jauge seule suit
	print("  sauvegarde avant jauge : md5 %s" % md5_avant)
	if _phase == "b":
		_relever(jeu, "phase b — appli ROUVERTE (nouveau processus, même user://), 1re vidéo", 0.5)
		_verifier("phase b — sauvegarde inchangée depuis la phase a, sans clé de volume (%s)" % md5_avant,
			md5_avant == _md5_phase_a() and not FileAccess.get_file_as_string(SAUVEGARDE).contains("volume"))
		_finir()
		return
	_relever(jeu, "1re vidéo", 0.5)
	jeu._fin_jauge.value = 25.0
	await _trames(2)
	_relever(jeu, "jauge réglée à 25 %", 0.25)
	jeu._fin_stop.pressed.emit()
	await _trames(3)
	_verifier("STOP → état « %s », rejouer / maison visibles" % jeu.fin_etat,
		jeu.fin_etat == "stoppee" and jeu._fin_rejouer.visible and jeu._fin_maison.visible)
	jeu._fin_rejouer.pressed.emit()
	await _trames(4)
	_verifier("REJOUER → en jeu au dernier tableau (index %d), écran de fin retiré" % jeu._niveau_courant,
		not jeu._en_accueil and not is_instance_valid(jeu._couche_fin) and jeu._niveau_courant == jeu.NIVEAUX.size() - 1)
	await _gagner_dernier(jeu)
	_relever(jeu, "dernier tableau regagné après rejouer", 0.25)
	# Fin naturelle puis revoir : la maison n'apparaît qu'après STOP / fin ; on prend la fin naturelle ici.
	jeu._fin_video.stream_position = maxf(0.0, jeu._fin_video.get_stream_length() - 1.5)
	var t0 := Time.get_ticks_msec()
	while jeu.fin_etat == "joue" and Time.get_ticks_msec() - t0 < 8000:
		await process_frame
	_verifier("fin naturelle de la vidéo → état « %s »" % jeu.fin_etat, jeu.fin_etat == "finie")
	jeu._fin_maison.pressed.emit()
	await _trames(4)
	_verifier("MAISON → accueil de Pousse-Pollen (encore dedans : même jeu)", jeu._en_accueil and _jeu_courant() == jeu)
	await _gagner_dernier(jeu)
	_relever(jeu, "accueil → Jouer → dernier tableau regagné", 0.25)
	jeu._retour_ou_quitter()                            # Échap / Retour Android pendant la vidéo = la maison
	await _trames(3)
	_verifier("Échap pendant la vidéo → accueil (même jeu)", jeu._en_accueil and _jeu_courant() == jeu)
	await _gagner_dernier(jeu)
	_relever(jeu, "Échap → accueil → Jouer → regagné", 0.25)
	var md5_reglage := _etat_sauvegarde()
	_verifier("sauvegarde NON écrite par la jauge (md5 %s = %s), aucune clé de volume" % [md5_reglage, md5_avant],
		md5_reglage == md5_avant and not FileAccess.get_file_as_string(SAUVEGARDE).contains("volume"))
	# SORTIE : maison → croix de l'accueil (vrai `_quitter_coccos`) → bureau.
	var chemin_bureau: String = jeu.CHEMIN_BUREAU
	jeu._retour_ou_quitter()                            # vidéo en cours → accueil ; puis la croix de l'accueil :
	await _trames(3)
	jeu._quitter_coccos()
	await _trames(10)
	var bureau: Node = current_scene
	_verifier("croix de l'accueil → BUREAU CoccOs (%s), Pousse-Pollen libéré" % (bureau.scene_file_path if is_instance_valid(bureau) else "?"),
		is_instance_valid(bureau) and bureau.scene_file_path == chemin_bureau and not is_instance_valid(jeu))
	if not (is_instance_valid(bureau) and bureau.has_method("_lancer_jeu")):
		_finir()
		return
	bureau._lancer_jeu("pousse")                        # le geste du bureau (fenêtre-catégorie → Pousse-Pollen)
	await _trames(10)
	var jeu2 := _jeu_courant()
	_verifier("le bureau relance Pousse-Pollen (nouveau jeu)", jeu2 != null)
	if jeu2 == null:
		_finir()
		return
	await _gagner_dernier(jeu2)
	_relever(jeu2, "retour dans Pousse-Pollen après le bureau", 0.5)
	# Pour la phase b : on laisse la jauge à 25 % puis l'appli se ferme.
	jeu2._fin_jauge.value = 25.0
	await _trames(2)
	_relever(jeu2, "jauge remise à 25 % avant fermeture de l'appli", 0.25)
	var md5_fin := _etat_sauvegarde()
	_verifier("sauvegarde inchangée de bout en bout (md5 %s = %s)" % [md5_fin, md5_avant], md5_fin == md5_avant)
	FileAccess.open("user://p8_md5_phase_a.txt", FileAccess.WRITE).store_string(md5_fin)
	_verifier("unlock_all toujours un fichier vide (%d o)" % FileAccess.get_file_as_bytes(UNLOCK).size(),
		FileAccess.file_exists(UNLOCK) and FileAccess.get_file_as_bytes(UNLOCK).size() == 0)
	_finir()


func _md5_phase_a() -> String:
	return FileAccess.get_file_as_string("user://p8_md5_phase_a.txt").strip_edges()


func _finir() -> void:
	print("=== %s (%d échec(s)) ===" % ["TOUT VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(1 if _echecs > 0 else 0)

# Preuve du JALON 1 — la voix femme siwis dit n'importe quel mot, à la volée.
#
# Ce que la preuve établit, sans prendre l'écran ni le son de Fabrice :
#   1. l'extension PiperTTS est chargée et le modèle résident ;
#   2. la latence MESURÉE par mot, modèle déjà chargé (temps réel ou non) ;
#   3. le cache user:// évite la seconde synthèse du même mot ;
#   4. la recette est respectée — 44100 Hz, mono, crête à -4 dB ;
#   5. la casse est normalisée comme dans generer_voix_bureau.py ;
#   6. Voix.dire() passe bien par Piper pour un mot HORS des clips embarqués ;
#   7. les mots qui ONT un clip embarqué sont resynthétisés côte à côte, pour
#      que outils/preuve_voix_identite.py compare timbre, niveau et débit.
#
# Le moteur signale « Playback can only happen when a node is inside the scene
# tree » au point ⑥ : dans _initialize() l'arbre ne tourne pas encore, la
# lecture ne peut pas démarrer. Ce que ⑥ vérifie, c'est que Voix.dire a bien
# CHARGÉ un flux Piper — ce message est attendu, pas un échec.
# Les wav de preuve sont écrits dans /tmp (jamais dans le dépôt).
#
# Lancement :
#   godot --headless --path . --script res://outils/preuve_voix_piper.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const VoixPiper = preload("res://scripts/voix_piper.gd")
const Voix = preload("res://scripts/voix.gd")

const MOTS_PREUVE := ["MAISON", "BONJOUR", "Fabrice", "ANTICONSTITUTIONNEL"]
# Mots qui ONT un clip embarqué : resynthétisés pour la comparaison côte à côte.
const MOTS_COMPARAISON := ["PAPA", "MAMAN", "AIDE", "ASSIS", "ATTACHER"]
const SORTIE := "/tmp/preuve_voix_piper"

var _echecs := 0


func _verifier(libelle: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("  VERT  %s%s" % [libelle, ("" if detail == "" else "  — " + detail)])
	else:
		_echecs += 1
		print("  ROUGE %s%s" % [libelle, ("" if detail == "" else "  — " + detail)])


## Crête du flux en dBFS — la mesure que ffmpeg volumedetect donne aux 395 clips.
func _crete_db(flux: AudioStreamWAV) -> float:
	var octets := flux.data
	var maxi := 0
	var i := 0
	while i + 1 < octets.size():
		var v := octets.decode_s16(i)
		maxi = maxi if absi(v) < maxi else absi(v)
		i += 2
	if maxi == 0:
		return -INF
	return 20.0 * (log(float(maxi) / 32767.0) / log(10.0))


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(SORTIE)
	print("=== PREUVE VOIX PIPER — jalon 1 (desktop Linux) ===")

	# ① Extension présente et modèle chargé
	var t0 := Time.get_ticks_usec()
	var pret := VoixPiper.disponible()
	var ms_chargement := (Time.get_ticks_usec() - t0) / 1000.0
	_verifier("① extension + modèle résidents", pret,
		VoixPiper.motif_indisponible() if not pret else "chargement %.0f ms" % ms_chargement)
	if not pret:
		print("ÉCHECS : %d" % _echecs)
		quit(1)
		return

	# ⑤ Casse normalisée — même règle que generer_voix_bureau.py
	var piper := Engine.get_singleton("PiperTTS")
	var cas := {"MAISON": "maison", "Fabrice": "Fabrice", "L": "L", "CoccOs": "CoccOs",
		"UN CHAT": "un chat", "ÉTÉ": "été"}
	for entree in cas:
		_verifier("⑤ casse « %s »" % entree, piper.texte_pour_tts(entree) == cas[entree],
			"obtenu « %s », attendu « %s »" % [piper.texte_pour_tts(entree), cas[entree]])

	# ② latence par mot, modèle résident + ④ recette respectée
	VoixPiper.vider_cache()
	var latences: Array[float] = []
	for mot in MOTS_PREUVE:
		var t := Time.get_ticks_usec()
		var flux: AudioStreamWAV = piper.synthese(mot)
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		if flux == null:
			_verifier("② synthèse « %s »" % mot, false, piper.derniere_erreur())
			continue
		latences.append(ms)
		var secondes := float(flux.data.size() / 2) / float(flux.mix_rate)
		_verifier("② « %s » synthétisé" % mot, ms < 1000.0,
			"%.0f ms pour %.2f s d'audio (facteur temps réel %.2f)" % [ms, secondes, (ms / 1000.0) / maxf(secondes, 0.001)])
		_verifier("④ « %s » : 44100 Hz mono 16 bits" % mot,
			flux.mix_rate == 44100 and not flux.stereo and flux.format == AudioStreamWAV.FORMAT_16_BITS,
			"%d Hz, %s, format %d" % [flux.mix_rate, "stéréo" if flux.stereo else "mono", flux.format])
		var crete := _crete_db(flux)
		_verifier("④ « %s » : crête -4 dB" % mot, absf(crete - (-4.0)) < 0.2,
			"mesuré %.2f dBFS" % crete)
		flux.save_to_wav("%s/%s.wav" % [SORTIE, mot])
	if latences.size() > 0:
		var somme := 0.0
		for l in latences:
			somme += l
		print("  → latence moyenne par mot, modèle résident : %.0f ms" % (somme / latences.size()))

	# ③ le cache évite la seconde synthèse
	VoixPiper.vider_cache()
	var t1 := Time.get_ticks_usec()
	var a := VoixPiper.flux("CHARIOT", "mots")
	var ms_froid := (Time.get_ticks_usec() - t1) / 1000.0
	var t2 := Time.get_ticks_usec()
	var b := VoixPiper.flux("CHARIOT", "mots")
	var ms_chaud := (Time.get_ticks_usec() - t2) / 1000.0
	_verifier("③ cache user:// actif", a != null and b != null and ms_chaud < ms_froid / 2.0,
		"1er appel %.0f ms, 2e appel %.0f ms" % [ms_froid, ms_chaud])

	# ⑥ Voix.dire passe par Piper pour un mot hors clips embarqués
	var hors_clips := "ANTICONSTITUTIONNEL"
	_verifier("⑥ « %s » absent des clips embarqués" % hors_clips,
		not ResourceLoader.exists("res://lang/fr/voix/mots/%s.wav" % hors_clips))
	var noeud := Node.new()
	root.add_child(noeud)
	Voix.dire(noeud, hors_clips, "mots")
	var lecteur: AudioStreamPlayer = noeud.get_node_or_null("_VoixLecteur")
	_verifier("⑥ Voix.dire a chargé un flux Piper", lecteur != null and lecteur.stream != null,
		"lecteur %s" % ("absent" if lecteur == null else "flux " + str(lecteur.stream)))
	if lecteur != null and lecteur.stream is AudioStreamWAV:
		_verifier("⑥ ce flux suit la recette", lecteur.stream.mix_rate == 44100,
			"%d Hz, crête %.2f dBFS" % [lecteur.stream.mix_rate, _crete_db(lecteur.stream)])
	noeud.queue_free()

	# ⑦ Paires clip / à la volée, pour la mesure de timbre et de débit
	for mot in MOTS_COMPARAISON:
		var jumeau: AudioStreamWAV = piper.synthese(mot)
		if jumeau == null:
			_verifier("⑦ paire « %s »" % mot, false, piper.derniere_erreur())
			continue
		jumeau.save_to_wav("%s/compare_%s.wav" % [SORTIE, mot])
	_verifier("⑦ paires clip / à la volée écrites", true,
		"%d mots — mesure : outils/preuve_voix_identite.py" % MOTS_COMPARAISON.size())

	print("=== ÉCHECS : %d — wav de preuve dans %s ===" % [_echecs, SORTIE])
	quit(1 if _echecs > 0 else 0)

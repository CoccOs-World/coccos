## Fait parler CoccOs — enregistrements d'abord, synthèse vocale sinon.
## Voix.dire(noeud, terme, categorie) cherche « <terme>.wav|ogg|mp3 » dans :
##   1) user://lang/<code>/voix/<categorie>/   (déposé par l'adulte, sans rebuild —
##      la voix de papa/maman peut remplacer la synthèse)
##   2) res://lang/<code>/voix/<categorie>/    (embarqué dans l'application)
##   3) synthèse Piper à la volée (voix siwis femme, scripts/voix_piper.gd) —
##      même timbre et même recette que les clips embarqués ;
##   4) à défaut seulement : synthèse vocale du système/navigateur.
## Catégories : chiffres, lettres, mots, phrases (spec-lang.md).
## Le lecteur audio est créé à la volée (enfant "_VoixLecteur" de la scène appelante).
## La voix de synthèse est résolue paresseusement : sur le web les voix du
## navigateur arrivent en asynchrone (liste vide au démarrage) — on réessaie à
## chaque prononciation tant qu'aucune n'est trouvée, puis on la garde.
##
## Watchdog (Linux) : après une mise en veille, le démon speech-dispatcher meurt
## et la connexion de Godot avec lui aussi — l'application devient muette jusqu'à
## sa relance (vécu au 2ᵉ test d'Isabella, 2026-07-10). Parade : les signaux
## d'énonciation (commencée/finie/annulée) prouvent que le démon vit ; SEUIL_SECOURS
## prononciations sans AUCUN signe de vie → bascule sur la commande externe
## `spd-say`, qui rouvre une connexion neuve à chaque appel. La voix revient
## toute seule, sans relancer CoccOs.
extends Object

const Lang = preload("res://scripts/lang.gd")
const PinConfig = preload("res://scripts/pin_config.gd")
const VoixPiper = preload("res://scripts/voix_piper.gd")
const NOM_LECTEUR := "_VoixLecteur"
const EXTENSIONS := ["wav", "ogg", "mp3"]
const SEUIL_SECOURS := 3

static var _voix_id := ""
static var _prochain_id := 0
static var _sans_reponse := 0      # prononciations restées sans signe de vie du démon
static var _mode_secours := false  # démon déclaré mort → spd-say externe
static var _secours_hs := false    # spd-say introuvable : ne plus essayer
static var _callbacks_poses := false


## Dit le terme : fichier enregistré si présent, synthèse vocale sinon.
static func dire(noeud: Node, terme: String, categorie: String) -> void:
	DisplayServer.tts_stop()
	var flux := _flux_enregistre(terme, categorie)
	if flux == null:
		# Hors du vocabulaire fixe : la MÊME voix femme, synthétisée à la volée.
		flux = VoixPiper.flux(terme, categorie)
	if flux != null:
		_jouer(noeud, flux)
		return
	_arreter_lecteur(noeud)
	var voix := _voix_tts()
	if voix == "":
		return
	if _secours_possible():
		if _mode_secours:
			_dire_secours(terme)
			return
		_poser_callbacks()
		_sans_reponse += 1
		if _sans_reponse >= SEUIL_SECOURS:
			_mode_secours = true
			_dire_secours(terme)
			return
	_prochain_id += 1
	DisplayServer.tts_speak(terme, voix, volume() / 2, 1.0, 1.0, _prochain_id)


## Amorce la résolution de la voix de synthèse (à appeler en _ready).
static func amorcer() -> void:
	VoixPiper.disponible()
	_voix_tts()


## Coupe toute parole en cours (synthèse ET enregistrement) — à la sortie d'un jeu.
static func arreter(noeud: Node) -> void:
	DisplayServer.tts_stop()
	if _mode_secours:
		OS.create_process("spd-say", ["-C"])
	_arreter_lecteur(noeud)


## Volume choisi par l'enfant (0-100, bouton haut-parleur de la barre des tâches).
static func volume() -> int:
	return clampi(int(PinConfig.lire_option("interface", "volume", 100)), 0, 100)


# --- Watchdog du démon de synthèse (Linux) ----------------------------------------

static func _secours_possible() -> bool:
	return OS.get_name() == "Linux" and not _secours_hs


## Un signal d'énonciation, quel qu'il soit, prouve que le démon répond.
static func _signe_de_vie(_id: int) -> void:
	_sans_reponse = 0


static func _poser_callbacks() -> void:
	if _callbacks_poses:
		return
	_callbacks_poses = true
	for evenement in [DisplayServer.TTS_UTTERANCE_STARTED,
			DisplayServer.TTS_UTTERANCE_ENDED, DisplayServer.TTS_UTTERANCE_CANCELED]:
		DisplayServer.tts_set_utterance_callback(evenement, _signe_de_vie)


## Parle par la commande externe spd-say — connexion neuve à chaque appel,
## insensible à la mort/résurrection du démon. spd-say -i : volume -100..100.
static func _dire_secours(terme: String) -> void:
	OS.create_process("spd-say", ["-C"])
	var pid := OS.create_process("spd-say",
		["-l", Lang.code(), "-i", str(volume() * 2 - 100), terme])
	if pid < 0:
		_secours_hs = true
		_mode_secours = false


# --- Recherche et lecture des enregistrements -----------------------------------

static func _flux_enregistre(terme: String, categorie: String) -> AudioStream:
	var code := Lang.code()
	# 1) Dépôt utilisateur (chargement direct depuis le disque)
	for ext in EXTENSIONS:
		var chemin := "user://lang/%s/voix/%s/%s.%s" % [code, categorie, terme, ext]
		if FileAccess.file_exists(chemin):
			match ext:
				"wav":
					return AudioStreamWAV.load_from_file(chemin)
				"ogg":
					return AudioStreamOggVorbis.load_from_file(chemin)
				"mp3":
					return AudioStreamMP3.load_from_file(chemin)
	# 2) Voix embarquées (ressources importées par l'éditeur)
	for ext in EXTENSIONS:
		var chemin := "res://lang/%s/voix/%s/%s.%s" % [code, categorie, terme, ext]
		if ResourceLoader.exists(chemin):
			return load(chemin)
	return null


static func _jouer(noeud: Node, flux: AudioStream) -> void:
	var lecteur: AudioStreamPlayer = noeud.get_node_or_null(NOM_LECTEUR)
	if lecteur == null:
		lecteur = AudioStreamPlayer.new()
		lecteur.name = NOM_LECTEUR
		noeud.add_child(lecteur)
	lecteur.stop()
	lecteur.stream = flux
	lecteur.play()


static func _arreter_lecteur(noeud: Node) -> void:
	var lecteur: AudioStreamPlayer = noeud.get_node_or_null(NOM_LECTEUR)
	if lecteur != null:
		lecteur.stop()


# --- Synthèse vocale (repli) ------------------------------------------------------

static func _voix_tts() -> String:
	if _voix_id != "":
		return _voix_id
	var langue := Lang.code()
	var voix := DisplayServer.tts_get_voices_for_language(langue)
	if voix.size() > 0:
		_voix_id = voix[0]
	else:
		var toutes := DisplayServer.tts_get_voices()
		if toutes.size() > 0:
			_voix_id = String(toutes[0].get("id", ""))
	return _voix_id

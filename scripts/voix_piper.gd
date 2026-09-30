## Synthèse Piper à la volée — la voix femme siwis dit N'IMPORTE QUEL mot.
##
## Les 395 clips pré-rendus (lang/fr/voix/) couvrent le vocabulaire FIXE du
## bureau. Pour tout le reste — un prénom, un mot du classeur de l'adulte, un
## mot tapé par l'enfant — on synthétisait jusqu'ici avec la voix du système,
## robotique et d'un timbre étranger au reste du bureau. Ici, c'est la MÊME voix
## qui parle, à la même recette : length_scale 1.3, 44100 Hz, crête -4 dB.
##
## Le modèle (61 Mo) et les bibliothèques Piper n'entrent pas dans le dépôt.
## Chemins cherchés, dans l'ordre :
##   1) variable d'environnement COCCOS_PIPER_MODELE ;
##   2) user://piper/fr_FR-siwis-medium.onnx  (dépôt de l'adulte, sans rebuild) ;
##   3) ~/.local/opt/piper/fr_FR-siwis-medium.onnx (poste de développement).
## L'annexe espeak-ng est cherchée à côté du modèle, sous « espeak-ng-data ».
##
## Un mot synthétisé est gardé en cache dans user://cache_voix/ : on ne paie la
## synthèse qu'une fois par mot, et le cache survit au redémarrage.
extends Object

const MODELE_DEFAUT := "fr_FR-siwis-medium.onnx"
const DOSSIER_ESPEAK := "espeak-ng-data"
const CACHE := "user://cache_voix"

enum Etat { INCONNU, PRET, INDISPONIBLE }

static var _etat := Etat.INCONNU
static var _motif := ""


## Vrai si la synthèse Piper est utilisable (charge le modèle au premier appel).
static func disponible() -> bool:
	if _etat == Etat.INCONNU:
		_amorcer()
	return _etat == Etat.PRET


## Pourquoi Piper est indisponible (chaîne vide s'il est prêt).
static func motif_indisponible() -> String:
	return _motif


## Le flux du terme : cache d'abord, synthèse sinon. null si Piper est absent.
static func flux(terme: String, categorie: String) -> AudioStream:
	if not disponible():
		return null
	var chemin := _chemin_cache(terme, categorie)
	if FileAccess.file_exists(chemin):
		var garde := AudioStreamWAV.load_from_file(chemin)
		if garde != null:
			return garde
	var flux_neuf: AudioStreamWAV = Engine.get_singleton("PiperTTS").synthese(terme)
	if flux_neuf == null:
		push_warning("Piper : %s" % Engine.get_singleton("PiperTTS").derniere_erreur())
		return null
	DirAccess.make_dir_recursive_absolute(chemin.get_base_dir())
	flux_neuf.save_to_wav(chemin)
	return flux_neuf


## Efface les mots mis en cache (l'adulte a changé de modèle ou de recette).
static func vider_cache() -> void:
	if DirAccess.dir_exists_absolute(CACHE):
		OS.move_to_trash(ProjectSettings.globalize_path(CACHE))


# --- Amorçage ---------------------------------------------------------------------

static func _amorcer() -> void:
	_etat = Etat.INDISPONIBLE
	if not Engine.has_singleton("PiperTTS"):
		_motif = "extension PiperTTS absente (bin/libpiper_tts…so non compilé)"
		return
	var modele := _trouver_modele()
	if modele == "":
		_motif = "modèle %s introuvable" % MODELE_DEFAUT
		return
	var espeak := modele.get_base_dir().path_join(DOSSIER_ESPEAK)
	if not DirAccess.dir_exists_absolute(espeak):
		_motif = "annexe espeak-ng introuvable : %s" % espeak
		return
	var piper := Engine.get_singleton("PiperTTS")
	if not piper.charger(modele, espeak):
		_motif = piper.derniere_erreur()
		return
	_etat = Etat.PRET
	_motif = ""


static func _trouver_modele() -> String:
	var pistes := []
	var par_env := OS.get_environment("COCCOS_PIPER_MODELE")
	if par_env != "":
		pistes.append(par_env)
	pistes.append(ProjectSettings.globalize_path("user://piper").path_join(MODELE_DEFAUT))
	pistes.append(OS.get_environment("HOME").path_join(".local/opt/piper").path_join(MODELE_DEFAUT))
	for piste in pistes:
		if FileAccess.file_exists(piste) and FileAccess.file_exists(piste + ".json"):
			return piste
	return ""


## Nom de fichier sûr : le terme lisible, plus une empreinte qui distingue deux
## termes que l'assainissement rendrait identiques (« a/b » et « a_b »).
static func _chemin_cache(terme: String, categorie: String) -> String:
	var lisible := terme.validate_filename().substr(0, 32)
	var empreinte := terme.sha256_text().substr(0, 8)
	return "%s/%s/%s_%s.wav" % [CACHE, categorie, lisible, empreinte]

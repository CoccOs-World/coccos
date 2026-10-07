# Preuve — table EXCEPTIONS_TTS : les mots que siwis écorche reçoivent une
# graphie corrigée AVANT la synthèse Piper, et rien d'autre ne bouge.
#
# Ce que la preuve établit, sans prendre l'écran ni le son de Fabrice :
#   1. le chemin du CLASSEUR : chaque libellé des planches embarquées est dit
#      par un clip phrases/ ou par Piper live (Voix._flux_enregistre) ;
#   2. la table s'applique quelle que soit la casse (papa, PAPA, Papa) ;
#   3. les mots témoins (papier, tu, couteau, MAISON, lettres) passent INCHANGÉS ;
#   4. la clé de cache d'un mot corrigé change (l'ancien rendu écorché déjà en
#      cache est ignoré), celle des autres mots reste la même ;
#   5. outils/generer_voix_bureau.py lit la table ici (source unique) ;
#   6. option PREUVE_TIRAGES=N : N tirages Piper LIVE par mot, « avant » (texte
#      brut) et « après » (VoixPiper.flux, cache vidé à chaque tirage), écrits
#      dans /tmp/preuve_voix_exceptions/ pour les juges ASR du banc.
#
# Lancement (user:// isolé conseillé : XDG_DATA_HOME=/tmp/…) :
#   godot --headless --path . --script res://outils/preuve_voix_exceptions.gd
# Code de sortie 0 = tout vert, 1 = au moins un échec.
extends SceneTree

const VoixPiper = preload("res://scripts/voix_piper.gd")
const Voix = preload("res://scripts/voix.gd")
const PlancheTlab = preload("res://scripts/classeur/planche_tlab.gd")

const ATTENDUS := {
	"papa": "Papa !", "PAPA": "Papa !", "Papa": "Papa !",
	"aide": "Aide.", "AIDE": "Aide.", "pinceau": "Pin-ceau !", "PINCEAU": "Pin-ceau !",
}
const TEMOINS := ["papier", "PAPIER", "tu", "TU", "couteau", "COUTEAU", "MAISON", "Fabrice"]
const MOTS_TIRAGES := ["papa", "aide", "pinceau", "tu", "couteau", "papier"]
const SORTIE := "/tmp/preuve_voix_exceptions"

var _echecs := 0


func _verifier(libelle: String, ok: bool, detail: String = "") -> void:
	if ok:
		print("  VERT  %s%s" % [libelle, ("" if detail == "" else "  — " + detail)])
	else:
		_echecs += 1
		print("  ROUGE %s%s" % [libelle, ("" if detail == "" else "  — " + detail)])


## La clé de cache d'AVANT la table (terme seul) — pour prouver qu'elle change.
func _cle_ancienne(terme: String, categorie: String) -> String:
	return "%s/%s/%s_%s.wav" % [VoixPiper.CACHE, categorie,
		terme.validate_filename().substr(0, 32), terme.sha256_text().substr(0, 8)]


func _initialize() -> void:
	print("=== PREUVE VOIX — table EXCEPTIONS_TTS ===")

	print("① chemin du classeur (planches embarquées, catégorie « phrases »)")
	var vus := {}
	for nom in PlancheTlab.lister_planches():
		var planche := PlancheTlab.charger(PlancheTlab.lister_planches()[nom])
		for cellule in planche.get("cellules", []):
			var lib: String = cellule["libelle"]
			if lib == "" or lib.begins_with("Pictos") or lib.begins_with("Tableau"):
				continue
			vus[lib] = Voix._flux_enregistre(lib, "phrases") != null
	for mot in ["tu", "aide", "couteau", "pinceau", "papier", "papa"]:
		var chemin := "clip res://lang/fr/voix/phrases/%s.wav" % mot if vus.get(mot, false) \
			else ("Piper LIVE" if vus.has(mot) else "absent des planches embarquées → s'il est ajouté : Piper LIVE")
		print("  « %s » : %s" % [mot, chemin])
	_verifier("papa absent des planches et sans clip phrases/ → Piper live",
		not vus.has("papa") and Voix._flux_enregistre("papa", "phrases") == null)
	_verifier("tu/aide/couteau/pinceau/papier des planches → clip phrases/",
		vus.get("tu", false) and vus.get("aide", false) and vus.get("couteau", false)
		and vus.get("pinceau", false) and vus.get("papier", false))

	print("② table appliquée, toutes casses")
	for terme in ATTENDUS:
		var t := VoixPiper.texte_pour_tts(terme)
		_verifier("« %s » → « %s »" % [terme, t], t == ATTENDUS[terme])

	print("③ témoins inchangés")
	for terme in TEMOINS:
		var t := VoixPiper.texte_pour_tts(terme)
		_verifier("« %s » → « %s »" % [terme, t], t == terme)
	for lettre in ["P", "T", "A", "M"]:
		_verifier("lettre %s → « %s »" % [lettre, VoixPiper.texte_pour_tts(lettre)],
			VoixPiper.texte_pour_tts(lettre) == VoixPiper.NOMS_LETTRES[lettre])

	print("④ clé de cache")
	for terme in ["papa", "PAPA", "aide", "pinceau"]:
		_verifier("« %s » : clé neuve (le rendu écorché en cache est ignoré)" % terme,
			VoixPiper._chemin_cache(terme, "phrases") != _cle_ancienne(terme, "phrases"))
	for terme in ["papier", "tu", "couteau", "MAISON"]:
		_verifier("« %s » : clé inchangée (cache existant conservé)" % terme,
			VoixPiper._chemin_cache(terme, "phrases") == _cle_ancienne(terme, "phrases"))

	print("⑤ source unique")
	var gen := FileAccess.get_file_as_string("res://outils/generer_voix_bureau.py")
	_verifier("generer_voix_bureau.py lit EXCEPTIONS_TTS dans voix_piper.gd",
		gen.contains("const EXCEPTIONS_TTS := ") and gen.contains("\"scripts\", \"voix_piper.gd\"")
		and not gen.contains("\"Pin-ceau !\""))

	var n := int(OS.get_environment("PREUVE_TIRAGES"))
	if n > 0:
		print("⑥ %d tirages Piper LIVE par mot → %s" % [n, SORTIE])
		_verifier("Piper disponible", VoixPiper.disponible(), VoixPiper.motif_indisponible())
		if VoixPiper.disponible():
			DirAccess.make_dir_recursive_absolute(SORTIE)
			var piper := Engine.get_singleton("PiperTTS")
			for mot in MOTS_TIRAGES:
				for i in n:
					var avant: AudioStreamWAV = piper.synthese(mot)
					avant.save_to_wav("%s/%s__avant__%02d.wav" % [SORTIE, mot, i])
					var cache := ProjectSettings.globalize_path(VoixPiper._chemin_cache(mot, "phrases"))
					if FileAccess.file_exists(cache):
						DirAccess.remove_absolute(cache)
					var apres: AudioStreamWAV = VoixPiper.flux(mot, "phrases")
					apres.save_to_wav("%s/%s__apres__%02d.wav" % [SORTIE, mot, i])
			_verifier("%d fichiers écrits" % (MOTS_TIRAGES.size() * n * 2),
				DirAccess.get_files_at(SORTIE).size() >= MOTS_TIRAGES.size() * n * 2)

	print("=== %s — %d échec(s) ===" % ["VERT" if _echecs == 0 else "ROUGE", _echecs])
	quit(0 if _echecs == 0 else 1)

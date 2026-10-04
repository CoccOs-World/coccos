# Preuve ponctuelle — la table des noms de lettres est bien posée sur la
# synthèse À LA VOLÉE (scripts/voix_piper.gd), et le terme BRUT reste la clé
# du cache et le nom des clips pré-rendus.
extends SceneTree

const VoixPiper = preload("res://scripts/voix_piper.gd")
const Voix = preload("res://scripts/voix.gd")

var _echecs := 0

func _v(libelle: String, ok: bool, detail := "") -> void:
	if not ok:
		_echecs += 1
	print("  %s %s%s" % ["VERT " if ok else "ROUGE", libelle,
		("" if detail == "" else "  — " + detail)])

func _initialize() -> void:
	print("=== PREUVE TABLE DES NOMS DE LETTRES (synthèse à la volée) ===")
	var attendu := {"A": "a", "E": "euh", "M": "èmme", "O": "eau", "U": "ue",
		"Y": "ie grec", "Z": "zède"}
	for lettre in attendu:
		_v("① « %s » → nom écrit" % lettre,
			VoixPiper.texte_pour_tts(lettre) == attendu[lettre],
			"obtenu « %s », attendu « %s »" % [VoixPiper.texte_pour_tts(lettre), attendu[lettre]])
	# minuscule aussi : la table est interrogée en MAJUSCULE
	_v("② minuscule « e » → « euh »", VoixPiper.texte_pour_tts("e") == "euh",
		"obtenu « %s »" % VoixPiper.texte_pour_tts("e"))
	# ce qui ne doit PAS bouger
	for intact in ["7", "CHAT", "Fabrice", "É", "Ç", "ie grec"]:
		_v("③ « %s » inchangé" % intact, VoixPiper.texte_pour_tts(intact) == intact,
			"obtenu « %s »" % VoixPiper.texte_pour_tts(intact))
	# le clip pré-rendu reste prioritaire et porte le nom BRUT
	_v("④ clip embarqué « E.wav » toujours trouvé",
		ResourceLoader.exists("res://lang/fr/voix/lettres/E.wav"))
	# la synthèse à la volée produit bien un son pour une lettre
	if VoixPiper.disponible():
		VoixPiper.vider_cache()
		var f: AudioStreamWAV = VoixPiper.flux("U", "lettres")
		_v("⑤ synthèse à la volée de « U »", f != null and f.data.size() > 0,
			"" if f == null else "%d octets, %d Hz" % [f.data.size(), f.mix_rate])
	else:
		_v("⑤ synthèse à la volée", false, "Piper indisponible : "
			+ VoixPiper.motif_indisponible())
	print("=== ÉCHECS : %d ===" % _echecs)
	quit(1 if _echecs > 0 else 0)

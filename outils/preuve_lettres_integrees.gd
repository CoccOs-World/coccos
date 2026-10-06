# Preuve ponctuelle #191 — les 26 lettres validées (lang/fr/voix/lettres/A…Z.wav)
# sont bien celles que le jeu joue, EN PRIORITÉ sur la synthèse à la volée :
# on passe par le vrai chemin de Voix.dire() (_flux_enregistre) et on compare
# la durée du flux importé à celle du fichier sur disque (l'import compresse
# en QOA : les octets diffèrent par construction, la durée non).
extends SceneTree

const Voix = preload("res://scripts/voix.gd")

var _echecs := 0

func _v(libelle: String, ok: bool, detail := "") -> void:
	if not ok:
		_echecs += 1
	print("  %s %s%s" % ["VERT " if ok else "ROUGE", libelle,
		("" if detail == "" else "  — " + detail)])

func _initialize() -> void:
	print("=== PREUVE 26 LETTRES INTÉGRÉES (priorité sur la synthèse) ===")
	for i in 26:
		var lettre := String.chr(65 + i)
		var chemin := "res://lang/fr/voix/lettres/%s.wav" % lettre
		var flux = Voix._flux_enregistre(lettre, "lettres")
		var disque := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(chemin))
		var ok: bool = flux is AudioStreamWAV and flux.resource_path == chemin \
			and disque != null and absf(flux.get_length() - disque.get_length()) < 0.002 \
			and flux.mix_rate == 44100 and not flux.stereo
		_v("« %s » → %s" % [lettre, chemin], ok, "" if flux == null else "%.3f s (disque %.3f s), %d Hz, %s" % [
			flux.get_length(), disque.get_length(), flux.mix_rate, "stéréo" if flux.stereo else "mono"])
	print("=== ÉCHECS : %d ===" % _echecs)
	quit(1 if _echecs > 0 else 0)

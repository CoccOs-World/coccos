# (#192, 06-10-2026) COPIE à l'octet près de `~/dev/coccos/scripts/effets/sons.gd` (bureau CoccOs), elle-même
#   identique à `scripts/souris/sons.gd` (la découverte de la souris, #97). Sons SYNTHÉTISÉS par code : aucun
#   fichier audio à copier ni à déclarer dans `export_files`. Seul cet en-tête est ajouté.
## Générateur de sons synthétisés par code — aucun asset audio nécessaire.
## Chaque fonction renvoie un AudioStreamWAV prêt à jouer :
## timbre doux (sinus + un peu d'harmonique), attaque courte, extinction douce.
extends RefCounted

const TAUX_ECHANTILLONNAGE := 22050


## Clic gauche : « pop » joyeux montant.
static func pop_joyeux() -> AudioStreamWAV:
	return _glissando(500.0, 950.0, 0.18, 0.45)


## Clic droit : carillon à deux notes (sol → do).
static func carillon() -> AudioStreamWAV:
	return _suite_de_notes([[784.0, 0.14], [1046.5, 0.22]], 0.4)


## Clic molette : « boum » doux descendant (feu d'artifice).
static func boum_doux() -> AudioStreamWAV:
	return _glissando(700.0, 240.0, 0.35, 0.5)


## Molette qui tourne : petit tic discret.
static func tic() -> AudioStreamWAV:
	return _glissando(1500.0, 1200.0, 0.05, 0.3)


## Note glissée de freq_debut à freq_fin, avec enveloppe attaque/extinction.
static func _glissando(freq_debut: float, freq_fin: float, duree: float, volume: float) -> AudioStreamWAV:
	var nb_echantillons := int(duree * TAUX_ECHANTILLONNAGE)
	var donnees := PackedByteArray()
	donnees.resize(nb_echantillons * 2)
	var phase := 0.0
	for i in nb_echantillons:
		var t := float(i) / float(nb_echantillons)
		var frequence := lerpf(freq_debut, freq_fin, t)
		phase += TAU * frequence / TAUX_ECHANTILLONNAGE
		var enveloppe := minf(t / 0.03, 1.0) * pow(1.0 - t, 2.0)
		var echantillon := (sin(phase) + 0.35 * sin(phase * 2.0)) * enveloppe * volume
		donnees.encode_s16(i * 2, int(clampf(echantillon, -1.0, 1.0) * 32767.0))
	return _vers_flux(donnees)


## Suite de notes [fréquence, durée] jouées bout à bout, chacune avec son enveloppe.
static func _suite_de_notes(notes: Array, volume: float) -> AudioStreamWAV:
	var donnees := PackedByteArray()
	for note in notes:
		var frequence: float = note[0]
		var duree: float = note[1]
		var nb_echantillons := int(duree * TAUX_ECHANTILLONNAGE)
		var debut := donnees.size()
		donnees.resize(debut + nb_echantillons * 2)
		var phase := 0.0
		for i in nb_echantillons:
			var t := float(i) / float(nb_echantillons)
			phase += TAU * frequence / TAUX_ECHANTILLONNAGE
			var enveloppe := minf(t / 0.03, 1.0) * pow(1.0 - t, 2.0)
			var echantillon := (sin(phase) + 0.35 * sin(phase * 2.0)) * enveloppe * volume
			donnees.encode_s16(debut + i * 2, int(clampf(echantillon, -1.0, 1.0) * 32767.0))
	return _vers_flux(donnees)


static func _vers_flux(donnees: PackedByteArray) -> AudioStreamWAV:
	var flux := AudioStreamWAV.new()
	flux.format = AudioStreamWAV.FORMAT_16_BITS
	flux.mix_rate = TAUX_ECHANTILLONNAGE
	flux.stereo = false
	flux.data = donnees
	return flux

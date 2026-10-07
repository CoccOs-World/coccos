## Helper centralisé pour la configuration persistante (user://config.cfg) :
## code PIN adulte + options générales (lire_option / ecrire_option).
## Utilisé par pin_gate.gd, change_pin.gd, adult_settings.gd, bureau.gd.
## NE PAS ajouter de class_name (non résolu au run direct sans cache de classes).
extends RefCounted

## Chemin du fichier de configuration persistant.
const CHEMIN := "user://config.cfg"
## Valeur par défaut du PIN adulte.
const PIN_DEFAUT := "1234"


## Lit le PIN depuis la configuration.
## Si absent, écrit la valeur par défaut et la retourne.
static func lire_pin() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load(CHEMIN)
	if err == OK and cfg.has_section_key("adulte", "pin"):
		return cfg.get_value("adulte", "pin")
	# Valeur absente → initialiser avec le défaut
	cfg.set_value("adulte", "pin", PIN_DEFAUT)
	cfg.save(CHEMIN)
	return PIN_DEFAUT


## Écrit un nouveau PIN dans la configuration.
static func ecrire_pin(nouveau: String) -> void:
	var cfg := ConfigFile.new()
	# Charge le fichier existant s'il existe (pour préserver les autres clés)
	cfg.load(CHEMIN)
	cfg.set_value("adulte", "pin", nouveau)
	cfg.save(CHEMIN)


## Lit une option générale ; retourne `defaut` si elle n'a jamais été écrite.
static func lire_option(section: String, cle: String, defaut: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN) == OK and cfg.has_section_key(section, cle):
		return cfg.get_value(section, cle)
	return defaut


## Écrit une option générale (en préservant les autres clés du fichier).
static func ecrire_option(section: String, cle: String, valeur: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CHEMIN)
	cfg.set_value(section, cle, valeur)
	cfg.save(CHEMIN)


## Efface une option (retour au comportement par défaut du programme).
static func effacer_option(section: String, cle: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN) != OK:
		return
	if cfg.has_section_key(section, cle):
		cfg.erase_section_key(section, cle)
		cfg.save(CHEMIN)


## Efface toute une section (retour aux défauts du programme pour chacune de ses clés).
static func effacer_section(section: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN) != OK:
		return
	if cfg.has_section(section):
		cfg.erase_section(section)
		cfg.save(CHEMIN)

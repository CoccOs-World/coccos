extends RefCounted
class_name SonPuzzle

# ============================================================================================================
# LE SON DE CE JEU — UN BUS À NOUS, LA MUSIQUE DE MARCHE DE L'ACCUEIL, ET UN VOLUME QUI SURVIT
# (PUZZLE-ACCUEIL-PHASE1, GDD_puzzles §20.1 — la SIGNATURE CoccOs)
#
# ⚠⚠ CE QUE FABRICE A DICTÉ, MOT POUR MOT, ET QUI COMMANDE CE FICHIER (GDD du puzzle adulte §16.1, la même
#   phrase gouverne les deux jeux) :
#   « le fond de verdure, la croix rouge qui est grosse pour quitter, la barre assez large de volume pour régler
#     le son, la petite musique de marche qu'on utilise : ça c'est la signature de CoccOs, et ça doit être présent
#     dans n'importe quelle interface d'accueil. »
#
# ============================================================================================================
# POURQUOI CE FICHIER EXISTE, ET NON TROIS LIGNES DANS `accueil.gd`
# ============================================================================================================
# Trois choses qui n'ont l'air que d'une : le BUS (où le son passe), la MUSIQUE (ce qui joue), le VOLUME (ce que
# Fabrice règle et qui doit se retrouver au lancement suivant). Elles se tiennent l'une l'autre — un volume posé
# sur un bus qui n'existe pas ne règle rien, une musique qui ne passe pas par le bus échappe au réglage — et elles
# sont lues par DEUX écrans (l'accueil règle, le puzzle subit le réglage). Un seul endroit les décide, donc un seul
# endroit peut se tromper. C'est la raison qui a déjà fait `curseurs_puzzle.gd` : un réglage porté par deux scènes
# vit dans un fichier, pas en double.
# ⚠ IL EST À LA BONNE ADRESSE (CLAUDE.md règle 10 · STRUCTURE « un nom par rôle ») : `scripts/son_puzzle.gd` nomme
#   le rôle. Poser un volume dans `curseurs_puzzle.gd` aurait mis le son dans le fichier des pointeurs.
# ⚠ ET C'EST UNE **REPRISE**, PAS UNE INVENTION : le fichier du même nom existe au jeu du puzzle adulte (sa
#   phase 1, 19-08) et vient lui-même du 7 différences (sa B17). Seul le NOM DU BUS change — cf. juste dessous.
#
# ============================================================================================================
# ⚠⚠ POURQUOI UN BUS À NOUS ET NON LE MASTER — la leçon du 7 différences (sa B17), reprise telle quelle
# ============================================================================================================
# Le réflexe serait `AudioServer.set_bus_volume_db(0, …)`, c'est-à-dire le MASTER. Il est faux ici pour une raison
# de fratrie : ce jeu est copiable seul sur une clé, mais il peut aussi tourner à côté d'un frère dans une même
# session. Baisser le Master baisserait TOUT ce qui sonne sur la machine, pas ce jeu-ci. Les lecteurs de CE jeu —
# et eux seuls — sont donc routés vers `BUS`, lui-même envoyé dans Master.
# ⚠ LE NOM DU BUS EST **CELUI DE CE JEU** (`JeuPuzzles`, quand l'adulte a `JeuPuzzleAdulte`) : les deux jeux
#   peuvent tourner dans la même session, et deux bus de même nom se marcheraient dessus.
# ⚠ SI LE BUS N'A PAS PU ÊTRE CRÉÉ, `index_bus()` RESTE À −1 ET LE RÉGLAGE NE PRÉTEND PAS AGIR : les lecteurs
#   restent sur Master, le journal le dit, et `etat_accueil()` le publie. On ne fait jamais semblant.
#
# ============================================================================================================
# ⚠ POURQUOI LE VOLUME VIT DANS `reglages_puzzle.cfg` ET NON DANS LE SIGNET (`progression_puzzle.cfg`)
# ============================================================================================================
# `progression_puzzle.gd` le dit lui-même : le harnais remet CELUI-CI à zéro à chaque passage pour mesurer au
# premier lancement. Un volume rangé là serait effacé à chaque preuve. `reglages_puzzle.cfg` est le fichier des
# réglages de CONFORT (le choix du curseur y est déjà, et son en-tête annonce « ce fichier accueillera d'autres
# réglages plus tard ») : c'est exactement ce qu'est un volume. Deux fichiers, deux durées de vie — c'est voulu.
#
# ⚠ 0 % COUPE LE BUS AU LIEU DE LUI POSER UN −INF : `linear_to_db(0.0)` vaut −infini, et une valeur infinie posée
#   sur un bus est un piège (elle ne se relit pas, elle ne se compare pas). Sous `VOLUME_MUET` on MUTE, franchement.
# ============================================================================================================

const BUS := "JeuPuzzles"

# LA MUSIQUE DE MARCHE — **COPIÉE** dans `audio/` de ce jeu, jamais empruntée au dossier du 7 différences
# (principe de Fabrice, 14-08 : « on copie les contenus, on ne bifurque pas sur les autres jeux »). Le contrôle ⓪
# du harnais relit chemin par chemin qu'aucun `res://` ne sort de ce projet, et compare le md5 à l'original.
# ⚠ C'EST LA VERSION **_boucle** ET C'EST CELLE QUI EST DEMANDÉE : le fondu de fin y est déjà fait (7-diff B18),
#   donc la boucle ne « claque » pas au raccord. La version non fondue, bouclée, s'entend à chaque tour.
const MUSIQUE_ACCUEIL := "res://jeux_integres/puzzle/audio/marche_cote_coccos_boucle.mp3"

# −10 dB : un FOND, pas une écoute. Le chiffre est celui du 7 différences (`ACCUEIL_MUSIQUE_DB`), et on le reprend
# au lieu d'en choisir un autre — même musique, même rôle, même écran d'accueil (« on reproduit l'acquis »).
const MUSIQUE_DB := -10.0

const VOLUME_DEFAUT := 1.0              # 100 % : sans geste de Fabrice, le jeu sonne comme avant cette balle
const VOLUME_MUET := 0.005              # sous ce seuil, on COUPE le bus (cf. l'encadré)

const REGLAGE := "user://reglages_puzzle.cfg"     # le fichier du curseur — cf. l'encadré
const SECTION := "jeu"
const CLE_VOLUME := "volume"


# ------------------------------------------------------------------------------------------------------------
# LE BUS
# ------------------------------------------------------------------------------------------------------------
# S'il existe déjà, on le REPREND : l'accueil peut se rouvrir (retour depuis le puzzle par la maison), et on
# n'empile pas un bus par visite. Rend son index, ou −1 si le serveur audio n'a pas pu le créer.
static func preparer_bus() -> int:
	var i := AudioServer.get_bus_index(BUS)
	if i < 0:
		var n := AudioServer.get_bus_count()
		AudioServer.add_bus(n)
		AudioServer.set_bus_name(n, BUS)
		AudioServer.set_bus_send(n, "Master")
		i = AudioServer.get_bus_index(BUS)
	if i < 0:
		push_warning("[son] bus audio « %s » non créé — le réglage de volume n'agira sur rien" % BUS)
		return -1
	appliquer_volume(lire_volume())
	return i


static func index_bus() -> int:
	return AudioServer.get_bus_index(BUS)


# ROUTER UN LECTEUR VERS LE BUS DU JEU — appelée à la création de CHAQUE lecteur de ce jeu, et d'aucun autre.
# C'est cette fonction qui garantit que la barre de volume de l'accueil atteint bien tout ce qui sonne ici, et
# rien de ce qui sonne ailleurs.
static func router(p: AudioStreamPlayer) -> AudioStreamPlayer:
	var i := index_bus()
	if p != null and i >= 0:
		p.bus = BUS
	return p


# POSER LE VOLUME SUR LE BUS. Amplitude linéaire (0 → 1) → décibels ; 0 % = bus COUPÉ (cf. l'encadré).
static func appliquer_volume(v: float) -> void:
	var i := index_bus()
	if i < 0:
		return
	var n := clampf(v, 0.0, 1.0)
	var muet: bool = n <= VOLUME_MUET
	AudioServer.set_bus_mute(i, muet)
	AudioServer.set_bus_volume_db(i, 0.0 if muet else linear_to_db(n))


# CE QUE LE BUS PORTE VRAIMENT — relu sur le serveur audio, jamais recopié d'une variable. C'est ce que le harnais
# lit : un réglage qui « pense » être posé et un bus qui l'a reçu sont deux choses différentes.
static func volume_bus_db() -> float:
	var i := index_bus()
	return AudioServer.get_bus_volume_db(i) if i >= 0 else -999.0


static func bus_muet() -> bool:
	var i := index_bus()
	return AudioServer.is_bus_mute(i) if i >= 0 else true


# ------------------------------------------------------------------------------------------------------------
# LE VOLUME QUI SURVIT À L'EXTINCTION
# ------------------------------------------------------------------------------------------------------------
# Un réglage absent, illisible ou hors bornes rend 100 % : le jeu sonne toujours, même si le fichier a été effacé
# à la main. Même graduation que `CurseursPuzzle.lire_choix()`.
static func lire_volume() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(REGLAGE) != OK:
		return VOLUME_DEFAUT
	return clampf(float(cfg.get_value(SECTION, CLE_VOLUME, VOLUME_DEFAUT)), 0.0, 1.0)


# ⚠ ON RELIT AVANT D'ÉCRIRE : le choix du curseur vit dans le même fichier, et une écriture qui écraserait tout
#   l'emporterait. C'est le même filet que `CurseursPuzzle.noter_choix()` et `ProgressionPuzzle.noter_victoire()`.
static func noter_volume(v: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(REGLAGE)
	cfg.set_value(SECTION, CLE_VOLUME, clampf(v, 0.0, 1.0))
	cfg.save(REGLAGE)


# ------------------------------------------------------------------------------------------------------------
# LA MUSIQUE DE MARCHE DE L'ACCUEIL
# ------------------------------------------------------------------------------------------------------------
# Rend un lecteur PRÊT (bouclé, routé, au bon niveau), que l'appelant ajoute à son arbre — ou `null` si le fichier
# manque. ⚠ SON ABSENCE N'EST PAS FATALE, ET C'EST UNE GRADUATION, PAS UNE NÉGLIGENCE : un accueil silencieux
# reste un accueil jouable (même règle qu'au 7 différences), alors qu'une image de tableau absente rendrait
# l'écran faux. On le DIT au journal, et on continue.
# ⚠⚠ `loop` EST POSÉ SUR UNE **COPIE** DU FLUX (`duplicate()`) : la ressource importée est PARTAGÉE par tout le
#   projet ; la boucler en place bouclerait aussi une autre musique si un jour elle chargeait le même fichier.
#   Piège payé au 7 différences (sa B18), on ne le repaie pas.
# ⚠ `PROCESS_MODE_ALWAYS` : l'accueil peut vivre sur un arbre gelé (le puzzle met l'arbre en pause à l'écran de
#   fin) — sans ça la musique se tairait sans que personne ne l'ait demandé.
static func fabriquer_musique_accueil() -> AudioStreamPlayer:
	if not ResourceLoader.exists(MUSIQUE_ACCUEIL):
		print("[son] musique de marche introuvable (%s) — l'accueil restera silencieux" % MUSIQUE_ACCUEIL)
		return null
	var flux := load(MUSIQUE_ACCUEIL) as AudioStream
	if flux == null:
		print("[son] musique de marche illisible (%s) — l'accueil restera silencieux" % MUSIQUE_ACCUEIL)
		return null
	var boucle := flux.duplicate() as AudioStream
	if boucle is AudioStreamMP3:
		(boucle as AudioStreamMP3).loop = true
	var p := AudioStreamPlayer.new()
	p.name = "MusiqueAccueil"
	p.stream = boucle
	p.volume_db = MUSIQUE_DB
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	router(p)
	return p

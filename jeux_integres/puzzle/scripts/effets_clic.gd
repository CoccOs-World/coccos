extends Node

# ============================================================================================================
# (#192, 06-10-2026) LES PETITES FLEURS AU CLIC — clic gauche · clic droit · roulette, chacun son son
# ============================================================================================================
# ⚠⚠ CE QUE FABRICE A DICTÉ, MOT POUR MOT : « Quand on a un curseur — Cocox ou l'ami l'abeille — et qu'on clique,
#   il apparaît des petites fleurs, comme sur le bureau de CoccOs. J'aimerais que ça fasse pareil dans le jeu du
#   puzzle, comme dans le jeu découverte de la souris : des fleurs apparaissent, accompagnées de sons — clic
#   gauche · clic droit · roulette. »
#
# ⚠ C'EST UNE REPRISE, PAS UNE INVENTION :
#   - la FLEUR est `fleur_clic.gd` (copie de `scripts/effets/fleur.gd` du bureau = `scripts/souris/fleur.gd` de la
#     découverte de la souris) ;
#   - la RONDE est `_animation_fleurs()` de `scripts/bureau.gd` (la « version bureau, plus légère » : 4 fleurs de
#     10-15 px à 30-50 px du clic) et ses quatre couleurs `COULEURS_FLEURS`, reprises telles quelles ;
#   - les SONS sont ceux de la découverte (`_lecteurs` de `decouverte_souris.gd`) : gauche = `pop_joyeux`,
#     droit = `carillon`, roulette = `tic` (le son de la molette ROULÉE). Synthétisés par `sons_clic.gd`.
#   Seule différence voulue : au clic droit, la découverte fait des ÉTOILES — Fabrice demande des FLEURS aux trois
#   entrées ; le son, lui, reste distinct par entrée.
#
# ⚠⚠ C'EST UN RETOUR DÉCORATIF, IL NE MANGE AUCUN GESTE : `puzzle.gd:_input` appelle ce nœud PUIS continue son
#   chemin (prise, déplacement de la vue, zoom) sans `return` ni `set_input_as_handled`. Les fleurs sont des
#   `Node2D` sur un `CanvasLayer` : elles n'ont aucune surface de clic.
# ⚠ LE CALQUE EST À 26 : au-dessus de la vignette du modèle (25) — sinon les fleurs disparaissent quand on clique
#   le modèle — et sous l'écran de fin (30). Il est en repère ÉCRAN : zoomer ne grossit pas les fleurs.
# ⚠ LA ROULETTE N'EST PAS UNE FONTAINE : une molette envoie une rafale d'événements par geste. Le son `tic` suit
#   chaque cran (comme la découverte), mais une fleur au plus tous les `ROULETTE_INTERVALLE_MS`.
# ⚠ LES LECTEURS PASSENT PAR LE BUS DU JEU (`SonPuzzle.router`) : la barre de volume de l'accueil les règle.
#
# (#192, 07-10-2026) ET AU DOIGT — Fabrice, testé sur son téléphone : « Sur Android, pas de fleurs ni de son : il
#   n'y a pas de souris. On peut faire l'effort de mettre des sons au TOUCHÉ, avec les fleurs. » Quatrième entrée
#   `"doigt"` : un appui = la même ronde que le clic gauche + le même son (`pop_joyeux`, joué par le MÊME lecteur
#   — pas de quatrième). Le doigt n'a qu'un geste, donc pas de droit ni de roulette.
# ⚠ LE DOIGT N'EST PAS UNE FONTAINE NON PLUS : fleur ET son au plus tous les `DOIGT_INTERVALLE_MS` — une rafale de
#   tapes ou plusieurs doigts posés ensemble font UNE ronde. (Le glissé n'en fait aucune : seul l'APPUI appelle.)
# ============================================================================================================

const Fleur := preload("res://jeux_integres/puzzle/scripts/fleur_clic.gd")
const Sons := preload("res://jeux_integres/puzzle/scripts/sons_clic.gd")

const CALQUE := 26
const ROULETTE_INTERVALLE_MS := 120
const DOIGT_INTERVALLE_MS := 120
const COULEURS_FLEURS: Array[Color] = [
	Color(1.0, 0.45, 0.7), Color(0.8, 0.5, 0.95), Color(0.5, 0.6, 1.0), Color(1.0, 0.6, 0.85),
]

var _calque_effets: Node2D
var _lecteurs := {}
var _derniere_roulette := -100000
var _dernier_doigt := -100000
var compte := {"gauche": 0, "droit": 0, "roulette": 0, "doigt": 0}   # lu par la preuve


func _ready() -> void:
	var couche := CanvasLayer.new()
	couche.name = "CalqueFleurs"
	couche.layer = CALQUE
	add_child(couche)
	_calque_effets = Node2D.new()
	couche.add_child(_calque_effets)
	var flux := {"gauche": Sons.pop_joyeux(), "droit": Sons.carillon(), "roulette": Sons.tic()}
	for cle in flux:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux[cle]
		lecteur.max_polyphony = 4  # clics rapprochés = sons superposés, pas coupés (découverte)
		SonPuzzle.router(lecteur)
		add_child(lecteur)
		_lecteurs[cle] = lecteur


## `cle` : "gauche", "droit", "roulette" ou "doigt" ; `ou` en coordonnées d'écran.
func cliquer(cle: String, ou: Vector2) -> void:
	if cle == "doigt":
		var instant := Time.get_ticks_msec()
		if instant - _dernier_doigt < DOIGT_INTERVALLE_MS:
			return
		_dernier_doigt = instant
		_lecteurs["gauche"].play()            # le son du clic gauche, son lecteur : rien de dupliqué
		compte[cle] += 1
		_animation_fleurs(ou)
		return
	if not _lecteurs.has(cle):
		return
	_lecteurs[cle].play()
	compte[cle] += 1
	if cle == "roulette":
		var maintenant := Time.get_ticks_msec()
		if maintenant - _derniere_roulette < ROULETTE_INTERVALLE_MS:
			return
		_derniere_roulette = maintenant
		_poser_fleur(ou + Vector2(randf_range(-12, 12), randf_range(-12, 12)), randf_range(9, 13), 0.0)
		return
	_animation_fleurs(ou)


func nombre_fleurs() -> int:
	return _calque_effets.get_child_count() if _calque_effets != null else 0


## Version « bureau » de la ronde de fleurs — reprise de `bureau.gd:_animation_fleurs`.
func _animation_fleurs(ou: Vector2) -> void:
	for i in 4:
		var angle := TAU * float(i) / 4.0 + randf_range(-0.3, 0.3)
		_poser_fleur(ou + Vector2.from_angle(angle) * randf_range(30, 50), randf_range(10, 15), 0.05 * float(i))


func _poser_fleur(ou: Vector2, taille: float, delai: float) -> void:
	var fleur: Node2D = Fleur.new()
	fleur.position = ou
	fleur.couleur = COULEURS_FLEURS.pick_random()
	fleur.rayon = taille
	fleur.delai = delai
	_calque_effets.add_child(fleur)

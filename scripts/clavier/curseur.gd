## Gros curseur amical qui remplace le curseur système (masqué) — LE curseur de l'OS.
## Le point actif (hotspot) est à (0, 0) : pointe de la flèche, bout de l'index
## de la main, ou petite main levée de l'abeille / de la coccinelle.
## Main/abeille/coccinelle utilisent les IMAGES fournies par Freddy
## (assets/curseurs/) ; repli automatique sur les dessins par code si absentes
## (l'activité reste auto-contenue). La flèche reste dessinée par code.
## Forme, taille et vitesse lues dans les réglages adulte (user://config.cfg, [souris] :
## forme_curseur = fleche/main/abeille/coccinelle ; taille_curseur = petit/moyen/grand ;
## vitesse_curseur = 0.3 à 1.5, 1.0 = vitesse système).
## - pulser() : petit écrasement/rebond à chaque clic
## - zoomer() : grossit/rétrécit avec la molette (bornes min/max)
## - vitesse : chaque déplacement physique est re-scalé en repositionnant le
##   pointeur système (warp). Si la plateforme ignore le warp (web, certains
##   Wayland), le réglage est simplement sans effet — jamais cassé.
extends Node2D

const CHEMIN_CONFIG := "user://config.cfg"
const ECHELLES_TAILLE := {"petit": 0.55, "moyen": 1.0, "grand": 1.45}
const ECHELLE_MIN := 0.55
const ECHELLE_MAX := 1.8
const CONTOUR := Color(0.15, 0.15, 0.25)

const HAUTEUR_IMAGE := 72.0  # hauteur affichée des curseurs-images à l'échelle 1
const CHEMINS_TEXTURES := {
	"main": "res://assets/curseurs/main.png",
	"abeille": "res://assets/curseurs/abeille.png",
	"coccinelle": "res://assets/curseurs/coccinelle.png",
}
## Position du bout du doigt dans chaque image, en fractions largeur/hauteur
## (mesurée sur les pixels : plus haut point opaque de la zone de la main).
const HOTSPOTS := {
	"main": Vector2(0.559, 0.0),
	"abeille": Vector2(0.128, 0.081),
	"coccinelle": Vector2(0.127, 0.081),
}

# Silhouette de flèche classique, grande (~58 px de haut à l'échelle 1)
const POINTS_FLECHE: Array[Vector2] = [
	Vector2(0, 0), Vector2(0, 52), Vector2(12, 40), Vector2(20, 58),
	Vector2(29, 54), Vector2(21, 37), Vector2(38, 37),
]

var forme_forcee := ""  # pour les aperçus des réglages (prime sur la config)
var facteur := 1.0      # multiplicateur propre à un jeu (jeu des lettres : 2.0), posé avant add_child

var _echelle_base := 1.0
var _forme := "coccinelle"  # la mascotte de CoccOs est le curseur par défaut
var _texture: Texture2D = null
var _vitesse := 1.0
var _pos_virtuelle := Vector2.ZERO
var _warp_attendu := false


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN_CONFIG) == OK:
		var taille: String = cfg.get_value("souris", "taille_curseur", "moyen")
		_echelle_base = ECHELLES_TAILLE.get(taille, 1.0)
		_forme = cfg.get_value("souris", "forme_curseur", "coccinelle")
		_vitesse = float(cfg.get_value("souris", "vitesse_curseur", 1.0))
	if forme_forcee != "":
		# Aperçu des réglages : forme imposée, et l'échelle posée à la main
		# (mini.scale) ne doit PAS être écrasée par le réglage de taille —
		# sinon les aperçus deviennent géants dès que « Grand » est choisi.
		_forme = forme_forcee
	else:
		scale = Vector2.ONE * _echelle_base * facteur
	# Image du curseur si disponible (sinon repli sur le dessin par code)
	if CHEMINS_TEXTURES.has(_forme) and ResourceLoader.exists(CHEMINS_TEXTURES[_forme]):
		_texture = load(CHEMINS_TEXTURES[_forme])


## Vitesse du pointeur : à chaque déplacement physique, le pointeur système est
## replacé sur une position réduite/amplifiée par le facteur — les évènements
## suivants (position ET clics) partent donc du pointeur corrigé, le geste et
## l'écran restent d'accord. Le calcul repart des champs de l'évènement à chaque
## fois : si un warp est ignoré par la plateforme, aucune dérive ne s'accumule,
## le réglage devient simplement neutre.
func _input(event: InputEvent) -> void:
	if forme_forcee != "" or absf(_vitesse - 1.0) < 0.01 or OS.has_feature("web"):
		return
	if not (event is InputEventMouseMotion):
		return
	# Évènement engendré par notre propre warp → ne pas le re-corriger
	if _warp_attendu and event.position.distance_to(_pos_virtuelle) < 3.0:
		_warp_attendu = false
		return
	_warp_attendu = false
	var zone := get_viewport().get_visible_rect()
	_pos_virtuelle = event.position - event.relative * (1.0 - _vitesse)
	_pos_virtuelle = _pos_virtuelle.clamp(zone.position, zone.end)
	if _pos_virtuelle.distance_to(event.position) < 0.5:
		return  # correction trop petite pour valoir un warp
	_warp_attendu = true
	Input.warp_mouse(get_viewport().get_screen_transform() * _pos_virtuelle)


func _draw() -> void:
	if _texture != null:
		# Image affichée pour que le bout du doigt tombe exactement sur (0, 0)
		var taille: Vector2 = _texture.get_size() * (HAUTEUR_IMAGE / _texture.get_size().y)
		var decalage: Vector2 = (HOTSPOTS[_forme] as Vector2) * taille
		draw_texture_rect(_texture, Rect2(-decalage, taille), false)
		return
	match _forme:
		"main":
			_dessiner_main()
		"abeille":
			_dessiner_insecte(Color(1.0, 0.80, 0.20), true)
		"coccinelle":
			_dessiner_insecte(Color(0.85, 0.22, 0.18), false)
		_:
			_dessiner_fleche()


## Écrasement/rebond au clic — le curseur « vit ».
func pulser() -> void:
	var animation := create_tween()
	animation.tween_property(self, "scale", Vector2.ONE * _echelle_base * facteur * 0.8, 0.06)
	animation.tween_property(self, "scale", Vector2.ONE * _echelle_base * facteur, 0.14) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Molette : +1 = grossit, -1 = rétrécit (dans les bornes).
func zoomer(direction: int) -> void:
	_echelle_base = clampf(_echelle_base + 0.12 * float(direction), ECHELLE_MIN, ECHELLE_MAX)
	var animation := create_tween()
	animation.tween_property(self, "scale", Vector2.ONE * _echelle_base * facteur, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Les formes ----------------------------------------------------------------

func _dessiner_fleche() -> void:
	var points := PackedVector2Array(POINTS_FLECHE)
	draw_colored_polygon(points, Color.WHITE)
	# Contour sombre fermé pour la lisibilité sur tout fond
	var contour := points.duplicate()
	contour.append(points[0])
	draw_polyline(contour, CONTOUR, 4.0, true)


## Main gantée (façon dessin animé) : l'index pointe vers le haut, bout à (0, 0).
func _dessiner_main() -> void:
	# Contour : mêmes formes en sombre, légèrement plus grandes
	_capsule(Vector2(0, 9), Vector2(0, 30), 9.5, CONTOUR)
	draw_circle(Vector2(2, 44), 20.0, CONTOUR)
	_capsule(Vector2(-11, 38), Vector2(-4, 46), 8.5, CONTOUR)
	# Gant blanc
	_capsule(Vector2(0, 9), Vector2(0, 30), 7.0, Color.WHITE)
	draw_circle(Vector2(2, 44), 17.0, Color.WHITE)
	_capsule(Vector2(-11, 38), Vector2(-4, 46), 6.0, Color.WHITE)
	# Plis des doigts repliés
	draw_line(Vector2(8, 36), Vector2(16, 33), CONTOUR, 2.5)
	draw_line(Vector2(9, 43), Vector2(17, 40), CONTOUR, 2.5)


## Abeille ou coccinelle, le bras levé : la petite main pointe vers (0, 0).
func _dessiner_insecte(couleur_corps: Color, est_abeille: bool) -> void:
	# Bras levé + petite main (le point actif du curseur)
	_capsule(Vector2(4, 5), Vector2(15, 16), 2.5, CONTOUR)
	draw_circle(Vector2(4, 5), 4.5, CONTOUR)
	# Ailes translucides (abeille seulement), derrière le corps
	if est_abeille:
		draw_set_transform(Vector2(34, 17), deg_to_rad(15.0), Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 9.5, Color(1, 1, 1, 0.8))
		draw_set_transform(Vector2(41, 24), deg_to_rad(40.0), Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 8.5, Color(1, 1, 1, 0.8))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Corps incliné (ellipse via cercle transformé)
	var centre := Vector2(27, 31)
	draw_set_transform(centre, deg_to_rad(-38.0), Vector2(1.0, 0.74))
	draw_circle(Vector2.ZERO, 18.0, CONTOUR)
	draw_circle(Vector2.ZERO, 15.5, couleur_corps)
	if est_abeille:
		# Rayures
		draw_line(Vector2(-4.0, -14.0), Vector2(-4.0, 14.0), CONTOUR, 5.0)
		draw_line(Vector2(5.0, -12.0), Vector2(5.0, 12.0), CONTOUR, 5.0)
	else:
		# Ligne des élytres + points de la coccinelle
		draw_line(Vector2(0.0, -15.0), Vector2(0.0, 15.0), CONTOUR, 2.5)
		for point in [Vector2(-7, -6), Vector2(-6, 6), Vector2(7, -4), Vector2(6, 7), Vector2(-2, -12)]:
			draw_circle(point, 2.6, CONTOUR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Tête (côté bras levé) + œil + antennes
	draw_circle(Vector2(13, 15), 7.5, CONTOUR)
	draw_circle(Vector2(11, 13), 2.0, Color.WHITE)
	draw_line(Vector2(14, 8), Vector2(12, 0), CONTOUR, 2.0)
	draw_line(Vector2(18, 10), Vector2(20, 2), CONTOUR, 2.0)
	draw_circle(Vector2(12, 0), 2.0, CONTOUR)
	draw_circle(Vector2(20, 2), 2.0, CONTOUR)


## Segment aux bouts ronds (brique des dessins).
func _capsule(a: Vector2, b: Vector2, rayon: float, couleur: Color) -> void:
	draw_circle(a, rayon, couleur)
	draw_circle(b, rayon, couleur)
	draw_line(a, b, couleur, rayon * 2.0)

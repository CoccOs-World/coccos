# (#192, 06-10-2026) COPIE à l'octet près de `~/dev/coccos/scripts/effets/fleur.gd` (bureau CoccOs), elle-même
#   identique à `scripts/souris/fleur.gd` (la découverte de la souris, #97). Copiée, jamais empruntée : ce jeu se
#   copie seul sur une clé. Seul cet en-tête est ajouté.
## Fleur dessinée par code — animation du clic droit.
## Éclot avec un rebond (échelle 0 → 1), reste un instant, puis s'estompe.
extends Node2D

var couleur := Color(1.0, 0.45, 0.7)
var rayon := 16.0  # distance des pétales au centre
var delai := 0.0   # attente avant l'éclosion (pour l'effet ronde)


func _ready() -> void:
	scale = Vector2.ZERO
	var animation := create_tween()
	if delai > 0.0:
		animation.tween_interval(delai)
	animation.tween_property(self, "scale", Vector2.ONE, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.tween_interval(0.4)
	animation.tween_property(self, "modulate:a", 0.0, 0.5)
	animation.tween_callback(queue_free)


func _draw() -> void:
	# 6 pétales ronds autour d'un cœur jaune
	for i in 6:
		var angle := TAU * float(i) / 6.0
		draw_circle(Vector2(cos(angle), sin(angle)) * rayon, rayon * 0.75, couleur)
	draw_circle(Vector2.ZERO, rayon * 0.55, Color(1.0, 0.85, 0.3))

extends Node2D

# ============================================================================================================
# L'ÉCRAN D'ACCUEIL — LE CHOIX DU CURSEUR AVANT LE JEU
# (PUZZLE-B2, REQ_260814_PUZZLE_B2_accueil_zoom_suggestions_responsive · GDD §7.6, brief §1)
#
# « Avec bien sûr le choix du curseur avant le démarrage du jeu. » (Fabrice, GDD §2)
#
# CE QUE CET ÉCRAN MONTRE, ET DANS QUEL ORDRE — le modèle est l'accueil du jeu des 7 différences, parce que c'est
# celui que l'enfant connaît déjà :
#   ① le NOM du jeu, en grand, tout en haut : le repère de la page ;
#   ② la RÈGLE en deux lignes courtes : reconstituer l'image en emboîtant les pièces ;
#   ③ (B4) l'IMAGE MODÈLE du tableau sélectionné, et SOUS ELLE la ligne ◀ [n° du tableau] ▶ puis le nom du
#      tableau — c'est le sélecteur du GDD §7.11 (cf. son encadré plus bas) ;
#   ④ « Choisis ton curseur » et les TROIS amis — main · coccinelle · abeille — chacun montré par SA VRAIE
#      texture (ce que l'enfant voit ici est exactement ce qu'il aura sous la main) ;
#   ⑤ le bouton JOUER — qui lance LE TABLEAU SÉLECTIONNÉ (B4).
# Parcours : accueil (tableau + curseur) → puzzle. Rien d'autre entre les deux.
#
# ⚠⚠ POURQUOI L'ACCUEIL EST UNE SCÈNE À PART, ET NON UN ÉTAT DE PLUS DANS `puzzle.gd` — c'est la décision de
#   structure de cette balle, et elle a deux conséquences qu'on ne voit qu'après coup :
#   ① `scenes/puzzle.tscn` reste LE JEU PUR. Le harnais de B1 monte cette scène-là et la joue directement : il
#      n'a pas à traverser un écran d'accueil pour mesurer une découpe. La preuve de B1 continue donc de dire ce
#      qu'elle disait, sans une ligne de retouche — on ne défait pas B1 (brief §7), on n'y touche même pas.
#   ② Le choix voyage par le RÉGLAGE (`CurseursPuzzle`), pas par une variable globale : le jeu lancé seul (harnais,
#      essai) prend le dernier choix connu ou la coccinelle par défaut, et se comporte exactement comme en B1.
#
# ⚠ ET POURQUOI ON N'APPELLE PAS `change_scene_to_file` : cette méthode remplace la scène RACINE de l'arbre. Dans
#   le harnais, l'accueil vit dans un `SubViewport` — un changement de scène racine y détruirait le harnais
#   lui-même au milieu de sa mesure. On fait donc l'inverse, et c'est plus simple : l'accueil ajoute le puzzle
#   DANS SON PROPRE PARENT, puis se retire. Le même code marche à la racine (chez Fabrice) et dans le viewport
#   (au harnais) — une seule voie de code, prouvée là où elle est mesurable.
#
# ⚠ RESPONSIVE 4 CIBLES (brief §4, GDD §5) : rien n'est écrit en pixels absolus. Tout se déduit du canvas RÉEL
#   (`_ecran`, relu à l'ouverture et à chaque `size_changed`) : les blocs se posent en FRACTIONS de la hauteur, et
#   les tailles de police et de vignette suivent `_k = min(largeur/1024 ; hauteur/768)`. Un projecteur 4:3, un
#   portable 16:9, un téléphone couché ou debout affichent le même accueil, jamais rogné, jamais étiré.
#
# ⚠ DALTONIEN (CLAUDE.md) : le curseur choisi se lit de DEUX façons qui ne doivent rien à la couleur — un CADRE
#   clair épais autour de sa vignette (contraste de luminance) et le mot « choisi » écrit sous son nom. Aucune
#   information de cet écran n'est portée par une teinte seule.
# ============================================================================================================

# ============================================================================================================
# ⚠⚠ (ACCUEIL-PHASE 1, 19-08) LA SIGNATURE CoccOs EST POSÉE ICI — GDD §20.1
# ============================================================================================================
# CE QUE FABRICE A DICTÉ, MOT POUR MOT (GDD du puzzle adulte §16.1 ; la même phrase gouverne les deux puzzles) :
#   « le fond de verdure, la croix rouge qui est grosse pour quitter, la barre assez large de volume pour régler le
#     son, la petite musique de marche qu'on utilise : ça c'est la signature de CoccOs, et ça doit être présent
#     dans n'importe quelle interface d'accueil. »
#   Et le principe qui borne la balle : « si je ne précise pas, c'est parce qu'on ne change pas ce qu'on a
#   l'habitude de faire, ce qui fonctionne. »
#
# LES CINQ ÉLÉMENTS, ET D'OÙ CHACUN EST **REPRIS** (jamais réinventé — GDD §20.1) :
#   ① le FOND VERDURE (`res://images/fond_accueil_verdure.png`, COPIÉ dans ce projet) à la place du fond sombre ;
#   ② QUITTER = un ROND ROUGE à CROIX NOIRE, en HAUT À DROITE, gros (tactile Android) — il REMPLACE le bouton
#      rectangulaire « Quitter » de B3, qui était en bas à droite ; réf. `sept_differences.gd:1481` et sa B20 ;
#   ③ la BARRE DE VOLUME large (660 × 56 unités, « Volume sonore N % ») — réf. 7-diff B33 ;
#   ④ la MUSIQUE DE MARCHE en boucle sur un bus à nous (`scripts/son_puzzle.gd`) — réf. 7-diff B18 ;
#   ⑤ JOUER en VERT FONCÉ `Color(0.06, 0.30, 0.13)`, liseré ET texte BLANCS — réf. `sept_differences.gd:1478-1479`.
# CE QUI EST **GARDÉ INTACT** : le titre, les deux règles, l'image modèle, le sélecteur ◀ n ▶ et son nom de
# tableau, le choix des trois curseurs, et le chemin de `JOUER` vers `scenes/puzzle.tscn`.
#
# ⚠⚠ IL N'Y A **PAS DE VOILE** SUR LA VERDURE, ET C'EST UNE DÉCISION DE FABRICE, PAS UNE ÉCONOMIE. Le GDD §20.1 dit
#   « jamais de voile », et la source de cette phrase est le 7 différences (sa B22, mot pour mot) : « vire son voile
#   qu'il a mis sur l'image, c'est moche — une image pure. Certainement pas toucher à l'image de fond que
#   j'apporte. » Le jeu du puzzle ADULTE, lui, porte un voile à 0,66 (son §14.4) : c'est son acquis à lui, ce n'est
#   pas la consigne d'ici. ⚠ CE QUE ÇA EXIGE EN RETOUR, et qui est tenu : la lisibilité passe alors ENTIÈREMENT par
#   le CONTOUR NOIR par glyphe des écritures (`_label`, `CONTOUR`/`CONTOUR_TEL` — 5 px au bureau, 12 px sur écran
#   debout, les deux chiffres du 7-diff B1/B25). Le harnais MESURE ce contraste bande par bande et le remonte
#   chiffré : c'est Fabrice qui tranche ce qu'on fait AUX ÉCRITURES, on ne retouche jamais l'image de notre côté.
#
# ⚠ ET LE BOUCHON À CLICS RESTE (leçon 7-diff B22) : le `ColorRect` de fond ne servait pas qu'à peindre, il
#   arrêtait les clics (`MOUSE_FILTER_STOP`). Le fond verdure est un `TextureRect` qui, lui, laisse passer — le
#   bouchon est donc CONSERVÉ sous la photo, avec la même couleur qu'avant, et il reste utile le jour où la photo
#   manque (l'accueil retombe alors sur le fond sombre d'avant cette balle, sans une ligne de code en plus).
# ============================================================================================================

# ============================================================================================================
# ⚠⚠ (ACCUEIL-PHASE 3, 20-08) LA DISPOSITION DE FABRICE EST PORTÉE ICI — GDD_puzzles §20.3
# ============================================================================================================
# CE QUE LA PHASE 3 CHANGE, ET CE QU'ELLE NE CHANGE PAS. Tout ce qui suit dans ce fichier continue de poser une
# DISPOSITION PAR DÉFAUT, calculée, responsive, qui ne se chevauche sur aucune cible (c'est la phase 1, et c'est
# ce qui a permis à l'outil DEV d'exister). La phase 3 n'y touche pas d'une ligne : elle ajoute UN DERNIER GESTE à
# la fin de `_batir()` — reposer les éléments là où **Fabrice** les a mis (`_appliquer_disposition`).
#
# ⚠ POURQUOI PAR-DESSUS ET NON À LA PLACE : la disposition de Fabrice couvre TROIS cibles nommées (`linux_4_3`,
#   `linux_16_9`, `android_paysage`). Sur tout le reste — un écran DEBOUT (Android portrait, iOS, que le brief
#   laisse inchangés), une fenêtre redimensionnée à la main — c'est la disposition calculée qui tient l'écran.
#   Remplacer le calcul par la table aurait donc laissé ces cas SANS mise en page du tout.
#
# ⚠⚠ LES GROUPES NE SONT PAS UNE LISTE ÉCRITE ICI : ils sont RELEVÉS comme l'outil DEV les a relevés (§20.2 bis ①)
#   — chaque enfant direct de `_racine` tombe dans le plus petit rectangle que cet accueil DÉCLARE
#   (`etat_accueil()`), et ce qui n'entre dans aucun devient sa propre ligne de texte. Recopier ici la liste des
#   16 éléments l'aurait périmée au premier changement de l'accueil, et une clé périmée ne se voit PAS à l'écran :
#   l'élément repart simplement à sa place calculée. Le relevé, lui, suit le jeu.
#
# ⚠ ET LES RECTANGLES DÉCLARÉS SUIVENT (`_croix`, `_vol_rect`, `_modele`, `_numero`, `_fleche_g/d`, `_bouton`,
#   `_cases`) : sans ça `etat_accueil()` décrirait la page d'AVANT la disposition — le harnais mesurerait un écran
#   que personne ne voit, et un contrôle de chevauchement accuserait un écran juste.
#
# ⚠⚠ LA TOUCHE « S » DE L'OUTIL EST HONORÉE, ET ICI ELLE PORTE UNE VRAIE DÉCISION : Fabrice a SUPPRIMÉ les DEUX
#   LIGNES DE RÈGLE (`texte_regle_1`, `texte_regle_2`) sur les TROIS cibles. Un accueil qui les rallumerait
#   rendrait la touche S de l'outil décorative. On n'ALLUME jamais rien, on n'ÉTEINT que ce que S a supprimé : les
#   liserés de sélection et les mentions « ✔ choisi » des curseurs non choisis sont volontairement invisibles
#   (`_maj_choix`), et les remettre visibles afficherait TROIS « ✔ choisi ».
#
# ⚠ LA TABLE EST **CUITE** DANS `scripts/disposition_accueil.gd`, ELLE N'EST PAS LUE DANS `outils/` : ce dossier
#   n'est dans AUCUN des QUATRE `export_files`, et `user://` est un fichier de poste (un téléphone neuf n'en a
#   aucun). Cf. l'encadré de `outils/cuire_disposition_phase3.py`.
# ============================================================================================================

const JEU := "res://jeux_integres/puzzle/scenes/puzzle.tscn"

# (LOGITHÈQUE, 01-10) LE JEU EST DÉSORMAIS UNE ACTIVITÉ DU BUREAU CoccOs : la croix rouge ne ferme plus
# l'ordinateur, elle REND LA MAIN AU BUREAU — c'est le patron de sortie des autres activités
# (`scripts/classeur/classeur.gd`, `scripts/tele/tele.gd`, `scripts/pousse_pollen/pousse_pollen.gd`).
# Le repli `get_tree().quit()` est conservé pour les deux cas où il n'y a pas de bureau derrière :
#   ① le jeu rejoué seul (paquet autonome, où `res://scenes/bureau.tscn` n'existe pas) ;
#   ② le lancement direct d'une appli (`--app puzzle`, raccourci épinglé) — fermer, c'est rendre le téléphone.
const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const REF := Vector2(1024.0, 768.0)                 # l'écran de référence de Fabrice — sert d'ÉTALON, pas de cadre

# (PHASE 1) LE FOND DE VERDURE — **COPIÉ** dans `images/` de ce jeu (md5 identique à l'original du 7 différences),
# jamais emprunté : « chaque jeu doit avoir ses propres contenus » (Fabrice, 14-08).
const FOND_VERDURE := "res://jeux_integres/puzzle/images/fond_accueil_verdure.png"

const COL_FOND := Color(0.10, 0.13, 0.16, 1.0)
const COL_CARTE := Color(1.0, 1.0, 1.0, 0.10)
const COL_LISERE := Color(1.0, 1.0, 1.0, 0.92)      # le cadre du choix : de la LUMINANCE, pas une teinte
const COL_TEXTE := Color(0.94, 0.95, 0.97, 1.0)
const COL_BOUTON := Color(1.0, 1.0, 1.0, 0.16)
# (PHASE 1) SUR LA PHOTO, UNE CARTE CLAIRE À 10 % NE SE DÉTACHE PLUS : la verdure est déjà claire par endroits. On
# ASSOMBRIT au lieu d'éclaircir — même parti que le puzzle adulte (son B10), et c'est la seule façon de garder un
# contraste de FORME (la carte se voit) sans poser de voile sur toute l'image.
const COL_CARTE_SUR_FOND := Color(0.10, 0.13, 0.16, 0.42)
const COL_BOUTON_SUR_FOND := Color(0.10, 0.13, 0.16, 0.38)

# (PHASE 1) LES COULEURS DE LA SIGNATURE — chacune est RELEVÉE dans la source, pas choisie à l'œil.
const COL_JOUER := Color(0.06, 0.30, 0.13, 1.0)     # `sept_differences.gd:1478` — le VERT FONCÉ demandé
# ⚠ LE CHIFFRE DE CONTRASTE DE LA SOURCE EST À CORRIGER, ET ÇA NE CHANGE RIEN À LA COULEUR : le 7 différences
#   annonce « 6,4:1 » pour ce blanc sur ce vert ; le calcul WCAG refait par le harnais rend **10,05:1**. Les deux
#   passent le 4,5:1 de AA, la teinte demandée est tenue — mais on n'hérite pas d'un nombre sans le recalculer.
const COL_JOUER_TXT := Color(1.0, 1.0, 1.0, 1.0)    # `:1479` — le liseré ET le texte, BLANCS
const COL_QUITTER := Color(0.88, 0.24, 0.20, 1.0)   # `:1499` — le ROUGE du rond de fermeture
const COL_QUITTER_SURVOL := Color(0.95, 0.34, 0.30, 1.0)    # `:1500`
const COL_CROIX := Color(0.08, 0.09, 0.14, 1.0)     # `:1266` (COL_SORTIE_TXT) — la croix NOIRE dans le rond
const COL_RAIL := Color(0.16, 0.10, 0.05, 1.0)      # `:1523` — le creux du rail de volume
const COL_JAUGE := Color(0.98, 0.88, 0.25, 1.0)     # `:1524` — la part REMPLIE : c'est sa LONGUEUR qui informe

# (PHASE 1) LES MESURES DE LA SIGNATURE, toutes en unités de canvas (× `_k` à l'usage)
const CROIX_COTE := 64.0               # (7-diff B20) le rond de la croix, à la souris
const CROIX_COTE_TEL := 128.0          # (7-diff B25) …et sur un écran debout : le côté DOUBLE, la surface × 4
const CROIX_MARGE := 18.0              # son retrait au coin haut-droit du CANVAS
const VOL_LARGEUR := 660.0             # (7-diff B33) la barre « assez large » de Fabrice
const VOL_EPAISSEUR := 56.0            # (7-diff B33) son ÉPAISSEUR — c'est elle qui la rend commandable au doigt
const CONTOUR := 5                     # (7-diff B1) le contour noir par glyphe, au bureau
const CONTOUR_TEL := 12                # (7-diff B25) …et sur un écran debout, où 5 px ne se voient plus

const TITRE := "Le jeu des puzzles"
const REGLE_1 := "Reconstitue l'image : chaque pièce a sa place."
const REGLE_2 := "Pose une pièce près de sa voisine — elles s'accrochent toutes seules."

# ============================================================================================================
# (PUZZLE-B3) LA SORTIE DU JEU VIT SUR L'ACCUEIL, ET NULLE PART AILLEURS
# (GDD §7.9, retour de test de Fabrice : « la sortie du jeu se fait depuis l'accueil »)
#
# ⚠ POURQUOI — c'est la même doctrine que le jeu des 7 différences, et elle protège l'enfant : un enfant qui
#   cherche à sortir d'un TABLEAU ne doit pas fermer l'application par erreur. Dans le puzzle, le seul bouton est
#   la petite MAISON, qui ramène ici ; fermer le jeu est un geste séparé, explicite, et il n'est possible que
#   depuis cette page. Avant B3, ni l'un ni l'autre n'existait : une fois le puzzle lancé, sortir était « très
#   difficile » (GDD §7.9). Cet acquis-là ne change pas.
#
# ⚠⚠ (PHASE 1) CE QUI CHANGE, ET C'EST NOMMÉ PAR FABRICE : LA **FORME** ET LA **PLACE**. Le bouton RECTANGULAIRE
#   portant le mot « Quitter », en bas à droite, DISPARAÎT — « Quitter, on n'écrit pas quitter. C'est la croix
#   noire dans un rond rouge, toujours situé en haut à droite, suffisamment grosse pour pouvoir être touchée,
#   surtout sur Android. » On reprend donc le rond du 7 différences (sa B20), on ne le réinvente pas.
#   ⚠ LA CONSTANTE `QUITTER` (le mot écrit) N'EXISTE PLUS, et la clé `libelle_quitter` non plus : un harnais
#     d'avant cette phase qui les lit doit sortir ROUGE — c'est le signal qu'il mesure un écran qui n'existe plus.
#     Une clé complaisante l'aurait laissé vert sur du vide.
#
# ⚠ DALTONIEN (CLAUDE.md) — LE ROUGE EST DEMANDÉ, IL NE PORTE RIEN TOUT SEUL : ① la FORME (un ROND à croix, le seul
#   de cette page où tout est rectangle) ; ② la PLACE (le coin haut-droit, convention universelle) ; ③ la LUMINANCE
#   (croix sombre sur rond clair) ; ④ l'INFOBULLE en toutes lettres. Le rouge perdu, tout tient encore.
# ⚠ ET ELLE EST ANCRÉE AU COIN DU **CANVAS** : « toujours situé en haut à droite » veut dire la même chose sur les
#   quatre cibles. Elle est aussi à l'OPPOSÉ de JOUER — le geste qui ferme le jeu n'est pas celui qui tombe le
#   premier sous le doigt.
# ============================================================================================================
const QUITTER_BULLE := "Fermer le jeu"

# ============================================================================================================
# (PUZZLE-B4) LE SÉLECTEUR DE TABLEAU — « sous l'image modèle : ◀ [numéro du tableau] ▶ » (GDD §7.11)
#
# CE QUE FABRICE A DEMANDÉ, MOT POUR MOT, ET CE QUE ÇA DONNE À L'ÉCRAN :
#   « À l'accueil, sous l'image modèle, une ligne : flèche gauche · numéro du tableau · flèche droite. »
#   « La flèche de DROITE est INVISIBLE tant que le tableau suivant n'a jamais été atteint. »
#   « JOUER lance le tableau sélectionné. »
#
# ⚠⚠ « INVISIBLE » EST PRIS AU PIED DE LA LETTRE : quand le tableau suivant n'est pas débloqué, le bouton
#   n'existe PAS — il n'est pas grisé, pas transparent, pas désactivé. Un bouton grisé, un enfant le voit, il
#   appuie, il ne se passe rien, et il recommence. Rien à voir, rien à essayer : la page ne montre que ce qui
#   est possible. ⚠ EN REVANCHE SA PLACE RESTE RÉSERVÉE : le numéro ne se déplace pas le jour où la flèche
#   paraît. Ce qui bouge d'un lancement à l'autre déroute plus que ce qui manque.
#
# ⚠ LA FLÈCHE DE GAUCHE SUIT LA MÊME RÈGLE, par symétrie : au tableau 1 il n'y a rien derrière, elle n'est donc
#   pas là. « La flèche gauche permet de revenir aux tableaux déjà connus » (brief §2) — au premier, aucun.
#
# ⚠ LES FLÈCHES SONT DESSINÉES (deux triangles `Polygon2D`), PAS ÉCRITES. Un « ◀ » de police n'est pas garanti
#   présent dans la fonte par défaut : sur la machine où il manque, l'enfant voit un rectangle vide. Un triangle
#   dessiné s'affiche partout, à toutes les tailles, et son CONTRASTE est de la luminance — clair sur sombre,
#   lisible sous n'importe quel daltonisme (CLAUDE.md).
#
# ⚠ ET LE MODÈLE AU-DESSUS SUIT LE TABLEAU SÉLECTIONNÉ : c'est lui qui dit à l'enfant ce qu'il va reconstituer.
#   Il garde le rapport du dessin (un portrait ne s'étale pas dans une boîte couchée), et il est doublé du NOM du
#   tableau écrit dessous — l'image et le mot, jamais l'un sans l'autre.
# ============================================================================================================
const CHOISIS := "Choisis ton curseur"

# (B15 · §23 ter) LE SÉLECTEUR DU NOMBRE DE PIÈCES — une pièce DESSINÉE, deux flèches. Les trois mesures sont
# celles du puzzle adulte (`le jeu du puzzle adulte/scripts/accueil.gd:191-193`, §16.3) : on REPRODUIT l'acquis,
# on ne réinvente pas une seconde pièce qui ne lui ressemblerait qu'à peu près (règle 12).
const MOT_PIECES := "pièces"
const PIECE_COTE := 118.0              # le côté de la pièce — « assez grosse pour qu'on lise le chiffre »
const PIECE_COTE_MIN := 64.0           # …et son plancher : sous ça, « 15 » n'est plus lisible dedans
const PIECE_FLECHE := 48.0             # le côté d'une flèche de pièces : une CIBLE DE DOIGT, pas une icône

var _ecran := REF
var _k := 1.0                                        # l'échelle de tout ce qui se dessine ici
var _tel := false                                    # (PHASE 1) canvas DEBOUT (téléphone) : la croix et le contour doublent
var _racine: Control = null
var _curseur := CurseursPuzzle.DEFAUT
var _cases: Array[Rect2] = []
# (B23 · §31.1) CE QUE CHAQUE EMPLACEMENT DE CASE MONTRE — `_slots[rang]` = l'index dans `CurseursPuzzle.TABLE`.
# ⚠⚠ LE RANG ET L'INDEX NE SONT PLUS LA MÊME CHOSE, et c'est TOUT le soin de cette balle : la table porte QUATRE
#   entrées (Main · Coccinelle · Abeille · Sans curseur) et la page en montre TROIS. `_cases`, `_liseres` et
#   `_mentions` sont indexés par RANG (0/1/2 — les `case_curseur_i` de Fabrice, inchangés) ; `_curseur` est un
#   index de TABLE. Confondre les deux entourerait la mauvaise case sur Android.
var _slots: Array[int] = []
var _liseres: Array[ColorRect] = []
var _mentions: Array[Label] = []
var _bouton := Rect2()
var _parti := false                                  # le puzzle est lancé : on ne le lance pas deux fois
var _quitte := false                                 # (B3) la fermeture a été actionnée (le harnais le relit)

# (PHASE 1) LA SIGNATURE — la croix, le son, le fond
var _croix := Rect2()                                # le rond rouge de fermeture : le harnais le clique
var _croix_bouton: Button = null
var _volume := SonPuzzle.VOLUME_DEFAUT
var _vol_rect := Rect2()
var _vol_curseur: HSlider = null
var _vol_libelle: Label = null
var _musique: AudioStreamPlayer = null
var _bus := -1
var _fond_pose := false                              # la photo a-t-elle VRAIMENT été trouvée et posée ?
var _fond_taille := Vector2.ZERO                     # sa taille en pixels
var _fond_echelle := 0.0                             # le facteur de COUVERTURE réellement appliqué (x et y)

# (B4) le sélecteur
var _famille := TableauxPuzzle.DEFAUT_FAMILLE        # (B15 · §23 ter) la FAMILLE = le nombre de pièces
var _tableau := 0                                    # le tableau sélectionné, en INDEX DE TABLE (pas en rang)
var _modele := Rect2()                               # le rectangle réel de l'image modèle
var _modele_pose := false                            # la texture du tableau a-t-elle vraiment été trouvée ?
var _fleche_g := Rect2()                             # la place de la flèche gauche (réservée, même absente)
var _fleche_d := Rect2()                             # …et celle de la flèche droite
var _fleche_g_visible := false
var _fleche_d_visible := false
var _numero := Rect2()                               # la boîte du numéro, entre les deux flèches
# (B15) LE BLOC « NOMBRE DE PIÈCES » — la pièce dessinée et ses deux flèches. Leurs places restent RÉSERVÉES même
# quand la flèche n'existe pas, exactement comme celles du sélecteur de tableau (cf. `_selecteur`).
var _piece := Rect2()
var _piece_fleche_g := Rect2()
var _piece_fleche_d := Rect2()
var _piece_fleche_g_visible := false
var _piece_fleche_d_visible := false

# ⚠ (B3) LE SEUL RÉGLAGE QUE LE HARNAIS POSE, ET IL NE CHANGE AUCUNE LOGIQUE : `get_tree().quit()` tuerait la
#   preuve elle-même au milieu de sa mesure. Avec ce drapeau, le bouton parcourt EXACTEMENT le même chemin
#   (journal compris) et s'arrête à la dernière ligne — celle qui ferme la fenêtre. Ce qui est prouvé, c'est donc
#   que le bouton DÉCLENCHE la sortie ; ce qui n'est pas prouvé par le moteur, c'est que Godot sait fermer une
#   fenêtre. Le paquet livré, lui, n'a pas ce drapeau : il vaut `false` et le jeu se ferme pour de bon.
var sans_quitter := false

# ============================================================================================================
# (PHASE 3) L'ÉTAT DE LA DISPOSITION DE FABRICE
# ============================================================================================================
# `_dispo_groupes` : les ÉLÉMENTS au sens de l'outil DEV (§20.2 bis ① : « JOUER à l'écran, c'est 4 nœuds »). Ils
# se RELÈVENT à chaque `_batir()`, jamais avant : la page est reconstruite entière à chaque changement de canvas
# ou de tableau, et des groupes plus vieux que la page désigneraient des nœuds morts.
var _dispo_groupes: Array = []
var _dispo: Dictionary = {}                          # le compte rendu, relu par `etat_accueil()` et le harnais
var _dispo_absents: Dictionary = {}                  # les nœuds qu'une clé « present: false » a éteints
# LE RÔLE D'UNE LIGNE DE TEXTE, DÉCLARÉ À SA NAISSANCE. ⚠ L'outil nomme ces lignes par leur TEXTE
# (`texte_les_porcelets`) ; or le nom du tableau est ce que le sélecteur sert à changer. La cuisson les renomme
# par leur rôle, et c'est ce même rôle qu'on inscrit ici — au seul endroit qui le sait, l'appel qui pose la ligne.
var _roles: Dictionary = {}

# ⚠ LA CIBLE NOMMÉE PAR UN HARNAIS — en jeu, personne ne pose ce champ : le jeu livré passe TOUJOURS par
#   `DispositionAccueil.cible_pour()`. Un harnais, lui, monte un canvas de 1664 × 768 sur un poste Linux : sans ce
#   champ il mesurerait `linux_16_9` là où le téléphone lira `android_paysage`, donc une autre disposition.
var cible_imposee := ""

# ⚠⚠ POSÉ PAR L'OUTIL DEV, ET LUI SEUL (`outil_dev_accueil.gd:_monter_accueil`) : l'outil monte CE fichier, relève
#   les boîtes des nœuds, puis RECHARGE la disposition par-dessus. Si l'accueil s'était déjà reposé tout seul,
#   l'outil relèverait des boîtes DÉJÀ DÉPLACÉES et appliquerait les fractions une SECONDE fois — la page de
#   Fabrice partirait hors écran dès l'ouverture de son propre outil. Le drapeau ferme cette porte, et lui seul.
var sans_disposition := false


func _ready() -> void:
	_curseur = CurseursPuzzle.lire_choix()
	CurseursPuzzle.poser(_curseur)                   # l'enfant voit son ami sous sa main DÈS l'accueil
	# (PHASE 1) LE SON AVANT LA PAGE : le bus doit exister avant que le lecteur de musique soit routé, et le volume
	# relu avant que la barre soit dessinée — sinon la barre s'ouvrirait à 100 % et écraserait le réglage de Fabrice
	# au premier `_batir()`.
	_bus = SonPuzzle.preparer_bus()
	_volume = SonPuzzle.lire_volume()
	SonPuzzle.appliquer_volume(_volume)
	_musique = SonPuzzle.fabriquer_musique_accueil()
	if _musique != null:
		add_child(_musique)
		_musique.play()
	# (B4) ON OUVRE TOUJOURS SUR LE TABLEAU 1 — décision de Code, exposée. La progression dit ce qui est OUVERT,
	# elle ne choisit pas à la place de l'enfant : celui qui vient de débloquer le 2 le trouve d'un coup de flèche,
	# et celui qui veut refaire la ferme la trouve sans rien chercher. C'est aussi ce qui rend la flèche de droite
	# VISIBLE au retour d'une victoire — la preuve exacte, à l'écran, que quelque chose s'est ouvert.
	# ============================================================================================================
	# (B15 · §23 ter) L'ACCUEIL S'OUVRE **TOUJOURS** SUR LA FAMILLE « 4 PIÈCES », ET SUR SON PREMIER TABLEAU
	# ============================================================================================================
	# Fabrice, mot pour mot : « Par défaut on est sur du 4 pièces. […] En revenant sur l'accueil, ça se remettra
	# toujours par défaut sur le 4 pièces. » — c'est donc un NON-MÉMORISÉ ASSUMÉ, à la différence du curseur, qui
	# lui est relu du disque juste au-dessus. Les deux réglages sont de nature opposée : le curseur est un choix
	# d'ami qu'on garde, le nombre de pièces est une DIFFICULTÉ qu'on ne veut pas voir imposée à l'ouverture — un
	# enfant qui a essayé le 15 pièces et l'a trouvé dur ne doit pas le retrouver en face de lui le lendemain.
	# ⚠ ET C'EST GRATUIT À TENIR, PARCE QUE RIEN NE L'ÉCRIT : `_famille` naît à `DEFAUT_FAMILLE` et aucune ligne
	#   de ce fichier ne la sauvegarde. La garantie est donc structurelle, pas une remise à zéro qu'on pourrait
	#   oublier d'appeler — mais on la RÉAFFIRME ici pour que la relecture n'ait pas à le déduire.
	_famille = TableauxPuzzle.DEFAUT_FAMILLE
	_tableau = TableauxPuzzle.tableau_de(_famille, 0)
	var fautes: Array = TableauxPuzzle.verifier_familles()
	for faute in fautes:
		push_error("[accueil] ⚠ familles : " + str(faute))
	print("[accueil] familles : %d — %s · cohérence : %s"
		% [TableauxPuzzle.nombre_familles(), _resume_familles(),
			"OK" if fautes.is_empty() else "⚠ %d faute(s)" % fautes.size()])
	_maj_ecran()
	_batir()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_redimensionne):
		vp.size_changed.connect(_redimensionne)
	# ⚠ CE COMPTE N'EST PAS DÉCORATIF : c'est la seule façon de savoir, EN INTERROGEANT LE PAQUET EXPORTÉ, que les
	#   trois curseurs sont bien DANS le `.pck`. Un fichier oublié dans `export_files` ne fait pas rater l'export —
	#   il fait disparaître l'image en silence chez celui qui joue (leçon payée par le jeu des 7 différences).
	# ⚠ (B23 · §31.1) LE DÉNOMINATEUR EST `nombre_images()`, PAS `TABLE.size()` : depuis cette balle la table porte
	#   une entrée qui n'attend AUCUN fichier (« Sans curseur »). Comparer à 4 aurait écrit « 3 sur 4 » sur un
	#   paquet complet, et personne n'aurait su si le quatrième manquait vraiment.
	var dispo := 0
	for i in CurseursPuzzle.TABLE.size():
		if CurseursPuzzle.texture(i) != null:
			dispo += 1
	print("[accueil] écran %s · cible %s · curseur d'ouverture : %s (défaut %s) · %d curseurs sur %d présents dans le paquet"
		% [str(_ecran), "ANDROID" if CurseursPuzzle.android() else "BUREAU",
			CurseursPuzzle.nom(_curseur), CurseursPuzzle.nom(CurseursPuzzle.defaut()),
			dispo, CurseursPuzzle.nombre_images()])
	print("[accueil] cases montrées (§31.1) : %s" % str(_noms_slots()))
	# (PHASE 1) LE FOND ET LE SON, DITS AU JOURNAL DÈS L'OUVERTURE — chez Fabrice et sans harnais, c'est ce qui
	# distingue « la musique est absente du paquet » de « le volume est à zéro » : deux silences, deux causes, deux
	# remèdes. Même service pour la photo : « absente du .pck » ne se voit pas autrement qu'à l'écran.
	print("[accueil] fond verdure : %s (%s) · échelle de couverture × %.3f · voile AUCUN (GDD §20.1)"
		% ["posé" if _fond_pose else "ABSENT", str(_fond_taille), _fond_echelle])
	print("[accueil] son : bus « %s » = n°%d · volume %d %% (%.1f dB, muet %s) · musique de marche %s"
		% [SonPuzzle.BUS, _bus, int(round(_volume * 100.0)), SonPuzzle.volume_bus_db(),
			str(SonPuzzle.bus_muet()), "EN BOUCLE" if (_musique != null and _musique.playing) else "ABSENTE"])


# LA TAILLE RÉELLE DU CANVAS. ⚠ `get_visible_rect()` du viewport, et NON `DisplayServer.window_get_size()` : sous
# `stretch/mode = canvas_items` la fenêtre est en pixels d'écran et ce fichier dessine en unités de canvas — les
# deux ne coïncident que par hasard (leçon du 7 différences, sa B6).
func _maj_ecran() -> bool:
	var t := REF
	var vp := get_viewport()
	if vp != null:
		var r: Vector2 = vp.get_visible_rect().size
		if r.x >= 64.0 and r.y >= 64.0:              # filet : un viewport dégénéré n'écrase pas la référence
			t = r
	if t.is_equal_approx(_ecran):
		return false
	_ecran = t
	_k = minf(_ecran.x / REF.x, _ecran.y / REF.y)
	# (PHASE 1) UN CANVAS NETTEMENT DEBOUT = UN TÉLÉPHONE TENU À LA VERTICALE. C'est le seul cas où la croix double
	# de côté et le contour des écritures passe de 5 à 12 px — les deux réponses du 7 différences (ses B25/B29) à
	# « suffisamment grosse pour pouvoir être touchée, surtout sur Android ». Le seuil 1,20 est le sien.
	_tel = _ecran.y > _ecran.x * 1.20
	return true


func _redimensionne() -> void:
	if _maj_ecran():
		_batir()


# ------------------------------------------------------------------------------------------------------------
# LA PAGE — reconstruite entière à chaque changement de canvas. Elle ne porte aucun état : la reconstruire coûte
# une poignée de nœuds et évite de traîner quinze réglages de position à mettre à jour un par un.
# ------------------------------------------------------------------------------------------------------------
func _batir() -> void:
	if _racine != null:
		_racine.queue_free()
	_cases = []
	_slots = []
	_liseres = []
	_mentions = []
	_dispo_groupes = []                              # (PHASE 3) les groupes se refont AVEC la page, jamais avant
	_dispo_absents = {}
	_roles = {}
	_racine = Control.new()
	_racine.name = "Accueil"
	_racine.position = Vector2.ZERO
	_racine.size = _ecran
	_racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_racine)

	# (PHASE 1) LE BOUCHON À CLICS — c'est l'ex-fond sombre, et il ne disparaît PAS avec l'arrivée de la photo
	# (leçon 7-diff B22, cf. l'encadré en tête) : un `TextureRect` laisse passer les clics, ce `ColorRect`-ci les
	# arrête. Il reste peint : le jour où la photo manque, l'accueil retombe sur le fond d'avant cette balle.
	var fond := ColorRect.new()
	fond.name = "BouchonFond"
	fond.color = COL_FOND
	fond.position = Vector2.ZERO
	fond.size = _ecran
	fond.mouse_filter = Control.MOUSE_FILTER_STOP     # bouchon à clics : rien ne passe derrière l'accueil
	_racine.add_child(fond)
	_poser_le_fond()

	# (PHASE 1) LA CROIX ROUGE EN PREMIER, ET CE N'EST PAS COSMÉTIQUE : le titre est une ligne centrée sur TOUTE la
	# largeur du canvas ; sur un écran étroit ses glyphes atteindraient la colonne de la croix. Le titre a donc
	# besoin de connaître `_croix` avant de choisir son `y` (cf. juste dessous).
	_batir_croix_quitter()

	# ============================================================================================================
	# (B4) LE FLUX VERTICAL DE LA PAGE — et pourquoi il se calcule des DEUX BOUTS À LA FOIS
	# ============================================================================================================
	# B2 posait chaque bloc à une fraction fixe de la hauteur (0,075 · 0,19 · 0,33 · 0,40 · 0,80). C'était juste
	# tant que la page portait quatre blocs. B4 en ajoute deux — l'image modèle et le sélecteur — et des fractions
	# fixes se seraient recouvertes sur l'écran de référence, ou auraient laissé un trou sur un écran debout.
	# Alors on procède autrement, et c'est plus sûr : le HAUT (titre, règles) se pose depuis le haut, le BAS
	# (la barre de volume, JOUER, les trois curseurs, leurs libellés) se pose depuis le bas, et LE MODÈLE PREND CE
	# QUI RESTE ENTRE LES DEUX. Aucun bloc ne peut donc en écraser un autre : c'est le seul élément élastique qui
	# absorbe l'écart, et il ne se déforme jamais (sa largeur suit sa hauteur par le rapport du dessin).
	# ⚠ (PHASE 1) LE TITRE DESCEND SOUS LA CROIX QUAND, ET SEULEMENT QUAND, IL LA TOUCHERAIT. Le test se fait sur la
	#   largeur RÉELLE de ses glyphes (`get_minimum_size`), pas sur celle du nœud, qui fait tout l'écran : sur le
	#   4:3 de Fabrice le titre reste où il était (le harnais le vérifie), sur un canvas étroit il s'écarte.
	var taille_titre: int = int(round(40.0 * _k))
	var y_titre: float = 0.030 * _ecran.y
	var sonde := _label(TITRE, taille_titre)
	var demi: float = sonde.get_minimum_size().x * 0.5
	sonde.free()
	if _ecran.x * 0.5 + demi > _croix.position.x - 6.0 * _k and y_titre < _croix.end.y:
		y_titre = _croix.end.y + 6.0 * _k
	_ligne(TITRE, y_titre, taille_titre, "texte_titre")
	_ligne(REGLE_1, y_titre + 56.0 * _k, int(round(21.0 * _k)), "texte_regle_1")
	_ligne(REGLE_2, y_titre + 86.0 * _k, int(round(21.0 * _k)), "texte_regle_2")
	var haut_modele: float = y_titre + 124.0 * _k

	# --- LE BAS, posé depuis le bas ---
	# (PHASE 1) LA BANDE DU VOLUME OCCUPE LE BAS DE LA PAGE, ET ELLE EST SERVIE **AVANT** JOUER — c'est elle qui
	# fixe désormais le plancher de tout le reste. Pourquoi le bas, et pleine largeur : Fabrice demande une barre
	# « assez large » (660 unités, celle du 7-diff), et 660 ne tient à côté d'aucun bouton centré de 360. La place
	# était disponible : c'est celle que l'ancien bouton rectangulaire « Quitter » vient de libérer en bas à droite.
	# ⚠ CE QUE ÇA COÛTE, ET C'EST DIT : l'image modèle, seul bloc élastique, perd la hauteur que prend la bande
	#   (~98 unités sur le 4:3 de Fabrice, soit 132 → 96 px de haut). C'est la disposition PAR DÉFAUT de la phase 1 ;
	#   la disposition définitive est celle que Fabrice réglera à la souris (GDD §20.2/§20.3).
	var vol_ep: float = minf(VOL_EPAISSEUR * _k, 0.09 * _ecran.y)
	var vol_bande: float = 30.0 * _k + vol_ep + 12.0 * _k
	var y_vol: float = _ecran.y - vol_bande

	# LE BOUTON JOUER. Sa hauteur suit l'échelle, sa largeur est plafonnée par le canvas : sur un écran étroit il
	# occupe 62 % de la largeur, jamais plus — un bouton qui touche les deux bords se lit comme une bande.
	var bl: float = minf(360.0 * _k, 0.62 * _ecran.x)
	var bh: float = 78.0 * _k
	_bouton = Rect2(Vector2((_ecran.x - bl) * 0.5,
		minf(0.80 * _ecran.y, y_vol - 14.0 * _k - bh)), Vector2(bl, bh))

	# LES TROIS CASES. Le côté de la vignette est plafonné DEUX FOIS — par la hauteur (0,16 de l'écran ; c'était
	# 0,20 en B2, et les 4 % rendus sont exactement la place qu'il fallait au modèle) et par la largeur (les trois
	# cases plus leurs écarts doivent tenir dans 84 % du canvas). C'est ce second plafond qui tient un écran
	# étroit (téléphone debout) : sans lui, les vignettes déborderaient sur les côtés.
	var cote: float = minf(0.16 * _ecran.y, (0.84 * _ecran.x - 2.0 * 0.05 * _ecran.x) / 3.0)
	var ecart: float = 0.05 * _ecran.x
	var total: float = 3.0 * cote + 2.0 * ecart
	var x0: float = (_ecran.x - total) * 0.5
	# Sous chaque vignette viennent son NOM (+8) puis la mention « ✔ choisi » (+42, haute de 28) : le bloc d'une
	# case mesure donc `cote + 70` — c'est ce total, et non la seule vignette, qui doit rester au-dessus de JOUER.
	var y0: float = _bouton.position.y - 12.0 * _k - cote - 70.0 * _k
	# ⚠⚠ (B23 · §31.1) TROIS EMPLACEMENTS, LEUR CONTENU DONNÉ PAR `visibles()` — ET NON « une case par entrée de
	#   la table ». La table en porte QUATRE depuis cette balle ; une quatrième case aurait débordé la page et
	#   invalidé les `case_curseur_0/1/2` que Fabrice a réglés à la souris. La largeur calculée ci-dessus
	#   (`3.0 * cote + 2.0 * ecart`) reste donc juste, sur les quatre cibles.
	_slots = CurseursPuzzle.visibles()
	for rang in _slots.size():
		var r := Rect2(Vector2(x0 + float(rang) * (cote + ecart), y0), Vector2(cote, cote))
		_cases.append(r)
		_case(r, _slots[rang], rang)
	_ligne(CHOISIS, y0 - 40.0 * _k, int(round(26.0 * _k)), "texte_choisis")

	# --- LE SÉLECTEUR ET LE MODÈLE, entre les deux ---
	var y_nom: float = y0 - 70.0 * _k                 # le nom du tableau, juste sous la ligne des flèches
	var hs: float = 46.0 * _k                         # la hauteur de la ligne ◀ [n°] ▶
	var y_sel: float = y_nom - 6.0 * _k - hs
	_selecteur(y_sel, hs)
	_ligne(TableauxPuzzle.nom(_tableau), y_nom, int(round(20.0 * _k)), "texte_legende_tableau")
	# ============================================================================================================
	# (B15 · §23 ter) LA PIÈCE DU NOMBRE DE PIÈCES ET L'IMAGE MODÈLE PARTAGENT LA **MÊME BANDE**, CÔTE À CÔTE
	# ============================================================================================================
	# ⚠⚠ LA PREMIÈRE ÉCRITURE LES EMPILAIT (la pièce AU-DESSUS de l'image, comme au puzzle adulte §16.3), ET LA
	#   MESURE L'A REFUSÉE : sur le 4:3 de Fabrice, la bande élastique qui reste entre les règles et le sélecteur
	#   ne fait que **96 unités** de haut (le bas de la page est plein : volume, JOUER, les trois curseurs et
	#   leurs libellés, le sélecteur et le nom du tableau). Un bloc de pièce mesure 118 + 24 : empilé, il ne
	#   laissait à l'image ni sa place ni même de quoi exister, et le filet de `_bloc_pieces` refusait alors de
	#   poser la pièce — l'écran perdait le sélecteur que la balle vient d'ajouter. C'était mesuré au journal,
	#   pas supposé : « bande trop courte (96 unités) ».
	# LE PARTAGE HORIZONTAL RÈGLE ÇA SANS BRANCHEMENT NI CAS PARTICULIER : la bande a toujours une hauteur, on la
	#   donne aux deux, et c'est la LARGEUR qu'on répartit. Le couple est ensuite CENTRÉ, donc rien ne dérive
	#   quand l'image change de rapport d'un tableau à l'autre.
	# ⚠ ET ÇA GARDE LE COMPTEUR **CONTRE SON IMAGE**, qui est la vraie leçon du puzzle adulte : là-bas, un premier
	#   écrit posait la pièce en haut et le sélecteur en bas, laissant 650 unités de vide entre l'image et ce qui
	#   la commande. Rien ne se chevauchait, et c'était faux : un compteur si loin de son image ne se lit plus
	#   comme le sien.
	# ⚠ SUR L'ÉCRAN LIVRÉ À FABRICE, C'EST SA DISPOSITION QUI COMMANDE (§20.3) : les trois clés neuves
	#   (`piece_nombre`, `fleche_pieces_moins`, `fleche_pieces_plus`) n'étant pas encore dans sa table cuite,
	#   elles gardent CETTE place calculée — il pourra les poser à la souris avec l'outil DEV.
	var bande := Rect2(Vector2(0.0, haut_modele), Vector2(_ecran.x, y_sel - 8.0 * _k - haut_modele))
	var mp: Dictionary = _mesure_piece(bande)
	var lp: float = float(mp["largeur"])
	var ecart_pi: float = (14.0 * _k if lp > 0.0 else 0.0)
	var tm: Vector2 = _taille_modele(bande.size.y, minf(0.42 * _ecran.x, _ecran.x - lp - ecart_pi))
	var xg: float = (_ecran.x - (lp + ecart_pi + tm.x)) * 0.5
	if lp > 0.0:
		_bloc_pieces(mp, Rect2(Vector2(xg, bande.position.y), Vector2(lp, bande.size.y)))
	_modele_image(bande.position.y, bande.end.y, xg + lp + ecart_pi, tm)

	# --- LE GRAND BOUTON JOUER, à la place calculée plus haut ---
	# ⚠⚠ (PHASE 1) SES TROIS COULEURS SONT NOMMÉES PAR FABRICE, ET ELLES SONT RELEVÉES DANS LA SOURCE, PAS CHOISIES :
	#   « il a régressé parce qu'il n'était pas peint avec un vert foncé, avec un liseré blanc, écrit en blanc. »
	#   Le fond translucide générique (`COL_BOUTON`) de B2 était exactement la régression décrite : il est remplacé
	#   par le VERT FONCÉ `sept_differences.gd:1478`, son liseré et son mot passant au BLANC PLEIN (`:1479`).
	#   Contraste blanc sur ce vert : 10,05:1 MESURÉ par le harnais — très au-dessus du 4,5:1 de WCAG AA, donc
	#   lisible sans la teinte (daltonisme). La source annonçait 6,4:1 ; cf. l'encadré de `COL_JOUER_TXT`.
	var carte := ColorRect.new()
	carte.color = COL_JOUER
	carte.position = _bouton.position
	carte.size = _bouton.size
	carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(carte)
	var cadre := Line2D.new()
	cadre.points = PackedVector2Array([_bouton.position, _bouton.position + Vector2(bl, 0.0),
		_bouton.end, _bouton.position + Vector2(0.0, bh)])
	cadre.closed = true
	cadre.width = maxf(2.0, 3.0 * _k)
	cadre.default_color = COL_JOUER_TXT
	_racine.add_child(cadre)
	var lbl := _label("JOUER", int(round(40.0 * _k)))
	lbl.add_theme_color_override("font_color", COL_JOUER_TXT)
	lbl.position = _bouton.position + Vector2(0.0, (bh - 48.0 * _k) * 0.5)
	lbl.size = Vector2(bl, 48.0 * _k)
	_racine.add_child(lbl)
	var btn := Button.new()
	btn.flat = true
	btn.name = "BoutonJouer"
	btn.position = _bouton.position
	btn.size = _bouton.size
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Commencer le puzzle"
	btn.pressed.connect(_jouer)
	_racine.add_child(btn)

	# (PHASE 1) LA BARRE DE VOLUME, dans la bande réservée au bas de la page (cf. le calcul de `y_vol` plus haut).
	_batir_volume(y_vol, vol_ep)

	# (PHASE 3) LE DERNIER GESTE — la page calculée est complète, on la repose là où Fabrice l'a mise.
	# ⚠ AVANT `_maj_choix()`, ET DANS CET ORDRE : la repose ÉTEINT ce que la touche S a supprimé, `_maj_choix()`
	#   rallume ensuite le liseré et la mention du curseur choisi — en respectant ces extinctions.
	_relever_les_groupes()
	_appliquer_disposition()
	_piece_au_premier_plan()

	_maj_choix()


# ⚠⚠ (PHASE 1) LE CONTOUR NOIR PAR GLYPHE EST POSÉ ICI, POUR TOUS LES TEXTES DE LA PAGE, ET C'EST LUI QUI REMPLACE
#   LE VOILE QUE FABRICE INTERDIT (cf. l'encadré en tête). `outline_size` de Godot détoure chaque lettre : un texte
#   clair reste lisible au-dessus d'une feuille claire comme d'une ombre. 5 px au bureau, 12 px sur écran debout —
#   les deux chiffres du 7 différences (B1 puis B25 : à 5 px, sur la densité d'un téléphone, il ne se voit plus).
# ⚠ UN BALAYAGE EN FIN DE PAGE AURAIT ÉTÉ L'AUTRE VOIE (c'est celle du 7-diff) ; ici tous les textes naissent dans
#   cette seule fabrique, alors on le pose à la source : rien ne peut être oublié.
func _label(texte: String, taille: int) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_font_size_override("font_size", maxi(taille, 8))
	l.add_theme_color_override("font_color", COL_TEXTE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", CONTOUR_TEL if _tel else CONTOUR)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ============================================================================================================
# (PHASE 1) ① LE FOND DE VERDURE — EN COUVERTURE, DONC JAMAIS DÉFORMÉ, ET **SANS VOILE**
# ============================================================================================================
# ⚠ `STRETCH_KEEP_ASPECT_COVERED` : la photo est agrandie jusqu'à couvrir le canvas ENTIER, et ce qui dépasse est
#   rogné (centré). Un `STRETCH_SCALE` l'étirerait — sur un 16:9 la prairie deviendrait une prairie écrasée, et
#   « toucher à l'image que j'apporte » est précisément ce que Fabrice interdit.
# ⚠ `expand_mode` AVANT `size` — le piège payé en B1 : tant qu'il vaut son défaut, la taille minimale du nœud est
#   celle de la TEXTURE, et le nœud pousserait la page au lieu de se ranger dedans.
# ⚠⚠ LE FILTRE À MIPMAPS N'EST PAS UNE COQUETTERIE SUR **CETTE** IMAGE-LÀ (leçon du puzzle adulte, sa B4) : une photo
#   de FEUILLAGE est le pire cas d'échantillonnage qui soit. Dès que la fenêtre est plus petite que le canvas, le
#   fond est RÉDUIT, et sans niveaux de mipmap l'herbe grouille à chaque redimensionnement. `mipmaps/generate=true`
#   dans le `.import` FABRIQUE les niveaux ; cette ligne-ci les UTILISE. Les deux moitiés sont nécessaires.
# ⚠ FILET : la photo manque → on l'ÉCRIT au journal et l'accueil garde le fond sombre d'avant cette balle. Un
#   habillage absent ne doit jamais valoir un écran cassé.
func _poser_le_fond() -> void:
	_fond_pose = false
	_fond_echelle = 0.0
	if not ResourceLoader.exists(FOND_VERDURE):
		print("[accueil] fond verdure introuvable (%s) — accueil sur fond uni, palette d'avant la phase 1" % FOND_VERDURE)
		return
	var tex := load(FOND_VERDURE) as Texture2D
	if tex == null:
		print("[accueil] fond verdure illisible (%s) — accueil sur fond uni" % FOND_VERDURE)
		return
	_fond_taille = Vector2(tex.get_size())
	if _fond_taille.x <= 0.0 or _fond_taille.y <= 0.0:
		return
	var vue := TextureRect.new()
	vue.name = "FondVerdure"
	vue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vue.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	vue.texture = tex
	vue.position = Vector2.ZERO
	vue.size = _ecran
	vue.clip_contents = true
	vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vue.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_racine.add_child(vue)
	# ⚠⚠ ET RIEN NE VIENT PAR-DESSUS : pas de voile, pas de teinte, pas de rectangle translucide plein écran. C'est
	#   la consigne du GDD §20.1, et le harnais la vérifie en BALAYANT l'arbre — un `ColorRect` opaque de la taille
	#   du canvas posé après cette ligne sortirait ROUGE, quel que soit le nom qu'on lui aurait donné.
	_fond_pose = true
	_fond_echelle = maxf(_ecran.x / _fond_taille.x, _ecran.y / _fond_taille.y)


# LA COULEUR D'UNE CARTE ET CELLE D'UN BOUTON — elles DÉPENDENT du fond, et c'est tout l'objet de ces deux
# fonctions : sur la photo on ASSOMBRIT, sur le fond sombre on ÉCLAIRCIT. Un seul endroit décide, donc un seul
# endroit peut se tromper.
func _col_carte() -> Color:
	return COL_CARTE_SUR_FOND if _fond_pose else COL_CARTE


func _col_bouton() -> Color:
	return COL_BOUTON_SUR_FOND if _fond_pose else COL_BOUTON


# ============================================================================================================
# (PHASE 3) ① LE RELEVÉ DES GROUPES — LA MÊME OPÉRATION QUE L'OUTIL DEV, PAS UNE LISTE RECOPIÉE
# ============================================================================================================
# ⚠⚠ POURQUOI RELEVER PLUTÔT QUE DÉCLARER (et c'est LA décision de structure de cette balle). L'outil DEV de ce
#   jeu ne s'est pas fait dicter ses éléments : il a lu l'arbre RÉEL et rangé chaque nœud dans le plus petit
#   rectangle que cet accueil DÉCLARE (§20.2 bis ①). Les clés du fichier de Fabrice — donc de la table cuite — sont
#   la SORTIE de cet algorithme. Le reproduire à l'identique, c'est garantir par construction que la clé écrite est
#   la clé relue, y compris les RANGS de parties (`jouer/p2_label` est le 3ᵉ nœud du bouton JOUER). Une liste des
#   16 éléments recopiée ici aurait été juste aujourd'hui et fausse au premier nœud ajouté à un groupe — et un
#   groupe qui perd sa clé ne fait pas d'erreur : il repart, en silence, à sa place calculée.
# ⚠ UN ÉLÉMENT EST UN **GROUPE** : « JOUER » à l'écran, c'est une carte, un liseré, un mot et un bouton ; une case
#   de curseur, six nœuds. Les déplacer séparément déchirerait le bouton.
# ⚠ ENFANTS DIRECTS SEULEMENT, comme l'outil : un enfant suit son parent (la croix DESSINÉE est enfant du bouton
#   rouge, le triangle d'une flèche enfant de son bouton — ils suivent sans être comptés).
const DISPO_PART_DANS := 0.60                        # `outil_dev_accueil.gd:168` — la part d'un nœud dans une ancre
const DISPO_CASE_HAUT := 72.0                        # `:_ancres()` — le nom (+8, h 34) et « ✔ choisi » (+42, h 28)


# LES ANCRES — CE QUE CET ACCUEIL DÉCLARE, RELU PAR `etat_accueil()` : la même source que l'outil, mot pour mot.
# ⚠ LES DEUX AGRANDISSEMENTS SONT CEUX DE L'OUTIL, et chacun a sa raison : une case déborde de 6 unités sur les
#   côtés (son liseré) et de 70 en bas (son nom puis sa mention) ; la bande du volume épouse TOUTE la largeur du
#   canvas parce que son libellé y est posé, alors que la barre ne fait que 660 unités centrées — une ancre calée
#   sur la seule barre aurait avalé le libellé sur 1024 (660/1024 = 0,64 ≥ 0,60) et l'aurait laissé DEHORS sur la
#   planche paysage (660/1664 = 0,40) : le même geste de Fabrice n'aurait pas eu le même effet d'une cible à l'autre.
# ⚠ UNE ANCRE VIDE EST JETÉE : un rectangle de taille nulle (l'image du tableau quand la texture manque) n'est pas
#   un élément. Et la PLACE d'une flèche absente reste déclarée (elle est réservée) : l'ancre existe, mais son
#   panier sera vide — un panier vide ne fabrique aucun groupe.
func _ancres_disposition() -> Array:
	var e: Dictionary = etat_accueil()
	var k: float = float(e["k"])
	var ecran: Vector2 = e["ecran"]
	var a: Array = []
	a.append({"cle": "croix_quitter", "r": e["croix_quitter"]})
	var cases: Array = e["cases"]
	for i in cases.size():
		a.append({"cle": "case_curseur_%d" % i,
			"r": DispositionAccueil.grandir(cases[i], 8.0 * k, 8.0 * k, 8.0 * k, DISPO_CASE_HAUT * k)})
	var vol: Rect2 = e["volume_rect"]
	a.append({"cle": "volume",
		"r": DispositionAccueil.grandir(vol, vol.position.x, 32.0 * k, maxf(ecran.x - vol.end.x, 0.0), 0.0)})
	a.append({"cle": "modele_image", "r": e["modele"]})
	# (B15) LE BLOC DU NOMBRE DE PIÈCES — trois ancres, comme le sélecteur de tableau en a trois. ⚠ LE MOT
	# « pièces » N'EN EST PAS UNE : il est posé par `_ligne()` sur TOUTE la largeur du canvas, donc il ne tient
	# dans aucune ancre et devient son propre élément (`texte_mot_pieces`) — « un contrôle sur CHAQUE ligne de
	# texte », la phrase de Fabrice. C'est le même sort que le nom du tableau, juste sous les flèches.
	a.append({"cle": "piece_nombre", "r": _piece})
	a.append({"cle": "fleche_pieces_moins", "r": _piece_fleche_g})
	a.append({"cle": "fleche_pieces_plus", "r": _piece_fleche_d})
	a.append({"cle": "selecteur_numero", "r": e["numero"]})
	a.append({"cle": "fleche_image_gauche", "r": e["fleche_gauche"]})
	a.append({"cle": "fleche_image_droite", "r": e["fleche_droite"]})
	a.append({"cle": "jouer", "r": e["bouton"]})
	var vraies: Array = []
	for x in a:
		var r: Rect2 = x["r"]
		if r.size.x > 1.0 and r.size.y > 1.0:
			vraies.append(x)
	return vraies


func _relever_les_groupes() -> void:
	_dispo_groupes = []
	if _racine == null:
		return
	var ancres := _ancres_disposition()
	var paniers: Array = []
	for _i in ancres.size():
		paniers.append([])
	var libres: Array = []
	for n in _racine.get_children():
		var r: Rect2 = DispositionAccueil.rect_noeud(n)
		var choisi := -1
		var aire := INF
		for i in ancres.size():
			var ra: Rect2 = ancres[i]["r"]
			if DispositionAccueil.part_dans(r, ra) >= DISPO_PART_DANS and ra.get_area() < aire:
				choisi = i
				aire = ra.get_area()
		if choisi >= 0:
			(paniers[choisi] as Array).append(n)
		else:
			libres.append(n)
	for i in ancres.size():
		if (paniers[i] as Array).is_empty():
			continue
		_inscrire_groupe(str(ancres[i]["cle"]), paniers[i])
	# CE QUI N'ENTRE DANS AUCUNE ANCRE : chaque ligne de texte est son PROPRE élément (« un contrôle sur CHAQUE
	# ligne de texte », Fabrice). Les nœuds qui couvrent tout le canvas — la photo de verdure et le bouchon à clics
	# qui la double — sont réunis : ce sont deux calques d'UNE seule chose, le FOND.
	var fond: Array = []
	var sans_role := 0
	for n in libres:
		var r: Rect2 = DispositionAccueil.rect_noeud(n)
		if r.size.x >= _ecran.x - 2.0 and r.size.y >= _ecran.y - 2.0:
			fond.append(n)
		elif _roles.has(n):
			_inscrire_groupe(str(_roles[n]), [n])
		else:
			sans_role += 1
	if not fond.is_empty():
		_inscrire_groupe("fond_ecran", fond)
	if sans_role > 0:
		# ⚠ ON LE DIT AU LIEU DE L'AVALER : un nœud libre sans rôle est un nœud que Fabrice ne pourra PAS retrouver
		#   d'une session à l'autre (l'outil le nommerait par son texte, la cuisson le refuserait). C'est le signe
		#   qu'une ligne a été ajoutée à l'accueil sans lui donner sa clé.
		print("[accueil] ⚠ disposition : %d nœud(s) libre(s) sans rôle déclaré — non disposables" % sans_role)


func _inscrire_groupe(cle: String, noeuds: Array) -> void:
	if cle == "" or noeuds.is_empty():
		return
	var boite := Rect2()
	var premier := true
	var rects0: Array = []
	var pos0: Array = []
	var classes: Array = []
	for n in noeuds:
		var r: Rect2 = DispositionAccueil.rect_noeud(n)
		rects0.append(r)
		pos0.append(n.get("position"))
		classes.append(n.get_class())
		boite = r if premier else boite.merge(r)
		premier = false
	_dispo_groupes.append({"cle": cle, "noeuds": noeuds, "origine": boite, "rects0": rects0,
		"pos0": pos0, "classes": classes, "ech": 1.0, "dep": Vector2.ZERO})


func _groupe(cle: String) -> Dictionary:
	for g in _dispo_groupes:
		if str(g["cle"]) == cle:
			return g
	return {}


# ============================================================================================================
# (PHASE 3) ② LA REPOSE — LE DERNIER GESTE DE `_batir()`
# ============================================================================================================
# LE FLUX, ET IL N'A QU'UNE SEULE VOIE POUR LES TROIS CIBLES :
#   ⓐ les groupes sont relevés (juste avant), avec la boîte d'ORIGINE de chacun — ce que l'accueil vient de poser ;
#   ⓑ on nomme la cible (déduite en jeu, imposée au harnais) et on cherche son entrée dans la table cuite ;
#   ⓒ pour chaque élément : les FRACTIONS du canvas → (échelle, déplacement) → on pose les nœuds ;
#   ⓓ on RECALE les rectangles déclarés, sinon `etat_accueil()` décrirait la page d'avant.
# ⚠ RIEN N'EST APPLIQUÉ SUR UNE CIBLE QUE FABRICE N'A PAS DISPOSÉE (écran debout, fenêtre bricolée) : la
#   disposition calculée tient l'écran, et le motif est ÉCRIT au journal — un accueil qui se pose autrement sans
#   rien dire est exactement ce qu'on ne veut pas devoir deviner sur un téléphone.
func _appliquer_disposition() -> void:
	var cle_cible: String = cible_imposee if cible_imposee != "" else DispositionAccueil.cible_pour(_ecran)
	_dispo = {
		"cible": cle_cible, "cible_nommee": cible_imposee != "", "appliquee": false, "motif": "",
		"canvas_enregistre": Vector2.ZERO, "quand": "", "elements": 0, "parties": 0,
		"inconnues": [], "hors_page": [], "absents": [], "poses": {}, "membres": {},
		# (§20.5) D'OÙ VIENT LA BOÎTE DE L'IMAGE DU MODÈLE, et quels tableaux ont la leur
		"modele_source": "", "modeles_regles": [],
	}
	for g in _dispo_groupes:
		(_dispo["membres"] as Dictionary)[str(g["cle"])] = g["classes"]
	if sans_disposition:
		_dispo["motif"] = "l'outil DEV monte cet accueil : il reposera lui-même la disposition (double application évitée)"
		print("[accueil] disposition : %s" % _dispo["motif"])
		return
	if not DispositionAccueil.CIBLES.has(cle_cible):
		_dispo["motif"] = ("cible « %s » non portée (le brief laisse Android debout et iOS inchangés) — l'accueil "
			+ "garde la disposition qu'il calcule") % cle_cible
		print("[accueil] disposition : %s" % _dispo["motif"])
		return
	var entree: Dictionary = DispositionAccueil.CIBLES[cle_cible]
	_dispo["canvas_enregistre"] = entree["canvas"]
	_dispo["quand"] = str(entree["enregistre_le"])
	_dispo["modeles_regles"] = (entree.get("modeles", {}) as Dictionary).keys()
	for x in (entree["elements"] as Array):
		var d: Dictionary = x
		var cle := str(d["cle"])
		# ⚠⚠ (§20.5) L'IMAGE DU MODÈLE PREND LA BOÎTE DU **TABLEAU SÉLECTIONNÉ**, ET SANS ÇA LA REPOSE EST FAUSSE POUR
		#   QUATRE TABLEAUX SUR CINQ. La repose honore le coin et la LARGEUR ; la hauteur suit le rapport du dessin
		#   (pour ne jamais le déformer). Or la boîte d'origine du modèle est calculée AU RAPPORT DE L'IMAGE
		#   (`_modele_image`), et les cinq tableaux n'ont pas le même : 0,854 pour la ferme, 1,164 pour les
		#   porcelets, 1,833 pour le tracteur. À largeur imposée, la même entrée rend donc 626 unités de haut au
		#   tableau 1 et 291 au tableau 5 — l'image déborde du canvas ici, laisse un trou là. Une entrée par cible
		#   ne PEUT pas être juste pour cinq dessins de formes différentes ; il en faut une par tableau (§20.5 ②).
		# ⚠ ET UN TABLEAU QUE FABRICE N'A PAS CADRÉ N'EST PAS DEVINÉ : on retombe sur l'entrée unique de la cible et
		#   on l'ÉCRIT au journal. « Tout fit/contain automatique » est refusé par le brief — c'est Fabrice qui cadre.
		if cle == "modele_image":
			d = _entree_du_modele(entree, d)
		var g := _groupe(cle)
		var o := Rect2() if g.is_empty() else (g["origine"] as Rect2)
		if g.is_empty() or (o.size.x <= 0.5 and o.size.y <= 0.5):
			# ⚠⚠ DEUX ABSENCES QU'IL SERAIT FAUX DE CONFONDRE, ET C'EST LE POINT LE PLUS SUBTIL DE LA PHASE 3 :
			#   ⓐ L'ÉLÉMENT N'EST PAS SUR LA PAGE **PARCE QUE L'ACCUEIL NE L'Y A PAS MIS**, et il a raison : une
			#     flèche qui ne mène nulle part n'EXISTE PAS (§7.11, pris au pied de la lettre). Fabrice a enregistré
			#     sa disposition sur le tableau 2, où les DEUX flèches existent ; ouvrir le jeu sur le tableau 1 en
			#     fait disparaître une — ce n'est PAS une clé perdue.
			#   ⓑ LA CLÉ NE CORRESPOND PLUS À RIEN : l'accueil a changé depuis l'enregistrement. Là, il FAUT le
			#     crier — c'est le signe qu'il faut rouvrir l'outil DEV, pas deviner.
			#   Les mettre dans le même panier aurait rendu le harnais aveugle à ⓑ, puisque ⓐ arrive tous les jours.
			var raison := _raison_hors_page(cle)
			if raison == "":
				(_dispo["inconnues"] as Array).append(cle)
			else:
				(_dispo["hors_page"] as Array).append("%s : %s" % [cle, raison])
				_recaler_reserve(cle, d["rel"])
			continue
		var t := DispositionAccueil.resoudre_groupe(o, d["rel"], float(d["echelle"]), _ecran)
		var gech: float = float(t["ech"])
		var gdep: Vector2 = t["dep"]
		g["ech"] = gech
		g["dep"] = gdep
		var present := bool(d["present"])
		var noeuds: Array = g["noeuds"]
		var rects0: Array = g["rects0"]
		var pos0: Array = g["pos0"]
		var p_ech: Array = []
		var p_dep: Array = []
		var p_present: Array = []
		for _j in noeuds.size():
			p_ech.append(1.0)
			p_dep.append(Vector2.ZERO)
			p_present.append(true)
		# LES PARTIES — le SECOND étage de l'outil (« un contrôle sur chaque ligne de texte », le 2ᵉ double-clic
		# droit descend dans un groupe). Elles ne sont écrites au fichier que si Fabrice les a touchées.
		for y in (d.get("parties", []) as Array):
			var dp: Dictionary = y
			var j := -1
			for i in noeuds.size():
				if DispositionAccueil.cle_partie(cle, i, noeuds[i]) == str(dp["cle"]):
					j = i
					break
			if j < 0:
				(_dispo["inconnues"] as Array).append(str(dp["cle"]))
				continue
			var tp := DispositionAccueil.resoudre_partie(o, gech, gdep, rects0[j], dp["rel"],
				float(dp["echelle"]), _ecran)
			p_ech[j] = float(tp["ech"])
			p_dep[j] = tp["dep"]
			p_present[j] = bool(dp["present"])
			_dispo["parties"] = int(_dispo["parties"]) + 1
			(_dispo["poses"] as Dictionary)[str(dp["cle"])] = DispositionAccueil.rect_pose(o, gech, gdep,
				DispositionAccueil.rect_pose(rects0[j], p_ech[j], p_dep[j], rects0[j]))
		for j in noeuds.size():
			DispositionAccueil.appliquer(o, gech, gdep, noeuds[j], pos0[j], rects0[j], p_ech[j], p_dep[j])
			# ⚠ ON N'ALLUME JAMAIS RIEN ICI, ON N'ÉTEINT QUE CE QUE LA TOUCHE « S » A SUPPRIMÉ : deux des six nœuds
			#   d'une case de curseur sont volontairement invisibles (le liseré et « ✔ choisi » des curseurs non
			#   choisis, cf. `_maj_choix`). Les remettre visibles afficherait TROIS « ✔ choisi ».
			if not present or not p_present[j]:
				(noeuds[j] as Node).set("visible", false)
				_dispo_absents[noeuds[j]] = true
				(_dispo["absents"] as Array).append(cle)
		# ⓓ LE RECTANGLE DÉCLARÉ SUIT **SON NŒUD**, pas seulement son groupe (cf. l'encadré de `_recaler_rect`).
		var membre := _membre_du_rect(cle, noeuds)
		var r_membre := Rect2()
		var trouve := false
		if membre >= 0:
			r_membre = DispositionAccueil.rect_pose(o, gech, gdep,
				DispositionAccueil.rect_pose(rects0[membre], p_ech[membre], p_dep[membre], rects0[membre]))
			trouve = true
		_recaler_rect(cle, o, gech, gdep, r_membre, trouve)
		(_dispo["poses"] as Dictionary)[cle] = DispositionAccueil.rect_pose(o, gech, gdep, o)
		_dispo["elements"] = int(_dispo["elements"]) + 1
	_dispo["appliquee"] = true
	print("[accueil] DISPOSITION de Fabrice appliquée : cible « %s »%s · enregistrée le %s (canvas %s) · %d élément(s), %d partie(s) · canvas réel %s"
		% [cle_cible, " (nommée par le harnais)" if bool(_dispo["cible_nommee"]) else " (déduite)",
			str(_dispo["quand"]), str(_dispo["canvas_enregistre"]), int(_dispo["elements"]),
			int(_dispo["parties"]), str(_ecran)])
	# (§20.5) LA BOÎTE DU MODÈLE EST DITE À CHAQUE PAGE : c'est ce qui distingue « Fabrice a cadré ce tableau » de
	# « ce tableau prend l'entrée de la cible », deux écrans qui se ressemblent et dont un seul est voulu.
	print("[accueil] (§20.5) image du modèle : %s · tableaux réglés dans la table : %s"
		% [str(_dispo["modele_source"]), str(_dispo["modeles_regles"])])
	if not (_dispo["hors_page"] as Array).is_empty():
		print("[accueil] disposition : %d élément(s) que l'accueil ne pose pas en ce moment (leur place est tenue) : %s"
			% [(_dispo["hors_page"] as Array).size(), str(_dispo["hors_page"])])
	if not (_dispo["inconnues"] as Array).is_empty():
		# ⚠ CE QUI N'A PAS PU ÊTRE REPOSÉ SE DIT, JAMAIS AVALÉ EN SILENCE : c'est le signe que l'accueil a changé
		#   depuis l'enregistrement — donc qu'il faut rouvrir l'outil DEV, pas deviner.
		print("[accueil] ⚠ disposition : %d clé(s) sans correspondance dans l'accueil : %s"
			% [(_dispo["inconnues"] as Array).size(), str(_dispo["inconnues"])])
	if not (_dispo["absents"] as Array).is_empty():
		print("[accueil] disposition : %d nœud(s) éteints par une suppression de Fabrice (touche S) : %s"
			% [(_dispo["absents"] as Array).size(), str(_dispo["absents"])])


# ============================================================================================================
# (§20.5) LA BOÎTE DU MODÈLE POUR LE TABLEAU SÉLECTIONNÉ
# ============================================================================================================
# Rend soit l'entrée du tableau courant (cuite depuis `modele_par_tableau`, et seulement pour les tableaux que
# Fabrice a RÉGLÉS), soit l'entrée unique de la cible — telle quelle, sans la retoucher. Le motif est écrit dans
# `_dispo["modele_source"]`, donc lisible par `etat_accueil()` : un choix qui ne se voit pas est un choix qu'on ne
# peut pas contredire.
# ============================================================================================================
# (B15) LE SÉLECTEUR DE PIÈCES NE PEUT PAS DISPARAÎTRE SOUS UN ÉLÉMENT QUE FABRICE A DÉPLACÉ
# ============================================================================================================
# ⚠⚠ CE BLOC EXISTE PARCE QUE LA MESURE L'A EXIGÉ, ET LE DÉFAUT MÉRITE D'ÊTRE ÉCRIT PLUTÔT QUE CORRIGÉ EN
#   SILENCE : sur l'écran de Fabrice, sa disposition agrandit l'image modèle jusqu'à **535 × 626 unités**
#   (`disposition_accueil.gd`, cible `linux_4_3`, `modele_image` : 52 % de la largeur, 81 % de la hauteur). La
#   place que le flux calcule pour la pièce du nombre de pièces tombe DEDANS — mesuré au pixel : 0,0 % de matière
#   claire dans sa boîte, la pièce était peinte PUIS recouverte. Un sélecteur invisible, c'est un sélecteur que
#   Fabrice ne peut même pas trouver pour le déplacer.
# CE QU'ON FAIT, ET CE QU'ON NE FAIT PAS :
#   ⓐ on remonte les nœuds de la pièce AU PREMIER PLAN — ils sont alors visibles et cliquables ;
#   ⓑ on NE LES DÉPLACE PAS. Inventer une place « libre » sur un écran que Fabrice a composé à la main serait
#     décider à sa place, et la §20.3 dit exactement le contraire : Code ajoute l'élément, FABRICE le pose.
#   ⓒ on l'ÉCRIT au journal, avec le nom des clés à poser — c'est la seule façon que ça ne se perde pas.
# ⚠ ET RIEN NE BOUGE SUR LES CIBLES NON DISPOSÉES (téléphone debout, iOS) : sans recouvrement mesuré, on ne
#   touche pas à l'ordre de dessin.
func _piece_au_premier_plan() -> void:
	if _racine == null or _piece.size.x <= 1.0:
		return
	var couvert := false
	for n in _racine.get_children():
		if not (n is TextureRect):
			continue
		if str(n.name) != "ModeleAccueil":
			continue
		if (n as Control).get_global_rect().intersects(Rect2(
				_racine.global_position + _piece.position, _piece.size)):
			couvert = true
	if not couvert:
		return
	# ⚠ L'ORDRE DE CETTE LISTE EST L'ORDRE DE DESSIN FINAL : le fond d'abord, le cadre ensuite, le bouton (et son
	#   triangle) en dernier — sinon le fond opaque de la flèche recouvrirait son propre triangle.
	var noms := ["PieceNombre", "ChiffrePieces",
		"FlechePiecesMoinsFond", "FlechePiecesMoinsCadre", "FlechePiecesMoins",
		"FlechePiecesPlusFond", "FlechePiecesPlusCadre", "FlechePiecesPlus"]
	var remontes := 0
	for nom in noms:
		var n := _racine.get_node_or_null(nom)
		if n != null:
			_racine.move_child(n, -1)
			remontes += 1
	for n in _racine.get_children():
		if _roles.get(n, "") == "texte_mot_pieces":
			_racine.move_child(n, -1)
			remontes += 1
	print("[accueil] (B15) le sélecteur de pièces tombe SOUS l'image modèle que ta disposition agrandit : "
		+ "%d nœud(s) remontés au premier plan pour qu'il reste visible et cliquable. " % remontes
		+ "⚠ À POSER à la souris dans l'outil DEV (§20.3) — clés : « piece_nombre », « fleche_pieces_moins », "
		+ "« fleche_pieces_plus », « texte_mot_pieces ».")


func _entree_du_modele(entree: Dictionary, defaut: Dictionary) -> Dictionary:
	var modeles = entree.get("modeles", null)
	if modeles is Dictionary and (modeles as Dictionary).has(_tableau):
		var m: Dictionary = (modeles as Dictionary)[_tableau]
		_dispo["modele_source"] = "tableau %d « %s » — sa boîte propre (réglée par Fabrice)" \
			% [_tableau + 1, TableauxPuzzle.nom(_tableau)]
		return {"cle": "modele_image", "present": bool(m["present"]), "rel": m["rel"], "echelle": m["echelle"]}
	_dispo["modele_source"] = ("tableau %d « %s » — AUCUNE boîte propre : l'entrée unique de la cible s'applique, "
		+ "et la hauteur suit le rapport de CE dessin (l'image peut déborder ou laisser un trou — à cadrer dans "
		+ "l'outil DEV, §20.5)") % [_tableau + 1, TableauxPuzzle.nom(_tableau)]
	return defaut


# POURQUOI CET ÉLÉMENT N'EST-IL PAS SUR LA PAGE ? — la réponse vient de l'accueil lui-même, pas d'une supposition.
# Une chaîne vide veut dire « aucune raison connue », et c'est alors une vraie clé perdue.
func _raison_hors_page(cle: String) -> String:
	match cle:
		"fleche_image_gauche":
			if not _fleche_g_visible:
				return "premier tableau : la flèche gauche n'existe pas (§7.11)"
		"fleche_image_droite":
			if not _fleche_d_visible:
				return "dernier tableau ouvert : la flèche droite n'existe pas (§7.11)"
		# ⚠⚠ (B20) LES DEUX FLÈCHES DU NOMBRE DE PIÈCES OBÉISSENT À LA MÊME RÈGLE QUE CELLES DU TABLEAU, ET ELLES
		#   MANQUAIENT ICI : une flèche « moins de pièces » n'existe pas dans la PREMIÈRE famille, une « plus » pas
		#   dans la DERNIÈRE (`_bloc_pieces`, mêmes lignes que §7.11). Sans ces deux cas, leur clé tombait dans
		#   « inconnues » — le cri réservé à une clé qui ne désigne PLUS RIEN. Le journal accusait donc la
		#   disposition de Fabrice d'être périmée alors qu'elle est juste, et c'est exactement la confusion ⓐ/ⓑ que
		#   l'encadré d'`_appliquer_disposition` dit de ne jamais faire.
		"fleche_pieces_moins":
			if not _piece_fleche_g_visible:
				return "première famille : la flèche « moins de pièces » n'existe pas (§23 ter)"
		"fleche_pieces_plus":
			if not _piece_fleche_d_visible:
				return "dernière famille : la flèche « plus de pièces » n'existe pas (§23 ter)"
		"modele_image":
			if not _modele_pose:
				return "aucune image de tableau à montrer (texture absente ou écran écrasé)"
		_:
			if cle.begins_with("case_curseur_") and int(cle.trim_prefix("case_curseur_")) >= _cases.size():
				return "ce curseur n'existe plus dans la table"
	return ""


# LA PLACE D'UN ÉLÉMENT ABSENT RESTE **CELLE DE FABRICE**, pas celle du calcul par défaut.
# ⚠ POURQUOI ON LA TIENT QUAND MÊME : « sa place reste réservée » est une règle du sélecteur (le numéro ne se
#   déplace pas selon qu'on est au bout ou au milieu). Si `etat_accueil()` rendait pour la flèche absente son
#   ancienne place calculée — à côté d'un numéro qui, lui, a déménagé chez Fabrice — un contrôle de chevauchement
#   accuserait un écran juste.
# ⚠ ET LA TAILLE SE DÉDUIT SANS DEVINER : la boîte du groupe d'une flèche EST la flèche, donc sa largeur voulue est
#   exactement `l × canvas.x` ; la hauteur suit le rapport de la place réservée, donc rien n'est déformé.
func _recaler_reserve(cle: String, rel: Rect2) -> void:
	var vise := Vector2(rel.position.x * _ecran.x, rel.position.y * _ecran.y)
	var large: float = rel.size.x * _ecran.x
	var r := Rect2()
	match cle:
		"fleche_image_gauche":
			r = _fleche_g
		"fleche_image_droite":
			r = _fleche_d
		# (B20) mêmes deux lignes pour le sélecteur de pièces — cf. l'encadré de `_raison_hors_page`.
		"fleche_pieces_moins":
			r = _piece_fleche_g
		"fleche_pieces_plus":
			r = _piece_fleche_d
		_:
			return
	if r.size.x <= 0.5 or large <= 0.0:
		return
	var pose := Rect2(vise, r.size * (large / r.size.x))
	match cle:
		"fleche_image_gauche":
			_fleche_g = pose
		"fleche_image_droite":
			_fleche_d = pose
		"fleche_pieces_moins":
			_piece_fleche_g = pose
		"fleche_pieces_plus":
			_piece_fleche_d = pose
	(_dispo["poses"] as Dictionary)[cle] = pose


# ============================================================================================================
# (PHASE 3) ⓓ LES RECTANGLES DÉCLARÉS SUIVENT LA DISPOSITION — ET CHACUN SUIT **SON** NŒUD
# ============================================================================================================
# Sans ce recalage, `etat_accueil()` (donc le harnais, donc tout ce qui lit `_croix.end.y`) décrirait un écran que
# personne ne voit.
# ⚠⚠ ET IL NE SUFFIT PAS DE SUIVRE LE GROUPE (défaut mesuré par le puzzle adulte, son §18.3 bis ⑨) : Fabrice peut
#   déplacer un nœud SEUL, au second étage de l'outil. Un rectangle calculé sur le seul groupe désignerait alors une
#   zone que personne ne peut saisir — et un appui « sur la barre » ne remonterait plus le volume.
# ⚠ CHAQUE RECTANGLE DÉSIGNE DONC LE NŒUD QU'IL DÉCRIT — celui qu'on TOUCHE : le bouton pour JOUER, la croix, les
#   flèches et les cases ; le rail pour le volume ; l'image pour le modèle. Le seul sans nom est la boîte du
#   numéro : c'est le premier nœud de son groupe (sa carte, posée exactement sur `_numero`).
func _recaler_rect(cle: String, o: Rect2, ech: float, dep: Vector2, membre: Rect2, trouve: bool) -> void:
	match cle:
		"croix_quitter":
			_croix = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _croix)
		"volume":
			_vol_rect = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _vol_rect)
		"modele_image":
			_modele = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _modele)
		"selecteur_numero":
			_numero = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _numero)
		# ⚠⚠ (B20) LES TROIS RECTANGLES DU SÉLECTEUR DE PIÈCES MANQUAIENT ICI, ET C'ÉTAIT UN OUBLI, PAS UN CHOIX :
		#   ils sont nés en B15, `_recaler_rect` datait d'avant. Tant qu'ils n'y étaient pas, `_piece`,
		#   `_piece_fleche_g` et `_piece_fleche_d` gardaient la place CALCULÉE alors que leurs nœuds, eux, avaient
		#   bougé — donc `etat_accueil()` annonçait une place fausse, `_piece_au_premier_plan()` jugeait le
		#   recouvrement sur un fantôme, et les ancres que l'outil DEV lit dans cet état ne tombaient plus sur le
		#   bloc. Le sélecteur de tableau, lui, avait ses trois lignes depuis toujours : on ne fait qu'aligner.
		"piece_nombre":
			_piece = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _piece)
		"fleche_pieces_moins":
			_piece_fleche_g = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _piece_fleche_g)
		"fleche_pieces_plus":
			_piece_fleche_d = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _piece_fleche_d)
		"fleche_image_gauche":
			_fleche_g = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _fleche_g)
		"fleche_image_droite":
			_fleche_d = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _fleche_d)
		"jouer":
			_bouton = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _bouton)
		_:
			if cle.begins_with("case_curseur_"):
				var i := int(cle.trim_prefix("case_curseur_"))
				if i >= 0 and i < _cases.size():
					_cases[i] = membre if trouve else DispositionAccueil.rect_pose(o, ech, dep, _cases[i])


# QUEL NŒUD DU GROUPE PORTE LE RECTANGLE DÉCLARÉ ? — par son NOM, parce qu'un nom est stable et qu'un rang ne l'est
# pas. ⚠ Et quand plusieurs nœuds partagent le même rectangle de départ (la carte, le liseré et le bouton de JOUER
#   se superposent), c'est le BOUTON qui gagne : le rectangle déclaré sert à savoir où l'on appuie.
func _membre_du_rect(cle: String, noeuds: Array) -> int:
	var nom := ""
	match cle:
		"croix_quitter":
			nom = "CroixQuitter"
		"volume":
			nom = "BarreVolume"
		"modele_image":
			nom = "ModeleAccueil"
		"fleche_image_gauche":
			nom = "FlecheGauche"
		"fleche_image_droite":
			nom = "FlecheDroite"
		"jouer":
			nom = "BoutonJouer"
		"selecteur_numero":
			return 0 if noeuds.size() > 0 else -1     # la boîte du numéro n'a pas de nom : c'est le premier nœud
		_:
			if cle.begins_with("case_curseur_"):
				nom = "Case" + cle.trim_prefix("case_curseur_")
	if nom == "":
		return -1
	for i in noeuds.size():
		if str((noeuds[i] as Node).name) == nom:
			return i
	return -1


# ============================================================================================================
# (PHASE 1) ② LA CROIX ROUGE EN ROND — « Quitter, on n'écrit pas quitter » (GDD §20.1)
# ============================================================================================================
# ⚠ SA TAILLE DOUBLE SUR UN ÉCRAN DEBOUT (64 → 128 unités, donc une surface × 4) : c'est la réponse du 7-diff
#   (sa B25) à « suffisamment grosse pour pouvoir être touchée, surtout sur Android ».
# ⚠ LA CROIX EST **DESSINÉE** (deux barres en X tracées), jamais un glyphe « ✕ » de police : sur la machine où la
#   fonte ne le porte pas, on verrait un rectangle vide (leçon 7-diff B17 — la même que celle des flèches de B4).
# ⚠ LE ROND EST FAIT D'UN RAYON DE COIN ÉGAL À LA MOITIÉ DU CÔTÉ : un carré arrondi ne serait pas « un rond », et
#   la FORME est l'un des quatre signaux qui rendent ce bouton lisible sans sa couleur.
func _batir_croix_quitter() -> void:
	var cote: float = (CROIX_COTE_TEL if _tel else CROIX_COTE) * _k
	_croix = Rect2(Vector2(_ecran.x - cote - CROIX_MARGE * _k, CROIX_MARGE * _k), Vector2(cote, cote))
	var btn := Button.new()
	btn.name = "CroixQuitter"
	btn.text = ""                                    # « on n'écrit pas quitter »
	btn.position = _croix.position
	btn.size = _croix.size
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = QUITTER_BULLE
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = COL_QUITTER_SURVOL if etat == "hover" or etat == "pressed" else COL_QUITTER
		st.set_corner_radius_all(int(cote * 0.5))    # la moitié du côté = un ROND, pas un carré arrondi
		btn.add_theme_stylebox_override(etat, st)
	btn.pressed.connect(_quitter)
	_racine.add_child(btn)
	var croix := CroixDessinee.new()
	croix.name = "CroixDessinee"
	croix.position = Vector2.ZERO
	croix.size = _croix.size
	croix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	croix.couleur_trait = COL_CROIX
	btn.add_child(croix)
	_croix_bouton = btn


# ============================================================================================================
# (PHASE 1) ③ LA BARRE DE VOLUME — « la barre assez large de volume pour régler le son »
# ============================================================================================================
# ⚠ DEUX SIGNAUX, JAMAIS UNE TEINTE SEULE (CLAUDE.md · daltonisme) : la LONGUEUR de la part remplie, et le
#   POURCENTAGE ÉCRIT en toutes lettres au-dessus (« Volume sonore 100 % »). Le jaune de la jauge peut disparaître,
#   le réglage reste lisible.
# ⚠ SON ÉPAISSEUR EST CE QUI LA REND COMMANDABLE (7-diff B33) : une barre fine se rate au doigt. 56 unités, et les
#   deux rayons de coin suivent la moitié de cette épaisseur — un rayon de 8 posé en dur rendrait un rail carré.
# ⚠ `content_margin_top/bottom` À LA MOITIÉ DE L'ÉPAISSEUR : sans ces marges, Godot dessine un rail de la hauteur
#   de sa texture par défaut (quelques pixels) au milieu d'un nœud de 56 — la barre paraîtrait fine malgré tout.
func _batir_volume(y: float, ep: float) -> void:
	var lv: float = minf(VOL_LARGEUR * _k, 0.96 * _ecran.x)
	var x: float = (_ecran.x - lv) * 0.5
	_vol_libelle = _label(_texte_volume(), int(round(22.0 * _k)))
	_vol_libelle.name = "LibelleVolume"
	_vol_libelle.position = Vector2(0.0, y)
	_vol_libelle.size = Vector2(_ecran.x, 28.0 * _k)
	_racine.add_child(_vol_libelle)
	_vol_rect = Rect2(Vector2(x, y + 30.0 * _k), Vector2(lv, ep))
	var s := HSlider.new()
	s.name = "BarreVolume"
	s.position = _vol_rect.position
	s.size = _vol_rect.size
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 1.0
	s.set_value_no_signal(round(_volume * 100.0))
	s.focus_mode = Control.FOCUS_NONE                # comme les boutons : le clavier ne se fait pas voler la main
	s.tooltip_text = "Volume sonore du jeu"
	var arrondi: int = int(ep * 0.5)
	var rail := StyleBoxFlat.new()
	rail.bg_color = COL_RAIL
	rail.set_corner_radius_all(arrondi)
	rail.set_border_width_all(int(maxf(2.0, 2.0 * _k)))
	rail.border_color = COL_TEXTE
	rail.content_margin_top = ep * 0.5
	rail.content_margin_bottom = ep * 0.5
	s.add_theme_stylebox_override("slider", rail)
	for etat in ["grabber_area", "grabber_area_highlight"]:
		var jauge := StyleBoxFlat.new()
		jauge.bg_color = COL_JAUGE
		jauge.set_corner_radius_all(arrondi)
		jauge.content_margin_top = ep * 0.5
		jauge.content_margin_bottom = ep * 0.5
		s.add_theme_stylebox_override(etat, jauge)
	var poignee: ImageTexture = _pastille_poignee(ep)
	for icone in ["grabber", "grabber_highlight", "grabber_disabled"]:
		s.add_theme_icon_override(icone, poignee)
	s.value_changed.connect(_volume_change)
	_racine.add_child(s)
	_vol_curseur = s


func _texte_volume() -> String:
	return "Volume sonore   %d %%" % int(round(_volume * 100.0))


# LA PASTILLE DE LA POIGNÉE — un disque CLAIR bordé de sombre, peint à la main au diamètre demandé.
# ⚠ POURQUOI PEINTE ET NON CHARGÉE : un PNG de plus serait un fichier de plus à importer, à inscrire aux DEUX
#   manifestes d'export et à tenir en cohérence avec l'épaisseur du rail — trois choses à tenir justes pour un
#   disque (leçon `godot-export-liste-explicite`). Ici le diamètre EST l'épaisseur, par construction.
func _pastille_poignee(diametre: float) -> ImageTexture:
	var d: int = maxi(8, int(roundf(diametre)))
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rr: float = float(d) * 0.5
	var c := Vector2(rr, rr)
	for yy in d:
		for xx in d:
			var dist: float = (Vector2(float(xx) + 0.5, float(yy) + 0.5) - c).length()
			if dist <= rr - 3.0:
				img.set_pixel(xx, yy, COL_TEXTE)
			elif dist <= rr - 0.5:
				img.set_pixel(xx, yy, COL_CROIX)     # le bord franc, comme la croix de fermeture
	return ImageTexture.create_from_image(img)


# ⚠ LE RÉGLAGE EST POSÉ **ET** NOTÉ : posé sur le bus (on l'entend tout de suite), noté dans `user://` (on le
#   retrouve au lancement suivant). C'est un réglage de confort, pas une humeur.
func _volume_change(valeur: float) -> void:
	_volume = clampf(valeur / 100.0, 0.0, 1.0)
	SonPuzzle.appliquer_volume(_volume)
	SonPuzzle.noter_volume(_volume)
	if _vol_libelle != null:
		_vol_libelle.text = _texte_volume()
	print("[accueil] volume : %d %% · bus « %s » %.1f dB (muet %s)"
		% [int(round(_volume * 100.0)), SonPuzzle.BUS, SonPuzzle.volume_bus_db(), str(SonPuzzle.bus_muet())])


# ⚠ (PHASE 3) `cle_dispo` NOMME LA LIGNE PAR SON **RÔLE**, et c'est la correction d'un défaut annoncé : l'outil DEV
#   tire la clé d'une ligne libre de son TEXTE, or le nom du tableau change à chaque coup de flèche. Sans rôle, la
#   ligne de légende — elle seule — repartirait à sa place calculée au premier changement de tableau, et personne
#   ne l'aurait vu sur une capture. Le rôle se déclare ICI, à l'appel qui pose la ligne : c'est le seul endroit qui
#   sache de quelle ligne il s'agit.
func _ligne(texte: String, y: float, taille: int, cle_dispo := "") -> void:
	var l := _label(texte, taille)
	l.position = Vector2(0.0, y)
	l.size = Vector2(_ecran.x, float(taille) + 14.0)
	_racine.add_child(l)
	if cle_dispo != "":
		_roles[l] = cle_dispo


# UNE CASE : le cadre de sélection (caché sauf sur le curseur courant), la carte de fond, l'APERÇU = la vraie
# texture du curseur, le nom, la mention « choisi », et un bouton transparent qui couvre toute la case — la cible
# du doigt est la case ENTIÈRE, pas la vignette.
# ⚠ (B23 · §31.1) DEUX NOMBRES, DEUX RÔLES : `i` est l'index dans la TABLE (ce qu'on montre), `rang` est
#   l'EMPLACEMENT (0/1/2 — ce que la disposition de Fabrice adresse, et ce dont le bouton porte le nom).
func _case(r: Rect2, i: int, rang: int) -> void:
	var lisere := ColorRect.new()
	lisere.color = COL_LISERE
	lisere.position = r.position - Vector2(6.0, 6.0) * _k
	lisere.size = r.size + Vector2(12.0, 12.0) * _k
	lisere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lisere.visible = false
	_racine.add_child(lisere)
	_liseres.append(lisere)
	var carte := ColorRect.new()
	carte.color = _col_carte()
	carte.position = r.position
	carte.size = r.size
	carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(carte)
	var tex := CurseursPuzzle.texture(i)
	# ⚠⚠ (B14 · §22) LA CASE « SANS CURSEUR » N'A PAS DE TEXTURE, ET CE N'EST PAS UNE TEXTURE QUI MANQUE. Sans ce
	#   premier cas, elle serait tombée dans le FILET ci-dessous et l'accueil aurait écrit « (image absente) » à
	#   l'enfant — un message d'erreur là où il y a un CHOIX. Elle reçoit donc son propre glyphe DESSINÉ.
	# ⚠ DALTONIEN (CLAUDE.md, et §22 le redemande) : le choix se lit par la FORME (un pointeur barré) et par le
	#   LIBELLÉ écrit dessous (« Sans curseur », rendu par `CurseursPuzzle.nom`), jamais par une couleur.
	# ⚠ UN SEUL NŒUD, À LA PLACE DE L'APERÇU : la case garde ses six nœuds dans le même ORDRE (liseré, carte,
	#   aperçu, nom, mention, bouton). C'est ce qui laisse intacts les rangs des groupes `case_curseur_i` que
	#   l'outil DEV relève et que les dispositions de Fabrice adressent (§20.3).
	if CurseursPuzzle.sans_curseur(i):
		var bar := PointeurBarre.new()
		bar.name = "PointeurBarre"
		bar.position = r.position + Vector2(8.0, 8.0) * _k
		bar.size = r.size - Vector2(16.0, 16.0) * _k
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_racine.add_child(bar)
	elif tex != null:
		var ap := TextureRect.new()
		ap.texture = tex
		# `expand_mode` AVANT `size` (le piège payé en B1 : sinon la taille minimale du nœud est celle de la
		# texture, 470 px, et la vignette recouvre la page). `KEEP_ASPECT_CENTERED` : le curseur n'est pas déformé.
		ap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ap.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ap.position = r.position + Vector2(8.0, 8.0) * _k
		ap.size = r.size - Vector2(16.0, 16.0) * _k
		ap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_racine.add_child(ap)
	else:
		# FILET : la texture manque → on l'ÉCRIT. Un curseur de remplacement mentirait sur ce que l'enfant aura.
		# ⚠ (PHASE 3) CE LIBELLÉ-CI N'A PAS BESOIN DE RÔLE : il tombe DANS l'ancre de sa case, donc dans le
		#   groupe `case_curseur_i` — comme les cinq autres nœuds de la case. Il en devient la partie de rang 2,
		#   et c'est aussi ce que l'outil DEV a relevé. (Il n'apparaît que si une texture de curseur manque.)
		var absent := _label("(image absente)", int(round(20.0 * _k)))
		absent.position = r.position + Vector2(0.0, r.size.y * 0.5 - 12.0 * _k)
		absent.size = Vector2(r.size.x, 28.0 * _k)
		_racine.add_child(absent)
	var nom := _label(CurseursPuzzle.nom(i), int(round(26.0 * _k)))
	nom.position = r.position + Vector2(0.0, r.size.y + 8.0 * _k)
	nom.size = Vector2(r.size.x, 34.0 * _k)
	_racine.add_child(nom)
	# LA MENTION ÉCRITE — le second signal, celui qui ne demande pas de distinguer une nuance (CLAUDE.md).
	var men := _label("✔ choisi", int(round(20.0 * _k)))
	men.position = r.position + Vector2(0.0, r.size.y + 42.0 * _k)
	men.size = Vector2(r.size.x, 28.0 * _k)
	men.visible = false
	_racine.add_child(men)
	_mentions.append(men)
	var btn := Button.new()
	btn.flat = true
	btn.name = "Case%d" % rang
	btn.position = r.position
	btn.size = r.size
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Curseur " + CurseursPuzzle.nom(i)
	btn.pressed.connect(_choisir.bind(i))
	_racine.add_child(btn)


# ============================================================================================================
# (B4) L'IMAGE MODÈLE DU TABLEAU SÉLECTIONNÉ — « ce que tu vas reconstituer »
# ⚠ ELLE PREND LA PLACE QUI RESTE, ET ELLE NE SE DÉFORME JAMAIS : la hauteur disponible est ce qui sépare le bas
#   des règles du haut du sélecteur ; la largeur s'en déduit par le RAPPORT du dessin, puis elle est plafonnée à
#   42 % du canvas (un paysage de 4758 px de large, servi sur un téléphone debout, mangerait sinon toute la
#   page) — et si c'est la largeur qui plafonne, c'est la HAUTEUR qui est recalculée, jamais l'image qu'on étire.
# ⚠ `expand_mode` AVANT `size` : le piège déjà payé en B1 (tant qu'il vaut son défaut, la taille minimale du
#   `TextureRect` est celle de la TEXTURE — 2048 px — et la vignette recouvrirait la page).
# ============================================================================================================
# (B15) LA TAILLE QUE PRENDRA L'IMAGE — mesurée AVANT toute pose, parce que le flux a besoin de sa largeur pour
# centrer le couple [pièce | image] (cf. l'encadré du flux vertical). Elle ne déforme jamais le dessin : la
# hauteur commande, la largeur suit par le rapport, et si la largeur dépasse le plafond c'est l'inverse.
func _taille_modele(dispo: float, plafond: float) -> Vector2:
	if dispo < 30.0 * _k or plafond <= 0.0:
		return Vector2.ZERO
	var tex := TableauxPuzzle.image(_tableau)
	if tex == null:
		return Vector2.ZERO
	var t := Vector2(tex.get_size())
	if t.x <= 0.0 or t.y <= 0.0:
		return Vector2.ZERO
	var mh: float = dispo
	var ml: float = mh * t.x / t.y
	if ml > plafond:
		ml = plafond
		mh = ml * t.y / t.x
	return Vector2(ml, mh)


# ⚠ (B15) `x_gauche` ET `taille` SONT LES DEUX PARAMÈTRES NEUFS, ET ILS ONT UN DÉFAUT QUI REND EXACTEMENT LE
#   COMPORTEMENT D'AVANT (image centrée sur le canvas, taille recalculée ici) : la fonction reste appelable comme
#   avant, et c'est le flux — le seul qui sache où va la pièce du nombre de pièces — qui impose la colonne.
func _modele_image(haut: float, bas: float, x_gauche := -1.0, taille := Vector2.ZERO) -> void:
	_modele = Rect2()
	_modele_pose = false
	var dispo: float = bas - haut
	if dispo < 30.0 * _k:
		return                                       # écran écrasé : on ne pose rien plutôt que d'écraser le reste
	var tex := TableauxPuzzle.image(_tableau)
	if tex == null:
		# FILET : la texture manque → on l'ÉCRIT. Une vignette de remplacement mentirait sur le tableau.
		var absent := _label("(image du tableau absente)", int(round(20.0 * _k)))
		absent.position = Vector2(0.0, haut + dispo * 0.5)
		absent.size = Vector2(_ecran.x, 28.0 * _k)
		_racine.add_child(absent)
		_roles[absent] = "texte_tableau_absent"      # (PHASE 3) même un filet porte un nom : cf. `_ligne`
		return
	var m: Vector2 = taille if taille.x > 1.0 and taille.y > 1.0 else _taille_modele(dispo, 0.42 * _ecran.x)
	if m.x <= 1.0 or m.y <= 1.0:
		return
	var gx: float = x_gauche if x_gauche >= 0.0 else (_ecran.x - m.x) * 0.5
	_modele = Rect2(Vector2(gx, haut + (dispo - m.y) * 0.5), m)
	var vue := TextureRect.new()
	vue.name = "ModeleAccueil"
	vue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vue.stretch_mode = TextureRect.STRETCH_SCALE
	vue.texture = tex
	vue.position = _modele.position
	vue.size = _modele.size
	vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ⚠⚠ (B23 · §31.6) LE FILTRE **AVEC MIPMAPS**, ET IL FAUT LES DEUX MOITIÉS POUR QUE ÇA CORRIGE QUOI QUE CE SOIT.
	#   Fabrice a vu des « petits pointillés » sur les images modèles, sur LINUX BUREAU. Cause mesurée : une image
	#   nette de 956 × 1120 (ou 1664 × 908) réduite à ~240 unités est échantillonnée UN pixel sur quatre ou cinq —
	#   c'est de l'aliasing de minification, et un filtre bilinéaire n'en corrige aucun (il n'interpole qu'entre
	#   les 4 texels voisins de celui qu'il a choisi, pas sur les 20 qu'il saute).
	#   ⚠ LA MOITIÉ QUE LE BRIEF NE DISAIT PAS : ces nœuds n'étaient PAS en `LINEAR_WITH_MIPMAPS` — ils héritaient
	#     du défaut du projet, `LINEAR` tout court (mesuré : `project.godot` ne porte aucun
	#     `default_texture_filter`, et le seul `LINEAR_WITH_MIPMAPS` du dépôt était sur le fond de l'accueil).
	#     Poser `mipmaps/generate=true` sur les treize `.import` était donc NÉCESSAIRE mais INSUFFISANT : sans
	#     échantillonneur qui les lise, les mipmaps fabriquées ne seraient jamais allées jusqu'à l'écran. Les deux
	#     moitiés sont dans la même balle, sinon elle ne corrige rien.
	#   ⚠ ET ÇA NE TOUCHE QUE LES **IMAGES MODÈLES** : les pièces du plateau ne sont pas concernées (Fabrice n'a
	#     rien signalé sur elles, et §31.5 dit de ne pas casser ce qui marche).
	vue.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_racine.add_child(vue)
	var bord := Line2D.new()
	bord.points = PackedVector2Array([_modele.position, _modele.position + Vector2(_modele.size.x, 0.0),
		_modele.end, _modele.position + Vector2(0.0, _modele.size.y)])
	bord.closed = true
	bord.width = maxf(2.0, 2.0 * _k)
	bord.default_color = Color(1.0, 1.0, 1.0, 0.55)
	_racine.add_child(bord)
	_modele_pose = true


# ============================================================================================================
# (B15 · §23 ter) LE NOMBRE DE PIÈCES — UNE PIÈCE DESSINÉE, DEUX FLÈCHES : ◀ [nb] ▶ = **LA FAMILLE**
# ============================================================================================================
# Fabrice, mot pour mot : « à l'accueil, flèche — nombre de pièces — flèche (ce qu'on a déjà utilisé). Par défaut
# on est sur du 4 pièces. Si l'enfant clique sur la flèche et se rend compte que c'est compliqué, il saura se
# retrancher. »
#
# ⚠⚠ « CE QU'ON A DÉJÀ UTILISÉ » EST UNE CONSIGNE DE REPRODUCTION, PAS UNE INVITATION À REDESSINER : la pièce et
#   ses deux flèches sont celles du puzzle adulte (§16.3), géométrie comprise — `PieceDessinee` est recopiée en
#   toutes lettres depuis `le jeu du puzzle adulte/scripts/accueil.gd:1913-1954`, tenon à droite, creux à gauche,
#   mêmes fractions. Un second dessin « qui y ressemble » aurait été une divergence de plus à entretenir.
#   ⚠ ON COPIE LE **CODE**, PAS UN FICHIER : la règle de Fabrice (GDD §6) interdit d'ancrer un jeu sur les assets
#     d'un autre, et cette pièce n'est justement AUCUN asset — elle est dessinée. Rien n'entre dans les paquets.
#
# ⚠ LES DEUX FLÈCHES N'EXISTENT QUE SI ELLES MÈNENT QUELQUE PART (§23 ter : « flèche “moins” absente au minimum
#   (4), flèche “plus” absente au maximum (15) ») — c'est la règle DÉJÀ tenue par les flèches de tableau, prise
#   au pied de la lettre : le bouton n'est pas grisé, il n'est PAS POSÉ. Leur place, elle, reste réservée : la
#   pièce ne se déplace pas selon qu'on est au bout ou au milieu.
#
# ⚠ « ASSEZ GROSSE POUR QU'ON LISE LE CHIFFRE » EST UN CALCUL, PAS UN GOÛT (§16.3), et il est fait sur la FONTE
#   qui va vraiment écrire — le puzzle adulte a payé de le supposer : le CREUX du bord gauche mord dans le corps
#   de la pièce sur toute la profondeur du rayon, si bien que la largeur utile ne vaut pas les 78 % du corps mais
#   78 − 13 = 65 %. On mesure la chaîne et on réduit la police jusqu'à ce qu'elle entre, avec 6 % de marge.
#
# ⓐ LA MESURE — ce que le bloc VEUT occuper, avant que quoi que ce soit ne soit posé. Le flux vertical en a
#   besoin pour partager la bande entre la pièce et l'image (cf. l'encadré du flux), et rien n'est créé ici :
#   mesurer et poser sont deux gestes, et les mélanger obligerait à défaire des nœuds déjà nés.
# ⚠ LE CÔTÉ DE LA PIÈCE EST PLAFONNÉ **TROIS** FOIS, et chaque plafond a sa raison : par l'échelle (le dessin
#   voulu), par la LARGEUR du canvas (0,22 — sur un téléphone étroit, la pièce et ses deux flèches doivent tenir
#   côte à côte avec l'image), et par la HAUTEUR de la bande moins le mot « pièces » (sinon le bloc déborderait
#   sur le sélecteur, qui est juste dessous). Le plancher `PIECE_COTE_MIN` passe AVANT les trois : sous ce côté,
#   le chiffre n'est plus lisible dans la pièce, et une pièce illisible ne vaut pas mieux qu'aucune pièce.
func _mesure_piece(bande: Rect2) -> Dictionary:
	var h_mot: float = 24.0 * _k                     # le mot « pièces », sous la pièce
	var cote: float = minf(minf(PIECE_COTE * _k, _ecran.x * 0.22), maxf(bande.size.y - h_mot, 0.0))
	if cote < PIECE_COTE_MIN * _k:
		# ⚠ ON NE POSE RIEN PLUTÔT QUE DE POSER UN CHIFFRE QU'ON NE PEUT PAS LIRE — et on l'ÉCRIT, parce qu'un
		#   sélecteur qui manque sans un mot au journal est une panne qu'on ne peut chercher que sur l'écran.
		print("[accueil] ⚠ bande de %.0f × %.0f unités : trop petite pour une pièce lisible (%.0f < %.0f) — "
			% [bande.size.x, bande.size.y, cote, PIECE_COTE_MIN * _k]
			+ "le sélecteur de pièces n'est pas posé")
		return {"largeur": 0.0, "cote": 0.0, "fleche": 0.0, "ecart": 0.0, "mot": h_mot}
	var fl: float = maxf(minf(PIECE_FLECHE * _k, cote * 0.45), 24.0 * _k)
	var e: float = 12.0 * _k
	return {"largeur": cote + 2.0 * (fl + e), "cote": cote, "fleche": fl, "ecart": e, "mot": h_mot}


# ⓑ LA POSE — dans la colonne que le flux lui a réservée, le bloc est CENTRÉ VERTICALEMENT sur la bande : la
#   pièce se retrouve donc à mi-hauteur de l'image qu'elle commande, quel que soit le rapport du dessin.
func _bloc_pieces(mp: Dictionary, colonne: Rect2) -> void:
	_piece = Rect2()
	_piece_fleche_g = Rect2()
	_piece_fleche_d = Rect2()
	_piece_fleche_g_visible = false
	_piece_fleche_d_visible = false
	var cote: float = float(mp["cote"])
	if cote <= 0.0:
		return
	var fl: float = float(mp["fleche"])
	var e: float = float(mp["ecart"])
	var h_mot: float = float(mp["mot"])
	var haut: float = colonne.position.y + maxf((colonne.size.y - (cote + h_mot)) * 0.5, 0.0)
	var x: float = colonne.position.x
	var yc: float = haut + (cote - fl) * 0.5         # les flèches sont centrées sur la HAUTEUR de la pièce
	_piece_fleche_g = Rect2(Vector2(x, yc), Vector2(fl, fl))
	_piece = Rect2(Vector2(x + fl + e, haut), Vector2(cote, cote))
	_piece_fleche_d = Rect2(Vector2(x + fl + e + cote + e, yc), Vector2(fl, fl))

	var dessin := PieceDessinee.new()
	dessin.name = "PieceNombre"
	dessin.position = _piece.position
	dessin.size = _piece.size
	dessin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dessin.fond = _col_carte()
	dessin.couleur_trait = COL_LISERE
	dessin.epaisseur = maxf(2.0, 3.0 * _k)
	_racine.add_child(dessin)

	# LE CHIFFRE DANS LA PIÈCE — sa taille est MESURÉE SUR LA FONTE (cf. l'encadré), jamais estimée.
	var texte: String = str(TableauxPuzzle.pieces_de_famille(_famille))
	var t: int = maxi(int(round(cote * 0.30)), 8)
	var utile: float = (PieceDessinee.CORPS.size.x - PieceDessinee.RAYON) * cote * 0.94
	var large: float = ThemeDB.fallback_font.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
	if large > utile and large > 0.0:
		t = maxi(int(floor(float(t) * utile / large)), 8)
	var chiffre := _label(texte, t)
	chiffre.name = "ChiffrePieces"
	# ⚠ LE CENTRE N'EST NI CELUI DU CARRÉ NI CELUI DU CORPS : c'est celui de la zone UTILE (entre le fond du creux
	#   et le bord du tenon). Centrer sur le carré pousserait le texte dans le creux.
	var centre: float = (PieceDessinee.CORPS.position.x + PieceDessinee.RAYON
		+ PieceDessinee.CORPS.position.x + PieceDessinee.CORPS.size.x) * 0.5
	chiffre.position = _piece.position + Vector2((centre - 0.5) * cote, (cote - float(t) * 1.25) * 0.5)
	chiffre.size = Vector2(cote, float(t) * 1.25)
	_racine.add_child(chiffre)

	# LE MOT « pièces » — le second signal, ÉCRIT. Le chiffre seul se lirait comme un numéro de tableau, et il
	# n'est pas question de compter sur une couleur pour les distinguer (Fabrice est daltonien).
	_ligne(MOT_PIECES, haut + cote, int(round(minf(19.0 * _k, h_mot * 0.80))), "texte_mot_pieces")

	_piece_fleche_g_visible = _famille > 0
	_piece_fleche_d_visible = _famille < TableauxPuzzle.nombre_familles() - 1
	if _piece_fleche_g_visible:
		_fleche(_piece_fleche_g, -1, "FlechePiecesMoins", "Moins de pièces", _changer_pieces)
	if _piece_fleche_d_visible:
		_fleche(_piece_fleche_d, 1, "FlechePiecesPlus", "Plus de pièces", _changer_pieces)


# CHANGER DE FAMILLE = CHANGER LE NOMBRE DE PIÈCES (§23 ter).
# ⚠⚠ ET LE SÉLECTEUR DE TABLEAU REPART SUR LE **PREMIER** TABLEAU DE LA FAMILLE, donc l'image modèle change —
#   c'est la phrase de Fabrice, mot pour mot : « Quand on change de famille, l'accueil présentera toujours le
#   PREMIER tableau de la famille — donc l'image du tableau change. » Le rang n'est PAS reporté d'une famille à
#   l'autre : « le 3ᵉ des 15 pièces » n'a rien à voir avec « le 3ᵉ des 4 pièces », et reporter le rang aurait pu
#   ouvrir d'un coup de flèche un tableau que l'enfant n'a pas gagné dans la famille où il arrive.
func _changer_pieces(d: int) -> void:
	var vise: int = clampi(_famille + d, 0, TableauxPuzzle.nombre_familles() - 1)
	if vise == _famille:
		return
	_famille = vise
	_tableau = TableauxPuzzle.tableau_de(_famille, 0)
	print("[accueil] NOMBRE DE PIÈCES : %d (famille « %s ») — retour au 1er tableau de la famille : « %s » ; %s"
		% [TableauxPuzzle.pieces_de_famille(_famille), TableauxPuzzle.cle_famille(_famille),
			TableauxPuzzle.nom(_tableau), _resume_progression()])
	_batir()                                         # la page se refait : la pièce, le modèle, le numéro, les flèches


func _resume_familles() -> String:
	var bouts: PackedStringArray = PackedStringArray()
	for f in TableauxPuzzle.nombre_familles():
		bouts.append("%s : %d pièces, %d tableau(x)"
			% [TableauxPuzzle.cle_famille(f), TableauxPuzzle.pieces_de_famille(f),
				TableauxPuzzle.nombre_dans_famille(f)])
	return " · ".join(bouts)


func _resume_progression() -> String:
	return "débloqués dans cette famille : %d sur %d" % [
		ProgressionPuzzle.plus_haut_famille(_famille) + 1, TableauxPuzzle.nombre_dans_famille(_famille)]


# LA LIGNE ◀ [n°] ▶ — sous le modèle, exactement comme Fabrice l'a dictée (cf. l'encadré du sélecteur).
func _selecteur(y: float, h: float) -> void:
	var fl: float = 46.0 * _k                        # le côté d'une flèche : une CIBLE DE DOIGT, pas une icône
	var ln: float = 92.0 * _k                        # la boîte du numéro
	var e: float = 18.0 * _k
	var tot: float = 2.0 * fl + 2.0 * e + ln
	var x: float = (_ecran.x - tot) * 0.5
	_fleche_g = Rect2(Vector2(x, y), Vector2(fl, h))
	_numero = Rect2(Vector2(x + fl + e, y), Vector2(ln, h))
	_fleche_d = Rect2(Vector2(x + fl + e + ln + e, y), Vector2(fl, h))
	# LA BOÎTE DU NUMÉRO — le chiffre en grand, dans un cadre clair. Le NUMÉRO est ce que Fabrice a demandé ; le
	# NOM du tableau est écrit juste dessous par `_batir` (deux façons de lire la même chose : chiffre et mot).
	var carte := ColorRect.new()
	carte.color = _col_carte()
	carte.position = _numero.position
	carte.size = _numero.size
	carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(carte)
	var cadre := Line2D.new()
	cadre.points = PackedVector2Array([_numero.position, _numero.position + Vector2(_numero.size.x, 0.0),
		_numero.end, _numero.position + Vector2(0.0, _numero.size.y)])
	cadre.closed = true
	cadre.width = maxf(2.0, 2.0 * _k)
	cadre.default_color = COL_LISERE
	_racine.add_child(cadre)
	# ⚠ (B15) LE NUMÉRO EST LE **RANG DANS LA FAMILLE**, PAS L'INDEX DE TABLE : les coccos sont le tableau 6 de la
	#   table (ils y ont été ajoutés en dernier, cf. `tableaux_puzzle.gd`) et le PREMIER que l'enfant voit. Écrire
	#   « 6 » sur le premier puzzle du jeu n'aurait aucun sens pour lui. La table est une adresse interne ; ce
	#   chiffre-ci est ce que l'enfant compte.
	var num := _label(str(TableauxPuzzle.rang_dans_famille(_tableau) + 1), int(round(30.0 * _k)))
	num.name = "NumeroTableau"
	num.position = _numero.position + Vector2(0.0, (h - 38.0 * _k) * 0.5)
	num.size = Vector2(_numero.size.x, 38.0 * _k)
	_racine.add_child(num)
	# LES DEUX FLÈCHES — chacune n'est POSÉE que si elle mène quelque part (cf. l'encadré : invisible = absente).
	# ⚠ (B15) « LA GAUCHE EXISTE SI ON N'EST PAS AU PREMIER » SE LIT DÉSORMAIS DANS LA FAMILLE : au premier tableau
	#   d'une famille la flèche gauche est ABSENTE même si la table porte des index plus petits — ils appartiennent
	#   à une autre famille, et ce n'est pas la flèche de tableau qui change de famille (§23 ter).
	_fleche_g_visible = TableauxPuzzle.rang_dans_famille(_tableau) > 0
	_fleche_d_visible = ProgressionPuzzle.suivant_ouvert(_tableau)
	if _fleche_g_visible:
		_fleche(_fleche_g, -1)
	if _fleche_d_visible:
		_fleche(_fleche_d, 1)


# UNE FLÈCHE : un triangle DESSINÉ (jamais un caractère de police), dans un cadre clair, sur toute la surface
# duquel on peut appuyer. `sens` vaut −1 (vers la gauche) ou +1 (vers la droite).
# ⚠ (B15) LES **QUATRE** FLÈCHES DE LA PAGE PASSENT PAR ICI (deux pour le tableau, deux pour le nombre de pièces),
#   et c'est voulu : une seule fabrique, donc un seul dessin, une seule cible de doigt, un seul liseré. Les trois
#   derniers paramètres ont un défaut qui rend EXACTEMENT le comportement d'avant cette balle — les appels du
#   sélecteur de tableau n'ont pas eu à changer.
func _fleche(r: Rect2, sens: int, nom := "", bulle := "", action := Callable()) -> void:
	var vrai_nom: String = nom if nom != "" else ("FlecheGauche" if sens < 0 else "FlecheDroite")
	var carte := ColorRect.new()
	carte.color = _col_bouton()
	carte.position = r.position
	carte.size = r.size
	carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# ⚠ (B15) LE FOND ET LE CADRE PORTENT LE NOM DE LEUR BOUTON, ET CE N'EST PAS DE LA COSMÉTIQUE : ce sont trois
	#   nœuds FRÈRES, pas un bouton et ses enfants. Sans un nom qui les rattache, `_piece_au_premier_plan()`
	#   remontait le triangle SEUL et laissait son cadre derrière l'image modèle — mesuré sur la capture : une
	#   flèche sans sa boîte, donc une cible de doigt qu'on ne voit plus.
	carte.name = vrai_nom + "Fond"
	_racine.add_child(carte)
	var cadre := Line2D.new()
	cadre.points = PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0.0),
		r.end, r.position + Vector2(0.0, r.size.y)])
	cadre.closed = true
	cadre.width = maxf(2.0, 2.0 * _k)
	cadre.default_color = COL_LISERE
	cadre.name = vrai_nom + "Cadre"
	_racine.add_child(cadre)
	var btn := Button.new()
	btn.flat = true
	btn.name = vrai_nom
	btn.position = r.position
	btn.size = r.size
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = bulle if bulle != "" else ("Tableau précédent" if sens < 0 else "Tableau suivant")
	btn.pressed.connect((action if action.is_valid() else _changer_tableau).bind(sens))
	_racine.add_child(btn)
	var tri := Polygon2D.new()
	tri.color = COL_LISERE                           # clair sur sombre : de la LUMINANCE, jamais une teinte seule
	if sens < 0:
		tri.polygon = PackedVector2Array([Vector2(0.70 * r.size.x, 0.18 * r.size.y),
			Vector2(0.70 * r.size.x, 0.82 * r.size.y), Vector2(0.26 * r.size.x, 0.50 * r.size.y)])
	else:
		tri.polygon = PackedVector2Array([Vector2(0.30 * r.size.x, 0.18 * r.size.y),
			Vector2(0.30 * r.size.x, 0.82 * r.size.y), Vector2(0.74 * r.size.x, 0.50 * r.size.y)])
	btn.add_child(tri)


# CHANGER DE TABLEAU. ⚠ LE PLAFOND EST RELU DANS LA PROGRESSION, PAS DANS L'ÉTAT DE LA PAGE : même si une flèche
# survivait à un enchaînement imprévu, elle ne pourrait pas ouvrir un tableau qui n'a pas été atteint.
# ⚠ (B15) ON NAVIGUE LE **RANG DANS LA FAMILLE**, ET LE PLAFOND EST CELUI DE CETTE FAMILLE-LÀ. Le principe de B4
#   ne bouge pas d'un pouce ; ce qui change, c'est que la borne basse n'est plus 0 mais le PREMIER tableau de la
#   famille : cette fonction ne peut donc pas faire sortir l'enfant de la famille qu'il a choisie. Seule
#   `_changer_pieces` en change.
func _changer_tableau(d: int) -> void:
	var rang: int = clampi(TableauxPuzzle.rang_dans_famille(_tableau) + d, 0,
		ProgressionPuzzle.plus_haut_famille(_famille))
	var vise: int = TableauxPuzzle.tableau_de(_famille, rang)
	if vise == _tableau:
		return
	_tableau = vise
	print("[accueil] tableau sélectionné : %d « %s » dans la famille « %s » (%s)"
		% [rang + 1, TableauxPuzzle.nom(_tableau), TableauxPuzzle.cle_famille(_famille), _resume_progression()])
	_batir()                                         # la page se refait : le modèle, le numéro et les flèches suivent


func _choisir(i: int) -> void:
	_curseur = clampi(i, 0, CurseursPuzzle.TABLE.size() - 1)
	CurseursPuzzle.noter_choix(_curseur)
	CurseursPuzzle.poser(_curseur)                   # le choix se voit tout de suite sous la main, pas seulement au cadre
	_maj_choix()
	print("[accueil] curseur choisi : %s (%d)" % [CurseursPuzzle.nom(_curseur), _curseur])


# ⚠ (PHASE 3) LE FILTRE `_dispo_absents` N'EST PAS THÉORIQUE : cette fonction est rappelée à CHAQUE choix de
#   curseur, longtemps après la repose. Sans lui, un nœud que la touche « S » de Fabrice a supprimé se rallumerait
#   au premier clic sur une case — la suppression n'aurait tenu que le temps de la première image.
# ⚠⚠ (B23 · §31.1) LA COMPARAISON SE FAIT SUR `_slots[rang]`, PLUS SUR LE RANG LUI-MÊME : `_curseur` est un index
#   de TABLE (0 → 3) et `_liseres`/`_mentions` sont rangés par EMPLACEMENT (0 → 2). Sur Android, où le rang 0
#   montre l'entrée 3, comparer rang et index n'aurait entouré AUCUNE case — l'enfant n'aurait pas vu son choix.
func _maj_choix() -> void:
	for i in _liseres.size():
		var vise: bool = i < _slots.size() and _slots[i] == _curseur
		_liseres[i].visible = vise and not _dispo_absents.has(_liseres[i])
	for i in _mentions.size():
		var vise2: bool = i < _slots.size() and _slots[i] == _curseur
		_mentions[i].visible = vise2 and not _dispo_absents.has(_mentions[i])


# « JOUER » — on note le choix (il aura survécu même si le jeu est coupé brutalement), puis le puzzle prend la
# place de l'accueil DANS LE MÊME PARENT (cf. l'encadré en tête : ni `change_scene_to_file`, ni variable globale).
func _jouer() -> void:
	if _parti:
		return
	_parti = true
	CurseursPuzzle.noter_choix(_curseur)
	var scene := load(JEU) as PackedScene
	if scene == null:
		push_error("[accueil] scène de jeu introuvable : " + JEU)
		return
	var jeu := scene.instantiate()
	# (B4) « JOUER lance le tableau sélectionné » (Fabrice, GDD §7.11). Le numéro voyage par la propriété du jeu,
	# comme « Rejouer » le fait déjà depuis B3 — une seule voie, la même pour les deux.
	jeu.tableau = TableauxPuzzle.numero_valide(_tableau)
	var parent := get_parent()
	parent.add_child(jeu)
	if parent == get_tree().root:
		get_tree().current_scene = jeu               # la scène courante suit, sinon l'arbre pointerait dans le vide
	print("[accueil] JOUER — %d pièces (famille « %s ») · tableau %d « %s » (index de table %d) · curseur %s"
		% [TableauxPuzzle.pieces_de_famille(_famille), TableauxPuzzle.cle_famille(_famille),
			TableauxPuzzle.rang_dans_famille(_tableau) + 1, TableauxPuzzle.nom(_tableau), _tableau,
			CurseursPuzzle.nom(_curseur)])
	queue_free()


# (B3 · PHASE 1) LA CROIX ROUGE — ON FERME LE JEU. Une seule ligne fait le travail ; tout le reste de cette fonction
# sert à ce que la preuve puisse la mesurer sans se suicider (cf. l'encadré de `sans_quitter`).
func _quitter() -> void:
	_quitte = true
	print("[accueil] CROIX ROUGE — fermeture du jeu demandée depuis l'accueil")
	if sans_quitter:
		print("[accueil] (mesure : la fermeture réelle est retenue — le jeu livré, lui, se ferme ici)")
		return
	if Lancement.app_directe() == "" and ResourceLoader.exists(CHEMIN_BUREAU):
		print("[accueil] retour au bureau CoccOs")
		get_tree().change_scene_to_file(CHEMIN_BUREAU)
	else:
		get_tree().quit()


# La touche Entrée ou la barre d'espace lancent aussi la partie : un clavier suffit, aucune souris n'est exigée.
# (B4) Et les touches ← → font ce que font les deux flèches — MÊME FONCTION, donc même plafond de progression :
# le clavier ne peut pas ouvrir un tableau que la souris n'ouvrirait pas.
func _unhandled_input(evt: InputEvent) -> void:
	if evt is InputEventKey and (evt as InputEventKey).pressed:
		var k := (evt as InputEventKey).keycode
		if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
			_jouer()
		# (LOGITHÈQUE, 01-10) ÉCHAP FAIT CE QUE FAIT LA CROIX ROUGE — même fonction, donc même sortie : on
		# revient au bureau. Un clavier suffit à quitter l'activité, aucune souris n'est exigée.
		elif k == KEY_ESCAPE:
			_quitter()
		elif k == KEY_LEFT:
			_changer_tableau(-1)
		elif k == KEY_RIGHT:
			_changer_tableau(1)
		# (B15) ET ↑ / ↓ FONT CE QUE FONT LES DEUX FLÈCHES DE LA PIÈCE — MÊME FONCTION, donc mêmes bornes : le
		# clavier ne peut pas atteindre une famille que la souris n'atteindrait pas.
		elif k == KEY_UP:
			_changer_pieces(1)
		elif k == KEY_DOWN:
			_changer_pieces(-1)


# ============================================================================================================
# CE QUE LE HARNAIS VIENT LIRE — rien ici ne CHOISIT à sa place : la preuve clique pour de vrai sur les cases et
# sur « JOUER » (`push_input`), et relit ensuite ce que l'accueil montre.
# ============================================================================================================
# (B23 · §31.1) LES NOMS DES TROIS EMPLACEMENTS, DANS L'ORDRE — écrit au journal à l'ouverture et rendu au
# harnais. C'est la ligne que Fabrice relit pour voir, sans rien déduire, que la Main est là au bureau et absente
# sur son téléphone.
func _noms_slots() -> Array:
	var n: Array = []
	for t in _slots:
		n.append(CurseursPuzzle.nom(t))
	return n


func etat_accueil() -> Dictionary:
	var noms: Array = []
	var vus: Array = []
	for i in CurseursPuzzle.TABLE.size():
		noms.append(CurseursPuzzle.nom(i))
		vus.append(CurseursPuzzle.texture(i) != null)
	var liseres: Array = []
	for l in _liseres:
		liseres.append(l != null and l.visible)
	# (B14 · §22) CE QUE LA PREUVE VIENT LIRE SUR LE MODE « SANS CURSEUR » : quelles cases n'ont pas de sprite, et
	# combien de glyphes « pointeur barré » sont RÉELLEMENT posés dans la page (comptés sur les nœuds, pas déduits).
	var sans: Array = []
	for i in CurseursPuzzle.TABLE.size():
		sans.append(CurseursPuzzle.sans_curseur(i))
	var barres := 0
	var glyphe: Array = []
	var glyphe_barre: Array = []
	if _racine != null:
		for n in _racine.get_children():
			if n is PointeurBarre:
				barres += 1
				# LA GÉOMÉTRIE DU GLYPHE, RAMENÉE À L'ÉCRAN — celle-là même que `_draw` a peinte, jamais un
				# second calcul : c'est ce qui laisse le contrôle de PIXELS mesurer la silhouette et non « du
				# blanc quelque part dans la case ».
				var g := PointeurBarre.geometrie((n as Control).size)
				if not g.is_empty():
					for p in (g["polygone"] as PackedVector2Array):
						glyphe.append((n as Control).position + p)
					glyphe_barre = [(n as Control).position + (g["barre_a"] as Vector2),
						(n as Control).position + (g["barre_b"] as Vector2), g["barre_large"],
						g["contour_large"]]
	return {
		"sans_curseur": sans,
		"sans_curseur_defaut": CurseursPuzzle.defaut(),
		# (B23 · §31.1) CE QUE CHAQUE EMPLACEMENT MONTRE, ET SUR QUELLE CIBLE — la preuve lit ces trois lignes au
		# lieu de redéduire la table. `slots` est une COPIE : le harnais ne peut pas modifier la page qu'il mesure.
		"android": CurseursPuzzle.android(),
		"defaut_plateforme": CurseursPuzzle.defaut(),
		"slots": _slots.duplicate(),
		"slots_noms": _noms_slots(),
		"nombre_images": CurseursPuzzle.nombre_images(),
		"pointeurs_barres": barres,
		"glyphe_polygone": glyphe,
		"glyphe_barre": glyphe_barre,
		"ecran": _ecran,
		"k": _k,
		"curseur": _curseur,
		"curseur_nom": CurseursPuzzle.nom(_curseur),
		"noms": noms,
		"textures_presentes": vus,
		"cases": _cases,
		"liseres_visibles": liseres,
		"bouton": _bouton,
		"titre": TITRE,
		"regle": REGLE_1 + " " + REGLE_2,
		"parti": _parti,
		# (B3 · PHASE 1) LA SORTIE — ⚠ `bouton_quitter` ET `libelle_quitter` ONT DISPARU AVEC LE BOUTON QU'ELLES
		# DÉCRIVAIENT (GDD §20.1) : un harnais qui les lit doit sortir ROUGE, c'est le signal qu'il mesure un écran
		# qui n'existe plus. On les remplace par ce que la croix, elle, peut prouver — sa boîte, sa forme, son rayon.
		"quitte": _quitte,
		"croix_quitter": _croix,
		"croix_ronde": _croix_bouton != null and _croix_bouton.get_node_or_null("CroixDessinee") != null,
		"croix_rayon": (float(int(_croix.size.x * 0.5)) if _croix.size.x > 0.0 else 0.0),
		"croix_tel": _tel,
		"croix_bulle": QUITTER_BULLE,
		# (PHASE 1) LE FOND, LE SON, LES COULEURS DE LA SIGNATURE — tout relu sur le RÉEL (le serveur audio, le
		# lecteur, les nœuds), jamais recopié d'une intention.
		"fond_pose": _fond_pose,
		"fond_chemin": FOND_VERDURE,
		"fond_taille": _fond_taille,
		"fond_echelle": _fond_echelle,
		"contour_texte": CONTOUR_TEL if _tel else CONTOUR,
		"volume": _volume,
		"volume_rect": _vol_rect,
		"volume_valeur": (_vol_curseur.value if _vol_curseur != null else -1.0),
		"volume_libelle": (_vol_libelle.text if _vol_libelle != null else ""),
		"volume_bus": SonPuzzle.BUS,
		"volume_bus_index": SonPuzzle.index_bus(),
		"volume_bus_db": SonPuzzle.volume_bus_db(),
		"volume_bus_muet": SonPuzzle.bus_muet(),
		"musique_chemin": SonPuzzle.MUSIQUE_ACCUEIL,
		"musique_joue": _musique != null and _musique.playing,
		"musique_boucle": _musique != null and (_musique.stream is AudioStreamMP3)
			and (_musique.stream as AudioStreamMP3).loop,
		"musique_bus": (_musique.bus if _musique != null else ""),
		"musique_db": (_musique.volume_db if _musique != null else 0.0),
		"jouer_fond": COL_JOUER,
		"jouer_lisere": COL_JOUER_TXT,
		"jouer_texte": COL_JOUER_TXT,
		# (B15 · §23 bis/ter/quater) LES FAMILLES — ce que le harnais vient lire pour prouver qu'on n'a pas
		# seulement AJOUTÉ des images, mais bien SÉPARÉ deux jeux d'images et deux progressions.
		"famille": _famille,
		"famille_cle": TableauxPuzzle.cle_famille(_famille),
		"famille_defaut": TableauxPuzzle.DEFAUT_FAMILLE,
		"familles": TableauxPuzzle.nombre_familles(),
		"familles_cles": _cles_familles(),
		"familles_pieces": _pieces_familles(),
		"familles_tableaux": _tableaux_familles(),
		"familles_fautes": TableauxPuzzle.verifier_familles(),
		"pieces": TableauxPuzzle.pieces_de_famille(_famille),
		"pieces_grille": [TableauxPuzzle.colonnes(_tableau), TableauxPuzzle.rangs(_tableau)],
		"piece_rect": _piece,
		"piece_dessinee": _racine != null and _racine.get_node_or_null("PieceNombre") != null,
		"piece_chiffre": (_racine.get_node_or_null("ChiffrePieces").text
			if (_racine != null and _racine.get_node_or_null("ChiffrePieces") != null) else ""),
		"piece_fleche_moins": _piece_fleche_g,
		"piece_fleche_plus": _piece_fleche_d,
		"piece_fleche_moins_visible": _piece_fleche_g_visible,
		"piece_fleche_plus_visible": _piece_fleche_d_visible,
		"piece_fleche_moins_noeud": _racine != null and _racine.get_node_or_null("FlechePiecesMoins") != null,
		"piece_fleche_plus_noeud": _racine != null and _racine.get_node_or_null("FlechePiecesPlus") != null,
		"rang": TableauxPuzzle.rang_dans_famille(_tableau),
		"rangs_famille": TableauxPuzzle.nombre_dans_famille(_famille),
		"plus_haut_famille": ProgressionPuzzle.plus_haut_famille(_famille),
		"plus_hauts_familles": _plus_hauts_familles(),
		"image_chemin": TableauxPuzzle.chemin_image(_tableau),
		"musique_chemin_tableau": TableauxPuzzle.chemin_musique(_tableau),
		# (B4) le sélecteur de tableau
		"tableau": _tableau,
		"tableau_nom": TableauxPuzzle.nom(_tableau),
		"tableaux": TableauxPuzzle.nombre(),
		"numero_affiche": str(TableauxPuzzle.rang_dans_famille(_tableau) + 1),
		"plus_haut": ProgressionPuzzle.plus_haut(),
		"modele": _modele,
		"modele_pose": _modele_pose,
		"modele_rapport": (_modele.size.x / _modele.size.y) if _modele.size.y > 0.0 else 0.0,
		"fleche_gauche": _fleche_g,
		"fleche_droite": _fleche_d,
		"fleche_gauche_visible": _fleche_g_visible,
		"fleche_droite_visible": _fleche_d_visible,
		"fleche_gauche_noeud": _racine != null and _racine.get_node_or_null("FlecheGauche") != null,
		"fleche_droite_noeud": _racine != null and _racine.get_node_or_null("FlecheDroite") != null,
		"numero": _numero,
		# (PHASE 3) LE COMPTE RENDU DE LA DISPOSITION DE FABRICE — GDD §20.3
		# ⚠ `disposition_poses` REND LES RECTANGLES **MESURÉS** APRÈS REPOSE, élément par élément et partie par
		#   partie : c'est ce qui permet à un harnais de comparer la place VOULUE (les fractions du fichier) à la
		#   place POSÉE, sans refaire le calcul de son côté — deux calculs jumeaux ne prouveraient rien.
		# ⚠⚠ ET `disposition_inconnues` EST LA CLÉ QUI COMPTE LE PLUS : une disposition « appliquée » avec trois clés
		#   perdues est un écran à moitié disposé, et ça ne se voit pas sur une capture. Elle doit rester VIDE.
		"disposition": _dispo,
		"disposition_cible": str(_dispo.get("cible", "")),
		"disposition_appliquee": bool(_dispo.get("appliquee", false)),
		"disposition_motif": str(_dispo.get("motif", "")),
		"disposition_elements": int(_dispo.get("elements", 0)),
		"disposition_parties": int(_dispo.get("parties", 0)),
		"disposition_inconnues": _dispo.get("inconnues", []),
		"disposition_hors_page": _dispo.get("hors_page", []),
		"disposition_absents": _dispo.get("absents", []),
		"disposition_poses": _dispo.get("poses", {}),
		"disposition_membres": _dispo.get("membres", {}),
		"disposition_quand": str(_dispo.get("quand", "")),
		# (§20.5) LA BOÎTE DE L'IMAGE DU MODÈLE — d'où elle vient pour LE TABLEAU AFFICHÉ, et la liste des tableaux
		# que la table cuite porte. Le harnais mesure les deux, il ne les croit pas.
		"disposition_modele_source": str(_dispo.get("modele_source", "")),
		"disposition_modeles_regles": _dispo.get("modeles_regles", []),
		"disposition_canvas_enregistre": _dispo.get("canvas_enregistre", Vector2.ZERO),
		"disposition_cibles_portees": DispositionAccueil.CIBLES.keys(),
	}


# ============================================================================================================
# (PHASE 1) CE QUE LE HARNAIS BALAIE POUR PROUVER QU'IL N'Y A **AUCUN VOILE** SUR LA VERDURE
# ============================================================================================================
# ⚠ POURQUOI UNE FONCTION ET NON UNE CLÉ DE PLUS : « pas de voile » est une propriété de l'ARBRE, pas d'une
#   variable. Publier un booléen `voile: false` ne prouverait rien — il dirait seulement que personne n'a mis à
#   jour le booléen. Ici on rend la LISTE des rectangles peints qui couvrent au moins 90 % du canvas avec un alpha
#   non nul, le bouchon à clics excepté (lui est transparent OU sous la photo). Si la liste n'est pas vide, il y a
#   un voile, et le harnais nomme le coupable.
# (B15) QUATRE PETITS RELEVÉS POUR LE HARNAIS — chacun lit la TABLE, jamais une liste recopiée : le jour où une
# famille s'ajoute, la preuve la mesure sans qu'on y touche.
func _cles_familles() -> Array:
	var a: Array = []
	for f in TableauxPuzzle.nombre_familles():
		a.append(TableauxPuzzle.cle_famille(f))
	return a


func _pieces_familles() -> Array:
	var a: Array = []
	for f in TableauxPuzzle.nombre_familles():
		a.append(TableauxPuzzle.pieces_de_famille(f))
	return a


func _tableaux_familles() -> Array:
	var a: Array = []
	for f in TableauxPuzzle.nombre_familles():
		a.append(TableauxPuzzle.tableaux_de_famille(f))
	return a


func _plus_hauts_familles() -> Array:
	var a: Array = []
	for f in TableauxPuzzle.nombre_familles():
		a.append(ProgressionPuzzle.plus_haut_famille(f))
	return a


func rectangles_couvrants() -> Array:
	var trouves := []
	if _racine == null:
		return trouves
	var seuil: float = 0.90 * _ecran.x * _ecran.y
	for n in _racine.get_children():
		if not (n is ColorRect):
			continue
		var cr := n as ColorRect
		if cr.color.a <= 0.0:
			continue
		if cr.size.x * cr.size.y < seuil:
			continue
		# Le bouchon est SOUS la photo : il ne voile rien tant que la photo est posée au-dessus de lui.
		if cr.name == "BouchonFond" and _fond_pose and cr.get_index() < _index_du_fond():
			continue
		trouves.append({"nom": str(cr.name), "couleur": cr.color, "boite": Rect2(cr.position, cr.size)})
	return trouves


func _index_du_fond() -> int:
	if _racine == null:
		return -1
	var f := _racine.get_node_or_null("FondVerdure")
	return f.get_index() if f != null else -1


# ============================================================================================================
# ============================================================================================================
# (B15 · §23 ter) LA PIÈCE DE PUZZLE DESSINÉE — le repère visuel du NOMBRE DE PIÈCES
# ============================================================================================================
# ⚠⚠ RECOPIÉE EN TOUTES LETTRES DEPUIS LE PUZZLE ADULTE (`le jeu du puzzle adulte/scripts/accueil.gd:1913-1954`,
#   classe `PieceDessinee`, §16.3) — mêmes fractions, même tenon à droite, même creux à gauche, même nombre de
#   segments. Fabrice a dit « ce qu'on a déjà utilisé » : la reproduction est la consigne, et la SOURCE est
#   nommée ici pour que la prochaine relecture puisse la comparer sans la chercher (règle 12 · SAVOIR).
# ⚠ AUCUN FICHIER N'EST EMPRUNTÉ À L'AUTRE JEU, ET C'EST LA RÈGLE §6 DE FABRICE : la pièce est DESSINÉE par ce
#   code-ci. Rien à copier dans `images/`, rien à ajouter aux quatre `export_files`, rien qui puisse manquer
#   dans un paquet en silence.
# ⚠ LE TENON SORT À DROITE ET LE CREUX RENTRE À GAUCHE : c'est ce qui la rend reconnaissable comme une pièce de
#   puzzle et non comme un carré aux coins mordus — et c'est aussi ce qui MANGE de la place au chiffre, sur toute
#   la profondeur du rayon (cf. le calcul de la police dans `_bloc_pieces`).
class PieceDessinee extends Control:
	var fond := Color(0.10, 0.13, 0.16, 0.42)
	var couleur_trait := Color(1.0, 1.0, 1.0, 0.92)
	var epaisseur := 3.0
	const CORPS := Rect2(0.08, 0.06, 0.78, 0.88)     # en fraction du côté
	const RAYON := 0.13                              # le rayon du tenon (et du creux), même fraction
	const PAS := 14                                  # segments par demi-cercle : au-delà, l'œil ne voit plus rien

	func _draw() -> void:
		var c: float = minf(size.x, size.y)
		if c <= 4.0:
			return
		var poly := _contour(c)
		draw_colored_polygon(poly, fond)
		var ferme := poly.duplicate()
		ferme.append(poly[0])
		draw_polyline(ferme, couleur_trait, maxf(1.0, epaisseur), true)

	# LE CONTOUR, DANS L'ORDRE : haut → droite (avec le tenon SORTANT) → bas → gauche (avec le creux RENTRANT).
	func _contour(c: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		var g: float = CORPS.position.x * c
		var d: float = (CORPS.position.x + CORPS.size.x) * c
		var h: float = CORPS.position.y * c
		var b: float = (CORPS.position.y + CORPS.size.y) * c
		var my: float = (h + b) * 0.5
		var r: float = RAYON * c
		p.append(Vector2(g, h))
		p.append(Vector2(d, h))
		p.append(Vector2(d, my - r))
		for i in range(PAS + 1):                     # le TENON : demi-cercle vers l'extérieur (+x)
			var a: float = -PI * 0.5 + PI * float(i) / float(PAS)
			p.append(Vector2(d + cos(a) * r, my + sin(a) * r))
		p.append(Vector2(d, my + r))
		p.append(Vector2(d, b))
		p.append(Vector2(g, b))
		p.append(Vector2(g, my + r))
		for i in range(PAS + 1):                     # le CREUX : demi-cercle vers l'intérieur (+x aussi, mais
			var a: float = PI * 0.5 - PI * float(i) / float(PAS)   # parcouru de bas en haut → il RENTRE
			p.append(Vector2(g + cos(a) * r, my + sin(a) * r))
		p.append(Vector2(g, my - r))
		return p


# LA CROIX — deux barres en X, épaisses (elles se voient de loin, sur un projecteur 4:3 comme sur un téléphone).
# Reprise à l'identique du 7 différences (`sept_differences.gd:8098-8101`, classe `IconeDessinee`, forme « croix »),
# via le jeu du puzzle adulte qui l'a reprise avant nous. ⚠ LA MARGE EST UNE **FRACTION** : les boutons n'ont pas
# tous la même taille (64 unités à la souris, 128 au doigt), une marge en pixels donnerait deux croix différentes.
# ============================================================================================================
class CroixDessinee extends Control:
	var couleur_trait := Color(0.08, 0.09, 0.14, 1.0)
	const MARGE := 0.16

	func _draw() -> void:
		var m: Vector2 = size * MARGE
		var z := Rect2(m, size - m * 2.0)
		if z.size.x <= 2.0 or z.size.y <= 2.0:
			return
		var c: Vector2 = z.get_center()
		var r: float = minf(z.size.x, z.size.y) * 0.40
		for d in [Vector2(1.0, 1.0).normalized(), Vector2(1.0, -1.0).normalized()]:
			draw_line(c - d * r, c + d * r, couleur_trait, r * 0.46)


# ============================================================================================================
# (B14 · §22) LE GLYPHE DE LA CASE « SANS CURSEUR » — UN POINTEUR BARRÉ, DESSINÉ, SANS AUCUN FICHIER
# ============================================================================================================
# ⚠⚠ POURQUOI IL EST DESSINÉ ET NON IMPORTÉ : un PNG neuf aurait dû entrer dans les QUATRE `export_files` des
#   préréglages, sinon la case serait AVEUGLE chez l'enfant et l'export sortirait VERT quand même (la leçon du 7
#   différences, repayée en B12 pour le logo du bouton). Un glyphe tracé au code n'a pas de manifeste : il est
#   dans le `.pck` parce que le script y est.
# ⚠ LES DEUX SIGNAUX DE LA CASE SONT DES FORMES, PAS DES TEINTES (CLAUDE.md, daltonien) : la silhouette du
#   pointeur, et la BARRE qui le raye. Le libellé « Sans curseur » l'écrit dessous, en toutes lettres.
# ⚠ LA BARRE EST DOUBLE — un trait CLAIR large, un trait SOMBRE dedans — et c'est de la lisibilité, pas du décor :
#   elle traverse à la fois le pointeur (clair) et le fond de la carte (sombre). D'une seule couleur, elle
#   disparaîtrait sur l'un ou sur l'autre.
# ⚠ TOUT EST EN FRACTIONS de la boîte : la case n'a pas la même taille à la souris, au projecteur et au doigt
#   (`_k`), et un tracé en pixels aurait donné trois glyphes différents.
# ⚠⚠ LE GLYPHE N'A QU'UNE GÉOMÉTRIE (`geometrie`), PARTAGÉE PAR LE DESSIN ET PAR LA PREUVE — c'est le patron de
#   la flèche du bouton PRENDRE/POSER (§21 bis) : deux calculs jumeaux, l'un pour peindre et l'autre pour
#   mesurer, finissent par diverger, et le rouge tombe alors sur un jeu juste.
class PointeurBarre extends Control:
	var couleur_clair := Color(0.94, 0.95, 0.97, 1.0)      # `COL_TEXTE` : le glyphe se lit comme un écrit
	var couleur_sombre := Color(0.08, 0.09, 0.14, 1.0)
	const MARGE := 0.16
	# LA SILHOUETTE DU POINTEUR, pointe en HAUT À GAUCHE — le pointeur que l'enfant ne verra justement pas.
	const POINTEUR := [Vector2(0.02, 0.00), Vector2(0.02, 0.74), Vector2(0.24, 0.55),
		Vector2(0.38, 0.94), Vector2(0.53, 0.87), Vector2(0.39, 0.49), Vector2(0.64, 0.46)]

	# LA GÉOMÉTRIE, DANS LE REPÈRE DU NŒUD. Rendue à la preuve telle que le pinceau la reçoit.
	static func geometrie(taille: Vector2) -> Dictionary:
		var m: Vector2 = taille * MARGE
		var z := Rect2(m, taille - m * 2.0)
		if z.size.x <= 6.0 or z.size.y <= 6.0:
			return {}
		var cote: float = minf(z.size.x, z.size.y)
		var o: Vector2 = z.get_center() - Vector2(cote, cote) * 0.5
		var pts := PackedVector2Array()
		for v in POINTEUR:
			pts.append(o + (v as Vector2) * cote)
		return {"polygone": pts, "cote": cote, "contour_large": maxf(cote * 0.03, 1.0),
			"barre_a": o + Vector2(0.06, 0.94) * cote, "barre_b": o + Vector2(0.94, 0.06) * cote,
			"barre_large": maxf(cote * 0.16, 3.0)}

	func _draw() -> void:
		var g := geometrie(size)
		if g.is_empty():
			return
		var pts: PackedVector2Array = g["polygone"]
		var cote: float = g["cote"]
		draw_colored_polygon(pts, couleur_clair)
		var ferme := pts.duplicate()
		ferme.append(pts[0])
		draw_polyline(ferme, couleur_sombre, g["contour_large"])
		# LA BARRE : de bas-gauche à haut-droite, tout en travers de la boîte. Elle est DOUBLE (cf. l'encadré) :
		# un trait clair large, un trait sombre dedans — elle traverse le pointeur clair ET le fond sombre.
		draw_line(g["barre_a"], g["barre_b"], couleur_clair, g["barre_large"])
		draw_line(g["barre_a"], g["barre_b"], couleur_sombre, maxf(cote * 0.09, 2.0))

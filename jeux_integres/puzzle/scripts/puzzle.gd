extends Node2D

# ============================================================================================================
# LE JEU DES PUZZLES — LE CŒUR JOUABLE (PUZZLE-B1, REQ_260814_PUZZLE_B1_puzzle_jouable)
#                       + LE ZOOM, LES SUGGESTIONS ET LE RESPONSIVE (PUZZLE-B2, REQ_260814_PUZZLE_B2)
#
# Ce fichier fait TOUT le jeu : il découpe l'image en quinze vraies pièces, les éparpille, les laisse prendre à
# la souris et au doigt, les emboîte quand elles se rejoignent, et joue la fête quand l'image est refaite.
# Rien à assembler dans un `.tscn` : la scène ne porte qu'un nœud, et le jeu se construit lui-même — même
# doctrine que le jeu des 7 différences, dont ce projet est le FRÈRE (et non un morceau : cf. `project.godot`).
#
# LES QUATRE DÉCISIONS DE FABRICE QUI COMMANDENT CE FICHIER (14-08, mot pour mot) :
#   ① « L'essai avec l'image que je propose, en quinze pièces. »          → `_cols` × `_rangs` = 15 (3 × 5 sur
#      la ferme, 5 × 3 sur les porcelets depuis B4 : la grille suit la forme du dessin, cf. l'encadré B4).
#      ⚠ POURQUOI 3 × 5 ET NON 5 × 3 (correction B1b) : le premier passage de B1 avait découpé une CAPTURE
#      D'ÉCRAN de 1024 × 768 attrapée par erreur à la place du dessin. Le VRAI dessin de la ferme est
#      956 × 1120 — un PORTRAIT. Quinze pièces ne se posent que sur 3 × 5 ou 5 × 3 : la cellule vaut
#      318,7 × 224 (rapport 1,42) dans un cas, 191,2 × 373,3 (rapport 0,51) dans l'autre. La première est de
#      loin la mieux proportionnée — c'est celle-là. Le « 1024 × 768 » du premier brief n'était donc pas une
#      décision de Fabrice, c'était le mauvais fichier ; rien de sa volonté n'est touché ici.
#   ② « Des vraies formes de puzzle (…) l'image très claire, généralisée, de la forme d'une pièce de puzzle. »
#      → §« LA FORME D'UNE PIÈCE » ci-dessous : tête ronde, COL PLUS ÉTROIT QUE LA TÊTE (contre-dépouille),
#        deux congés tangents. C'est la géométrie qui fait qu'une pièce s'ACCROCHE au lieu de se poser.
#   ③ « Un seul [récompense] (une seule image). Et après la cinématique de la récompense, c'est l'image
#      affichée en plein écran. »                                        → `_lancer_recompense` → `_plein_ecran`.
#   ④ « Chaque jeu doit avoir ses propres contenus, on copie les contenus. » → tous les `res://` de ce fichier
#      sont des fichiers RÉELS de CE projet ; aucun ne sort de `le jeu des puzzles/`. Le harnais le mesure.
#
# ============================================================================================================
# CE QUE B2 AJOUTE — ET CE QU'IL NE TOUCHE PAS
# ============================================================================================================
# B2 AJOUTE quatre choses, et rien du jeu de B1 n'est défait (brief §7) : la découpe, les quinze pièces,
# l'aimantation, la récompense et le plein écran final sont le code de B1, ligne pour ligne.
#   ⑤ LE CURSEUR EST CELUI QUE L'ENFANT A CHOISI (brief §1). Le choix se fait sur l'ACCUEIL, qui est une scène à
#      part (`scenes/accueil.tscn`) ; il voyage jusqu'ici par le réglage `CurseursPuzzle`. Lancé seul — au
#      harnais, ou en essai — ce fichier prend le dernier choix connu, ou la coccinelle : le comportement exact
#      de B1.
#   ⑥ LE ZOOM (brief §2) : molette au bureau, pincement à deux doigts au tactile. Il agit sur le NŒUD `_jeu` —
#      donc sur le plateau ET les pièces ensemble — et les événements de souris sont retraduits en coordonnées
#      de jeu avant d'être traités. C'est ce qui fait que ni la prise, ni le glisser, ni l'aimantation ne
#      changent d'un iota quand on zoome : elles continuent de travailler dans le repère du plateau. Le panneau
#      (modèle réduit, compte, aide) vit sur un `CanvasLayer` et ne zoome PAS : un repère qui grossit avec la
#      vue n'est plus un repère.
#   ⑦ LES SUGGESTIONS TOUTES LES 15 s (brief §3) : la BONNE PLACE d'une pièce encore à poser clignote sur le
#      plateau, par PULSATION DE LUMINANCE et liseré clair — jamais par la couleur seule (CLAUDE.md, daltonien).
#      (B7 : la PIÈCE clignote maintenant elle aussi, en anti-phase avec sa place — cf. l'encadré B7 plus bas.)
#   ⑧ LE RESPONSIVE 4 CIBLES (brief §4) : plus une seule position en pixels absolus. Tout se déduit du canvas
#      RÉEL — cf. l'encadré « LA MISE EN PAGE SE DÉDUIT DU CANVAS ».
# ============================================================================================================
# CE QUE B3 AJOUTE (REQ_260814_PUZZLE_B3_victoire_navigation · GDD §7.9 et §7.10) — et rien de B1/B2 n'est défait
# ============================================================================================================
#   ⑨ LA PETITE MAISON, DANS LE PUZZLE (GDD §7.9). « Il faut une petite maison pour revenir à l'accueil, sans
#      cacher le jeu, comme la sortie du 7 différences, en coin. » Elle vit DANS LE PANNEAU — son coin haut-droit
#      en paysage, le bout droit du bandeau en portrait. C'est ce qui garantit « sans cacher le jeu » au sens
#      fort : le panneau n'est pas l'aire de jeu, aucune pièce ne s'y pose JAMAIS (la couronne est calculée dans
#      `_zone`, qui exclut le panneau). Poser la maison dans un coin de l'ÉCRAN aurait été plus simple et faux :
#      en portrait, ce coin-là est une place de pièce.
#   ⑩ LE TABLEAU EST UN PARAMÈTRE (brief §3). Le jeu ne connaît plus « l'image » : il connaît le tableau courant
#      et lui demande son image ET sa musique (`scripts/tableaux_puzzle.gd`). Ajouter le 2ᵉ tableau se fera en
#      ajoutant une ligne à cette table — pas une ligne ici. (Le 2ᵉ tableau et son sélecteur sont HORS de cette
#      balle : brief §5.)
#   ⑪ L'ÉCRAN DE VICTOIRE (GDD §7.10, mot pour mot). PENDANT LE PUZZLE, AUCUNE MUSIQUE — silence : rien n'est
#      chargé, rien ne joue, et le harnais le mesure. À la fin : la récompense coccos (B1) → l'image complète en
#      plein écran (B1) → LA MUSIQUE DU TABLEAU, UNE FOIS. Pendant qu'elle passe, un bouton STOP À DROITE,
#      TRIANGLE ROUGE, l'arrête. Une fois la musique finie OU stoppée, DEUX boutons apparaissent : REJOUER (la
#      flèche tournante, le logo de rejeu de la fratrie CoccOs, COPIÉ ici en code — cf. `IconeDessinee`) et la
#      PETITE MAISON. Rejouer = le MÊME tableau, avec un NOUVEAU mélange des quinze pièces.
#   ⚠ LE SEUL SON DU JEU AVANT LA VICTOIRE RESTE CELUI DE LA RÉCOMPENSE (B1, `audio/recompense_coccos.mp3`) :
#     c'est le chant de la fête, pas une musique de fond — il arrive APRÈS la dernière pièce. « Pendant le
#     puzzle » se lit donc au pied de la lettre : entre le lancement et la quinzième pièce, le jeu est muet.
# ============================================================================================================
# CE QUE B4 AJOUTE (REQ_260814_PUZZLE_B4_deuxieme_tableau_selecteur · GDD §7.11) — deux lignes de vie, pas plus
# ============================================================================================================
#   ⑫ LA GRILLE VIENT DU TABLEAU (cf. l'encadré « POURQUOI `COLS` ET `RANGS` ONT CESSÉ D'ÊTRE DES CONSTANTES »).
#      C'est tout ce qu'il a fallu pour que le 2ᵉ tableau — un dessin COUCHÉ, quand la ferme est DEBOUT — se
#      taille en quinze pièces bien proportionnées. Le plateau, la couronne, les quinze places, le modèle réduit
#      et le plein écran se déduisaient déjà du canvas et du rapport de l'image depuis B2 : ils suivent seuls.
#   ⑬ GAGNER UN TABLEAU DÉBLOQUE LE SUIVANT (`ProgressionPuzzle`, écrit dans `user://`). Le jeu ne fait qu'une
#      chose de plus à la victoire : noter le plus haut tableau atteint. C'est l'ACCUEIL qui en tire le
#      sélecteur ◀ [n°] ▶ et sa flèche de droite invisible tant que rien n'est débloqué.
#   ⚠ RIEN D'AUTRE N'A BOUGÉ : la forme des pièces, l'aimantation, le zoom, les suggestions, la maison, l'écran
#     de victoire et son STOP sont le code de B1/B2/B3, ligne pour ligne. Le harnais de B4 les remesure tous.
# ============================================================================================================
# CE QUE B6 REFOND (REQ_260814_PUZZLE_B6_refonte_mise_en_page_camera · GDD §10 et §10 bis) — L'IMAGE ÉTAIT TROP
# PETITE, ET C'EST LA COURONNE QUI LA RAPETISSAIT
# ============================================================================================================
# Fabrice, mot pour mot : « le positionnement qui a été fait de me les mettre tout autour réduit considérablement
# la taille de l'image ». La couronne de B1/B2 coûtait DEUX BOÎTES DE PIÈCE de chaque côté du plateau — soit,
# sur la ferme, 888 unités d'image en largeur et 805 en hauteur PRISES SUR L'IMAGE. B6 la supprime.
#
#   ⑭ LES PIÈCES SONT EN TAS, EMPILÉES, SOUS LE MODÈLE (GDD §10). « Nous tricherons, nous les mettrons en vrac,
#      certaines seront par-dessus d'autres. Ce sera au joueur de disposer les pièces pour arriver à voir
#      lesquelles sont en dessous. » Le chevauchement n'est donc PAS un défaut à corriger : c'est ce qui libère
#      la place. Le tas se pose dans la RÉSERVE (l'ancien panneau), sous le modèle, et il n'y a plus UN SEUL
#      ÉCRIT sous le modèle — « en dessous de l'image modèle, je ne veux aucun écrit » : le compte remonte sur la
#      ligne du haut, l'aide en toutes lettres disparaît (les gestes s'apprennent en jouant, pas en lisant).
#   ⑮ L'ÉCHELLE N'EST PLUS PLAFONNÉE QUE PAR LE PLATEAU. Une seule ligne remplace le calcul de couronne et sa
#      boucle de rattrapage — et le plateau passe de 334 × 392 à 636 × 745 sur l'écran de référence : **3,6 fois
#      plus de surface**, pièces comprises (la boîte d'une pièce passe de 155 × 141 à 295 × 268).
#   ⑯ LE DÉZOOM N'EST PLUS LIMITÉ (GDD §10 bis). « Pour avoir de la place pour ranger les pièces, le joueur va
#      dézoomer, reculer la caméra et faire des petits tas. Surtout qu'il ne soit pas limité dans le dézoom. »
#      Le plancher 1,0 de B2 saute ; ce qui le remplace n'est pas une borne de jeu mais un PLAN DE TRAVAIL qui
#      SUIT les pièces (cf. `_plan_travail`) : plus le joueur écarte ses tas, plus le plan grandit.
#   ⑰ ET UN RETOUR : « quand il veut revoir son puzzle, il retrouve l'image qu'il a eue au départ, aussi grande
#      que possible » → le bouton RECADRER (et la barre d'espace) rend la vue de départ, au plus grand.
#   ⑱ DOUBLE-CLIC SUR LE MODÈLE → PLEIN ÉCRAN, double-clic à nouveau → retour (GDD §10).
#   ⑲ PENSÉ POUR 100+ PIÈCES DÈS MAINTENANT (GDD §10 bis, la demande la plus structurante de la balle) : plus
#      une seule constante ne suppose quinze. L'échelle ne dépend PAS du nombre de pièces (le plateau seul la
#      commande), le tas est une spirale d'or qui se resserre quand le nombre monte, et le plan de travail suit
#      les pièces. Le harnais monte le MÊME tableau en 10 × 10 = CENT pièces et remesure tout.
#   ⚠ CE QUI N'EST PAS DÉFAIT : la découpe, la forme des pièces, l'aimantation, les suggestions, la maison,
#     l'écran de victoire, les musiques, les deux tableaux, la progression. B6 ne touche QUE la mise en page,
#     la caméra et le modèle. Le harnais de B6 remesure B1 → B5 dans la foulée.
# ============================================================================================================
# CE QUE B7 CHANGE (REQ_260814_PUZZLE_B7_suggestion_piece_place_antiphase · GDD §11 et §11 bis) — LA SUGGESTION
# MONTRE LA PIÈCE **ET** SA PLACE, EN ANTI-PHASE. UNE SEULE CHOSE BOUGE : L'EFFET VISUEL DE LA SUGGESTION.
# ============================================================================================================
# Le constat de Fabrice après essai, mot pour mot : « ça a clignoté dans l'image en construction, mais je pensais
# que ça allait clignoter sur une pièce visible ; je n'ai pas vu de pièce clignoter. J'ai trouvé la pièce en
# regardant seulement la forme. L'ENFANT NE VA PAS JOUER COMME ÇA. » Le cadre blanc de B2 autour de la pièce ne
# suffisait pas : dans un TAS (B6), un mince rectangle clair sur une pièce à demi enfouie ne se voit pas.
#
#   ⑳ LA PIÈCE CLIGNOTE, ELLE AUSSI, ET DANS SA VRAIE FORME. Ce n'est plus un rectangle englobant mais le
#      CONTOUR EXACT de la pièce, rempli et cerné, posé PAR-DESSUS TOUT (son propre calque, remonté au sommet à
#      chaque image). L'enfant voit « CETTE pièce-là », même si elle est à demi couverte.
#   ㉑ ET ELLE REMONTE SUR LE TAS pendant la suggestion (décision de Code, exposée au brief §1). Montrer une
#      pièce enfouie et la laisser dessous, ce serait désigner ce qu'on ne peut pas attraper. Elle passe donc au
#      sommet de la pile — et elle Y RESTE après le clignotement : la remettre dessous au moment précis où
#      l'enfant tend la main serait lui reprendre l'aide qu'on vient de lui donner.
#   ㉒ LES DEUX BATTENT EN **ANTI-PHASE** (GDD §11 bis, mot pour mot) : « les deux clignotements battent sur le
#      même rythme, mais quand l'une s'allume, l'autre s'éteint. Ça donne un effet d'œil que l'un va vers
#      l'autre, et vice versa. C'est encore plus fort qu'un clignotement simple synchrone — QUE JE NE VEUX PAS,
#      C'EST L'INVERSE. » D'où une seule sinusoïde pour les deux : `u` pour la pièce, `1 − u` pour la place.
#      Pas deux horloges (elles dériveraient), pas un décalage en secondes (il dépendrait de la période) : LA
#      MÊME, retournée. L'opposition est alors exacte par construction, à toute image et à toute fréquence.
#   ㉓ RAPIDE ET ROUGE. La pulsation passe de 1,2 s à 0,45 s — « rapide » — et la teinte est le ROUGE que
#      Fabrice a retenu (« ça attirait bien l'œil »).
#      ⚠ LE ROUGE EST UN BONUS, JAMAIS LE MESSAGE : ce qui clignote reste une PULSATION DE LUMINANCE doublée
#        d'un liseré épais (alpha 0,05 → 0,72). Un daltonien lit l'alternance comme un autre — `CLAUDE.md`.
#   ⚠ CE QUI NE CHANGE PAS : les 15 s, la remise à zéro dès qu'une pièce est posée, l'effacement au bout de 6 s,
#     et le CHOIX de la pièce (une pièce encore à poser, voisine du plus gros bloc). B7 ne touche QUE l'effet.
# ============================================================================================================
# CE QUE B8 AJOUTE (REQ_260814_PUZZLE_B8_bouton_niveau_suivant · GDD §12) — UN TROISIÈME BOUTON SUR L'ÉCRAN DE
# FIN : « NIVEAU SUIVANT ». RIEN N'EST RETIRÉ — REJOUER, LA MAISON, LE STOP, LA MUSIQUE ET L'IMAGE SONT INTACTS.
# ============================================================================================================
# Fabrice, après essai, mot pour mot : « Après l'image musicale, on a l'affichage : Rejouer, ou aller à l'accueil.
# **Devrait rajouter niveau suivant** — comme dans le jeu des sept différences, **la flèche avec le plus**. »
#
#   ㉔ LE 3ᵉ BOUTON, ET IL MÈNE DROIT AU TABLEAU SUIVANT (`_niveau_suivant`). Pas de détour par l'accueil : un
#      enfant qui vient de gagner veut la suite, pas un menu. C'est la MÊME mécanique que REJOUER — on remonte
#      une scène de jeu NEUVE dans son propre parent puis on se retire — avec un seul chiffre de différence :
#      `tableau + 1`. Rien de la partie qui s'achève ne peut donc survivre dans celle qui commence.
#   ㉕ IL N'EXISTE QUE S'IL Y A UNE SUITE, ET SA PLACE N'EST PAS RÉSERVÉE (décision de Fabrice, GDD §12 : sur le
#      dernier tableau, le bouton est ABSENT — « mêmes règles que la flèche droite absente à l'accueil »). Ce
#      n'est donc pas un bouton grisé : l'écran de fin porte DEUX boutons au dernier tableau et TROIS ailleurs,
#      et les boutons restent CENTRÉS dans les deux cas (`cadre_bouton_fin`, un seul calcul pour les trois).
#      ⚠ ET LA QUESTION SE POSE UNE SEULE FOIS, À L'INSTANT DE LA VICTOIRE (`_suivant_offert`, posé dans
#        `_gagne`) — pas à chaque appel des rectangles. Sans ce gel, une progression qui bougerait entre la pose
#        de REJOUER et celle de la MAISON changerait le nombre de boutons EN COURS de mise en page : les deux
#        premiers boutons se poseraient centrés pour deux, le troisième pour trois. On lit le disque une fois.
#      ⚠ LA QUESTION EST POSÉE À `ProgressionPuzzle.suivant_ouvert()` — EXACTEMENT la fonction qui commande la
#        flèche ▶ de l'accueil. C'est ce qui interdit aux deux écrans de se contredire : un bouton qui mènerait
#        à un tableau que l'accueil montre encore fermé serait une porte dérobée. Comme `_gagne` écrit la
#        progression AVANT (㊀ de B4), la réponse est « oui » dès qu'un tableau suivant existe.
#   ㉖ LA FLÈCHE AVEC LE PLUS — la forme demandée, RECOPIÉE POINT PAR POINT dans ce projet (`FLECHE_SUIVANT` +
#      `IconeDessinee._suivant_plus`), jamais empruntée par une ancre : « chaque jeu ses contenus » (GDD §6).
#      Ce que la forme dit à un enfant de quatre ans : la FLÈCHE dit « avance », le « + » à sa droite dit « un de
#      plus » = un tableau de plus. Deux signes séparés valent mieux qu'un symbole composé que personne n'a
#      jamais vu. Et le mot « Suivant » les double sous le bouton, comme « Rejouer » et « Accueil ».
#      ⚠ NI ROUGE NI VERT, ET C'EST LA SOURCE QUI TRANCHE : le brief annonçait « rouge/vert selon le style du 7
#        différences ». Relu dans la fratrie, ce bouton-là n'a AUCUNE teinte propre — fond clair, glyphe sombre,
#        le même habillage que son voisin REJOUER (le vert, dans l'autre jeu, appartient au bouton « passer le
#        tutoriel », qui ne prête que sa GÉOMÉTRIE). On copie donc ce qui est, pas ce qu'on croyait : les trois
#        boutons de la fin sont frères, et le sens tient par la FORME et la LUMINANCE (CLAUDE.md, daltonien).
# ⚠ CE QUI N'EST PAS DÉFAIT : la découpe, l'aimantation, le tas, la caméra, les suggestions en anti-phase, la
#   maison, le recadrage, le STOP, la musique une fois, REJOUER (même tableau, remélangé), la maison de fin et la
#   progression. B8 n'ajoute QU'UN bouton et son chemin. Le harnais de B8 remesure B1 → B7 dans la foulée.
# ============================================================================================================

# ------------------------------------------------------------------------------------------------------------
# LA DÉCOUPE
# ------------------------------------------------------------------------------------------------------------
# (B3) L'image ne s'écrit plus ici : elle appartient au TABLEAU (cf. `scripts/tableaux_puzzle.gd`, ⑩).
# (B4) ET LA GRILLE NON PLUS — pour la raison qui suit, et elle n'est pas un détail de rangement.
#
# ⚠⚠ POURQUOI `COLS` ET `RANGS` ONT CESSÉ D'ÊTRE DES CONSTANTES (B4). Quinze pièces se posent sur 3 × 5 ou sur
#   5 × 3, et le bon choix dépend de la FORME DU DESSIN, pas du jeu : la ferme est un portrait (3 × 5, cellule
#   presque carrée), les porcelets un paysage (5 × 3). Garder la grille dans ce fichier aurait taillé le paysage
#   en cinq lamelles hautes — des pièces qu'un enfant ne reconnaît plus. Le calcul du choix, chiffres à l'appui,
#   vit dans `tableaux_puzzle.gd` (encadré « POURQUOI LA GRILLE APPARTIENT AU TABLEAU ») : ici, on la LIT.
#   Le NOMBRE de pièces, lui, ne bouge pas : quinze aux deux tableaux — c'est la demande de Fabrice.
#   ⚠ Ces deux valeurs sont posées UNE FOIS, dans `_ready`, avant tout calcul ; rien ensuite ne les change (pas
#     même un redimensionnement). Elles se lisent donc comme les constantes qu'elles remplacent.
var _cols := 3                         # colonnes de la grille du TABLEAU COURANT (3 pour la ferme, 5 pour les porcelets)
var _rangs := 5                        # rangs de cette même grille (5 · 3) — le produit vaut toujours 15
const GRAINE := 20260814               # graine FIXE : la découpe et l'éparpillement sont les MÊMES à chaque
                                       # lancement. Un puzzle qui change de forme à chaque partie ne se
                                       # reconnaît pas, et une preuve qui change de sujet ne prouve rien.

# ============================================================================================================
# LA FORME D'UNE PIÈCE — « la forme très claire, généralisée, de la pièce de puzzle » (Fabrice, 14-08)
# ============================================================================================================
# Un bord de pièce n'est pas un trait : c'est une ligne droite, puis une TÊTE RONDE portée par un COL PLUS
# ÉTROIT QU'ELLE, puis la droite à nouveau. C'est cette différence-là — col plus étroit que tête — qui fait la
# CONTRE-DÉPOUILLE : la tête, une fois entrée, ne peut plus ressortir tout droit. Sans elle on dessinerait une
# bosse, pas une pièce de puzzle.
#
# Tout se calcule dans un repère local au bord : `t` court de 0 à 1 le long du bord, `h` s'en écarte
# perpendiculairement ; les deux sont en FRACTIONS DE LA LONGUEUR du bord, donc la même forme habille un bord
# horizontal (318,7 px) et un bord vertical (224 px) sans se déformer.
#
#   • la TÊTE est un cercle plein : centre (0,5 · `KNOB_CY`), rayon `KNOB_R` ;
#   • le COL est l'écartement des deux points où la forme quitte la droite : 0,5 ± `KNOB_W` ;
#   • entre les deux, DEUX CONGÉS (petits cercles) tangents À LA FOIS à la droite et à la tête. Leur rayon
#     n'est pas un réglage : il est IMPOSÉ par les trois autres nombres. En posant le centre du congé en
#     (0,5 − `KNOB_W`, r) — c'est la tangence à la droite — et la tangence EXTÉRIEURE à la tête
#     (distance des centres = `KNOB_R` + r), il vient :
#
#           KNOB_W² + (KNOB_CY − r)² = (KNOB_R + r)²   ⇒   r = (KNOB_W² + KNOB_CY² − KNOB_R²) / (2·(KNOB_R + KNOB_CY))
#
#     Avec les valeurs ci-dessous : r ≈ 0,0179. La courbe est donc CONTINUE et TANGENTE partout — aucun angle
#     mort, aucun raccord bricolé, et la tête déborde du col de 0,135 − 0,085 = 0,05 de chaque côté.
#   • hauteur totale de la languette : `KNOB_CY` + `KNOB_R` = 0,28 de la longueur du bord (≈ 89 px d'image sur
#     un bord horizontal, ≈ 63 px sur un vertical) — bien visible, jamais mesquine.
#     ⚠ ET C'EST LE CHIFFRE QUI A PIÉGÉ LE HARNAIS EN B1b : sur ces cellules-là (318,7 × 224) un creux de bord
#     horizontal descend de 89 px dans une cellule qui n'en fait que 224 de haut — soit 40 % de sa hauteur.
#     Rien à corriger dans le jeu (les aires se compensent au pixel carré près, §② de la preuve), mais toute
#     mesure qui lit « un peu au-dessus du centre d'une pièce » doit vérifier qu'elle ne lit pas dans le vide.
#
# ⚠⚠ ET LE POINT QUI REND LES VOISINES COMPLÉMENTAIRES PAR CONSTRUCTION, PAS PAR CHANCE : un bord intérieur est
#   calculé UNE SEULE FOIS, et les DEUX pièces qui le partagent réemploient LA MÊME polyligne — l'une à
#   l'endroit, l'autre à l'envers. Il n'existe donc pas de version « à peu près pareille » du bord : là où l'une
#   bombe, l'autre creuse, au point près. Le harnais ne fait pas que le croire : il compare les deux listes de
#   points (§③) et il mesure que la somme des aires des 15 pièces fait EXACTEMENT l'aire de l'image (§②) — ce qui
#   ne peut arriver que si chaque languette est payée par un creux de même taille.
# ============================================================================================================
const KNOB_R := 0.135                  # rayon de la tête
const KNOB_CY := 0.145                 # hauteur du centre de la tête
const KNOB_W := 0.085                  # DEMI-largeur du col — plus petite que le rayon : c'est la contre-dépouille
const PAS_TETE := 44                   # points échantillonnés sur la tête (292° d'arc) — rond à l'œil
const PAS_CONGE := 8                   # points sur chacun des deux congés (146° d'arc chacun)
const LANGUETTE := KNOB_CY + KNOB_R    # 0,28 — de combien une pièce DÉBORDE de sa cellule, en fraction du bord

# ============================================================================================================
# (B2) LA MISE EN PAGE SE DÉDUIT DU CANVAS — L'UNIQUE ENDROIT DU FICHIER QUI DÉCIDE OÙ LES CHOSES SONT
# ============================================================================================================
# ⚠⚠ CE QUE B2 REMPLACE, ET POURQUOI IL LE FAUT. B1 écrivait la mise en page en PIXELS : échelle 0,35, plateau
#   centré en (400, 384), panneau à x = 800, et quinze places de départ listées une à une. Ces nombres étaient
#   justes — pour 1024 × 768, et pour lui seul. Le brief §4 demande les QUATRE cibles (projecteur 4:3, portable
#   16:9, Android, iOS) : sur un canvas plus large, le panneau de B1 se serait retrouvé au milieu de l'écran
#   avec 340 px de vide à sa droite, et sur un canvas plus haut les pièces du bas seraient sorties du cadre.
#
# CE QUI EST CALCULÉ, DANS CET ORDRE, ET POURQUOI CHAQUE ÉTAPE EST CONTRAINTE :
#
#   ① LE PANNEAU (modèle réduit + compte + aide) prend un côté, et LEQUEL dépend de la forme de l'écran :
#      À DROITE quand l'écran est couché (rapport ≥ 1,1) — c'est la disposition de B1 ; EN BAS quand il est
#      carré ou debout, parce qu'une colonne de 200 px prise sur la largeur d'un téléphone tenu debout ne
#      laisserait pas de quoi poser le plateau. Sa taille suit le canvas (21,9 % de la largeur, bornée à
#      [200, 300] ; 20 % de la hauteur en portrait, bornée à [150, 260]).
#
#   ② L'ÉCHELLE DU PUZZLE N'EST PAS PLAFONNÉE PAR LE PLATEAU, MAIS PAR LA COURONNE. C'est le point qui ne se
#      devine pas, et il vient de B1 : les pièces s'éparpillent AUTOUR du plateau, donc il faut qu'une BOÎTE DE
#      PIÈCE ENTIÈRE tienne de chaque côté. Une boîte de pièce, ce n'est pas une cellule : c'est la cellule PLUS
#      ses languettes, qui débordent de 0,28 de la longueur du bord OPPOSÉ —
#           boîte = (cellule.x + 2 × 0,28 × cellule.y ; cellule.y + 2 × 0,28 × cellule.x) = 444,1 × 402,4 (image)
#      d'où, pour que le plateau plus deux boîtes tiennent en largeur ET en hauteur :
#           échelle = 0,877 × min( zone.largeur / (image.x + 2 × boîte.x) ; zone.hauteur / (image.y + 2 × boîte.y) )
#      Le 0,877 est une MARGE DE RESPIRATION, et sa valeur n'est pas arbitraire : c'est exactement celle qui rend
#      l'échelle de B1 (0,350) sur l'écran de B1 (1024 × 768). Le responsive ne change donc RIEN à ce que Fabrice
#      a déjà vu, il l'étend aux autres écrans. Sur 16:9 et sur Android, c'est la HAUTEUR qui commande (le dessin
#      est un portrait) : le plateau y garde sa taille et c'est la couronne qui s'élargit.
#
#   ③ LES QUINZE PLACES DE DÉPART ne sont plus listées : elles sont RÉPARTIES dans la couronne — colonnes à
#      gauche et à droite, lignes en haut et en bas — en autant d'exemplaires que la couronne peut en tenir
#      SANS QUE DEUX BOÎTES SE RECOUVRENT. Sur 1024 × 768 le calcul retombe sur la répartition de B1 (3 à
#      gauche, 3 à droite, 4 en haut, 5 en bas) à quelques pixels près ; ailleurs il s'adapte tout seul.
#      ⚠ LA GARDE `GARDE_COURONNE` EXISTE POUR UN CAS PRÉCIS : sans elle, la première place d'une colonne
#      latérale et la place d'angle de la ligne du haut se recouvrent de 3,7 px — mesuré, pas supposé. Elle
#      écarte les colonnes de 8 unités (à l'échelle) et le recouvrement disparaît.
#
#   ④ LA TOLÉRANCE D'AIMANTATION SUIT L'ÉCHELLE, elle aussi : 19 % de la diagonale d'une cellule à l'écran, ce
#      qui rend 25,9 px sur 1024 × 768 — les 26 px de B1. Une tolérance en pixels fixes serait devenue trop
#      lâche sur un grand écran (les pièces s'y colleraient de loin) et trop serrée sur un petit.
# ============================================================================================================
# ============================================================================================================
# ⚠⚠⚠ ET CE QUE **B6** REMPLACE DANS TOUT CE QUI PRÉCÈDE — LIRE CECI AVANT LE RESTE (GDD §10 et §10 bis)
#
# LES POINTS ② ET ③ CI-DESSUS SONT MORTS. Ils décrivaient la COURONNE, et la couronne est ce que Fabrice a
# demandé de supprimer : « le positionnement qui a été fait de me les mettre tout autour réduit considérablement
# la taille de l'image ». Ils restent écrits parce qu'ils expliquent D'OÙ VIENT le 0,350 que Fabrice a vu en
# B1 → B5, et pourquoi il était si petit — mais le calcul de B6 est celui-ci, et lui seul :
#
#   ①' LA RÉSERVE (l'ancien panneau) prend un côté : à DROITE quand l'écran est couché, EN BAS quand il est
#      debout — la règle de B2, inchangée. Elle porte le MODÈLE, et SOUS lui le TAS DE PIÈCES.
#   ②' L'ÉCHELLE NE CONNAÎT PLUS QUE LE PLATEAU : `échelle = 0,97 × min(zone.l / image.l ; zone.h / image.h)`.
#      Il n'y a plus rien à réserver autour de l'image, donc plus rien qui la rapetisse. ⚠ ET ELLE NE DÉPEND PAS
#      DU NOMBRE DE PIÈCES — c'est ce qui rend le jeu scalable à 100 pièces (GDD §10 bis) : à 15 comme à 100, le
#      plateau est le même, seul le tas se resserre.
#   ③' LA RÉSERVE RÉCUPÈRE TOUT CE QUE LE PLATEAU NE PREND PAS. Le dessin de la ferme est un PORTRAIT : sur un
#      écran couché, c'est la HAUTEUR qui commande, et il reste de la largeur. Cette largeur-là ne coûte donc
#      RIEN à l'image — elle va au tas, qui en a besoin. Sur 1024 × 768 la réserve passe ainsi de 307 à 376 px
#      sans qu'un pixel soit repris au plateau.
#   ④' LE TAS EST UNE SPIRALE D'OR (angle 137,5°) dans l'ellipse inscrite au tas : les places sont réparties du
#      centre vers le bord, l'écart entre deux places décroît en 1/√n. C'est CE QUI TIENT À 100 PIÈCES — un
#      quadrillage aurait dû choisir entre déborder et rapetisser les pièces ; la spirale, elle, se contente de
#      SE RESSERRER, et le chevauchement qui en résulte est exactement ce que Fabrice demande (« certaines
#      seront par-dessus d'autres, ce sera au joueur de les disposer pour voir lesquelles sont en dessous »).
#      ⚠ LA SEULE BORNE DURE : le CENTRE d'une pièce reste dans le tas ET sa boîte reste dans l'écran — une
#        pièce à moitié dehors au premier regard serait une pièce perdue. Au-delà, elles se recouvrent tant
#        qu'elles veulent : c'est le jeu.
#   ⑤' LA TOLÉRANCE D'AIMANTATION suit toujours l'échelle (④ ci-dessus, inchangé) : elle passe donc de 25,9 à
#      49,2 px sur l'écran de référence — l'aimantation reste EXACTEMENT aussi facile qu'avant, rapportée à la
#      taille des pièces. C'est une conséquence de l'agrandissement, pas une décision séparée.
# ============================================================================================================
const REF := Vector2(1024.0, 768.0)    # l'écran de référence de Fabrice — l'ÉTALON du calcul, pas un cadre
const MARGE_PLATEAU := 0.97            # (B6) la seule respiration qui reste : 3 % autour du plateau
const ECART_RESERVE := 12.0            # (B6) le filet d'air entre le plateau et la réserve, quand elle s'élargit
const MARGE_RESERVE := 8.0             # (B6) la marge intérieure de la réserve (modèle, tas)
const MODELE_PART := 0.42              # (B6) le modèle prend au plus 42 % de la hauteur utile — le reste est AU TAS
const ANGLE_OR := 2.39996322972865332  # (B6) l'angle d'or, en radians : la spirale du tas (cf. ④')
const TAS_PAS := 0.55                  # (B6) écart de confort entre deux places du tas, en fraction de boîte
const TAS_PAS_MIN := 5.0               # (B6) …et jamais deux pièces exactement au même point, même à 100
const DOUBLE_CLIC_MS := 450            # (B6) deux appuis en moins de 450 ms = un double-clic (souris ET doigt)
# ⚠ LA MARGE DE BORD EXISTE POUR UNE RAISON MESURÉE, PAS POUR FAIRE JOLI : sans elle, la première place d'une
#   ligne tombe à exactement une demi-boîte du bord, et l'englobant réel d'une pièce dont la languette sort de ce
#   côté-là affleure le canvas à 10⁻³ px près — le contrôle « aucune pièce ne sort de l'écran » sortait rouge sur
#   les quatre cibles pour deux millièmes de pixel. Deux unités de marge, et la pièce est franchement dedans.
const MARGE_BORD := 2.0
# (B6) LA RÉSERVE — l'ancien panneau, devenu le PORTE-MODÈLE ET LE TAS. Elle part de 30 % du canvas (au lieu de
# 22 %) parce qu'elle doit maintenant tenir un tas de pièces, et elle s'élargit ensuite de tout ce que le plateau
# laisse (③'). Ses bornes montent en conséquence.
const RESERVE_FRAC := 0.30
const RESERVE_MIN := 220.0
const RESERVE_MAX := 460.0
const RESERVE_PART_MAX := 0.55         # elle ne prendra JAMAIS plus de 55 % du canvas : le plateau reste le sujet
# ⚠⚠ (B13 · §21.8) LES TROIS CONSTANTES DU BANDEAU DEBOUT (`RESERVE_H_*`), CELLE DU MODÈLE COUCHÉ DANS CE BANDEAU
#   (`MODELE_PART_L`) ET LE SEUIL `RAPPORT_PORTRAIT` SONT SUPPRIMÉES : « je ne veux pas que le jeu fonctionne en
#   mode portrait. Le jeu fonctionne uniquement en mode paysage » (Fabrice, mot pour mot, GDD §21.8). Il ne reste
#   donc plus UN seul nombre qui ne serve qu'à un écran debout — c'est ainsi qu'on tient une règle dure : en
#   retirant le chemin, pas en le laissant dormir.
const TOL_AIMANT_FRAC := 0.19          # part de la diagonale d'une cellule (cf. ④ : 26 px sur 1024 × 768)

# ------------------------------------------------------------------------------------------------------------
# (B2) LE ZOOM — molette au bureau, pincement au tactile (GDD §7.7, brief §2)
# ------------------------------------------------------------------------------------------------------------
# ⚠⚠ (B6) LE PLANCHER DE 1,0 EST SUPPRIMÉ — C'EST UNE DEMANDE, MOT POUR MOT (GDD §10 bis) : « pour avoir de la
#   place pour ranger les pièces, le joueur va dézoomer, reculer la caméra et faire des petits tas. Surtout qu'il
#   ne soit PAS LIMITÉ dans le dézoom ». Le raisonnement de B2 (« sous la vue entière on ne verrait rien de
#   plus ») était juste TANT QUE tout tenait dans l'écran. Avec le tas empilé, c'est faux : le joueur SORT les
#   pièces de l'écran pour les trier en familles (les coins, les bords, le remplissage) — il lui faut un plan de
#   travail plus grand que l'écran, et c'est précisément ce que le dézoom lui donne.
# ⚠ CE QUI REMPLACE LE PLANCHER N'EST PAS UNE BORNE DE JEU : `ZOOM_PLANCHER` vaut 0,01, soit un plan de travail
#   de CENT écrans de côté (dix mille écrans de surface). Aucun joueur ne l'atteint ; il existe pour que la
#   division de `_vers_jeu` ne rencontre jamais un zéro. Le dézoom est libre au sens de Fabrice.
# ⚠ LE PLAFOND RESTE À 3,0 (B2, exposé), et le zoom AVANT se fait VERS LE CURSEUR (GDD §10) : `_zoomer_autour`
#   ancre le point visé — c'est déjà ce qu'il faisait, mais le bornage de B2 le contredisait dès qu'on approchait
#   d'un bord (la vue était recollée au canvas). Avec le plan de travail de B6, l'ancre tient vraiment.
# ⚠ LE DÉPLACEMENT RESTE BORNÉ, mais AU PLAN DE TRAVAIL et non plus au canvas (cf. `_plan_travail`) : le plan
#   suit les pièces, donc il grandit à mesure que le joueur écarte ses tas. Et le bouton RECADRER ramène toujours
#   la vue sur le puzzle — un enfant perdu dans le vide a un geste pour revenir (GDD §10 bis).
const ZOOM_PLANCHER := 0.01            # plancher TECHNIQUE, pas une limite de jeu (cf. l'encadré)
const ZOOM_MIN := ZOOM_PLANCHER        # …et l'ancien nom garde son sens pour tout ce qui le lisait
const ZOOM_MAX := 3.0
const ZOOM_PAS_MOLETTE := 1.15
const PINCE_ZONE_MORTE := 8.0          # variation d'écart en deçà de laquelle deux doigts DÉPLACENT sans zoomer
const PLAN_MARGE := 1.0                # (B6) le plan de travail déborde le contenu d'UN écran de chaque côté
const RECADRE_MARGE := 0.98            # (B6) « aussi grande que possible » — 2 % d'air pour ne pas raser le bord

# ------------------------------------------------------------------------------------------------------------
# (B2) LES SUGGESTIONS — « toutes les quinze secondes » (GDD §8.2, brief §3)
# ------------------------------------------------------------------------------------------------------------
# CE QUI CLIGNOTE, DEPUIS B7 : **DEUX** choses, et c'est tout l'objet de la balle.
#   • LA PLACE — la forme exacte de la pièce, dessinée SUR LE PLATEAU à l'endroit où cette pièce ira, languettes
#     comprises. C'est le TROU à combler.
#   • LA PIÈCE elle-même, là où elle traîne dans le tas — sa VRAIE forme, remplie et cernée, par-dessus tout.
# L'enfant lit donc « CETTE pièce → VA LÀ » d'un seul regard, sans rien à retenir : c'est la demande du GDD §11
# (« simplifier pour l'enfant », jeu FACILE ; montrer l'une puis l'autre ferait travailler la mémoire).
#
# ⚠⚠ ET LES DEUX BATTENT EN ANTI-PHASE (GDD §11 bis) : MÊME rythme, mais quand l'une s'allume l'autre s'éteint —
#   « un effet d'œil que l'un va vers l'autre, et vice versa ». D'où UNE SEULE sinusoïde `u` dans
#   `_pulser_suggestion`, la pièce en `u` et la place en `1 − u`. Deux horloges dériveraient ; un décalage écrit
#   en secondes dépendrait de la période. Retourner la même valeur rend l'opposition EXACTE, par construction.
#   ⚠ PAS de clignotement synchrone : Fabrice le refuse explicitement, « c'est l'inverse » qu'il veut.
# ⚠ LE CLIGNOTEMENT RESTE UNE PULSATION DE LUMINANCE (alpha 0,05 → 0,72) DOUBLÉE D'UN LISERÉ ÉPAIS, et le ROUGE
#   ne fait que s'y ajouter : `CLAUDE.md` demande que rien ne repose sur la teinte seule (daltonien). Le rouge
#   est la demande de Fabrice (« le rouge c'était pas mal, ça attirait bien l'œil »), pas le porteur du message.
# ⚠ LE COMPTE REPART À 15 s DÈS QUE L'ENFANT POSE UNE PIÈCE (décision de Code, exposée au brief §3) : une
#   suggestion n'a de sens que pour celui qui CHERCHE. Un enfant qui enchaîne les poses n'est pas interrompu ;
#   celui qui s'arrête quinze secondes est aidé.
const SUGG_PERIODE := 15.0             # « toutes les quinze secondes » — la demande, au chiffre près
const SUGG_DUREE := 6.0                # la suggestion s'efface au bout de 6 s : elle guide, elle ne s'installe pas
const SUGG_PULSE := 0.45               # (B7) « rapide » — une navette complète en 0,45 s, treize allers-retours
const SUGG_ALPHA_MIN := 0.05           # (B7) presque ÉTEINT : l'anti-phase ne se lit que si l'une s'efface vraiment
const SUGG_ALPHA_MAX := 0.72
const SUGG_LISERE_MIN := 0.10          # le liseré suit la même pulsation — la forme reste lisible sans la teinte
const SUGG_LISERE_MAX := 1.0
const SUGG_ROUGE := Color(1.0, 0.13, 0.09)   # (B7) le rouge retenu par Fabrice
const SUGG_LISERE_LARGEUR := 5.0       # épais : un trait fin se perd sur un tas de pièces imprimées

# ------------------------------------------------------------------------------------------------------------
# (§24) LE LISERÉ BLANC DE LA PIÈCE PRISE — « on va quand même mettre un petit liseré autour des pièces au
# moment où on a pris la pièce. Nous ferons un liseré plus fin que celui qui a été fait sur le jeu du puzzle
# adulte. » (Fabrice, 06-09)
# ------------------------------------------------------------------------------------------------------------
# ⚠ IL ÉPOUSE LA FORME EXACTE, PAS UN RECTANGLE : c'est `_noeud[i].polygon` qui est relu — tête ronde, cols,
#   languettes et creux compris. Un cadre englobant désignerait une BOÎTE et non une pièce, exactement le
#   reproche qui a fait tomber le cadre blanc de B2 (GDD §11).
# ⚠ BLANC PLEIN, ET C'EST LA LUMINANCE QUI PORTE LE SIGNAL : le blanc est le point le plus clair de l'écran
#   devant des pièces imprimées et un plateau sombre. Doublé de la FORME, il se lit sans la teinte — `CLAUDE.md`,
#   daltonien.
# ⚠ TROIS UNITÉS, ET NON CINQ : c'est le choix de Fabrice — « plus fin que celui du jeu du puzzle adulte »
#   (`PRISE_LISERE_LARGEUR := 5.0` là-bas). Ici, la main est celle d'un enfant et les pièces sont plus grosses :
#   un trait de 3 suffit à dire « c'est celle-ci », sans manger le dessin qu'elle porte.
# ⚠ IL NE CLIGNOTE PAS. La suggestion pulse parce qu'elle doit ATTIRER l'œil de celui qui cherche ; ce liseré-ci
#   ACCOMPAGNE une main déjà posée. Un clignotement de plus sous les doigts se lirait comme une seconde aide.
const PRISE_LISERE_BLANC := Color(1.0, 1.0, 1.0, 1.0)
const PRISE_LISERE_LARGEUR := 3.0      # (§24) le choix de Fabrice n° 1 — plus fin que les 5.0 de l'adulte

# ------------------------------------------------------------------------------------------------------------
# LA RÉCOMPENSE — « le même genre qu'on a déjà utilisé. Un seul. » (Fabrice, 14-08)
# ------------------------------------------------------------------------------------------------------------
# 240 planches de 512 × 288 jouées à 24 im/s = 10 s pile, avec leur chant. Ce sont les planches COPIÉES dans ce
# projet (`res://recompense/`), pas celles du 7 différences : le contenu ne s'emprunte pas.
const DOSSIER_REC := "res://jeux_integres/puzzle/recompense"
const SON_REC := "res://jeux_integres/puzzle/audio/recompense_coccos.mp3"
const REC_IM_PAR_S := 24.0
const REC_AGRANDIR := 1.62             # 512 × 288 → 829 × 467 à l'écran : la fête occupe le centre, pas un timbre
const REC_FONDU := 0.6                 # elle s'efface, elle ne disparaît pas d'un coup

# ============================================================================================================
# (B3) LES BOUTONS — LA MAISON, LE STOP, LE REJOUER
#
# ⚠⚠ POURQUOI LES ICÔNES SONT **DESSINÉES EN CODE** ET JAMAIS ÉCRITES AVEC UN CARACTÈRE (« ⌂ », « ↻ », « ■ ») :
#   c'est une leçon déjà payée dans la fratrie CoccOs. Ces caractères-là dépendent de la couverture Unicode de la
#   police embarquée, et ce qui manque s'affiche en CARRÉ VIDE. Sur le HUD d'un enfant qui ne lit pas encore,
#   l'icône EST le message : on ne parie pas dessus.
#
# ⚠⚠ ET C'EST AUSSI LA RÉPONSE À « LE LOGO DE REJEU DÉJÀ UTILISÉ AILLEURS : LE RETROUVER ET LE **COPIER**, JAMAIS
#   D'ANCRE » (brief §2). Le logo de rejeu de la fratrie est une FLÈCHE TOURNANTE dessinée par le code du jeu des
#   7 différences — un arc de 300° et sa pointe tangente, pas un fichier image. On ne peut donc pas copier un
#   PNG : ce qu'on copie, c'est la GÉOMÉTRIE, recopiée ici en toutes lettres (`IconeDessinee._rejouer`), points
#   et proportions identiques. Le résultat est le même signe à l'œil de l'enfant, et ce projet ne pointe vers
#   aucun autre : pas un `res://` ne sort de « le jeu des puzzles » (règle de Fabrice, GDD §6 — mesuré par le
#   contrôle ⓪ du harnais). Même chose pour la MAISON, qui est le signe du retour partout dans la fratrie.
#
# ⚠ DALTONIEN (CLAUDE.md) — le brief demande un triangle ROUGE, et le rouge ne porte rien tout seul : ① la FORME
#   (un triangle plein, unique sur cet écran) ; ② le LIBELLÉ « STOP » écrit sous lui ; ③ la LUMINANCE (triangle
#   clair cerné de noir sur un bouton sombre). Un enfant daltonien lit le bouton par trois voies dont aucune
#   n'est la teinte. Idem pour la maison (forme + porte évidée) et la flèche tournante (forme + ouverture).
# ============================================================================================================
const SCENE_ACCUEIL := "res://jeux_integres/puzzle/scenes/accueil.tscn"
const SCENE_PUZZLE := "res://jeux_integres/puzzle/scenes/puzzle.tscn"

const MAISON_TAILLE := Vector2(62.0, 58.0)     # une CIBLE DE DOIGT, pas une icône de barre d'outils
const MAISON_MARGE := 10.0
const FIN_BOUTON := Vector2(128.0, 96.0)       # les boutons de la fin — plus gros : ils sont seuls en scène
const FIN_ECART := 26.0
const FIN_MARGE := 18.0
const STOP_TAILLE := Vector2(112.0, 96.0)

# (B8) LA FLÈCHE DU « NIVEAU SUIVANT », EN COORDONNÉES DE 0 → 1 DANS SON RECTANGLE DE DESSIN — la géométrie de la
# fratrie CoccOs, RECOPIÉE ICI POINT PAR POINT (aucune ancre vers un autre jeu, GDD §6). Hampe épaisse puis tête
# triangulaire pleine hauteur : « courte et épaisse » est donc une PROPORTION, pas une taille en dur, et la forme
# reste juste le jour où le bouton changera de dimensions.
const FLECHE_SUIVANT := [Vector2(0.00, 0.31), Vector2(0.47, 0.31), Vector2(0.47, 0.00), Vector2(1.00, 0.50),
	Vector2(0.47, 1.00), Vector2(0.47, 0.69), Vector2(0.00, 0.69)]

# ============================================================================================================
# (B12 · GDD §21 → **B23 · §31.3**) LA DISPOSITION AU DOIGT EN TROIS COLONNES — **ET PLUS AUCUN BOUTON**
#
# ⚠⚠ CE QUE B23 RETIRE, ET POURQUOI CE N'EST PAS UNE PERTE. Fabrice, mot pour mot (14-09) : « Le bouton prendre
#   déposer, j'ai décidé qu'on le supprime, pour le jeu du puzzle, et pour le jeu du puzzle adulte. » Le bouton
#   (§21.3) n'existait QUE sur tactile ET QUE si un curseur était choisi ; sans lui, on **prend et on pose au
#   DOIGT DIRECTEMENT**, en mode avec curseur EXACTEMENT comme en mode sans curseur. Ont donc disparu avec lui :
#   `_prendre_rect`, `FLECHE_PRENDRE`, `_batir_prendre()`, `_bouton_prise_actif()`, la bascule `_basculer_prise()`,
#   le glyphe `prendre_poser` et le doigt-du-bouton exclu du comptage (`_doigt_bouton`).
#
# ⚠⚠ ET LE MODE QUI RESTE N'EST PAS RECONSTRUIT — IL EST **RE-EMPRUNTÉ** : `_input` porte DEUX chemins depuis
#   B12, et B14 (§22) faisait déjà tourner le second (le doigt direct) pour le mode « sans curseur ». On supprime
#   donc une branche, on n'en écrit aucune. C'est ce qui rend la suppression sûre : le chemin qui subsiste est
#   celui que les harnais B10 puis B14 mesuraient déjà, curseur dessiné compris.
#
# ⚠ CE QUI RESTE DE §21, ET QUE FABRICE N'A PAS DEMANDÉ DE TOUCHER (§31.5) : la DISPOSITION au doigt en trois
#   colonnes — modèle à gauche (§21.9, réduit), cadre de montage au milieu, tas à droite (§21.2/§21.10). Seule la
#   colonne gauche change : la place que le bouton occupait tout en bas lui est rendue, et elle va au MODÈLE.
# ⚠ CE QUI DISPARAÎT AUSSI, PAR CONSÉQUENCE DIRECTE : le refus de pincement pièce en main (§21.4). Il n'avait de
#   sens qu'AVEC le bouton — une pièce y restait prise sans qu'aucun doigt ne la tienne. Au doigt direct, la
#   pièce EST tenue par le doigt : poser un second doigt redevient donc « on lâche et on zoome », le geste de
#   B10, que §31.3 nomme explicitement (« le mode d'avant B12 »).
# ============================================================================================================
# ------------------------------------------------------------------------------------------------------------
# (B13 · §21.9 · §21.9 bis · §21.10) LE MODÈLE **RÉDUIT**, ET LE CADRE DE MONTAGE **DÉPORTÉ À GAUCHE**
# ------------------------------------------------------------------------------------------------------------
# ⚠⚠ FABRICE A CORRIGÉ CE POINT **TROIS FOIS** : ce sont **DEUX éléments différents, deux gestes différents**
#   (§21.9, 3ᵉ écriture). Lire le GDD au moment de livrer, pas le brief de départ.
#   ① **L'IMAGE MODÈLE** (colonne gauche) → **BEAUCOUP PLUS PETITE**. « Elle n'est pas déportée : on la RÉDUIT,
#      et c'est ça qui LIBÈRE DE LA PLACE. » Elle reste donc CENTRÉE dans sa colonne, comme en B12 ; ce qui change,
#      c'est qu'elle ne dépasse plus la largeur du BOUTON (`MODELE_L_MAX`) — de 417 unités elle tombe à 240.
#   ② **LE CADRE DE MONTAGE** (le plateau) → **DÉPORTÉ VERS LA GAUCHE, pas à 100 %** : il garde la marge
#      `ECART_RESERVE` avec la colonne gauche. But (§21.9 bis) : lui donner la LARGEUR qu'exige une image large —
#      le tracteur (rapport 1,833) était plafonné par la largeur de sa zone, pas par la hauteur de l'écran.
#   ③ **LES PIÈCES EN VRAC** ne réclament rien (§21.10 : « en tas, plus on empile, moins ça prend de place ; le
#      joueur dézoome pour décompacter ») → la colonne droite ne reçoit que le SURPLUS, jamais un pixel pris au
#      cadre de montage.
# ⚠⚠ ET LE DÉPORT NE SE FAIT QUE **QUAND L'IMAGE L'EXIGE** (§21.9, mot pour mot : « le cadre de montage PEUT
#   glisser vers la gauche QUAND L'IMAGE L'EXIGE — cas du tracteur »). La question se tranche par une MESURE, pas
#   par un goût : l'échelle est-elle plafonnée par la LARGEUR de la zone ou par la HAUTEUR de l'écran ?
#     · plafonnée par la HAUTEUR (les dessins debout : ferme, fusée, moto) → l'image ne gagnerait RIEN à la
#       largeur : on garde EXACTEMENT la disposition de B12, plateau **centré à 0,000 unité** sur le canvas.
#     · plafonnée par la LARGEUR (tracteur, porcelets) → colonne gauche réduite à SON CONTENU, plateau collé à
#       gauche, et tout le reste au tas. C'est là que l'image grandit.
const MODELE_L_MAX := 240.0            # le modèle ne dépasse JAMAIS la largeur du bouton (§21.9 : « beaucoup plus petit »)
const COLONNE_G_CONTENU := 260.0       # modèle (240) + ses deux marges (2 × 10) : le PLANCHER de la colonne gauche
                                       # ⚠ (B23 · §31.3) LA VALEUR NE BOUGE PAS ALORS QUE LE BOUTON DISPARAÎT : ce
                                       #   260 était « bouton (240) + 2 × 10 », il est maintenant « modèle
                                       #   (`MODELE_L_MAX` = 240) + 2 × 10 » — le MÊME nombre pour la MÊME raison
                                       #   (les deux faisaient 240 de large). Le changer aurait déplacé le cadre de
                                       #   montage des CINQ tableaux que §21.9 a coûté cinq rouges à régler.
const COLONNE_FRAC := 0.24             # la part du canvas que prend CHACUNE des deux colonnes latérales
const COLONNE_MIN := 200.0
const COLONNE_MAX := 430.0
const COLONNES_PART_MAX := 0.62        # les deux ensemble ne prennent JAMAIS plus de 62 % : le milieu reste le sujet
# (B23 · §31.3) LA MARGE BASSE DE LA COLONNE GAUCHE — celle qui était la marge du bouton (`PRENDRE_MARGE`). Le
# bouton est parti, la marge reste : sans elle le modèle toucherait le bord bas de l'écran.
const COLONNE_G_MARGE := 10.0

const COL_BOUTON := Color(0.93, 0.94, 0.97, 1.0)       # le fond clair des boutons : le glyphe sombre s'y détache
const COL_BOUTON_SURVOL := Color(1.0, 1.0, 1.0, 1.0)
const COL_GLYPHE := Color(0.08, 0.09, 0.14, 1.0)       # le sombre commun de tous les glyphes
const COL_STOP := Color(0.16, 0.17, 0.21, 1.0)         # le STOP a le fond SOMBRE : c'est le triangle qui est rouge
const COL_STOP_SURVOL := Color(0.24, 0.25, 0.30, 1.0)
const COL_ROUGE := Color(0.86, 0.16, 0.16, 1.0)        # « triangle rouge » (Fabrice) — doublé par la forme et le mot
const COL_ETIQUETTE := Color(0.96, 0.97, 0.99, 1.0)

enum Etat { JEU, RECOMPENSE, PLEIN_ECRAN }

# ------------------------------------------------------------------------------------------------------------
var _image: Texture2D = null
var _taille := Vector2(956.0, 1120.0)
var _cellule := Vector2.ZERO
# `_bord_h[r][c]` = le bord qui court AU-DESSUS de la case (r, c) ; r va de 0 à _rangs (0 et _rangs = le cadre).
# `_bord_v[r][c]` = le bord qui court À GAUCHE de la case (r, c) ; c va de 0 à _cols (0 et _cols = le cadre).
# Chacun est une polyligne en coordonnées IMAGE, calculée UNE fois et partagée par les deux pièces voisines.
var _bord_h: Array = []
var _bord_v: Array = []
var _contour: Array[PackedVector2Array] = []   # [i] → le tour de la pièce i, en coordonnées IMAGE
var _noeud: Array[Polygon2D] = []      # [i] → le nœud qui la dessine
var _cible: Array[Vector2] = []        # [i] → sa position d'écran quand le puzzle est fait
var _pos: Array[Vector2] = []          # [i] → sa position d'écran maintenant
var _groupe: Array[int] = []           # [i] → numéro du bloc auquel elle appartient (15 au départ, 1 à la fin)
var _saisi := -1                       # la pièce sous la main, ou -1
var _prise_ecart := Vector2.ZERO
var _etat: int = Etat.JEU
var _emboitements := 0                 # combien de fois deux blocs se sont accrochés depuis le début
var _jeu: Node2D = null
var _ihm: CanvasLayer = null
var _compteur: Label = null
var _rec_planches: Array[Texture2D] = []
var _rec_manque := ""
var _rec_t := 0.0
var _rec_calque: CanvasLayer = null
var _rec_voile: ColorRect = null
var _rec_vue: TextureRect = null
var _rec_son: AudioStreamPlayer = null
var _final: TextureRect = null
var _pe_porteur: Control = null        # le porteur du plein écran (bandes + image) : c'est SON fondu qu'on lit
var _journal_ouvert := true            # le jeu RACONTE ce qu'il fait : c'est ce que le harnais relit

# (B2) LA MISE EN PAGE, TOUTE DÉDUITE DU CANVAS
var _ecran := REF
# ⚠⚠ (B13 · §21.8) `_portrait` A DISPARU, ET C'EST LE POINT DE LA BALLE : plus un seul chemin de ce fichier ne
#   demande la forme de l'écran pour décider d'une disposition. « Le jeu fonctionne uniquement en mode paysage »
#   (Fabrice). Ce qui RESTE mesuré, pour le seul journal, c'est `canvas_debout()` — un CONSTAT, pas un chemin.
var _zone := Rect2()                 # la zone de jeu : le plateau (B6 : plus de couronne autour)
var _panneau := Rect2()                # (B6) l'ancien nom de la réserve — gardé pour tout ce qui le lisait
var _reserve := Rect2()                # (B6) la réserve : le modèle EN HAUT, le tas de pièces EN DESSOUS
var _modele_rect := Rect2()            # (B6) où le modèle est posé — rendu au harnais, double-cliquable
var _tas := Rect2()                    # (B6) le tas : là où les places de départ s'empilent
var _tas_utile := Rect2()              # (B6) …intersecté avec « la boîte reste dans l'écran » (cf. ④')
var _tas_pas := 0.0                    # (B6) l'écart réel entre deux places : il DÉCROÎT quand le nombre monte
var _echelle := 0.35
var _plateau := Rect2()                # le plateau à l'écran (là où l'image se refait)
var _boite := Vector2.ZERO             # la boîte d'une pièce à l'écran, languettes comprises
var _places: Array[Vector2] = []
var _tol_aimant := 26.0
var _fond_plateau: Polygon2D = null
var _cadre_plateau: Line2D = null
var _repartition := ""                 # « 3 gauche · 3 droite · 4 haut · 5 bas » — écrit au journal et relu par le harnais

# (B2) LE CURSEUR CHOISI À L'ACCUEIL
var _curseur := CurseursPuzzle.DEFAUT
var _curseur_taille := Vector2.ZERO

# ============================================================================================================
# ⓶⓪ (B10, REQ_260818_PUZZLE_B10) LE CURSEUR CHOISI EST VISIBLE **PENDANT LE JEU**, SUR LES QUATRE CIBLES
# ============================================================================================================
# LES MOTS DE FABRICE : « dans le jeu du puzzle, quel que soit le choix du curseur, quand on joue, il n'y en a
# pas. Il fallait quand même être débile de ne pas mettre de curseur, alors qu'on travaille avec des curseurs
# depuis le début, même sous Android. »
#
# ⚠⚠ CE QUE LA MESURE A TROUVÉ, ET IL FAUT LE DIRE SANS TOURNER AUTOUR : AU BUREAU, LE CURSEUR ÉTAIT DÉJÀ LÀ.
#   `_poser_curseur()` est appelé dans `_ready` depuis B2, il passe par `CurseursPuzzle.poser` et celui-là appelle
#   bien `Input.set_custom_mouse_cursor`. Relevé du DEHORS sur le PAQUET LINUX LIVRÉ, en plein écran, par
#   l'extension X11 XFixes (la seule mesure honnête : le moteur ne rend pas son propre pointeur) — la coccinelle
#   de 55 × 64 px, point chaud (8,7), 2069 pixels opaques, à l'accueil COMME en jeu. Ce n'est donc pas au bureau
#   qu'il manquait.
# ⚠⚠ IL MANQUAIT LÀ OÙ FABRICE POINTE LUI-MÊME : « même sous Android ». Un écran tactile n'a AUCUN pointeur de
#   souris — `Input.set_custom_mouse_cursor` y habille un objet qui n'existe pas, la ligne s'exécute et ne montre
#   rien. L'enfant choisit son ami à l'accueil, entre dans le jeu, et son ami a disparu.
#
# CE QUE B10 POSE, ET C'EST L'ACQUIS DE LA FRATRIE REPRIS TEL QUEL (7 différences B14/B34, points reliés B3) :
#   • AU BUREAU (Windows/Linux) : le pointeur du SYSTÈME, reposé à l'entrée du jeu — on ne compte plus sur ce que
#     l'accueil aurait laissé derrière lui (une scène qui se lance seule, un « rejouer », un « niveau suivant »
#     n'ont pas d'accueil derrière eux). C'était déjà le cas ; c'est maintenant ÉCRIT comme tel et mesuré.
#   • AU DOIGT (Android/iOS) : le curseur est **DESSINÉ** sur son propre calque, il suit le doigt, et c'est SA
#     POINTE (`chaud`) qui prend et pose les pièces — pas le pixel sous la pulpe.
#   • LE DOIGT TIENT LE SPRITE PAR SON `ancre` (le milieu du corps, marqué par Fabrice) : la pointe se retrouve
#     donc AU-DESSUS et un peu de côté, « exprès, pour que le bout du curseur reste visible ».
#
# ⚠⚠ ET UN ÉCART ASSUMÉ AVEC LE MODÈLE COPIÉ — L'AXE Y (cf. `_decal_tactile`) : les points reliés rattrapent le
#   décalage près du bord HAUT ; ici c'est le bord BAS. Ce n'est pas une préférence, c'est le seul côté qui en a
#   besoin, et le 7 différences le dit lui-même en toutes lettres (encadré B34 §2) : « le doigt ne peut pas
#   descendre sous le bas de l'écran, donc la pointe ne peut pas descendre sous 768 − 91 ». Le 7 différences et
#   les points reliés s'en sortent avec un SUIVI DE BORD qui fait défiler ou grossir la vue ; ce suivi-là touche
#   à la caméra, et le brief B10 borne la balle au curseur (« ne rien changer d'autre au gameplay »). Rattraper
#   le décalage du bon côté rend la même garantie sans toucher à la vue : AUCUN point de l'écran n'est hors
#   d'atteinte de la pointe, et la fonction « doigt → pointe » reste continue et strictement croissante.
const MOBILES := ["Android", "iOS"]
const CURSEUR_H_DOIGT := 192.0         # (7 différences B34, réglé par Fabrice sur son téléphone) le curseur DESSINÉ
const CURSEUR_CALQUE := 8              # au-dessus du panneau (0) et sous la fête (10), le plein écran (20), la fin (30)
var forcer_tactile := false            # posé par le harnais, ou `++ --forcer-tactile` : jouer le doigt sur ce poste
var _tactile := false
var _curseur_calque: CanvasLayer = null
var _curseur_vue: TextureRect = null   # le curseur DESSINÉ — c'est LUI que le doigt déplace
var _curseur_vise := Vector2.ZERO      # le POINT CHAUD du curseur dessiné = le pixel qui prend et pose
var _curseur_pose := false             # le doigt a-t-il déjà posé le curseur au moins une fois ?

# (B2) LE ZOOM
var _zoom := 1.0
var _pan := Vector2.ZERO
var _pan_souris := false               # (B6) bouton DROIT tenu : la souris déplace la vue (le plan de travail)
var _pan_dernier := Vector2.ZERO
var _recadrages := 0                   # (B6) combien de fois la vue a été ramenée sur le puzzle — relu au harnais
var _dezoom_mini := 1.0                # (B6) le plus petit zoom atteint dans la partie — relu au harnais
var _doigts := {}                      # index du doigt → sa position ; c'est ce qui distingue un doigt de deux
var _pincement := false                # deux doigts posés : on zoome/déplace, on ne bouge aucune pièce
# (B13 · §21.4 corrigé) LE PINCEMENT REFUSÉ PENDANT QU'UNE PIÈCE EST PRISE — compté, jamais deviné.
var _doigt_vise := -1                  # le doigt qui TIENT la visée : un doigt en trop ne la lui prend pas
var _pince_ecart := 0.0
var _pince_centre := Vector2.ZERO

# (B2) LES SUGGESTIONS
var _t_sugg := 0.0
var _sugg_i := -1
var _sugg_t := 0.0
var _sugg_rang := 0                    # pour ne pas montrer toujours la même pièce
var _sugg_calque: Node2D = null        # LA PLACE — derrière les pièces (une place ne doit pas cacher le jeu)
var _sugg_forme: Polygon2D = null
var _sugg_lisere: Line2D = null
# (B7) LA PIÈCE — son propre calque, et il vit AU-DESSUS de tout le reste : la pièce désignée peut être à demi
# enfouie dans le tas, c'est précisément le cas où l'aide sert. Le cadre blanc rectangulaire de B2 a disparu :
# il désignait une BOÎTE, pas une pièce, et il se perdait sur le tas (constat de Fabrice, GDD §11).
var _sugg_calque_piece: Node2D = null
var _sugg_piece_forme: Polygon2D = null
var _sugg_piece_lisere: Line2D = null
var _sugg_u := 0.0                     # la sinusoïde du moment : la PIÈCE la suit, la PLACE suit son inverse
var _suggestions := 0                  # combien de suggestions ont été montrées depuis le début

# (§24) LE LISERÉ DE LA PIÈCE PRISE — son PROPRE calque, et il vit AU SOMMET de `_jeu`. Le calque de la
# suggestion-pièce se remonte lui aussi à chaque image ; celui-ci se remonte APRÈS (cf. `_process`), pour que la
# pièce QU'ON TIENT soit toujours la dernière chose dessinée. C'est celle sous la main : rien ne passe dessus.
var _prise_calque: Node2D = null
var _prise_lisere: Line2D = null

# ------------------------------------------------------------------------------------------------------------
# (B3) LE TABLEAU, LE MÉLANGE, LES BOUTONS, LA MUSIQUE
# ------------------------------------------------------------------------------------------------------------
# ⚠⚠ CES DEUX-LÀ SONT **PUBLIQUES ET SANS SOULIGNÉ**, ET C'EST VOULU : elles se posent sur la scène AVANT son
#   `add_child` (donc avant `_ready`), par celui qui la monte. C'est le seul chemin qui ne passe ni par une
#   variable globale ni par un `autoload` — la même doctrine que le choix du curseur en B2, qui voyage par un
#   réglage. `tableau` prépare la balle suivante (elle n'aura qu'à monter la scène avec `tableau = 1`) ; `melange`
#   est ce qui fait que « Rejouer » REMÉLANGE les quinze pièces au lieu de resservir le même désordre.
# ⚠ LA DÉCOUPE, ELLE, NE BOUGE JAMAIS (`GRAINE` seule) : rejouer le même tableau doit rendre LES MÊMES PIÈCES,
#   sans quoi l'enfant ne rejoue pas son puzzle, il en découvre un autre. Ce qui change, c'est OÙ elles sont
#   posées au départ — et rien d'autre.
var tableau := TableauxPuzzle.DEFAUT
var melange := 0                       # 0 = la partie d'origine (le désordre de B1) ; +1 à chaque « Rejouer »

# (B6) LA GRILLE FORCÉE — le contrôle de scalabilité du GDD §10 bis, et RIEN D'AUTRE.
# ⚠ POURQUOI CES DEUX VARIABLES EXISTENT DANS LE JEU ET NON DANS LE HARNAIS : « on finira par mettre des
#   tableaux avec bien plus de pièces ; 100 pièces ne tiendraient pas sous le modèle si elles ne pouvaient pas se
#   chevaucher » (Fabrice). Prouver que la mise en page tient à 100, c'est MONTER LE VRAI JEU en 100 pièces —
#   pas recalculer des rectangles à côté. À 0 (le défaut, et le seul état que Fabrice rencontre), la grille est
#   celle du tableau : le jeu livré ne connaît que quinze pièces. Le jour où un tableau en demandera cent, il
#   suffira d'écrire « cols » et « rangs » dans sa ligne de table — ce chemin-là est déjà prouvé.
var cols_forcees := 0
var rangs_forcees := 0

# (B6) LE MODÈLE EN PLEIN ÉCRAN — double-clic pour l'ouvrir, double-clic pour revenir (GDD §10).
var _modele_vue: TextureRect = null    # le modèle réduit dans la réserve (c'est LUI qu'on double-clique)
var _modele_calque: CanvasLayer = null # le plein écran du modèle, créé à la demande, détruit au retour
var _modele_plein := false
var _modele_ouvertures := 0            # combien de fois il a été ouvert — relu au harnais
var _dernier_appui := -9999            # (ms) l'appui précédent sur le modèle : c'est lui qui fait le double-clic
var _btn_recadrer: Button = null       # (B6) « revenir au puzzle, aussi grand que possible » (GDD §10 bis)
# (B12 · §21) LE BOUTON PRENDRE ⇄ POSER et sa disposition
var _trois_colonnes := false           # au doigt : modèle · plateau · tas (§21.2 ; B13 : plus de condition d'écran)
# (B13 · §21.9) LE CADRE DE MONTAGE EST-IL DÉPORTÉ À GAUCHE ? Vrai quand l'échelle est plafonnée par la LARGEUR
# de la zone — « le cadre de montage peut glisser vers la gauche QUAND L'IMAGE L'EXIGE » (cas du tracteur).
var _deporte_gauche := false
var _colonne_g := Rect2()              # la colonne GAUCHE — le modèle SEUL depuis B23 (vide hors trois colonnes)
var _compte_rect := Rect2()            # où le compte est écrit — au-DESSUS du modèle, jamais dessous

var _btn_maison: Button = null         # la maison du HUD de jeu (dans le panneau)
var _fin_calque: CanvasLayer = null    # le calque des boutons de la victoire — AU-DESSUS du plein écran
var _btn_stop: Button = null
var _btn_rejouer: Button = null
var _btn_maison_fin: Button = null
var _btn_suivant: Button = null         # (B8) « niveau suivant » — il n'existe QUE s'il y a un tableau après
# (B8) LA RÉPONSE À « Y A-T-IL UNE SUITE ? », GELÉE À L'INSTANT DE LA VICTOIRE et jamais relue ensuite (cf. ㉕ en
# tête). Avant la victoire elle vaut `false` : la question ne se pose pas encore, et l'écran de fin — que
# personne ne regarde à ce moment-là — se calcule alors pour deux boutons, comme avant B8.
var _suivant_offert := false
var _musique: AudioStreamPlayer = null
# ⚠⚠ (B17 · §25) CE DRAPEAU EST CELUI DE LA **SÉQUENCE FINALE**, PAS DE LA SEULE MUSIQUE — et il garde son nom
#   à dessein. Sur huit tableaux la séquence finale EST la musique ; sur « La petite feuille » c'est la VIDÉO
#   (qui porte son propre chant). Les trois portes de sortie sont les mêmes dans les deux cas — « joue » tant
#   qu'on écoute, puis « finie » ou « stoppee », et c'est ce mot-là qui commande l'apparition des deux boutons.
#   Lui donner un second nom pour la vidéo aurait dédoublé `_montrer_boutons_fin`, le STOP et tous les contrôles
#   des harnais B3 → B16 qui le lisent : deux chemins pour une seule règle, donc deux occasions de diverger.
var _musique_etat := "silence"         # silence · joue · finie · stoppee — écrit au journal, relu par le harnais
var _musique_passages := 0             # combien de fois la musique a été LANCÉE : elle doit valoir 1, jamais 2
var _musique_manque := ""
# (B17 · §25) LE LECTEUR VIDÉO — il n'existe QUE pour un tableau qui déclare une vidéo, et seulement une fois
# l'écran de fin atteint. Nul pendant le jeu : rien ne décode en tâche de fond derrière le puzzle.
var _video: VideoStreamPlayer = null
var _video_passages := 0               # combien de fois la vidéo a été LANCÉE : 1, jamais 2 (même verrou)
var _video_manque := ""
var _progression_ouverte := false      # (B4) cette victoire a-t-elle débloqué un tableau ? (relu par le harnais)


# ============================================================================================================
func _ready() -> void:
	randomize()
	# (B10) LE DOIGT OU LA SOURIS — la question est tranchée AVANT toute construction, parce que le curseur, la
	# lecture des événements et la mise en page du calque en descendent. `forcer_tactile` est un chemin de PREUVE
	# sur ce poste, il ne remplace pas la détection : sur un vrai téléphone il reste faux et le jeu est tactile
	# quand même.
	_tactile = forcer_tactile or MOBILES.has(OS.get_name()) \
		or OS.get_cmdline_user_args().has("--forcer-tactile")
	# ⚠⚠ (B14 · §22 — MAINTENU EN B23) LE CHOIX DU CURSEUR EST LU **ICI**, AVANT TOUTE CONSTRUCTION. Le piège qui
	#   l'avait imposé a disparu avec le bouton (`_batir_ihm()` s'exécutait AVANT `_poser_curseur()`, et le bouton
	#   se bâtissait donc sur un curseur pas encore relu — §31.3). La ligne RESTE pour le curseur DESSINÉ au doigt,
	#   qui lit `_curseur` dès `_batir_curseur_doigt()`, et pour sa TAILLE (§31.2 : la Main est deux fois plus
	#   petite). `_poser_curseur()` relit la même ligne ensuite : c'est idempotent, et ça garde son journal.
	_curseur = CurseursPuzzle.lire_choix()
	tableau = TableauxPuzzle.numero_valide(tableau)
	_image = TableauxPuzzle.image(tableau)
	if _image == null:
		push_error("[puzzle] image introuvable : " + TableauxPuzzle.chemin_image(tableau))
		return
	# (B4) LA GRILLE EST CELLE DU TABLEAU, et elle est posée AVANT le premier calcul : `_cellule`, la découpe, la
	# mise en page et les places de départ en descendent toutes. C'est la seule ligne qui fait qu'un dessin couché
	# se taille en 5 × 3 et un dessin debout en 3 × 5, sans une autre retouche nulle part.
	_cols = TableauxPuzzle.colonnes(tableau)
	_rangs = TableauxPuzzle.rangs(tableau)
	# (B6) …sauf quand une grille est FORCÉE : c'est le contrôle de scalabilité à 100 pièces, et lui seul.
	if cols_forcees > 0 and rangs_forcees > 0:
		_cols = cols_forcees
		_rangs = rangs_forcees
		_dire("⚠ GRILLE FORCÉE %d × %d = %d pièces — contrôle de scalabilité (GDD §10 bis), pas le jeu livré"
			% [_cols, _rangs, _cols * _rangs])
	_taille = Vector2(_image.get_size())
	_cellule = _taille / Vector2(float(_cols), float(_rangs))
	_calculer_mise_en_page()
	# (B15) LE JOURNAL DIT LA FAMILLE ET LE NOMBRE DE PIÈCES — c'est le premier endroit où l'on voit, sans rien
	# déduire, qu'un 2 × 2 a bien donné QUATRE pièces et non quinze (§23 : « zéro divergence », c'est le premier
	# tableau à un autre nombre de pièces que 15).
	_dire("tableau %d « %s » (famille « %s », %d pièces) · image %s · grille %d × %d = %d pièces · mélange n° %d"
		% [tableau + 1, TableauxPuzzle.nom(tableau),
			TableauxPuzzle.cle_famille(TableauxPuzzle.famille_de(tableau)),
			TableauxPuzzle.pieces_de_famille(TableauxPuzzle.famille_de(tableau)),
			TableauxPuzzle.chemin_image(tableau).get_file(), _cols, _rangs, _cols * _rangs, melange])
	_dire("image %s · découpe %d × %d = %d pièces · cellule %.1f × %.1f"
		% [str(_taille), _cols, _rangs, _cols * _rangs, _cellule.x, _cellule.y])
	# (B13 · §21.8) LE JEU EST PAYSAGE SEULEMENT : on écrit la FORME MESURÉE du canvas, et le fait qu'aucune
	# disposition n'en dépend plus. Si un canvas debout se présentait quand même, la page reste celle du paysage.
	_dire("canvas %s (forme mesurée : %s — le jeu est PAYSAGE SEULEMENT, §21.8) · zone de jeu %s · panneau %s · échelle %.4f · tolérance d'aimant %.1f px"
		% [str(_ecran), "debout" if canvas_debout() else "couché", str(_zone.size), str(_panneau.size),
			_echelle, _tol_aimant])
	# (B12 · §21) CE QUE LA DISPOSITION A DÉCIDÉ, ÉCRIT AU JOURNAL — c'est ce que Fabrice relit sur son téléphone.
	if _trois_colonnes:
		_dire("disposition ANDROID en TROIS COLONNES (§21.2) : modèle à gauche %s (§21.9 : plus petit) · plateau au milieu %s · tas à droite %s — AUCUN bouton PRENDRE/POSER (§31.3 : prise et pose au DOIGT DIRECT)"
			% [str(_modele_rect), str(_plateau), str(_tas)])
	else:
		_dire("disposition bureau (§21.5 : le bureau garde le jeu de B6) — AUCUN bouton PRENDRE/POSER (§31.3 ; souris : prise au clic maintenu)")

	_tailler()
	_batir_plateau()
	_batir_pieces()
	_batir_ihm()
	_eparpiller()
	_poser_curseur()
	_batir_curseur_doigt()
	# (B2) Le canvas peut changer en cours de route — fenêtre redimensionnée, téléphone qu'on tourne, passage au
	# projecteur. On se branche sur le signal du viewport : le recadrage est une réaction à un événement rare.
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_redimensionne):
		vp.size_changed.connect(_redimensionne)
	# Les 34 Mo de la fête se chargent APRÈS la première image affichée : l'enfant voit son puzzle tout de suite,
	# et les dix secondes de chant sont prêtes bien avant qu'il ait posé la quinzième pièce.
	call_deferred("_charger_recompense")
	# (B3) « PENDANT LE PUZZLE : AUCUNE MUSIQUE » (Fabrice, GDD §7.10). Ce n'est pas un volume à zéro ni une piste
	# en pause : AUCUN lecteur de musique n'existe tant que l'image n'est pas refaite. Celui de la victoire est
	# créé par `_lancer_musique_tableau`, et pas une seconde plus tôt.
	_dire("silence pendant le puzzle : aucun lecteur de musique — la musique du tableau est « %s », elle ne passera qu'à la victoire"
		% TableauxPuzzle.chemin_musique(tableau).get_file())


# ------------------------------------------------------------------------------------------------------------
# ⓪ (B2) LA MISE EN PAGE — tout se déduit du canvas réel (cf. l'encadré « LA MISE EN PAGE SE DÉDUIT DU CANVAS »)
# ------------------------------------------------------------------------------------------------------------
# ⚠ `get_visible_rect()` du viewport, et NON `DisplayServer.window_get_size()` : sous `stretch/mode = canvas_items`
#   la fenêtre est en PIXELS d'écran tandis que ce fichier dessine en unités de CANVAS. Les deux ne coïncident que
#   par hasard — leçon payée par le 7 différences (sa B6), reprise ici sans la repayer.
func _maj_ecran() -> bool:
	var t := REF
	var vp := get_viewport()
	if vp != null:
		var r: Vector2 = vp.get_visible_rect().size
		if r.x >= 64.0 and r.y >= 64.0:          # filet : un viewport dégénéré n'écrase pas la référence
			t = r
	if t.is_equal_approx(_ecran):
		return false
	_ecran = t
	return true


# (B13 · §21.8) LA FORME DU CANVAS — UN CONSTAT, PAS UN CHEMIN. Le jeu est paysage seulement : cette fonction ne
# décide de RIEN (aucun `if` de mise en page ne la lit), elle sert au journal et au harnais, pour dire « voilà ce
# qu'on nous a présenté ». L'orientation est verrouillée à la source côté mobile (`project.godot`).
func canvas_debout() -> bool:
	return _ecran.x < _ecran.y


func _calculer_mise_en_page() -> void:
	_maj_ecran()
	# ⚠⚠ (B13 · §21.8) IL N'Y A PLUS DE QUESTION « L'ÉCRAN EST-IL DEBOUT ? » — LE JEU EST PAYSAGE, POINT.
	#   Fabrice, mot pour mot : « je ne veux pas que le jeu fonctionne en mode portrait. Le jeu fonctionne
	#   uniquement en mode paysage. C'est une décision qui a été dite et écrite. » Le drapeau `_portrait`, le
	#   bandeau du bas de B6 en debout et le bouton posé dans son coin (§21.5) sont donc RETIRÉS : la réserve est
	#   toujours à DROITE, les trois colonnes s'appliquent dès que c'est le DOIGT qui joue. L'orientation est en
	#   outre verrouillée à la source (`project.godot` : `display/window/handheld/orientation = 0`, Paysage), donc
	#   un téléphone tourné ne présente plus de canvas debout au jeu.
	# (B12 · §21.2) TROIS COLONNES : AU DOIGT, ET NULLE PART AILLEURS. Au bureau `_tactile` est faux — le jeu
	# garde exactement la mise en page de B6 (§21.5, confirmé par Fabrice).
	_trois_colonnes = _tactile
	_colonne_g = Rect2()
	# ①' LA RÉSERVE PROVISOIRE — une part du canvas, bornée. Elle sera élargie en ③' de tout ce que le plateau
	#    ne prend pas : le tas gagne la place que l'image laisse, jamais l'inverse.
	if _trois_colonnes:
		# ⚠⚠ (B13 · §21.9 bis) LA COLONNE GAUCHE PART DE **SON CONTENU**, PAS D'UNE PART DU CANVAS. C'est la
		#   traduction exacte de « on RÉDUIT le modèle, et c'est ça qui LIBÈRE DE LA PLACE » : la place libérée
		#   doit aller au cadre de montage, donc l'échelle est d'abord calculée dans la zone LA PLUS LARGE
		#   possible. Si l'image n'en profite pas (dessin debout, plafonné par la hauteur), ③' rend cette largeur
		#   aux deux colonnes et l'on retombe EXACTEMENT sur B12.
		_poser_trois_colonnes(minf(COLONNE_G_CONTENU, _ecran.x * 0.25),
			clampf(COLONNE_FRAC * _ecran.x, COLONNE_MIN, COLONNE_MAX))
	else:
		_poser_reserve(clampf(RESERVE_FRAC * _ecran.x, RESERVE_MIN, RESERVE_MAX))
	# La boîte d'une pièce EN COORDONNÉES IMAGE : la cellule plus ses languettes, qui débordent de 0,28 de la
	# longueur du bord OPPOSÉ (une languette de bord vertical déborde en X, et sa longueur est `cellule.y`).
	var boite_img := Vector2(_cellule.x + 2.0 * LANGUETTE * _cellule.y, _cellule.y + 2.0 * LANGUETTE * _cellule.x)
	# ②' L'ÉCHELLE — LE PLATEAU, ET LUI SEUL. Une ligne à la place du calcul de couronne et de sa boucle de
	#    rattrapage : c'est TOUTE la refonte de B6, et c'est ce qui triple la surface de l'image.
	#    ⚠ Elle ne lit NI le nombre de pièces NI la taille d'une boîte : à 15 comme à 100, le plateau est le même.
	_echelle = MARGE_PLATEAU * minf(_zone.size.x / _taille.x, _zone.size.y / _taille.y)
	_boite = boite_img * _echelle
	# ③' TOUT CE QUE LE PLATEAU NE PREND PAS VA À LA RÉSERVE — et ne coûte donc rien à l'image (cf. l'encadré).
	# ⚠⚠ (B13 · §21.9) EN TROIS COLONNES, DEUX CAS, ET C'EST UNE **MESURE** QUI TRANCHE — pas un goût :
	#   · L'ÉCHELLE EST PLAFONNÉE PAR LA **HAUTEUR** (dessin debout : ferme, fusée, moto) → l'image ne gagnerait
	#     RIEN à recevoir de la largeur. Le reste se partage donc **EN DEUX PARTS ÉGALES** entre les deux colonnes
	#     et le plateau reste **« en plein milieu »** (§21.2) : c'est EXACTEMENT la disposition de B12, au millième.
	#   · L'ÉCHELLE EST PLAFONNÉE PAR LA **LARGEUR** (tracteur 1,833, porcelets 1,164) → « le cadre de montage
	#     peut glisser vers la gauche QUAND L'IMAGE L'EXIGE » (§21.9). La colonne gauche garde alors son CONTENU,
	#     le plateau est collé à gauche de sa zone (à `ECART_RESERVE` de la colonne : « pas à 100 % »), et **tout
	#     le surplus va au tas** — jamais l'inverse (§21.10 : les pièces en vrac ne réclament rien, le joueur
	#     dézoome pour décompacter).
	# ⚠ `_plateau` est posé plus bas ; ici on ne fait que RÉGLER LES COLONNES et se souvenir du cas.
	if _trois_colonnes:
		_deporte_gauche = (_zone.size.x / _taille.x) < (_zone.size.y / _taille.y)
		var large_p: float = _taille.x * _echelle
		var r: float = _zone.size.x - large_p
		if _deporte_gauche:
			# LE SURPLUS, ENTIÈREMENT AU TAS : la colonne gauche ne bouge pas (le modèle est réduit, il n'a pas
			# besoin de plus), le plateau prend la largeur, le tas prend ce qui reste à sa droite.
			if r > ECART_RESERVE:
				_poser_trois_colonnes(_colonne_g.size.x, _reserve.size.x + r - ECART_RESERVE)
		elif r > 2.0 * ECART_RESERVE:
			# ⚠⚠ ICI ON NE PARTAGE PAS « LA MOITIÉ CHACUNE » — ON **CENTRE LE MILIEU**. La nuance a coûté un rouge
			#   sur cinq tableaux : en B12 les deux colonnes partaient de la MÊME base (0,24 × canvas), donc leur
			#   donner la moitié du reste laissait le plateau centré. Depuis §21.9 la colonne GAUCHE part de son
			#   CONTENU (260) et la droite de 0,24 × canvas : à moitié-moitié, le plateau se retrouvait décalé de
			#   **74,8 unités**. On calcule donc les deux colonnes POUR QUE le milieu soit centré — c'est la
			#   propriété que Fabrice a demandée (« en plein milieu », §21.2), pas la façon de la répartir.
			var c: float = maxf((_ecran.x - large_p - 2.0 * ECART_RESERVE) * 0.5, 80.0)
			_poser_trois_colonnes(c, c)
	else:
		var reste: float = _zone.size.x - _taille.x * _echelle
		if reste > ECART_RESERVE:
			_poser_reserve(_reserve.size.x + reste - ECART_RESERVE)
	# LE CADRE DE MONTAGE : centré dans sa zone… SAUF quand l'image exige la largeur — il est alors **DÉPORTÉ À
	# GAUCHE** (§21.9), collé au bord gauche de sa zone, qui est déjà à `ECART_RESERVE` de la colonne du modèle
	# (« pas à 100 % » : il ne touche jamais la colonne ni le bord de l'écran).
	var haut: float = _zone.position.y + (_zone.size.y - _taille.y * _echelle) * 0.5
	if _trois_colonnes and _deporte_gauche:
		_plateau = Rect2(Vector2(_zone.position.x, haut), _taille * _echelle)
	else:
		_plateau = Rect2(_zone.position + (_zone.size - _taille * _echelle) * 0.5, _taille * _echelle)
	_tol_aimant = TOL_AIMANT_FRAC * (_cellule * _echelle).length()
	_calculer_modele_et_tas()
	_calculer_places()


# LA RÉSERVE PREND UN CÔTÉ, ET C'EST TOUJOURS LA DROITE (B2 → B6 en paysage).
# ⚠⚠ (B13 · §21.8) LE BANDEAU DU BAS A DISPARU AVEC LE MODE PORTRAIT : le jeu ne connaît plus qu'un écran couché,
#   donc plus qu'une réserve — celle de droite. Le reste du canvas est la zone de jeu : le plateau, et rien
#   d'autre depuis B6.
func _poser_reserve(t: float) -> void:
	var l: float = clampf(t, RESERVE_MIN, _ecran.x * RESERVE_PART_MAX)
	_reserve = Rect2(Vector2(_ecran.x - l, 0.0), Vector2(l, _ecran.y))
	_zone = Rect2(Vector2.ZERO, Vector2(_ecran.x - l, _ecran.y))
	_panneau = _reserve                    # l'ancien nom, pour tout ce qui le lisait (la maison, le harnais)


# (B12 · §21.2) LES TROIS COLONNES — « l'image modèle à gauche · le cadre de montage en plein milieu · à droite
# les pièces de puzzle en vrac » (Fabrice, mot pour mot).
#
# ⚠ `_reserve` (et donc `_panneau`) EST LA COLONNE DROITE, et ce n'est pas un raccourci de nommage : c'est ce qui
#   garde la maison, le recadrage, le compte et TOUT le harnais de B2 → B11 à leur place sans une retouche — ils
#   lisent `_panneau`, et `_panneau` reste « le bord où vivent les pièces et les boutons ». Ce qui est NOUVEAU,
#   c'est `_colonne_g` : elle n'existe qu'ici, et elle ne porte que le modèle et le bouton.
# ⚠ LES DEUX COLONNES SONT BORNÉES ENSEMBLE (`COLONNES_PART_MAX`) : bornées séparément, deux colonnes larges sur
#   un écran étroit se rejoindraient au milieu et le plateau tomberait à 40 unités — le filet est sur le TOTAL.
func _poser_trois_colonnes(lg: float, ld: float) -> void:
	# ⚠⚠ (B13 · §21.10) LE PLAFOND N'EST PLUS « LA MOITIÉ DE 62 % CHACUNE », ET C'EST UNE DEMANDE : « ne PAS
	#   élargir la colonne des pièces en vrac au détriment du CADRE DE MONTAGE ». Le tas peut donc recevoir tout
	#   le surplus (il en fait bon usage : le joueur dézoome pour décompacter son tas), mais **il ne peut pas
	#   descendre le milieu sous ce que le cadre de montage occupe** — le filet porte sur ce qui RESTE au milieu.
	var tot_max: float = _ecran.x * COLONNES_PART_MAX
	var l1: float = clampf(lg, 80.0, tot_max * 0.5)
	var milieu_min: float = maxf(_taille.x * _echelle, 40.0) if _echelle > 0.0 else 40.0
	var l2: float = clampf(ld, 80.0, maxf(_ecran.x - l1 - 2.0 * ECART_RESERVE - milieu_min, 80.0))
	_colonne_g = Rect2(Vector2.ZERO, Vector2(l1, _ecran.y))
	_reserve = Rect2(Vector2(_ecran.x - l2, 0.0), Vector2(l2, _ecran.y))
	_zone = Rect2(Vector2(l1 + ECART_RESERVE, 0.0),
		Vector2(maxf(_ecran.x - l1 - l2 - 2.0 * ECART_RESERVE, 40.0), _ecran.y))
	_panneau = _reserve


# LE MODÈLE EN HAUT, LE TAS EN DESSOUS — « les pièces mises en dessous du modèle » (Fabrice, GDD §10).
#
# ⚠⚠ CE QUE LA LIGNE DU HAUT PORTE, ET POURQUOI ELLE EST AU-DESSUS DU MODÈLE : le COMPTE et les DEUX BOUTONS
#   (la maison de B3, le recadrage de B6). Fabrice demande « aucun écrit EN DESSOUS de l'image modèle » — le
#   compte est un écrit, il remonte donc AU-DESSUS. Ce n'est pas une interprétation large : c'est le seul endroit
#   de la réserve qui ne soit pas « en dessous ».
# ⚠⚠ (B13 · §21.8) LE CAS DU BANDEAU DEBOUT A ÉTÉ RETIRÉ D'ICI : il n'existe plus d'écran debout pour ce jeu.
#   Ce qui est tenu partout : aucun écrit sous le modèle, le tas est dans la réserve, et l'image reste au plus
#   grand.
func _calculer_modele_et_tas() -> void:
	var m := MARGE_RESERVE
	var ligne: float = MAISON_TAILLE.y + 2.0 * MAISON_MARGE          # la ligne du haut : compte + les 2 boutons
	# (B12 · §21.2) LA COLONNE GAUCHE — LE MODÈLE, ET LE BOUTON **TOUT EN BAS**. Le bouton est posé LE PREMIER,
	# et le modèle prend ce qui reste au-dessus : c'est l'ordre qui traduit « tout en bas à gauche » sans qu'un
	# modèle un peu grand ne vienne jamais le pousser hors de l'écran.
	# ⚠ LE COMPTE EST AU-DESSUS DU MODÈLE, comme en B6 et pour la même raison : « aucun écrit EN DESSOUS de
	#   l'image modèle » (Fabrice, GDD §10). Sous le modèle, ici, il n'y a que le bouton — qui ne porte aucun mot.
	if _trois_colonnes:
		_compte_rect = Rect2(_colonne_g.position + Vector2(m, MAISON_MARGE),
			Vector2(maxf(_colonne_g.size.x - 2.0 * m, 40.0), ligne))
		# ⚠⚠ (B23 · §31.3) LA HAUTEUR UTILE DESCEND MAINTENANT JUSQU'AU BAS DE LA COLONNE : le bouton n'est plus là
		#   pour la borner, donc la place qu'il occupait (240 × 173 unités sur 1024 × 768) est RENDUE AU MODÈLE.
		#   C'est la seule conséquence visible de sa suppression sur la mise en page, et elle est dans le bon sens :
		#   l'image de référence est ce qu'on regarde pour jouer.
		# ⚠ NI LE PLATEAU NI LE TAS NE BOUGENT D'UN MILLIÈME : la LARGEUR de la colonne gauche est inchangée
		#   (`COLONNE_G_CONTENU`), et seule la largeur entre dans le partage des trois colonnes.
		var utile: float = maxf(_colonne_g.end.y - COLONNE_G_MARGE
			- (_colonne_g.position.y + ligne) - m, 40.0)
		# ⚠⚠ (B13 · §21.9) LE MODÈLE EST « BEAUCOUP PLUS PETIT », ET IL N'EST **PAS DÉPORTÉ** : « elle n'est pas
		#   déportée : on la RÉDUIT, et c'est ça qui libère de la place » (Fabrice, 3ᵉ écriture du §21.9). Il reste
		#   donc CENTRÉ dans sa colonne, comme en B12. Ce qui change : il ne dépasse plus la largeur du BOUTON
		#   (`MODELE_L_MAX`) — de 417 unités il tombe à 240, et la place libérée va au cadre de montage.
		# ⚠ (B23 · §31.3) LE PLAFOND DE LARGEUR NE BOUGE PAS AVEC LA DISPARITION DU BOUTON : « beaucoup plus
		#   petit » était une demande sur le MODÈLE, pas une conséquence du bouton. Ce que le modèle gagne, il le
		#   gagne en HAUTEUR UTILE — et son rapport le borne tout seul.
		# ⚠ LA HAUTEUR SUIT TOUJOURS LE RAPPORT DU DESSIN : c'est ce qui montre l'image ENTIÈRE des CINQ tableaux,
		#   jamais déformée, jamais rognée (0,854 · 1,164 · 0,854 · 0,854 · 1,833).
		var ml3: float = maxf(minf(_colonne_g.size.x - 2.0 * m, MODELE_L_MAX), 20.0)
		var mh3: float = ml3 * _taille.y / _taille.x
		if mh3 > utile:
			mh3 = utile
			ml3 = mh3 * _taille.x / _taille.y
		_modele_rect = Rect2(Vector2(_colonne_g.position.x + (_colonne_g.size.x - ml3) * 0.5,
			_colonne_g.position.y + ligne), Vector2(ml3, mh3))
		# LE TAS = TOUTE LA COLONNE DROITE, sous la ligne du compte et des deux boutons. « À droite, il nous
		# restera la place pour mettre les pièces de puzzle en vrac » (Fabrice) : la colonne entière est à elles.
		_tas = Rect2(Vector2(_reserve.position.x, _reserve.position.y + ligne),
			Vector2(_reserve.size.x, maxf(_reserve.size.y - ligne - m, 20.0)))
		return
	# LE BUREAU (souris) — la réserve de B6, à droite : le modèle en haut, le tas dessous. Inchangé (§21.5).
	var ml2: float = _reserve.size.x - 2.0 * m
	var mh2: float = ml2 * _taille.y / _taille.x
	var mh_max: float = maxf((_reserve.size.y - ligne) * MODELE_PART, 40.0)
	if mh2 > mh_max:
		mh2 = mh_max
		ml2 = mh2 * _taille.x / _taille.y
	_modele_rect = Rect2(Vector2(_reserve.position.x + (_reserve.size.x - ml2) * 0.5,
		_reserve.position.y + ligne), Vector2(ml2, mh2))
	var y0: float = _modele_rect.end.y + m
	_tas = Rect2(Vector2(_reserve.position.x, y0),
		Vector2(_reserve.size.x, maxf(_reserve.end.y - y0 - m, 20.0)))
	_compte_rect = Rect2(_reserve.position + Vector2(m, MAISON_MARGE),
		Vector2(maxf(_reserve.size.x - 2.0 * MAISON_TAILLE.x - 4.0 * MAISON_MARGE, 40.0), ligne))


# LES PLACES DE DÉPART — LE TAS (④' de l'encadré). Une SPIRALE D'OR dans l'ellipse inscrite au tas.
#
# ⚠⚠ LA SEULE CHOSE QUI SOIT VRAIMENT BORNÉE ICI, C'EST LE CENTRE D'UNE PIÈCE — pas sa boîte. Les boîtes se
#   CHEVAUCHENT, et c'est la demande (« nous tricherons, certaines seront par-dessus d'autres ») : c'est le
#   chevauchement qui paie la grande image. Ce qu'on garantit, et qui compte pour l'enfant, c'est ① qu'aucune
#   pièce ne commence à moitié hors de l'écran (elle serait perdue), ② que deux pièces ne partent jamais du
#   MÊME point (l'une serait strictement invisible, `TAS_PAS_MIN`), et ③ que le centre de chacune reste dans le
#   tas, donc attrapable d'un clic même si ses bords sont couverts.
# ⚠ ET C'EST CE QUI TIENT À CENT PIÈCES : l'étendue de la spirale est bornée par le tas, pas par le nombre. Quand
#   n monte, `pas = étendue / √(n−1)` descend tout seul — les pièces se serrent, aucune ne sort, rien ne casse.
#   Le harnais monte le jeu en 10 × 10 et remesure les trois garanties.
func _calculer_places() -> void:
	var n := _cols * _rangs
	# ① « la boîte reste dans l'écran » : le domaine des CENTRES admissibles, tout écran confondu.
	var borne := Rect2(_boite * 0.5 + Vector2(MARGE_BORD, MARGE_BORD),
		(_ecran - _boite - Vector2(2.0 * MARGE_BORD, 2.0 * MARGE_BORD)).max(Vector2(1.0, 1.0)))
	_tas_utile = _tas.intersection(borne)
	if _tas_utile.size.x < 1.0 or _tas_utile.size.y < 1.0:
		# FILET (écran minuscule ou pièce plus grande que la réserve) : on ne perd pas les pièces, on les empile
		# au centre du tas ramené dans l'écran. On l'ÉCRIT — le harnais le lit.
		_tas_utile = Rect2(borne.get_center(), Vector2.ZERO)
		_dire("⚠ tas plus étroit qu'une pièce : les places se replient sur %s" % str(_tas_utile.position))
	var c := _tas_utile.get_center()
	var racine: float = sqrt(float(maxi(n - 1, 1)))
	var confort: float = TAS_PAS * minf(_boite.x, _boite.y)          # l'écart qu'on prendrait si la place ne manquait pas
	var etendue := Vector2(minf(_tas_utile.size.x * 0.5, confort * racine),
		minf(_tas_utile.size.y * 0.5, confort * racine))
	# Deux places ne se confondent JAMAIS : sous le pas minimal, on rouvre la spirale sur ce pas-là et on rentre
	# le tout dans l'écran à la fin (la boucle de clampage ci-dessous s'en charge).
	_tas_pas = maxf(minf(etendue.x, etendue.y) / racine, TAS_PAS_MIN)
	etendue = etendue.max(Vector2(_tas_pas, _tas_pas) * racine)
	_places = []
	for k in n:
		var a: float = float(k) * ANGLE_OR
		var u: float = sqrt(float(k)) / racine                        # √k : une spirale d'AIRE constante
		var p := c + Vector2(cos(a) * etendue.x, sin(a) * etendue.y) * u
		_places.append(Vector2(clampf(p.x, borne.position.x, borne.end.x),
			clampf(p.y, borne.position.y, borne.end.y)))
	_repartition = "tas empilé de %d pièces sous le modèle (spirale, pas %.1f px, étendue %.0f × %.0f)" \
		% [n, _tas_pas, etendue.x * 2.0, etendue.y * 2.0]


# LE CANVAS A CHANGÉ. On ne rebâtit rien : on RECALCULE la mise en page et on TRANSPORTE ce qui existe. Les pièces
# gardent leur position RELATIVE au plateau (et donc les blocs déjà emboîtés restent emboîtés, puisque
# l'aimantation ne regarde que des ÉCARTS) — une partie en cours survit à un redimensionnement.
func _redimensionne() -> void:
	if not _maj_ecran():
		return
	var ancien_coin := _plateau.position
	var ancienne_e := _echelle
	_calculer_mise_en_page()
	var f: float = _echelle / ancienne_e
	for i in _pos.size():
		_pos[i] = _plateau.position + (_pos[i] - ancien_coin) * f
	_refaire_geometrie()
	_dire("canvas redimensionné → %s · échelle %.4f (× %.3f) · zone %s" % [str(_ecran), _echelle, f, str(_zone.size)])


# Redessiner ce qui dépend de l'échelle : le plateau, les contours des pièces, leurs cibles, le panneau, le zoom.
func _refaire_geometrie() -> void:
	var coin := _plateau.position
	if _fond_plateau != null:
		var p := PackedVector2Array([coin, coin + Vector2(_plateau.size.x, 0.0), coin + _plateau.size,
			coin + Vector2(0.0, _plateau.size.y)])
		_fond_plateau.polygon = p
		if _cadre_plateau != null:
			_cadre_plateau.points = p
	for i in _noeud.size():
		var r := i / _cols
		var c := i % _cols
		var centre_img := Vector2((float(c) + 0.5) * _cellule.x, (float(r) + 0.5) * _cellule.y)
		var forme := PackedVector2Array()
		for p2 in _contour[i]:
			forme.append((p2 - centre_img) * _echelle)
		_noeud[i].polygon = forme
		for enfant in _noeud[i].get_children():
			if enfant is Line2D:
				(enfant as Line2D).points = forme
		_cible[i] = coin + centre_img * _echelle
		_noeud[i].position = _pos[i]
	_cacher_suggestion()
	_batir_ihm()
	_borner_pan()
	_appliquer_zoom()
	# (B10) LE CURSEUR DESSINÉ SUIT LE NOUVEAU CANVAS : sa taille en descend (`_k_curseur`) et sa pointe doit être
	# rebornée — un téléphone qu'on tourne rendrait sinon la pointe hors de l'écran, donc invisible.
	if _curseur_pose:
		_curseur_vise = Vector2(clampf(_curseur_vise.x, 0.0, _ecran.x), clampf(_curseur_vise.y, 0.0, _ecran.y))
	_maj_curseur_doigt()
	# (B12) …et la pièce qu'on tenait quand le téléphone a tourné reste sous la pointe : l'état ne bouge pas, il
	# se lit dans `_saisi`.
	_recoller_piece()
	_poser_lisere_prise()            # (§24) …ni le liseré derrière la pièce : il se refait à la nouvelle échelle


# ------------------------------------------------------------------------------------------------------------
# ① TAILLER — les bords d'abord, les contours ensuite
# ------------------------------------------------------------------------------------------------------------
func _tailler() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GRAINE
	# LES BORDS HORIZONTAUX. r = 0 et r = _rangs sont le CADRE de l'image : droits, sans languette (`s = 0`) —
	# un puzzle a des pièces de bord, c'est ce qui permet à l'enfant de commencer par le tour.
	_bord_h = []
	for r in _rangs + 1:
		var rangee: Array = []
		for c in _cols:
			var a := Vector2(float(c) * _cellule.x, float(r) * _cellule.y)
			var b := Vector2(float(c + 1) * _cellule.x, float(r) * _cellule.y)
			var s := 0 if (r == 0 or r == _rangs) else (1 if rng.randi() % 2 == 0 else -1)
			rangee.append(_polyligne_bord(a, b, s))
		_bord_h.append(rangee)
	# LES BORDS VERTICAUX, même chose : c = 0 et c = _cols sont le cadre.
	_bord_v = []
	for r in _rangs:
		var rangee: Array = []
		for c in _cols + 1:
			var a := Vector2(float(c) * _cellule.x, float(r) * _cellule.y)
			var b := Vector2(float(c) * _cellule.x, float(r + 1) * _cellule.y)
			var s := 0 if (c == 0 or c == _cols) else (1 if rng.randi() % 2 == 0 else -1)
			rangee.append(_polyligne_bord(a, b, s))
		_bord_v.append(rangee)

	# LE CONTOUR D'UNE PIÈCE = ses quatre bords mis bout à bout, dans le sens des aiguilles d'une montre :
	# le haut à l'endroit, la droite à l'endroit, le bas À L'ENVERS, la gauche À L'ENVERS. Ce sont les deux
	# « à l'envers » qui font toute l'affaire : la pièce d'en dessous relira le MÊME bas, à l'endroit, elle.
	_contour = []
	for r in _rangs:
		for c in _cols:
			var pts := PackedVector2Array()
			_coudre(pts, _bord_h[r][c], false)          # haut : gauche → droite
			_coudre(pts, _bord_v[r][c + 1], false)      # droite : haut → bas
			_coudre(pts, _bord_h[r + 1][c], true)       # bas : droite → gauche (le bord de la voisine du dessous)
			_coudre(pts, _bord_v[r][c], true)           # gauche : bas → haut (le bord de la voisine de gauche)
			_contour.append(pts)
	_dire("découpe faite : %d contours · %d points au total · languette = %.3f de la longueur d'un bord"
		% [_contour.size(), _total_points(), LANGUETTE])


# Un bord, de `a` à `b`, avec une languette de signe `s` (+1 d'un côté, −1 de l'autre, 0 = droit).
# Voir l'encadré « LA FORME D'UNE PIÈCE » : congé — tête — congé, tous tangents entre eux.
func _polyligne_bord(a: Vector2, b: Vector2, s: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(a)
	if s != 0:
		var d := b - a
		var lg := d.length()
		var u := d / lg
		var n := Vector2(-u.y, u.x) * float(s)   # la perpendiculaire ; `s` décide de quel côté la tête sort
		var r := (KNOB_W * KNOB_W + KNOB_CY * KNOB_CY - KNOB_R * KNOB_R) / (2.0 * (KNOB_R + KNOB_CY))
		var centre := Vector2(0.5, KNOB_CY)
		var f1 := Vector2(0.5 - KNOB_W, r)
		var f2 := Vector2(0.5 + KNOB_W, r)
		var alpha: float = (centre - f1).angle()     # direction congé → tête : c'est là qu'ils se touchent
		# ① le congé de gauche : de la droite (−90°) au point de tangence avec la tête (alpha)
		for k in range(1, PAS_CONGE + 1):
			var th: float = lerpf(-PI / 2.0, alpha, float(k) / float(PAS_CONGE))
			pts.append(_local(a, u, n, lg, f1 + r * Vector2(cos(th), sin(th))))
		# ② la tête : 292° d'arc, du point de tangence de gauche à celui de droite en passant PAR LE HAUT
		for k in range(1, PAS_TETE + 1):
			var th: float = lerpf(alpha + PI, -alpha, float(k) / float(PAS_TETE))
			pts.append(_local(a, u, n, lg, centre + KNOB_R * Vector2(cos(th), sin(th))))
		# ③ le congé de droite : miroir du premier, il redescend sur la droite (270°)
		for k in range(1, PAS_CONGE + 1):
			var th: float = lerpf(PI - alpha, 3.0 * PI / 2.0, float(k) / float(PAS_CONGE))
			pts.append(_local(a, u, n, lg, f2 + r * Vector2(cos(th), sin(th))))
	pts.append(b)
	return pts


# (t, h) du repère du bord → coordonnées image.
func _local(a: Vector2, u: Vector2, n: Vector2, lg: float, q: Vector2) -> Vector2:
	return a + u * (q.x * lg) + n * (q.y * lg)


# Ajoute une polyligne au contour, éventuellement à l'envers, sans redoubler le point de raccord.
func _coudre(dans: PackedVector2Array, bord: PackedVector2Array, envers: bool) -> void:
	var n := bord.size()
	for k in n:
		var p := bord[n - 1 - k] if envers else bord[k]
		if dans.size() > 0 and dans[dans.size() - 1].is_equal_approx(p):
			continue
		dans.append(p)


# ------------------------------------------------------------------------------------------------------------
# ② LE PLATEAU, LES PIÈCES, LE PANNEAU
# ------------------------------------------------------------------------------------------------------------
func _batir_plateau() -> void:
	_jeu = Node2D.new()
	_jeu.name = "Jeu"
	add_child(_jeu)
	var coin := _plateau.position
	# Le plateau : un rectangle sombre à peine dessiné, qui DIT où l'image va se refaire sans la montrer.
	var fond := Polygon2D.new()
	fond.name = "Plateau"
	fond.polygon = PackedVector2Array([coin, coin + Vector2(_plateau.size.x, 0.0),
		coin + _plateau.size, coin + Vector2(0.0, _plateau.size.y)])
	fond.color = Color(1.0, 1.0, 1.0, 0.07)
	_jeu.add_child(fond)
	_fond_plateau = fond
	var cadre := Line2D.new()
	cadre.points = fond.polygon
	cadre.closed = true
	cadre.width = 3.0
	cadre.default_color = Color(1.0, 1.0, 1.0, 0.30)
	_jeu.add_child(cadre)
	_cadre_plateau = cadre
	# (B2) LE CALQUE DES SUGGESTIONS, posé ICI et pas ailleurs : il doit être DERRIÈRE les pièces (une place qui
	# clignote par-dessus la pièce qu'on déplace cacherait le jeu) mais DEVANT le plateau. Il est ajouté à `_jeu`,
	# donc il suit le zoom comme le reste : la place clignote au bon endroit quelle que soit la vue.
	_sugg_calque = Node2D.new()
	_sugg_calque.name = "Suggestion"
	_sugg_calque.visible = false
	_jeu.add_child(_sugg_calque)
	_sugg_forme = Polygon2D.new()
	_sugg_forme.color = Color(SUGG_ROUGE.r, SUGG_ROUGE.g, SUGG_ROUGE.b, SUGG_ALPHA_MIN)
	_sugg_calque.add_child(_sugg_forme)
	_sugg_lisere = Line2D.new()
	_sugg_lisere.closed = true
	_sugg_lisere.width = SUGG_LISERE_LARGEUR
	_sugg_lisere.default_color = SUGG_ROUGE
	_sugg_calque.add_child(_sugg_lisere)
	# (B7) LE CALQUE DE LA PIÈCE, et pourquoi c'en est un SECOND et non deux nœuds de plus dans le premier : les
	# deux moitiés de la suggestion ne vivent pas au même étage. La PLACE doit rester DERRIÈRE les pièces (sans
	# quoi elle masquerait celle qu'on déplace) ; la PIÈCE doit être DEVANT TOUTES (sans quoi le tas la cache —
	# c'est exactement ce que Fabrice a vu). Un seul calque ne peut pas être aux deux étages à la fois.
	_sugg_calque_piece = Node2D.new()
	_sugg_calque_piece.name = "SuggestionPiece"
	_sugg_calque_piece.visible = false
	_jeu.add_child(_sugg_calque_piece)
	_sugg_piece_forme = Polygon2D.new()
	_sugg_piece_forme.color = Color(SUGG_ROUGE.r, SUGG_ROUGE.g, SUGG_ROUGE.b, SUGG_ALPHA_MIN)
	_sugg_calque_piece.add_child(_sugg_piece_forme)
	_sugg_piece_lisere = Line2D.new()
	_sugg_piece_lisere.closed = true
	_sugg_piece_lisere.width = SUGG_LISERE_LARGEUR
	_sugg_piece_lisere.default_color = SUGG_ROUGE
	_sugg_calque_piece.add_child(_sugg_piece_lisere)
	# (§24) LE CALQUE DU LISERÉ DE PRISE — un TROISIÈME calque, et non un nœud de plus dans celui de la
	# suggestion-pièce : les deux n'ont ni la même durée de vie (l'un dure le temps d'une main posée, l'autre six
	# secondes), ni la même pièce (on peut tenir la pièce A pendant que la suggestion désigne la pièce B), ni le
	# même étage (celui-ci passe encore par-dessus). Un calque partagé les ferait s'effacer l'un l'autre.
	# ⚠ Il est ajouté ICI, donc AVANT les pièces (`_batir_pieces` vient ensuite) : sans le `move_child` de
	#   `_poser_lisere_prise`, le tas passerait devant lui. C'est le remontage à chaque image qui le tient au
	#   sommet, exactement comme `_pulser_suggestion` le fait pour la suggestion-pièce.
	# ⚠ Et il n'entre PAS dans le compte des pièces : `_rang_des_pieces` lit le rang RÉEL de chaque `_noeud`,
	#   il ne suppose aucun décalage fixe — un calque de plus dans `_jeu` ne dérange donc ni la prise ni le
	#   harnais.
	_prise_calque = Node2D.new()
	_prise_calque.name = "LiserePrise"
	_prise_calque.visible = false
	_jeu.add_child(_prise_calque)
	_prise_lisere = Line2D.new()
	_prise_lisere.closed = true
	_prise_lisere.width = PRISE_LISERE_LARGEUR
	_prise_lisere.default_color = PRISE_LISERE_BLANC
	_prise_calque.add_child(_prise_lisere)


func _batir_pieces() -> void:
	var coin := _plateau.position
	_noeud = []
	_cible = []
	_pos = []
	_groupe = []
	for i in _contour.size():
		var r := i / _cols
		var c := i % _cols
		var centre_img := Vector2((float(c) + 0.5) * _cellule.x, (float(r) + 0.5) * _cellule.y)
		# ⚠ LE POINT TECHNIQUE DE LA BALLE (B1) : le `Polygon2D` porte DEUX listes de points, et elles ne vivent
		#   pas dans le même monde. `polygon` est la forme À L'ÉCRAN (centrée sur la pièce, à l'échelle du
		#   plateau) ; `uv` est le MORCEAU D'IMAGE à y peindre, en pixels de l'image d'origine. Les découpler
		#   ainsi, c'est ce qui permet d'afficher un puzzle taillé dans une image de 956 × 1120 sans jamais
		#   redécouper l'image : une seule texture en mémoire, quinze fenêtres dessus. Et c'est aussi ce qui rend
		#   le responsive de B2 possible sans rien redécouper : seul `polygon` change quand l'échelle change.
		var poly := Polygon2D.new()
		poly.name = "Piece%02d" % i
		poly.texture = _image
		poly.antialiased = true
		var forme := PackedVector2Array()
		var uv := PackedVector2Array()
		for p in _contour[i]:
			forme.append((p - centre_img) * _echelle)
			uv.append(p)
		poly.polygon = forme
		poly.uv = uv
		# Le liseré : sans lui, deux pièces voisines à peine décalées se lisent comme une seule tache. Il est
		# sombre et fin — luminance, pas couleur (CLAUDE.md, daltonien).
		var lisere := Line2D.new()
		lisere.points = forme
		lisere.closed = true
		lisere.width = 2.0
		lisere.default_color = Color(0.05, 0.05, 0.08, 0.85)
		poly.add_child(lisere)
		_jeu.add_child(poly)
		_noeud.append(poly)
		_cible.append(coin + centre_img * _echelle)
		_pos.append(_cible[i])
		_groupe.append(i)


# LE PANNEAU — modèle réduit, compte, aide. Reconstruit à chaque changement de canvas : il n'y a pas un pixel
# écrit en dur ici, tout se pose dans le rectangle `_panneau` calculé plus haut (à droite en paysage, en bas en
# portrait). Il vit sur un `CanvasLayer` : il ne zoome donc PAS avec le plateau (cf. l'encadré du zoom).
func _batir_ihm() -> void:
	if _ihm != null:
		_ihm.queue_free()
	_ihm = CanvasLayer.new()
	_ihm.name = "Panneau"
	add_child(_ihm)
	_batir_maison()
	_batir_recadrer()
	_batir_reserve()
	_rafraichir_compte()


# (B3) LA PETITE MAISON — le retour à l'accueil, DANS LE PANNEAU (cf. ⑨ de l'encadré de tête).
# ⚠ Elle est bâtie AVANT le reste du panneau, et les deux dispositions lui réservent sa place (en paysage tout
#   descend sous elle ; en portrait la colonne de texte se raccourcit d'autant) : aucun libellé ne passe dessous.
# ⚠ Elle ne se montre QUE pendant le jeu. Sur la fête et sur l'image finale, c'est l'écran de victoire qui porte
#   sa propre maison — deux maisons visibles en même temps, dont une derrière un voile, se contrediraient.
func _batir_maison() -> void:
	var r := cadre_maison()
	_btn_maison = _bouton_icone(r, "maison", "Revenir à l'accueil", _retour_accueil)
	_btn_maison.name = "BoutonMaison"
	_btn_maison.visible = (_etat == Etat.JEU)
	_ihm.add_child(_btn_maison)


# LE RECTANGLE DE LA MAISON — rendu au jeu ET au harnais, pour que la mesure et la mise en page lisent le même
# nombre. En paysage : le coin HAUT-DROIT du panneau (donc de l'écran). En portrait : le bout DROIT du bandeau.
func cadre_maison() -> Rect2:
	return Rect2(Vector2(_panneau.end.x - MAISON_MARGE - MAISON_TAILLE.x, _panneau.position.y + MAISON_MARGE),
		MAISON_TAILLE)


# (B6) LE BOUTON RECADRER — « quand il veut revoir son puzzle, il retrouve l'image qu'il a eue au départ, aussi
# grande que possible » (Fabrice, GDD §10 bis). Il vit À GAUCHE DE LA MAISON, sur la même ligne du haut de la
# réserve : c'est le geste de secours d'un joueur qui s'est éloigné dans son plan de travail, il doit être là où
# l'œil le cherche — avec la sortie, jamais dans l'aire de jeu.
func cadre_recadrer() -> Rect2:
	var m := cadre_maison()
	return Rect2(m.position - Vector2(MAISON_TAILLE.x + MAISON_MARGE, 0.0), MAISON_TAILLE)


func _batir_recadrer() -> void:
	_btn_recadrer = _bouton_icone(cadre_recadrer(), "recadrer",
		"Revenir sur le puzzle (barre d'espace)", _recadrer_sur_puzzle)
	_btn_recadrer.name = "BoutonRecadrer"
	_btn_recadrer.visible = (_etat == Etat.JEU)
	_ihm.add_child(_btn_recadrer)


# (B23 · §31.3) ⚠ CE QUI ÉTAIT ICI A ÉTÉ SUPPRIMÉ, ET LA TRACE RESTE : `_batir_prendre()`, `cadre_prendre()` et
# `_bouton_prise_actif()` construisaient et gardaient le bouton PRENDRE ⇄ POSER de B12 (§21.3). Fabrice a décidé
# le 14-09 de le supprimer. Rien ne les remplace — c'est `_input` qui prend et pose, au doigt, directement.
#
# ⚠⚠ ET LE PIÈGE DE B14 MEURT AVEC EUX, IL FAUT LE DIRE : `_batir_ihm()` s'exécute AVANT `_poser_curseur()`, donc
#   le bouton était bâti sur un `_curseur` qui n'avait pas encore été relu. B14 avait dû, pour ça, avancer
#   `_curseur = CurseursPuzzle.lire_choix()` tout en haut de `_ready()`. Cette ligne RESTE (le curseur dessiné en
#   dépend aussi), mais plus rien dans la construction de l'IHM ne dépend désormais du curseur choisi : l'ordre
#   des deux appels n'est plus un piège, il n'est plus qu'un ordre.


# (B14) LE JEU EST-IL EN MODE « SANS CURSEUR » ? Rendu au harnais, qui n'a ainsi pas à refaire la lecture du
# réglage — et posé sur `_curseur`, la valeur que CETTE scène a lue, jamais sur le fichier relu entre-temps.
func sans_curseur() -> bool:
	return CurseursPuzzle.sans_curseur(_curseur)


# CE QUE LA FLÈCHE MONTRE — la VÉRITÉ du jeu, relue, jamais recopiée (cf. l'encadré des constantes).
func piece_prise() -> bool:
	return _saisi >= 0


# (B23 · §31.3) ⚠ SUPPRIMÉS AVEC LE BOUTON : `logo_bouton()`, `fleche_bouton_locale()`, `fleche_bouton()` et la
# constante `ICONE_MARGE` qui leur servait. Ils ne dessinaient QUE le glyphe du bouton PRENDRE ⇄ POSER.
# ⚠ `icone/icone_puzzle_512.png` N'EST PAS SUPPRIMÉE POUR AUTANT : elle reste l'icône de fenêtre du jeu et celle
#   des quatre paquets (B11). Ce qui disparaît, c'est son usage comme glyphe de bouton, pas le fichier.


# (B6) LA RÉSERVE — LE COMPTE EN HAUT, LE MODÈLE AU MILIEU, LE TAS EN DESSOUS. Et **RIEN D'ÉCRIT SOUS LE
# MODÈLE** : c'est la demande de Fabrice au mot (GDD §10), et c'est ce qui libère la place du tas.
#
# ⚠⚠ CE QUI A DISPARU ICI, ET POURQUOI CE N'EST PAS UNE PERTE : le titre « Le jeu des puzzles », l'étiquette
#   « Le modèle » et les huit lignes d'aide (« prends une pièce, pose-la près de sa voisine… »). Elles occupaient
#   exactement la place que Fabrice réclame pour le tas, et elles s'adressaient à un enfant qui, pour la plupart,
#   ne lit pas encore : ce jeu s'apprend en tirant une pièce, pas en lisant un mode d'emploi. Le COMPTE, lui,
#   reste — il dit où on en est — mais il remonte AU-DESSUS du modèle, sur la ligne des boutons.
func _batir_reserve() -> void:
	_compteur = _ecrire("", _compte_rect.position + Vector2(0.0, 4.0), 18, _compte_rect.size.x)
	_compteur.name = "Compteur"
	_modele(_modele_rect.position, _modele_rect.size)


func _modele(pos: Vector2, taille: Vector2) -> void:
	var modele := TextureRect.new()
	modele.name = "Modele"
	# ⚠⚠ L'ORDRE DE CES TROIS LIGNES EST LA MISE EN PAGE ELLE-MÊME, ET IL N'EST PAS ÉVIDENT (leçon B1) :
	#   tant que `expand_mode` vaut son DÉFAUT (`EXPAND_KEEP_SIZE`), la taille MINIMALE d'un `TextureRect` est
	#   celle de sa texture — ici 956 × 1120. Poser `size` avant `expand_mode` fait donc REMONTER la taille de
	#   force, et le « modèle réduit » recouvre tout le panneau. Mesuré, pas supposé.
	#   → `expand_mode` D'ABORD, `size` ENSUITE.
	modele.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	modele.stretch_mode = TextureRect.STRETCH_SCALE
	modele.texture = _image
	modele.position = pos
	modele.size = taille
	# (B6) LE MODÈLE SE DOUBLE-CLIQUE (GDD §10). Il prend donc la souris et le doigt — et c'est aussi ce qui
	# l'empêche de laisser passer un clic vers une pièce du tas qui traînerait dessous.
	modele.mouse_filter = Control.MOUSE_FILTER_STOP
	modele.tooltip_text = "Double-clic : voir le modèle en grand"
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
	modele.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	modele.gui_input.connect(_modele_entree)
	_ihm.add_child(modele)
	_modele_vue = modele
	var bordure := Line2D.new()
	bordure.points = PackedVector2Array([pos, pos + Vector2(taille.x, 0.0), pos + taille, pos + Vector2(0.0, taille.y)])
	bordure.closed = true
	bordure.width = 2.0
	bordure.default_color = Color(1.0, 1.0, 1.0, 0.55)
	_ihm.add_child(bordure)


func _ecrire(texte: String, pos: Vector2, taille: int, largeur: float) -> Label:
	var l := Label.new()
	l.text = texte
	l.position = pos
	l.size = Vector2(largeur, 0.0)
	l.add_theme_font_size_override("font_size", taille)
	# (B6) UN LIBELLÉ NE PREND JAMAIS LA SOURIS : depuis que les pièces s'empilent DANS la réserve, un mot qui
	# intercepte le clic est une pièce qu'on ne peut plus attraper. Posé explicitement, jamais supposé du défaut.
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ihm.add_child(l)
	return l


# ============================================================================================================
# (B6) LE MODÈLE EN PLEIN ÉCRAN — « double-clic sur le modèle → plein écran ; double-clic à nouveau → retour »
#
# ⚠⚠ POURQUOI LE DOUBLE-CLIC EST COMPTÉ ICI ET NON LU DANS `evt.double_click` : ce drapeau-là est posé par la
#   couche système (X11, Windows…) et il n'existe NI au doigt (Android, iOS — la demande vise les quatre cibles)
#   NI dans un événement poussé par un harnais. Deux appuis rapprochés, c'est une mesure de temps : on la fait,
#   et le même code répond alors à la souris, au doigt et à la preuve. Le drapeau système, quand il est là, est
#   honoré en plus — un vrai double-clic de bureau ouvre donc au premier coup.
# ⚠ ET LE PLEIN ÉCRAN DU MODÈLE N'EST PAS CELUI DE LA VICTOIRE : il vit sur SON calque (25), il se referme, et
#   il ne touche ni à l'état du jeu ni aux pièces. Le puzzle est simplement caché le temps qu'on regarde.
# ============================================================================================================
func _modele_entree(evt: InputEvent) -> void:
	var appui := false
	if evt is InputEventMouseButton:
		var mb := evt as InputEventMouseButton
		appui = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		if appui and mb.double_click:
			_basculer_modele_plein()
			return
	elif evt is InputEventScreenTouch:
		appui = (evt as InputEventScreenTouch).pressed
	if not appui:
		return
	var t := Time.get_ticks_msec()
	if t - _dernier_appui <= DOUBLE_CLIC_MS:
		_dernier_appui = -9999                       # un triple clic n'ouvre pas puis ne referme pas aussitôt
		_basculer_modele_plein()
	else:
		_dernier_appui = t


func _basculer_modele_plein() -> void:
	if _modele_plein:
		_fermer_modele_plein()
	else:
		_ouvrir_modele_plein()


func _ouvrir_modele_plein() -> void:
	if _modele_plein or _etat != Etat.JEU:
		return
	_modele_plein = true
	_modele_ouvertures += 1
	_maj_curseur_doigt()             # (B10) rien à viser derrière le modèle en grand : le curseur dessiné s'efface
	_modele_calque = CanvasLayer.new()
	_modele_calque.name = "ModelePleinEcran"
	_modele_calque.layer = 25                        # au-dessus de la réserve (défaut 0), sous l'écran de fin (30)
	add_child(_modele_calque)
	var porteur := Control.new()
	porteur.name = "PorteurModelePlein"
	porteur.position = Vector2.ZERO
	porteur.size = _ecran
	# C'est LUI qui reçoit le double-clic de retour : le fond entier est la cible, pas un bouton à viser.
	porteur.mouse_filter = Control.MOUSE_FILTER_STOP
	porteur.gui_input.connect(_modele_entree)
	_modele_calque.add_child(porteur)
	var fond := ColorRect.new()
	fond.color = Color(0.0, 0.0, 0.0, 1.0)           # noir plein : le modèle garde son rapport, le reste est bande
	fond.position = Vector2.ZERO
	fond.size = _ecran
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	porteur.add_child(fond)
	var r := rect_plein_ecran()
	var vue := TextureRect.new()
	vue.name = "ModeleEnGrand"
	vue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vue.stretch_mode = TextureRect.STRETCH_SCALE
	vue.texture = _image
	vue.position = r.position
	vue.size = r.size
	vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# (B23 · §31.6) LE MÊME FILTRE QUE LE MODÈLE RÉDUIT — ici l'image est le plus souvent AGRANDIE, et sur une
	# magnification un échantillonneur à mipmaps se comporte exactement comme le bilinéaire (niveau 0). C'est donc
	# gratuit, et ça couvre le cas d'un grand tableau sur un petit canvas, où il réduit quand même.
	vue.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	porteur.add_child(vue)
	_dire("MODÈLE EN PLEIN ÉCRAN (ouverture n° %d) — %.0f × %.0f, rapport tenu · double-clic pour revenir"
		% [_modele_ouvertures, r.size.x, r.size.y])


func _fermer_modele_plein() -> void:
	if not _modele_plein:
		return
	_modele_plein = false
	if _modele_calque != null:
		_modele_calque.queue_free()
		_modele_calque = null
	_maj_curseur_doigt()             # (B10) le puzzle revient, la pointe avec lui — à la place où elle était
	_dire("MODÈLE : retour au puzzle (le plein écran est refermé)")


func rect_modele_plein() -> Rect2:
	return rect_plein_ecran()


func _rafraichir_compte() -> void:
	# LE COMPTE — un LIBELLÉ, pas une couleur (CLAUDE.md : daltonien, luminance + libellé). Sur deux lignes dans
	# la colonne de droite, sur une seule dans le bandeau du bas : c'est la place disponible qui décide.
	if _compteur == null:
		return
	# (B13 · §21.8) UNE SEULE ÉCRITURE : la colonne de droite est le seul endroit où le compte vit désormais (le
	# bandeau du bas, où il tenait sur une ligne, n'existe plus).
	_compteur.text = "Pièces accrochées :\n%d sur %d" % [_plus_gros_bloc(), _cols * _rangs]


# L'éparpillement : chaque pièce va sur une des quinze places, tirées dans un ordre mélangé (graine fixe).
func _eparpiller() -> void:
	var rng := RandomNumberGenerator.new()
	# (B3) LE MÉLANGE SUIT LE NUMÉRO DE PARTIE. À la première (`melange = 0`), la graine vaut GRAINE + 1 : c'est
	# EXACTEMENT le désordre de B1/B2, au pixel près — rien n'est défait. À chaque « Rejouer », `melange` monte
	# d'un et la graine change : les quinze pièces repartent d'un désordre neuf, sur le même tableau et avec les
	# mêmes pièces. Le multiplicateur est un nombre premier : deux parties voisines ne se ressemblent pas.
	rng.seed = GRAINE + 1 + melange * 7919
	var ordre: Array = []
	for i in _contour.size():
		ordre.append(i)
	# mélange de Fisher-Yates, à graine fixe : le même désordre à chaque lancement
	for i in range(ordre.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = ordre[i]
		ordre[i] = ordre[j]
		ordre[j] = t
	for k in ordre.size():
		_poser(ordre[k], _places[k] if k < _places.size() else _tas_utile.get_center())
		# (B6) L'ORDRE D'EMPILEMENT EST L'ORDRE DE POSE — c'est ce qui fait un TAS et non une superposition
		# arbitraire : la spirale va du centre vers le bord, donc les dernières jetées couvrent les premières,
		# comme des pièces versées d'une boîte. C'est aussi ce que `_prendre` défait, en attrapant celle du dessus.
		_jeu.move_child(_noeud[ordre[k]], _jeu.get_child_count() - 1)
	_dire("%d pièces versées EN TAS sous le modèle (%s) — elles se chevauchent, c'est la demande" \
		% [_contour.size(), _repartition])


func _poser(i: int, p: Vector2) -> void:
	_pos[i] = p
	_noeud[i].position = p


# ------------------------------------------------------------------------------------------------------------
# ③ JOUER — prendre, glisser, lâcher ; l'aimantation ; et (B2) le zoom
# ------------------------------------------------------------------------------------------------------------
# ⚠⚠ LE POINT QUI FAIT QUE LE ZOOM NE CASSE NI LA PRISE NI L'AIMANTATION : tout ce qui vient de la souris est
#   traduit UNE FOIS, ici, du repère de l'ÉCRAN vers le repère du JEU (`_vers_jeu`). En aval, `_prendre`,
#   `_glisser`, `_emboiter` et les quinze positions continuent de travailler dans le repère du plateau, exactement
#   comme en B1 — ils ne savent même pas qu'un zoom existe. C'est aussi ce qui garde la tolérance d'aimantation
#   JUSTE : elle est en unités de plateau, donc zoomer rend le geste plus précis À L'ÉCRAN sans jamais rendre
#   l'accroche plus facile ou plus difficile.
func _input(evt: InputEvent) -> void:
	if _etat != Etat.JEU:
		return
	# (B6) LE MODÈLE EST OUVERT EN GRAND : le puzzle est derrière, on n'y touche pas. Seul le calque du modèle
	# écoute (son porteur, par `gui_input`) — plus la touche Échap, qui referme sans viser.
	if _modele_plein:
		if evt is InputEventKey and (evt as InputEventKey).pressed and (evt as InputEventKey).keycode == KEY_ESCAPE:
			_fermer_modele_plein()
		return
	# (B6) LES DEUX TOUCHES DU CLAVIER : espace recadre sur le puzzle (GDD §10 bis), Échap n'a rien à fermer ici.
	if evt is InputEventKey:
		var k := evt as InputEventKey
		if k.pressed and not k.echo and k.keycode == KEY_SPACE:
			_recadrer_sur_puzzle()
		return
	# --- le tactile : c'est le NOMBRE DE DOIGTS qui décide. UN doigt joue — et depuis B10 il joue PAR LA POINTE
	#     DU CURSEUR DESSINÉ, pas par la pulpe ; DEUX doigts zooment et déplacent la vue (inchangé).
	if evt is InputEventScreenTouch:
		var t := evt as InputEventScreenTouch
		# (B23 · §31.3) ⚠ CE QUI ÉTAIT ICI : la porte du bouton PRENDRE ⇄ POSER, et l'exclusion du doigt qui le
		#   tenait (`_doigt_bouton`) du comptage des doigts. Le bouton supprimé, chaque doigt posé est un doigt de
		#   JEU — un doigt joue, deux doigts zooment, comme avant B12.
		if t.pressed:
			_doigts[t.index] = t.position
		else:
			_doigts.erase(t.index)
		if _doigts.size() >= 2:
			if not _pincement:
				_pincement = true
				# ⚠⚠ (B23 · §31.3) DEUX DOIGTS ⇒ **ON LÂCHE LA PIÈCE**, ET C'EST LE GESTE DE B10 RETROUVÉ. Le refus
				#   de pincement pièce en main (§21.4, B13) n'avait de sens qu'AVEC le bouton : la pièce y restait
				#   prise sans qu'aucun doigt ne la tienne, donc un second doigt ne créait aucune ambiguïté. Au
				#   doigt direct, la pièce EST tenue par le premier doigt — un doigt qui traîne une pièce et deux
				#   doigts qui zooment redeviennent le même geste, et le trancher en silence ferait sauter la
				#   pièce. On lâche, ce qui est visible et sans surprise.
				if _saisi >= 0:
					_lacher()                    # on ne traîne pas une pièce pendant qu'on zoome
				_amorcer_pince()
			return
		if _doigts.is_empty():
			_pincement = false
			_pince_ecart = 0.0
		if not _tactile:
			return
		# (B10) UN SEUL DOIGT — LE CURSEUR LE SUIT, ET C'EST SA POINTE QUI PREND LA PIÈCE.
		# ⚠ ON NE REPREND PAS LA VISÉE AVEC LE DERNIER DOIGT D'UNE PINCE (`_pincement`) : sans ce filet, finir un
		#   zoom ramènerait le curseur sous le doigt qui reste, et l'enfant verrait sa visée sauter toute seule.
		if t.pressed:
			if _pincement:
				return
			_doigt_vise = t.index                # (B13) c'est CE doigt qui tient la visée (cf. les `Drag`)
			_poser_curseur_doigt(t.position)
			# LE PANNEAU N'EST PAS UNE AIRE DE JEU (règle de B6, tenue au doigt comme à la souris) : la maison, le
			# recadrage et le modèle se pressent AU DOIGT (Godot leur envoie la souris émulée à la position du
			# DOIGT) — on ne leur vole pas le geste en attrapant la pièce du dessous en même temps.
			if _sur_hud(t.position):
				return
			# ⚠⚠ (B23 · §31.3) L'APPUI **PREND**, ET LE LEVER **POSE** — le doigt direct, dans les deux modes.
			#   C'était déjà le chemin du mode « sans curseur » (§22) ; il devient le SEUL. Ce que la prise vise,
			#   ce n'est pas la pulpe mais `_curseur_vise` — la POINTE du curseur dessiné (B10), ou le doigt
			#   lui-même quand il n'y a pas de curseur (le décalage est alors nul). C'est ce qui garde la
			#   précision que §21.6 réclamait, sans le bouton qui la payait.
			_prendre(_vers_jeu(_curseur_vise))
		else:
			_lacher()
		return
	elif evt is InputEventScreenDrag:
		var d := evt as InputEventScreenDrag
		_doigts[d.index] = d.position
		if _pincement and _doigts.size() >= 2:
			_pincer()
			_maj_curseur_doigt()
			return
		if not _tactile or _pincement:
			return
		# ⚠ (B13 · §21.4 → B23) UN SEUL DOIGT VISE, ET C'EST CELUI QUI VISAIT. Le filet reste utile sans le
		#   bouton : entre le 2ᵉ appui et l'amorce de la pince, un `Drag` du doigt surnuméraire pourrait encore
		#   commander le curseur et faire sauter la pièce sous lui.
		if _saisi >= 0 and _doigts.size() >= 2 and d.index != _doigt_vise:
			return
		_poser_curseur_doigt(d.position)
		if _saisi >= 0:
			_glisser(_vers_jeu(_curseur_vise))
		return
	# --- la souris
	# ⚠⚠ (B10) AU DOIGT, ON S'ARRÊTE ICI. `project.godot` porte les DEUX émulations croisées depuis B1
	#   (`emulate_mouse_from_touch` ET `emulate_touch_from_mouse`) : chaque appui arrive donc AUSSI en clic de
	#   souris, à la position du DOIGT. Sans cette ligne, un même appui prendrait la pièce DEUX fois — une par la
	#   pointe (juste) et une par la pulpe, 40 à 90 px plus bas (fausse). Les boutons, eux, ne passent pas par
	#   `_input` : ils continuent de recevoir cette souris émulée et se pressent au doigt comme avant.
	if _tactile:
		return
	if evt is InputEventMouseButton:
		var mb := evt as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoomer_autour(mb.position, ZOOM_PAS_MOLETTE)
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoomer_autour(mb.position, 1.0 / ZOOM_PAS_MOLETTE)
			return
		# (B6) LE BOUTON DROIT DÉPLACE LA VUE — le pendant souris des deux doigts. Sans lui, un joueur de bureau
		# qui a dézoomé pour se faire un plan de travail ne pourrait pas s'y promener : il n'y a pas de deuxième
		# doigt sur une souris, et la molette seule ne fait que grossir.
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_pan_souris = mb.pressed
			_pan_dernier = mb.position
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and not _pincement:
			if mb.pressed:
				# (B6) LE HUD N'EST PAS UNE AIRE DE JEU. Depuis que le tas vit DANS la réserve, une pièce peut
				# traîner sous la maison, sous le recadrage ou sous le modèle : sans ce filtre, cliquer la maison
				# attraperait la pièce du dessous en même temps (`_input` passe AVANT les boutons). Mesuré.
				if _sur_hud(mb.position):
					return
				_prendre(_vers_jeu(mb.position))
			else:
				_lacher()
	elif evt is InputEventMouseMotion:
		var mm := evt as InputEventMouseMotion
		if _pan_souris:
			_pan += mm.position - _pan_dernier
			_pan_dernier = mm.position
			_borner_pan()
			_appliquer_zoom()
		elif _saisi >= 0 and not _pincement:
			_glisser(_vers_jeu(mm.position))


# LES TROIS RECTANGLES QUE LE JEU NE TOUCHE PAS : la maison, le recadrage, le modèle. (Le compte est un libellé
# qui laisse passer la souris — cf. `_ecrire` — donc il n'en est pas.)
# ⚠ (B23 · §31.3) LE BOUTON PRENDRE/POSER EN ÉTAIT LE QUATRIÈME : il en sort avec lui. Et **rien ne le remplace
#   par un trou** — c'était le défaut assumé de B14, où la PLACE du bouton restait réservée en bas de la colonne
#   gauche ; elle est maintenant rendue au modèle, donc il n'existe plus un seul rectangle de l'écran où l'enfant
#   verrait du vide et ne pourrait pas prendre une pièce.
func _sur_hud(p: Vector2) -> bool:
	return cadre_maison().has_point(p) or cadre_recadrer().has_point(p) or _modele_rect.has_point(p)


# ============================================================================================================
# (B23 · §31.3) ⚠ `_basculer_prise()` ET `_maj_bouton_prendre()` ONT ÉTÉ SUPPRIMÉS AVEC LE BOUTON.
#   La première portait la bascule PRENDRE ⇄ POSER (§21.3) et ses trois compteurs (`_prises_bouton`,
#   `_poses_bouton`, `_prendre_vides`) ; la seconde montrait ou cachait le bouton. Prendre et poser passent
#   désormais par `_prendre()` et `_lacher()`, appelés directement par l'appui et le lever du doigt — le MÊME
#   code que la souris de bureau, donc l'aimantation, le compte des pièces et la victoire sont inchangés.
# ============================================================================================================


# LA PIÈCE PRISE RESTE **SOUS LA POINTE** QUAND LA VUE BOUGE (zoom, recadrage, déplacement à deux doigts).
#
# ⚠⚠ POURQUOI IL FAUT UNE LIGNE POUR ÇA, ALORS QUE « RIEN NE BOUGE » : la pointe du curseur vit en coordonnées
#   d'ÉCRAN (le curseur est « ce qui n'est pas induit par les effets de zoom », §21.4) tandis que la pièce vit en
#   coordonnées de JEU. Zoomer déplace donc l'une par rapport à l'autre : sans ce recollage, la pièce prise
#   s'écarterait de la pointe, puis SAUTERAIT de tout cet écart au premier glissé suivant (`_prise_ecart` est figé
#   à la prise).
# ⚠⚠ (B23 · §31.3) SA GARDE ÉTAIT `_bouton_prise_actif()` ; ELLE DEVIENT `_tactile`, ET C'EST LE MÊME PÉRIMÈTRE
#   QU'AVANT — le bouton n'existait QUE sur tactile. Au bureau ça ne s'exécute donc toujours jamais : là, une
#   pièce n'est tenue que pendant un maintien de bouton de souris, et molette + maintien changeraient un
#   comportement que §21.5 demande de ne pas toucher.
func _recoller_piece() -> void:
	if _saisi < 0 or not _tactile:
		return
	_glisser(_vers_jeu(_curseur_vise))


# La pièce prise est la PLUS HAUTE de la pile sous le doigt — celle qu'on voit. `is_point_in_polygon` travaille
# sur le VRAI contour, languettes comprises : on attrape une pièce par sa languette, comme sur une table.
func _prendre(p: Vector2) -> void:
	# On descend la pile de dessin À L'ENVERS (du dernier enfant vers le premier) : la pièce qu'on attrape est
	# celle qu'on VOIT — et c'est ce qui fait qu'un TAS se joue par le haut (B6). Les premiers enfants de `_jeu`
	# sont le plateau, son cadre et le calque des suggestions : ils n'ont pas de rang de pièce, on passe.
	# (B6) ⚠ Le rang se lit dans un dictionnaire et non par `_noeud.find(enfant)` : cf. `_rang_des_pieces`.
	var rang := _rang_des_pieces()
	for k in range(_jeu.get_child_count() - 1, -1, -1):
		if not rang.has(k):
			continue
		var i: int = int(rang[k])
		if Geometry2D.is_point_in_polygon(p - _pos[i], _noeud[i].polygon):
			_saisi = i
			_prise_ecart = _pos[i] - p
			for j in _bloc(_groupe[i]):
				_jeu.move_child(_noeud[j], _jeu.get_child_count() - 1)   # le bloc pris passe DEVANT
			# (§24) …et le liseré blanc se pose DANS LA MÊME IMAGE. L'attendre du `_process` suivant le ferait
			# apparaître une image après la pièce — visible à l'œil sur une prise franche, et impossible à
			# mesurer proprement dans un harnais qui lit l'état juste après l'événement.
			_montrer_lisere_prise()
			_dire("prise : pièce %d (bloc de %d) en %s — liseré blanc posé sur sa forme"
				% [i, _bloc(_groupe[i]).size(), str(_pos[i])])
			return


func _glisser(p: Vector2) -> void:
	if _saisi < 0:
		return
	var delta := (p + _prise_ecart) - _pos[_saisi]
	_bouger_bloc(_groupe[_saisi], delta)


func _lacher() -> void:
	if _saisi < 0:
		return
	var i := _saisi
	_saisi = -1
	_cacher_lisere_prise()           # (§24) la main s'ouvre, le liseré se retire — pas d'image de retard
	var n := _emboiter(_groupe[i])
	if n > 0:
		_dire("emboîtement : %d accroche(s) — le bloc fait maintenant %d pièces" % [n, _bloc(_groupe[i]).size()])
	_rafraichir_compte()
	# (B2) L'ENFANT VIENT DE JOUER : le compte des quinze secondes repart de zéro et la suggestion en cours
	# s'efface (cf. l'encadré des suggestions — on n'aide que celui qui cherche).
	_t_sugg = 0.0
	_cacher_suggestion()
	if _plus_gros_bloc() == _cols * _rangs and _etat == Etat.JEU:
		_gagne()


func _bouger_bloc(g: int, delta: Vector2) -> void:
	for j in _bloc(g):
		_pos[j] += delta
		_noeud[j].position = _pos[j]


func _bloc(g: int) -> Array:
	var l: Array = []
	for j in _groupe.size():
		if _groupe[j] == g:
			l.append(j)
	return l


func _plus_gros_bloc() -> int:
	var comptes := {}
	var maxi := 0
	for g in _groupe:
		comptes[g] = int(comptes.get(g, 0)) + 1
		maxi = maxi if maxi > int(comptes[g]) else int(comptes[g])
	return maxi


# Les quatre voisines d'une pièce dans la grille — et elles seules : deux pièces qui ne se touchent pas dans
# l'image n'ont aucune raison de s'accrocher, même posées côte à côte.
func _voisines(i: int) -> Array:
	var r := i / _cols
	var c := i % _cols
	var l: Array = []
	if r > 0:
		l.append(i - _cols)
	if r < _rangs - 1:
		l.append(i + _cols)
	if c > 0:
		l.append(i - 1)
	if c < _cols - 1:
		l.append(i + 1)
	return l


# L'AIMANTATION. Une pièce du bloc `g` et une voisine d'un AUTRE bloc s'accrochent si l'écart entre elles est,
# à `_tol_aimant` près, l'écart qu'elles auront dans l'image finie. On déplace alors tout le bloc `g` de l'erreur
# exacte — donc l'ajustement est PARFAIT, pas « à peu près » — et les deux blocs n'en font plus qu'un.
# La boucle recommence tant que ça accroche : poser une pièce au bon endroit peut souder trois blocs d'un coup.
func _emboiter(g: int) -> int:
	var fusions := 0
	var encore := true
	while encore:
		encore = false
		var meilleur_i := -1
		var meilleur_j := -1
		var meilleure_err := Vector2.ZERO
		var meilleure_d := _tol_aimant + 1.0
		for i in _bloc(g):
			for j in _voisines(i):
				if _groupe[j] == g:
					continue
				var err: Vector2 = (_pos[j] - _pos[i]) - (_cible[j] - _cible[i])
				var d := err.length()
				if d <= _tol_aimant and d < meilleure_d:
					meilleure_d = d
					meilleur_i = i
					meilleur_j = j
					meilleure_err = err
		if meilleur_i >= 0:
			_bouger_bloc(g, meilleure_err)                  # le bloc qu'on tient vient se caler sur l'autre
			var vieux: int = _groupe[meilleur_j]
			for k in _groupe.size():
				if _groupe[k] == vieux:
					_groupe[k] = g
			fusions += 1
			_emboitements += 1
			encore = true
	return fusions


# ------------------------------------------------------------------------------------------------------------
# (B2) LE ZOOM — la vue grossit, le jeu ne change pas
# ------------------------------------------------------------------------------------------------------------
# Le nœud `_jeu` porte le plateau ET les quinze pièces : le zoomer, c'est zoomer la scène entière d'un bloc, sans
# toucher à une seule position. `p_écran = p_jeu × zoom + pan` — et `_vers_jeu` est l'inverse exact.
func _vers_jeu(p: Vector2) -> Vector2:
	return (p - _pan) / _zoom


func _appliquer_zoom() -> void:
	if _jeu == null:
		return
	_jeu.scale = Vector2(_zoom, _zoom)
	_jeu.position = _pan


# ZOOMER AUTOUR D'UN POINT : ce qui est sous le pointeur (ou entre les deux doigts) y RESTE. C'est la seule façon
# de zoomer qui ne fasse pas fuir la pièce qu'on regardait.
func _zoomer_autour(p_ecran: Vector2, facteur: float) -> void:
	var z2: float = clampf(_zoom * facteur, ZOOM_PLANCHER, ZOOM_MAX)
	if is_equal_approx(z2, _zoom):
		return
	var ancre := _vers_jeu(p_ecran)
	_zoom = z2
	_pan = p_ecran - ancre * _zoom
	_borner_pan()
	_appliquer_zoom()
	_dezoom_mini = minf(_dezoom_mini, _zoom)
	_recoller_piece()                    # (B12) la pièce prise reste sous la pointe — cf. `_recoller_piece`
	_dire("zoom %.3f× (plafond %.1f · dézoom LIBRE) autour de %s" % [_zoom, ZOOM_MAX, str(p_ecran)])


# ============================================================================================================
# (B6) LE PLAN DE TRAVAIL — ce qui remplace le bornage au canvas de B2 (GDD §10 bis)
#
# ⚠⚠ CE QUE B2 BORNAIT, ET POURQUOI ÇA NE PEUT PLUS TENIR : il interdisait à la vue de sortir du CANVAS. Tant que
#   tout le jeu tenait dans l'écran, c'était juste. Depuis que Fabrice demande de « reculer la caméra et faire
#   des petits tas », le joueur pose ses familles de pièces HORS de l'écran de départ : les borner au canvas
#   reviendrait à lui reprendre le plan de travail qu'on vient de lui donner.
# ⚠ CE QUI EST BORNÉ MAINTENANT : le CENTRE DE LA VUE reste dans le plan de travail — c'est-à-dire le rectangle
#   qui contient le plateau ET toutes les pièces, débordé d'un écran de chaque côté. Deux conséquences voulues :
#     ① le plan GRANDIT quand le joueur écarte ses tas (il suit les pièces, il ne les précède pas) ;
#     ② on ne peut pas se perdre dans le vide : au pire on voit un écran de noir, avec le puzzle juste à côté —
#        et le bouton RECADRER ramène tout d'un geste.
# ============================================================================================================
func _plan_travail() -> Rect2:
	var r := _plateau
	for i in _pos.size():
		r = r.merge(Rect2(_pos[i] - _boite * 0.5, _boite))
	var m := _ecran * PLAN_MARGE
	return r.grow_individual(m.x, m.y, m.x, m.y)


func _borner_pan() -> void:
	var plan := _plan_travail()
	var demi := _ecran * 0.5
	# pan = demi − centre_vue × zoom ; borner le centre de la vue, c'est borner le pan à l'envers.
	_pan.x = clampf(_pan.x, demi.x - plan.end.x * _zoom, demi.x - plan.position.x * _zoom)
	_pan.y = clampf(_pan.y, demi.y - plan.end.y * _zoom, demi.y - plan.position.y * _zoom)


# RECADRER SUR LE PUZZLE — « il retrouve l'image qu'il a eue au départ, AUSSI GRANDE QUE POSSIBLE » (Fabrice).
# On cadre le PLATEAU (l'image en cours d'assemblage) dans la zone de jeu : au premier appel d'une partie neuve,
# ça rend exactement la vue de départ, puisque la mise en page a déjà posé le plateau au plus grand dans la zone.
func _recadrer_sur_puzzle() -> void:
	if _plateau.size.x <= 0.0 or _plateau.size.y <= 0.0:
		return
	var z: float = RECADRE_MARGE * minf(_zone.size.x / _plateau.size.x, _zone.size.y / _plateau.size.y)
	_zoom = clampf(z, ZOOM_PLANCHER, ZOOM_MAX)
	_pan = _zone.get_center() - _plateau.get_center() * _zoom
	_borner_pan()
	_appliquer_zoom()
	_recoller_piece()                    # (B12) recadrer pendant qu'on tient une pièce ne la laisse pas derrière
	_recadrages += 1
	_dire("RECADRAGE (n° %d) — la vue revient sur le puzzle, au plus grand : zoom %.3f×, plateau %.0f × %.0f à l'écran"
		% [_recadrages, _zoom, _plateau.size.x * _zoom, _plateau.size.y * _zoom])


func _amorcer_pince() -> void:
	var l: Array = _doigts.values()
	if l.size() < 2:
		return
	_pince_ecart = (l[0] as Vector2).distance_to(l[1] as Vector2)
	_pince_centre = ((l[0] as Vector2) + (l[1] as Vector2)) * 0.5


# LE PINCEMENT — et sa ZONE MORTE, qui vient d'un retour de Fabrice sur le 7 différences : sans elle, un
# balayage à deux doigts (qui veut DÉPLACER) fait varier l'écart de quelques pixels et dézoome tout seul. En deçà
# de 8 px de variation, deux doigts déplacent ; au-delà, ils zooment. Les deux gestes cohabitent sans se gêner.
func _pincer() -> void:
	var l: Array = _doigts.values()
	if l.size() < 2:
		return
	var a := l[0] as Vector2
	var b := l[1] as Vector2
	var ecart := a.distance_to(b)
	var centre := (a + b) * 0.5
	if _pince_ecart > 0.0:
		if absf(ecart - _pince_ecart) > PINCE_ZONE_MORTE:
			_zoomer_autour(centre, ecart / _pince_ecart)
			_pince_ecart = ecart
		_pan += centre - _pince_centre
		_borner_pan()
		_appliquer_zoom()
		_recoller_piece()                # (B12) le déplacement à deux doigts non plus n'arrache pas la pièce
	else:
		_pince_ecart = ecart
	_pince_centre = centre


# ------------------------------------------------------------------------------------------------------------
# (B2) LES SUGGESTIONS — toutes les 15 s, la bonne place clignote (GDD §8.2)
# ------------------------------------------------------------------------------------------------------------
# QUELLE PIÈCE ON MONTRE, ET POURQUOI CELLE-LÀ. On cherche une pièce qui n'est PAS dans le plus gros bloc — donc
# une pièce qu'il reste à rattacher — et, parmi celles-là, on préfère une VOISINE du plus gros bloc : sa place est
# collée à ce qui est déjà fait, l'enfant n'a pas à traverser le plateau. Si rien n'est encore emboîté (quinze
# blocs d'une pièce), on montre la pièce n° 0, le coin en haut à gauche : commencer par un coin, c'est ce qu'on
# apprend à un enfant devant un puzzle. Et d'une suggestion à l'autre on prend la SUIVANTE des candidates, pour ne
# pas répéter la même quatre fois de suite.
func _piece_a_suggerer() -> int:
	var gros := _groupe_du_plus_gros_bloc()
	var taille_gros := _bloc(gros).size()
	if taille_gros >= _cols * _rangs:
		return -1                                    # le puzzle est fait : il n'y a plus rien à suggérer
	if taille_gros <= 1:
		return 0                                     # rien n'est encore accroché → on montre le coin
	var voisines: Array = []
	var autres: Array = []
	for i in _groupe.size():
		if _groupe[i] == gros:
			continue
		var touche := false
		for j in _voisines(i):
			if _groupe[j] == gros:
				touche = true
				break
		if touche:
			voisines.append(i)
		else:
			autres.append(i)
	var candidates: Array = voisines if not voisines.is_empty() else autres
	if candidates.is_empty():
		return -1
	return int(candidates[_sugg_rang % candidates.size()])


func _groupe_du_plus_gros_bloc() -> int:
	var comptes := {}
	for g in _groupe:
		comptes[g] = int(comptes.get(g, 0)) + 1
	var meilleur := _groupe[0]
	for g in comptes.keys():
		if int(comptes[g]) > int(comptes[meilleur]):
			meilleur = int(g)
	return int(meilleur)


func _montrer_suggestion() -> void:
	var i := _piece_a_suggerer()
	if i < 0:
		return
	_sugg_i = i
	_sugg_t = 0.0
	_sugg_rang += 1
	_suggestions += 1
	# LA BONNE PLACE : la forme exacte de la pièce, dessinée à SA CIBLE sur le plateau. C'est le trou à combler.
	var forme: PackedVector2Array = _noeud[i].polygon
	var a_la_cible := PackedVector2Array()
	for p in forme:
		a_la_cible.append(p + _cible[i])
	_sugg_forme.polygon = a_la_cible
	_sugg_lisere.points = a_la_cible
	# (B7) ET LA PIÈCE, DANS SA VRAIE FORME, LÀ OÙ ELLE TRAÎNE — plus un rectangle : le contour exact, rempli et
	# cerné. `_pulser_suggestion` le reposera à chaque image (l'enfant peut la déplacer pendant que ça clignote).
	_poser_forme_piece()
	# (B7) ET ELLE REMONTE SUR LE TAS. Décision de Code exposée au brief §1 : dans un tas (B6), la pièce désignée
	# est souvent à demi couverte — la montrer sans la rendre PRENABLE, ce serait désigner ce qu'on ne peut pas
	# attraper. Elle passe au sommet, et elle y RESTE : la renfouir juste quand l'enfant tend la main lui
	# reprendrait l'aide. C'est le même geste que `_prendre` fait déjà quand on saisit une pièce.
	if _etat == Etat.JEU and _jeu != null and is_instance_valid(_noeud[i]):
		_jeu.move_child(_noeud[i], _jeu.get_child_count() - 1)
	_sugg_calque.visible = true
	_sugg_calque_piece.visible = true
	_dire("SUGGESTION (%d) : la PIÈCE %d (en %s) et SA PLACE (%s) clignotent en rouge, en ANTI-PHASE (%.2f s)"
		% [_suggestions, i, str(_pos[i]), str(_cible[i]), SUGG_PULSE])


func _cacher_suggestion() -> void:
	_sugg_i = -1
	if _sugg_calque != null:
		_sugg_calque.visible = false
	if _sugg_calque_piece != null:
		_sugg_calque_piece.visible = false


# LA PULSATION — LE CŒUR DE B7. Une SEULE sinusoïde `u` : la PIÈCE la suit, la PLACE suit `1 − u`. C'est ce qui
# rend l'anti-phase exacte à toute image et à toute fréquence — deux horloges dériveraient, et un décalage écrit
# en secondes dépendrait de la période. Quand l'une s'allume, l'autre s'éteint : « un effet d'œil que l'un va
# vers l'autre, et vice versa » (Fabrice, GDD §11 bis).
# L'alpha porte le signal (luminance) et le liseré le double : rien ne repose sur la teinte seule (CLAUDE.md).
func _pulser_suggestion(dt: float) -> void:
	if _sugg_i < 0:
		return
	_sugg_t += dt
	if _sugg_t >= SUGG_DUREE:
		_cacher_suggestion()
		return
	_sugg_u = 0.5 + 0.5 * sin(TAU * _sugg_t / SUGG_PULSE)
	var v: float = 1.0 - _sugg_u                     # la PLACE : l'exacte opposée de la pièce
	_sugg_piece_forme.color = _rouge(_sugg_u, SUGG_ALPHA_MIN, SUGG_ALPHA_MAX)
	_sugg_piece_lisere.default_color = _rouge(_sugg_u, SUGG_LISERE_MIN, SUGG_LISERE_MAX)
	_sugg_forme.color = _rouge(v, SUGG_ALPHA_MIN, SUGG_ALPHA_MAX)
	_sugg_lisere.default_color = _rouge(v, SUGG_LISERE_MIN, SUGG_LISERE_MAX)
	# La pièce a pu bouger (l'enfant la déplace pendant que ça clignote) : sa forme la suit, au pixel.
	_poser_forme_piece()
	# …et le calque de la pièce reste AU SOMMET : prendre une pièce la fait passer devant (cf. `_prendre`), ce
	# qui recouvrirait la désignation. On le remonte à chaque image — c'est un seul `move_child`.
	if _jeu != null and _sugg_calque_piece != null:
		_jeu.move_child(_sugg_calque_piece, _jeu.get_child_count() - 1)


# LE CONTOUR EXACT DE LA PIÈCE DÉSIGNÉE, à sa place du moment — languettes comprises.
func _poser_forme_piece() -> void:
	if _sugg_i < 0 or not is_instance_valid(_noeud[_sugg_i]):
		return
	var chez_elle := PackedVector2Array()
	for p in _noeud[_sugg_i].polygon:
		chez_elle.append(p + _pos[_sugg_i])
	_sugg_piece_forme.polygon = chez_elle
	_sugg_piece_lisere.points = chez_elle


func _rouge(u: float, mini: float, maxi: float) -> Color:
	return Color(SUGG_ROUGE.r, SUGG_ROUGE.g, SUGG_ROUGE.b, lerpf(mini, maxi, u))


# ------------------------------------------------------------------------------------------------------------
# (§24) LE LISERÉ BLANC DE LA PIÈCE PRISE — le montrer, le cacher, le poser
# ------------------------------------------------------------------------------------------------------------
func _montrer_lisere_prise() -> void:
	_poser_lisere_prise()


func _cacher_lisere_prise() -> void:
	if _prise_calque != null:
		_prise_calque.visible = false


# LE CONTOUR EXACT DE LA PIÈCE TENUE, à sa place du moment — languettes comprises, comme `_poser_forme_piece`.
# ⚠ ON RELIT `_noeud[_saisi].polygon` À CHAQUE FOIS AU LIEU DE GARDER UNE COPIE : c'est ce qui fait suivre le
#   liseré quand le canvas change de taille (`_refaire_geometrie` réécrit les polygones à la nouvelle échelle).
#   Une copie prise à la saisie décrirait la pièce d'AVANT le redimensionnement.
# ⚠ ET LE GARDE-FOU N'EST PAS DÉCORATIF : `_saisi` n'est remis à −1 que par `_lacher`. Une pièce tenue au moment
#   où l'on gagne, où l'on rejoue ou où l'on change d'image laisserait un rang qui ne désigne plus rien.
func _poser_lisere_prise() -> void:
	if _prise_calque == null or _prise_lisere == null:
		return
	if _saisi < 0 or _saisi >= _noeud.size() or _etat != Etat.JEU or not is_instance_valid(_noeud[_saisi]):
		_prise_calque.visible = false
		return
	var chez_elle := PackedVector2Array()
	for p in _noeud[_saisi].polygon:
		chez_elle.append(p + _pos[_saisi])
	_prise_lisere.points = chez_elle
	_prise_calque.visible = true
	# AU SOMMET, à chaque image : `_prendre` fait passer le bloc pris devant, et une suggestion remonte le sien.
	# Sans ce geste, le liseré finirait SOUS la pièce qu'il cerne — c'est-à-dire invisible.
	if _jeu != null:
		_jeu.move_child(_prise_calque, _jeu.get_child_count() - 1)


# ------------------------------------------------------------------------------------------------------------
# ④ GAGNÉ → LA FÊTE → L'IMAGE EN PLEIN ÉCRAN (décision de Fabrice, GDD §7.5)
# ------------------------------------------------------------------------------------------------------------
func _gagne() -> void:
	_etat = Etat.RECOMPENSE
	_cacher_suggestion()
	_cacher_lisere_prise()           # (§24) la fête n'a plus de pièce à tenir : le liseré part avec le jeu
	_maj_curseur_doigt()             # (B10) le puzzle est fait : plus rien à viser, le curseur dessiné se retire
	# (B3) La maison du panneau se retire : à partir d'ici, c'est l'écran de victoire qui porte la sienne.
	if _btn_maison != null:
		_btn_maison.visible = false
	# (B6) …et le recadrage avec elle : la fête et l'image finale ne se cadrent pas, elles se regardent.
	if _btn_recadrer != null:
		_btn_recadrer.visible = false
	_fermer_modele_plein()
	# Le puzzle fini glisse à sa place sur le plateau : l'image se REPOSE là où le cadre l'annonçait.
	var delta := _cible[0] - _pos[0]
	_bouger_bloc(_groupe[0], delta)
	# (B2) La vue revient à l'image entière : la fête et le plein écran se regardent sans zoom.
	# (B6) …et « l'image entière » se dit maintenant RECADRER : le joueur peut avoir gagné en étant dézoomé à
	# l'autre bout de son plan de travail — remettre bêtement zoom 1 / pan 0 lui montrerait alors du vide.
	_recadrer_sur_puzzle()
	_dire("PUZZLE COMPLET — %d pièces en un seul bloc, recalé sur le plateau (%d emboîtements au total)"
		% [_cols * _rangs, _emboitements])
	# ============================================================================================================
	# (B4) GAGNER UN TABLEAU DÉBLOQUE LE SUIVANT (GDD §7.11, mécanique du 7 différences)
	# ⚠ C'EST ICI QUE ÇA SE JOUE, ET NON À LA FIN DE LA MUSIQUE OU AU RETOUR À L'ACCUEIL : le tableau est GAGNÉ à
	#   la quinzième pièce. Un enfant qui coupe le jeu pendant la fête a gagné quand même — sa progression est déjà
	#   écrite sur le disque. Faire dépendre le déblocage d'un écran qu'il faut regarder jusqu'au bout, ce serait
	#   lui reprendre ce qu'il vient de faire.
	# ============================================================================================================
	# ⚠⚠ (B15 · §23 quater) LA PROGRESSION EST CELLE DE **LA FAMILLE** — « dans chaque famille, c'est la
	#   progression qui débloque les puzzles suivants » (Fabrice). `noter_victoire` a gardé sa signature (elle
	#   prend l'index de table) et c'est elle qui retrouve la famille : gagner le dernier des 4 pièces n'ouvre
	#   RIEN dans les 15 pièces, et réciproquement. Le journal dit donc la famille, sinon deux chiffres identiques
	#   d'une famille à l'autre seraient impossibles à démêler dans une trace.
	var _f: int = TableauxPuzzle.famille_de(tableau)
	_progression_ouverte = ProgressionPuzzle.noter_victoire(tableau)
	if _progression_ouverte:
		_dire("PROGRESSION — famille « %s » (%d pièces) : le tableau %d de la famille est débloqué, sa flèche "
			% [TableauxPuzzle.cle_famille(_f), TableauxPuzzle.pieces_de_famille(_f),
				TableauxPuzzle.rang_dans_famille(tableau) + 2]
			+ "paraîtra à l'accueil (plus haut atteint dans cette famille : %d sur %d)"
			% [ProgressionPuzzle.plus_haut_famille(_f) + 1, TableauxPuzzle.nombre_dans_famille(_f)])
	else:
		_dire("PROGRESSION — rien de neuf à débloquer dans la famille « %s » (plus haut atteint : %d sur %d)"
			% [TableauxPuzzle.cle_famille(_f), ProgressionPuzzle.plus_haut_famille(_f) + 1,
				TableauxPuzzle.nombre_dans_famille(_f)])
	# ============================================================================================================
	# (B8) Y A-T-IL UN TABLEAU APRÈS CELUI-CI ? — la question est posée ICI, UNE FOIS, et sa réponse commande à
	# elle seule le 3ᵉ bouton de l'écran de fin ET le centrage des trois (cf. ㉕ en tête). Elle est posée à la
	# MÊME fonction que la flèche ▶ de l'accueil : les deux écrans ne peuvent pas se contredire.
	# ⚠ L'ORDRE COMPTE : la progression vient d'être écrite juste au-dessus. Gagner OUVRE la suite, et c'est cette
	#   suite-là qu'on offre — jamais une porte vers un tableau que l'accueil montrerait encore fermé.
	# ============================================================================================================
	# ⚠⚠ (B15) « LE SUIVANT » N'EST PLUS `tableau + 1` : c'est le suivant DANS LA FAMILLE
	#   (`TableauxPuzzle.suivant_dans_famille`). Avec les familles, l'index de table qui suit le dernier des
	#   15 pièces est le PREMIER des 4 pièces — un « niveau suivant » qui suivrait la table ferait sauter l'enfant
	#   d'une famille à l'autre, à rebours de l'âge, et lui donnerait un puzzle de 4 pièces en récompense d'un
	#   puzzle de 15. Au dernier tableau d'une famille, le bouton est ABSENT, exactement comme avant.
	_suivant_offert = ProgressionPuzzle.suivant_ouvert(tableau)
	var _suiv: int = TableauxPuzzle.suivant_dans_famille(tableau)
	if _suivant_offert:
		_dire("NIVEAU SUIVANT — il y a une suite DANS LA FAMILLE « %s » (« %s ») : l'écran de fin portera TROIS boutons"
			% [TableauxPuzzle.cle_famille(_f), TableauxPuzzle.nom(_suiv)])
	else:
		_dire("NIVEAU SUIVANT — dernier tableau de la famille « %s » (%d sur %d) : le bouton sera ABSENT, sa place n'est pas occupée"
			% [TableauxPuzzle.cle_famille(_f), TableauxPuzzle.rang_dans_famille(tableau) + 1,
				TableauxPuzzle.nombre_dans_famille(_f)])
	_lancer_recompense()


func _charger_recompense() -> void:
	var t0 := Time.get_ticks_msec()
	var d := DirAccess.open(DOSSIER_REC)
	if d == null:
		_rec_manque = DOSSIER_REC
		push_warning("[puzzle] dossier de récompense introuvable : " + DOSSIER_REC)
		return
	# ⚠ LE PIÈGE DU PCK, PAYÉ UNE FOIS PAR LE 7 DIFFÉRENCES (sa B7) ET REPRIS ICI SANS LE REPAYER : `get_files()`
	#   ne rend pas la même chose dans l'éditeur (« coc_000.png » ET « coc_000.png.import ») et dans un export
	#   (« coc_000.png.import » SEUL). On coupe donc les deux suffixes, et on DÉDOUBLONNE par dictionnaire —
	#   sans quoi l'éditeur compterait 480 planches pour 240 images, et la fête durerait deux fois son chant.
	var vus := {}
	for f in d.get_files():
		var n := f.trim_suffix(".remap").trim_suffix(".import")
		if n.ends_with(".png"):
			vus[n] = true
	var noms := vus.keys()
	noms.sort()                                    # coc_000 … coc_239 : l'ordre des noms EST l'ordre du temps
	_rec_planches = []
	for n in noms:
		var t := load("%s/%s" % [DOSSIER_REC, n]) as Texture2D
		if t != null:
			_rec_planches.append(t)
	if _rec_planches.is_empty():
		_rec_manque = DOSSIER_REC + " (aucune planche)"
		push_warning("[puzzle] aucune planche de récompense")
		return
	if ResourceLoader.exists(SON_REC):
		_rec_son = AudioStreamPlayer.new()
		_rec_son.stream = load(SON_REC)
		_rec_son.process_mode = Node.PROCESS_MODE_ALWAYS
		# (ACCUEIL-PHASE 1) ROUTÉ SUR LE BUS DU JEU — sans cette ligne, la barre de volume de l'accueil ne
		# commanderait que la musique de l'accueil, et « la barre pour régler le son » (Fabrice, GDD §20.1) ne
		# tiendrait qu'à moitié : le chant de la fête resterait à plein volume par-dessus un jeu baissé.
		SonPuzzle.router(_rec_son)
		add_child(_rec_son)
	else:
		_rec_manque = SON_REC
	_dire("récompense en mémoire : %d planches %s à %.0f im/s (%.1f s) + son %s — chargée en %d ms"
		% [_rec_planches.size(), str(_rec_planches[0].get_size()), REC_IM_PAR_S,
			float(_rec_planches.size()) / REC_IM_PAR_S,
			"OK" if _rec_son != null else "MANQUANT", Time.get_ticks_msec() - t0])


func _lancer_recompense() -> void:
	_rec_t = 0.0
	_rec_calque = CanvasLayer.new()
	_rec_calque.layer = 10
	add_child(_rec_calque)
	_rec_voile = ColorRect.new()
	_rec_voile.color = Color(0.0, 0.0, 0.0, 0.0)
	_rec_voile.size = _ecran
	_rec_voile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rec_calque.add_child(_rec_voile)
	var t := create_tween()
	t.tween_property(_rec_voile, "color:a", 0.55, 0.5)
	_rec_vue = TextureRect.new()
	_rec_vue.name = "Recompense"
	_rec_vue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rec_vue.stretch_mode = TextureRect.STRETCH_SCALE
	_rec_vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _rec_planches.is_empty():
		# (B2) L'agrandissement est plafonné par le canvas : la fête occupe le centre, elle n'en sort jamais —
		# sur un écran étroit elle rétrécit au lieu de déborder.
		var nat := Vector2(_rec_planches[0].get_size())
		var ech: float = minf(REC_AGRANDIR, minf(_ecran.x * 0.9 / nat.x, _ecran.y * 0.9 / nat.y))
		var s := nat * ech
		_rec_vue.size = s
		_rec_vue.position = _ecran * 0.5 - s * 0.5
		_rec_vue.texture = _rec_planches[0]
	_rec_calque.add_child(_rec_vue)
	if _rec_son != null:
		_rec_son.play()
	_dire("RÉCOMPENSE « coccos joyeuse » lancée — %d planches, %.1f s" % [_rec_planches.size(), _duree_recompense()])
	if _rec_planches.is_empty():
		_plein_ecran()                              # filet : pas de planches → on ne prive pas l'enfant de son image


func _duree_recompense() -> float:
	return float(_rec_planches.size()) / REC_IM_PAR_S


func _process(dt: float) -> void:
	# (B2) LE COMPTE DES QUINZE SECONDES — il ne tourne QUE pendant le jeu : ni pendant la fête, ni sur l'image
	# finale, et il repart à zéro dès que l'enfant pose une pièce (`_lacher`).
	if _etat == Etat.JEU:
		if _sugg_i >= 0:
			_pulser_suggestion(dt)
		else:
			_t_sugg += dt
			if _t_sugg >= SUGG_PERIODE:
				_t_sugg = 0.0
				_montrer_suggestion()
		# (§24) LE LISERÉ DE PRISE SUIT LA PIÈCE — et il est posé APRÈS la suggestion, à dessein :
		# `_pulser_suggestion` remonte SON calque au sommet à chaque image, donc le faire avant le laisserait
		# par-dessus la pièce tenue. Le dernier remonté gagne ; ce doit être la pièce sous la main.
		_poser_lisere_prise()
		return
	if _etat != Etat.RECOMPENSE or _rec_planches.is_empty():
		return
	_rec_t += dt
	var idx := int(_rec_t * REC_IM_PAR_S)
	if idx < _rec_planches.size():
		_rec_vue.texture = _rec_planches[idx]
		# Le fondu de sortie : la fête s'efface sur les 0,6 dernières secondes au lieu de se couper net.
		var reste := _duree_recompense() - _rec_t
		_rec_vue.modulate.a = clampf(reste / REC_FONDU, 0.0, 1.0)
	else:
		_plein_ecran()


# « Après la cinématique de la récompense, c'est l'image affichée en plein écran. » (Fabrice, 14-08)
#
# ⚠⚠ LE PIÈGE QU'IL FALLAIT ÉVITER (B1b) : le premier passage collait l'image sur 1024 × 768 pile, parce que la
#   capture erronée faisait EXACTEMENT la taille du canvas. Le vrai dessin est un portrait 956 × 1120 : l'étirer
#   sur un canvas couché lui donnerait 1,25 fois trop de largeur — un cheval écrasé, une coccinelle aplatie. On
#   garde donc le RAPPORT du dessin et on remplit ce qu'on peut :
#     échelle = min(canvas.x / 956 ; canvas.y / 1120) — sur 1024 × 768 : 0,6857, c'est la HAUTEUR qui commande
#     l'image occupe alors 655,5 × 768, centrée → deux bandes NOIRES de 184,2 px à gauche et à droite.
#   C'est un LETTERBOX (ici « pillarbox », les bandes sont verticales) : on montre tout le dessin, on n'en coupe
#   rien, on ne le déforme pas. Le harnais mesure les trois choses séparément : le rapport tenu, l'image juste À
#   L'INTÉRIEUR du cadre, et les bandes VRAIMENT noires.
# ⚠ (B2) LE CANVAS N'EST PLUS ÉCRIT : `rect_plein_ecran()` lit `_ecran`. Sur un 16:9 les bandes sont simplement
#   plus larges ; sur un écran debout, elles passent en haut et en bas. La règle est la même partout.
func _plein_ecran() -> void:
	if _etat == Etat.PLEIN_ECRAN:
		return
	_etat = Etat.PLEIN_ECRAN
	if _rec_son != null:
		_rec_son.stop()
	var calque := CanvasLayer.new()
	calque.layer = 20
	add_child(calque)
	# Un `Control` porteur : c'est LUI qu'on fait apparaître en fondu, pour que les bandes et l'image entrent
	# ensemble (un `CanvasLayer` n'a pas de `modulate` — le fondu ne peut pas s'y accrocher).
	var porteur := Control.new()
	porteur.name = "PleinEcran"
	porteur.position = Vector2.ZERO
	porteur.size = _ecran
	porteur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	porteur.modulate.a = 0.0
	calque.add_child(porteur)
	_pe_porteur = porteur
	var bandes := ColorRect.new()
	bandes.name = "Bandes"
	bandes.color = Color(0.0, 0.0, 0.0, 1.0)
	bandes.position = Vector2.ZERO
	bandes.size = _ecran
	bandes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	porteur.add_child(bandes)
	var r := rect_plein_ecran()
	# ⚠⚠ (B17 · §25) ICI SE JOUE LE « REMPLACE » DE FABRICE. Sur le tableau qui déclare une vidéo, l'image fixe
	#   n'est **pas posée du tout** : c'est le lecteur vidéo qui prend sa place, dans le même porteur, sur les
	#   mêmes bandes noires, avec le même fondu. Poser l'image PUIS la couvrir aurait donné, l'espace du fondu,
	#   le « plein écran fixe d'abord » que le choix n° 1 écarte — et aurait laissé dans l'arbre un nœud que le
	#   harnais aurait compté comme une image affichée. Les huit autres tableaux ne passent jamais par ici.
	if TableauxPuzzle.a_video(tableau):
		_batir_video(porteur)
	else:
		_final = TextureRect.new()
		_final.name = "ImagePleinEcran"
		# `expand_mode` avant `size` — même piège que le modèle réduit : tant qu'il vaut son défaut, la taille
		# minimale du nœud est celle de la TEXTURE, et le `size` posé avant se fait remonter de force.
		_final.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_final.stretch_mode = TextureRect.STRETCH_SCALE
		_final.texture = _image
		_final.position = r.position
		_final.size = r.size
		_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
		porteur.add_child(_final)
	var t := create_tween()
	t.tween_property(porteur, "modulate:a", 1.0, 0.8)
	if _rec_calque != null and _rec_calque.has_node("Recompense"):
		var t2 := create_tween()
		t2.tween_property(_rec_calque.get_node("Recompense") as CanvasItem, "modulate:a", 0.0, 0.4)
	if _video != null:
		var rv := rect_video()
		_dire("VIDÉO EN PLEIN ÉCRAN (§25 — elle REMPLACE l'image fixe) — %s, %.0f × %.0f, centrée en x=%.1f, "
			% [TableauxPuzzle.chemin_video(tableau).get_file(), rv.size.x, rv.size.y, rv.position.x]
			+ "bandes de %.1f px (rapport de la vidéo tenu, rien de coupé)" % rv.position.x)
	else:
		_dire("IMAGE COMPLÈTE EN PLEIN ÉCRAN — %.0f × %.0f à %.4f, centrée en x=%.1f, bandes de %.1f px (rapport tenu, rien de coupé)"
			% [r.size.x, r.size.y, r.size.y / _taille.y, r.position.x, r.position.x])
	# (B3) LE CALQUE DES BOUTONS DE FIN — au-dessus du plein écran (20), sinon le STOP serait derrière les bandes
	# noires et personne ne le verrait. Il est créé VIDE : ce qui s'y pose dépend de ce qui se passe ensuite.
	_fin_calque = CanvasLayer.new()
	_fin_calque.name = "FinDePartie"
	_fin_calque.layer = 30
	add_child(_fin_calque)
	# ⚠ ET LA MUSIQUE PART QUAND L'IMAGE EST POSÉE, PAS AVANT (cf. l'encadré ④ de l'écran de victoire) : on
	#   s'accroche à la FIN du fondu, pas à une durée recopiée à côté.
	t.finished.connect(_lancer_musique_tableau)


# Le rectangle que l'image occupe en plein écran : le plus grand qui tienne dans le canvas SANS changer le
# rapport du dessin. Rendu à la fois au jeu et au harnais — la mesure et la mise en page lisent le même nombre.
func rect_plein_ecran() -> Rect2:
	var e: float = minf(_ecran.x / _taille.x, _ecran.y / _taille.y)
	var s := _taille * e
	return Rect2((_ecran - s) * 0.5, s)


# (B17 · §25) LE RECTANGLE DE LA VIDÉO — **LA MÊME RÈGLE QUE L'IMAGE, SUR LA TAILLE DE LA VIDÉO**.
# ⚠ Elle n'a AUCUNE raison d'avoir la forme du dessin : ici le dessin est un portrait 896 × 1195 (0,750) et la
#   vidéo un CARRÉ 1024 × 1024 (1,000). Réutiliser `rect_plein_ecran()` l'étirerait de 33 % en hauteur — un chat
#   allongé. On reprend donc le calcul, pas le résultat : le plus grand rectangle qui tienne dans le canvas sans
#   changer le rapport, centré, le reste en bandes noires. Sur 1024 × 768 : 768 × 768, bandes de 128 px.
# ⚠ Si la taille native n'est pas déclarée (`Vector2.ZERO`), on retombe sur le cadre de l'image plutôt que de
#   diviser par zéro : un cadre imparfait vaut mieux qu'un écran de fin qui plante.
func rect_video() -> Rect2:
	var nat := TableauxPuzzle.taille_video(tableau)
	if nat.x <= 0.0 or nat.y <= 0.0:
		return rect_plein_ecran()
	var e: float = minf(_ecran.x / nat.x, _ecran.y / nat.y)
	var s := nat * e
	return Rect2((_ecran - s) * 0.5, s)


# LE LECTEUR VIDÉO, POSÉ MAIS **PAS ENCORE PARTI** — même discipline que la musique : rien ne sonne avant que
# l'écran soit en place. C'est `_lancer_musique_tableau`, accroché à la FIN du fondu, qui appuie sur lecture.
# ⚠⚠ `loop = false` EST ÉCRIT ICI, DANS LE CODE, et pas laissé au défaut : Fabrice demande la vidéo « UNE fois »
#   (§25), exactement comme la musique des autres tableaux. Le défaut du moteur va dans notre sens aujourd'hui —
#   ce n'est pas une raison pour ne pas dire la règle là où on la lira. Second verrou : `_video_passages`.
# ⚠ LE SON DE LA VIDÉO PASSE PAR LE BUS DU JEU (`JeuPuzzles`), sinon la barre de volume de l'accueil ne
#   l'atteindrait pas — le chant partirait à plein volume quand tout le reste est baissé. `VideoStreamPlayer`
#   n'est PAS un `AudioStreamPlayer` : `SonPuzzle.router()` ne l'accepte pas, on lui pose son bus à la main,
#   et seulement si le bus existe vraiment (le puzzle lancé seul par un harnais n'a pas traversé l'accueil).
func _batir_video(porteur: Control) -> void:
	var flux := TableauxPuzzle.video(tableau)
	if flux == null:
		# FILET : la vidéo est déclarée mais absente du paquet (la leçon d'export du 7 différences). On l'ÉCRIT,
		# et on retombe sur l'image fixe — l'enfant garde sa récompense, et l'adulte lit la cause au journal.
		_video_manque = TableauxPuzzle.chemin_video(tableau)
		push_warning("[puzzle] vidéo du tableau introuvable : " + _video_manque)
		_dire("VIDÉO MANQUANTE (%s) — repli sur l'image fixe en plein écran" % _video_manque)
		var r := rect_plein_ecran()
		_final = TextureRect.new()
		_final.name = "ImagePleinEcran"
		_final.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_final.stretch_mode = TextureRect.STRETCH_SCALE
		_final.texture = _image
		_final.position = r.position
		_final.size = r.size
		_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
		porteur.add_child(_final)
		return
	var rv := rect_video()
	_video = VideoStreamPlayer.new()
	_video.name = "VideoTableau"
	_video.stream = flux
	_video.expand = true                       # le lecteur remplit SON cadre, qui a déjà le rapport de la vidéo
	_video.autoplay = false
	_video.loop = false
	_video.paused = false
	_video.position = rv.position
	_video.size = rv.size
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.process_mode = Node.PROCESS_MODE_ALWAYS
	if SonPuzzle.index_bus() >= 0:
		_video.bus = SonPuzzle.BUS
	_video.finished.connect(_video_finie)
	porteur.add_child(_video)


# ============================================================================================================
# (B3) ⑤ L'ÉCRAN DE VICTOIRE — LA MUSIQUE DU TABLEAU, LE STOP, PUIS REJOUER ET LA MAISON (GDD §7.10)
#
# L'ENCHAÎNEMENT, DANS L'ORDRE OÙ FABRICE L'A DICTÉ, ET CE QUI LE DÉCLENCHE :
#   ① la quinzième pièce s'emboîte            → `_gagne`            (B1)
#   ② la récompense « coccos joyeuse » joue    → `_lancer_recompense` (B1)
#   ③ l'image complète paraît en plein écran   → `_plein_ecran`      (B1)
#   ④ **une fois l'image POSÉE** (le fondu de 0,8 s est allé au bout), la musique du tableau part — UNE FOIS.
#      ⚠ C'est le `finished` du fondu qui l'appelle, pas un compte à rebours écrit à côté : si un jour le fondu
#        change de durée, la musique suivra toute seule. Elle ne peut pas partir avant l'image.
#   ⑤ pendant qu'elle passe : le STOP à droite, triangle rouge — il l'arrête.
#   ⑥ à la fin de la musique **ou** au STOP : REJOUER et la MAISON apparaissent. Les deux, ensemble.
#
# ⚠ « UNE FOIS » EST TENU PAR UN COMPTEUR, PAS PAR UNE INTENTION : `_musique_passages` interdit un second départ,
#   et le flux lui-même est dupliqué avec `loop = false` (cf. `TableauxPuzzle.musique`). Deux verrous, parce
#   qu'une musique d'enfant qui repart en boucle sur un écran fixe est le genre de détail qu'on ne découvre que
#   chez l'utilisateur.
# ============================================================================================================
func _lancer_musique_tableau() -> void:
	if _musique_passages > 0:
		return                                     # le verrou du « une fois » (cf. l'encadré)
	# ⚠⚠ (B17 · §25) LA VIDÉO PREND LA PLACE DE LA MUSIQUE — pas en plus d'elle. Le tableau qui en a une porte
	#   son chant DANS la vidéo (« Maman je reviens ») : lancer aussi une musique de tableau ferait deux sons
	#   par-dessus l'autre. Et le point d'entrée reste le MÊME (la fin du fondu de l'image), donc la promesse
	#   de l'encadré ④ tient pour les deux : rien ne part avant que l'écran soit posé.
	if _video != null:
		_lancer_video_tableau()
		return
	var flux := TableauxPuzzle.musique(tableau)
	if flux == null:
		# FILET : la musique manque → on l'ÉCRIT, et on ne prive pas l'enfant de ses deux boutons. Un écran de fin
		# sans sortie serait pire que l'absence de musique.
		# ⚠⚠ (B15 · §23) DEUX SILENCES, DEUX CAUSES, ET ON NE LES CONFOND PAS. Un champ `musique` **VIDE** est
		#   une DÉCISION de Fabrice pour les quatre tableaux à 4 pièces (« pour le moment on n'a pas la musique »,
		#   §23) : ce n'est pas un défaut, et une alerte moteur (`push_warning`) au milieu d'un journal ferait
		#   chercher une panne qui n'existe pas. Un chemin ÉCRIT mais introuvable, lui, reste une panne — le
		#   fichier n'est pas entré dans le paquet, et c'est exactement la leçon d'export du 7 différences.
		_musique_manque = TableauxPuzzle.chemin_musique(tableau)
		if _musique_manque == "":
			_dire("PAS ENCORE DE MUSIQUE pour ce tableau (§23, décision de Fabrice : champ vide) — "
				+ "la récompense a été jouée, on passe directement aux boutons de fin")
		else:
			push_warning("[puzzle] musique du tableau introuvable : " + _musique_manque)
			_dire("musique du tableau MANQUANTE (%s) — on passe directement aux deux boutons" % _musique_manque)
		_montrer_boutons_fin()
		return
	_musique = AudioStreamPlayer.new()
	_musique.name = "MusiqueTableau"
	_musique.stream = flux
	_musique.process_mode = Node.PROCESS_MODE_ALWAYS
	_musique.finished.connect(_musique_finie)
	# (ACCUEIL-PHASE 1) ROUTÉ SUR LE BUS DU JEU — même raison que pour le son de la fête : le réglage de l'accueil
	# doit atteindre TOUT ce qui sonne ici. ⚠ Le bus peut ne pas exister (le puzzle lancé seul par un harnais n'a
	# pas traversé l'accueil) : `SonPuzzle.router` laisse alors le lecteur sur Master et ne prétend rien.
	SonPuzzle.router(_musique)
	add_child(_musique)
	_musique.play()
	_musique_passages += 1
	_musique_etat = "joue"
	_batir_stop()
	_dire("MUSIQUE DU TABLEAU « %s » — %s, %.1f s, UNE seule fois (passage n° %d) · le STOP rouge est à droite"
		% [TableauxPuzzle.nom(tableau), TableauxPuzzle.chemin_musique(tableau).get_file(),
			flux.get_length(), _musique_passages])


# (B17 · §25) LA VIDÉO PART — et à partir d'ici, tout est celui de la musique : l'état « joue », le STOP rouge
# à droite, puis les deux boutons à la fin OU au STOP. Un seul chemin, deux contenus.
func _lancer_video_tableau() -> void:
	if _video_passages > 0:
		return                                     # même verrou que la musique : UNE fois, jamais deux
	_video.play()
	_video_passages += 1
	_musique_etat = "joue"
	_batir_stop()
	_dire("VIDÉO DU TABLEAU « %s » — %s, %s, UNE seule fois (passage n° %d) · le chant est DANS la vidéo · "
		% [TableauxPuzzle.nom(tableau), TableauxPuzzle.chemin_video(tableau).get_file(),
			"bus " + _video.bus, _video_passages]
		+ "le STOP rouge est à droite")


func _video_finie() -> void:
	if _musique_etat != "joue":
		return
	_musique_etat = "finie"
	_dire("la vidéo est allée au bout (%.1f s jouées) — REJOUER et la MAISON apparaissent"
		% _video.stream_position)
	_montrer_boutons_fin()


func _musique_finie() -> void:
	if _musique_etat != "joue":
		return
	_musique_etat = "finie"
	_dire("la musique est allée au bout — REJOUER et la MAISON apparaissent")
	_montrer_boutons_fin()


# LE STOP — « un bouton STOP visible à droite, triangle rouge, qui arrête la musique » (Fabrice, mot pour mot).
# ⚠ ARRÊTER, C'EST FINIR : le brief dit « une fois la musique finie **ou stoppée** », les deux boutons
#   apparaissent. Le STOP n'est donc pas une pause — il clôt la séquence, exactement comme la dernière note.
func _musique_stop() -> void:
	if _musique_etat != "joue":
		return
	if _musique != null:
		_musique.stop()
	# (B17 · §25) LE MÊME BOUTON ARRÊTE LA VIDÉO — Fabrice demande « exactement comme la musique des autres
	# tableaux ».
	# ⚠⚠ ON MET EN PAUSE, ON N'APPELLE PAS `stop()`, ET LA RAISON EST L'ÉCRAN QUE L'ENFANT REGARDE. `stop()`
	#   rembobine le flux et VIDE l'affichage : le STOP rendrait alors un rectangle NOIR sous les deux boutons,
	#   alors que la vidéo arrivée au bout, elle, laisse sa dernière image. Deux fins pour une même séquence,
	#   dont une noire — le premier passage de la preuve l'a montré (capture de 9 ko contre 567). `paused`
	#   coupe le son et fige l'image : les deux sorties se ressemblent enfin, et aucune n'est un écran vide.
	#   ⚠ Ce n'est PAS une pause au sens du jeu : `_musique_etat` passe à « stoppee », les deux boutons
	#     paraissent, et rien ne peut relancer la lecture — le STOP disparaît avec elle.
	var quoi := "la musique"
	if _video != null:
		quoi = "la vidéo (figée sur son image de %.1f s)" % _video.stream_position
		_video.paused = true
	_musique_etat = "stoppee"
	_dire("STOP — %s est arrêtée par l'enfant · REJOUER et la MAISON apparaissent" % quoi)
	_montrer_boutons_fin()


func _batir_stop() -> void:
	if _fin_calque == null or _btn_stop != null:
		return
	var r := cadre_stop()
	_btn_stop = Button.new()
	_btn_stop.name = "BoutonStop"
	_btn_stop.flat = false
	_btn_stop.position = r.position
	_btn_stop.size = r.size
	_btn_stop.focus_mode = Control.FOCUS_NONE
	# (B17 · §25) L'infobulle dit CE QU'IL ARRÊTE — le glyphe, le libellé « STOP » et la place ne bougent pas
	# d'un pixel : c'est le même bouton, pas un second.
	_btn_stop.tooltip_text = "Arrêter la vidéo" if _video != null else "Arrêter la musique"
	for etat in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = COL_STOP if etat == "normal" else COL_STOP_SURVOL
		st.set_corner_radius_all(12)
		st.set_border_width_all(3)
		st.border_color = COL_ETIQUETTE          # bord clair franc : la FORME du bouton se lit sans la teinte
		_btn_stop.add_theme_stylebox_override(etat, st)
	_btn_stop.pressed.connect(_musique_stop)
	var ic := IconeDessinee.new()
	ic.ov = self
	ic.forme = "stop"
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fin_calque.add_child(_btn_stop)
	_btn_stop.add_child(ic)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_etiquette("STOP", r)


# LES BOUTONS DE LA FIN — REJOUER, la MAISON, et (B8) NIVEAU SUIVANT quand il y a une suite. Ensemble (GDD §7.10
# et §12).
# ⚠ Ils n'apparaissent QU'ICI, et cette fonction n'est appelée que par trois chemins : la musique finie, le STOP,
#   ou la musique manquante. Tant qu'elle joue, l'écran ne montre que l'image et le STOP — c'est la demande.
# ⚠ (B8) L'ORDRE DE LECTURE EST CELUI QUE FABRICE A DICTÉ — « Rejouer, ou aller à l'accueil… rajouter niveau
#   suivant » : REJOUER · ACCUEIL · SUIVANT, la suite venant en DERNIER, à droite, là où sa flèche pointe. Le
#   troisième n'est pas posé du tout quand il n'y a pas de suite : `_suivant_offert` commande, et `cadre_bouton_fin`
#   recentre alors les deux qui restent — l'écran du dernier tableau est EXACTEMENT celui d'avant B8.
func _montrer_boutons_fin() -> void:
	if _fin_calque == null or _btn_rejouer != null:
		return
	if _btn_stop != null:
		_btn_stop.visible = false                  # la musique est finie : le STOP n'a plus rien à arrêter
		var et: Node = _fin_calque.get_node_or_null("EtiquetteSTOP")
		if et != null:
			(et as CanvasItem).visible = false
	var rr := cadre_rejouer()
	_btn_rejouer = _bouton_icone(rr, "rejouer", "Rejouer le même tableau", _rejouer)
	_btn_rejouer.name = "BoutonRejouer"
	_fin_calque.add_child(_btn_rejouer)
	_etiquette("Rejouer", rr)
	var rm := cadre_maison_fin()
	_btn_maison_fin = _bouton_icone(rm, "maison", "Revenir à l'accueil", _retour_accueil)
	_btn_maison_fin.name = "BoutonMaisonFin"
	_fin_calque.add_child(_btn_maison_fin)
	_etiquette("Accueil", rm)
	# (B8) LE TROISIÈME, S'IL Y A UNE SUITE. Le mot sous le bouton est « Suivant » et non « Niveau suivant » : la
	# plaque fait la largeur du bouton (128 px) et deux mots à 18 pt en débordent — un libellé coupé ne double
	# rien. L'infobulle, elle, dit la phrase entière avec le NOM du tableau, pour l'adulte qui lit.
	if _suivant_offert:
		var rs := cadre_suivant()
		_btn_suivant = _bouton_icone(rs, "suivant_plus",
			"Niveau suivant — jouer « %s »" % TableauxPuzzle.nom(TableauxPuzzle.suivant_dans_famille(tableau)),
			_niveau_suivant)
		_btn_suivant.name = "BoutonSuivant"
		_fin_calque.add_child(_btn_suivant)
		_etiquette("Suivant", rs)
	_dire("écran de fin : REJOUER (flèche tournante), MAISON (accueil)%s sont posés — musique « %s »"
		% [" et NIVEAU SUIVANT (flèche + plus)" if _suivant_offert else " (pas de suivant : dernier tableau)",
			_musique_etat])


# REJOUER — « rejouer le MÊME tableau (re-mélange les 15 pièces) » (brief §2).
# ⚠ ON REMONTE LA SCÈNE AU LIEU DE REMETTRE CELLE-CI À ZÉRO, et ce n'est pas de la paresse : une partie, c'est
#   quinze contours, quinze positions, quinze groupes, un zoom, un compte de suggestions, une fête à moitié jouée
#   et un calque de plein écran. Repartir d'une scène neuve garantit qu'il ne reste RIEN de la partie précédente
#   — alors qu'une remise à zéro à la main oublie toujours un état, et l'oubli ne se voit qu'au troisième rejeu.
# ⚠ MÊME MÉCANIQUE QUE « JOUER » SUR L'ACCUEIL (et pour la même raison) : on s'ajoute dans SON PROPRE PARENT puis
#   on se retire. `change_scene_to_file` remplacerait la scène RACINE — et détruirait le harnais qui monte le jeu
#   dans un `SubViewport`.
func _rejouer() -> void:
	if _musique != null:
		_musique.stop()
	if _video != null:
		_video.stop()                              # (B17 · §25) sinon le chant survivrait à la scène qu'on quitte
	var scene := load(SCENE_PUZZLE) as PackedScene
	if scene == null:
		push_error("[puzzle] scène de jeu introuvable : " + SCENE_PUZZLE)
		return
	var jeu := scene.instantiate()
	jeu.tableau = tableau                          # LE MÊME tableau : c'est ce que « rejouer » veut dire
	jeu.melange = melange + 1                      # …et un désordre NEUF (cf. l'encadré de `melange`)
	jeu.forcer_tactile = forcer_tactile            # (B10) le doigt forcé VOYAGE : sinon la scène neuve redeviendrait
	                                               #       souris, et la preuve mesurerait un autre jeu que le sien
	var parent := get_parent()
	parent.add_child(jeu)
	if parent == get_tree().root:
		get_tree().current_scene = jeu
	_dire("REJOUER — même tableau « %s », mélange n° %d" % [TableauxPuzzle.nom(tableau), melange + 1])
	queue_free()


# (B8) NIVEAU SUIVANT — « mène directement au tableau suivant (charge le tableau n+1 et lance sa partie), sans
# repasser par l'accueil » (brief §1).
#
# ⚠ C'EST LE CHEMIN DE `_rejouer`, À UN CHIFFRE PRÈS, ET C'EST VOULU : on remonte une scène de jeu NEUVE dans son
#   propre parent puis on se retire. Les raisons sont celles de `_rejouer` mot pour mot (une partie, c'est quinze
#   contours, un zoom, un compte de suggestions, une fête à moitié jouée, un calque de plein écran et un lecteur
#   de musique : repartir d'une scène neuve garantit qu'il n'en reste RIEN), et une de plus qui n'appartient qu'à
#   ce bouton-ci : le tableau suivant n'a ni la même image, ni la même grille (5 × 3 contre 3 × 5), ni la même
#   musique. Ce n'est pas une remise à zéro, c'est un AUTRE tableau — seul un `_ready` complet le taille juste.
# ⚠ `melange` REPART À ZÉRO, alors que `_rejouer` l'incrémente : le désordre est celui du PREMIER mélange de ce
#   tableau-là, exactement ce que l'enfant aurait eu en le lançant depuis l'accueil. « Niveau suivant » ne doit
#   rien laisser deviner de la partie qu'on vient de finir.
# ⚠ LE FILET DU DÉBUT N'EST PAS DÉCORATIF : le bouton n'existe que si `_suivant_offert`, mais un appel qui
#   arriverait autrement (un raccourci ajouté un jour, un harnais) ne doit pas charger un tableau qui n'existe
#   pas — `TableauxPuzzle.numero_valide` rendrait alors le tableau 1, et l'enfant reculerait au lieu d'avancer.
func _niveau_suivant() -> void:
	# ⚠ (B15) LE FILET DEMANDE À LA FAMILLE, PLUS À LA TABLE : `suivant_dans_famille` rend −1 au dernier tableau
	#   d'une famille, et c'est le seul refus qui vaille. Une borne « tableau + 1 < nombre() » laisserait passer
	#   le saut du tracteur (index 4) vers les coccos (index 5), donc d'une famille à l'autre.
	var suivant: int = TableauxPuzzle.suivant_dans_famille(tableau)
	if not _suivant_offert or suivant < 0:
		_dire("NIVEAU SUIVANT demandé sans suite disponible dans la famille — refusé (rien ne bouge)")
		return
	if _musique != null:
		_musique.stop()
	if _video != null:
		_video.stop()                              # (B17 · §25) idem — inatteignable ici (« petite feuille » est
	                                               #   la dernière de sa famille), écrit pour la vidéo d'après
	if _rec_son != null:
		_rec_son.stop()
	var scene := load(SCENE_PUZZLE) as PackedScene
	if scene == null:
		push_error("[puzzle] scène de jeu introuvable : " + SCENE_PUZZLE)
		return
	var jeu := scene.instantiate()
	jeu.tableau = suivant                          # LE SUIVANT **DE LA FAMILLE** : cf. le filet ci-dessus
	jeu.melange = 0                                # un tableau neuf, son premier désordre
	jeu.forcer_tactile = forcer_tactile            # (B10) cf. `_rejouer` : le doigt forcé suit la chaîne des tableaux
	var parent := get_parent()
	parent.add_child(jeu)
	if parent == get_tree().root:
		get_tree().current_scene = jeu
	_dire("NIVEAU SUIVANT — tableau %d de la famille « %s » : « %s » (grille %d × %d), sans repasser par l'accueil"
		% [TableauxPuzzle.rang_dans_famille(suivant) + 1, TableauxPuzzle.cle_famille(TableauxPuzzle.famille_de(suivant)),
			TableauxPuzzle.nom(suivant), TableauxPuzzle.colonnes(suivant), TableauxPuzzle.rangs(suivant)])
	queue_free()


# LA MAISON — le retour à l'accueil, depuis le HUD du jeu comme depuis l'écran de fin. Le même geste, le même
# signe, la même fonction : un enfant qui a appris la maison dans le panneau la retrouve à la fin.
func _retour_accueil() -> void:
	if _musique != null:
		_musique.stop()
	if _video != null:
		_video.stop()                              # (B17 · §25) le chant ne suit pas l'enfant jusqu'à l'accueil
	if _rec_son != null:
		_rec_son.stop()
	var scene := load(SCENE_ACCUEIL) as PackedScene
	if scene == null:
		push_error("[puzzle] accueil introuvable : " + SCENE_ACCUEIL)
		return
	var acc := scene.instantiate()
	var parent := get_parent()
	parent.add_child(acc)
	if parent == get_tree().root:
		get_tree().current_scene = acc
	_dire("MAISON — retour à l'accueil (depuis %s)" % ("l'écran de fin" if _etat == Etat.PLEIN_ECRAN else "le jeu"))
	queue_free()


# ------------------------------------------------------------------------------------------- les rectangles
# Rendus au jeu ET au harnais : la mise en page et la mesure lisent le même nombre, jamais deux calculs jumeaux.
# ⚠ LE STOP EST « À DROITE » AU SENS DE FABRICE — bord droit du canvas, à mi-hauteur. Sur les écrans couchés il
#   tombe dans la bande noire du letterbox (il ne recouvre alors RIEN de l'image) ; sur un écran debout, où le
#   dessin occupe presque toute la largeur, il se pose par-dessus le bord droit de l'image. C'est assumé : « à
#   droite, visible » est la demande, et un bouton qu'on doit chercher ne sert à rien.
func cadre_stop() -> Rect2:
	return Rect2(Vector2(_ecran.x - FIN_MARGE - STOP_TAILLE.x, (_ecran.y - STOP_TAILLE.y) * 0.5), STOP_TAILLE)


# (B8) LES BOUTONS DE LA FIN — UN SEUL CALCUL POUR LES DEUX OU LES TROIS. La rangée est CENTRÉE quel qu'en soit le
# nombre : c'est ce qui fait qu'au dernier tableau « la place du bouton absent n'est pas occupée » (Fabrice, GDD
# §12) au lieu d'un trou à droite. Le 26 du bas est la hauteur de la plaque du libellé : les mots tiennent SOUS
# les boutons, dans l'écran.
# ⚠ TROIS BOUTONS TIENNENT SUR LA PLUS ÉTROITE DES CIBLES : 3 × 128 + 2 × 26 = 436 px pour un canvas qui ne
#   descend jamais sous 1024 dans sa petite dimension (`stretch/aspect = expand`, base 1024 × 768). Le harnais le
#   remesure sur les quatre cibles plutôt que de s'en tenir à ce calcul.
func nb_boutons_fin() -> int:
	return 3 if _suivant_offert else 2


func cadre_bouton_fin(rang: int) -> Rect2:
	var n: int = nb_boutons_fin()
	var total: float = float(n) * FIN_BOUTON.x + float(n - 1) * FIN_ECART
	var x: float = (_ecran.x - total) * 0.5 + float(rang) * (FIN_BOUTON.x + FIN_ECART)
	return Rect2(Vector2(x, _ecran.y - FIN_MARGE - FIN_BOUTON.y - 26.0), FIN_BOUTON)


func cadre_rejouer() -> Rect2:
	return cadre_bouton_fin(0)


func cadre_maison_fin() -> Rect2:
	return cadre_bouton_fin(1)


# ⚠ UN RECTANGLE VIDE QUAND IL N'Y A PAS DE SUITE, et non un rectangle « qui serait là si » : le bouton est
#   ABSENT, sa place n'existe pas. Rendre un cadre plausible laisserait croire à une place réservée — au harnais
#   comme à quiconque relira ce fichier.
func cadre_suivant() -> Rect2:
	return cadre_bouton_fin(2) if _suivant_offert else Rect2()


# ------------------------------------------------------------------------------------------- la fabrique
# UN BOUTON À ICÔNE : fond clair, bord sombre, glyphe DESSINÉ au centre. Le fond clair et le glyphe sombre font un
# contraste de LUMINANCE — lisible sous n'importe quel daltonisme (CLAUDE.md), et de loin sur un projecteur.
func _bouton_icone(r: Rect2, forme: String, infobulle: String, cible: Callable) -> Button:
	var b := Button.new()
	b.flat = false
	b.position = r.position
	b.size = r.size
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = infobulle
	for etat in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = COL_BOUTON if etat == "normal" else COL_BOUTON_SURVOL
		st.set_corner_radius_all(12)
		st.set_border_width_all(3)
		st.border_color = COL_GLYPHE
		b.add_theme_stylebox_override(etat, st)
	# (B12) UNE CIBLE VIDE EST LÉGITIME : le bouton PRENDRE/POSER ne se branche PAS sur `pressed` (les deux
	# émulations croisées le feraient basculer deux fois — cf. l'encadré des constantes). Il est alors un pur
	# cadre à glyphe, et c'est `_input` qui commande.
	if cible.is_valid():
		b.pressed.connect(cible)
	var ic := IconeDessinee.new()
	ic.ov = self
	ic.forme = forme
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE   # elle MONTRE, elle n'intercepte pas : le clic va au bouton
	b.add_child(ic)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return b


# LE MOT SOUS LE BOUTON — le second signal, celui qui ne demande de reconnaître aucune forme ni aucune teinte.
#
# ⚠⚠ ET IL LUI FAUT SON FOND SOMBRE, C'EST MESURÉ ET NON SUPPOSÉ : le premier rendu de B3 posait ces mots en
#   clair directement sur l'image de la ferme — dont le bas est une bande crème. Résultat relevé sur les pixels :
#   du blanc sur du blanc, un mot qu'on devine au lieu de le lire. Ces libellés se posent sur une IMAGE, et une
#   image n'a pas de couleur convenue : la seule façon de tenir le contraste de luminance (CLAUDE.md) sur
#   n'importe quel dessin, c'est d'apporter son propre fond. Il vaudra aussi pour les tableaux à venir.
func _etiquette(texte: String, r: Rect2) -> void:
	# La plaque et le mot voyagent ENSEMBLE dans un porteur : cacher l'étiquette du STOP, c'est cacher un nœud —
	# pas deux qu'on risquerait de dissocier le jour où l'un des deux changera de place.
	var porteur := Control.new()
	porteur.name = "Etiquette" + texte
	porteur.position = Vector2(r.position.x, r.end.y + 2.0)
	porteur.size = Vector2(r.size.x, 26.0)
	porteur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fin_calque.add_child(porteur)
	var plaque := ColorRect.new()
	plaque.color = Color(0.05, 0.06, 0.09, 0.72)
	plaque.position = Vector2.ZERO
	plaque.size = porteur.size
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	porteur.add_child(plaque)
	var l := Label.new()
	l.text = texte
	l.position = Vector2(0.0, 1.0)
	l.size = Vector2(r.size.x, 24.0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", COL_ETIQUETTE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	porteur.add_child(l)


# ============================================================================================================
# LES ICÔNES DESSINÉES — MAISON · FLÈCHE TOURNANTE · TRIANGLE · RECADRAGE (B6) · FLÈCHE AVEC LE PLUS (B8)
#
# ⚠⚠ CE SONT LES FORMES DE LA FRATRIE COCCOS, **RECOPIÉES ICI POINT PAR POINT** — c'est la demande du brief §2
#   (« le logo de rejeu déjà utilisé ailleurs : le retrouver et le COPIER dans le projet, jamais d'ancre »).
#   Le logo de rejeu de la fratrie n'est pas un fichier : c'est une géométrie tracée par le code. Ce qui se copie
#   est donc la géométrie — mêmes angles, mêmes proportions, même pointe tangente — et ce projet ne pointe vers
#   aucun autre fichier ni aucun autre dossier. C'est ce que le contrôle ⓪ du harnais vérifie sur la source.
#
# CE QUE CHAQUE FORME DIT À UN ENFANT DE QUATRE ANS :
#   • MAISON — un pignon large qui déborde le corps, et une PORTE ÉVIDÉE. C'est la porte qui fait la maison :
#     sans elle, un carré surmonté d'un triangle se lit aussi bien « tente » ou « flèche vers le haut ».
#   • FLÈCHE TOURNANTE — un arc de ~300°, PAS un cercle : un cercle fermé ne tourne pas. L'ouverture dit qu'il y
#     a un début et une fin, la pointe tangente dit dans quel sens. Les deux ensemble disent « recommence ».
#   • TRIANGLE — plein, rouge (la demande de Fabrice), cerné de sombre pour que le bord tienne sans la teinte.
#
# ⚠ TOUT EST EN FRACTION DE LA TAILLE DU BOUTON, jamais en pixels : les trois boutons n'ont pas les mêmes
#   dimensions (62 × 58 pour la maison du panneau, 128 × 96 pour ceux de la fin, 112 × 96 pour le STOP) — une
#   marge en dur aurait étouffé le plus petit.
# ============================================================================================================
class IconeDessinee extends Control:
	var ov = null
	var forme := "maison"
	const MARGE := 0.16

	func _draw() -> void:
		if ov == null:
			return
		var m: Vector2 = size * MARGE
		var z := Rect2(m, size - m * 2.0)
		if z.size.x <= 2.0 or z.size.y <= 2.0:
			return
		match forme:
			"maison":
				_maison(z)
			"rejouer":
				_rejouer(z)
			"stop":
				_stop(z)
			"recadrer":
				_recadrer(z)
			"suivant_plus":
				_suivant_plus(z)
			# (B23 · §31.3) ⚠ LA FORME « prendre_poser » A DISPARU : c'était le glyphe du bouton PRENDRE ⇄ POSER
			#   (logo du jeu + flèche retournée). Plus aucun bouton ne la demande.

	# LA MAISON — dessinée dans le plus grand CARRÉ que la zone contienne : sur un bouton large, une maison
	# étirée à la largeur deviendrait un hangar.
	func _maison(z: Rect2) -> void:
		var c: float = minf(z.size.x, z.size.y)
		var o: Vector2 = z.get_center() - Vector2(c, c) * 0.5
		var sombre: Color = ov.COL_GLYPHE
		draw_colored_polygon(PackedVector2Array([
			o + Vector2(c * 0.50, 0.0), o + Vector2(c, c * 0.46), o + Vector2(0.0, c * 0.46)]), sombre)
		draw_rect(Rect2(o + Vector2(c * 0.14, c * 0.44), Vector2(c * 0.72, c * 0.56)), sombre, true)
		# LA PORTE, ÉVIDÉE — on repeint le fond du bouton par-dessus le corps. `COL_BOUTON_SURVOL` est le fond des
		# états survolé et appuyé ; on prend le fond NORMAL, et l'évidement ne « clignote » pas au survol (les deux
		# teintes sont à deux centièmes l'une de l'autre : l'œil ne les distingue pas).
		draw_rect(Rect2(o + Vector2(c * 0.39, c * 0.64), Vector2(c * 0.22, c * 0.36)), ov.COL_BOUTON, true)

	# LA FLÈCHE TOURNANTE — l'arc, puis la pointe TANGENTE à son extrémité (c'est elle qui donne le sens).
	func _rejouer(z: Rect2) -> void:
		var sombre: Color = ov.COL_GLYPHE
		var c: Vector2 = z.get_center()
		var r: float = minf(z.size.x, z.size.y) * 0.42
		draw_arc(c, r, deg_to_rad(-60.0), deg_to_rad(240.0), 48, sombre, r * 0.42)
		var a: float = deg_to_rad(240.0)
		var n := Vector2(cos(a), sin(a))          # radiale : du centre vers le bout de l'arc
		var t := Vector2(-sin(a), cos(a))         # tangente, dans le sens où l'arc a été tracé
		var p: Vector2 = c + n * r
		draw_colored_polygon(PackedVector2Array([
			p + t * (r * 0.66), p + n * (r * 0.58), p - n * (r * 0.58)]), sombre)

	# (B6) LE RECADRAGE — QUATRE ÉQUERRES DE VISEUR ET, AU MILIEU, UNE PETITE IMAGE. Ce que ça dit à un enfant :
	# « je remets le cadre autour du tableau ». Les équerres seules feraient un viseur d'appareil photo ; c'est le
	# rectangle plein du milieu — la même proportion que le plateau — qui dit que le cadre se referme SUR LE
	# PUZZLE. Aucun caractère, aucune teinte porteuse : la forme, et la luminance (CLAUDE.md).
	func _recadrer(z: Rect2) -> void:
		var c: float = minf(z.size.x, z.size.y)
		var o: Vector2 = z.get_center() - Vector2(c, c) * 0.5
		var sombre: Color = ov.COL_GLYPHE
		var e: float = c * 0.34                        # longueur d'une branche d'équerre
		var t: float = maxf(c * 0.11, 2.0)             # son épaisseur
		for coin in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)]:
			var p: Vector2 = o + Vector2(coin.x * c, coin.y * c)
			var sx: float = -1.0 if coin.x > 0.5 else 1.0
			var sy: float = -1.0 if coin.y > 0.5 else 1.0
			var h := Rect2(p + Vector2(0.0 if sx > 0.0 else -e, 0.0 if sy > 0.0 else -t), Vector2(e, t))
			var v := Rect2(p + Vector2(0.0 if sx > 0.0 else -t, 0.0 if sy > 0.0 else -e), Vector2(t, e))
			draw_rect(h, sombre, true)
			draw_rect(v, sombre, true)
		draw_rect(Rect2(o + Vector2(c * 0.32, c * 0.30), Vector2(c * 0.36, c * 0.40)), sombre, true)

	# (B8) LA FLÈCHE « SUIVANT » ET SON PLUS — la flèche à gauche (60 % de la zone), le « + » à droite. La
	# géométrie de la fratrie, RECOPIÉE POINT PAR POINT : la flèche vient de `FLECHE_SUIVANT` (fractions de son
	# rectangle), le « + » est deux barres croisées dont la demi-longueur vaut 26 % du plus petit côté et
	# l'épaisseur 48 % de cette demi-longueur. Deux signes SÉPARÉS — « avance » puis « un de plus ».
	# ⚠ MÊME SOMBRE QUE LES DEUX AUTRES ICÔNES, sur le même fond clair : contraste de LUMINANCE, lisible sous
	#   n'importe quel daltonisme (CLAUDE.md), et le mot « Suivant » sous le bouton le double.
	func _suivant_plus(z: Rect2) -> void:
		var sombre: Color = ov.COL_GLYPHE
		var zf := Rect2(z.position + Vector2(0.0, z.size.y * 0.18), Vector2(z.size.x * 0.60, z.size.y * 0.64))
		var pts: Array = []
		for v in ov.FLECHE_SUIVANT:
			pts.append(zf.position + (v as Vector2) * zf.size)
		draw_colored_polygon(PackedVector2Array(pts), sombre)
		draw_polyline(PackedVector2Array(pts + [pts[0]]), sombre, 2.0)
		var cp: Vector2 = Vector2(z.position.x + z.size.x * 0.82, z.get_center().y)
		var br: float = minf(z.size.x, z.size.y) * 0.26      # demi-longueur d'un bras du « + »
		var ep: float = br * 0.48                            # son épaisseur
		draw_rect(Rect2(cp - Vector2(br, ep * 0.5), Vector2(br * 2.0, ep)), sombre, true)
		draw_rect(Rect2(cp - Vector2(ep * 0.5, br), Vector2(ep, br * 2.0)), sombre, true)

	# (B12 · §21.3) LE BOUTON PRENDRE ⇄ POSER — **LE LOGO DU JEU + UNE FLÈCHE**, ET RIEN D'ÉCRIT.
	# LE TRIANGLE DU STOP — plein et ROUGE (Fabrice), cerné d'un trait clair : le bord se lit même quand la teinte
	# ne se lit pas. Il pointe vers le HAUT, comme celui du lecteur de la fratrie.
	func _stop(z: Rect2) -> void:
		var c: float = minf(z.size.x, z.size.y)
		var o: Vector2 = z.get_center() - Vector2(c, c) * 0.5
		var pts := PackedVector2Array([
			o + Vector2(c * 0.50, c * 0.06), o + Vector2(c * 0.97, c * 0.94), o + Vector2(c * 0.03, c * 0.94)])
		draw_colored_polygon(pts, ov.COL_ROUGE)
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), ov.COL_ETIQUETTE, 3.0)


# ------------------------------------------------------------------------------------------------------------
# LE CURSEUR — celui que l'enfant a choisi sur l'accueil (B2). Lancé seul, le jeu prend le dernier choix connu.
# ------------------------------------------------------------------------------------------------------------
# ⚠ (B10) IL EST REPOSÉ **ICI**, À L'ENTRÉE DU JEU, ET NON HÉRITÉ DE L'ACCUEIL. Trois chemins arrivent dans cette
#   scène sans passer par l'accueil : `scenes/puzzle.tscn` lancée seule (c'est ce que fait le harnais depuis B1),
#   « REJOUER » et « NIVEAU SUIVANT » — qui montent une scène de jeu NEUVE et se retirent. Compter sur ce qu'une
#   scène précédente aurait laissé au système, c'est faire dépendre le pointeur d'un chemin d'arrivée.
# ⚠ (B10) ET AU DOIGT, ON NE LE POSE PAS : `Input.set_custom_mouse_cursor` habille un POINTEUR DE SOURIS, et un
#   écran tactile n'en a aucun. La ligne s'exécuterait sans rien montrer — c'est exactement le trou que Fabrice
#   décrit. C'est `_batir_curseur_doigt()` qui prend le relais, et il DESSINE.
func _poser_curseur() -> void:
	_curseur = CurseursPuzzle.lire_choix()
	# ⚠ (B23 · §31.1) AU BUREAU, LE DÉFAUT EST DÉSORMAIS LA **MAIN** — `lire_choix()` le rend sans que cette
	#   fonction ait à le savoir : elle pose ce qui lui est donné, et la table dit sa taille (la Main à 32 px,
	#   §31.2). Rien à brancher ici.
	# ⚠ (B14 · §22) SANS CURSEUR : ON LE POSE QUAND MÊME, parce que « poser » veut dire ici **rendre le pointeur
	#   système** — cf. `CurseursPuzzle.poser`, qui appelle `set_custom_mouse_cursor(null)`. Ne rien appeler
	#   laisserait au bureau le sprite posé par l'accueil dans la même session. Au doigt il n'y a pas de pointeur
	#   système, donc il n'y a rien à défaire — mais il n'y a rien à DESSINER non plus, et c'est ça la demande.
	if CurseursPuzzle.sans_curseur(_curseur):
		_curseur_taille = CurseursPuzzle.poser(_curseur)
		_dire("SANS CURSEUR (§22 ; §31.1 : le défaut sur ANDROID) : aucun curseur dessiné — %s"
			% ["la pièce se prend directement au doigt" if _tactile
				else "la souris garde le pointeur du système"])
		return
	if _tactile:
		_curseur_taille = Vector2.ZERO
		_dire("curseur %s : au DOIGT il est DESSINÉ (%.0f px de haut), pas posé en pointeur de souris — un écran tactile n'a pas de pointeur système"
			% [CurseursPuzzle.nom(_curseur), CURSEUR_H_DOIGT])
		return
	_curseur_taille = CurseursPuzzle.poser(_curseur)
	if _curseur_taille == Vector2.ZERO:
		return
	var chaud: Vector2 = CurseursPuzzle.chaud(_curseur)
	_dire("curseur %s posé EN JEU comme pointeur de souris (%d × %d px, point chaud %.0f,%.0f)"
		% [CurseursPuzzle.nom(_curseur), int(_curseur_taille.x), int(_curseur_taille.y),
			chaud.x * _curseur_taille.x, chaud.y * _curseur_taille.y])


# ============================================================================================================
# (B10) LE CURSEUR DESSINÉ AU DOIGT — SON PROPRE CALQUE, AU-DESSUS DU PANNEAU ET SOUS LA FÊTE
# ============================================================================================================
# ⚠ LE CALQUE EST À 8 : au-dessus du panneau (`_ihm`, calque 0) — donc la pointe ne peut pas se cacher derrière la
#   maison, le recadrage ou le modèle — et SOUS la fête (10), le plein écran (20) et l'écran de fin (30), parce
#   qu'une fois le puzzle gagné il n'y a plus rien à viser.
# ⚠ ET IL EST HORS DE `_ihm` : `_batir_ihm()` LIBÈRE et reconstruit tout son calque à chaque redimensionnement
#   (cf. `_refaire_geometrie`). Un curseur qui vivrait dedans disparaîtrait à la première rotation du téléphone.
func _batir_curseur_doigt() -> void:
	_curseur_vue = null
	var vieux := get_node_or_null("CurseurDoigt")
	if vieux != null:
		vieux.free()
	_curseur_calque = null
	if not _tactile:
		return
	# ⚠⚠ (B14 · §22) SANS CURSEUR, IL N'Y A PAS DE CALQUE DU TOUT — pas un nœud caché, RIEN. Un `TextureRect`
	#   invisible aurait suffi à l'œil, mais il aurait laissé au harnais et à la prochaine balle un curseur
	#   « presque là » : `curseur_doigt_rect()` rend alors un rectangle VIDE, et c'est ça qui se prouve.
	# ⚠ LA VISÉE EST QUAND MÊME INITIALISÉE AU CENTRE DU PLATEAU : `_curseur_vise` reste le point qui prend et qui
	#   pose (`_prendre`, `_glisser`), et sans curseur il vaut EXACTEMENT la position du doigt — le décalage
	#   doigt → pointe est nul faute de sprite. Le laisser à zéro ferait partir la première prise du coin de
	#   l'écran si un `Drag` arrivait avant tout `Touch`.
	if CurseursPuzzle.sans_curseur(_curseur):
		_curseur_vise = _zone.get_center()
		_curseur_pose = true
		_dire("SANS CURSEUR (§22) : aucun sprite dessiné, aucun décalage doigt → pointe — le doigt EST la pointe ; visée initiale %s"
			% str(_curseur_vise.round()))
		return
	_curseur_calque = CanvasLayer.new()
	_curseur_calque.name = "CurseurDoigt"
	_curseur_calque.layer = CURSEUR_CALQUE
	add_child(_curseur_calque)
	_curseur_vue = TextureRect.new()
	_curseur_vue.name = "CurseurDessine"
	_curseur_vue.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_curseur_vue.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_curseur_vue.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_curseur_vue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curseur_vue.visible = false
	_curseur_calque.add_child(_curseur_vue)
	# ⚠ LE CURSEUR PART AU MILIEU DU PLATEAU, DÉJÀ VISIBLE : sans cela, l'enfant qui ouvre un tableau ne voit aucun
	#   pointeur et ne sait pas qu'il en a un. Il n'a alors qu'à le faire glisser. C'est le geste de l'acquis.
	_poser_curseur_doigt(_zone.get_center())
	_maj_curseur_doigt()
	_dire("curseur DESSINÉ au doigt : « %s » %s px, tenu par l'ancre %s, pointe (chaud) %s — décalage plein %s px"
		% [CurseursPuzzle.nom(_curseur), str(_taille_curseur_doigt().round()),
			str(CurseursPuzzle.ancre(_curseur)), str(CurseursPuzzle.chaud(_curseur)),
			str(_decal_plein().round())])


# LA TAILLE DU SPRITE À L'ÉCRAN — la hauteur est le réglage de Fabrice (7 diff B34), la largeur suit le rapport de
# l'image.
# ⚠ Elle NE dépend PAS du zoom du jeu : un curseur est un pointeur, pas un objet posé sur le plateau.
# ⚠⚠ ET ELLE NE SE MET PAS À L'ÉCHELLE DU CANVAS — c'est une DÉCISION, et le premier jet de B10 s'est trompé
#   dessus, mesure à l'appui : mise à l'échelle par la hauteur du canvas, elle donnait 341 unités sur l'écran
#   debout (1024 × 1365) au lieu de 192. Or 192 est déjà un réglage PHYSIQUE — Fabrice l'a tranché à l'œil sur son
#   téléphone (7 diff B34 : 192 unités = 270 px réels ≈ 17 mm), et le 7 différences ne le met à l'échelle nulle
#   part (`_taille_curseur`, sa ligne `var h := CURSEUR_HAUTEUR_JEU if _tactile else CURSEUR_HAUTEUR`). Le mettre
#   à l'échelle ici reviendrait à réinventer un réglage que Fabrice a déjà posé, et à le poser plus mal.
func _taille_curseur_doigt() -> Vector2:
	var tex := CurseursPuzzle.texture(CurseursPuzzle.lire_choix())
	if tex == null:
		return Vector2.ZERO
	var src := Vector2(tex.get_size())
	if src.y <= 0.0:
		return Vector2.ZERO
	# ⚠ (B23 · §31.2) LE FACTEUR DE LA TABLE S'APPLIQUE **ICI AUSSI** — « ça va être général » (Fabrice). La Main
	#   dessinée au doigt est donc, elle aussi, deux fois plus petite ; la coccinelle et l'abeille gardent leurs
	#   192 px réglés par Fabrice sur son téléphone. Une seule source (`CurseursPuzzle.facteur`), deux lecteurs.
	var h: float = CURSEUR_H_DOIGT * CurseursPuzzle.facteur(_curseur)
	return Vector2(h * src.x / src.y, h)


# LE DÉCALAGE PLEIN — le vecteur qui va du DOIGT (posé sur l'`ancre` marquée par Fabrice) à la POINTE (`chaud`,
# le pixel qui prend la pièce). Une soustraction de deux FRACTIONS ramenée en pixels : grossir le curseur ne
# déplace donc ni la pointe ni la prise. Sa composante x est négative pour la coccinelle et l'abeille (pointe à
# gauche du doigt) et positive pour la main : c'est le SIGNE qui porte l'information, et `_bord_rattrape` le lit.
func _decal_plein() -> Vector2:
	var t := _taille_curseur_doigt()
	if t == Vector2.ZERO:
		return Vector2.ZERO
	var i := CurseursPuzzle.lire_choix()
	return (CurseursPuzzle.chaud(i) - CurseursPuzzle.ancre(i)) * t


# DE COMBIEN LA POINTE EST DÉCALÉE DU DOIGT, À CETTE POSITION-LÀ. Plein décalage au large ; RÉDUIT à l'approche du
# bord que la pointe ne pourrait pas atteindre autrement, jusqu'à ZÉRO au ras de ce bord (pointe = doigt).
# ⚠⚠ LE BORD RATTRAPÉ EST CELUI VERS LEQUEL LA POINTE S'ÉLOIGNE DU DOIGT, sur les DEUX axes, et c'est de
#   l'arithmétique, pas un goût : pour poser la pointe en P il faut le doigt en P − décalage. La coccinelle visant
#   91 px AU-DESSUS du doigt (à 192 px de haut), poser la pointe tout EN BAS demanderait un doigt 91 px SOUS
#   l'écran — la bande basse serait injouable, et c'est justement là que vit la réserve sur un écran debout.
#   Idem en x : visant 41 px à GAUCHE, atteindre le bord DROIT demanderait un doigt hors écran.
# ⚠ POURQUOI ÇA NE SAUTE AUCUN POINT : « doigt → pointe » ainsi corrigée reste CONTINUE et STRICTEMENT CROISSANTE
#   (au large `p + plein`, au ras du bord `p`, entre les deux `2p − bord`). Elle balaie tout le segment sans trou.
# ⚠ ET LE BORD OPPOSÉ N'A BESOIN DE RIEN : il est atteint avec le décalage PLEIN, par un doigt qui reste à
#   l'écran. Le borner aussi créerait la zone morte qu'on vient d'éviter.
func _decal_tactile(p_doigt: Vector2) -> Vector2:
	var plein := _decal_plein()
	var f := Rect2(Vector2.ZERO, _ecran)
	return Vector2(_bord_rattrape(plein.x, p_doigt.x, f.position.x, f.end.x),
		_bord_rattrape(plein.y, p_doigt.y, f.position.y, f.end.y))


# UNE COMPOSANTE, rattrapée près du bord qu'elle mettrait hors d'atteinte. (Fonction `_bord_x` des points reliés,
# reprise telle quelle — ici appliquée aux DEUX axes, cf. l'encadré ci-dessus.)
func _bord_rattrape(plein: float, p: float, debut: float, fin: float) -> float:
	if plein < 0.0:
		return -clampf(fin - p, 0.0, -plein)
	return clampf(p - debut, 0.0, plein)


# LA POINTE QUE CE DOIGT-LÀ VISE — la fonction pure, sans effet de bord. Le jeu s'en sert pour poser le curseur,
# le harnais pour prouver la continuité et la couverture sans avoir à rejouer un geste.
func pointe_au_doigt(doigt: Vector2) -> Vector2:
	var vise: Vector2 = doigt + _decal_tactile(doigt)
	return Vector2(clampf(vise.x, 0.0, _ecran.x), clampf(vise.y, 0.0, _ecran.y))


# POSER LE CURSEUR À PARTIR D'UN POINT DE CONTACT. C'est la seule fonction qui écrit `_curseur_vise`.
# ⚠ LA POINTE EST BORNÉE À L'ÉCRAN, PAS LE SPRITE ENTIER : ce que Fabrice demande, c'est que « le bout du curseur
#   reste visible » — et le bout, c'est la pointe. Borner le sprite entier (ce que font les points reliés avec
#   leur `mur_curseur`) rendrait au contraire une bande de 169 px inatteignable en bas, et il faudrait le suivi de
#   bord de leur B7 pour la rattraper — un mécanisme de CAMÉRA, hors du périmètre de cette balle. Au ras d'un
#   bord, le corps du curseur déborde donc un peu ; sa pointe, elle, est toujours sur l'écran.
func _poser_curseur_doigt(doigt: Vector2) -> void:
	_curseur_vise = pointe_au_doigt(doigt)
	_curseur_pose = true
	_maj_curseur_doigt()


# METTRE LE NŒUD À JOUR — la texture est celle que l'enfant a CHOISIE à l'accueil : c'est ce qui redonne enfin un
# effet VISIBLE à l'écran de choix sur un téléphone (un pointeur de souris n'y existe pas).
# ⚠ IL S'EFFACE DÈS QU'ON NE JOUE PLUS (fête, plein écran, modèle ouvert en grand) : il n'y a plus rien à viser,
#   et un curseur qui flotterait sur l'image finale se lirait comme une pièce oubliée.
func _maj_curseur_doigt() -> void:
	if _curseur_vue == null:
		return
	var tex := CurseursPuzzle.texture(CurseursPuzzle.lire_choix())
	var t := _taille_curseur_doigt()
	if not _tactile or tex == null or t == Vector2.ZERO or _etat != Etat.JEU or _modele_plein:
		_curseur_vue.visible = false
		return
	_curseur_vue.texture = tex
	_curseur_vue.size = t
	_curseur_vue.position = (_curseur_vise - CurseursPuzzle.chaud(CurseursPuzzle.lire_choix()) * t).floor()
	_curseur_vue.visible = true


# CE QUE LE CURSEUR DESSINÉ OCCUPE À L'ÉCRAN — rendu au harnais, qui n'a ainsi pas à refaire le calcul du jeu.
func curseur_doigt_rect() -> Rect2:
	if _curseur_vue == null:
		return Rect2()
	return Rect2(_curseur_vue.position, _curseur_vue.size)


func _dire(s: String) -> void:
	if _journal_ouvert:
		print("[puzzle] " + s)


func _total_points() -> int:
	var n := 0
	for p in _contour:
		n += (p as PackedVector2Array).size()
	return n


# ============================================================================================================
# CE QUE LE HARNAIS VIENT LIRE — et rien d'autre. Aucune de ces méthodes ne DÉPLACE quoi que ce soit : la preuve
# joue par de VRAIS événements de souris (`push_input`), elle ne téléporte pas les pièces.
# ============================================================================================================
func etat_pour_preuve() -> Dictionary:
	return {
		"pieces": _contour.size(),
		"cols": _cols, "rangs": _rangs,
		"echelle": _echelle,
		"etat": _etat,
		"blocs": _nb_blocs(),
		"plus_gros_bloc": _plus_gros_bloc(),
		"emboitements": _emboitements,
		"planches": _rec_planches.size(),
		"son": _rec_son != null,
		"manque": _rec_manque,
		"recompense_t": _rec_t,
		"recompense_image": int(_rec_t * REC_IM_PAR_S),
		"plein_ecran": _pe_porteur != null and _pe_porteur.modulate.a > 0.5,
		"taille_image": _taille,
		"tol_aimant": _tol_aimant,
		"rect_plein_ecran": rect_plein_ecran(),
		"panneau_x": _panneau.position.x,
		# (B2)
		"ecran": _ecran,
		# ⚠⚠ (B13 · §21.8) `portrait` VAUT DÉSORMAIS **TOUJOURS FAUX**, et ce n'est pas un raccourci : le jeu
		#   n'a plus de mode portrait (« uniquement en mode paysage », Fabrice). La clé reste pour tous les
		#   harnais de B2 → B12 qui la lisaient — ils y trouvent la vérité : aucune disposition debout.
		#   La FORME du canvas, elle, reste mesurable par `canvas_debout` (un constat, sans effet sur la page).
		"portrait": false,
		"paysage_seulement": true,
		"canvas_debout": canvas_debout(),
		"zone": _zone,
		"panneau": _panneau,
		"plateau": _plateau,
		"boite": _boite,
		"places": _places,
		"repartition": _repartition,
		"curseur": _curseur,
		"curseur_nom": CurseursPuzzle.nom(_curseur),
		"curseur_taille": _curseur_taille,
		"sans_curseur": sans_curseur(),          # (B14 · §22) le mode, relu sur `_curseur` — pas sur le fichier
		# (B10) LE CURSEUR EN JEU — au bureau le pointeur du système (`curseur_taille` non nulle le prouve), au
		# doigt le sprite DESSINÉ. Le harnais lit les deux mondes par la même porte.
		"tactile": _tactile,
		"curseur_dessine": _curseur_vue != null,
		"curseur_visible": _curseur_vue != null and _curseur_vue.visible,
		"curseur_rect": curseur_doigt_rect(),
		"curseur_doigt_taille": _taille_curseur_doigt(),
		"curseur_vise": _curseur_vise,
		"curseur_pose": _curseur_pose,
		"curseur_chaud": CurseursPuzzle.chaud(_curseur),
		"curseur_ancre": CurseursPuzzle.ancre(_curseur),
		"curseur_decal_plein": _decal_plein(),
		"saisie": _saisi,                          # (B10) QUELLE pièce est sous la main — la mesure du « c'est la
		                                           #       POINTE qui prend, pas la pulpe »
		"zoom": _zoom,
		"zoom_max": ZOOM_MAX,
		"zoom_min": ZOOM_MIN,
		"pan": _pan,
		"t_suggestion": _t_sugg,
		"sugg_periode": SUGG_PERIODE,
		"sugg_piece": _sugg_i,
		"sugg_visible": _sugg_calque != null and _sugg_calque.visible,
		"sugg_alpha": _sugg_forme.color.a if _sugg_forme != null else 0.0,
		"suggestions": _suggestions,
		# (B7) TOUT CE QU'IL FAUT POUR MESURER L'ANTI-PHASE SANS RIEN DEVINER : les deux alphas relevés sur les
		# VRAIS nœuds (pas une valeur recalculée pour la preuve), les deux teintes, l'âge de la suggestion et sa
		# période. Le harnais corrèle les deux séries : elles doivent s'opposer, pas se ressembler.
		"sugg_t": _sugg_t,
		"sugg_duree": SUGG_DUREE,
		"sugg_pulse": SUGG_PULSE,
		"sugg_u": _sugg_u,
		"sugg_piece_visible": _sugg_calque_piece != null and _sugg_calque_piece.visible,
		"sugg_alpha_place": _sugg_forme.color.a if _sugg_forme != null else 0.0,
		"sugg_alpha_piece": _sugg_piece_forme.color.a if _sugg_piece_forme != null else 0.0,
		"sugg_lisere_place": _sugg_lisere.default_color.a if _sugg_lisere != null else 0.0,
		"sugg_lisere_piece": _sugg_piece_lisere.default_color.a if _sugg_piece_lisere != null else 0.0,
		# (§24) la largeur du liseré de SUGGESTION, rendue au harnais : c'est le témoin qui prouve que celui de
		# la PRISE est plus fin — sans avoir à réécrire 5.0 dans la preuve, où il se périmerait en silence.
		"sugg_lisere_largeur": _sugg_piece_lisere.width if _sugg_piece_lisere != null else 0.0,
		"sugg_couleur_place": _sugg_forme.color if _sugg_forme != null else Color.BLACK,
		"sugg_couleur_piece": _sugg_piece_forme.color if _sugg_piece_forme != null else Color.BLACK,
		"sugg_alpha_min": SUGG_ALPHA_MIN,
		"sugg_alpha_max": SUGG_ALPHA_MAX,
		"sugg_forme_place": _sugg_forme.polygon if _sugg_forme != null else PackedVector2Array(),
		"sugg_forme_piece": _sugg_piece_forme.polygon if _sugg_piece_forme != null else PackedVector2Array(),
		"sugg_calque_piece_rang": _sugg_calque_piece.get_index() if _sugg_calque_piece != null else -1,
		# (§24) le liseré blanc de la pièce prise
		"prise_lisere_visible": _prise_calque != null and _prise_calque.visible,
		"prise_lisere_couleur": _prise_lisere.default_color if _prise_lisere != null else Color.BLACK,
		"prise_lisere_largeur": _prise_lisere.width if _prise_lisere != null else 0.0,
		"prise_lisere_ferme": _prise_lisere.closed if _prise_lisere != null else false,
		"prise_lisere_points": _prise_lisere.points if _prise_lisere != null else PackedVector2Array(),
		"prise_lisere_rang": _prise_calque.get_index() if _prise_calque != null else -1,
		"prise_lisere_largeur_reglee": PRISE_LISERE_LARGEUR,
		"sugg_calque_place_rang": _sugg_calque.get_index() if _sugg_calque != null else -1,
		"rangs_pieces": _rang_des_pieces().keys(),  # les rangs des PIÈCES dans l'arbre : le harnais compare les
		"enfants_jeu": _jeu.get_child_count() if _jeu != null else 0,   # deux calques à ces rangs-là
		# (B3) le tableau, la navigation, la musique de victoire
		"tableau": tableau,
		"tableau_nom": TableauxPuzzle.nom(tableau),
		"tableau_image": TableauxPuzzle.chemin_image(tableau),
		"tableau_musique": TableauxPuzzle.chemin_musique(tableau),
		"melange": melange,
		"places_ordre": _pos.duplicate(),          # OÙ sont les pièces : c'est ce qui change d'un mélange à l'autre
		"maison": cadre_maison(),
		"maison_visible": _btn_maison != null and _btn_maison.visible,
		"musique_existe": _musique != null,
		"musique_joue": _musique != null and _musique.playing,
		"musique_etat": _musique_etat,
		"musique_passages": _musique_passages,
		"musique_manque": _musique_manque,
		"musique_boucle": _musique != null and _musique.stream is AudioStreamMP3 \
			and (_musique.stream as AudioStreamMP3).loop,
		"musique_duree": _musique.stream.get_length() if _musique != null and _musique.stream != null else 0.0,
		"musique_position": _musique.get_playback_position() if _musique != null else 0.0,
		"stop_visible": _btn_stop != null and _btn_stop.visible,
		"stop": cadre_stop(),
		# (B17 · §25) LA RÉCOMPENSE VIDÉO — mesurée comme la musique, avec en plus ce que seule une vidéo a :
		# le cadre qu'elle occupe, sa taille NATIVE déclarée, et la taille de la texture que le décodeur rend
		# vraiment. Les deux dernières se confrontent : une taille déclarée fausse déformerait l'image sans
		# qu'aucun booléen ne s'en plaigne.
		"video_declaree": TableauxPuzzle.chemin_video(tableau),
		"video_existe": _video != null,
		# ⚠ `is_playing()` RESTE VRAI SUR UNE VIDÉO EN PAUSE (c'est écrit dans le moteur) : « elle joue » se
		#   mesure donc en DEUX questions, sinon le STOP passerait pour sans effet.
		"video_joue": _video != null and _video.is_playing() and not _video.paused,
		"video_en_pause": _video != null and _video.paused,
		"video_passages": _video_passages,
		"video_manque": _video_manque,
		"video_boucle": _video != null and _video.loop,
		"video_position": _video.stream_position if _video != null else 0.0,
		"video_bus": _video.bus if _video != null else "",
		"video_visible": _video != null and _video.visible,
		"video_rect": rect_video(),
		"video_taille_declaree": TableauxPuzzle.taille_video(tableau),
		"video_taille_texture": (Vector2(_video.get_video_texture().get_size())
			if _video != null and _video.get_video_texture() != null else Vector2.ZERO),
		# ⚠ L'IMAGE FIXE N'EST PLUS UNE CERTITUDE : sur le tableau à vidéo elle n'est PAS posée (§25, « la vidéo
		#   REMPLACE l'image »). Le harnais lit donc son existence, il ne la suppose pas.
		"image_fixe_posee": _final != null,
		"rejouer_visible": _btn_rejouer != null and _btn_rejouer.visible,
		"rejouer": cadre_rejouer(),
		"maison_fin_visible": _btn_maison_fin != null and _btn_maison_fin.visible,
		"maison_fin": cadre_maison_fin(),
		# (B8) LE 3ᵉ BOUTON : est-il OFFERT (y a-t-il une suite ?), est-il POSÉ dans l'arbre, est-il VISIBLE, et où.
		# Trois questions distinctes — un bouton offert mais non posé serait un défaut qu'un seul drapeau cacherait.
		"suivant_offert": _suivant_offert,
		"suivant_pose": _btn_suivant != null,
		"suivant_visible": _btn_suivant != null and _btn_suivant.visible,
		"suivant": cadre_suivant(),
		"suivant_infobulle": _btn_suivant.tooltip_text if _btn_suivant != null else "",
		"boutons_fin": nb_boutons_fin(),
		# (B4) la grille du tableau et la progression
		"tableaux": TableauxPuzzle.nombre(),
		"progression_plus_haut": ProgressionPuzzle.plus_haut(),
		"progression_ouverte": _progression_ouverte,
		"suivant_ouvert": ProgressionPuzzle.suivant_ouvert(tableau),
		"cellule": _cellule,
		# (B6) LA RÉSERVE, LE TAS, LE MODÈLE ET LA CAMÉRA — tout ce que la refonte doit pouvoir prouver
		"reserve": _reserve,
		"tas": _tas,
		"tas_utile": _tas_utile,
		"tas_pas": _tas_pas,
		"modele": _modele_rect,
		"modele_pose": _modele_vue != null,
		"compte_rect": _compte_rect,
		"libelles": _libelles(),                   # tous les écrits de la réserve, avec leur rectangle
		"plan": _plan_travail(),
		"zoom_plancher": ZOOM_PLANCHER,
		"dezoom_mini": _dezoom_mini,
		"recadrages": _recadrages,
		"recadrer": cadre_recadrer(),
		"recadrer_visible": _btn_recadrer != null and _btn_recadrer.visible,
		"modele_plein": _modele_plein,
		"modele_ouvertures": _modele_ouvertures,
		"rect_modele_plein": rect_modele_plein(),
		"pan_souris": _pan_souris,
		# (B12 · §21) LA DISPOSITION AU DOIGT — les quatre places de §21.2, sans qu'un harnais refasse un calcul.
		# ⚠⚠ (B23 · §31.3) LES CLÉS DU BOUTON ONT DISPARU D'ICI (`prendre`, `prendre_actif`, `prendre_pose`,
		#   `prendre_visible`, `prendre_texte`, `prendre_infobulle`, `prendre_souris`, `prendre_etat`,
		#   `prendre_fleche`, `prendre_logo`, `prises_bouton`, `poses_bouton`, `prendre_vides`, `doigt_bouton`) —
		#   avec `pinces_refusees` et `pince_refusee`, qui ne mesuraient que le refus de pincement du §21.4.
		#   Un harnais qui les lit doit sortir ROUGE : c'est le signal qu'il mesure un écran qui n'existe plus.
		#   On les remplace par UNE clé qui, elle, se prouve : `bouton_prendre` est FAUX, toujours et partout.
		"trois_colonnes": _trois_colonnes,
		"deporte_gauche": _deporte_gauche,          # (B13 · §21.9) le cadre de montage a-t-il glissé à gauche ?
		"colonne_gauche": _colonne_g,
		"bouton_prendre": false,                    # (B23 · §31.3) supprimé — la preuve lit ce faux, elle ne le déduit pas
		"piece_prise": piece_prise(),
		"prise_ecart": _prise_ecart,               # (B12) de quoi mesurer « la pièce est SOUS la pointe »
		"doigts": _doigts.size(),
		"pincement": _pincement,
		"doigt_vise": _doigt_vise,
		"saisi": _saisi,                           # QUELLE pièce la main tient — le harnais vérifie qu'il attrape
		"ordre_dessin": _ordre_dessin(),           # …celle du DESSUS, et le tas se lit dans cet ordre-là
		"boite_img": Vector2(_cellule.x + 2.0 * LANGUETTE * _cellule.y, _cellule.y + 2.0 * LANGUETTE * _cellule.x),
	}


# TOUS LES ÉCRITS DE LA RÉSERVE, avec leur rectangle — c'est ce que le harnais relit pour vérifier qu'il n'y a
# RIEN sous le modèle (la demande de Fabrice, GDD §10). On rend l'arbre tel quel : pas une liste tenue à la main
# qui pourrait oublier le libellé qu'on vient d'ajouter.
func _libelles() -> Array:
	var l: Array = []
	if _ihm == null:
		return l
	for enfant in _ihm.get_children():
		if enfant is Label:
			var e := enfant as Label
			# `get_rect()` et non `Rect2(position, size)` : la hauteur d'un libellé vient de sa taille MINIMALE
			# (on ne pose que sa largeur), et c'est cette hauteur-là qui dirait s'il déborde sous le modèle.
			l.append({"texte": e.text, "rect": e.get_rect()})
	return l


# L'ORDRE DE DESSIN DES PIÈCES, du dessous vers le dessus — c'est l'ordre du TAS, et c'est exactement celui que
# `_prendre` remonte pour attraper la pièce qu'on VOIT. Le harnais s'en sert pour jouer le tas par le haut, comme
# un enfant : on prend celle du dessus, et celle d'en dessous paraît.
func _ordre_dessin() -> Array:
	var l: Array = []
	if _jeu == null:
		return l
	var rang := _rang_des_pieces()
	for k in _jeu.get_child_count():
		if rang.has(k):
			l.append(int(rang[k]))
	return l


# LE RANG DE CHAQUE PIÈCE DANS L'ARBRE → son numéro. Ce dictionnaire remplace un `_noeud.find(enfant)` qui
# marchait mais criait : `_noeud` est un `Array[Polygon2D]` TYPÉ, et lui présenter le plateau (un Polygon2D non
# listé, passe encore) ou son cadre (un `Line2D`) fait tomber le moteur dans une erreur de validation par appel —
# quinze par prise, dans le journal de Fabrice comme dans celui du harnais. On demande donc leur place aux pièces
# elles-mêmes, ce qu'aucun type ne peut refuser.
func _rang_des_pieces() -> Dictionary:
	var rang := {}
	for i in _noeud.size():
		if is_instance_valid(_noeud[i]):
			rang[_noeud[i].get_index()] = i
	return rang


# LE CONTOUR D'UNE PIÈCE À L'ÉCRAN, à sa place du moment — languettes comprises. Rendu au harnais pour qu'il
# mesure les recouvrements du tas sur la VRAIE forme, et non sur un rectangle englobant qui mentirait.
func contour_ecran(i: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for p in _noeud[i].polygon:
		pts.append(p + _pos[i])
	return pts


func _nb_blocs() -> int:
	var vus := {}
	for g in _groupe:
		vus[g] = true
	return vus.size()


func contour_image(i: int) -> PackedVector2Array:
	return _contour[i]


func bord_horizontal(r: int, c: int) -> PackedVector2Array:
	return _bord_h[r][c]


func bord_vertical(r: int, c: int) -> PackedVector2Array:
	return _bord_v[r][c]


func position_ecran(i: int) -> Vector2:
	return _pos[i]


func cible_ecran(i: int) -> Vector2:
	return _cible[i]


func groupe_de(i: int) -> int:
	return _groupe[i]


func duree_recompense() -> float:
	return _duree_recompense()


# (B2) Ce que le harnais utilise pour VÉRIFIER le zoom sans tricher : il pousse une molette et relit ces deux-là.
func zoom_courant() -> float:
	return _zoom


func vers_jeu(p: Vector2) -> Vector2:
	return _vers_jeu(p)

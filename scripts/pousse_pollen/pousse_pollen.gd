## ═══════════════════════ INTÉGRATION CoccOs ═══════════════════════
## POUSSE-POLLEN — CONÇU PAR FABRICE (premier jeu contributeur, 2026-07-10→13).
## Source d'origine : dev/contributions/pousse_pollen/ (balle 71) — c'est LÀ que
## le jeu évolue, par ses « balles » ; ce fichier n'ajoute que l'habillage CoccOs
## (bloc en FIN de fichier) : croix de fermeture (haut-droit, ses ◄ N ► décalés
## de 100 px), voix CoccOs sur l'appariement réussi, Échap/retour Android,
## chemins relocalisés (res://scripts/pousse_pollen/, user://pousse_pollen_*).
## ════════════════════════════════════════════════════════════════════
extends Node2D
## Pousse-Pollen — ACCUEIL NETTOYÉ (2026-10-08, décisions Fabrice) : (1) le CHOIX DE CURSEUR est RETIRÉ (« dans le
## jeu il n'y a pas de curseur ») — sélecteur, aperçus, surbrillance et persistance de ce choix supprimés ; une
## ancienne clé choix/curseur est effacée à la prochaine sauvegarde. Le choix d'AVATAR, « Jouer », « Accueil », ◄/►
## et la mémoire avatar/progression sont INCHANGÉS. (2) La PRAIRIE est posée en fond de l'accueil (Fond.appliquer,
## la même image que les autres accueils) par-dessus l'ex-voile brun, qui reste le bouchon à clics. (3) Un curseur
## COCCINELLE et des PETITES FLEURS au clic/touche (fleur.gd + ronde de bureau.gd + pop_joyeux) vivent DANS
## L'ACCUEIL SEULEMENT : tout est enfant de la couche d'accueil, libérée par « Jouer » ; en jeu, curseur système.
## Pousse-Pollen — CHOIX DE CURSEUR RÉTABLI SUR PC (2026-10-08, Fabrice : « sur PC, le curseur est utile ; c'est sur
## Android qu'il n'est pas utile ») : hors mode tactile (Tactile.actif() faux = Linux/Windows), la section « Choisis
## ton curseur » (main/coccinelle/abeille), sa persistance choix/curseur, le curseur choisi EN JEU et le confinement
## fenêtre reviennent (code de 079ed08). En mode tactile (Android) : rien ne change, accueil et jeu comme ci-dessus.
## Prairie, curseur coccinelle + fleurs de l'accueil et choix d'avatar : sur les deux plateformes.
## Pousse-Pollen — Balle 69 (2026-07-13) : TERRE PARTOUT, fin de la verdure et du « marron vide » (décision DESIGN
## Fabrice, test N9/N15). Trois points, RENDU + cadrage uniquement (grilles/mécanique/victoire/preuves INTACTES) :
## (1) ÉCHAPPÉE VERDURE SUPPRIMÉE : plus de bande fond_prairie.png en haut — _construire_horizon, TEX_PRAIRIE,
##   HORIZON_H/HORIZON_CROP_*, _couche_horizon et le Rect2 horizon de _rects_boutons retirés. Le centre-haut se libère.
## (2) FOND ENTIÈREMENT EN TERRE : _draw peint d'abord TEX_TERRE sur toute la fenêtre caméra visible (repère-monde,
##   derrière le plateau) → il n'y a PLUS de default_clear_color brun visible. Le tunnel/grille (sol clair + relief)
##   se peint PAR-DESSUS, inchangé. Univers souterrain intégral. La terre du fond est LÉGÈREMENT assombrie
##   (MOD_FOND_TERRE, luminance — daltonien §1) pour que la galerie éclairée du premier plan ressorte.
## (3) CADRAGE : sans la bande horizon réservée, les tableaux capés par le haut REMONTENT en zoom et se recentrent
##   (bande_v = ECRAN.y pleine). Garde-fou b28/b33 INCHANGÉ (tunnel jamais coupé). Gains zoom mesurés : N11 0.44→0.52,
##   N13 0.51→0.57, N14 0.51→0.60, N17 0.63→0.72, N34 0.81→0.92 (+12 à +18 %) ; N15 (cœur) 0.70→0.72 + recentré ;
##   N9 (large-plat capé en LARGEUR) zoom inchangé 0.46 mais RECENTRÉ verticalement (fini le vide en bas). ⚠ Effet
##   b62 sur les LARGES-PLATS planchés (N18/N19/N21) : la cible de remplissage vertical passe à plein écran → cases
##   plus CARRÉES (ratio 1,15→~1,05) au prix d'un cheveu de zoom (N18 0.65→0.61) — comportement voulu (proportionné
##   > grand-écrasé, dial Fabrice), pas une régression (surface visible ≈, tunnel jamais coupé).
## Preuve : parse godot4 0 err ; planche 38/38 ; rendus X:0 lus (N15/N9/N34/N13/N1/N18). Dials : MOD_FOND_TERRE, FOND_MARGE.
## ---------------------------------------------------------------------------------------------------------------
## Pousse-Pollen — Balle 61 (2026-07-13) : CORRECTIONS DE RENDU (retour test Fabrice). 7 points, tout dans main.gd :
## (1) VUE moins haute → PLONGE_KY 0.68→0.52 (angle refermé, vue plus rasante, l'avatar « circule » dans le couloir).
## (2/3) RELIEF plus marqué (RELIEF_H 0.24→0.46) MAIS pris SUR LA TERRE : la paroi sombre = bande BASSE de la case du
##   MUR (dessus clair = reste haut), plus jamais tirée dans la galerie du dessous → le TUNNEL garde toute sa largeur ;
##   lecture cohérente en haut (crête + reflet) comme en bas (paroi + liseré de crevasse), dans les bornes du mur.
## (4) AVATAR : ce sont les PIEDS (AV_PIEDS_FRAC=0.90 du core) qui se posent au centre de case ; le corps/tête déborde
##   vers le HAUT et passe par-dessus le terrain (dessiné en dernier). (5) BRAS = PENDULE AMORTI (même ressort que le
##   flotteur des boules b56, _bras_bal) : balancent franchement à chaque geste puis se stabilisent (fini « ils bougent
##   à peine »). (6) BOULES : sens de roulement DISTINCT par direction (droite=horaire/gauche=anti ; descendre=anti/
##   monter=horaire) → plus « toutes le même sens » (rotation z = choix artistique, cf. _declencher_roulement).
## (7) HORIZON/verdure DERRIÈRE le plateau (CanvasLayer layer=-1) → ne masque JAMAIS une case ni ne coupe le perso
##   (tout se peint par-dessus) ; crop ZOOMÉ (HORIZON_CROP_*) sur les pâquerettes + coccinelles nettes du midground.
## Réglages exposés en constantes. Preuve : parse godot4 0 err ; planche 38/38 ; rendus X:0 lus (petit/pic large/trous/
## ex-injouable + anim bras + roulement). 0 régression jouabilité (grilles/mécaniques/victoire/caméra b33 INCHANGÉS).
## ---------------------------------------------------------------------------------------------------------------
## Pousse-Pollen — Balle 60 (2026-07-13) : RELIEF 2.5D sur la vue plongée (GDD §4ter, réf maquette Ryzlord
## core/tilemap.py : côté sombre / dessus clair / fond sombre / tri par y). PAS de 3D, PAS de rotation caméra :
## la profondeur est donnée par la COULEUR (luminance). Les murs de terre ('#') sont des BLOCS EXTRUDÉS = face
## SUPÉRIEURE claire (TEX_TERRE pleine) + FACE LATÉRALE plus sombre (COL_RELIEF_COTE) tirée vers le BAS (vers la
## caméra) sur RELIEF_H·CELL, dessinée SEULEMENT quand la case du dessous n'est pas un mur → là où un mur borde
## une galerie EN CONTREBAS, cette face + un LISERÉ de fond sombre (COL_RELIEF_FOND) au pied = la PAROI + le
## « trou » du TUNNEL CREUSÉ ; un reflet clair (COL_RELIEF_REFLET) sur l'arête haute = lumière rasante. Rendu en
## DEUX passes dans _draw (peintre, tri par y) : (1) tous les SOLS (_dessiner_sol), (2) puis les MURS du HAUT vers
## le BAS (_dessiner_mur) → chaque face latérale coiffe le haut de la rangée du dessous, un mur plus bas recouvre
## la face du mur du dessus (occlusion correcte). Dosage = RELIEF_H (0.24) + RELIEF_LISERE + RELIEF_REFLET_H, seuls
## leviers. Entités (boules/avatar) posées au CENTRE et dessinées APRÈS le terrain → jamais masquées ; cadrage
## anti-UI b33 INCHANGÉ (la face latérale = terre débordante, autorisée à sortir ; les cases praticables restent
## visibles). Preuve : parse godot4 0 erreur ; planche 38/38 ; rendus lus X:0 (N01 petit, N08 spirale, N16 pic
## PAPA, N31 peigne 6 boules) — relief net, grille lisible, 0 régression. Rien d'autre modifié (grilles, mécaniques,
## victoire, caméra b33, boule b56, avatar b59, vue plongée b55, horizon b55, choix b49).
## ---------------------------------------------------------------------------------------------------------------
## Pousse-Pollen — Balle 59 (2026-07-13) : AVATAR = le VRAI perso CoccOs « BRAS LE LONG » (nouveaux persos Gemini
## coccos.png / l'ami l'abeille.png), ANIMÉ EN CUTOUT. Pipeline : image bras-le-long → DÉTOURAGE (faux alpha Gemini :
## damier gris PEINT, alpha=255 → outils/detour_avatar_b59.py) → DÉCOUPE en membres par masques polygonaux
## (outils/decoupe_membres_b59.py → 5 pièces pleine toile/perso : core troué + brasG/D + jambeG/D) → animation cutout
## DANS _draw. ⚠ Skeleton2D = scene-nodes (Bone2D/Polygon2D) ; ce jeu rend TOUT en _draw immédiat (choix Fabrice,
## GDD §7bis) → j'implémente le MÊME PRINCIPE cutout (membres rigides pivotés autour de leur attache) là où l'avatar
## vit déjà, sans greffer un sous-arbre Skeleton2D (cf. RES b59). • _dessiner_avatar dessine jambes→core→bras (peintre)
## chacun tourné par _dessiner_membre autour de son pivot ; l'impulsion `pulse` (0→1→0 sur AVATAR_DUREE_GESTE) pilote
## repos (bras le long) / marche (jambes alternées + bras opposés + bob) / pousse (mains vers la boule + corps penché
## + pas) / tire (mains agrippées vers la boule + corps reculé + pas inverse). Au repos = pièces à l'identité =
## image d'origine reconstituée (0 fantôme). • _texture_avatar → texture ENTIÈRE bras-le-long (accueil + ami-récompense
## b50, cohérents). • CURSEURS b52 INCHANGÉS (doigt levé, _texture_curseur_perso). Preuve : parse godot4 0 erreur ;
## planche 38/38 ; frames d'anim lues (repos/marche/pousse/tire, coccinelle ET abeille). Rien d'autre modifié
## (grilles, mécaniques, victoire, caméra b33, boule roulante b56, vue plongée b55, choix b49).
## ---------------------------------------------------------------------------------------------------------------
## Pousse-Pollen — Balle 54 (2026-07-13) : HABILLAGE TERRAIN par textures Gemini. Murs (terre pleine) = TEX_TERRE
## FONCÉE, sol/galeries praticables = TEX_SOL ocre CLAIRE (distinction de LUMINANCE conservée, daltonien §1),
## boules = sprite TEX_POLLEN détouré du fond blanc (l'étiquette d'appariement reste peinte par-dessus). Les
## textures terre/sol sont ÉTALÉES sur toute la grille (_texturer_case → draw_texture_rect_region, une part de
## texture par case) : image continue, sans répétition ni couture. Le sol ':' (détails traversables) garde sa
## nuance via MOD_SOL_TEINTE par-dessus la texture. Aplats COL_MUR/COL_SOL_TEINTE/COL_POLLEN supprimés.
## ─ Balle 52 (2026-07-13) : VRAIS AVATARS CoccOs (remplacent les placeholders DESSINÉS b49). Les 3 PNG
## transparents de l'app CoccOs (textures/coccinelle.png · abeille.png · main.png) sont importés en Texture2D (preload
## TEX_*) et rendus tels quels. • AVATAR EN JEU : _dessiner_avatar peint la texture (coccinelle/abeille) ajustée à la
## case (ratio préservé, _dessiner_texture_fit). • CURSEUR souris : _appliquer_curseur → _curseur_souris pose la VRAIE
## image redimensionnée sous la limite matérielle (≤ 256 px) avec HOTSPOT = bout du doigt levé (proportions mesurées).
## • APERÇUS D'ACCUEIL : _apercu_avatar / _apercu_curseur dessinent les mêmes textures. Placeholders SUPPRIMÉS
## (_peindre_coccinelle / _peindre_abeille / _peindre_curseur / _texture_curseur). Fonctionnel b49 CONSERVÉ (choix,
## mémorisation user://pousse_pollen_progression.cfg, bouton « Accueil », confinement fenêtre). Doigt levé retiré à l'habillage = roadmap.
## Preuve : parse godot4 0 erreur ; 38 niveaux ; rendus lus (accueil 3 vrais avatars + N coccinelle + N abeille). Rien
## d'autre modifié (grilles, mécaniques, victoire, caméra b33, sauvegarde). FORMES_niveaux.md NON touché.
## ---------------------------------------------------------------------------------------------------------------
## Pousse-Pollen — Balle 50 (2026-07-13) : RÉCOMPENSE DE RÉUSSITE VARIÉE (GDD §2.3 l.87). À la victoire, on ALTERNE
## désormais deux scénarios positifs et calmes (variété §1) : variante 0 = éclat de pollen jaune (b36, CONSERVÉ),
## variante 1 = l'AMI (l'AUTRE perso : abeille si avatar coccinelle, coccinelle si avatar abeille) revient faire un
## câlin (arrivée fondu + petit bond) avec de PETITS CŒURS qui s'allument un à un. Dans les deux cas : court, calme,
## PUIS le MÊME auto-passage (b36, DUREE_SAVOURER_VICTOIRE_S). Effet RÉGLABLE/COUPABLE : RECOMPENSE_EFFETS=false coupe
## TOUT effet (Bravo ! + auto-passage restent). Câblage : _afficher_reussite bascule _recompense_variante ; nouvelles
## _lancer_ami_remercie / _peindre_coeur / _forme_coeur (persos réutilisés, cœurs dessinés — PLACEHOLDERS, habillage
## fin = roadmap). Nœuds enfants de la couche « Bravo ! » + tweens liés à leur nœud → libérés avec elle (0 fuite).
## Vérifié BALLE 50 : guidage tutoriel N1 (flèche gauche pulse, _lancer_guide) + N4 (Agripper+bas pulsent quand une
## boule est au-dessus, _maj_guide_tirer) INTACTS après les refontes (câblés dans _aller_a_niveau) — RIEN à restaurer.
## Périmètre : AUCUNE grille, mécanique, victoire (condition), caméra b33, débounce, nav, sauvegarde, accueil/avatar
## b49 modifiés. Preuve : parse godot4 0 erreur ; rendus lus (victoire variante « cœurs » + N1 avec guide) ; 38 niveaux.
## ---------------------------------------------------------------------------------------------------------------
## Pousse-Pollen — Balle 49 (2026-07-13) : ÉCRAN D'ACCUEIL + CHOIX D'AVATAR / CURSEUR (GDD §2.3 l.60/l.72 — pièce
## jamais implémentée). Au LANCEMENT (et à chaque clic « Accueil »), l'enfant choisit son AVATAR (coccinelle/abeille)
## et son CURSEUR (main gantée/coccinelle/abeille), puis « Jouer » entre dans le jeu (sélecteur ◄/► existant conservé).
##  • ACCUEIL = overlay plein écran (_afficher_accueil / _quitter_accueil) qui MASQUE l'UI de jeu (_couches_jeu) et
##    capte tous les clics (fond MOUSE_FILTER_STOP) → aucun geste ne passe au jeu tant qu'on choisit ; _en_accueil
##    bloque aussi le clavier (_unhandled_input). Cases = aperçu dessiné (placeholders) + libellé + grande cible.
##  • AVATAR EN JEU : _dessiner_avatar dispatche sur _avatar_type → _peindre_coccinelle (historique, INCHANGÉ) ou
##    _peindre_abeille (placeholder jaune + rayures noires + ailes + antennes — distinct par le MOTIF, daltonien).
##  • CURSEUR : _appliquer_curseur pose une texture placeholder (_texture_curseur : disque + liseré + motif) et
##    confine le pointeur à la FENÊTRE (Input.MOUSE_MODE_CONFINED). ⚠ « confiné au TUNNEL » STRICT est impossible
##    tant que les boutons (D-pad, Agripper, ◄/►) vivent HORS du tunnel → confinement fenêtre = placeholder fidèle,
##    confinement fin au couloir = ROADMAP (signalé au RES). Rendu FIN des avatars/curseurs = habillage/roadmap.
##  • MÉMOIRE : choix persistés dans user://pousse_pollen_progression.cfg, section "choix" (_charger_choix/_sauver_choix) — À CÔTÉ
##    de la progression, sauvegardes FUSIONNÉES (relire avant d'écrire) → ni la progression ni le choix ne s'écrasent.
##  • RÉ-MODIFIABLE : bouton « Accueil » EMPILÉ avec « Recommencer » DANS la MÊME zone réservée haut-gauche (aucun
##    NOUVEAU rectangle d'évitement) → cadrage b33 STRICTEMENT INCHANGÉ. Preuve : zoom+position IDENTIQUES 38/38
##    (mesure headless), planche 38/38 re-rendue, rendus b49 lus (accueil + N11 coccinelle + N11 abeille). Parse 0 erreur.
##  • Périmètre : AUCUNE grille, mécanique, victoire, sauvegarde-progression, débounce, nav modifiée. La planche
##    (outils/planche.gd) retire l'accueil avant de rendre les niveaux (idempotent). Décor fin = roadmap (rien dans FORMES).
## Pousse-Pollen — Balle 48 (2026-07-13) : TROIS niveaux SUPPLÉMENTAIRES N36/N37/N38 ajoutés APRÈS N35 (le jeu passe
## à 38), de difficulté SUPÉRIEURE à N34/N35 (joueur addict), design LIBRE, les 3 DIFFÉRENTS et en escalade CROISSANTE
## PROUVÉE : N36 = ENFILAGE long (tube 4 loges scellé, ordre forcé, appariement porteur+piégé) opt 74 ; N37 = GRANDE
## BOUCLE 2 cases de large (les BOULES circulent autour du bloc central, appariement croisé) opt 78 ; N38 = FINALE
## ULTIME BOUCLE × ENFILAGE (version agrandie de N35, 4 boules) opt 93. Tous > N35 (62). Preuve rendus/b48/pp_b48.py
## (réplique EXACTE du moteur, solveur VALIDÉ N10=11/N15=29) : opt EXACT (BFS bidir), 0 boule triviale, 0 cul-de-sac
## (réversibilité), appariement piégé, tests de CUT (murer la bouche → INSOLUBLE ; retirer le bloc → opt s'effondre).
## Câblage AUTOMATIQUE : NIVEAUX +3 grilles → l'écran de fin (_fin_victoire_niveau_suivant, borne NIVEAUX.size()-1) et
## la planche (outils/planche.gd) suivent la taille. NIVEAUX_PIC INCHANGÉ (N35 la plus dure est déjà hors pic → trio
## expert cohérent sans bandeau ; supersede la note balle-21 « ex-démos N36-38 retirées »). Périmètre STRICT : SEULES
## les 3 nouvelles grilles + la liste NIVEAUX + les commentaires « dernier » changent ; le reste INCHANGÉ. Décor = roadmap.
## Pousse-Pollen — Balle 44 (2026-07-12) : N9 REFAIT en « écris ton prénom » (tableau-mot). Retour de test Fabrice :
## l'ancien N9 (petite chambre mélange chiffres+lettres) ressemblait à N7/N8 → rébarbatif. Nouveau N9 = champ OUVERT
## (aucun mur intérieur, juste le cadre) : une rangée de croix EN HAUT porte PRENOM_DEFAUT (« ISABELLA ») DANS
## L'ORDRE, et dessous les boules portent les MÊMES lettres EN DÉSORDRE. L'enfant pousse chaque boule sur la croix
## de SA lettre → en les remettant en ordre, il écrit son prénom. Doublons (2×A, 2×L) INTERCHANGEABLES (la victoire
## typée compare les étiquettes AFFICHÉES → n'importe quelle croix de la bonne lettre convient). Mécanisme « mot
## imposé » : TUTO_SYMBOLES[8]="impose" → _generer_etiquettes n'affiche PAS un tirage aléatoire mais la LETTRE-CLÉ
## elle-même (identité) ; la grille encode le prénom (croix = MAJ dans l'ordre, boules = min en désordre). PRENOM_DEFAUT
## = constante propre, prête pour le futur prénom-par-compte (chantier DISTINCT — non fait ici). N9 perd « tirer
## indispensable » (assumé, validé Fabrice ; le tirer reste enseigné en N4/N5). Preuve (rendus/b44/prouver_b44.py,
## réplique moteur) : soluble (séquence vérifiée par rejeu), 0 cul-de-sac (réversibilité universelle poussée↔tirage,
## champ ouvert), désordre RÉEL (0 boule sous une croix de sa lettre : boules aux colonnes PAIRES, croix aux IMPAIRES),
## doublons gérés. Rendu X:0 lu (rendus/planche/N09.png). SEUL N9 change (+ const PRENOM_DEFAUT + mode "impose") :
## N1-N8, N10-N35, mécaniques, caméra b33, débounce b35, nav ◄/►, victoire b36, décor b43, sauvegarde, NIVEAUX_PIC : INCHANGÉS.
## Pousse-Pollen — Balle 41 (2026-07-12) : genre 5 « COMBINAISONS » (dernier genre) — N33/N34/N35 marient ≥ 2 genres,
## chacun distinct, N35 = GRANDE FINALE. N33 = FORME (champignon) × appariement piégé ; N34 = COMPACT × ENFILAGE ×
## appariement ; N35 = BOUCLE × ENFILAGE × appariement (la plus dure, hors pic). Progression opt 29 < 54 < 62, toutes
## 0 cul-de-sac (réversibilité). Chaque combinaison PROUVÉE nécessaire par test de cut (BFS exact, réplique moteur
## rendus/b41/pp_b41.py). N32 laissé en palier ; N1-N31, mécaniques, caméra b33, débounce b35, nav ◄/►, victoire b36,
## NIVEAUX_PIC [10,15,20,25,30], sauvegarde : INCHANGÉS. Seules 3 grilles (N33/N34/N35) + leurs commentaires changent.
## Pousse-Pollen — Balle 40 (2026-07-12) : TUTO N6-N10 ÉVOLUTIF — introduction PROGRESSIVE de l'appariement par
## symbole (façon musicale, UNE nouveauté/niveau), AVANT le piège assené de N11. N1-N5 = échelle mécanique pure,
## INCHANGÉS (appariement par POSITION). N6 = chiffres seuls sans piège · N7 = chiffres, piège léger (lire avant de
## pousser) · N8 = lettres, TUNNEL SPIRALE escargot (balle 42) · N9 = « écris ton prénom » tableau-mot (REFAIT balle 44,
## voir en-tête) · N10 = croix collées douces (pré-goût genre 3, ordre court réversible).
## Câblage : TUTO_SYMBOLES (index→pool) + _generer_etiquettes(mode) → N11-N35 gardent "mix" (INCHANGÉS). L'affichage
## des étiquettes s'active tout seul (grilles typées a/A). Preuve (rendus/b40/verifier_b40.py, réplique EXACTE du
## moteur) : SOLUBLES, coups BAS, 0 cul-de-sac (réversibilité), N7&N10 piège/ordre 1/2, N6/N7/N8/N10 push-only
## jouables (N9 refait balle 44 → « écris ton prénom », voir en-tête). Périmètre STRICT : seules les grilles N6-N10
## + le câblage TUTO_SYMBOLES/_generer_etiquettes changent ; N11-N35, mécaniques, caméra b33, débounce b35, nav ◄/►,
## victoire b36, NIVEAUX_PIC, sauvegarde : INCHANGÉS.
## Pousse-Pollen — Balle 39 (2026-07-12) : genre CROIX GROUPÉES / ENFILAGE (2 niveaux — 3ᵉ genre du « programme contenu »).
## Demande Fabrice (FORMES_niveaux.md §PROGRAMME, genre 3) : sur 2 niveaux GÉNÉRIQUES restants (N23, N29 — ni dessins,
## ni boucles, ni compacts, ni pics), grouper les CROIX (loges) en un BLOC COLLÉ où l'on doit ENFILER les bonnes boules
## une par une → l'ORDRE compte (une boule mal placée bloque l'accès aux croix voisines). Réalisation : rack VERTICAL
## SCELLÉ — colonne de loges A..D (N23) / A..E (N29) murée sur le côté, accessible SEULEMENT par la BOUCHE du bas ; pour
## poser une boule sur la loge du HAUT il faut la pousser à travers toute la colonne VIDE → on remplit du FOND vers la
## bouche, l'ordre est FORCÉ. Boules alignées en rangée sous le rack, appariement (étiquettes au hasard) PIÉGÉ (la loge
## la plus proche de chaque boule = la bouche, donc une AUTRE clé). Diversité = taille du bloc (4 vs 5 croix). Preuve
## (rendus/b39/ : pp_b39.py réplique EXACTE du moteur, build_b39.py construit par extraction depuis l'état résolu puis
## PROUVE) : SOLUBLE (BFS exhaustif, opt 55 / 85 coups) ; 0 cul-de-sac dur par RÉVERSIBILITÉ UNIVERSELLE (0 arête sans
## inverse — 7041 / 52969 états, exhaustif) ; ORDRE FORCÉ (murer la bouche D/E scelle la colonne → INSOLUBLE, BFS exact) ;
## appariement piégé 3/4 et 4/5. Périmètre STRICT (garde-fous brief) : SEULES les grilles NIVEAU_23 et NIVEAU_29 changent —
## aucune autre grille, aucune mécanique, cadrage b33, débounce b35, nav ◄/►, victoire b36, sauvegarde : INCHANGÉS.
## Pousse-Pollen — Balle 38 (2026-07-12) : genre ABSTRAITS COMPACTS (3 niveaux — 2ᵉ genre du « programme contenu »).
## Demande Fabrice (FORMES_niveaux.md §PROGRAMME, genre 2) : remplacer des niveaux encore GÉNÉRIQUES (rectangles b22)
## par des grilles réduites au MINIMUM de cases de sol (calcul) → la difficulté vient de la CONTRAINTE SPATIALE
## (l'espace serré IMPOSE l'ordre des coups, parfois « démonter pour remonter »), et la PUISSANCE DE CALCUL est
## démontrée par la PREUVE du minimum. Un genre à la fois, sur QUELQUES niveaux (anti-extrémisme) : ici N22, N24, N28
## SEULS (rectangles génériques, ni dessins N11-19, ni boucles N20/30, ni pics). 3 formes DISTINCTES : N22 = échelle
## verticale (2 couloirs joints par 3 barreaux) ; N24 = moulin diagonal (croisement dans 9 cases) ; N28 = marteau
## horizontal à poche (RÉORDONNANCEMENT : garer une boule dans la poche pour croiser l'autre = démonter/remonter).
## Appariement CONSERVÉ (2 boules/niveau, étiquettes tirées au hasard) : N24 et N28 = croisement PIÉGÉ (la loge la plus
## proche de chaque boule porte l'AUTRE étiquette) ; N22 = appariement franc (aucune boule triviale). Preuve (solveur
## rendus/b38/pp_b38.py, réplique EXACTE de _tenter_deplacement/_tenter_poussee/_tenter_tirage/_verifier_victoire,
## validé contre 5 opt documentés) : les 3 SOLUBLES (opt 24 / 24 / 30 coups, BFS EXACT) ; 0 cul-de-sac dur (BFS INVERSE
## exhaustif depuis l'état de départ : depuis TOUT état atteignable on revient au départ) ; MINIMUM PROUVÉ — murer
## N'IMPORTE quelle case de sol LIBRE de plus rend le niveau INSOLUBLE (8/8, 4/4, 6/6 cases libres testées ; les cases
## restantes portent avatar/boule/loge = structurellement nécessaires). Périmètre STRICT (garde-fous brief) : SEULES
## les grilles NIVEAU_22, NIVEAU_24, NIVEAU_28 changent — aucune autre grille, aucune mécanique, cadrage b33, débounce
## b35, nav ◄/►, animation victoire b36, sauvegarde : INCHANGÉS. Non-régression garantie (le socle absorbe 3 grilles).
## Pousse-Pollen — Balle 37 (2026-07-12) : genre TUNNEL-BOUCLE (2 niveaux — début du « programme contenu »).
## Demande Fabrice (GDD §2.3 « topologie boucle », regret : disparu au recalibrage b22) : réintroduire le tunnel-
## boucle — galerie en BOUCLE FERMÉE autour d'un bloc central plein ; la boule est sur l'anneau, sa loge dans un
## COIN ; depuis le départ, ni pousser ni tirer directement ne la posent → dans un couloir d'UNE case de large
## l'avatar ne peut pas croiser la boule, il doit faire le TOUR pour se placer derrière elle et la pousser. On ajoute
## UN genre à la fois, sur QUELQUES niveaux (anti-extrémisme) : ici N20 et N30 SEULS (niveaux génériques, ni dessins
## N11-N19, ni pics). Deux VARIANTES distinctes : N20 = anneau simple CARRÉ 7×7 ; N30 = anneau RECTANGULAIRE large
## 9×7 (tour plus long, sens miroir). UNE boule par niveau → on démontre le GENRE seul (appariement trivial, sans
## piège d'étiquette). Le passage d'un COIN se fait au TIRER (on ne pousse pas une boule dans un angle : geste N4).
## Preuve (solveur /tmp/pp_b37.py, réplique EXACTE de _tenter_deplacement/_tenter_poussee/_tenter_tirage/_verifier_
## victoire) : les DEUX niveaux SOLUBLES (opt 39 et 49 coups) ; l'avatar visite 100 % des cases praticables (16/16,
## 20/20) = il fait bien le TOUR ; 0 cul-de-sac dur (co-atteignabilité EXHAUSTIVE, 0 arête non-réversible) ; BOUCLE
## PROUVÉE NÉCESSAIRE — couper l'anneau en N'IMPORTE quelle case rend le niveau INSOLUBLE (13/13 et 17/17) → un
## couloir non bouclé ne résout pas, la fermeture de la boucle est requise. Périmètre STRICT (garde-fous brief) :
## SEULES les grilles NIVEAU_20 et NIVEAU_30 changent — aucune autre grille, aucune mécanique, cadrage b33, débounce
## b35, nav ◄/►, animation victoire b36, sauvegarde : INCHANGÉS. Non-régression garantie (le socle absorbe 2 grilles).
## Pousse-Pollen — Balle 36 (2026-07-12) : ANIMATION DE VICTOIRE — éclat de gouttelettes JAUNES (pollen) avant l'auto-passage.
## Demande Fabrice : l'auto-passage (b34) ne doit pas être instantané — il faut VOIR le moment de victoire. À la
## victoire, le mot « Bravo ! » s'affiche AVEC un petit ÉCLAT de gouttelettes jaunes (évoque le pollen) qui part du
## mot, le temps de SAVOURER (~1,6 s), PUIS le niveau suivant se charge tout seul (écran de fin au N35, l'éclat y joue
## aussi avant). Rester LÉGER, pas envahissant. Réalisation : _lancer_gouttelettes_pollen() (CPUParticles2D one-shot,
## explosiveness 1 = burst radial, gravité douce = retombée « pollen », fondu alpha via color_ramp, disque doux généré
## par _texture_gouttelette) ajouté à la couche « Bravo ! » (_afficher_reussite) → libéré AVEC elle (aucune fuite).
## Durée ISOLÉE en constante ajustable DUREE_SAVOURER_VICTOIRE_S (remplace le 1.6 en dur du tween d'enchaînement).
## Jaune sur brun = contraste de LUMINANCE (jamais la teinte seule, daltonien GDD §1). Non-régression : débounce ◄/►
## (b35), Agripper, D-pad, cadrage b33, écran de fin, sauvegarde — INCHANGÉS (le burst est décoratif, ne capte aucun
## clic : le « Recommencer » reste actionnable pendant le « Bravo ! »). Aucune grille modifiée. Preuve : rendu réel X:0
## (rendus/b36/victoire_f08.png = éclat naissant, f22.png = mot + gouttelettes épanouies).
## Pousse-Pollen — Balle 34 (2026-07-12) : NAVIGATION AUTO-EXPLICATIVE par flèches ◄/► ; FIN du mode SÉLECTION.
## Retour de test Fabrice : la recherche de niveau par le bouton « OK » (mode sélection b16) n'était PAS comprise
## au premier aperçu (« ça doit s'expliquer tout seul » — Fabrice ne peut pas être derrière chaque enfant). On
## SUPPRIME le mode sélection et on le remplace par deux flèches de NAVIGATION DE NIVEAU dédiées :
##  • Le mode SÉLECTION b16 DISPARAÎT : plus de bouton « OK », plus de bascule Agripper→OK, plus de détournement
##    des flèches du D-pad. Le bouton bas-gauche est TOUJOURS « Agripper » (mécanique de jeu) ; le D-pad déplace
##    TOUJOURS l'avatar. (_mode_selection + _entrer_mode_selection / _naviguer_selection / _valider_selection /
##    _maj_libelle_agripper RETIRÉS.)
##  • Deux flèches ◄/► (triangles PLEINS dessinés, fond clair, coin HAUT-DROITE sous « Niveau N » → style ET place
##    nettement distincts du D-pad, pour ne pas confondre « changer de tableau » et « déplacer l'avatar ») changent
##    de NIVEAU : ◄ = niveau précédent (CACHÉE au N1) ; ► = niveau suivant, VISIBLE SEULEMENT si débloqué
##    (niveau+1 ≤ _niveau_max_atteint ; unlock_all débloque tout). Un clic CHARGE DIRECT (pas de validation).
##    Réservées dans _rects_boutons → le tunnel ne passe jamais dessous (non-régression cadrage b33).
##  • Post-victoire : plus de retour en sélection → AUTO-passage au niveau suivant (_aller_a_niveau(courant+1)),
##    écran de FIN au N35. L'enfant peut aussi naviguer librement à tout moment par ◄/►. (DÉCISION de design,
##    non spécifiée au CDC → SIGNALÉE au RES ; alternative = rester sur le niveau gagné, ► guidant vers la suite.)
## Non-régression : cadrage b33 (zoom max, centré, tunnel visible), étiquettes/appariement (b21/b24), sauvegarde/
## unlock_all (b25), pousser/tirer/agripper, écran de fin (b24). SEUL le flux d'UI change (aucune grille touchée).
## Pousse-Pollen — Balle 24 (2026-07-11) : PILOTE « FORMES » (N11-N14 = figures) + étiquettes AU HASARD + fin.
## Retour de test Fabrice : les grottes rectangulaires du recalibrage b22 étaient « moches et ennuyeuses »,
## et « difficulté = nombre de coups » n'est PAS le but. Nouvelle direction (pilote, petit exprès) :
##  • FORMES : N11-N14 redessinés comme des FIGURES reconnaissables dont le CONTOUR dessine le tunnel —
##    N11 papillon, N12 maison, N13 fusée, N14 tournesol en pot (contours : FORMES_niveaux.md). La difficulté
##    vient de la MANŒUVRE dans la forme (contourner/croiser/traverser), pas d'un nombre de coups. Code place
##    boules/loges à l'intérieur et garantit soluble + 0 cul-de-sac dur (réversibilité) + appariement piégé
##    (signalé si la forme l'empêche : tournesol = 1/2 piège, sa loge de cœur jouxte les boules). N15-N34
##    laissés tels quels pour ce pilote (refonte en formes après validation) ; N1-N10 inchangés.
##  • ÉTIQUETTES AU HASARD : les symboles affichés ne suivent plus la suite 1-2-3 / A-B-C ; à chaque
##    chargement, chaque clé d'appariement reçoit un symbole tiré au hasard dans un pool qui MÊLE chiffres
##    ET lettres (POOL_CHIFFRES/POOL_LETTRES, _generer_etiquettes). La clé grille (a/A…) reste l'appariement,
##    seul l'AFFICHAGE change → victoire typée intacte. Remplace l'ancien NIVEAUX_CHIFFRES (blocs figés).
##  • FIN : au dernier niveau (N35) on n'affichait plus rien de neuf → le jeu rebouclait sur N35. Corrigé :
##    ÉCRAN DE FIN / félicitations (GDD §1 « récompense de félicitations », cœurs) + bouton « Rejouer » →
##    retour en sélection (choix libre, aucun cul-de-sac d'écran). Voir _afficher_ecran_fin.
## Non-régression : mécaniques pousser/tirer/agripper, caméra b20/b23, sélecteur b16, annonce pic, n° de
## niveau, victoire typée — inchangés. Preuve : solveur /tmp/pp_b24 (réplique moteur) + rendus X:0 lus.
## Pousse-Pollen — Balle 21 (2026-07-10) : APPARIEMENT intriqué déployé DÈS N11, en CHIFFRES ET LETTRES.
## Demande ferme de Fabrice (valeur ÉDUCATIVE — l'enfant reconnaît chiffres ET lettres). Sur les niveaux ≥ N11
## (N1-N10 = découverte, SANS appariement), chaque boule porte une étiquette et ne gagne que sur la loge de MÊME
## étiquette (victoire typée de la balle 17). Nouveautés balle 21 :
##  • DÉPLOIEMENT : les 25 niveaux N11→N35 sont désormais ÉTIQUETÉS (les grilles O/X sont devenues a-c / A-C ;
##    géométrie, murs, avatar INCHANGÉS — seuls les glyphes boule/loge portent une clé d'appariement).
##  • CHIFFRES ET LETTRES, variés par bloc de 5 (NIVEAUX_CHIFFRES) : N11-15 chiffres, N16-20 lettres,
##    N21-25 chiffres, N26-30 lettres, N31-35 chiffres. L'encodage grille reste letter-based ; _etiquette_affichee
##    rend la clé « A/B/C » en « 1/2/3 » sur un niveau chiffres → l'ENCODAGE supporte les deux SANS toucher le parseur.
##  • PREUVE (solveur BFS TYPÉ /tmp/pp_b21.py, réplique exacte pousser/tirer/marche) : les 25 niveaux SOLUBLES en
##    victoire typée, coups min = ceux d'origine (mapping issu d'une solution réelle → difficulté préservée,
##    recalibrage = balle suivante) ; 0 cul-de-sac dur (co-atteignabilité exhaustive ≤ N ; réversibilité universelle
##    pour les 3 pics à 3 boules N16/21/26/31). Les 3 ex-démos N36-N38 (balle 17) sont RETIRÉES (redite) → N35 = DERNIER.
## Pousse-Pollen — Balle 17 (refonte 2/3) : APPARIEMENT boule↔loge (étiquette chiffre/lettre).
## Balle 17 (2026-07-10, GDD §2.3 « AJUSTEMENTS POST-TEST » + « Appariement boule↔loge ») : chaque loge
## et chaque boule peuvent désormais porter une ÉTIQUETTE ; la victoire d'un niveau ÉTIQUETÉ exige que
## CHAQUE boule repose sur la loge de MÊME étiquette (plus « n'importe quelle loge »). Rétro-compatible :
## un niveau SANS étiquette garde la victoire actuelle (toute boule sur tout 'X') → N1-N10 restent NON typés
## (balle 21 a depuis étiqueté N11-N35 ; le régime NON typé sert désormais la découverte N1-N10).
##  • ENCODAGE grille : une lettre MINUSCULE 'a'-'z' = une BOULE d'étiquette maj(lettre) ; une lettre
##    MAJUSCULE 'A'-'Z' = une LOGE de cette lettre. 'O'/'X' restent la boule/loge SANS étiquette (glyphes
##    de base intacts). Boule 'a' et loge 'A' partagent la même étiquette affichée « A » → l'enfant les
##    apparie à l'œil. L'étiquette est un ATTRIBUT (pas un nouveau type de terrain) : le terrain stocke
##    TOUJOURS 'X' pour toute loge, les étiquettes vivent à côté (_loges_etiquette / _boules_etiquette) →
##    toute la logique acquise (X=loge, franchissable, caméra, tirer, sélecteur) reste INTACTE.
##  • RENDU : l'étiquette est dessinée SUR la boule ET SUR la loge (gros caractère sombre + liseré clair =
##    luminance + le caractère, jamais la couleur seule — daltonien, GDD §1).
##  • DÉMONSTRATION (balle 17) : trois niveaux témoins avaient été appendus (N36-N38) pour POSER la mécanique ;
##    ils sont RETIRÉS en balle 21 (redite), l'appariement étant maintenant déployé sur N11-N35. Fondement
##    0-cul-de-sac (toujours valable) : les étiquettes ne changent QUE l'ensemble-but, pas les transitions →
##    réversibilité intacte (graphe non orienté) → tout niveau soluble en a 0.
## Pousse-Pollen — Balle 16 (refonte 1/3) : SÉLECTEUR DE NIVEAUX (deux modes, réutilise flèches + bouton).
## Balle 16 (2026-07-10, GDD §2.3 « Sélecteur de niveaux » + AJUSTEMENTS POST-TEST) : on peut désormais
## REJOUER un niveau déjà réussi sans tout recommencer. Deux modes partagent les MÊMES contrôles :
##  • Mode SÉLECTION (au LANCEMENT et APRÈS CHAQUE VICTOIRE) : le bouton Agripper affiche « OK » ; les
##    flèches GAUCHE/DROITE font défiler le niveau AFFICHÉ (aperçu chargé) dans [N1 … `_niveau_max_atteint`]
##    — droite bloquée au plus haut atteint (jamais de niveau non débloqué), gauche bloquée à N1, haut/bas
##    sans effet ; l'avatar ne bouge pas. Un aperçu de pic peut afficher le bandeau « Niveau difficile ».
##  • Appui « OK » (bouton ou barre espace) → mode JEU : le bouton redevient « Agripper », les flèches
##    reprennent le déplacement de l'avatar, le niveau choisi est (re)chargé propre et devient jouable.
## `_niveau_max_atteint` (persisté sur DISQUE depuis la balle 25 : user://pousse_pollen_progression.cfg) mémorise le plus haut niveau débloqué :
## à chaque victoire, max(_, courant+1) borné à N35. Après victoire : « Bravo ! » puis (court délai) retour en
## SÉLECTION positionné sur le suivant débloqué, recul possible. Le bouton dédié « Niveau suivant » est SUPPRIMÉ
## (le flux passe par SÉLECTION + OK). « Recommencer » (rejoue le niveau courant, mode JEU) est conservé.
## Non-régression : mécanique pousser/tirer/agripper, 35 grilles, annonce pic, caméra, victoire — inchangées.
## Périmètre STRICT : le sélecteur uniquement (appariement boule↔loge et recalibrage = balles suivantes).
## Pousse-Pollen — Balle 15 (lot 5, bloc 4/4, DERNIER) : cinq niveaux DE PLUS (N31 → N35).
## Balle 15 (2026-07-10) : la série passe de 30 à 35 niveaux — N35 devient le DERNIER (fin des
## 20 niveaux du lot 5, série complète à 35). Ce bloc est GLOBALEMENT au-dessus du bloc 3. Rythme
## GDD §2.3 « pic tous les 5 » : N31 = PIC ANNONCÉ (index 30 ajouté à NIVEAUX_PIC → bandeau
## « Niveau difficile » générique), N32 = relâche nette, N33 → N35 = remontée progressive (N35
## conclut la série). AUCUNE mécanique nouvelle (glyphes # . @ O X seuls) → SEUL ce fichier change
## (constantes + NIVEAUX + NIVEAUX_PIC + docstring) ; tout le socle absorbe les 5 niveaux →
## non-régression N1-N30. Courbe des coups minimaux (solveur BFS) : N31=69 (PIC, 3 boules, peigne
## LARGE 17×7 traversée max, loges groupées à droite / boules à gauche → nettement > N26=60) →
## N32=8 → N33=22 → N34=29 → N35=48. Chaque niveau au-dessus de son équivalent du bloc 3
## (N26=60, N27=7, N28=17, N29=20, N30=39). PREUVE de 0 cul-de-sac dur : (1) argument STRUCTUREL —
## tout coup est RÉVERSIBLE (un pousser s'annule par un tirer en sens opposé, un tirer par un
## pousser, une marche par une marche), donc le graphe des états atteignables est NON ORIENTÉ →
## tout niveau SOLUBLE a 0 cul-de-sac dur (vérifié empiriquement : réversibilité tenue sur 350 000+
## arêtes des petits niveaux) ; (2) EXHAUSTIF — co-atteignabilité des buts par BFS inverse : N32/N33/
## N34/N35 (analyse directe = 0 piège) et N31 (prouveur « lean » à états encodés en entier :
## 3 257 530 états atteignables, 0 cul-de-sac dur). tirer NÉCESSAIRE sur N31/N34/N35 (push-only
## prouvé insoluble). Notation séquences : H=Haut B=Bas G=Gauche D=Droite ; préfixe * = Agripper
## tenu (TIRER). Détails/preuves : section « Lot 5, bloc 4 » plus bas + RES balle 15.
## Pousse-Pollen — Balle 14 (lot 5, bloc 3/4) : cinq niveaux DE PLUS (N26 → N30).
## Balle 14 (2026-07-10) : la série passe de 25 à 30 niveaux — N30 devient le DERNIER (jusqu'au bloc 4,
## N31+). Ce bloc est GLOBALEMENT au-dessus du bloc 2. Rythme GDD §2.3 « pic tous les 5 » : N26 = PIC
## ANNONCÉ (index 25 ajouté à NIVEAUX_PIC → bandeau « Niveau difficile » générique), N27 = relâche nette,
## N28 → N30 = remontée vers le pic N31. AUCUNE mécanique nouvelle (glyphes # . @ O X seuls) → SEUL ce
## fichier change (constantes + NIVEAUX + NIVEAUX_PIC + docstring) ; tout le socle absorbe les 5 niveaux
## → non-régression N1-N25. Courbe des coups minimaux (solveur BFS) : N26=60 (PIC, 3 boules, peigne large
## loges groupées à droite / boules à gauche → traversée max, > N21=48) → N27=7 → N28=17 → N29=20 → N30=39.
## Chaque niveau PROUVÉ résoluble + 0 cul-de-sac dur (analyse EXHAUSTIVE des états atteignables ; N26 =
## 1 820 495 états, 0 piège) + tirer prouvé NÉCESSAIRE sur N26/N29/N30 (push-only insoluble) + rejeu moteur
## réel. Détails : section « Lot 5, bloc 3 » plus bas + RES balle 14.
## Balle 13 (lot 5, bloc 2/4) : cinq niveaux DE PLUS (N21 → N25).
## Balle 13 (2026-07-10) : la série passe de 20 à 25 niveaux — N25 devient le DERNIER (jusqu'au bloc 3,
## N26+). Ce bloc est GLOBALEMENT au-dessus du bloc 1. Rythme GDD §2.3 « pic tous les 5 » : N21 = PIC
## ANNONCÉ (index 20 ajouté à NIVEAUX_PIC → bandeau « Niveau difficile » générique), N22 = relâche nette,
## N23 → N25 = remontée vers le pic N26. AUCUNE mécanique nouvelle (glyphes # . @ O X seuls) → SEUL ce
## fichier change (constantes + NIVEAUX + NIVEAUX_PIC + docstring) ; tout le socle absorbe les 5 niveaux
## → non-régression N1-N20. Courbe des coups minimaux (solveur BFS) : N21=48 (PIC, 3 boules, > N16=41) →
## N22=5 → N23=13 → N24=19 → N25=30. Chaque niveau PROUVÉ résoluble + 0 cul-de-sac dur (analyse exhaustive
## des états atteignables) + rejeu moteur réel. Détails : section « Lot 5, bloc 2 » plus bas + RES balle 13.
## Balle 12 (lot 5, bloc 1/4) : cinq niveaux DE PLUS (N16 → N20).
## Balle 12 (2026-07-10) : la série passe de 15 à 20 niveaux — N20 devient le DERNIER (jusqu'au bloc 2,
## N21+). Rythme GDD §2.3 (« pic tous les 5 ») : N16 = PIC ANNONCÉ (index 15 ajouté à NIVEAUX_PIC →
## bandeau « Niveau difficile » générique), N17 = relâche, N18 → N20 = remontée vers le pic N21.
## AUCUNE mécanique nouvelle (glyphes # . @ O X seuls, pas de '+') → SEUL ce fichier change (constantes
## + NIVEAUX + NIVEAUX_PIC + docstring) ; tout le socle (enchaînement, caméra, victoire, tirer,
## contournement, annonce pic) absorbe les 5 niveaux → non-régression N1-N15. Courbe des coups minimaux
## (solveur BFS) : N16=41 (PIC, 3 boules, nettement > N15=25) → N17=6 → N18=10 → N19=15 → N20=25
## (boucle). Chaque niveau PROUVÉ résoluble + 0 cul-de-sac dur (analyse exhaustive) + rejeu moteur réel.
## Détails (grilles + séquences + preuves) : voir la section « Lot 5, bloc 1 » plus bas + le RES balle 12.
## Balle 11 (lot 4) : cinq niveaux « PARENTS » (N11 → N15) + annonce « pic ».
## Balle 11 (2026-07-10) : la série passe de 10 à 15 niveaux — N15 devient le DERNIER. Au-delà du
## N10 (pour l'enfant), la difficulté monte pour accrocher le PARENT (GDD §2.3 « Public & intention »).
## Rythme (GDD §2.3 « Rythme de difficulté au-delà du N10 ») : un PIC de difficulté ANNONCÉ revient
## tous les 5 niveaux — le N11 est le premier pic (le prochain sera le N16). Après le pic, on RELÂCHE
## (N12), puis on REMONTE progressivement (N13 → N15) vers le pic suivant. Aucune mécanique nouvelle
## (l'annonce est de l'UI) — pousser/tirer/contournement/plusieurs boules/tunnels seulement.
##   N11 — PIC : galerie en BOUCLE (GDD §2.3). Loge dans un ANGLE, boule sur l'anneau ; pousser
##         l'éloigne, tirer ne suffit pas → il faut faire TOUT LE TOUR de la boucle pour se placer
##         derrière la boule et la pousser sur la loge du coin. Le plus dur du lot.        28 coups
##   N12 — RELÂCHE nette : un petit « L », une boule (pousser puis descendre). Respiration.  5 coups
##   N13 — remontée 1 : deux boules, mur central, REPOSITIONNEMENT (faire le tour, pousser). 12 coups
##   N14 — remontée 2 : pousser + TIRER indispensable (boule collée au coin haut-gauche).   15 coups
##   N15 — remontée 3 (haut du lot, sous le pic N16) : tirer + contournement DOUBLE.        25 coups
## Annonce « Niveau difficile » (nouveau, GÉNÉRIQUE) : le tableau NIVEAUX_PIC liste les index « pic »
## (ici : le seul N11 = index 10 ; le prochain, N16 = index 15, s'annoncera pareil sans code en plus).
## À l'entrée d'un niveau pic, un bandeau calme « Niveau difficile » (luminance + libellé, jamais la
## couleur seule ; ton non anxiogène) s'affiche, puis s'efface tout seul après un court instant OU au
## premier geste de l'enfant. Aucune mécanique de jeu ajoutée : c'est de l'UI (comme le « Bravo ! »).
## Chaque niveau N11-N15 est PROUVÉ résoluble par simulation exhaustive (solveur BFS répliquant la
## sémantique de ce fichier) : séquence gagnante minimale + preuve de résolubilité, et surtout
## analyse EXHAUSTIVE de tous les états atteignables = 0 cul-de-sac dur (depuis n'importe quel état,
## une victoire reste atteignable ; « Recommencer » reste le filet ultime, GDD §1 aucun échec).
## Détails (grilles + solutions + preuves) dans le RES balle 11.
## Balle 10 (lot 3) : cinq niveaux DE PLUS (N6 → N10), conception déléguée à Code.
## Balle 10 (2026-07-10) : la série passe de 5 à 10 niveaux — N10 devient le DERNIER. Aucune
## mécanique nouvelle : ces niveaux ne font que RÉUTILISER le socle acquis (pousser + tirer + manœuvre
## de contournement + plusieurs boules/loges + tunnels), donc N1-N9 restent intacts (non-régression).
## Difficulté progressive et TOUJOURS résoluble par un enfant (jamais un casse-tête d'expert) :
##   N6  — deux boules, POUSSER seul, petit coude de galerie (ré-entrée douce après N5).      6 coups
##   N7  — croix ouverte, deux boules, POUSSER + REPOSITIONNEMENT (se placer derrière/au-dessus). 11
##   N8  — anneau « galerie principale + galeries latérales » (GDD §2.3), navigation, pousser.  15
##   N9  — deux boules, une SE POUSSE et l'autre SE TIRE (collée au mur → le tirer est requis).  14
##   N10 — SYNTHÈSE et capstone : deux tiges, chacune une boule tirée puis contournée (croix du   22
##         Christ « doublée » : tirer + contournement × 2, dans l'esprit du N5).
## Chaque niveau est PROUVÉ résoluble par simulation exhaustive (BFS répliquant la sémantique de ce
## fichier) : séquence gagnante fournie dans le RES balle 10, et surtout AUCUN cul-de-sac — l'analyse
## de TOUS les états atteignables montre 0 état-piège (depuis n'importe quel état, y compris après un
## faux mouvement, une victoire reste atteignable sans même « Recommencer »). Le « Recommencer » doux
## reste le filet ultime (GDD §1 aucun échec). Les guides tutoriels restent restreints (N1 = pousser,
## N4 = tirer) : N6-N10 s'adressent à l'enfant qui a déjà appris les gestes.
## Balle 9 (lot 2, dernière du lot 2) : Niveau 5, la « croix du Christ » avec CONTOURNEMENT.
## Balle 9 (2026-07-10) : N5 = index 4, DERNIER niveau → pas de « Niveau suivant » à sa victoire ;
## N4 (index 3) en gagne un, qui charge N5. N5 est la SYNTHÈSE des acquis (pousser + tirer +
## manœuvre) — aucun nouveau geste, aucun tutoriel obligatoire (GDD §2.3, brief balle 9). Plan en
## CROIX LATINE « debout » ; la boule démarre en HAUT de la tige, MUR juste au-dessus → la pousser
## tout droit est IMPOSSIBLE : il faut d'abord la TIRER vers le bas (acquis N4), puis CONTOURNER par
## des cases DÉCAISSÉES à droite (2 cases) pour se replacer AU-DESSUS de la boule et la POUSSER sur
## la croix. Aucun cul-de-sac dur : toute boule coincée contre un mur se récupère au tirer, et
## « Recommencer » reste disponible (valeurs §1). Rendu, caméra et enchaînement réutilisent le socle
## existant : N5 n'ajoute qu'une grille à NIVEAUX (aucune mécanique nouvelle → non-régression N1-N4).
## Balle 8 (lot 2) : Niveau 4, tutoriel du TIRER (croix latine « debout »).
## Balle 8 (2026-07-10) : N4 = index 3, ajouté à NIVEAUX. Nouveautés :
##  (a) LOGE SOUS L'AVATAR — la grille accepte le glyphe '+' (avatar posé sur une croix) : le
##      terrain garde la loge 'X', l'avatar démarre dessus. La croix est CACHÉE tant que l'avatar
##      est dessus, RÉVÉLÉE dès qu'il se déplace — implémenté au rendu (_dessiner_sol ne peint pas
##      la croix de la case occupée par l'avatar), donc dynamique et sans état à maintenir.
##  (b) GUIDE DU TIRER (spécifique N4) — pendant du guide N1 mais pour le tirer : quand l'avatar
##      est directement SOUS une boule (opportunité de tirer vers le bas), l'Agripper ET la flèche
##      bas PULSENT (luminance, jamais la couleur seule). L'indice s'efface une fois la boule tirée
##      (l'avatar n'est plus sous une boule) ou à la victoire. Gardé après un 1ᵉʳ déplacement
##      (_deja_deplace) → pas affiché au tout départ (l'avatar y démarre déjà sous la boule du haut) :
##      il apparaît quand l'enfant REVIENT sous la boule du haut (déroulé GDD §2.3, étape 3). Le
##      guide N1 (flèche gauche « pousser ») reste, lui, restreint au N1.
## Balle 7 (multi-niveaux + N2 + N3 + enchaînement « rejouer ou monter »).
## Balle 7 (2026-07-09, lot 2) : le niveau n'est plus codé en dur. `NIVEAUX` est une LISTE
## ORDONNÉE de grilles (N1 = index 0, N2 = 1, N3 = 2) ; `_niveau_courant` pointe le niveau
## chargé ; `_charger_niveau()` lit `NIVEAUX[_niveau_courant]`. À la victoire, en plus de
## « Recommencer » (rejouer le même), un bouton « Niveau suivant » charge l'index+1 — RIEN ne
## force la montée (GDD §2.3 « Liberté »), et au dernier niveau chargé il n'apparaît pas. Le
## guide tutoriel « flèche gauche qui pulse » reste SPÉCIFIQUE au N1 (apprentissage du pousser).
## La caméra se recadre à CHAQUE niveau (N2/N3 = 7×5, plus grands que N1 = 5×3) : le zoom est
## calculé pour faire tenir le tableau à l'écran, plafonné au 1.4 d'origine pour ne pas
## sur-zoomer le petit N1. N2/N3 = « pousser » seul (2 puis 3 côtés) — pas de tirer (N4+).
## Balle 6 (Agripper en MAINTIEN multitouch ; pousser/tirer/victoire acquis).
## Grille logique + déplacement case par case (clavier ui_* ET quatre flèches à
## l'écran, unifiés). L'avatar POUSSE la boule de pollen (O) si la case juste
## derrière la boule est libre ; sinon rien ne bouge (neutre, aucun échec —
## valeurs CoccOs). Une seule boule à la fois (pas de poussée en chaîne).
## Réussite quand TOUTES les boules reposent sur une loge (croix) : message
## joyeux « Bravo ! » via un CanvasLayer, sans game over ni chrono. Spec : GDD.md
## §1 (aucun échec) + §2.3 (mécanique pousser, tableau Niveau 1) + §7 (socle).
## Agripper (tirer) : collé à une boule, la flèche OPPOSÉE la fait suivre d'une case si le
## recul est libre. Le pousser reste LIBRE (sans Agripper), inchangé.
## Balle 6 (correction balle 4 — tranché Fabrice 09-07) : l'Agripper est un MAINTIEN, pas
## une bascule. « Agripper » = TENIR le bouton (je tiens = je tire ; je lâche = je pousse en
## avançant) → l'ambiguïté pousser/tirer est levée sans 2ᵉ bouton. Tactile Android : le
## bouton Agripper ET les 4 flèches sont des `TouchScreenButton` (multitouch natif Godot,
## class_touchscreenbutton.rst l.22) → on tient l'Agripper d'un doigt et on actionne une
## flèche de l'autre, simultanément. Clavier PC : barre espace maintenue (inchangé).
## Balle 5 (clôt le squelette) : (1) « Recommencer » doux — un bouton écran réinitialise
## le niveau courant (avatar, boules, victoire) SANS « perdu » ni confirmation, y compris
## APRÈS la victoire (GDD §1 aucun échec + §2.3 recommencer doux). (2) Flèches-guides
## tutoriel N1 — la flèche GAUCHE (celle qui résout le tuto) pulse doucement au chargement
## et s'efface au PREMIER geste de l'enfant (indice non intrusif, effaçable — GDD §1 calme).
## (3) Finition légère : le « Bravo ! » apparaît en fondu doux (discret, sans son).

const CELL := 128  # grosses cases (grandes cibles souris/tactile pour jeune enfant, GDD §2.3)

# Niveau 1 (GDD §2.3 — tutoriel « pousser », 1 boule / 1 loge).
# Notation ASCII (équivalents du GDD, gardés hors multi-octets dans le code) :
#   '#' terre/mur (·GDD #) · '.' sol vide (·GDD ·) · '@' avatar (·GDD @)
#   'O' boule de pollen (·GDD ●) · 'X' loge / croix rouge (·GDD ✕)
#   '+' avatar POSÉ sur une loge (N4) : le terrain garde la croix 'X', l'avatar démarre dessus.
#   ':' sol TEINTÉ (balle 27) : praticable comme '.', peint en vert clair → dessine des détails FINS traversables.
const NIVEAU_1 := [
	"#####",
	"#XO@#",
	"#####",
]

# Niveau 2 (GDD §2.3 — « T majuscule », 2 boules / 2 loges, pousser 2 côtés). L'avatar monte
# de la tige jusqu'au croisement puis pousse à gauche (1ʳᵉ boule sur sa loge) et à droite (2ᵉ).
# Grille GDD (`# ✕ ● · ● ✕ #` / `# # # · # # #` / `# # # @ # # #`) transcrite en notation code.
const NIVEAU_2 := [
	"#######",
	"#XO.OX#",
	"###.###",
	"###@###",
	"#######",
]

# Niveau 3 (GDD §2.3 — « T à 3 branches », 3 boules / 3 loges, pousser 3 côtés). Avatar au
# centre ; pousser à gauche, à droite, puis vers le bas → les trois loges se remplissent.
# Grille GDD (`# ✕ ● @ ● ✕ #` / `# # # ● # # #` / `# # # ✕ # # #`) transcrite en notation code.
const NIVEAU_3 := [
	"#######",
	"#XO@OX#",
	"###O###",
	"###X###",
	"#######",
]

# Niveau 4 (GDD §2.3 — « croix latine debout », tutoriel du TIRER, avec découverte). L'avatar
# démarre POSÉ sur la croix centrale (glyphe '+' = avatar sur une loge) : elle est cachée tant
# qu'il est dessus. À gauche/droite une boule + une croix (pousser, acquis) ; au-dessus une boule
# dont la croix est la centrale (à remplir en TIRANT vers le bas). La case de tige sous le centre
# ('·') laisse la place de reculer en tirant. Grille GDD transcrite (`● ✕ @-sur-✕ ·` → `O X + .`).
const NIVEAU_4 := [
	"#######",
	"###O###",
	"#XO+OX#",
	"###.###",
	"#######",
]

# Niveau 5 (GDD §2.3 — « croix du Christ » avec CONTOURNEMENT, SYNTHÈSE : pousser + tirer + manœuvre).
# Croix latine « debout ». La boule (O) démarre en HAUT de la tige, MUR juste au-dessus et murs à
# gauche/droite → elle ne peut d'abord que DESCENDRE, et sans case au-dessus on ne peut PAS la pousser :
# il faut la TIRER (acquis N4). Une fois descendue, la croix (X, bas de tige) se remplit en POUSSANT
# vers le bas → l'avatar doit repasser AU-DESSUS de la boule, impossible tout droit (la boule bouche la
# tige) : il CONTOURNE par les 2 cases DÉCAISSÉES à droite (colonne 3, lignes 3-4), remonte, revient
# au-dessus, puis pousse. Solution prouvée (8 coups) dans le RES balle 9. `+` non requis ici : l'avatar
# démarre à CÔTÉ (croisement gauche), pas sur la croix.
const NIVEAU_5 := [
	"#####",
	"##O##",
	"#@..#",
	"##..#",
	"##X.#",
	"#####",
]

# --- Lot 3 (balle 10) : cinq niveaux de plus, conçus par Code et prouvés résolubles par simulation. ---
# Difficulté croissante, mécaniques existantes seulement (pousser · tirer · contournement · plusieurs
# boules/loges · tunnels). Chaque grille est équilibrée (autant de boules que de loges) et sans piège.

# ============================================================================
# BALLE 40 (2026-07-12) — TUTO N6-N10 ÉVOLUTIF : introduction PROGRESSIVE de l'APPARIEMENT PAR SYMBOLE.
# ============================================================================
# Trou pédagogique corrigé (brief REQ_260712_1530) : jusqu'ici N1-N10 n'enseignaient QUE la mécanique
# (sans étiquette) et N11 assénait l'appariement d'un coup, piégé, chiffres ET lettres mêlés. On superpose
# désormais, façon musicale (UNE nouveauté par niveau), l'appariement par symbole sur la 2ᵉ moitié du tuto —
# EN CONSERVANT la valeur mécanique de chaque créneau (le symbole s'AJOUTE, il ne remplace pas la leçon) :
#   • N6  = CHIFFRES seuls, AUCUN piège (mécanique = pousser, acquise) — apparier « 1 »→« 1 ».
#   • N7  = CHIFFRES, piège LÉGER (la loge la plus proche de 'a' porte un AUTRE chiffre) — LIRE avant de pousser.
#   • N8  = LETTRES, TUNNEL SPIRALE (escargot/colimaçon, balle 42) : avatar au centre, dérouler la spirale pour
#           venir derrière l'unique boule 'a' et la pousser d'1 case sur la croix 'A' voisine. Facile, sans piège.
#   • N9  = « ÉCRIS TON PRÉNOM » (tableau-mot, REFAIT balle 44 — voir en-tête et le bloc NIVEAU_9) : champ OUVERT,
#           croix EN HAUT = prénom DANS L'ORDRE, boules aux mêmes lettres EN DÉSORDRE → apparier chaque boule à sa croix.
#   • N10 = CROIX COLLÉES douces (pré-goût du genre 3) : loges A/B collées en colonne, B mure l'accès à A
#           → enfiler A (le fond) AVANT B (la bouche) ; l'ORDRE compte, mais court et réversible (tuto).
# N1-N5 restent l'ÉCHELLE MÉCANIQUE PURE, INCHANGÉS, sans symbole (appariement par POSITION, victoire d'origine).
# Affichage des étiquettes : automatique dès qu'une grille porte des glyphes a/A… (N6-N10 typés) ; N1-N5 gardent
# O/X → aucune étiquette. Le POOL de symboles par niveau (chiffres / lettres / mix) est piloté par TUTO_SYMBOLES
# + _generer_etiquettes(mode) → N11-N35 gardent le régime « mix » d'origine (INCHANGÉS). Preuve (rendus/b40/
# verifier_b40.py, réplique EXACTE du moteur) : les 5 SOLUBLES, coups BAS (opt 9/12/11/11/11), 0 cul-de-sac dur
# (réversibilité universelle), N7 & N10 piège/ordre 1/2. (N9 refait balle 44 → tableau-mot, voir en-tête.)
# Périmètre STRICT : SEULES les grilles N6-N10 + le câblage TUTO_SYMBOLES/_generer_etiquettes changent —
# N11-N35, mécaniques, caméra b33, débounce b35, nav ◄/►, victoire b36, NIVEAUX_PIC, sauvegarde : INCHANGÉS.

# Niveau 6 (CHIFFRES seuls, AUCUN piège — 1er contact avec l'appariement). Mécanique = pousser (acquise N1-N3).
# Chaque boule s'aligne sur SA loge (la plus proche = la bonne) : la SEULE nouveauté = lire le chiffre et
# apparier « 1 »→« 1 ». Push-only jouable ; opt 9 coups (prouvé rendus/b40/verifier_b40.py). a↔A, b↔B.
const NIVEAU_6 := [
	"#######",
	"#.a.A.#",
	"#..@..#",
	"#.b.B.#",
	"#######",
]

# Niveau 7 (CHIFFRES, piège LÉGER — apprendre à LIRE avant de pousser). La loge la plus proche de la boule
# 'a' est celle de l'AUTRE chiffre (B, collée à droite) : la pousser d'un cran l'y dépose SANS gagner (victoire
# typée) → l'enfant relit le chiffre et pousse encore vers SA loge (A). Piège 1/2 (léger). Push-only jouable ;
# opt 12 coups (prouvé). Reste FACILE : un seul cran d'écart, pas de croisement dur (≠ piège de N11).
const NIVEAU_7 := [
	"#######",
	"#.aBA.#",
	"#.....#",
	"#.b...#",
	"#..@..#",
	"#######",
]

# Niveau 8 (LETTRES — nouveau type de symbole) REFAIT en TUNNEL SPIRALE (balle 42, retour de test Fabrice : les
# petites chambres rectangulaires N7/N8 se ressemblaient → rébarbatif). Le tunnel s'enroule d'UNE case de large
# autour d'un mur central, comme une coquille d'escargot / colimaçon. L'avatar DÉMARRE AU CENTRE (3,3) = le cœur.
# UNE seule boule 'a' + UNE seule croix 'A' collée à sa gauche, au BOUT EXTERNE de la spirale. Le défi = DÉROULER
# tout le colimaçon depuis le centre jusqu'en (3,5) [derrière la boule, côté opposé à la croix], puis pousser d'UNE
# case → 'a' sur 'A'. La difficulté n'est PAS la poussée (croix collée) mais le TOUR de spirale pour atteindre le
# bon côté. Pédagogie LETTRES conservée (TUTO_SYMBOLES[7]="lettres" → 'a'/'A' affichent une lettre). FACILE, spirale
# COURTE. Parité 7×7 : n=7/11 finissent au centre EXACT (n=9 décalé) → 7×7 = plus courte taille centrée.
# BALLE 45 (retour Fabrice) : spirale RÉORIENTÉE — l'OUVERTURE externe (croix A + boule a) était en HAUT ; elle est
# maintenant en BAS pour DONNER VERS LA TÊTE de l'escargot (décor). Réorientation = miroir haut-bas de la grille
# (reverse des lignes) → jouabilité ISOMORPHE (mêmes opt/spirale/culs, revérifiée). Preuve b45
# (rendus/b45/prouver_b45.py, réplique moteur) : soluble · opt 15 coups (14 marche + 1 poussée) · corridor = CHEMIN
# SIMPLE 17 cases (2 extrémités, 0 carrefour → aucun raccourci) · 0 cul-de-sac dur (réversibilité) · CUT TEST
# spirale 15 vs salle ouverte 3 (×5 → la spirale est NÉCESSAIRE au détour) · isomorphe à b42 (opt 15=15).
# Seul N8 change (N1-N7, N9-N35 intacts).
const NIVEAU_8 := [
	"#######",
	"#.....#",
	"#.###.#",
	"#..@#.#",
	"#####.#",
	"#Aa...#",
	"#######",
]

# Prénom par DÉFAUT du tableau-mot N9 (balle 44). Constante PROPRE : le futur « prénom lié au compte de l'enfant /
# pseudo choisi par le parent » est un chantier DISTINCT (non fait ici) — il régénérera la grille NIVEAU_9 depuis
# cette valeur. Aujourd'hui, la grille NIVEAU_9 ci-dessous RÉALISE ce mot (croix en haut = MAJUSCULES dans l'ordre,
# boules dessous = minuscules en désordre). Changer le prénom = redessiner NIVEAU_9 en cohérence avec cette constante.
const PRENOM_DEFAUT := "ISABELLA"

# Niveau 9 (balle 44, RESSERRÉ balle 70b) — « ÉCRIS TON PRÉNOM » (tableau-mot). CHAMP OUVERT (aucun mur intérieur,
# juste le cadre). Rangée de croix EN HAUT = PRENOM_DEFAUT « ISABELLA » DANS L'ORDRE et COLLÉES (croix adjacentes :
# largeur croix = nb de lettres → largeur TOTALE minimale → zoom bien plus grand, boules/avatar plus gros et lisibles).
# Dessous, les 8 boules portent les MÊMES lettres EN DÉSORDRE, en 2 rangées décalées (colonnes PAIRES) séparées par une
# rangée libre → aucune boule empilée sur une autre. Les rangées libres 2/4/6 + les colonnes IMPAIRES libres forment une
# « autoroute » de tri : chaque boule se monte dans la rangée 2 (sous les croix), se route horizontalement jusqu'à SA
# colonne, puis se pousse vers le haut dans SA croix. En les remettant en ordre, l'enfant écrit son prénom. Doublons
# (2×A, 2×L) INTERCHANGEABLES : la victoire typée compare les étiquettes AFFICHÉES → n'importe quelle croix de la bonne
# lettre convient (plusieurs solutions valides). Mécanisme « mot imposé » : TUTO_SYMBOLES[8]="impose" → chaque clé
# s'affiche telle quelle (la LETTRE, pas un tirage aléatoire) ; encodage grille letter-based (min = boule, MAJ = loge,
# appariées par la lettre). AUCUNE boule ne démarre sous SA colonne (désordre RÉEL, 0 trivial). Champ ouvert +
# réversibilité poussée↔tirage → soluble & 0 cul-de-sac.
# Preuve (rendus_b70/pp_b70.py, réplique moteur pp_b41 ; méthode BORNÉE — PAS de BFS exact sur 8 boules, qui saturerait
# la RAM) : SOLUBLE (séquence constructive de 99 coups REJOUÉE dans le moteur → victoire typée) · opt ∈ [46, 99]
# (minorant = couplage des distances-poussée) · 8/8 pièges (loge la + proche = MAUVAISE lettre) · 0 boule triviale ·
# 0 cul-de-sac (réversibilité universelle pousser↔tirer + spot-check borné 200 000 états, 0 arête non-réversible).
const NIVEAU_9 := [
	"##########",
	"#ISABELLA#",
	"#........#",
	"#.l.a.s.i#",
	"#........#",
	"#.b.e.a.l#",
	"#....@...#",
	"##########",
]

# Niveau 10 (CROIX COLLÉES douces — pré-goût du genre 3, version tuto, capstone du tuto). Deux loges A et B
# COLLÉES en colonne (A au fond, B à la bouche) ; un mur jouxte B → l'accès à A ne se fait QU'À TRAVERS la case
# de B. Il faut donc ENFILER la boule de A AVANT celle de B (sinon B bouche le passage) : l'ORDRE compte —
# version DOUCE et réversible (≠ les 85 coups de N29). Piège/ordre 1/2 ; push-only ; opt 11 coups (prouvé). a↔A, b↔B.
const NIVEAU_10 := [
	"#######",
	"#.A...#",
	"#.B#..#",
	"#.b.a.#",
	"#..@..#",
	"#######",
]

# ============================================================================
# BALLE 22 (2026-07-10) — RECALIBRAGE de la DIFFICULTÉ : appariement VRAIMENT exploité
# ============================================================================
# Les 25 niveaux N11->N35 sont REDESSINÉS (N1-N10 = découverte, INCHANGÉS). N1-N10 gardent
# la victoire d'origine (aucune étiquette) ; dès N11 l'appariement est PIÉGÉ :
#   • AUCUNE boule triviale : chaque boule démarre à >=2 poussées de SA loge (jamais « une
#     poussée et fini » — le défaut constaté au test de Fabrice) ;
#   • PIÈGE : pour chaque boule (ou presque) la loge la PLUS PROCHE est celle d'une AUTRE
#     étiquette -> il faut RECONNAÎTRE le bon symbole et TRANSPORTER la bonne boule ailleurs ;
#   • CROISEMENTS : les trajets boule->SA loge se croisent -> l'ordre des coups compte.
# Boules : >= 3 PARTOUT (jamais 1-2 au-delà de N10) ; PICS 4-6 (N11=4, N16=4, N21=5, N26=5, N31=6).
# Courbe à PLANCHER MONTANT (planchers/relâches N12<N17<N22<N27<N32 = 16<18<20<21<24 ;
# pics N11<N16<N21<N26<N31, minorant prouvé 20<24<36<41<48). Dans chaque bloc : relâche<r1<r2<r3<pic.
# PREUVE (RES balle 22) : « opt » = coups de la solution OPTIMALE par BFS bidirectionnel (réplique
# exacte de _tenter_deplacement / _verifier_victoire typée) pour les niveaux tractables ; pour les
# pics 5-6 boules (états > RAM 7 Go) = MINORANT prouvé (heuristique admissible) + SÉQUENCE gagnante
# VÉRIFIÉE (rejeu moteur). 0 cul-de-sac dur GARANTI par la RÉVERSIBILITÉ UNIVERSELLE (poussée<->tirage :
# tout coup a son inverse -> graphe non orienté -> tout état atteignable ré-atteint le but ; prouvé sur
# 32420 arêtes aléatoires, 0 contre-exemple). Encodage grille, mécaniques (pousser/tirer/agripper),
# caméra (b20/b23), sélecteur (b16), appariement chiffres/lettres (b21) : INCHANGÉS — seules les
# 25 grilles N11-N35 changent. Étiquettes A-F (jusqu'à 6 boules) -> chiffres 1-6 sur blocs CHIFFRES.

# ============================================================================
# BALLE 24 (2026-07-11) — PILOTE « FORMES » : N11-N14 dessinés comme des FIGURES.
# Le CONTOUR de la forme (source : DEV_CoccOs_Minijeux/FORMES_niveaux.md) dessine le tunnel ;
# la difficulté vient de la MANŒUVRE DANS LA FORME (contourner, croiser, traverser), PAS d'un
# nombre de coups visé. Code place boules/loges À L'INTÉRIEUR + garantit : soluble · 0 cul-de-sac
# dur (réversibilité universelle poussée↔tirage → graphe non orienté) · appariement piégé
# (boule jamais devant SA loge ; loge la plus proche = AUTRE étiquette ; croisements). Étiquettes
# TIRÉES AU HASARD au chargement (chiffres ET lettres mêlés — voir _generer_etiquettes) : les glyphes
# a/A, b/B… restent la CLÉ d'appariement dans la grille ; le SYMBOLE affiché est tiré à part.
# N15-N34 = laissés tels quels pour ce pilote (refonte en formes après validation). N1-N10 inchangés.
# Preuve (solveur /tmp/pp_b24 réplique exacte du moteur) : bibfs optimal + rejeu moteur + composante
# symétrique (0 cul-de-sac) + analyse appariement. Rendus lus X:0 → chaque forme RECONNAISSABLE.

# N11 — PAPILLON v2 (pic annoncé). CONTOUR REDESSINÉ par Cowork (FORMES_niveaux.md §Papillon v2) : la v1
# (b24) rendait un quasi-rectangle. Rappel b24 : les murs '#' sont peints couleur du fond → c'est la masse
# CLAIRE (tunnel) qui dessine la silhouette. Le contour v2 lit « papillon » : antennes (row0), 2 grandes ailes
# hautes, taille PINCÉE (row5-7, entaille latérale), 2 ailes basses, corps central continu ; ailes reliées au
# corps (rows 3-4, 6, 8) → jouable. Grille AGRANDIE 13×11 (leçon b24 : forme complexe = grille plus grande).
# Boules dans les ailes HAUTES (a=aile gauche, b=aile droite), loges dans les ailes BASSES CROISÉES
# (A=aile basse DROITE, B=aile basse GAUCHE) → chaque boule doit TRAVERSER en diagonale vers l'aile opposée.
# opt = 54 coups (BFS exact, 421 784 états) · 2 boules · 2/2 pièges (loge la plus proche = MAUVAISE clé pour
# les deux) · 1 croisement (trajets a↘ et b↙ se croisent) · 0 boule triviale (dist propre = 14 chacune) ·
# 0 cul-de-sac (réversibilité poussée↔tirage : 0 transition non-réversible sur 400 001 vérifiées).
const NIVEAU_11 := [
	"####.###.####",
	"#####...#####",
	"#a.#.....#.b#",
	"#...........#",
	"#.....@.....#",
	"##..#...#..##",
	"####.....####",
	"##..#...#..##",
	"#..B.....A..#",
	"##...#.#...##",
	"###..#.#..###",
]
# N12 — MAISON. Toit pointu + porte en bas. opt = 16 coups · 2 boules · 2/2 pièges ·
# 1 croisement (a monte vers le pignon, b descend vers la porte) · 0 boule triviale ·
# 0 cul-de-sac (réversibilité, composante symétrique 110 542 états).
const NIVEAU_12 := [
	"#####.#####",
	"####...####",
	"###..A..###",
	"##.......##",
	"#.....b...#",
	"#....@....#",
	"#...a.....#",
	"####...####",
	"####.B.####",
]
# N13 — FUSÉE. Nez pointu, corps, ailerons + tuyères en bas. opt = 27 coups · 2 boules ·
# 2/2 pièges (chaque boule a SA loge à l'opposé, en diagonale) · 1 croisement · 0 boule triviale ·
# 0 cul-de-sac (réversibilité, composante symétrique 83 240 états).
const NIVEAU_13 := [
	"####.####",
	"###...###",
	"##.a.b.##",
	"##.....##",
	"##.....##",
	"##.....##",
	"##..@..##",
	"##.B.A.##",
	"#.......#",
	"#..#.#..#",
	"###.#.###",
]
# N14 — TOURNESOL EN POT. Fleur (haut), tige en zigzag, pot (bas). opt = 31 coups · 2 boules ·
# 1/2 pièges — SIGNALÉ : la forme place une loge au CŒUR de la fleur, juste à côté des boules, donc
# une seule boule (celle du pot) peut avoir sa loge la plus proche = mauvaise ; l'autre boule est à
# 2 cases de sa loge (fleur), non triviale. La difficulté vient de la TRAVERSÉE de la tige : la
# boule 'a' descend TOUTE la tige en zigzag (dist 10) jusqu'au pot. 0 boule triviale (<=1) ·
# 0 cul-de-sac (réversibilité, composante symétrique 70 200 états).
const NIVEAU_14 := [
	"##.....##",
	"#..a.b..#",
	"#...B...#",
	"##.....##",
	"####.####",
	"##...####",
	"####...##",
	"####.####",
	"##.....##",
	"##.@.A.##",
	"###...###",
]
# N15 — CŒUR (forme franche, balle 29 ; contour Cowork FORMES_niveaux.md §Lot 2). La masse CLAIRE (tunnel)
# dessine la silhouette (murs '#' = couleur du fond → invisibles) : 2 lobes hauts séparés par l'entaille
# centrale (row0-1), corps large (rows 2-3), pointe basse (rows 5-7). 2 boules dans les lobes hauts (a=gauche,
# b=droite), 2 loges dans le corps bas CROISÉES (A=bas-droite, B=bas-gauche) → chaque boule TRAVERSE en
# diagonale vers le lobe opposé. Difficulté par la FORME (traversée + croisement), pas par le nombre de coups.
# Preuve (solveur /tmp/pp_b29, réplique EXACTE du moteur) : opt = 29 coups (BFS exact, 91 078 états) · 2 boules ·
# 2/2 pièges (loge la plus proche = MAUVAISE clé pour chaque boule) · 0 boule triviale (dist propre = 9 chacune) ·
# 0 cul-de-sac (réversibilité poussée↔tirage : 0 transition non-réversible sur 295 152 vérifiées).
const NIVEAU_15 := [
	"##..###..##",
	"#.a..#..b.#",
	"#.........#",
	"#....@....#",
	"##B.....A##",
	"###.....###",
	"####...####",
	"#####.#####",
]
# N16 (pic — « PAPA », balle 46, RESSERRÉ balle 70b) : les 4 croix épellent PAPA (gauche→droite) → le parent lit
# le mot. Croix COLLÉES (adjacentes : largeur croix = 4 lettres → largeur TOTALE minimale → zoom plus grand).
# Mécanisme « mot imposé » (comme N9) : TUTO_SYMBOLES[15]="impose" → chaque clé s'affiche TELLE QUELLE (P, A) ;
# encodage grille letter-based (min = boule, MAJ = loge). DOUBLONS 2×P / 2×A INTERCHANGEABLES (la victoire typée
# compare les étiquettes AFFICHÉES → toute loge de la bonne lettre convient, plusieurs solutions). Les 4 boules
# p/a/a/p sont en 2 rangées (pas alignées, pas aux extrémités hautes) ; aucune boule sous SA colonne (0 trivial).
# Preuve (rendus_b70/pp_b70.py, réplique EXACTE du moteur pp_b41) : opt TYPÉ EXACT = 26 coups (BFS BORNÉ — cap
# 2 000 000 d'états, 1,69 M explorés, aucune saturation RAM) · 4/4 pièges STRICTS (loge la + proche = AUTRE
# lettre) · 0 boule triviale · 0 cul-de-sac EMPIRIQUE (1,86 M états atteignables, 0 arête non-réversible, 0
# cul-de-sac dur). Mot imposé (documentaire, parallèle à PRENOM_DEFAUT/N9) : la grille NIVEAU_16 RÉALISE ce mot
# (croix P-A-P-A dans l'ordre). Le changer = redessiner NIVEAU_16 en cohérence.
const MOT_N16 := "PAPA"
const NIVEAU_16 := [
	"######",
	"#PAPA#",
	"#....#",
	"#.pa.#",
	"#a..p#",
	"#.@..#",
	"######",
]
# N17 — CHAMPIGNON (forme franche, balle 29 ; contour Cowork FORMES_niveaux.md §Lot 2). La masse CLAIRE
# dessine la silhouette : chapeau large et arrondi (rows 0-4) + pied ÉTROIT (rows 5-8, 3 cases de large).
# Détail décoratif : 3 pastilles de sol teinté ':' sur le chapeau (row1) — praticables comme '.', montrent la
# NOUVELLE teinte ocre chaude en contexte (balle 29) sans altérer la solubilité. Boule 'a' (chapeau gauche) doit
# DESCENDRE tout le pied étroit jusqu'à SA loge A (bas du pied) ; boule 'b' TRAVERSE le chapeau vers B (haut-
# droite). Difficulté par la FORME (enfilage du pied étroit + croisement), pas par le nombre de coups.
# Preuve (solveur /tmp/pp_b29, réplique EXACTE du moteur) : opt = 28 coups (BFS exact, 110 544 états) · 2 boules ·
# 2/2 pièges (loge la plus proche = MAUVAISE clé) · 0 boule triviale (dist propre 9 et 8) ·
# 0 cul-de-sac (réversibilité poussée↔tirage : 0 transition non-réversible sur 368 736 vérifiées).
const NIVEAU_17 := [
	"###.....###",
	"##.:.:.:.##",
	"#.a.....B.#",
	"#....@....#",
	"##b......##",
	"####...####",
	"####...####",
	"####...####",
	"####.A.####",
]
# N18 — BUS (forme franche, balle 31 ; contour Cowork FORMES_niveaux.md §Lot 3). La masse CLAIRE (tunnel) dessine
# la silhouette (murs '#' = couleur du fond → invisibles) : corps allongé (rows 0-3), rangée de FENÊTRES en sol
# teinté ':' (row1, ocre praticable = visible sans bloquer), deux ROUES = les 2 blocs du bas (rows 4-5, cols 2-3 et
# 9-10). 2 boules + 2 loges dans le corps, CROISÉES : boule 'a' (bas-droite) → loge A (haut-GAUCHE) ; boule 'b'
# (bas-gauche) → loge B (haut-DROITE). Difficulté par la FORME (traversée croisée du corps + appariement piégé).
# Preuve (solveur /tmp/pp_b31.py, réplique EXACTE du moteur) : opt = 34 coups (BFS exact, 160 928 états) · 2 boules ·
# 2/2 pièges (loge la plus proche = MAUVAISE clé : dist propre 11 vs loge voisine 4) · 0 boule triviale ·
# 0 cul-de-sac (réversibilité poussée↔tirage : 0 transition non-inversible sur 557 136 vérifiées, 166 320 états).
const NIVEAU_18 := [
	"#.A........B.#",
	"#.:.:.:.:.:..#",
	"#............#",
	"#..b..@...a..#",
	"##..#####..###",
	"##..#####..###",
]
# N19 — CAMION (forme franche, balle 31 ; contour Cowork FORMES_niveaux.md §Lot 3). La masse CLAIRE dessine la
# silhouette : BENNE haute à droite (row0 ouverte cols 4-12) + CABINE plus basse à gauche avec sa FENÊTRE en sol
# teinté ':' (row2, col2), corps (rows 1-3), deux ROUES = les 2 blocs du bas (rows 4-5, cols 2-3 et 8-9). 2 boules +
# 2 loges CROISÉES : boule 'a' (cabine, bas-gauche) → loge A (benne, haut-DROITE) ; boule 'b' (benne, bas-droite) →
# loge B (cabine, haut-GAUCHE). Difficulté par la FORME (enfiler la cabine étroite + traversée croisée benne↔cabine).
# Preuve (solveur /tmp/pp_b31.py, réplique EXACTE du moteur) : opt = 34 coups (BFS exact, 130 748 états) · 2 boules ·
# 2/2 pièges (loge la plus proche = MAUVAISE clé : dist propre 12/11 vs loge voisine 2/3) · 0 boule triviale ·
# 0 cul-de-sac (réversibilité poussée↔tirage : 0 transition non-inversible sur 465 000 vérifiées, 140 556 états).
const NIVEAU_19 := [
	"####.......A.#",
	"#.B..........#",
	"#.:..........#",
	"#.a....@...b.#",
	"##..####..####",
	"##..####..####",
]
# N20 — TUNNEL-BOUCLE (genre b37, variante 1 : anneau simple CARRÉ 7×7). Galerie en boucle fermée autour d'un
# bloc central plein (GDD §2.3 « topologie boucle »). La boule 'a' démarre en HAUT de l'anneau, sa loge 'A' est
# dans le coin BAS-GAUCHE ; l'avatar au coin BAS-DROITE. Dans un couloir d'UNE case de large, l'avatar ne peut
# JAMAIS croiser la boule → pour se placer DERRIÈRE elle du bon côté (et la pousser vers le coin), il doit faire
# le TOUR de la boucle. La difficulté vient de la FORME (le tour), pas d'un nombre de coups visé. Une seule boule
# → appariement trivial (pas de piège d'étiquette : on introduit le GENRE seul, anti-extrémisme). Le passage d'un
# coin exige un TIRER (on ne pousse pas une boule dans un angle : le geste acquis N4 sert ici).
# Preuve (solveur /tmp/pp_b37.py, réplique EXACTE du moteur) : opt = 39 coups (BFS) · SOLUBLE · l'avatar visite
# 16/16 cases praticables = il fait bien le TOUR complet · 0 cul-de-sac dur (co-atteignabilité exhaustive sur
# 240 états, 0 arête non-réversible) · BOUCLE NÉCESSAIRE : couper l'anneau en N'IMPORTE quelle case (13/13) rend
# le niveau INSOLUBLE → un couloir non bouclé (ligne) ne peut pas résoudre, la fermeture de la boucle est requise.
const NIVEAU_20 := [
	"#######",
	"#..a..#",
	"#.###.#",
	"#.###.#",
	"#.###.#",
	"#A...@#",
	"#######",
]
# N21 (pic — « MAMAN », balle 47, RESSERRÉ balle 70b) : les 5 croix épellent MAMAN (gauche→droite) → le parent
# lit le mot. Croix COLLÉES (adjacentes : largeur croix = 5 lettres → largeur TOTALE minimale → zoom plus grand).
# Mécanisme « mot imposé » (comme N16/PAPA) : TUTO_SYMBOLES[20]="impose" → chaque clé s'affiche TELLE QUELLE
# (M, A, N) ; encodage grille letter-based (min = boule, MAJ = loge). DOUBLONS 2×M / 2×A INTERCHANGEABLES (la
# victoire typée compare les étiquettes AFFICHÉES → toute loge de la bonne lettre convient) ; le N est UNIQUE.
# Les 5 boules m/a/m/a/n sont en 2 rangées (désordre) ; aucune boule sous SA colonne (0 trivial).
# Preuve (rendus_b70/pp_b70.py, réplique EXACTE du moteur pp_b41 ; méthode BORNÉE — PAS d'exact sur 5 boules,
# ~4 Go RAM) : SOLUBLE (séquence constructive de 61 coups REJOUÉE dans le moteur → victoire typée) · opt ∈
# [19, 61] (minorant = couplage des distances-poussée) · 5/5 pièges (loge la + proche = AUTRE lettre) · 0 boule
# triviale · 0 cul-de-sac (réversibilité universelle pousser↔tirer + spot-check borné 200 000 états, 0 arête
# non-réversible). Mot imposé (documentaire, parallèle à MOT_N16) : la grille NIVEAU_21 RÉALISE ce mot
# (croix M-A-M-A-N). Le changer = redessiner NIVEAU_21.
const MOT_N21 := "MAMAN"
const NIVEAU_21 := [
	"#######",
	"#MAMAN#",
	"#.....#",
	"#.mam.#",
	"#an...#",
	"#..@..#",
	"#######",
]
# N22 — ABSTRAIT COMPACT (genre b38, forme 1 : ÉCHELLE VERTICALE). 2 couloirs verticaux (colonnes x=1 et x=3) reliés
# par 3 barreaux (haut, milieu, bas) autour de 2 blocs pleins → grille réduite au minimum (13 cases de sol, 8 libres).
# Boules b/a en HAUT, loges B/A en BAS, décalées : aucune boule triviale (on ne peut pas pousser une boule droit sur
# sa loge — l'espace force à faire le tour par un couloir puis à tirer). Appariement franc (2 boules, étiquettes au
# hasard, mais loge la plus proche = la sienne → pas de piège d'étiquette, la difficulté est SPATIALE).
# Preuve (solveur rendus/b38/pp_b38.py, réplique EXACTE du moteur) : SOLUBLE opt = 24 coups (BFS EXACT, 1710 états) ·
# 0 cul-de-sac dur (BFS inverse exhaustif, 0 cul) · MINIMUM PROUVÉ : murer 1 des 8 cases de sol libres = INSOLUBLE (8/8).
const NIVEAU_22 := [
	"#####",
	"#B.b#",
	"#.#.#",
	"#.@.#",
	"#.#.#",
	"#A.a#",
	"#####",
]
# N23 — CROIX GROUPÉES / ENFILAGE (genre b39, bloc de 4 croix). Colonne de loges A,B,C,D (x1) SCELLÉE par le mur x2
# (lignes 1..4) : les 4 croix sont collées en bloc vertical, accessibles SEULEMENT par la BOUCHE du bas (loge D).
# Les 4 boules sont alignées en rangée dessous (espacées d'un cran, poussables une par une). Pour poser une boule sur
# une loge du haut, il faut la pousser à travers la colonne VIDE au-dessus → on remplit du FOND (A, en haut) vers la
# bouche (D) : l'ordre d'enfilage est FORCÉ, une boule posée trop tôt sur la bouche bloque l'accès aux croix voisines.
# Appariement PIÉGÉ (étiquettes au hasard) : la loge la plus proche de CHAQUE boule est la bouche D (autre clé) → 3/4 pièges.
# Preuve (rendus/b39/build_b39.py, solveur pp_b39.py réplique EXACTE du moteur) : SOLUBLE opt = 55 coups (BFS EXACT, 7041
# états) · 0 cul-de-sac dur par RÉVERSIBILITÉ (0 arête sans inverse sur 18638) · ORDRE FORCÉ (murer la bouche D = colonne
# scellée → INSOLUBLE, BFS exact 728 états) · appariement 3/4 pièges.
const NIVEAU_23 := [
	"##########",
	"#A########",
	"#B########",
	"#C########",
	"#D########",
	"#a.b.c.d.#",
	"#@.......#",
	"##########",
]
# N24 — ABSTRAIT COMPACT (genre b38, forme 2 : MOULIN DIAGONAL). Croisement piégé dans 9 cases de sol seulement
# (4 libres) : boule a en haut-gauche, sa loge A en bas-gauche ; boule b en bas-droite, sa loge B en haut-milieu →
# les deux paires se CROISENT en diagonale dans un moulin minuscule. Piège d'étiquette 2/2 : la loge la plus proche
# de chaque boule porte l'AUTRE étiquette (a près de B, b près de A) → l'enfant DOIT apparier au symbole, pas à la
# proximité. Espace si serré que l'ordre des coups est imposé (croisement obligé via tirer/pousser alternés).
# Preuve (solveur rendus/b38/pp_b38.py, réplique EXACTE du moteur) : SOLUBLE opt = 24 coups (BFS EXACT, 99 états) ·
# 0 cul-de-sac dur (BFS inverse exhaustif, 0 cul) · MINIMUM PROUVÉ : murer 1 des 4 cases de sol libres = INSOLUBLE (4/4).
const NIVEAU_24 := [
	"######",
	"#a.B.#",
	"##@.##",
	"##A.b#",
	"######",
]
# N25 (peigne, 3 boules) : opt = 31 coups (appariement +12) · aucune boule triviale · 3/3 pièges (loge la plus proche = autre étiquette) · 2 croisements · 0 cul-de-sac (réversibilité) · preuve : optimal EXACT (BFS).
const NIVEAU_25 := [
	"###########",
	"#C.A.B....#",
	"#.#.#.#.#.#",
	"#.........#",
	"#a.b.c....#",
	"#....@....#",
	"###########",
]
# N26 (PIC — peigne 5 boules (large), 5 boules) : opt = [>=41, seq 94] · aucune boule triviale · 5/5 pièges (loge la plus proche = autre étiquette) · 6 croisements · 0 cul-de-sac (réversibilité) · preuve : minorant PROUVÉ 41 + séquence VÉRIFIÉE 94 coups (RAM 7 Go).
const NIVEAU_26 := [
	"###############",
	"#.C.E.A.D.B...#",
	"#.#.#.#.#.#.#.#",
	"#.............#",
	"#a..b..c..d.e.#",
	"#......@......#",
	"###############",
]
# N27 (palier — chambre, 3 boules) : opt = 21 coups (appariement +10) · aucune boule triviale · 3/3 pièges (loge la plus proche = autre étiquette) · 2 croisements · 0 cul-de-sac (réversibilité) · preuve : optimal EXACT (BFS).
const NIVEAU_27 := [
	"#######",
	"#C.A.B#",
	"#a.b.c#",
	"#..@..#",
	"#######",
]
# N28 — ABSTRAIT COMPACT (genre b38, forme 3 : MARTEAU À POCHE — RÉORDONNANCEMENT « démonter pour remonter »). Un
# couloir horizontal d'UNE case (loge B à gauche, loge A à droite ; boules a puis b entre les deux) + une POCHE de
# 3 cases sous le milieu. Dans le couloir 1-case les boules ne peuvent PAS se croiser : pour amener a jusqu'à A (à
# droite, au-delà de b) et b jusqu'à B (à gauche, au-delà de a), il faut GARER une boule dans la poche, faire passer
# l'autre, puis la ressortir → démonter/remonter. Piège d'étiquette 2/2 (loge la plus proche = autre étiquette).
# Preuve (solveur rendus/b38/pp_b38.py, réplique EXACTE du moteur) : SOLUBLE opt = 30 coups (BFS EXACT, 980 états) ·
# 0 cul-de-sac dur (BFS inverse exhaustif, 0 cul) · MINIMUM PROUVÉ : murer 1 des 6 cases de sol libres = INSOLUBLE (6/6).
const NIVEAU_28 := [
	"########",
	"#B.a.bA#",
	"###...##",
	"###@.###",
	"########",
]
# N29 — CROIX GROUPÉES / ENFILAGE (genre b39, bloc de 5 croix — plus grand que N23 = diversité). Colonne de loges
# A,B,C,D,E (x1) SCELLÉE par le mur x2 (lignes 1..5) : 5 croix collées en bloc vertical, accessibles SEULEMENT par la
# BOUCHE du bas (loge E). 5 boules alignées en rangée dessous (espacées). Même mécanique que N23 mais bloc plus long →
# enfilage plus profond (remplir du FOND A en haut vers la bouche E) ; l'ordre est FORCÉ.
# Appariement PIÉGÉ : la loge la plus proche de chaque boule = la bouche E → 4/5 pièges.
# Preuve (rendus/b39/build_b39.py, solveur pp_b39.py réplique EXACTE du moteur) : SOLUBLE opt = 85 coups (BFS EXACT, 52969
# états) · 0 cul-de-sac dur par RÉVERSIBILITÉ (0 arête sans inverse sur 142690) · ORDRE FORCÉ (murer la bouche E = colonne
# scellée → INSOLUBLE, BFS exact 3360 états) · appariement 4/5 pièges.
const NIVEAU_29 := [
	"############",
	"#A##########",
	"#B##########",
	"#C##########",
	"#D##########",
	"#E##########",
	"#a.b.c.d.e.#",
	"#@.........#",
	"############",
]
# N30 — TUNNEL-BOUCLE (genre b37, variante 2 : anneau RECTANGULAIRE LARGE 9×7 — distinct du carré N20). Même
# genre (boucle fermée autour d'un bloc central), mais anneau PLUS GRAND et allongé → le tour est plus long, la
# forme différente (rectangle couché vs carré). Boule 'a' en HAUT, loge 'A' au coin BAS-DROITE, avatar au coin
# BAS-GAUCHE (miroir de N20 → l'enfant redécouvre le tour dans l'autre sens). Une seule boule (appariement trivial,
# genre introduit seul). Passage d'un coin par TIRER (acquis N4).
# Preuve (solveur /tmp/pp_b37.py, réplique EXACTE du moteur) : opt = 49 coups (BFS) · SOLUBLE · l'avatar visite
# 20/20 cases praticables = TOUR complet · 0 cul-de-sac dur (co-atteignabilité exhaustive sur 380 états, 0 arête
# non-réversible) · BOUCLE NÉCESSAIRE : couper l'anneau en N'IMPORTE quelle case (17/17) rend le niveau INSOLUBLE.
const NIVEAU_30 := [
	"#########",
	"#...a...#",
	"#.#####.#",
	"#.#####.#",
	"#.#####.#",
	"#@.....A#",
	"#########",
]
# N31 (PIC FINALE — peigne 6 boules, 6 boules) : opt = [>=48, seq 118] · aucune boule triviale · 6/6 pièges (loge la plus proche = autre étiquette) · 9 croisements · 0 cul-de-sac (réversibilité) · preuve : minorant PROUVÉ 48 + séquence VÉRIFIÉE 118 coups (RAM 7 Go).
const NIVEAU_31 := [
	"###############",
	"#.D.F.A.C.E.B.#",
	"#.#.#.#.#.#.#.#",
	"#.............#",
	"#a.b.c.d.e.f..#",
	"#......@......#",
	"###############",
]
# N32 (palier — chambre, 3 boules) : opt = 24 coups (appariement +11) · aucune boule triviale · 3/3 pièges (loge la plus proche = autre étiquette) · 2 croisements · 0 cul-de-sac (réversibilité) · preuve : optimal EXACT (BFS).
const NIVEAU_32 := [
	"########",
	"#B.C..A#",
	"#.a.b.c#",
	"#......#",
	"#...@..#",
	"########",
]
# N33 — FORME (champignon) × APPARIEMENT PIÉGÉ (genre 5 « combinaisons », balle 41). La masse CLAIRE (tunnel) dessine un
# champignon : chapeau arrondi + pied FIN (1 case) + base évasée (murs '#' = fond, invisibles). Boules a/b dans le chapeau,
# loges A/B CROISÉES (chaque boule traverse vers le côté opposé) ; boule c dans le chapeau, sa loge C dans la BASE, à
# atteindre par le PIED → la forme est PORTEUSE. opt = 29 coups (BFS EXACT, 1 095 228 états) · 3 boules · 3/3 pièges (loge
# la plus proche = MAUVAISE clé pour chacune) · 0 boule triviale (dist propre 6/6/5) · 0 cul-de-sac (réversibilité, BFS
# inverse exhaustif culs=0). Combinaison NÉCESSAIRE (test de cut) : murer le pied → c n'atteint plus C → INSOLUBLE (forme) ;
# sans appariement (O/X) opt tombe 29→21 (appariement porteur, +8). Preuve : rendus/b41/design_b41.py + pp_b41.py.
const NIVEAU_33 := [
	"###########",
	"###A...B###",
	"#.b..c..a.#",
	"#....@....#",
	"##.......##",
	"#####.#####",
	"#####.#####",
	"###..C..###",
	"###########",
]
# N34 — COMPACT × ENFILAGE × APPARIEMENT (genre 5 « combinaisons », balle 41). Colonne de loges A(fond)/B/C(bouche) en
# col1, SCELLÉE par le mur col2 → tube borgne rempli SEULEMENT par la bouche du bas ; poche d'alimentation réduite au
# MINIMUM (esprit b38). Enfilage FORCÉ : remplir du FOND vers la bouche (une boule posée trop tôt bloque les loges
# profondes). opt = 54 coups (BFS EXACT, 4926 états) · 3 boules · 2/3 pièges (la boule qui matche la bouche n'est jamais
# piégée = propriété du genre enfilage) · 0 boule triviale · 0 cul-de-sac (réversibilité). Combinaison NÉCESSAIRE (cut) :
# murer la bouche → INSOLUBLE (enfilage) ; retirer 1 case de sol → INSOLUBLE (compact MINIMAL prouvé, 13 cases praticables).
const NIVEAU_34 := [
	"######",
	"#A####",
	"#B####",
	"#C####",
	"#.####",
	"#...##",
	"#.abc#",
	"##@.##",
	"######",
]
# N35 — GRANDE FINALE : BOUCLE × ENFILAGE × APPARIEMENT PIÉGÉ (genre 5 « combinaisons », balle 41 ; la plus dure de la
# série, hors pic → sans bandeau). Anneau autour d'un bloc central (b37, « faire le tour ») + tube d'enfilage scellé (col1,
# loges B(fond)/C/A(bouche), b39) rempli par la bouche. Les 3 boules partent du bas de l'anneau et doivent CIRCULER autour
# du bloc pour rejoindre le tube, puis s'y enfiler DANS L'ORDRE, chacune sur SA loge. opt = 62 coups (BFS EXACT, 1 241 076
# états) · 3 boules · 2/3 pièges · 0 boule triviale · 0 cul-de-sac (réversibilité, BFS inverse exhaustif culs=0). Combinaison
# NÉCESSAIRE (cut) : retirer le bloc → opt 62→44 (boucle porteuse, +18) ; murer la bouche → INSOLUBLE (enfilage) ; sans
# appariement (O/X) opt 62→50 (appariement porteur, +12).
const NIVEAU_35 := [
	"########",
	"#B#....#",
	"#C#....#",
	"#A#....#",
	"#......#",
	"#..##..#",
	"#..##..#",
	"#a.bc.@#",
	"########",
]

# --- NIVEAUX SUPPLÉMENTAIRES « expert » N36-N38 (balle 48) -------------------------------------------------
# Trio AJOUTÉ après N35, de difficulté SUPÉRIEURE à N34/N35 (joueur addict), design LIBRE, les 3 DIFFÉRENTS :
# chacun est une COMBINAISON distincte de particularités, en escalade croissante prouvée (opt 74 < 78 < 93,
# tous > N35 = 62). Décor = roadmap (aucun dessin ici). Preuve complète : rendus/b48/pp_b48.py (réplique EXACTE
# du moteur, solveur VALIDÉ N10=11/N15=29) → opt EXACT (BFS bidirectionnel), 0 boule triviale, appariement piégé,
# 0 cul-de-sac (réversibilité universelle), tests de CUT (combinaison nécessaire). PAS marqués PIC : N35 lui-même,
# « la plus dure de la série », est hors pic → ce trio encore plus dur reste cohérent sans bandeau (NIVEAUX_PIC inchangé).

# N36 — ENFILAGE LONG × COMPACT × APPARIEMENT (threading pur, « encore plus dur » que N34). Tube borgne de 4 loges
# A(fond)/B/C/D(bouche) en col1, SCELLÉ par le mur col2 → rempli SEULEMENT par la bouche du bas ; poche
# d'alimentation minimale. Ordre d'enfilage FORCÉ (remplir du FOND vers la bouche). Boules en DÉSORDRE (d,a,b,c) →
# l'appariement est PORTEUR (opt typé 74 > untyped 70, +4) et PIÉGÉ (3/4 ; la boule qui matche la bouche n'est
# jamais piégée = propriété du genre). opt = 74 coups (BFS EXACT) · 4 boules · 0 triviale · 0 cul-de-sac. CUT :
# murer la bouche (1,5) → INSOLUBLE (enfilage NÉCESSAIRE).
const NIVEAU_36 := [
	"#######",
	"#A#####",
	"#B#####",
	"#C#####",
	"#D#####",
	"#.#####",
	"#.....#",
	"#.dabc#",
	"##@...#",
	"#######",
]

# N37 — GRANDE BOUCLE × APPARIEMENT CROISÉ (loop pur, « faire le tour » — genre b37/N35 RÉUTILISÉ et diverge :
# ici l'anneau fait 2 cases de large → les BOULES elles-mêmes circulent autour du bloc central, pas seulement
# l'avatar). 3 boules en haut, 3 loges en bas, appariement CROISÉ (chaque boule traverse vers le côté opposé →
# 2 croisements ; loge la plus proche = MAUVAISE lettre pour chacune → 3/3 pièges). opt = 78 coups (BFS EXACT) ·
# 0 triviale · 0 cul-de-sac. CUT : retirer le bloc central (chambre ouverte) → opt 78→44 (boucle PORTEUSE, +34) ;
# sans appariement (O/X) → opt 78→57 (appariement porteur, +21).
const NIVEAU_37 := [
	"###########",
	"#a..b..c..#",
	"#..#####..#",
	"#..#####..#",
	"#..#####..#",
	"#.C..A..B.#",
	"#####@#####",
]

# N38 — GRANDE FINALE ULTIME : BOUCLE × ENFILAGE × APPARIEMENT PIÉGÉ (les DEUX piliers combinés, la plus dure du
# jeu). Version AGRANDIE de N35 : tube borgne 4 loges (col1, scellé) + anneau plus large autour d'un bloc central
# 3×2. Les 4 boules partent du bas, doivent CIRCULER autour du bloc pour rejoindre le tube, puis s'y ENFILER dans
# l'ordre, chacune sur SA loge. opt = 93 coups (BFS EXACT) · 4 boules · 0 triviale · 3/4 pièges · 0 cul-de-sac.
# CUT : murer la bouche (1,5) → INSOLUBLE (enfilage) ; retirer le bloc central → opt 93→63 (boucle porteuse, +30) ;
# sans appariement (O/X) → opt 93→79 (appariement porteur, +14).
const NIVEAU_38 := [
	"#########",
	"#D#.....#",
	"#C#.....#",
	"#B#.....#",
	"#A#.....#",
	"#.......#",
	"#..###..#",
	"#..###..#",
	"#a.bcd.@#",
	"#########",
]

# Liste ORDONNÉE des niveaux : l'index courant (`_niveau_courant`) désigne le tableau chargé.
# N1 = 0 (tutoriel pousser), N2 = 1, N3 = 2, N4 = 3 (tutoriel tirer), N5 = 4 (contournement), N6 = 5
# … N10 = 9 (lot 3), N11 = 10 … N15 = 14 (lot 4, niveaux « parents »), N16 = 15 … N20 = 19 (lot 5 bloc 1),
# N21 = 20 … N25 = 24 (lot 5 bloc 2), N26 = 25 … N30 = 29 (lot 5 bloc 3), puis N31 = 30 … N35 = 34 (lot 5
# bloc 4), puis N36 = 35 … N38 = 37 (balle 48 : trio « expert » supplémentaire, plus dur que N34/N35). La
# progression est LIBRE (GDD §2.3) : après une victoire, on AUTO-passe au niveau suivant (balle 34) et les
# flèches ◄/► naviguent parmi les débloqués ; « Recommencer » rejoue le courant — rien n'oblige.
# N38 = DERNIER → sa victoire mène à l'écran de fin (pas de reboucle), l'index restant borné à `dernier`.
const NIVEAUX := [
	NIVEAU_1, NIVEAU_2, NIVEAU_3, NIVEAU_4, NIVEAU_5,
	NIVEAU_6, NIVEAU_7, NIVEAU_8, NIVEAU_9, NIVEAU_10,
	NIVEAU_11, NIVEAU_12, NIVEAU_13, NIVEAU_14, NIVEAU_15,
	NIVEAU_16, NIVEAU_17, NIVEAU_18, NIVEAU_19, NIVEAU_20,
	NIVEAU_21, NIVEAU_22, NIVEAU_23, NIVEAU_24, NIVEAU_25,
	NIVEAU_26, NIVEAU_27, NIVEAU_28, NIVEAU_29, NIVEAU_30,
	NIVEAU_31, NIVEAU_32, NIVEAU_33, NIVEAU_34, NIVEAU_35,
	NIVEAU_36, NIVEAU_37, NIVEAU_38,   # balle 48 : N36=35, N37=36, N38=37 (DERNIER — trio expert)
]

# Index (0-based) des niveaux marqués « PIC de difficulté » (GDD §2.3 : pic annoncé tous les 5 niveaux).
# GÉNÉRIQUE : à l'entrée d'un de ces niveaux, le bandeau « Niveau difficile » s'affiche (voir
# _maj_annonce_pic). Pics livrés : N11 (index 10, lot 4), N16 (index 15, lot 5 bloc 1), N21 (index 20,
# lot 5 bloc 2), N26 (index 25, lot 5 bloc 3) et N31 (index 30, lot 5 bloc 4). Le trio expert N36-N38 (balle 48)
# n'est PAS marqué pic : N35, « la plus dure de la série », est déjà hors pic → un trio encore plus dur reste
# cohérent sans bandeau (INCHANGÉ). Un futur pic s'annoncerait pareil en ajoutant son index ici, sans autre code.
const NIVEAUX_PIC := [10, 15, 20, 25, 30]

# TUTO ÉVOLUTIF (balle 40) — POOL de symboles imposé par niveau, pour introduire l'appariement PROGRESSIVEMENT :
# index (0-based) → "chiffres" | "lettres" | "impose" | "mix". Les niveaux ABSENTS gardent le régime "mix"
# d'origine (défaut) → N11-N35 restent "mix" SAUF N16. Le tuto force un pool : N6/N7 = chiffres seuls,
# N8 = lettres seules, N9 = "impose" (mot « écris ton prénom », balle 44 : chaque clé s'affiche telle quelle =
# la lettre), N10 = mix. AJOUT balle 46 : N16 (index 15) = "impose" aussi → les 4 croix épellent le MOT_N16
# « PAPA » (pic gardé difficile, cf. const NIVEAU_16). AJOUT balle 47 : N21 (index 20) = "impose" → les 5 croix
# épellent le MOT_N21 « MAMAN » (pic gardé difficile, cf. const NIVEAU_21). Les autres niveaux "mix" INCHANGÉS.
const TUTO_SYMBOLES := {5: "chiffres", 6: "chiffres", 7: "lettres", 8: "impose", 9: "mix", 15: "impose", 20: "impose"}

# SAUVEGARDE DE LA PROGRESSION SUR DISQUE (balle 25, retour de test Fabrice : « refaire tout le jeu pour voir un
# niveau, insupportable »). Le plus haut niveau atteint (_niveau_max_atteint) est écrit dans user:// à chaque
# déblocage et rechargé au démarrage → l'enfant retrouve TOUS ses niveaux débloqués sans rejouer.
const CHEMIN_PROGRESSION := "user://pousse_pollen_progression.cfg"   # ConfigFile : { progression/niveau_max_atteint = int ; choix/avatar = int ; choix/curseur = int (PC) }
# Choix d'avatar/curseur (balle 49 ; curseur : PC seulement depuis le 08-10) : MÊME fichier que la progression, section "choix" (à CÔTÉ de la progression, GDD §2.3).
# Sauvegarde FUSIONNÉE (on relit le fichier avant d'écrire) → progression et choix cohabitent sans s'écraser.
const SECTION_CHOIX := "choix"
const CLE_AVATAR := "avatar"
const CLE_CURSEUR := "curseur"    # (08-10) PC : choix mémorisé · mode tactile (Android) : clé effacée à la prochaine sauvegarde
# CONFORT DE TEST : déblocage total immédiat de toute la série. Deux voies (la plus simple à la main) :
#   • poser un fichier vide `user://pousse_pollen_unlock_all` (sous Linux : ~/.local/share/godot/app_userdata/Pousse-Pollen/) ;
#   • OU passer DEBUG_UNLOCK_ALL à true (recompilé). Aucune des deux n'écrit la sauvegarde → test non destructif.
const FICHIER_UNLOCK_ALL := "user://pousse_pollen_unlock_all"
const DEBUG_UNLOCK_ALL := false

# Étiquettes TIRÉES AU HASARD (balle 24, retour de test Fabrice). Les symboles affichés ne suivent PLUS la
# suite 1-2-3 / A-B-C : à chaque chargement de niveau, chaque CLÉ d'appariement (lettre de la grille) reçoit un
# symbole tiré au hasard dans un pool qui MÊLE chiffres ET lettres (voir _generer_etiquettes). L'ENCODAGE grille
# reste letter-based (minuscule = boule, MAJUSCULE = loge, appariées par la lettre) ; seul l'AFFICHAGE change.
# Boule et loge d'une même clé passent par le MÊME tirage → même symbole → appariement lisible, victoire typée
# intacte. Pools volontairement épurés (peu de confusables pour un jeune enfant).
const POOL_CHIFFRES := ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
const POOL_LETTRES := ["A", "B", "C", "D", "E", "F", "G", "H", "K", "M"]

# Résolution de base du projet (1024×768, stretch canvas_items). Sert à recadrer la caméra
# pour faire tenir chaque tableau à l'écran (N2/N3 plus grands que N1) sans dépendre du timing
# du stretch dans _ready (valeur déterministe, alignée sur project.godot).
const ECRAN := Vector2(1024, 768)
# CADRAGE ÉCRAN RÉEL (21-10, REQ_pousse_cadrage_android) : ECRAN reste le repère de CONCEPTION des contrôles ci-dessous.
# Le projet CoccOs est en 1280×720 « expand » → l'écran VISIBLE réel (`_ecran`) vaut 1280×960 en 4:3, 1280×720 en 16:9,
# 1600×720 sur un téléphone 20:9. Le cadrage caméra et le fond lisent `_ecran` (mêmes règles b28/b33, bonne mesure) ;
# chaque contrôle garde sa distance à SON coin (ANCRE_*) → sur un écran visible de 1024×768, tout reste au pixel près.
const ANCRE_HG := Vector2(0, 0)
const ANCRE_HD := Vector2(1, 0)
const ANCRE_BG := Vector2(0, 1)
const ANCRE_BD := Vector2(1, 1)
const ANCRE_CENTRE := Vector2(0.5, 0.5)   # (21-10) accueil : le bloc 1024×768 est CENTRÉ sur l'écran réel
var _ecran := ECRAN
var _ancrages: Array = []        # [nœud, position dans le repère de conception, ancre] — replacés à chaque changement de taille

# CONTRÔLES à l'écran (repère 1024×768, stretch canvas_items) déduits des constructeurs de boutons :
#   Recommencer (haut-gauche)  : RECOMMENCER_POS/TAILLE → x[28,268]  y[24,108]   (bas = 108)
#   Niveau N (haut-droite)     : ~ symétrique  → y[24,~86]
#   Bandeau « Niveau difficile » (haut-centre) : pos (192,120) taille (640,100) → y[120,220] — TRANSITOIRE :
#       il s'auto-efface en ~3 s (voir _afficher_annonce_pic) → JAMAIS pris en compte par l'évitement caméra
#       (il peut couvrir brièvement les rangées hautes à l'entrée d'un pic : c'est son rôle d'annonce).
#   Agripper/OK (bas-gauche)   : AGRIPPER_CENTRE/TAILLE — balle 28 : DESCENDU (584→634).
#   D-pad (bas-droite)         : centre (DPAD_CENTRE_X,DPAD_CENTRE_Y), flèches DPAD_TAILLE_FLECHE à ±DPAD_ECART.
#       Balle 28 : flèches réduites 96→80. Boîte englobante = centre ± DPAD_DEMI.
# Balle 28 — RÈGLE DÉFINITIVE Fabrice : « les flèches peuvent être PAR-DESSUS la TERRE ; c'est le TUNNEL qui
# ne doit pas être caché. » On cadre donc sur les seules cases PRATICABLES (≠ '#') : elles évitent les boutons
# au pixel près ; les murs '#' (couleur du décor) débordent librement dessous. Contenu CENTRÉ en X, top-aligné
# au SOMMET de l'écran (balle 30 : les 2 boutons du haut suivent la même règle → le tunnel monte dans le couloir
# libre du centre-haut), zoom MAXIMAL (plafond 1.4). Cf. _cadrer_camera / _cadrage_ok / _rects_boutons.
const RECOMMENCER_BAS := 108.0                      # bas de la ZONE haut-gauche réservée (barre du haut) — repère historique, conservé
const RECOMMENCER_POS := Vector2(28, 24)            # coin haut-gauche de la ZONE réservée (Recommencer + Accueil empilés)
const RECOMMENCER_TAILLE := Vector2(240, 84)        # ZONE réservée à l'évitement caméra (_rects_boutons) → bord bas = 108. NE PAS réduire (cadrage b33).
# Balle 49 : les DEUX boutons (Recommencer + Accueil) sont EMPILÉS DANS cette même zone réservée → aucun NOUVEAU
# rectangle d'évitement → cadrage b33 STRICTEMENT INCHANGÉ (mesuré : 38/38 zoom+position identiques). Rendu fin = roadmap.
const RECOMMENCER_BTN_TAILLE := Vector2(240, 38)    # bouton Recommencer : moitié HAUTE de la zone → x[28,268] y[24,62]
const ACCUEIL_POS := Vector2(28, 66)                # bouton Accueil : moitié BASSE de la zone → x[28,268] y[66,104]
const ACCUEIL_TAILLE := Vector2(240, 38)            # (reste DANS la zone réservée y≤108 → 0 régression caméra par construction)
# (21-10) Les DEUX boutons de cette zone portent une ICÔNE DESSINÉE à la place du mot (demande Fabrice), reprise du jeu
# des 7 différences : flèche tournante = Recommencer, maison = Accueil (cf. `IconeDessinee`, fin de fichier). Mêmes
# teintes que là-bas : fond clair + trait sombre = contraste de LUMINANCE (daltonien, GDD §1) ; l'infobulle reste.
const COL_SORTIE      := Color(0.88, 0.90, 0.96, 1.0)   # fond clair du bouton, ses 3 états — 7 diff `COL_SORTIE`
const COL_SORTIE_TXT  := Color(0.08, 0.09, 0.14, 1.0)   # trait sombre de l'icône et de la bordure — 7 diff `COL_SORTIE_TXT`
# Indicateur de NIVEAU (haut-DROITE). Balle 63 (retour test Fabrice « gagner de la place ») : UNE SEULE ligne
# « ◄ N ► » — juste le NUMÉRO (plus le mot « Niveau ») encadré par les 2 flèches de navigation, au lieu du label
# sur une ligne + les flèches SOUS lui sur une 2e (place perdue). Emprise réduite en HAUTEUR (y[20,84] seulement)
# → libère le haut-droite pour le cadrage (point E). Géométrie CENTRALISÉE ici (source unique) → le constructeur
# (_construire_label_niveau) ET l'évitement caméra (_rects_boutons) la lisent → le TUNNEL ne passe jamais dessous.
const LABEL_NIVEAU_POS := Vector2(768, 20)  # CoccOs : décalé de 100 px (croix de fermeture à droite)          # panneau du NUMÉRO seul, au MILIEU de « ◄ N ► » → x[868,936]
const LABEL_NIVEAU_TAILLE := Vector2(68, 64)        # → couvre x[868,936], y[20,84] (rétréci au numéro, 1-2 chiffres)
# Flèches de NAVIGATION de NIVEAU (balle 34) : changent de TABLEAU (distinctes du D-pad qui déplace l'avatar).
# Balle 63 : placées de CHAQUE CÔTÉ du numéro, sur la MÊME ligne (« ◄ N ► ») → 1 rangée au lieu de 2. Distinctes
# du D-pad : triangles PLEINS ◄/► (vs flèches fines ^v<>), fond clair, POSITION opposée (haut-droite vs bas-droite).
# Réservées dans _rects_boutons (toujours, déterministe) → le tunnel jamais dessous.
const NAV_TAILLE := Vector2(64, 64)
const NAV_PREC_CENTRE := Vector2(732, 52)  # CoccOs : décalé de 100 px (croix de fermeture à droite)           # ◄ (précédent) — à GAUCHE du numéro, même ligne → x[800,864] y[20,84]
const NAV_SUIV_CENTRE := Vector2(872, 52)  # CoccOs : décalé de 100 px (croix de fermeture à droite)           # ► (suivant)   — à DROITE du numéro, bord écran → x[940,1004] y[20,84]
# Anti-rebond (débounce) de la navigation (balle 35, GDD §2.3 « Liberté ») : un clic ◄/► met à jour AUSSITÔT le
# NUMÉRO visé (« Niveau N ») SANS charger, et (re)démarre ce minuteur. On ne charge le niveau visé qu'à
# l'expiration — 2 s APRÈS le DERNIER clic. Enchaîner les clics ne provoque donc qu'UN seul chargement (pas de
# calcul ni de chargement en cascade des niveaux intermédiaires).
const NAV_DELAI_S := 2.0
# Géométrie du D-pad dérivée d'un centre UNIQUE (balle 23) : _construire_fleches_ecran ET le rectangle
# d'évitement caméra (_rects_boutons) lisent la MÊME source → cohérence garantie. Balle 63 (retour test Fabrice) :
# DISPOSITION 2 RANGÉES au lieu de la croix 3 rangées → « ^ » au-dessus, puis « < v > » sur la MÊME rangée du bas
# (down au centre, gauche/droite à ses côtés). Gain de HAUTEUR. Ensemble REDESCENDU franchement et bord DROIT
# aligné sur le bord droit de ► (1004). C'est la DISPOSITION qui change (positions dérivées du centre), pas le
# rôle des flèches.
const DPAD_CENTRE_X := 884.0                         # balle 63 : bord DROIT du D-pad (cx + DPAD_DEMI) aligné sur le bord droit de ► (1004) → 884
const DPAD_CENTRE_Y := 700.0                         # balle 63 : REDESCENDU franchement (584→700) — D-pad BAS sur TOUS les tableaux (retour test Fabrice)
const DPAD_ECART := 88.0                             # distance centre → centre d'une flèche — balle 62 : 100→88 (resserré)
const DPAD_TAILLE_FLECHE := 64.0                     # côté d'une flèche — balle 28 : 96→80 ; balle 62 : 80→64 (cible confortable au pouce d'un enfant, GDD §1)
const DPAD_DEMI := DPAD_ECART + DPAD_TAILLE_FLECHE * 0.5   # 120 : centre → bord EXTÉRIEUR gauche/droite ET HAUT (le « ^ » est à DPAD_ECART au-dessus du centre)
const DPAD_BAS_DEMI := DPAD_TAILLE_FLECHE * 0.5           # balle 63 : sous le centre, seule la rangée « < v > » → demi-flèche (boîte 2 rangées, plus basse en hauteur → LIBÈRE l'espace jouable, cf. point E)
# Agripper (bas-gauche). Balle 63 (retour test Fabrice « fait 3× l'épaisseur de l'écriture ») : plus FIN (150→72 de
# HAUT ≈ moitié, ~ hauteur d'un bouton texte), plus ÉTROIT (180→150) et DESCENDU encore. Reste une cible confortable
# au pouce (GDD §1). Géométrie centralisée ici → le bouton (_construire_bouton_agripper) et l'évitement caméra
# (_rects_boutons) lisent la MÊME source.
const AGRIPPER_TAILLE := Vector2(150, 72)
const AGRIPPER_CENTRE := Vector2(155, 694)          # bord bas ~730, aligné avec le bas de la rangée « < v > » du D-pad
# Cadrage (balle 28, RÈGLE DÉFINITIVE Fabrice) : « seul le TUNNEL évite les boutons ; la TERRE peut passer
# dessous ». On cadre sur les seules cases PRATICABLES (glyphe ≠ '#'), au zoom RÉELLEMENT MAXIMAL (plafond 1.4) :
# les murs '#' (couleur du décor) débordent librement sous les 4 boutons. Balle 33 (grief Fabrice répété : les
# plateaux larges-plats et les pics restaient minuscules, gros vide à droite/en bas) : le zoom retenu est le PLUS
# GRAND z pour lequel il EXISTE un placement caméra où TOUT le tunnel tient dans l'espace libre — on a retiré
# l'ancre « haut collé au sommet » de b30/b32 qui bridait les plateaux larges-plats (elle poussait le contenu
# dans les coins hauts occupés par 2 boutons → zoom sous-dimensionné). Balle 32 CONSERVÉE : la vue part CENTRÉE
# sur l'AVATAR et ne glisse que le MINIMUM si cela cacherait un bord de tunnel. Cf. _cadrer_camera /
# _fenetre_camera / _cadrage_ok / _rects_boutons.
const GARDE_BOUTON := 8.0                            # petit jeu entre une case praticable et un bouton (ne se collent pas)
const MARGE_BORD := 8.0                              # petit jeu entre une case praticable et le bord de l'écran
const ZOOM_PLAFOND := 1.4                            # ne pas grossir les tout petits niveaux au-delà (GDD §2.3)

# ── VUE PLONGÉE 3/4 (balle 55 — GDD §2.3 l.68 + §7 note) ─────────────────────────────────────────────────
# La vue plongée est un choix de RENDU, PAS une contrainte moteur : la logique reste une grille (GDD §7). On
# regarde le SOL de biais (« plongée 3/4 ») → foreshortening VERTICAL : une case fait CELL de large mais
# CELL·PLONGE_KY de HAUT (KY<1 = plan de sol incliné vers l'arrière, comme un plancher vu d'en haut-devant).
# Les OBJETS DEBOUT (boules de pollen, avatar, étiquettes d'appariement) restent À L'ENDROIT (billboard, non
# écrasés) → lisibilité préservée (daltonien + jeune enfant, GDD §1). RENDU et CADRAGE caméra lisent la MÊME
# valeur → cohérence garantie. Dosage réglable ici (« on dosera l'inclinaison ») ; 1.0 = ancienne vue à plat.
# Balle 61 (retour test Fabrice) : la vue était TROP HAUTE (trop de dessus) → on REFERME l'angle vers une vue
# plus RASANTE (regard plus bas, plancher plus incliné) en baissant KY : cases plus courtes en Y, les murs de
# terre lisent comme des PAROIS et les objets debout (avatar/boules) « circulent » dans le couloir. 1.0 = à plat.
const PLONGE_KY := 0.52
# ── DÉ-ÉCRASEMENT DES TABLEAUX PLATS (balle 62 — retour test Fabrice sur N9) ─────────────────────────────
# Un tableau LARGE et PLAT (peu de rangées, ex. N9 = 16 cases de large × 4 de haut) est cadré par sa LARGEUR :
# le zoom uniforme est bloqué par les bords gauche/droit → il reste une BANDE FINE au milieu, gros vide brun
# au-dessus ET en dessous (« il pourrait être étiré un peu plus vers le haut parce qu'il y a de la place »).
# Levier retenu = ADAPTER LE FORESHORTENING selon la forme, PAS un rustine sur N9. Le foreshortening vertical
# (PLONGE_KY) est le SEUL facteur qui étire la hauteur SANS toucher la largeur ni distordre les objets debout
# (avatar/boules restent billboard, taille inchangée — cf. _dessiner_pollen/_dessiner_avatar) : seuls le plan de
# SOL et les marques au sol (croix) grandissent en Y. Pour les tableaux plats on RELÈVE donc _plonge_ky (vers 1.0
# = sol vu plus de face, cases carrées) jusqu'à remplir une fraction cible de la hauteur jouable, PLAFONNÉ à
# PLONGE_KY_MAX. Le garde-fou b28/b33 reste PRIORITAIRE : _cadrer_camera re-teste la faisabilité après le relèvement
# → le TUNNEL n'est JAMAIS coupé (au pire le zoom rend un cheveu de largeur). Les tableaux HAUTS/carrés (rangées ≥
# colonnes : N8 spirale, N36…) ne remplissent PAS la condition « large-plat » → _plonge_ky reste 0.52 → INCHANGÉS.
const PLONGE_KY_MAX := 1.0                          # plafond du dé-écrasement : 1.0 = cases CARRÉES (sol vu de face, aucune distorsion). Monter (≤~1.3) = tableaux plats plus HAUTS (léger étirement vertical du sol/croix, objets debout intacts). Dial « à l'œil » Fabrice.
const PLAT_REMPLIR_V := 0.62                        # fraction cible de la hauteur jouable qu'un tableau plat cherche à remplir avant plafonnement (0 = jamais dé-écraser ; monter = plus haut). Dial « à l'œil » Fabrice.
# ── PLANCHER de quadrature (balle 67 — retour test Fabrice) ───────────────────────────────────────────────────
# Le dé-écrasement large-plat (PLAT_REMPLIR_V) ne visait que le REMPLISSAGE vertical : il laissait des cases écrasées
# jusqu'à ~2:1 (ratio de case = 1/_plonge_ky) sur les tableaux non-plats ou hauts (ex. N15 le cœur, ratio ~1,92).
# On impose donc un PLANCHER à _plonge_ky : aucune case ne peut être plus large que 1/PLONGE_KY_MIN fois sa hauteur.
# Défaut 1/1,15 ≈ 0,87 → ratio ≤ 1,15 PARTOUT (plongée douce conservée, ≤15 %). Monter vers 1.0 = cases plus carrées.
# Comme on prend le MAX, les tableaux déjà à _plonge_ky ≥ PLONGE_KY_MIN restent INCHANGÉS. Le garde-fou b28/b33
# (tunnel jamais coupé) reste prioritaire : le zoom re-descend si le contenu, plus haut, ne tenait plus.
const PLONGE_KY_MIN := 1.0 / 1.15                  # plancher du foreshortening : ratio de case ≤ 1,15 partout (fin de l'écrasement 2:1). Monter (≤1.0) = plus carré. Dial « à l'œil » Fabrice.
# ── PROPORTION boule/avatar CONSTANTE quel que soit le foreshortening (balle 63 — retour test Fabrice) ────────
# DIAGNOSTIC : la case se dessine CELL de large × CELL·_plonge_ky de HAUT ; boule et avatar sont des BILLBOARDS
# (ronds, non aplatis) de LARGEUR fixe = fraction de CELL. Comme _plonge_ky VARIE par tableau depuis b62 (0.52 pour
# les tableaux plongés/petits → 1.0 pour les larges-plats dé-écrasés), le remplissage VERTICAL de la case change :
# à _plonge_ky=0.52 la boule (0.80·CELL) dépasse la case courte (frôle/déborde, toléré) ; à _plonge_ky=1.0 la case
# est haute et la boule ne la remplit qu'aux 80 % (paraît TROP PETITE). Le CADRAGE (zoom caméra) n'y change RIEN :
# tout est en repère-monde, la boule et la case sont grossies du MÊME zoom → seul _plonge_ky déplace le rapport.
# CORRECTIF : la fraction MONTE avec _plonge_ky (remap PLONGE_KY→PLONGE_KY_MAX) → remplissage de case ~constant.
# À _plonge_ky bas = valeur HISTORIQUE (petits tableaux JAMAIS rapetissés, débordement conservé) ; à _plonge_ky
# haut = fraction relevée (grands tableaux remplis, léger débordement toléré). L'objet reste ROND (aucune
# distorsion : on ne change que sa TAILLE). Sur les tableaux NON-plats (_plonge_ky = PLONGE_KY) → fraction MIN
# → rendu STRICTEMENT INCHANGÉ (N1-N10, pics, N8…). Dials « à l'œil » Fabrice.
const BOULE_FRAC_MIN := 0.40    # boule à _plonge_ky = PLONGE_KY (0.52) : demi-largeur = 0.40·CELL (HISTORIQUE, petits tableaux inchangés)
const BOULE_FRAC_MAX := 0.50    # boule à _plonge_ky = PLONGE_KY_MAX (1.0) : demi-largeur = 0.50·CELL (grands tableaux, ~pleine case)
const AVATAR_FRAC_MIN := 0.46   # avatar à _plonge_ky bas : demi = 0.46·CELL (HISTORIQUE)
const AVATAR_FRAC_MAX := 0.54   # avatar à _plonge_ky haut : demi = 0.54·CELL (grands tableaux, léger débordement toléré)
# Balle 69 : l'ÉCHAPPÉE VERDURE / horizon (bande fond_prairie.png en haut, balle 55/61) est SUPPRIMÉE (décision
# DESIGN Fabrice : « la verdure ne rend pas ce que j'attendais → la supprimer et combler avec la terre »). Les
# constantes HORIZON_H / HORIZON_CROP_* / TEX_PRAIRIE et la fonction _construire_horizon sont retirées ; le centre-
# haut, jadis réservé à la bande, se libère → gain de zoom sur les tableaux capés par le haut (cf. _cadrer_camera).

# ── RELIEF 2.5D (balle 60 — GDD §4ter, réf maquette Ryzlord core/tilemap.py) ─────────────────────────────
# Pas de 3D ni de rotation caméra : on donne de la PROFONDEUR par la COULEUR (luminance), pas par la géométrie.
# Principe maquette : côté sombre / dessus clair / fond sombre / tri par y. Les murs de terre ('#') deviennent
# des BLOCS EXTRUDÉS : face SUPÉRIEURE claire (texture terre pleine) + FACE LATÉRALE plus sombre tirée vers le
# BAS (vers la caméra) → le mur a une hauteur. Là où un mur borde une galerie EN CONTREBAS (case praticable
# au-dessous), cette face latérale + un LISERÉ de fond sombre à son pied dessinent la PAROI + le « trou » du
# tunnel creusé. Rendu en DEUX passes (peintre, tri par y) dans _draw : d'abord tous les SOLS, puis les MURS du
# haut vers le bas (chaque face latérale recouvre le haut de la rangée du dessous ; un mur plus bas recouvre à
# son tour la face du mur du dessus → occlusion correcte).
# ⚠ Balle 61 (retour test Fabrice) : l'extrusion se prend DÉSORMAIS SUR LA TERRE, jamais sur le sol praticable.
# La face latérale sombre = la BANDE BASSE de la case du MUR lui-même (on ampute la terre) ; le dessus clair = le
# reste HAUT de la même case. La case du dessous (galerie) garde donc TOUTE sa hauteur → le tunnel ne rétrécit
# plus. Cohérent en HAUT comme en BAS : chaque mur exposé au sud (galerie en contrebas) montre sa paroi dans ses
# propres bornes ; le reflet reste sur l'arête haute (crête). RELIEF_H peut donc monter FORT (paroi bien marquée)
# sans jamais rogner le praticable. Dosage = les 3 constantes ci-dessous (seul levier d'épaisseur du relief).
const RELIEF_H := 0.46                             # épaisseur de la paroi, fraction de la HAUTEUR-écran de case (bornée à <1 → jamais tout le dessus)
const RELIEF_LISERE := 4.0                         # liseré de fond sombre au pied de la paroi (le « trou » du tunnel), pixels-monde
const COL_RELIEF_COTE := Color(0.50, 0.50, 0.50)   # face latérale : terre ASSOMBRIE (côté sombre — profondeur par la luminance, daltonien §1)
const COL_RELIEF_FOND := Color(0.05, 0.04, 0.03)   # fond très sombre au pied du mur (crevasse / ombre portée du tunnel)
const COL_RELIEF_REFLET := Color(1.0, 0.96, 0.85, 0.16)  # reflet clair sur l'arête HAUTE du dessus (lumière rasante, maquette)
const RELIEF_REFLET_H := 5.0                       # épaisseur du reflet clair sur l'arête haute, pixels-monde

# Distinction par FORME + luminance + (à venir) libellé — jamais la couleur seule (daltonien, GDD §1).
# Balle 54 : mur (terre) et sol (galerie) sont désormais TEXTURÉS (TEX_TERRE/TEX_SOL, cf. _texturer_case) —
# les aplats COL_MUR/COL_SOL_TEINTE ne servent plus. La distinction praticable/mur reste portée par la
# LUMINANCE (terre FONCÉE = on bloque, sol OCRE CLAIR = on passe), jamais la couleur seule (daltonien §1).
# Le sol ':' (détails traversables, balle 27) garde sa nuance via MOD_SOL_TEINTE par-dessus la texture.
const COL_SOL := Color(0.62, 0.47, 0.33)      # sol clair — encore utilisé pour la carte de choix d'accueil
const COL_LOGE := Color(0.80, 0.16, 0.13)     # croix rouge de la loge
const COL_ETIQ_LOGE := Color(0.98, 0.98, 0.96)  # étiquette SUR une loge : caractère BLANC (lisible sur le rouge), liseré sombre
const COL_TRAIT := Color(0.10, 0.08, 0.06)    # contours sombres
# (balle 52) COL_AVATAR / COL_ABEILLE / COL_MAIN retirés : avatars/curseur rendus par les VRAIES textures ci-dessous.

# AVATARS RÉELS CoccOs (balle 52) — PNG transparents importés depuis l'app CoccOs, remplacent les placeholders dessinés
# b49. Coccinelle/abeille = avatar EN JEU (choix 0/1) ; main/coccinelle/abeille = curseurs souris + aperçus d'accueil.
# (08-10) La coccinelle est AUSSI le curseur de l'ACCUEIL (deux plateformes) ; main/abeille ne servent qu'au choix PC.
const TEX_COCCINELLE := preload("res://scripts/pousse_pollen/textures/coccinelle.png")
const TEX_ABEILLE := preload("res://scripts/pousse_pollen/textures/abeille.png")
const TEX_MAIN := preload("res://scripts/pousse_pollen/textures/main.png")
# (08-10) PC ou tactile : le même test que les autres jeux CoccOs (réglage [interface] mode_tactile, coché sur Android).
const Tactile := preload("res://scripts/tactile.gd")
# (08-10) Prairie de fond + petites fleurs au clic de l'ACCUEIL : les pièces PARTAGÉES de CoccOs, reprises telles quelles.
const Fond := preload("res://scripts/fond.gd")
const FleurAccueil := preload("res://scripts/effets/fleur.gd")
const SonsAccueil := preload("res://scripts/effets/sons.gd")
const COULEURS_FLEURS: Array[Color] = [   # bureau.gd:COULEURS_FLEURS
	Color(1.0, 0.45, 0.7), Color(0.8, 0.5, 0.95), Color(0.5, 0.6, 1.0), Color(1.0, 0.6, 0.85),
]
const APPUI_FLEURS_INTERVALLE_MS := 120   # effets_clic.gd:DOIGT_INTERVALLE_MS — une rafale de tapes = une ronde
# Balle 59 — AVATAR « bras le long » (nouveaux persos Gemini détourés) : texture ENTIÈRE (accueil + ami-récompense)
# et PIÈCES cutout (core troué + 4 membres pleine toile) pour l'animation EN JEU. Générés par outils/detour_avatar_b59.py
# + outils/decoupe_membres_b59.py. ⚠ NE PAS confondre avec coccinelle.png/abeille.png (= CURSEURS doigt-levé, inchangés).
const TEX_AV_COCC := preload("res://scripts/pousse_pollen/textures/avatar_coccinelle.png")
const TEX_AV_ABEILLE := preload("res://scripts/pousse_pollen/textures/avatar_abeille.png")
const AV_CUTOUT := {
	0: {"core": preload("res://scripts/pousse_pollen/textures/av_cocc_core.png"),
		"brasG": preload("res://scripts/pousse_pollen/textures/av_cocc_brasG.png"),
		"brasD": preload("res://scripts/pousse_pollen/textures/av_cocc_brasD.png"),
		"jambeG": preload("res://scripts/pousse_pollen/textures/av_cocc_jambeG.png"),
		"jambeD": preload("res://scripts/pousse_pollen/textures/av_cocc_jambeD.png")},
	1: {"core": preload("res://scripts/pousse_pollen/textures/av_abeille_core.png"),
		"brasG": preload("res://scripts/pousse_pollen/textures/av_abeille_brasG.png"),
		"brasD": preload("res://scripts/pousse_pollen/textures/av_abeille_brasD.png"),
		"jambeG": preload("res://scripts/pousse_pollen/textures/av_abeille_jambeG.png"),
		"jambeD": preload("res://scripts/pousse_pollen/textures/av_abeille_jambeD.png")},
}
# HABILLAGE TERRAIN (balle 54) — textures Gemini : terre FONCÉE = murs/terre pleine, sol OCRE CLAIR = galeries
# praticables (distinction de LUMINANCE conservée, daltonien §1), boule de pollen détourée du fond blanc = sprite
# des boules. terre/sol sont ÉTALÉES sur toute la grille (draw_texture_rect_region, une part de texture par case) →
# pas de répétition, pas de couture (les images Gemini ne sont pas tuilables). pollen.png remplace le cercle doré.
const TEX_TERRE := preload("res://scripts/pousse_pollen/textures/terre.png")
const TEX_SOL := preload("res://scripts/pousse_pollen/textures/sol_galerie.png")
const TEX_POLLEN := preload("res://scripts/pousse_pollen/textures/pollen.png")

# Balle 71 — SONS cartoon (GDD §"Son", additif strict). 4 bruitages courts (banc d'essai Fabrice), un
# AudioStreamPlayer RÉUTILISABLE par événement (jamais empilé). Générés par outils/gen_sons_b71.py.
#   déplacement : « pop doux »           tirer   : « boing montant »
#   pousser     : « boing court »        victoire: « petite fanfare »
const SON_DEPLACEMENT := preload("res://scripts/pousse_pollen/audio/deplacement.wav")
const SON_POUSSER := preload("res://scripts/pousse_pollen/audio/pousser.wav")
const SON_TIRER := preload("res://scripts/pousse_pollen/audio/tirer.wav")
const SON_VICTOIRE := preload("res://scripts/pousse_pollen/audio/victoire.wav")
# Balle 72 — « boule bien placée » : gamme rapide montante (carré), jouée quand une boule devient NOUVELLEMENT
# bien appariée sur sa loge, sauf coup gagnant (la fanfare victoire prime). Additif strict.
const SON_PLACEE := preload("res://scripts/pousse_pollen/audio/boule_placee.wav")
# Réglage global (rejoint le code parental §4). SON_ACTIF coupe TOUT si false ; SON_VOLUME_DB = volume commun
# (dB, 0 = niveau nominal du .wav ; négatif = plus doux). Tous deux LUS avant chaque lecture (_jouer_son). Le
# branchement UI (bouton coupure) viendra plus tard : ici, le POINT de coupure est déjà propre.
const SON_ACTIF := true
const SON_VOLUME_DB := 0.0
# Balle 69 — FOND ENTIÈREMENT EN TERRE : _draw peint TEX_TERRE sur toute la fenêtre caméra visible, DERRIÈRE le
# plateau, avant les sols/murs → plus jamais de default_clear_color brun vide. On ÉTALE l'image entière (pas de
# répétition) sur le rectangle-monde visible : terre.png n'est PAS tuilable (balle 54) → l'étaler en UNE fois évite
# toute couture. FOND_MARGE agrandit un peu le rectangle (aucun liseré brun aux bords après arrondi). MOD_FOND_TERRE
# assombrit LÉGÈREMENT ce fond (luminance, daltonien §1) → la galerie éclairée du premier plan ressort. Dials à l'œil.
const MOD_FOND_TERRE := Color(0.72, 0.72, 0.72)    # teinte du fond de terre (1,1,1 = neutre ; plus bas = plus sombre / plus « profond »)
const FOND_MARGE := 2.0 * CELL                     # débord (px-monde) du fond au-delà de la fenêtre visible → 0 brun aux bords
# Teinte du sol ':' PAR-DESSUS la texture (modulate multiplicatif) : nuance AMBRE CHAUDE (harmonie FEU — balle 29
# a écarté le vert, qui jurait sur la palette + daltonisme). Reste CLAIRE = praticable (luminance haute), juste
# distincte du sol normal. Décoratif : jamais le seul repère (la praticabilité tient à la luminance — GDD §1).
const MOD_SOL_TEINTE := Color(1.0, 0.80, 0.50)
# Touches écran (flèches + Agripper). Libellé sombre sur fond clair = luminance, jamais la
# couleur seule (daltonien, GDD §1). La touche Agripper VIRE au doré tant qu'elle est TENUE :
# retour visuel du maintien (l'ancienne bascule montrait l'état enfoncé ; ici le maintien).
const COL_TOUCHE := Color(0.85, 0.78, 0.62)          # fond de touche au repos (sol clair)
const COL_TOUCHE_ACTIVE := Color(0.98, 0.88, 0.25)   # fond de l'Agripper tenu (doré, luminance ↑)

# Animation de victoire (balle 36, GDD §1 « aucun échec, récompense joyeuse ») : au moment de la victoire, un petit
# ÉCLAT de gouttelettes JAUNES (évoque le POLLEN) part du mot « Bravo ! » — le temps de SAVOURER — PUIS auto-passage
# au niveau suivant (ou écran de fin au N35). Rester LÉGER, pas envahissant. Jaune sur fond brun = contraste de
# LUMINANCE (jamais la teinte seule, daltonien GDD §1). Constante de durée ISOLÉE ci-dessous (ajustable).
const DUREE_SAVOURER_VICTOIRE_S := 1.6   # délai « Bravo ! » + éclat AVANT l'auto-passage (le temps de voir l'animation)
const GOUTTELETTES_NB := 28              # nombre de gouttelettes de l'éclat — volontairement modeste (léger)
const GOUTTELETTES_DUREE_S := 1.2        # durée de vie d'une gouttelette (< au délai → l'éclat s'achève avant le passage)
const COL_GOUTTELETTE := Color(0.98, 0.85, 0.25)   # jaune pollen doré (luminance ↑ nette sur le brun de fond)

# Récompense VARIÉE (balle 50, GDD §2.3 l.87 « fleurissement OU l'abeille amie qui revient remercier — câlin, petits
# cœurs qui s'allument »). À chaque victoire on ALTERNE deux scénarios positifs et calmes → variété (GDD §1) :
#   variante 0 = ÉCLAT DE POLLEN (b36, ci-dessus, comportement CONSERVÉ) ;
#   variante 1 = l'AMI (l'AUTRE personnage : abeille si l'avatar = coccinelle, coccinelle si l'avatar = abeille)
#               revient faire un câlin, avec de PETITS CŒURS qui s'ALLUMENT un à un.
# Dans les deux cas : court, calme, PUIS le MÊME auto-passage (b36 conservé, DUREE_SAVOURER_VICTOIRE_S).
# Effet RÉGLABLE/COUPABLE (GDD §1) : RECOMPENSE_EFFETS=false coupe TOUT effet (le « Bravo ! » + l'auto-passage
# restent, jeu jouable sans aucune animation). Visuels persos/cœurs = PLACEHOLDERS (habillage fin = roadmap §4bis).
const RECOMPENSE_EFFETS := true                    # false → aucun effet de récompense (Bravo ! + auto-passage seuls)
const COEURS_NB := 5                               # nombre de petits cœurs qui s'allument (variante « ami »)
const COL_COEUR := Color(0.93, 0.34, 0.42)         # rose-rouge tendre ; contour sombre + shape « cœur » = jamais la teinte seule (daltonien)

# Rythme DOUX de la variante « ami » (balle 58, retour test Fabrice : la récompense était « un peu rapide » →
# ADOUCIR / RALENTIR, esprit CALME GDD §1). L'ami arrive lentement en fondu + petit bond (courbe SINE douce) « prendre
# dans les bras » ; les cœurs s'allument un à un, RESTENT allumés un instant, puis s'estompent TOUS ensemble en un
# fondu de sortie LENT (avant, ils étaient coupés net au changement de niveau). Chaque durée est isolée/ajustable ici.
const AMI_FONDU_ENTREE_S := 0.6        # arrivée de l'ami en fondu (lente, douce)
const AMI_BOND_MONTEE_S := 0.6         # petit bond du câlin — montée (parallèle au fondu)
const AMI_BOND_RETOUR_S := 0.9         # redescente douce jusqu'à la position posée
const AMI_BOND_HAUTEUR := 16.0         # amplitude du petit bond (px) — volontairement modeste
const COEURS_APPARITION_DEBUT_S := 0.5 # instant du 1er cœur (après le début du câlin)
const COEURS_APPARITION_PAS_S := 0.20  # écart entre deux allumages → ils s'allument l'un après l'autre
const COEURS_FONDU_ENTREE_S := 0.34    # fondu + léger « pop » d'allumage d'un cœur
const COEURS_MAINTIEN_S := 2.2         # instant (depuis la victoire) où les cœurs COMMENCENT à s'estomper (ils RESTENT avant)
const COEURS_FONDU_SORTIE_S := 0.8     # disparition LENTE, tous ensemble (s'estompent doucement)
# Délais AVANT l'auto-passage, le temps de SAVOURER (le pollen b36 reste à 1.6 s ; l'ami+cœurs demandent plus de temps
# pour s'allumer, tenir puis s'estomper → délai propre, plus long — sans ralentir la variante pollen non critiquée).
const DUREE_SAVOURER_AMI_S := 3.2      # variante « ami » : couvre câlin + allumage + maintien + fondu de sortie

# COUCHE DÉCOR (balle 43) — peinture COSMÉTIQUE dans la TERRE (murs / fond), à résolution SOUS-CASE. Transpose aux
# MURS ce que fait le sol teinté ':' au sol : peindre un dessin fin SANS toucher la logique. Le décor n'altère NI
# terrain (#/./:/X), NI collision, NI solveurs, NI cadrage (_boite_contenu ignore les murs). Il est purement dessiné
# dans _draw() APRÈS le terrain (donc par-dessus le brun des murs) et AVANT les entités. Voir DECORS + _dessiner_decor().
# GARDE-FOU DALTONIEN : le décor reste NETTEMENT plus SOMBRE que le sol clair (luminance) → jamais lu « praticable ».
#   sol normal ≈0.49 · sol teinté ≈0.39 (CLAIRS = on passe) │ corps décor ≈0.37 · mur ≈0.24 · fond ≈0.19 (FONCÉS = terre).
# Le corps du décor est un cran AU-DESSUS du mur (visible comme forme) mais SOUS le sol (non praticable), avec un
# CONTOUR sombre (COL_TRAIT) qui fixe la SILHOUETTE (forme + luminance, jamais la teinte seule).
const COL_DECOR_CORPS := Color(0.46, 0.36, 0.27)   # chair du décor (escargot…) : terre chaude, ≈0.37 < sol → non praticable
const COL_DECOR_OEIL := Color(0.90, 0.72, 0.20)    # œil au bout de l'antenne (petit point doré, lecture « animal »)

# ── AVATAR EN JEU (balle 57) : le VRAI perso CoccOs (textures/coccinelle.png · abeille.png), le MÊME que le curseur —
# rendu tel quel par _dessiner_avatar (aucune couleur dessinée : la palette « articulé » b53 a été retirée).

# Grille de terrain STATIQUE : copie de NIVEAU_1 dont l'avatar ET les boules ont
# été retirés (leurs cases redeviennent le sol/loge qui les porte). L'avatar et
# les boules mobiles sont suivis à part, en coordonnées de cellule (Vector2i) —
# ainsi la loge 'X' reste connue MÊME quand une boule repose dessus (victoire).
# GDD §7 : « position en Vector2i ; vérifier la case cible AVANT de valider le pas. »
var _terrain: Array = []
# Foreshortening vertical EFFECTIF du niveau courant (balle 62). Vaut PLONGE_KY (0.52) partout, RELEVÉ par
# _cadrer_camera pour dé-écraser les tableaux larges-plats. RENDU (_draw & co) et CADRAGE (_fenetre_camera,
# _cadrage_ok, _centre_plonge) lisent CETTE valeur → cohérence garantie. Recalculé à chaque _cadrer_camera.
var _plonge_ky := PLONGE_KY
var _avatar := Vector2i.ZERO
var _boules: Array[Vector2i] = []
# Appariement boule↔loge (balle 17). Étiquettes en side-data pour NE PAS toucher le terrain (qui garde 'X'
# pour toute loge) ni la logique acquise. Vides sur les niveaux non étiquetés → victoire d'origine conservée.
#   _boules_etiquette : étiquette de chaque boule, PARALLÈLE à _boules (même index) ; "" = boule sans étiquette.
#   _loges_etiquette  : Vector2i (case de loge) → étiquette ; absente = loge sans étiquette.
#   _niveau_apparie   : true si le niveau courant porte au moins une étiquette (loge ou boule) → victoire TYPÉE.
var _boules_etiquette: Array[String] = []
var _loges_etiquette := {}
var _niveau_apparie := false
# Tirage au hasard des symboles affichés (balle 24) : clé d'appariement (lettre MAJ de la grille) → symbole
# affiché (chiffre ou lettre). Régénéré à chaque _charger_niveau → un même niveau peut changer de symboles
# d'une visite à l'autre. Boule et loge d'une même clé lisent la MÊME entrée → même symbole.
var _etiquettes_niveau := {}
var _a_gagne := false                          # partie gagnée : on fige en douceur (pas de game over)
var _niveau_courant := 0                        # index dans NIVEAUX du tableau actuellement chargé (0 = N1)

# Navigation de niveau (balle 34, GDD §2.3 « Liberté » — remplace le sélecteur b16 : navigation auto-explicative).
#   _niveau_max_atteint: plus haut index DÉBLOQUÉ (persisté sur DISQUE, balle 25 : _charger/_sauver_progression).
#                        Départ = 0 (N1 seul). À chaque victoire : max(_, _niveau_courant + 1), borné à N35.
#                        Conditionne l'apparition de la flèche ► (jamais un niveau non débloqué ; pas de triche).
var _niveau_max_atteint := 0

# Agripper — sert UNIQUEMENT à TIRER (le pousser reste libre, acquis balle 3).
# Deux sources d'un même état « agripper actif », toutes deux en MAINTIEN (balle 6) :
#   _agripper_touche : barre espace MAINTENUE (PC) — vrai maintien tant que la touche est enfoncée.
#   _agripper_bouton : TouchScreenButton MAINTENU (tactile/pointeur) — actif de `pressed` à
#     `released`. Multitouch natif → on peut le tenir d'un doigt et actionner une flèche de l'autre.
var _agripper_touche := false
var _agripper_bouton := false

# Références gardées pour piloter l'UI après coup :
#   _visuel_gauche  : le VISUEL de la flèche écran GAUCHE (ColorRect), celui que le guide fait pulser.
#   _visuel_agripper: le VISUEL de l'Agripper (ColorRect), viré au doré tant que la touche est tenue.
#   _couche_reussite: le CanvasLayer « Bravo ! », retiré quand on rejoue après victoire.
#   _guide_tween    : l'animation de pulsation du guide (tuée dès le premier geste).
var _visuel_gauche: Control = null
var _visuel_bas: Control = null                # flèche BAS : pulsée par le guide du tirer (N4)
var _visuel_agripper: ColorRect = null
var _couche_reussite: CanvasLayer = null
var _couche_fin: CanvasLayer = null            # écran de fin / félicitations après le dernier niveau (balle 24)
# Balle 71 — un AudioStreamPlayer RÉUTILISABLE par son (créés dans _ready, joués par _jouer_son). Réutilisés →
# jamais d'empilement d'instances. Clé = même identité que la constante SON_* correspondante.
var _lecteurs_son: Dictionary = {}
var _guide_tween: Tween = null

# Guide du TIRER (N4) : pulse l'Agripper + la flèche bas quand l'avatar est sous une boule.
#   _guide_tirer_tween  : l'animation de pulsation (tuée quand l'indice n'a plus lieu d'être).
#   _deja_deplace       : l'avatar a bougé au moins une fois → n'affiche pas le guide au tout départ
#                         (l'avatar y démarre déjà sous la boule du haut) ; réarmé par « Recommencer ».
var _guide_tirer_tween: Tween = null
var _deja_deplace := false
var _recompense_variante := 0   # balle 50 : alterne 0 (pollen) / 1 (ami + cœurs) à chaque victoire → variété (GDD §2.3 l.87)

# Annonce « Niveau difficile » (balle 11, GDD §2.3 « pic annoncé tous les 5 niveaux »). Bandeau UI
# calme affiché à l'entrée d'un niveau « pic » (index dans NIVEAUX_PIC), effacé après un court instant
# OU au premier geste. Aucune mécanique de jeu — comme le « Bravo ! », c'est un CanvasLayer par-dessus.
#   _couche_pic : le CanvasLayer du bandeau (retiré en quittant le pic / au 1ᵉʳ geste / au fondu).
#   _pic_tween  : l'animation d'auto-fondu (tuée si on efface avant la fin).
var _couche_pic: CanvasLayer = null
var _pic_tween: Tween = null

# Numéro de niveau affiché (balle 18, GDD §2.3 « AJUSTEMENTS POST-TEST #2 »). Label « Niveau N » en
# HAUT-DROITE (zone libre : au-dessus du bandeau, à droite du Recommencer, jamais sur le plateau ni un
# bouton). Reflète _niveau_courant → suit le niveau chargé, y compris après une navigation ◄/► (balle 34).
var _label_niveau: Label = null

# Flèches de NAVIGATION de NIVEAU (balle 34). Deux Button (Control → show/hide immédiat par .visible) sous le
# label « Niveau N » (haut-droite). ◄ (précédent) cachée au N1 ; ► (suivant) visible seulement si débloqué.
# _maj_fleches_navigation() règle leur visibilité selon _niveau_courant et _niveau_max_atteint.
var _btn_niveau_prec: Button = null
var _btn_niveau_suiv: Button = null

# Anti-rebond de la navigation (balle 35). _niveau_vise = index CIBLE affiché par le numéro « Niveau N » (ce que
# les clics ◄/► font défiler) ; il n'est PAS forcément chargé. _niveau_courant reste le niveau réellement JOUÉ
# tant que le minuteur n'a pas expiré. Au repos, _niveau_vise == _niveau_courant. _timer_nav (one-shot) est
# (re)démarré à chaque clic ; à son timeout on charge enfin _niveau_vise (cf. _naviguer_vise / _sur_timer_nav).
var _niveau_vise := 0
var _timer_nav: Timer = null

# ÉCRAN D'ACCUEIL + CHOIX D'AVATAR / CURSEUR (balle 49, GDD §2.3 l.60 / l.72 ; curseur : PC SEULEMENT depuis le 08-10).
# Au lancement, l'enfant choisit son avatar (coccinelle/abeille) et, sur PC, son curseur (main gantée/coccinelle/abeille)
# AVANT d'entrer dans le jeu. Choix
# MÉMORISÉ (user://pousse_pollen_progression.cfg, section "choix") et ré-modifiable (bouton « Accueil » en jeu). Visuels =
# PLACEHOLDERS fonctionnels distincts, daltonien-safe (forme + luminance, pas la couleur seule) ; rendu fin = roadmap.
var _avatar_type := 0          # 0 = coccinelle (défaut, l'avatar actuel) · 1 = abeille (placeholder jaune/noir)
var _curseur_type := 0         # 0 = main gantée · 1 = coccinelle · 2 = abeille (PC seulement)
var _curseur_pc := true        # (08-10) vrai hors mode tactile → choix de curseur + curseur en jeu (posé dans _ready)
var curseur_pose := ""         # (08-10) curseur réellement posé, lu par la preuve : "accueil" · "jeu:<type>" · "systeme"
var _en_accueil := false       # vrai tant que l'écran d'accueil est affiché → bloque l'entrée de jeu (clavier)
var _couche_accueil: CanvasLayer = null
var _couches_jeu: Array[CanvasLayer] = []            # couches d'UI de jeu (D-pad, Agripper, Recommencer, label, nav, Accueil) — masquées pendant l'accueil
var _surbrillance_avatar: Array[ColorRect] = []      # liseré de sélection des 2 cases avatar (mis à jour au choix)
var _surbrillance_curseur: Array[ColorRect] = []     # liseré de sélection des 3 cases curseur (PC)
var _calque_fleurs_accueil: Node2D = null          # (08-10) fleurs du clic — DANS la couche d'accueil (libéré avec elle)
var _lecteur_fleurs_accueil: AudioStreamPlayer = null
var _dernier_appui_fleurs := -100000
var fleurs_accueil_posees := 0                      # (08-10) compteur lu par la preuve

# ── AVATAR ANIMÉ (balle 57) — animation GLOBALE et simple du VRAI perso (aucun découpage en membres, cf. b53 retiré).
# Chaque geste discret (marche/pousse/tire) allume un état pendant AVATAR_DUREE_GESTE ; _dessiner_avatar en tire une
# petite impulsion (bob vertical en marche, avancée-penchée vers la boule en poussée, appui-recul en tirage) qui monte
# puis redescend. À l'expiration du timer, retour AU REPOS (perso statique, centré). _process redemande le rendu tant
# que le geste dure.
const ETAT_REPOS := 0
const ETAT_MARCHE := 1
const ETAT_POUSSE := 2
const ETAT_TIRE := 3
const AVATAR_DUREE_GESTE := 0.34     # durée (s) de l'impulsion d'un pas/poussée/tirage avant retour au repos
var _avatar_etat := ETAT_REPOS       # état d'animation courant
var _avatar_geste_dir := Vector2i.DOWN  # direction du dernier geste (oriente l'impulsion vers/contre la boule)
var _avatar_reste := 0.0             # temps restant (s) dans l'état animé ; à 0 → retour au repos
var _avatar_pas := 0                 # balle 59 : compteur de pas → alterne quelle jambe/bras avance (marche)

# ── CUTOUT (balle 59) — pivots (point d'attache de chaque membre, en FRACTION de l'image fittée) + amplitudes de
# rotation (rad) atteintes au sommet du pulse. Mesurés sur les persos détourés (canevas commun 953×1120). Réglables.
const PIV_BRAS_G := Vector2(0.15, 0.575)    # épaule gauche (attache du bras gauche)
const PIV_BRAS_D := Vector2(0.85, 0.575)    # épaule droite
const PIV_JAMBE_G := Vector2(0.37, 0.85)    # hanche gauche
const PIV_JAMBE_D := Vector2(0.63, 0.85)    # hanche droite
const JAMBE_SWING := 0.30            # amplitude du pas des jambes en marche (rad)
const BRAS_REACH := 0.46             # rotation des bras qui tendent les mains vers la boule (pousse/tire)
const AV_BOB := 0.06                 # bob vertical du corps en marche (fraction de CELL)
const AV_LEAN := 0.11                # penché du corps vers/contre la boule (fraction de CELL)
# Balle 61 (retour test Fabrice) : ce sont les PIEDS qui doivent être posés au CENTRE de la case (pas le centre
# géométrique du sprite) → l'avatar « circule » dans le couloir et son corps/tête DÉBORDE vers le haut, par-dessus
# le terrain (il est dessiné en dernier). AV_PIEDS_FRAC = hauteur des pieds mesurée sur le core détouré (contenu bas
# ≈ 0,90 de la toile 953×1120). On remonte donc le sprite de (AV_PIEDS_FRAC−0,5)·hauteur.
const AV_PIEDS_FRAC := 0.90
# (21-10, REQ_pousse_avatar_decapite_android) ENVELOPPE de l'avatar autour du CENTRE de son sprite, en fraction de sa
# HAUTEUR dessinée (dim.y) — mesurée sur les PNG détourés (alpha > 8) avec les membres TOURNÉS à leur amplitude max
# (bras BRAS_REACH + BRAS_BAL_MAX, jambes JAMBE_SWING) : ±0,573/0,580 en X, -0,500/+0,506 en Y → arrondi au-dessus.
# Le cadrage (_cadrage_ok) garde cette enveloppe (+ penché AV_LEAN) DANS l'écran pour CHAQUE case praticable : la tête
# (qui déborde de la case vers le haut, ancrage pieds b61) n'est plus coupée par le bord, sur Android comme sur PC.
const AV_ENV_X := 0.59
const AV_ENV_HAUT := 0.50
const AV_ENV_BAS := 0.51
# ── BALANCEMENT DES BRAS = PENDULE AMORTI (balle 61) — même ressort que le flotteur des boules (b56) : à chaque
# geste on injecte une impulsion, les bras balancent puis se stabilisent en douceur (2-3 oscillations). Amplitude
# MARQUÉE (grief test : « ils bougent à peine »). État GLOBAL (un seul avatar). Bras opposés (démarche naturelle).
const BRAS_BAL_RAIDEUR := 36.0       # ressort k (rad/s²) → ω≈6, période ≈1,05 s (balancement ample, lisible)
const BRAS_BAL_AMORTI := 2.4         # amortissement c (ζ≈0,20, sous-amorti) → 2-3 balancements VISIBLES puis calme
const BRAS_BAL_IMPULSION := 3.8      # vitesse angulaire (rad/s) injectée à chaque geste → pic ≈0,6 rad (~34°)
const BRAS_BAL_MAX := 0.75           # borne d'amplitude (~43°) → geste franc mais bras jamais à l'horizontale grotesque
const BRAS_BAL_SEUIL := 0.004        # sous ce seuil (angle ET vitesse) → bras au repos (collés le long, nets)
var _bras_bal := 0.0                 # angle courant du balancement (rad) ; 0 = bras le long
var _bras_bal_vit := 0.0             # vitesse angulaire du balancement (ressort amorti)

# ── BOULE ROULANTE + FLOTTEUR (balle 56, GDD §4bis) — animation PUREMENT visuelle (la logique reste une grille).
# Quand une boule est poussée/tirée elle donne l'impression de ROULER : sa texture (pollen.png) tourne dans le sens
# du déplacement. L'ÉTIQUETTE, elle, n'est PAS solidaire du roulement : elle se comporte comme un FLOTTEUR sur un
# liquide enfermé dans la sphère → pendant le mouvement elle oscille légèrement (inertie), à l'arrêt elle revient à
# la verticale par un balancement AMORTI (ressort → 0). Toujours droite et lisible à l'arrêt. AUCUNE eau dessinée.
# État PARALLÈLE à _boules (même index), réinitialisé à chaque niveau (_charger_niveau).
const ROULE_DUREE := 0.34            # durée (s) du roulement d'une case (aligné sur AVATAR_DUREE_GESTE = geste)
const ROULE_PAR_CASE := 2.4          # rotation (rad) de la texture par case franchie (~137°, roulement bien visible)
const FLOT_RAIDEUR := 48.0           # ressort du flotteur : raideur k (rad/s²) → rappel vers la verticale (ω≈6,9 rad/s, T≈0,9 s)
const FLOT_AMORTI := 3.4             # ressort du flotteur : amortissement c (ζ≈0,25, sous-amorti) → 2-3 balancements VISIBLES puis calme
const FLOT_IMPULSION := 2.6          # vitesse angulaire (rad/s) injectée au flotteur au départ d'un mouvement (inertie)
const FLOT_MAX := 0.30               # borne d'inclinaison du flotteur (~17°) → l'étiquette reste toujours lisible
const FLOT_SEUIL := 0.004            # angle/vitesse sous lesquels le flotteur est considéré « au repos » (collé vertical)
var _boules_roule: Array[float] = []       # rotation AFFICHÉE de la texture (accumulée)
var _boules_roule_reste: Array[float] = [] # temps restant (s) du roulement en cours ; 0 = immobile
var _boules_roule_de: Array[float] = []    # angle de départ du roulement en cours
var _boules_roule_a: Array[float] = []     # angle cible du roulement en cours
var _boules_flot: Array[float] = []        # angle du flotteur (étiquette) ; 0 = verticale
var _boules_flot_vit: Array[float] = []    # vitesse angulaire du flotteur (pour le ressort amorti)

@onready var _cam: Camera2D = $Camera2D

func _ready() -> void:
	_curseur_pc = not Tactile.actif()  # (08-10) choix de curseur + curseur en jeu : PC seulement (avant l'UI qui en dépend)
	randomize()                        # graine aléatoire → étiquettes tirées au hasard varient d'une session à l'autre (balle 24)
	_construire_lecteurs_son()         # balle 71 : un AudioStreamPlayer réutilisable par bruitage
	_maj_ecran()                       # (21-10) écran visible RÉEL, avant l'UI ancrée et le premier cadrage
	get_viewport().size_changed.connect(_sur_taille_ecran)
	_construire_fleches_ecran()
	_construire_bouton_agripper()
	_construire_bouton_recommencer()
	_construire_label_niveau()
	_creer_bouton_quitter_coccos()
	_construire_fleches_navigation()   # balle 34 : les 2 flèches ◄/► de navigation de niveau (haut-droite)
	_construire_bouton_accueil()       # balle 49 : bouton « Accueil » (retour au choix avatar/curseur, top-centre)
	_charger_progression()             # balle 25 : recharge le plus haut niveau atteint (disque) → tout est débloqué
	_charger_choix()                   # balle 49 : recharge l'avatar + le curseur (PC) choisis (disque, même fichier)
	# Au lancement, on charge N1 en JEU (balle 34 : plus de mode sélection). La progression rechargée ci-dessus
	# donne accès à TOUT [N1 … max atteint] par les flèches ◄/► (plus besoin de rejouer). Le guide tutoriel N1
	# est (re)lancé par _aller_a_niveau si c'est le N1.
	_aller_a_niveau(0)
	# balle 49 : l'écran d'ACCUEIL s'affiche PAR-DESSUS le jeu déjà chargé (choix d'avatar). « Jouer » le retire.
	_afficher_accueil()

# Anime l'avatar (balle 57) UNIQUEMENT pendant un geste : décompte _avatar_reste et redemande le rendu tant qu'il
# est > 0 (_dessiner_avatar en tire l'impulsion). Au bout de AVATAR_DUREE_GESTE, retour au REPOS (statique) →
# plus aucun redraw (calme, GDD §1 : l'animation ne tourne pas en permanence, elle accompagne le geste).
func _process(delta: float) -> void:
	var actif := false
	if _avatar_reste > 0.0:
		_avatar_reste -= delta
		if _avatar_reste <= 0.0:
			_avatar_reste = 0.0
			_avatar_etat = ETAT_REPOS
		actif = true
	# Balle 56 : le roulement des boules et le balancement amorti des flotteurs tournent APRÈS le geste (le
	# flotteur se calme sur ~1 s) → on redemande le rendu tant qu'au moins une boule bouge encore.
	if _animer_pollen(delta):
		actif = true
	if actif:
		queue_redraw()

# Balle 56 — fait avancer d'un pas (delta s) le roulement des textures et le ressort amorti des flotteurs.
# Renvoie true tant qu'au moins une boule est encore en mouvement (→ _process continue de redessiner). Au repos,
# rien ne tourne (calme, GDD §1 : l'animation accompagne le geste puis s'éteint).
func _animer_pollen(delta: float) -> bool:
	var actif := false
	for i in _boules.size():
		if i >= _boules_roule.size():
			continue                                   # sécurité (arrays parallèles toujours dimensionnés en _charger_niveau)
		# Roulement de la texture : interpolation ease-out de l'angle de départ vers la cible sur ROULE_DUREE.
		if _boules_roule_reste[i] > 0.0:
			_boules_roule_reste[i] -= delta
			var t := clampf(1.0 - _boules_roule_reste[i] / ROULE_DUREE, 0.0, 1.0)
			var e := 1.0 - pow(1.0 - t, 3.0)           # ease-out cubique : départ franc, arrivée douce (roule puis se pose)
			_boules_roule[i] = lerpf(_boules_roule_de[i], _boules_roule_a[i], e)
			if _boules_roule_reste[i] <= 0.0:
				_boules_roule_reste[i] = 0.0
				_boules_roule[i] = _boules_roule_a[i]
			actif = true
		# Flotteur (étiquette) : ressort amorti vers la verticale (θ'' = -k·θ - c·θ'). Sous-amorti → il oscille
		# quelques allers-retours puis se colle à 0 (droit, lisible). NE dépend PAS du roulement de la texture.
		var ang := _boules_flot[i]
		var vit := _boules_flot_vit[i]
		if absf(ang) > FLOT_SEUIL or absf(vit) > FLOT_SEUIL:
			vit += (-FLOT_RAIDEUR * ang - FLOT_AMORTI * vit) * delta
			ang += vit * delta
			ang = clampf(ang, -FLOT_MAX, FLOT_MAX)
			_boules_flot[i] = ang
			_boules_flot_vit[i] = vit
			actif = true
		elif ang != 0.0 or vit != 0.0:
			_boules_flot[i] = 0.0                       # sous le seuil → collé à la verticale (repos net)
			_boules_flot_vit[i] = 0.0
	# Balle 61 — PENDULE des bras de l'avatar (même ressort amorti que le flotteur) : θ'' = -k·θ - c·θ'. Injecté
	# à chaque geste, il balance puis revient au repos (bras le long). Dure plus longtemps que le geste → tenu actif ici.
	if absf(_bras_bal) > BRAS_BAL_SEUIL or absf(_bras_bal_vit) > BRAS_BAL_SEUIL:
		_bras_bal_vit += (-BRAS_BAL_RAIDEUR * _bras_bal - BRAS_BAL_AMORTI * _bras_bal_vit) * delta
		_bras_bal += _bras_bal_vit * delta
		_bras_bal = clampf(_bras_bal, -BRAS_BAL_MAX, BRAS_BAL_MAX)
		actif = true
	elif _bras_bal != 0.0 or _bras_bal_vit != 0.0:
		_bras_bal = 0.0                                 # sous le seuil → bras collés le long (repos net)
		_bras_bal_vit = 0.0
	return actif

# Balle 56 — déclenche le roulement d'une case pour la boule i dans le sens `direction` (appelé au moment EXACT
# où une poussée/un tirage la déplace). La texture tourne dans le sens du déplacement ; le flotteur reçoit une
# impulsion d'inertie (le haut du flotteur retarde à l'horizontale ; léger balancement à la verticale).
func _declencher_roulement(i: int, direction: Vector2i) -> void:
	if i < 0 or i >= _boules_roule.size():
		return
	# Balle 61 — SENS DE ROULEMENT cohérent avec la direction (grief test : « toutes tournaient dans le même sens »).
	# On rend le roulement par une rotation z du sprite (vue plongée quasi de dessus). Convention « roue » :
	#   • DROITE → horaire (+), GAUCHE → anti-horaire (−) : lecture directe d'un ballon qui roule.
	#   • DESCENDRE → anti-horaire (−), MONTER → horaire (+) : sens OPPOSÉ à l'horizontale → les 4 directions
	#     donnent 4 comportements distincts (plus « toutes pareilles »). ⚠ Une rotation z ne peut pas rendre un vrai
	#     roulement vertical (physiquement 0 spin vu de dessus) : choix ARTISTIQUE assumé, cohérence de sens garantie.
	var sens := float(signi(direction.x)) if direction.x != 0 else -float(signi(direction.y))
	_boules_roule_de[i] = _boules_roule[i]
	_boules_roule_a[i] = _boules_roule[i] + ROULE_PAR_CASE * sens
	_boules_roule_reste[i] = ROULE_DUREE
	var imp := -float(signi(direction.x)) if direction.x != 0 else float(signi(direction.y))
	_boules_flot_vit[i] += FLOT_IMPULSION * imp

# Allume l'état d'animation d'un geste (marche/pousse/tire) et mémorise sa direction. Appelé au moment EXACT où
# un déplacement/poussée/tirage RÉUSSIT (une seule source par mécanique). _dessiner_avatar en tire une petite
# impulsion GLOBALE orientée par `direction` (vers la boule en poussée/marche, à l'opposé en tirage).
func _declencher_geste(etat: int, direction: Vector2i) -> void:
	_avatar_etat = etat
	_avatar_geste_dir = direction
	_avatar_reste = AVATAR_DUREE_GESTE
	_avatar_pas += 1                     # balle 59 : chaque geste = un pas → alterne la jambe/le bras qui avance
	# Balle 61 : impulsion au PENDULE des bras (ressort amorti) à chaque PAS de MARCHE, alternée → démarche
	# naturelle. Le balancement dure ~1 s (au-delà du geste 0,34 s) puis se stabilise, comme le flotteur des boules
	# b56. POUSSE/TIRE gardent leur pose « mains vers la boule » (lisibilité) → pas d'impulsion, pas de bras qui fouette.
	if etat == ETAT_MARCHE:
		var s := 1.0 if (_avatar_pas % 2 == 0) else -1.0
		_bras_bal_vit += BRAS_BAL_IMPULSION * s

# Sépare le terrain statique de l'avatar et des boules mobiles, pour le niveau courant
# (NIVEAUX[_niveau_courant]). Généralisé en balle 7 : l'ancien N1 en dur devient l'index 0.
func _charger_niveau() -> void:
	_terrain = []
	_boules = []
	_boules_etiquette = []
	_loges_etiquette = {}
	var grille: Array = NIVEAUX[_niveau_courant]
	# Pré-passe : collecter les CLÉS d'appariement présentes (lettre MAJ), puis tirer au hasard leur symbole
	# affiché (balle 24). Fait AVANT le parsing pour que boule et loge d'une même clé lisent le même tirage.
	var cles: Array = []
	for ligne_p in grille:
		for x_p in (ligne_p as String).length():
			var g_p: String = (ligne_p as String)[x_p]
			var cle_p := ""
			if g_p >= "a" and g_p <= "z":
				cle_p = g_p.to_upper()
			elif g_p >= "A" and g_p <= "Z":
				cle_p = g_p
			if cle_p != "" and not cles.has(cle_p):
				cles.append(cle_p)
	_etiquettes_niveau = _generer_etiquettes(cles, TUTO_SYMBOLES.get(_niveau_courant, "mix"))
	for y in grille.size():
		var ligne: String = grille[y]
		var terrain_ligne := ""
		for x in ligne.length():
			var glyphe := ligne[x]
			match glyphe:
				"@":
					_avatar = Vector2i(x, y)
					terrain_ligne += "."     # sous l'avatar : du sol
				"+":
					_avatar = Vector2i(x, y)
					terrain_ligne += "X"     # avatar posé sur une loge (N4) : la croix reste dans le terrain, cachée tant qu'il est dessus
				"O":
					_boules.append(Vector2i(x, y))
					_boules_etiquette.append("")   # boule sans étiquette (victoire d'origine)
					terrain_ligne += "."     # sous la boule : du sol (aucune boule ne démarre sur une loge, N1→N3)
				"X":
					terrain_ligne += "X"     # loge sans étiquette
				"#", ".", ":":
					terrain_ligne += glyphe   # ':' = sol teinté (balle 27) : recopié tel quel → praticable comme '.', peint en vert clair
				_:
					# Étiquette (balle 17, étendue balle 21) : lettre MINUSCULE = boule ; MAJUSCULE = loge ;
					# la LETTRE (majuscule) est la CLÉ d'appariement. Le SYMBOLE affiché dérive de cette clé via
					# _etiquette_affichee → tirage au hasard (balle 24, _generer_etiquettes) mêlant chiffres et
					# lettres : boule et loge de la MÊME clé lisent le même tirage → affichent le MÊME symbole.
					if glyphe >= "a" and glyphe <= "z":
						_boules.append(Vector2i(x, y))
						_boules_etiquette.append(_etiquette_affichee(glyphe.to_upper()))
						terrain_ligne += "."     # sous la boule étiquetée : du sol
					elif glyphe >= "A" and glyphe <= "Z":
						_loges_etiquette[Vector2i(x, y)] = _etiquette_affichee(glyphe)
						terrain_ligne += "X"     # loge étiquetée : le terrain garde 'X', l'étiquette est en side-data
					else:
						terrain_ligne += glyphe   # glyphe inconnu : recopié tel quel (robustesse)
		_terrain.append(terrain_ligne)
	# Niveau ÉTIQUETÉ si au moins une loge ou une boule porte une étiquette → victoire TYPÉE (sinon victoire d'origine).
	_niveau_apparie = not _loges_etiquette.is_empty()
	for e in _boules_etiquette:
		if e != "":
			_niveau_apparie = true
			break
	# Balle 56 : réinitialise l'état d'animation (roulement + flotteur) PARALLÈLE à _boules → boules figées et
	# étiquettes verticales au chargement (aucune animation résiduelle d'un niveau à l'autre).
	var n := _boules.size()
	_boules_roule = []; _boules_roule_reste = []; _boules_roule_de = []; _boules_roule_a = []
	_boules_flot = []; _boules_flot_vit = []
	for _i in n:
		_boules_roule.append(0.0); _boules_roule_reste.append(0.0)
		_boules_roule_de.append(0.0); _boules_roule_a.append(0.0)
		_boules_flot.append(0.0); _boules_flot_vit.append(0.0)
	_maj_label_niveau()   # « Niveau N » suit _niveau_courant (balle 18)
	_maj_fleches_navigation()   # ◄/► ajustées au niveau courant et au débloqué (balle 34)

# Étiquette AFFICHÉE d'une clé d'appariement (balle 24 : tirage au hasard). La clé est une lettre MAJUSCULE
# ("A".."Z", donnée par l'encodage grille). On renvoie le symbole tiré au hasard pour cette clé (rempli par
# _generer_etiquettes au chargement). Boule et loge d'une même clé passent par ici → même symbole → appariement
# lisible et victoire typée (comparaison des étiquettes affichées, identiques) intacte. Repli sur la clé si
# absente (robustesse — ne devrait pas arriver, la pré-passe collecte toutes les clés).
func _etiquette_affichee(cle_maj: String) -> String:
	return _etiquettes_niveau.get(cle_maj, cle_maj)

# Tire au hasard un symbole affiché DISTINCT pour chaque clé d'appariement (balle 24). Les symboles ne suivent
# plus la suite (1-2-3 / A-B-C) et, en mode "mix", MÊLENT chiffres ET lettres : dès 2 clés, on garantit AU MOINS
# un chiffre ET au moins une lettre (le reste réparti au hasard), puis on mélange l'affectation aux clés. Symboles
# distincts (pas deux clés avec le même) → l'enfant distingue chaque paire boule↔loge. Pools épurés (peu de confusables).
# TUTO ÉVOLUTIF (balle 40) : le paramètre `mode` restreint le pool pour introduire l'appariement pas à pas —
#   • "chiffres" : tous les symboles tirés dans POOL_CHIFFRES (N6/N7) ;
#   • "lettres"  : tous dans POOL_LETTRES (N8) ;
#   • "impose" (N9, balle 44 « écris ton prénom ») : AUCUN tirage — chaque clé s'affiche TELLE QUELLE (la lettre du
#     prénom, ex. PRENOM_DEFAUT). Les doublons (2×A, 2×L) → même clé → même symbole affiché → croix interchangeables.
#   • "mix" (DÉFAUT, N10 et tout N11-N35) : comportement d'origine INCHANGÉ (au moins 1 chiffre ET 1 lettre dès 2 clés).
func _generer_etiquettes(cles: Array, mode: String = "mix") -> Dictionary:
	var map := {}
	var n := cles.size()
	if n == 0:
		return map
	if mode == "impose":
		for cle in cles:
			map[cle] = cle                                # mot imposé : la lettre-clé EST le symbole affiché (pas de tirage)
		return map
	var chiffres := POOL_CHIFFRES.duplicate()
	var lettres := POOL_LETTRES.duplicate()
	chiffres.shuffle()
	lettres.shuffle()
	var symboles: Array = []
	if mode == "chiffres":
		for i in n:
			symboles.append(chiffres[i])              # pool restreint aux chiffres (tuto N6/N7)
	elif mode == "lettres":
		for i in n:
			symboles.append(lettres[i])               # pool restreint aux lettres (tuto N8)
	elif n == 1:
		# mode "mix", une seule clé : chiffre OU lettre au hasard
		symboles.append(chiffres[0] if (randi() % 2 == 0) else lettres[0])
	else:
		# mode "mix", ≥ 2 clés : au moins 1 chiffre ET au moins 1 lettre ; le reste réparti au hasard
		var nb_chiffres := randi_range(1, n - 1)
		for i in nb_chiffres:
			symboles.append(chiffres[i])
		for i in (n - nb_chiffres):
			symboles.append(lettres[i])
	symboles.shuffle()
	for i in n:
		map[cles[i]] = symboles[i]
	return map

func _colonnes() -> int:
	return (NIVEAUX[_niveau_courant][0] as String).length()

func _lignes() -> int:
	return (NIVEAUX[_niveau_courant] as Array).size()

# Bornes (en cellules) du CONTENU VISIBLE = toutes les cases ≠ '#'. Les murs de bordure ('#') sont
# désormais texturés (terre, balle 54) mais restent EXCLUS du cadrage : on cadre sur le contenu praticable,
# pas sur la grille brute : une bordure de murs qui glisse sous un bouton (couvert par le bouton opaque) ne gêne pas.
func _boite_contenu() -> Rect2:
	var x0 := 1 << 30 ; var y0 := 1 << 30 ; var x1 := -1 ; var y1 := -1
	for y in _terrain.size():
		var ligne: String = _terrain[y]
		for x in ligne.length():
			if ligne[x] != "#":
				x0 = mini(x0, x) ; y0 = mini(y0, y)
				x1 = maxi(x1, x + 1) ; y1 = maxi(y1, y + 1)
	if x1 < 0:                                          # aucun contenu (cas dégénéré) → toute la grille
		return Rect2(0, 0, _colonnes(), _lignes())
	return Rect2(x0, y0, x1 - x0, y1 - y0)

# Rectangles ÉCRAN des boutons PERMANENTS qu'une case praticable ne doit JAMAIS recouvrir (balle 28, ÉTENDU b30).
# Source UNIQUE, partagée avec les constructeurs de boutons. Les QUATRE boutons permanents y figurent : les deux
# du HAUT (Recommencer haut-gauche, indicateur « Niveau N » haut-droite — balle 30) ET les deux du BAS (Agripper
# bas-gauche, D-pad bas-droite). Le D-pad est pris par sa BOÎTE ENGLOBANTE (croix → carré) : conservateur, mais
# il est en bas-droite où réserver les 4 coins vides de la croix ne coûte rien. Les quatre boutons occupent les
# QUATRE COINS → ils laissent libres le centre-haut (le tunnel y monte) et le centre-bas.
# Le bandeau « Niveau difficile » est TRANSITOIRE → volontairement ABSENT (il peut couvrir brièvement le haut).
func _rects_boutons() -> Array[Rect2]:
	# Les flèches ◄/► (balle 34) sont réservées MÊME quand elles sont cachées (◄ au N1, ► si non débloqué) →
	# le cadrage reste DÉTERMINISTE (il ne varie pas selon la visibilité) : coin haut-droite stable, non-régression.
	var hd := _decalage_ancre(ANCRE_HD)                # (21-10) chaque contrôle suit SON coin de l'écran réel
	var bg := _decalage_ancre(ANCRE_BG)
	var bd := _decalage_ancre(ANCRE_BD)
	var rects: Array[Rect2] = [
		Rect2(RECOMMENCER_POS, RECOMMENCER_TAILLE),                                   # ZONE haut-gauche (Recommencer + Accueil empilés, balle 49) — INCHANGÉE
		Rect2(LABEL_NIVEAU_POS + hd, LABEL_NIVEAU_TAILLE),
		Rect2(CROIX_COCCOS_POS + hd, CROIX_COCCOS_TAILLE),  # croix de fermeture CoccOs                                 # numéro « N » (haut-droite, milieu de « ◄ N ► », b63)
		Rect2(NAV_PREC_CENTRE - NAV_TAILLE * 0.5 + hd, NAV_TAILLE),                        # flèche ◄ navigation (haut-droite, à gauche du numéro, b63)
		Rect2(NAV_SUIV_CENTRE - NAV_TAILLE * 0.5 + hd, NAV_TAILLE),                        # flèche ► navigation (haut-droite, à droite du numéro, b63)
		Rect2(AGRIPPER_CENTRE - AGRIPPER_TAILLE * 0.5 + bg, AGRIPPER_TAILLE),              # Agripper (bas-gauche)
		Rect2(Vector2(DPAD_CENTRE_X - DPAD_DEMI, DPAD_CENTRE_Y - DPAD_DEMI) + bd,
			Vector2(2.0 * DPAD_DEMI, DPAD_DEMI + DPAD_BAS_DEMI)),                     # D-pad (bas-droite) — boîte 2 rangées : « ^ » à -DPAD_DEMI, rangée « < v > » à +DPAD_BAS_DEMI (b63)
	]
	return rects

# (21-10) Décalage d'un contrôle ancré au coin `ancre` : 0 sur un écran visible 1024×768 (repère de conception).
func _decalage_ancre(ancre: Vector2) -> Vector2:
	return (_ecran - ECRAN) * ancre

# (21-10) Enregistre un nœud d'UI (Control ou TouchScreenButton) posé dans le repère de conception et le place à son coin.
func _ancrer(n: Node, ancre: Vector2) -> void:
	_ancrages.append([n, n.position, ancre])
	n.position += _decalage_ancre(ancre)

func _maj_ecran() -> void:
	_ecran = get_viewport().get_visible_rect().size

# (21-10) Rotation / fenêtre redimensionnée : contrôles replacés à leur coin, plateau recadré (mêmes règles).
func _sur_taille_ecran() -> void:
	var avant := _ecran
	_maj_ecran()
	if _ecran == avant:
		return
	_ancrages = _ancrages.filter(func(a: Array) -> bool: return is_instance_valid(a[0]))   # nœuds d'un accueil fermé
	for a in _ancrages:
		a[0].position = a[1] + _decalage_ancre(a[2])
	_cadrer_camera()
	queue_redraw()

# Fenêtre des positions caméra qui font tenir TOUT le contenu (bbox des cases praticables) à l'écran au zoom z,
# marge MARGE_BORD. Bornes analytiques : depuis screen = (monde - cam)·z + _ecran/2, le bord GAUCHE du contenu
# (monde wx0) doit être ≥ MARGE_BORD et le bord DROIT (wx1) ≤ _ecran.x-MARGE_BORD → cam.x ∈ [wx1-demi/z, wx0+demi/z]
# avec demi = _ecran.x/2-MARGE_BORD (idem en Y). Rect2 VIDE (size < 0) si le contenu ne tient pas à ce zoom.
# N'INTÈGRE PAS l'évitement des boutons (non convexe) : c'est _cadrage_ok qui le teste, point par point.
func _fenetre_camera(z: float) -> Rect2:
	var boite := _boite_contenu()
	var wx0 := boite.position.x * CELL
	var wx1 := (boite.position.x + boite.size.x) * CELL
	# Vue plongée (balle 55) : le contenu est comprimé verticalement (PLONGE_KY) → ses bornes-monde en Y aussi.
	# Cohérent avec _cadrage_ok (qui projette chaque case au même y comprimé) → cadrage exact, pas approché.
	var wy0 := boite.position.y * CELL * _plonge_ky
	var wy1 := (boite.position.y + boite.size.y) * CELL * _plonge_ky
	# (21-10) débord de l'avatar au-delà de sa case (tête en haut surtout) → même exigence que _cadrage_ok.
	var env := _enveloppe_avatar()
	wx0 -= maxf(0.0, -CELL * 0.5 - env.position.x)
	wx1 += maxf(0.0, env.end.x - CELL * 0.5)
	wy0 -= maxf(0.0, -CELL * _plonge_ky * 0.5 - env.position.y)
	wy1 += maxf(0.0, env.end.y - CELL * _plonge_ky * 0.5)
	var demi_x := _ecran.x * 0.5 - MARGE_BORD
	var demi_y := _ecran.y * 0.5 - MARGE_BORD
	var camx_lo := wx1 - demi_x / z
	var camx_hi := wx0 + demi_x / z
	var camy_lo := wy1 - demi_y / z
	var camy_hi := wy0 + demi_y / z
	return Rect2(camx_lo, camy_lo, camx_hi - camx_lo, camy_hi - camy_lo)

# Vrai s'il EXISTE, au zoom z, une position caméra valide (_cadrage_ok). On balaie une grille 41×41 de la
# fenêtre de cadrage écran (_fenetre_camera) et on s'arrête au premier point valide (faisabilité seule).
# Grille 41×41 : la résolution ne change pas le z retenu au-delà de 0,01 (vérifié sur les niveaux larges).
const CADRAGE_PAS := 40                                              # nb d'intervalles de la grille de recherche (→ 41×41 points)
func _cadrage_faisable(z: float, boutons: Array[Rect2]) -> bool:
	var f := _fenetre_camera(z)
	if f.size.x < 0.0 or f.size.y < 0.0:
		return false                                                 # contenu trop grand pour l'écran à ce zoom
	for i in range(CADRAGE_PAS + 1):
		var camx := f.position.x + f.size.x * float(i) / CADRAGE_PAS
		for j in range(CADRAGE_PAS + 1):
			var camy := f.position.y + f.size.y * float(j) / CADRAGE_PAS
			if _cadrage_ok(Vector2(camx, camy), z, boutons):
				return true
	return false

# Position caméra VALIDE la plus proche de `a_ideal` (vue centrée-avatar), au zoom z. Même grille que
# _cadrage_faisable ; on retient le point valide de distance minimale à a_ideal. Repli (aucun point valide,
# ne survient pas au z retenu) : centre du contenu, garanti dans l'écran par construction de la fenêtre.
func _placement_le_plus_proche(z: float, a_ideal: Vector2, boutons: Array[Rect2]) -> Vector2:
	var f := _fenetre_camera(z)
	var repli := f.position + f.size * 0.5                           # contenu centré (fenêtre non vide au z retenu)
	var meilleur := repli
	var meilleure_d := INF
	for i in range(CADRAGE_PAS + 1):
		var camx := f.position.x + f.size.x * float(i) / CADRAGE_PAS
		for j in range(CADRAGE_PAS + 1):
			var camy := f.position.y + f.size.y * float(j) / CADRAGE_PAS
			var p := Vector2(camx, camy)
			if _cadrage_ok(p, z, boutons):
				var d := p.distance_squared_to(a_ideal)
				if d < meilleure_d:
					meilleure_d = d ; meilleur = p
	return meilleur

# Recadré à CHAQUE changement de niveau. Zoom RÉELLEMENT MAXIMAL (grief Fabrice b33 : « le plateau doit REMPLIR
# l'espace libre ») : garde-fou PRIORITAIRE (b28/b30, RÈGLE DÉFINITIVE Fabrice) inchangé — tout le TUNNEL (cases
# praticables ≠ '#') reste VISIBLE, jamais sous un bouton (haut+bas) ni hors écran ; la TERRE ('#', couleur du
# décor) déborde librement. Balle 32 CONSERVÉE : la vue part CENTRÉE sur l'AVATAR.
# Méthode :
#   1) ZOOM = plus grand z (plafond ZOOM_PLAFOND, pas 0,01) pour lequel il EXISTE un placement caméra valide
#      (_cadrage_faisable). Recherche descendante : la faisabilité est MONOTONE (un z plus petit rétrécit les
#      cases et élargit la fenêtre → jamais moins faisable). C'est le vrai maximum, plus l'ancre top-collée qui
#      bridait les larges-plats en les coinçant sous les 2 boutons du haut.
#   2) PLACEMENT = on part de la vue centrée-avatar (a_ideal) et, si elle cache un bord de tunnel, on GLISSE le
#      MINIMUM vers le placement valide le plus proche (terminus, valide par construction) jusqu'au premier
#      point valide → « recadrer le minimum, avatar aussi central que possible ». Terminus étant valide (t=1),
#      la boucle termine toujours.
# La caméra est STATIQUE en jeu : ce centrage est fait à l'ENTRÉE, elle ne défile pas quand l'avatar bouge.
func _cadrer_camera() -> void:
	var boutons := _rects_boutons()
	_plonge_ky = PLONGE_KY                                          # base (plongée normale) — repris pour tout tableau non-plat
	var z := ZOOM_PLAFOND
	while z > 0.05 and not _cadrage_faisable(z, boutons):
		z -= 0.01
	z = maxf(z, 0.05)
	# ── Dé-écrasement des tableaux LARGES-PLATS (balle 62) ────────────────────────────────────────────────
	# Condition « large-plat » : colonnes praticables > rangées praticables (N9 16×4 ✓ ; N8 spirale/N36 hauts ✗).
	# On mesure la hauteur écran ACTUELLE du contenu ; si elle remplit moins que PLAT_REMPLIR_V de la hauteur
	# jouable (balle 69 : TOUTE la hauteur écran — l'horizon n'est plus réservé en haut), on relève _plonge_ky pour
	# l'étirer verticalement, plafonné à PLONGE_KY_MAX. Puis on RE-DESCEND le zoom si le contenu, devenu plus haut, ne
	# tenait plus (le garde-fou « tunnel jamais coupé » b28/b33 reste prioritaire — au pire un cheveu de largeur en moins).
	var boite := _boite_contenu()
	if boite.size.x > boite.size.y:
		var h_px := boite.size.y * CELL * _plonge_ky * z
		var bande_v := _ecran.y                                     # balle 69 : hauteur jouable = plein écran (plus de bande horizon réservée)
		if h_px < PLAT_REMPLIR_V * bande_v:
			var ky_vise := (PLAT_REMPLIR_V * bande_v) / (boite.size.y * CELL * z)
			_plonge_ky = clampf(ky_vise, PLONGE_KY, PLONGE_KY_MAX)
			while z > 0.05 and not _cadrage_faisable(z, boutons):   # re-vérifie APRÈS relèvement de _plonge_ky
				z -= 0.01
			z = maxf(z, 0.05)
	# ── PLANCHER de quadrature (balle 67) : aucune case plus large que 1/PLONGE_KY_MIN × sa hauteur ─────────────
	# S'applique à TOUS les tableaux (pas seulement les larges-plats) — c'est l'écrasement 2:1 qu'on borne, pas le
	# remplissage. Le max ne baisse jamais les tableaux déjà OK. Garde-fou b28/b33 : on re-vérifie la faisabilité,
	# le zoom re-descend si la hauteur accrue coupait le tunnel (Fabrice : proportionné > grand-écrasé).
	if _plonge_ky < PLONGE_KY_MIN:
		_plonge_ky = PLONGE_KY_MIN
		while z > 0.05 and not _cadrage_faisable(z, boutons):
			z -= 0.01
		z = maxf(z, 0.05)
	_cam.zoom = Vector2(z, z)
	# a_ideal : caméra centrée sur l'avatar de départ (l'avatar se projette au centre écran quand cam = a_ideal).
	# Vue plongée (balle 55) : on vise le centre PLONGÉ de l'avatar (y comprimé) → même repère que le rendu.
	var a_ideal := _centre_plonge(_avatar)
	var terminus := _placement_le_plus_proche(z, a_ideal, boutons)   # placement valide le plus proche de l'avatar
	var cam_pos := terminus
	var t := 0.0                                                     # 0 = pile sur l'avatar ; 1 = terminus valide
	while t <= 1.0:
		var p := a_ideal.lerp(terminus, t)
		if _cadrage_ok(p, z, boutons):
			cam_pos = p                                             # premier placement valide = avatar le plus central possible
			break
		t += 0.02
	_cam.position = cam_pos
	# La caméra est STATIQUE en jeu (l'avatar bouge, pas la vue) → les limites ne servent qu'à éviter un
	# scroll parasite ; on les ouvre largement pour ne pas ré-annuler le placement calculé ci-dessus.
	_cam.limit_left = -100000
	_cam.limit_top = -100000
	_cam.limit_right = 100000
	_cam.limit_bottom = 100000
	_cam.make_current()

# Vrai si, à la position caméra `cam_pos` et au zoom z, AUCUNE case PRATICABLE (glyphe ≠ '#') ne chevauche un
# bouton (agrandi de GARDE_BOUTON) ni ne déborde de l'écran. Projection Camera2D standard :
#   sx = (x·CELL - cam_pos.x)·z + _ecran.x/2 ,  sy = (y·CELL - cam_pos.y)·z + _ecran.y/2   (écran RÉEL, 21-10).
# Les murs '#' sont IGNORÉS (ils peuvent passer sous un bouton) — c'est toute la règle définitive b28.
func _cadrage_ok(cam_pos: Vector2, z: float, boutons: Array[Rect2]) -> bool:
	var cote := CELL * z
	var cote_y := CELL * _plonge_ky * z                          # hauteur écran d'une case en vue plongée (balle 55 ; b62 : _plonge_ky adaptatif)
	var ecran := Rect2(MARGE_BORD, MARGE_BORD, _ecran.x - 2.0 * MARGE_BORD, _ecran.y - 2.0 * MARGE_BORD)
	var env := _enveloppe_avatar()                               # (21-10) l'avatar ENTIER doit tenir à l'écran sur toute case praticable
	var env_ecran := Rect2(env.position * z, env.size * z)
	for y in _terrain.size():
		var ligne: String = _terrain[y]
		for x in ligne.length():
			if ligne[x] == "#":
				continue                                             # mur (terre) : aucune contrainte
			var sx := (x * CELL - cam_pos.x) * z + _ecran.x * 0.5
			var sy := (y * CELL * _plonge_ky - cam_pos.y) * z + _ecran.y * 0.5   # y comprimé (plongée)
			var case_rect := Rect2(sx, sy, cote, cote_y)
			if not ecran.encloses(case_rect):
				return false                                         # case praticable hors écran
			var centre := Vector2(sx + cote * 0.5, sy + cote_y * 0.5)
			if not ecran.encloses(Rect2(centre + env_ecran.position, env_ecran.size)):
				return false                                         # avatar posé là : une partie (tête) hors écran
			for b in boutons:
				if b.grow(GARDE_BOUTON).intersects(case_rect):
					return false                                     # case praticable sous un bouton
	return true

# ---------------------------------------------------------------------------
# ENTRÉES — clavier + flèches écran unifiés sur _tenter_deplacement()
# ---------------------------------------------------------------------------

# Clavier : les touches écran (TouchScreenButton) consomment leurs propres événements
# tactiles dans _input, en amont de _unhandled_input → un appui écran ne déclenche pas
# AUSSI la branche clavier. is_action_pressed(allow_echo=false par défaut) → un appui
# physique = un seul pas, l'auto-répétition clavier ne fait pas glisser.
func _unhandled_input(event: InputEvent) -> void:
	if _en_accueil:
		return                                        # écran d'accueil affiché → aucune entrée de jeu (clavier compris) — balle 49
	# Barre espace = Agripper MAINTENU (PC). physical_keycode → indépendant de la
	# disposition clavier. pressed=true à l'enfoncement (et aux échos), false au relâché.
	if event is InputEventKey and event.physical_keycode == KEY_SPACE:
		_agripper_touche = event.pressed              # espace = Agripper MAINTENU (tirer) — balle 34 : plus de mode « OK »
		return
	if event.is_action_pressed("ui_up"):
		_tenter_deplacement(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		_tenter_deplacement(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		_tenter_deplacement(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		_tenter_deplacement(Vector2i(1, 0))

# Repère ÉCRAN ABSOLU : haut/bas/gauche/droite = directions de l'écran, jamais
# relatif au personnage (GDD §2.3). Un appui = une case (GDD §7).
# Si une boule occupe la case cible → tenter de la pousser (règle balle 3).
# Balle 71 — crée un AudioStreamPlayer par bruitage (réutilisable, jamais empilé) et le rattache à la scène.
# Chaque lecteur porte déjà son flux ; _jouer_son(...) applique volume/coupure puis le (re)lance.
func _construire_lecteurs_son() -> void:
	for flux in [SON_DEPLACEMENT, SON_POUSSER, SON_TIRER, SON_VICTOIRE, SON_PLACEE]:
		var lecteur := AudioStreamPlayer.new()
		lecteur.stream = flux
		add_child(lecteur)
		_lecteurs_son[flux] = lecteur

# Joue un bruitage (le rejouer coupe l'occurrence précédente du MÊME son → pas d'empilement). Respecte le flag
# SON_ACTIF (coupe tout) et le volume commun SON_VOLUME_DB, tous deux LUS ici, avant chaque lecture (code §4).
func _jouer_son(flux: AudioStream) -> void:
	if not SON_ACTIF:
		return
	var lecteur: AudioStreamPlayer = _lecteurs_son.get(flux, null)
	if lecteur == null:
		return
	lecteur.volume_db = SON_VOLUME_DB
	lecteur.play()

func _tenter_deplacement(direction: Vector2i) -> void:
	_arreter_guide()                                  # l'enfant agit → l'indice tutoriel s'efface (non intrusif, GDD §1)
	_effacer_annonce_pic()                            # 1ᵉʳ geste → le bandeau « Niveau difficile » disparaît (GDD §2.3)
	if _a_gagne:
		return                                        # niveau réussi : plus de mouvement (calme, pas de « perdu »)
	# Agripper actif ET collé à une boule → on N'EST PLUS en déplacement libre :
	# seule la flèche OPPOSÉE à la boule tire ; les autres (perpendiculaire, ou vers
	# la boule) restent sans effet (GDD §2.3 / garde-fou balle 4). Loin de toute boule,
	# agripper ne change rien : on marche / pousse normalement.
	if _agripper_actif() and _adjacent_a_une_boule():
		_tenter_tirage(direction)
		return
	var cible := _avatar + direction
	var i_boule := _index_boule(cible)
	if i_boule != -1:
		_tenter_poussee(i_boule, direction)
		return
	if _case_franchissable(cible):
		_avatar = cible
		_declencher_geste(ETAT_MARCHE, direction)
		_jouer_son(SON_DEPLACEMENT)                   # balle 71 : « pop doux » au déplacement RÉEL d'une case
		queue_redraw()
		_apres_deplacement()

# Pousser UNE boule : si la case juste derrière (même direction) est libre, la
# boule y avance et l'avatar prend l'ancienne place de la boule. Sinon rien ne
# bouge (neutre, aucun message d'échec — GDD §1). Pas de poussée en chaîne :
# une case de destination occupée par une autre boule bloque (voir _case_libre_boule).
func _tenter_poussee(i_boule: int, direction: Vector2i) -> void:
	var derriere := _boules[i_boule] + direction
	if _case_libre_boule(derriere):
		var bien_avant := _boule_bien_placee(i_boule)   # balle 72 : appariement AVANT le coup (ancienne case)
		_boules[i_boule] = derriere
		_avatar += direction
		_declencher_geste(ETAT_POUSSE, direction)
		_declencher_roulement(i_boule, direction)   # balle 56 : la boule roule dans le sens du déplacement
		_jouer_son(SON_POUSSER)                      # balle 71 : « boing court » sur poussée RÉUSSIE
		queue_redraw()
		_verifier_victoire()
		_signaler_appariement(i_boule, bien_avant)   # balle 72 : « bon appariement » nouvellement obtenu (sauf gagnant)
		_apres_deplacement()
	# sinon : mur ou autre boule derrière → immobile, sans punition

# TIRER (balle 4) — l'avatar RECULE et la boule agrippée le suit d'une case. La boule
# agrippée est celle du côté OPPOSÉ au sens demandé (_avatar - direction) : on appuie
# « à l'opposé » d'elle. Recul = _avatar + direction (devant l'avatar). Si ce recul est
# libre (ni mur ni autre boule) → l'avatar y va et la boule prend son ancienne case.
# Sinon rien ne bouge (neutre, aucun échec — GDD §1). Une seule boule à la fois.
func _tenter_tirage(direction: Vector2i) -> void:
	var i_boule := _index_boule(_avatar - direction)
	if i_boule == -1:
		return                                        # flèche perpendiculaire ou vers la boule → sans effet
	var recul := _avatar + direction
	if _case_libre_boule(recul):
		var bien_avant := _boule_bien_placee(i_boule)   # balle 72 : appariement AVANT le coup (ancienne case)
		_boules[i_boule] = _avatar                    # la boule suit sur l'ancienne case de l'avatar
		_avatar = recul
		_declencher_geste(ETAT_TIRE, direction)
		# balle 56 : la boule se déplace de +direction (de _avatar-direction vers _avatar) → elle roule dans ce sens.
		_declencher_roulement(i_boule, direction)
		_jouer_son(SON_TIRER)                         # balle 71 : « boing montant » sur tirage RÉUSSI
		queue_redraw()
		_verifier_victoire()
		_signaler_appariement(i_boule, bien_avant)   # balle 72 : « bon appariement » nouvellement obtenu (sauf gagnant)
		_apres_deplacement()
	# sinon : recul bloqué (mur/boule) → immobile, sans punition

func _agripper_actif() -> bool:
	return _agripper_touche or _agripper_bouton

# Vrai si une boule occupe l'une des quatre cases adjacentes (haut/bas/gauche/droite).
func _adjacent_a_une_boule() -> bool:
	for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if _index_boule(_avatar + d) != -1:
			return true
	return false

func _index_boule(cellule: Vector2i) -> int:
	return _boules.find(cellule)

func _glyphe_terrain(cellule: Vector2i) -> String:
	if cellule.y < 0 or cellule.y >= _terrain.size():
		return "#"                                    # hors grille = mur (ne sort pas du tunnel)
	var ligne: String = _terrain[cellule.y]
	if cellule.x < 0 or cellule.x >= ligne.length():
		return "#"
	return ligne[cellule.x]

# Case franchissable par l'AVATAR quand elle n'a pas de boule : tout sauf un mur
# (le sol '.' et la loge 'X' se traversent). Les boules sont gérées en amont.
func _case_franchissable(cellule: Vector2i) -> bool:
	return _glyphe_terrain(cellule) != "#"

# Case où une boule peut être poussée : ni mur, ni déjà occupée par une autre
# boule (interdit la poussée en chaîne). Une loge 'X' est une destination valide.
func _case_libre_boule(cellule: Vector2i) -> bool:
	if _glyphe_terrain(cellule) == "#":
		return false
	return _index_boule(cellule) == -1

# Balle 72 — vrai si la boule i repose sur une loge « à elle » : loge de MÊME étiquette (niveau apparié) ou
# n'importe quelle loge 'X' (niveau non étiqueté). Réplique EXACTE du test par-boule de _verifier_victoire →
# cohérence garantie entre le son « bon appariement » et la condition de victoire.
func _boule_bien_placee(i: int) -> bool:
	var b: Vector2i = _boules[i]
	if _glyphe_terrain(b) != "X":
		return false
	if _niveau_apparie:
		return _loges_etiquette.get(b, "") == _boules_etiquette[i]
	return true

# Balle 72 — joue « bon appariement » quand la boule i vient de DEVENIR bien placée (elle ne l'était pas avant
# ce coup). Anti-cumul victoire : si ce coup est le coup gagnant (_a_gagne posé par _verifier_victoire juste
# avant), la fanfare prime → aucun son ici (jamais les deux superposés).
func _signaler_appariement(i: int, bien_avant: bool) -> void:
	if _a_gagne:
		return
	if not bien_avant and _boule_bien_placee(i):
		_jouer_son(SON_PLACEE)
		# CoccOs : la voix dit l'étiquette gagnée (lettre ou chiffre)
		if _niveau_apparie:
			var dit := _etiquette_affichee(_boules_etiquette[i])
			VoixCoccos.dire(self, dit, "chiffres" if (dit >= "0" and dit <= "9") else "lettres")

# Réussite. Deux régimes (balle 17) :
#  • Niveau NON étiqueté (N1-N35) : dès que TOUTES les boules reposent sur une loge (croix), inchangé.
#  • Niveau ÉTIQUETÉ : chaque boule doit reposer sur une loge de MÊME étiquette (appariement boule↔loge).
# Boules ne bougeant que par poussée/tirage, ce contrôle après chaque déplacement de boule suffit.
func _verifier_victoire() -> void:
	if _niveau_apparie:
		for i in _boules.size():
			var b: Vector2i = _boules[i]
			if _glyphe_terrain(b) != "X":
				return                                    # boule pas encore sur une loge
			if _loges_etiquette.get(b, "") != _boules_etiquette[i]:
				return                                    # boule sur une loge, mais pas la SIENNE (étiquette différente)
	else:
		for b in _boules:
			if _glyphe_terrain(b) != "X":
				return
	_a_gagne = true
	_jouer_son(SON_VICTOIRE)                          # balle 71 : « petite fanfare » (accompagne l'éclat gouttelettes b36)
	# Progression débloquée (balle 16) : le niveau suivant devient accessible (flèche ►, balle 34), borné à N35.
	var avant := _niveau_max_atteint
	_niveau_max_atteint = mini(maxi(_niveau_max_atteint, _niveau_courant + 1), NIVEAUX.size() - 1)
	if _niveau_max_atteint != avant:
		_sauver_progression()                          # balle 25 : persiste sur disque → gardé à la fermeture
		_maj_fleches_navigation()                      # balle 34 : le déblocage rend ► immédiatement disponible (navigation libre)
	_afficher_reussite()

# --- SAUVEGARDE DE LA PROGRESSION (balle 25) --------------------------------
# Recharge le plus haut niveau atteint depuis user:// au démarrage. Déblocage total pour le TEST si la
# constante DEBUG_UNLOCK_ALL est vraie OU si le fichier user://pousse_pollen_unlock_all existe (aucune des deux n'écrit la
# sauvegarde → non destructif). Sinon, lit le ConfigFile ; absent/illisible (1er lancement) → reste à 0 (N1).
func _charger_progression() -> void:
	if DEBUG_UNLOCK_ALL or FileAccess.file_exists(FICHIER_UNLOCK_ALL):
		_niveau_max_atteint = NIVEAUX.size() - 1       # test : toute la série accessible d'emblée
		return
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN_PROGRESSION) == OK:
		var v: int = int(cfg.get_value("progression", "niveau_max_atteint", 0))
		_niveau_max_atteint = clampi(v, 0, NIVEAUX.size() - 1)   # borné (robuste à un fichier trafiqué/obsolète)

# Écrit le plus haut niveau atteint sur disque (appelé à chaque nouveau déblocage, _verifier_victoire).
# Balle 49 : on RELIT d'abord le fichier (fusion) → la section "choix" (avatar/curseur) n'est pas écrasée.
func _sauver_progression() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CHEMIN_PROGRESSION)                        # fusion : préserve la section "choix" (balle 49)
	cfg.set_value("progression", "niveau_max_atteint", _niveau_max_atteint)
	cfg.save(CHEMIN_PROGRESSION)

# Recharge l'avatar + le curseur (PC) choisis (balle 49) — même fichier que la progression, section "choix". Bornés
# (robuste à un fichier trafiqué/obsolète). Absent (1er lancement) → valeurs par défaut (coccinelle + main gantée).
func _charger_choix() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CHEMIN_PROGRESSION) == OK:
		_avatar_type = clampi(int(cfg.get_value(SECTION_CHOIX, CLE_AVATAR, 0)), 0, 1)
		if _curseur_pc:
			_curseur_type = clampi(int(cfg.get_value(SECTION_CHOIX, CLE_CURSEUR, 0)), 0, 2)

# Écrit l'avatar + le curseur (PC) choisis (balle 49). On RELIT d'abord (fusion) → la section "progression" est préservée.
# (08-10) En mode tactile (Android), pas de choix de curseur : une clé restante est effacée au passage (comme ab66be9).
func _sauver_choix() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CHEMIN_PROGRESSION)                        # fusion : préserve la section "progression"
	cfg.set_value(SECTION_CHOIX, CLE_AVATAR, _avatar_type)
	if _curseur_pc:
		cfg.set_value(SECTION_CHOIX, CLE_CURSEUR, _curseur_type)
	elif cfg.has_section_key(SECTION_CHOIX, CLE_CURSEUR):
		cfg.erase_section_key(SECTION_CHOIX, CLE_CURSEUR)
	cfg.save(CHEMIN_PROGRESSION)

# Message de réussite simple et joyeux : Label « Bravo ! » dans un CanvasLayer,
# centré plein écran. Contour épais → lisible sur tout fond (luminance + libellé,
# jamais la couleur seule, GDD §1). Aucun « game over », aucun chrono.
func _afficher_reussite() -> void:
	_couche_reussite = CanvasLayer.new()
	_couche_reussite.name = "Reussite"
	add_child(_couche_reussite)
	var etiquette := Label.new()
	etiquette.text = "Bravo !"
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette.set_anchors_preset(Control.PRESET_FULL_RECT)   # occupe tout l'écran → centrage réel
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE     # laisse passer les clics vers « Recommencer » (rejouer après victoire)
	etiquette.add_theme_font_size_override("font_size", 110)
	etiquette.add_theme_color_override("font_color", Color(0.98, 0.88, 0.25))     # doré joyeux
	etiquette.add_theme_color_override("font_outline_color", COL_TRAIT)
	etiquette.add_theme_constant_override("outline_size", 14)
	_couche_reussite.add_child(etiquette)
	# Finition légère : apparition en fondu doux (discret, sans son — GDD §1 calme et réglable).
	etiquette.modulate.a = 0.0
	create_tween().tween_property(etiquette, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
	# Récompense VARIÉE (balle 50, GDD §2.3 l.87) : on ALTERNE, à chaque victoire, l'éclat de pollen (b36) et l'AMI
	# qui revient remercier avec de petits cœurs. Effet RÉGLABLE/COUPABLE (GDD §1) : RECOMPENSE_EFFETS=false → rien.
	var variante_montree := -1                          # -1 = aucun effet ; sinon la variante RÉELLEMENT jouée (avant bascule)
	if RECOMPENSE_EFFETS:
		variante_montree = _recompense_variante
		if _recompense_variante == 0:
			_lancer_gouttelettes_pollen()          # variante 0 : éclat de pollen jaune (b36, conservé)
		else:
			_lancer_ami_remercie()                 # variante 1 : l'ami revient + petits cœurs qui s'allument
		_recompense_variante = 1 - _recompense_variante   # bascule pour la prochaine victoire (variété)
	# Enchaînement (balle 34, GDD §2.3) : après un court instant pour savourer le « Bravo ! » + l'effet, on AUTO-passe
	# au niveau suivant (ou écran de fin au N35). L'enfant peut aussi naviguer librement par ◄/► à tout moment. Le
	# « Recommencer » (haut-gauche) reste dispo pendant le « Bravo ! » et rejoue le même niveau. La variante « ami »
	# (balle 58) demande PLUS de temps (câlin lent + cœurs qui s'allument, tiennent puis s'estompent) → délai propre.
	var delai_savourer := DUREE_SAVOURER_AMI_S if variante_montree == 1 else DUREE_SAVOURER_VICTOIRE_S
	var vers_suivant := create_tween()
	vers_suivant.tween_interval(delai_savourer)
	vers_suivant.tween_callback(_fin_victoire_niveau_suivant)

# Éclat de gouttelettes jaunes « pollen » (balle 36) : un petit burst RADIAL de particules qui part du centre
# (là où s'affiche « Bravo ! »), retombe doucement (gravité) et s'efface en fondu. Léger, pas envahissant.
# CPUParticles2D (pas GPU) : rendu fiable partout (y compris capture X:0), aucune dépendance shader. Ajouté à
# la couche « Bravo ! » → libéré AVEC elle au chargement du niveau suivant / à l'écran de fin (aucune fuite).
func _lancer_gouttelettes_pollen() -> void:
	if not is_instance_valid(_couche_reussite):
		return
	var eclat := CPUParticles2D.new()
	eclat.name = "GouttelettesPollen"
	eclat.position = _ecran * 0.5                   # éclatent DEPUIS le mot (centré plein écran, comme « Bravo ! »)
	eclat.texture = _texture_gouttelette()         # petit disque doux (sans texture, le point serait à peine visible)
	eclat.one_shot = true                          # un seul éclat (pas d'émission continue)
	eclat.explosiveness = 1.0                      # toutes les gouttelettes partent D'UN COUP = éclat (burst)
	eclat.amount = GOUTTELETTES_NB
	eclat.lifetime = GOUTTELETTES_DUREE_S
	eclat.direction = Vector2(0, -1)
	eclat.spread = 180.0                           # 360° autour de la direction → éclat radial depuis le mot
	eclat.initial_velocity_min = 140.0
	eclat.initial_velocity_max = 300.0
	eclat.gravity = Vector2(0, 240)                # les gouttelettes retombent doucement (pollen qui se dépose)
	eclat.scale_amount_min = 0.5
	eclat.scale_amount_max = 1.0
	eclat.color = COL_GOUTTELETTE                  # jaune pollen (luminance ↑ sur le brun, jamais la teinte seule)
	# Fondu de sortie : la gouttelette s'efface en fin de vie (léger, discret — jamais un rideau opaque).
	var rampe := Gradient.new()
	rampe.set_color(0, Color(COL_GOUTTELETTE.r, COL_GOUTTELETTE.g, COL_GOUTTELETTE.b, 1.0))
	rampe.set_color(1, Color(COL_GOUTTELETTE.r, COL_GOUTTELETTE.g, COL_GOUTTELETTE.b, 0.0))
	eclat.color_ramp = rampe
	eclat.emitting = true
	_couche_reussite.add_child(eclat)

# Petit disque doux (dégradé alpha du centre vers le bord) servant de forme à une gouttelette. Blanc → coloré par
# la couleur de la particule (modulate). Généré une fois par éclat, jeté avec la couche « Bravo ! ».
func _texture_gouttelette() -> ImageTexture:
	var d := 24
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var centre := (d - 1) * 0.5
	var rayon := d * 0.5
	for y in d:
		for x in d:
			var dist := Vector2(x - centre, y - centre).length()
			var a: float = clampf(1.0 - dist / rayon, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

# Variante « ami » de la récompense (balle 50, GDD §2.3 l.87) : l'AMI (l'AUTRE personnage — abeille si l'avatar est
# une coccinelle, coccinelle si l'avatar est une abeille) revient sous le mot « Bravo ! » (petit câlin : arrivée en
# fondu + léger bond) et de PETITS CŒURS s'ALLUMENT un à un autour de lui. Court, calme (GDD §1), PUIS le même
# auto-passage (b36). Tout est enfant de la couche « Bravo ! » → libéré AVEC elle (aucune fuite) ; chaque tween est
# créé PAR son nœud (ami/cœur) → auto-arrêté quand la couche est libérée. Placeholders (persos réutilisés, cœurs
# dessinés) ; habillage fin = roadmap. L'ami et les cœurs sont des Node2D à _draw signalé (indépendants de la police).
func _lancer_ami_remercie() -> void:
	if not is_instance_valid(_couche_reussite):
		return
	var ami_type := 1 - _avatar_type                   # l'AMI = l'autre perso (0 coccinelle ↔ 1 abeille)
	var centre := _ecran * 0.5 + Vector2(0, 150)        # sous le mot « Bravo ! » (centré) → n'en masque pas les lettres
	var r := 66.0
	var ami := Node2D.new()
	ami.name = "AmiRemercie"
	ami.position = centre
	# Dessin dans le signal `draw` du Node2D (valide : appelé pendant SA passe de dessin) → la VRAIE image de l'ami (b52).
	ami.draw.connect(func() -> void:
		_dessiner_texture_fit(ami, _texture_avatar(ami_type), Vector2.ZERO, r))
	ami.modulate.a = 0.0
	_couche_reussite.add_child(ami)
	ami.queue_redraw()
	# Arrivée « câlin » DOUCE et LENTE (balle 58) : fondu + petit bond vers le haut, puis retour — courbe SINE, tenue
	# jusqu'à l'auto-passage. Il vient « prendre dans les bras » calmement, pas d'un coup (durées AMI_* ajustables).
	var t := ami.create_tween()                        # lié à l'ami → auto-arrêté à la libération de la couche
	t.tween_property(ami, "modulate:a", 1.0, AMI_FONDU_ENTREE_S).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(ami, "position:y", centre.y - AMI_BOND_HAUTEUR, AMI_BOND_MONTEE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(ami, "position:y", centre.y, AMI_BOND_RETOUR_S).set_trans(Tween.TRANS_SINE)
	# Petits cœurs qui s'ALLUMENT un à un (fondu + « pop » échelonnés) en éventail AU-DESSUS de l'ami.
	var coeurs: Array[Node2D] = []
	for i in COEURS_NB:
		var frac := float(i) / float(maxi(1, COEURS_NB - 1))
		var ang: float = PI * (0.18 + 0.64 * frac)     # arc gauche→droite au-dessus de l'ami
		var pos := centre + Vector2(-cos(ang), -sin(ang)) * (r * 1.75)
		var taille := 16.0 if (i % 2 == 0) else 20.0   # tailles alternées → petit essaim vivant
		var coeur := Node2D.new()
		coeur.name = "Coeur%d" % i
		coeur.position = pos
		coeur.scale = Vector2.ONE * 0.4
		coeur.modulate.a = 0.0
		coeur.draw.connect(func() -> void: _peindre_coeur(coeur, Vector2.ZERO, taille))
		_couche_reussite.add_child(coeur)
		coeur.queue_redraw()
		coeurs.append(coeur)
		var tc := coeur.create_tween()                 # lié au cœur → auto-arrêté à la libération de la couche
		tc.tween_interval(COEURS_APPARITION_DEBUT_S + COEURS_APPARITION_PAS_S * i)  # décalage → ils s'allument l'un après l'autre
		tc.tween_property(coeur, "modulate:a", 1.0, COEURS_FONDU_ENTREE_S).set_trans(Tween.TRANS_SINE)
		tc.parallel().tween_property(coeur, "scale", Vector2.ONE, COEURS_FONDU_ENTREE_S).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Ils RESTENT allumés un instant, puis s'estompent TOUS ENSEMBLE en un fondu de sortie LENT (balle 58 : avant, ils
	# étaient coupés net au changement de niveau). Un seul tween (lié au 1er cœur → auto-arrêté avec la couche) pilote
	# la sortie synchronisée : interval de maintien, puis alpha→0 en parallèle sur chaque cœur.
	if not coeurs.is_empty():
		var sortie := coeurs[0].create_tween()
		sortie.tween_interval(COEURS_MAINTIEN_S)                       # les cœurs restent allumés avant de s'estomper
		sortie.tween_property(coeurs[0], "modulate:a", 0.0, COEURS_FONDU_SORTIE_S).set_trans(Tween.TRANS_SINE)
		for i in range(1, coeurs.size()):
			sortie.parallel().tween_property(coeurs[i], "modulate:a", 0.0, COEURS_FONDU_SORTIE_S).set_trans(Tween.TRANS_SINE)

# Silhouette pleine d'un cœur (placeholder) : deux lobes ronds + un V vers la pointe, à `taille` px et couleur donnée.
func _forme_coeur(canvas: CanvasItem, centre: Vector2, taille: float, couleur: Color) -> void:
	var lobe := taille * 0.5
	var g := centre + Vector2(-lobe * 0.55, -lobe * 0.35)   # lobe gauche
	var d := centre + Vector2(lobe * 0.55, -lobe * 0.35)    # lobe droit
	canvas.draw_circle(g, lobe, couleur)
	canvas.draw_circle(d, lobe, couleur)
	var pointe := centre + Vector2(0, taille)
	canvas.draw_colored_polygon(PackedVector2Array([
		g + Vector2(-lobe * 0.98, lobe * 0.15), d + Vector2(lobe * 0.98, lobe * 0.15), pointe]), couleur)

# Petit cœur (placeholder balle 50) : silhouette rose posée sur un léger contour sombre (luminance + FORME « cœur »
# → jamais la couleur seule, daltonien GDD §1). Habillage fin = roadmap.
func _peindre_coeur(canvas: CanvasItem, centre: Vector2, taille: float) -> void:
	_forme_coeur(canvas, centre, taille * 1.18, COL_TRAIT)   # contour sombre (débord léger sous la silhouette rose)
	_forme_coeur(canvas, centre, taille, COL_COEUR)

# Une touche écran MULTITOUCH : un TouchScreenButton (Node2D, multitouch natif —
# class_touchscreenbutton.rst l.22 « several TouchScreenButtons can be pressed at the same
# time ») pour l'ENTRÉE, doublé d'un VISUEL Control (fond + libellé) pour l'AFFICHAGE — le
# TouchScreenButton ne dessine rien sans texture. Le visuel est MOUSE_FILTER_IGNORE : il ne
# capte jamais l'entrée, seul le TouchScreenButton la reçoit (par sa forme rectangulaire).
# Sur PC, project.godot active emulate_touch_from_mouse → la souris pilote aussi ces touches
# (un seul pointeur : pas de vrai multitouch souris — le maintien Agripper passe par l'espace).
# Retourne { "tsb": TouchScreenButton, "visuel": ColorRect }.
func _creer_touche_ecran(couche: CanvasLayer, nom: String, libelle: String, centre: Vector2, taille: Vector2, taille_police: int, ancre: Vector2 = ANCRE_HG) -> Dictionary:
	var visuel := ColorRect.new()
	visuel.name = "Visuel_" + nom
	visuel.color = COL_TOUCHE
	visuel.position = centre - taille * 0.5           # centrer le visuel sur le point de la touche
	visuel.size = taille
	visuel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ne capte jamais l'entrée (le TouchScreenButton s'en charge)
	var etiquette := Label.new()
	etiquette.text = libelle                          # libellé (accessibilité) + luminance, pas la couleur seule
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette.set_anchors_preset(Control.PRESET_FULL_RECT)
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiquette.add_theme_font_size_override("font_size", taille_police)
	etiquette.add_theme_color_override("font_color", COL_TRAIT)
	visuel.add_child(etiquette)
	couche.add_child(visuel)
	var tsb := TouchScreenButton.new()
	tsb.name = "Touche_" + nom
	tsb.position = centre                             # forme centrée sur ce point (voir ci-dessous)
	var forme := RectangleShape2D.new()
	forme.size = taille                               # RectangleShape2D couvre position ± size/2 → recouvre le visuel
	tsb.shape = forme
	tsb.shape_visible = false                         # pas de contour de forme en jeu (le visuel ColorRect suffit)
	couche.add_child(tsb)
	_ancrer(visuel, ancre)                            # (21-10) visuel + zone tactile suivent le même coin de l'écran réel
	_ancrer(tsb, ancre)
	return {"tsb": tsb, "visuel": visuel, "label": etiquette}

# Quatre flèches à l'écran, chacune une touche MULTITOUCH. Reliées aux MÊMES actions que le
# clavier → écran et clavier déclenchent le même déplacement (GDD §7). Passées en
# TouchScreenButton (balle 6) pour que, sur Android, on puisse presser une flèche d'un doigt
# tout en tenant l'Agripper de l'autre (multitouch), ce qu'un Button + souris émulée interdisait.
func _construire_fleches_ecran() -> void:
	var couche := CanvasLayer.new()
	couche.name = "FlechesEcran"
	add_child(couche)
	_couches_jeu.append(couche)          # balle 49 : masquée pendant l'écran d'accueil
	# D-pad en bas à droite du repère écran de base (1024x768, stretch canvas_items). Géométrie dérivée des
	# constantes DPAD_* → même source que la boîte d'évitement caméra (_rects_boutons) : géométrie cohérente.
	var taille := Vector2(DPAD_TAILLE_FLECHE, DPAD_TAILLE_FLECHE)
	var centre := Vector2(DPAD_CENTRE_X, DPAD_CENTRE_Y)
	var ecart := DPAD_ECART
	# Balle 63 — DISPOSITION 2 RANGÉES : « ^ » au-dessus (centre - ecart en Y), puis « < v > » sur la MÊME rangée
	# (down PILE au centre, gauche/droite à ± ecart de part et d'autre). Gain de hauteur vs la croix 3 rangées.
	_ajouter_fleche(couche, "haut", "^", centre + Vector2(0, -ecart), taille, Vector2i(0, -1))
	# La flèche BAS est gardée : c'est son VISUEL que le guide du TIRER (N4) fait pulser avec l'Agripper.
	_visuel_bas = _ajouter_fleche(couche, "bas", "v", centre, taille, Vector2i(0, 1))
	# La flèche GAUCHE est gardée : c'est son VISUEL que le guide tutoriel fait pulser (elle résout le N1).
	_visuel_gauche = _ajouter_fleche(couche, "gauche", "<", centre + Vector2(-ecart, 0), taille, Vector2i(-1, 0))
	_ajouter_fleche(couche, "droite", ">", centre + Vector2(ecart, 0), taille, Vector2i(1, 0))

# Crée une flèche écran et renvoie son VISUEL (pour la flèche gauche pulsée par le guide).
func _ajouter_fleche(couche: CanvasLayer, nom: String, libelle: String, centre: Vector2, taille: Vector2, direction: Vector2i) -> Control:
	var touche := _creer_touche_ecran(couche, nom, libelle, centre, taille, 40, ANCRE_BD)   # D-pad : coin bas-droit
	var tsb: TouchScreenButton = touche["tsb"]
	# Même chemin que le clavier : le signal pressed appelle _tenter_deplacement (un appui = une case).
	tsb.pressed.connect(_tenter_deplacement.bind(direction))
	return touche["visuel"]

# Bouton « Agripper » à l'écran, à l'OPPOSÉ des flèches (bas-gauche), grosse touche.
# MAINTIEN (balle 6, tranché Fabrice 09-07) et non bascule : agripper actif TANT QUE la
# touche est TENUE (signal `pressed` → actif, `released` → relâché — class_touchscreenbutton.rst).
# TouchScreenButton = multitouch natif → on tient l'Agripper d'un doigt et on appuie une
# flèche de l'autre (Android). Le maintien lève l'ambiguïté pousser/tirer (je tiens = je tire ;
# je lâche = je pousse en avançant). Le maintien clavier (barre espace) reste inchangé.
func _construire_bouton_agripper() -> void:
	var couche := CanvasLayer.new()
	couche.name = "BoutonAgripper"
	add_child(couche)
	_couches_jeu.append(couche)          # balle 49 : masquée pendant l'écran d'accueil
	var taille := AGRIPPER_TAILLE
	var centre := AGRIPPER_CENTRE                     # bas-gauche ; balle 28 : DESCENDU (voir constantes)
	# Balle 34 : le bouton affiche TOUJOURS « Agripper » (le mode « OK » du sélecteur b16 est retiré).
	var touche := _creer_touche_ecran(couche, "agripper", "Agripper", centre, taille, 34, ANCRE_BG)   # coin bas-gauche
	var tsb: TouchScreenButton = touche["tsb"]
	_visuel_agripper = touche["visuel"]               # gardé : vire au doré tant qu'on tient, remis au repos par « Recommencer »
	tsb.pressed.connect(_sur_agripper_presse)
	tsb.released.connect(_sur_agripper_relache)

func _sur_agripper_presse() -> void:
	_agripper_bouton = true
	_mettre_en_valeur_agripper(true)

func _sur_agripper_relache() -> void:
	_agripper_bouton = false
	_mettre_en_valeur_agripper(false)

# Retour visuel du MAINTIEN : la touche Agripper vire au doré tant qu'elle est tenue, revient
# au repos au relâché (luminance qui change, pas la couleur seule — GDD §1).
func _mettre_en_valeur_agripper(actif: bool) -> void:
	if is_instance_valid(_visuel_agripper):
		_visuel_agripper.color = COL_TOUCHE_ACTIVE if actif else COL_TOUCHE

# ---------------------------------------------------------------------------
# RECOMMENCER DOUX + GUIDE TUTORIEL (balle 5)
# ---------------------------------------------------------------------------

# Bouton « Recommencer » à l'écran, en HAUT-GAUCHE (le bas est déjà pris : D-pad à
# droite, Agripper à gauche). Grosse touche, libellé explicite. Aucun « game over »,
# aucune confirmation anxiogène (GDD §1) : un clic réinitialise, point.
func _construire_bouton_recommencer() -> void:
	var couche := CanvasLayer.new()
	couche.name = "BoutonRecommencer"
	add_child(couche)
	_couches_jeu.append(couche)          # balle 49 : masquée pendant l'écran d'accueil
	var bouton := Button.new()
	bouton.name = "Recommencer"
	bouton.text = ""                                   # (21-10) plus de mot : l'icône « rejouer » (flèche tournante) dit « recommence »
	bouton.tooltip_text = "Recommencer le niveau (sans perdre)"
	bouton.position = RECOMMENCER_POS                  # haut-gauche, moitié HAUTE de la zone réservée (balle 49)
	bouton.size = RECOMMENCER_BTN_TAILLE               # bouton = moitié haute ; la ZONE réservée (caméra) reste RECOMMENCER_TAILLE
	bouton.focus_mode = Control.FOCUS_NONE             # ne vole pas le focus au clavier
	_styler_bouton_icone(bouton)                       # (21-10) fond clair cerné de sombre, comme au jeu des 7 différences
	bouton.pressed.connect(_recommencer)
	couche.add_child(bouton)
	_habiller_icone(bouton, "rejouer", RECOMMENCER_BTN_TAILLE)

# Bouton « Accueil » (balle 49, GDD §2.3) : retourne à l'écran de choix d'avatar (et de curseur sur PC — choix RÉ-MODIFIABLE).
# Sous le Recommencer (haut-gauche), grosse touche, libellé explicite. Un clic ré-affiche l'accueil PAR-DESSUS
# le jeu en cours (sans perdre la progression, aucun « game over ») → l'enfant change d'avatar puis « Jouer » reprend.
func _construire_bouton_accueil() -> void:
	var couche := CanvasLayer.new()
	couche.name = "BoutonAccueil"
	add_child(couche)
	_couches_jeu.append(couche)                        # masqué pendant l'accueil (on y est déjà)
	var bouton := Button.new()
	bouton.name = "Accueil"
	bouton.text = ""                                   # (21-10) plus de mot : l'icône « maison » dit « retour à l'accueil »
	bouton.tooltip_text = "Changer d'avatar / de curseur" if _curseur_pc else "Changer d'avatar"
	bouton.position = ACCUEIL_POS                      # moitié BASSE de la zone réservée haut-gauche (empilé sous Recommencer, balle 49)
	bouton.size = ACCUEIL_TAILLE
	bouton.focus_mode = Control.FOCUS_NONE             # ne vole pas le focus au clavier
	_styler_bouton_icone(bouton)                       # (21-10) même fond que Recommencer (7 différences)
	bouton.pressed.connect(_afficher_accueil)
	couche.add_child(bouton)
	_habiller_icone(bouton, "maison", ACCUEIL_TAILLE)

# (21-10) FOND DE BOUTON À ICÔNE — recopié de la fabrique `_bouton` du jeu des 7 différences (sept_differences.gd) :
# plaque claire à coins ronds (10), cernée de 3 px du sombre de l'icône. Les trois états (normal, survol, appuyé)
# partagent LE MÊME fond → l'évidement de la porte de la maison (repeint en `COL_SORTIE`) ne « clignote » pas au survol.
# INACTIF : même forme, même place, luminance nettement plus basse (le BORD tient la forme).
func _styler_bouton_icone(b: Button) -> void:
	var fond := StyleBoxFlat.new()
	fond.bg_color = COL_SORTIE
	fond.set_corner_radius_all(10)
	fond.set_border_width_all(3)
	fond.border_color = COL_SORTIE_TXT
	for etat in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(etat, fond)
	var eteint := StyleBoxFlat.new()
	eteint.bg_color = Color(COL_SORTIE.r, COL_SORTIE.g, COL_SORTIE.b, 0.14)
	eteint.set_corner_radius_all(10)
	eteint.set_border_width_all(3)
	eteint.border_color = Color(COL_SORTIE.r, COL_SORTIE.g, COL_SORTIE.b, 0.75)
	b.add_theme_stylebox_override("disabled", eteint)

# (21-10) POSE DE L'ICÔNE — recopié de `_habiller_icone` du jeu des 7 différences : l'icône est un enfant du bouton,
# dessinée en code (aucun glyphe de police : ce qui manque à la couverture Unicode s'affiche en carré vide — sur le
# HUD d'un enfant qui ne lit pas encore, l'icône EST le message). `PRESET_FULL_RECT` : elle suit le bouton, quelle que
# soit sa taille. `MOUSE_FILTER_IGNORE` : elle MONTRE, elle n'intercepte pas — le clic va au bouton.
func _habiller_icone(bouton: Button, forme: String, taille: Vector2) -> void:
	var ic := IconeDessinee.new()
	ic.ov = self
	ic.forme = forme
	ic.position = Vector2.ZERO
	ic.size = taille
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bouton.add_child(ic)
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

# Label « Niveau N » en HAUT-DROITE (balle 18). Position ÉCRAN FIXE (au-dessus du bandeau y ≥ 120, à droite du
# Recommencer x ≤ 268). Balle 30 : ce panneau est désormais un obstacle de _rects_boutons → le TUNNEL l'évite
# (la terre '#' peut déborder dessous), au lieu de brider tout le plateau sous la barre du haut.
# Panneau clair + texte sombre à liseré clair = fort contraste de LUMINANCE + libellé (daltonien, GDD §1).
func _construire_label_niveau() -> void:
	var couche := CanvasLayer.new()
	couche.name = "LabelNiveau"
	add_child(couche)
	_couches_jeu.append(couche)          # balle 49 : masquée pendant l'écran d'accueil
	var panneau := ColorRect.new()
	panneau.name = "FondLabelNiveau"
	panneau.color = Color(COL_TOUCHE.r, COL_TOUCHE.g, COL_TOUCHE.b, 0.88)   # clair, semi-opaque (lisible sur la terre sombre)
	panneau.position = LABEL_NIVEAU_POS                # haut-droite : x[804,1004] (source unique, cf. constantes b30)
	panneau.size = LABEL_NIVEAU_TAILLE
	panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE # ne bloque aucun clic
	_label_niveau = Label.new()
	_label_niveau.name = "TexteNiveau"
	_label_niveau.text = "1"                                                # balle 63 : NUMÉRO seul (« Niveau » retiré)
	_label_niveau.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_niveau.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_niveau.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label_niveau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_niveau.add_theme_font_size_override("font_size", 40)             # balle 63 : chiffre plus gros (panneau rétréci au numéro)
	_label_niveau.add_theme_color_override("font_color", COL_TRAIT)          # texte sombre = fort contraste (luminance)
	_label_niveau.add_theme_color_override("font_outline_color", COL_TOUCHE) # liseré clair → lisible sur tout fond
	_label_niveau.add_theme_constant_override("outline_size", 5)
	panneau.add_child(_label_niveau)
	couche.add_child(panneau)
	_ancrer(panneau, ANCRE_HD)                         # (21-10) « N » suit le coin haut-droit réel

# « Niveau N » montre le niveau VISÉ (_niveau_vise) : au repos c'est le niveau chargé, et pendant un anti-rebond
# ◄/► c'est la CIBLE en cours de sélection — retour visuel immédiat, avant tout chargement (balle 35).
func _maj_label_niveau() -> void:
	if is_instance_valid(_label_niveau):
		_label_niveau.text = "%d" % (_niveau_vise + 1)   # balle 63 : NUMÉRO seul, encadré par « ◄ N ► »

# Charge le niveau d'index donné et remet TOUT à l'état de départ — terrain, avatar, boules,
# victoire, Agripper, caméra, guide — SANS « perdu », sans pénalité, sans confirmation (GDD §1).
# Cœur commun de « Recommencer » (même index) et « Niveau suivant » (index+1). L'index est borné
# à la plage valide : un appel hors bornes retombe sur le niveau extrême, sans planter.
func _aller_a_niveau(index: int) -> void:
	_niveau_courant = clampi(index, 0, NIVEAUX.size() - 1)
	# Balle 35 : un chargement effectif recale la cible sur le niveau JOUÉ et annule tout anti-rebond en cours
	# (ex. auto-passage après victoire, « Recommencer », ou le timeout lui-même) → numéro et flèches cohérents.
	_niveau_vise = _niveau_courant
	if is_instance_valid(_timer_nav):
		_timer_nav.stop()
	_charger_niveau()                                  # avatar + boules replacés à leur départ, terrain reconstruit
	_cadrer_camera()                                   # tableau (dimensions variables N1→N3) recadré à l'écran
	_a_gagne = false
	if is_instance_valid(_couche_reussite):            # si « Bravo ! » affiché (après victoire) → le retirer
		_couche_reussite.queue_free()
		_couche_reussite = null
	if is_instance_valid(_couche_fin):                 # si l'écran de fin est affiché (balle 24) → le retirer
		_couche_fin.queue_free()
		_couche_fin = null
	_agripper_touche = false                           # état neutre : on relâche l'Agripper (touche + écran)
	_agripper_bouton = false
	_mettre_en_valeur_agripper(false)                  # visuel de l'Agripper remis au repos
	_deja_deplace = false                              # l'avatar n'a pas encore bougé → guide du tirer pas au tout départ (N4)
	_arreter_guide_tirer()                             # éteint le guide du tirer (utile en quittant N4 ou en le rejouant)
	_lancer_guide()                                    # guide N1 uniquement (vérifié dans _lancer_guide) → rien sur N2/N3+
	_maj_annonce_pic()                                 # affiche le bandeau « pic » si ce niveau en est un, l'efface sinon
	queue_redraw()

# Recommencer DOUX : rejoue le niveau COURANT depuis son état de départ. Fonctionne aussi
# APRÈS la victoire (on retire le « Bravo ! » et on rejoue). GDD §2.3 (recommencer doux).
func _recommencer() -> void:
	_aller_a_niveau(_niveau_courant)

# ---------------------------------------------------------------------------
# NAVIGATION DE NIVEAU (balle 34, GDD §2.3 « Liberté ») — deux flèches ◄/► dédiées, distinctes du D-pad
# ---------------------------------------------------------------------------

# Construit les deux flèches ◄/► de NAVIGATION de niveau (haut-droite, sous « Niveau N »). Ce sont des Button
# (Control) : visibilité par .visible (immédiate), input GUI natif (souris/tactile), un clic = un changement de
# niveau. Style volontairement DISTINCT du D-pad (triangle PLEIN dessiné, fond clair, coin opposé) pour que
# l'enfant ne confonde jamais « changer de tableau » et « déplacer l'avatar ». La visibilité est ensuite pilotée
# par _maj_fleches_navigation (◄ cachée au N1 ; ► seulement si le niveau suivant est débloqué).
func _construire_fleches_navigation() -> void:
	var couche := CanvasLayer.new()
	couche.name = "FlechesNavigation"
	add_child(couche)
	_couches_jeu.append(couche)          # balle 49 : masquée pendant l'écran d'accueil
	_btn_niveau_prec = _creer_bouton_nav(couche, "prec", -1, NAV_PREC_CENTRE, _niveau_precedent)
	_btn_niveau_suiv = _creer_bouton_nav(couche, "suiv", 1, NAV_SUIV_CENTRE, _niveau_suivant)
	# Minuteur d'anti-rebond (balle 35) : one-shot, (re)démarré à chaque clic ◄/► ; à son timeout on charge le
	# niveau visé. Créé ici (avec les flèches) car il ne sert QU'À elles.
	_timer_nav = Timer.new()
	_timer_nav.name = "TimerNavigation"
	_timer_nav.one_shot = true
	_timer_nav.timeout.connect(_sur_timer_nav)
	add_child(_timer_nav)

# Un bouton de navigation : fond clair + triangle PLEIN dessiné (sens = -1 pour ◄, +1 pour ►). Le triangle est
# tracé dans le _draw d'un Control enfant (signal `draw`) → indépendant de la police (aucun glyphe manquant
# possible) et net à toute taille. Le fond porte le libellé accessible (title/tooltip) ; distinction par la FORME
# + la LUMINANCE (triangle sombre sur fond clair), jamais la couleur seule (daltonien, GDD §1).
func _creer_bouton_nav(couche: CanvasLayer, nom: String, sens: int, centre: Vector2, rappel: Callable) -> Button:
	var bouton := Button.new()
	bouton.name = "Nav_" + nom
	bouton.flat = true                                 # pas de style de bouton par défaut : on peint nous-mêmes
	bouton.position = centre - NAV_TAILLE * 0.5
	bouton.size = NAV_TAILLE
	bouton.focus_mode = Control.FOCUS_NONE              # ne vole pas le focus clavier (les flèches restent le D-pad)
	bouton.tooltip_text = "Niveau précédent" if sens < 0 else "Niveau suivant"
	var fond := ColorRect.new()                        # fond clair (luminance ↑) = grande cible lisible
	fond.color = COL_TOUCHE
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE     # le Button (parent) capte le clic, pas le fond
	bouton.add_child(fond)
	var triangle := Control.new()                      # dessine le triangle plein (indépendant de la police)
	triangle.set_anchors_preset(Control.PRESET_FULL_RECT)
	triangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	triangle.draw.connect(_dessiner_triangle_nav.bind(triangle, sens))
	bouton.add_child(triangle)
	bouton.pressed.connect(rappel)
	couche.add_child(bouton)
	_ancrer(bouton, ANCRE_HD)                          # (21-10) ◄ ► suivent le coin haut-droit réel
	return bouton

# Dessine un triangle PLEIN pointant à gauche (sens<0) ou à droite (sens>0), centré verticalement, dans le
# Control `ctrl` (appelé depuis son signal `draw` → les draw_* s'appliquent bien à ctrl). Sombre (COL_TRAIT)
# sur le fond clair du bouton = fort contraste de luminance.
func _dessiner_triangle_nav(ctrl: Control, sens: int) -> void:
	var w := ctrl.size.x
	var h := ctrl.size.y
	var pts: PackedVector2Array
	if sens < 0:                                       # ◄ : pointe à gauche
		pts = PackedVector2Array([Vector2(w * 0.68, h * 0.22), Vector2(w * 0.68, h * 0.78), Vector2(w * 0.30, h * 0.5)])
	else:                                              # ► : pointe à droite
		pts = PackedVector2Array([Vector2(w * 0.32, h * 0.22), Vector2(w * 0.32, h * 0.78), Vector2(w * 0.70, h * 0.5)])
	ctrl.draw_colored_polygon(pts, COL_TRAIT)

# Ajuste la visibilité des flèches au niveau courant et au plus haut débloqué (balle 34) :
#   ◄ visible si un niveau précédent existe (_niveau_courant > 0) → CACHÉE au N1 ;
#   ► visible SEULEMENT si le niveau suivant est débloqué (_niveau_courant + 1 ≤ _niveau_max_atteint) →
#     jamais au-delà du débloqué (progression sauvegardée ; unlock_all débloque tout, donc les deux flèches).
# Le CADRAGE ne dépend PAS de cette visibilité (les rects sont réservés en permanence, _rects_boutons).
func _maj_fleches_navigation() -> void:
	# Balle 35 : la visibilité suit la CIBLE (_niveau_vise), pas le niveau chargé → pendant un anti-rebond, on peut
	# continuer à défiler à partir de la cible (◄ dès que la cible > N1 ; ► tant que cible+1 est débloqué).
	if is_instance_valid(_btn_niveau_prec):
		_btn_niveau_prec.visible = _niveau_vise > 0
	if is_instance_valid(_btn_niveau_suiv):
		_btn_niveau_suiv.visible = _niveau_vise + 1 <= _niveau_max_atteint

# Clic sur ◄ → décrémente la CIBLE (anti-rebond, balle 35). Ne charge PAS ; sans effet une fois la cible au N1.
func _niveau_precedent() -> void:
	_naviguer_vise(-1)

# Clic sur ► → incrémente la CIBLE (anti-rebond, balle 35). Ne charge PAS ; la cible ne dépasse jamais le débloqué.
func _niveau_suivant() -> void:
	_naviguer_vise(1)

# Cœur de l'anti-rebond (balle 35). Déplace la CIBLE (_niveau_vise) de `delta`, bornée à [N1 … _niveau_max_atteint]
# (◄ jamais sous N1 ; ► jamais au-delà du débloqué — garde-fou b34 conservé). Puis : met à jour AUSSITÔT le numéro
# et les flèches (retour visuel immédiat, SANS charger), et (RE)démarre le minuteur — donc chaque clic repousse
# l'échéance. Si la cible ne bouge pas (déjà en butée), on ne relance rien.
func _naviguer_vise(delta: int) -> void:
	var cible := clampi(_niveau_vise + delta, 0, _niveau_max_atteint)
	if cible == _niveau_vise:
		return
	_niveau_vise = cible
	_maj_label_niveau()                                # « Niveau N » montre la cible (le niveau courant reste JOUÉ)
	_maj_fleches_navigation()                          # ◄/► suivent la cible (on peut continuer à défiler)
	if is_instance_valid(_timer_nav):
		_timer_nav.start(NAV_DELAI_S)                  # (ré)armé → charge 2 s après CE clic (le dernier gagne)

# Expiration de l'anti-rebond (balle 35) : 2 s après le dernier clic ◄/►, on charge ENFIN le niveau visé (un seul
# chargement pour toute la série de clics). Si la cible égale déjà le niveau joué (ex. aller-retour revenu au
# départ), rien à faire.
func _sur_timer_nav() -> void:
	if _niveau_vise != _niveau_courant:
		_aller_a_niveau(_niveau_vise)

# Après le « Bravo ! » (court délai), on AUTO-passe au niveau suivant (balle 34 : plus de retour en sélection).
# Garde-fou : si un « Recommencer » ou une flèche ◄/► a déjà repris la main (_a_gagne repassé à false), on ne
# force RIEN. Au DERNIER niveau (N35), on n'auto-avance pas — on affiche l'ÉCRAN DE FIN (GDD §1 « récompense de
# félicitations », balle 24). L'enfant garde la navigation libre par ◄/► à tout moment.
func _fin_victoire_niveau_suivant() -> void:
	if not _a_gagne:
		return
	if _niveau_courant >= NIVEAUX.size() - 1:
		_afficher_ecran_fin()
		return
	_aller_a_niveau(_niveau_courant + 1)

# Écran de FIN (balle 24, GDD §1 « récompense de félicitations » — jamais de reboucle du dernier niveau).
# Panneau de félicitations joyeux plein écran + petits cœurs (récompense positive, §7 « cœurs qui s'allument »)
# et un bouton « Rejouer » qui recharge N1 en JEU (l'enfant navigue ensuite librement par ◄/►, aucun échec, aucun
# cul-de-sac d'écran). Luminance + libellé (jamais la couleur seule, daltonien GDD §1).
func _afficher_ecran_fin() -> void:
	if is_instance_valid(_couche_reussite):            # retire le « Bravo ! » transitoire avant l'écran de fin
		_couche_reussite.queue_free()
		_couche_reussite = null
	_couche_fin = CanvasLayer.new()
	_couche_fin.name = "EcranFin"
	add_child(_couche_fin)
	var fond := ColorRect.new()                        # voile chaud semi-opaque (calme, pas d'alarme)
	fond.color = Color(0.35, 0.22, 0.12, 0.75)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_couche_fin.add_child(fond)
	var titre := Label.new()
	titre.text = "Bravo ! Tu as tout fini ! ♥ ♥ ♥"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titre.set_anchors_preset(Control.PRESET_FULL_RECT)
	titre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titre.add_theme_font_size_override("font_size", 54)   # tient dans 1024 px avec les cœurs (pas de débord)
	titre.add_theme_color_override("font_color", Color(0.98, 0.88, 0.25))   # doré joyeux
	titre.add_theme_color_override("font_outline_color", COL_TRAIT)
	titre.add_theme_constant_override("outline_size", 10)
	_couche_fin.add_child(titre)
	# Bouton « Rejouer » (centré, sous le titre) → recharge N1 en JEU, navigation libre par ◄/► (GDD §2.3).
	var rejouer := Button.new()
	rejouer.name = "Rejouer"
	rejouer.text = "Rejouer"
	rejouer.size = Vector2(280, 90)
	rejouer.position = Vector2((_ecran.x - 280) * 0.5, _ecran.y * 0.5 + 90)
	rejouer.focus_mode = Control.FOCUS_NONE
	rejouer.add_theme_font_size_override("font_size", 40)
	rejouer.pressed.connect(_rejouer_depuis_fin)
	_couche_fin.add_child(rejouer)
	# Apparition en fondu doux (discret, sans son — GDD §1 calme).
	fond.modulate.a = 0.0
	titre.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(fond, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(titre, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)

# « Rejouer » depuis l'écran de fin → retire l'écran et recharge N1 en JEU (balle 34 : plus de mode sélection ;
# tous les niveaux restent débloqués via _niveau_max_atteint → l'enfant navigue librement par ◄/►).
func _rejouer_depuis_fin() -> void:
	if is_instance_valid(_couche_fin):
		_couche_fin.queue_free()
		_couche_fin = null
	_aller_a_niveau(0)

# ---------------------------------------------------------------------------
# ÉCRAN D'ACCUEIL + CHOIX D'AVATAR / CURSEUR (balle 49, GDD §2.3 l.60 / l.72)
# ---------------------------------------------------------------------------
# Au LANCEMENT (et à chaque clic « Accueil »), l'enfant choisit son AVATAR (coccinelle/abeille) et, sur PC, son CURSEUR
# (main gantée/coccinelle/abeille), puis « Jouer » entre dans le jeu (sélecteur ◄/► existant, comportement conservé).
# (08-10) Choix de curseur sur PC SEULEMENT (Fabrice) ; en mode tactile (Android), pas de section curseur.
# Le choix est MÉMORISÉ (user://pousse_pollen_progression.cfg, section "choix") et ré-modifiable (bouton « Accueil » en jeu).
# Overlay plein écran (bg opaque + MOUSE_FILTER_STOP) qui MASQUE l'UI de jeu (_couches_jeu) → aucun clic ni geste
# ne passe au jeu tant qu'on choisit. (08-10) Prairie en fond, curseur coccinelle et fleurs au clic, ICI SEULEMENT.
func _afficher_accueil() -> void:
	if is_instance_valid(_couche_accueil):
		return                                          # déjà affiché (idempotent)
	_en_accueil = true
	for c in _couches_jeu:                              # masque l'UI de jeu (D-pad, Agripper, Recommencer, label, nav, Accueil)
		if is_instance_valid(c):
			c.visible = false
	# (08-10) En accueil SEULEMENT : le curseur coccinelle, souris LIBRE.
	_poser_curseur_accueil()
	_surbrillance_avatar.clear()
	_surbrillance_curseur.clear()
	_couche_accueil = CanvasLayer.new()
	_couche_accueil.name = "Accueil"
	add_child(_couche_accueil)
	var fond := ColorRect.new()                        # voile chaud OPAQUE : cache le plateau derrière + capte tous les clics
	fond.color = Color(0.28, 0.17, 0.09, 1.0)
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_STOP      # STOP → rien ne passe au jeu masqué dessous
	_couche_accueil.add_child(fond)
	# (08-10) LA PRAIRIE, comme les autres accueils : Fond.appliquer (image pure, aucun voile). Ses nœuds IGNORENT la
	# souris → le voile brun ci-dessus reste le bouchon à clics, et le fond de repli si l'image manque.
	var prairie := Control.new()
	prairie.name = "Prairie"
	prairie.set_anchors_preset(Control.PRESET_FULL_RECT)
	prairie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_couche_accueil.add_child(prairie)
	Fond.appliquer(prairie)
	_ajouter_titre_accueil(_couche_accueil, "Pousse-Pollen", 30, 84, 58, Color(0.98, 0.88, 0.25))
	# --- Choix de l'AVATAR (2 cases : coccinelle / abeille) ---
	_ajouter_titre_accueil(_couche_accueil, "Choisis ton personnage", 132, 44, 32, COL_TOUCHE)
	var cell_av := 130.0
	var largeur_av := 200.0
	var depart_av := (ECRAN.x - (2.0 * largeur_av + 40.0)) * 0.5
	for t in 2:
		var region := Rect2(depart_av + t * (largeur_av + 40.0), 186, largeur_av, 200)
		var libelle: String = "Coccinelle" if t == 0 else "Abeille"
		var liseré := _ajouter_cellule_choix(_couche_accueil, region, cell_av, true, t, libelle, _choisir_avatar.bind(t))
		_surbrillance_avatar.append(liseré)
	# --- Choix du CURSEUR (3 cases : main / coccinelle / abeille) — PC SEULEMENT (08-10) ---
	if _curseur_pc:
		_ajouter_titre_accueil(_couche_accueil, "Choisis ton curseur", 402, 44, 32, COL_TOUCHE)
		var cell_cur := 100.0
		var largeur_cur := 150.0
		var depart_cur := (ECRAN.x - (3.0 * largeur_cur + 2.0 * 40.0)) * 0.5
		for t in 3:
			var region := Rect2(depart_cur + t * (largeur_cur + 40.0), 452, largeur_cur, 150)
			var libelle: String = ["Main", "Coccinelle", "Abeille"][t]
			var liseré := _ajouter_cellule_choix(_couche_accueil, region, cell_cur, false, t, libelle, _choisir_curseur.bind(t))
			_surbrillance_curseur.append(liseré)
	# --- Bouton « Jouer » → entre dans le jeu ---
	var jouer := Button.new()
	jouer.name = "Jouer"
	jouer.text = "Jouer"
	jouer.size = Vector2(300, 96)
	jouer.position = Vector2((ECRAN.x - 300) * 0.5, 636)
	jouer.focus_mode = Control.FOCUS_NONE
	jouer.add_theme_font_size_override("font_size", 44)
	jouer.pressed.connect(_quitter_accueil)
	_couche_accueil.add_child(jouer)
	_ancrer(jouer, ANCRE_CENTRE)                       # (21-10) centré sur l'écran réel (0 en 1024×768)
	# (08-10) Les PETITES FLEURS du clic, en DERNIER → peintes par-dessus tout l'accueil. Node2D sans surface de clic :
	# elles ne mangent aucun geste. Enfants de la couche d'accueil → « Jouer » les emporte avec elle.
	_calque_fleurs_accueil = Node2D.new()
	_calque_fleurs_accueil.name = "FleursAccueil"
	_couche_accueil.add_child(_calque_fleurs_accueil)
	_lecteur_fleurs_accueil = AudioStreamPlayer.new()  # pop joyeux = le son des fleurs (bureau.gd, même volume)
	_lecteur_fleurs_accueil.stream = SonsAccueil.pop_joyeux()
	_lecteur_fleurs_accueil.volume_db = -6.0
	_lecteur_fleurs_accueil.max_polyphony = 3
	_couche_accueil.add_child(_lecteur_fleurs_accueil)
	_maj_surbrillance_accueil()                        # montre le liseré doré sur les choix courants

# Titre / sous-titre CENTRÉ pleine largeur (accueil). Doré ou clair sur le voile brun = fort contraste de LUMINANCE.
func _ajouter_titre_accueil(couche: CanvasLayer, texte: String, y: float, h: float, taille: int, couleur: Color) -> void:
	var lbl := Label.new()
	lbl.text = texte
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(0, y)
	lbl.size = Vector2(ECRAN.x, h)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", taille)
	lbl.add_theme_color_override("font_color", couleur)
	lbl.add_theme_color_override("font_outline_color", COL_TRAIT)
	lbl.add_theme_constant_override("outline_size", 6)
	couche.add_child(lbl)
	_ancrer(lbl, ANCRE_CENTRE)                         # (21-10) centré sur l'écran réel (0 en 1024×768)

# Une case de choix : liseré de sélection (doré, caché par défaut) + carte de fond + APERÇU dessiné (placeholder) +
# libellé + un Button transparent couvrant toute la case (grande cible). Renvoie le liseré (surbrillance au choix).
func _ajouter_cellule_choix(couche: CanvasLayer, region: Rect2, apercu_taille: float, est_avatar: bool, type: int, libelle: String, rappel: Callable) -> ColorRect:
	var centre_ap := Vector2(region.position.x + region.size.x * 0.5, region.position.y + apercu_taille * 0.5 + 8.0)
	var marge := 9.0
	var liseré := ColorRect.new()                      # liseré doré (luminance ↑) = sélection VISIBLE (daltonien : pas la couleur seule, c'est un CADRE)
	liseré.color = COL_TOUCHE_ACTIVE
	liseré.position = centre_ap - Vector2(apercu_taille * 0.5 + marge, apercu_taille * 0.5 + marge)
	liseré.size = Vector2(apercu_taille + 2.0 * marge, apercu_taille + 2.0 * marge)
	liseré.mouse_filter = Control.MOUSE_FILTER_IGNORE
	liseré.visible = false
	couche.add_child(liseré)
	var carte := ColorRect.new()                       # carte de fond claire → l'aperçu se détache
	carte.color = COL_SOL
	carte.position = centre_ap - Vector2(apercu_taille * 0.5, apercu_taille * 0.5)
	carte.size = Vector2(apercu_taille, apercu_taille)
	carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	couche.add_child(carte)
	var apercu := Control.new()                        # APERÇU dessiné (placeholder) — même tracé que le jeu (peindre_*)
	apercu.position = carte.position
	apercu.size = carte.size
	apercu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if est_avatar:
		apercu.draw.connect(_apercu_avatar.bind(apercu, type))
	else:
		apercu.draw.connect(_apercu_curseur.bind(apercu, type))
	couche.add_child(apercu)
	var lbl := Label.new()                             # libellé (accessibilité) sous l'aperçu
	lbl.text = libelle
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(region.position.x, centre_ap.y + apercu_taille * 0.5 + 8.0)
	lbl.size = Vector2(region.size.x, 34)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", COL_TOUCHE)
	lbl.add_theme_color_override("font_outline_color", COL_TRAIT)
	lbl.add_theme_constant_override("outline_size", 4)
	couche.add_child(lbl)
	var btn := Button.new()                            # bouton transparent = toute la case cliquable (grande cible enfant)
	btn.flat = true
	btn.position = region.position
	btn.size = region.size
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = libelle
	btn.pressed.connect(rappel)
	couche.add_child(btn)
	for n in [liseré, carte, apercu, lbl, btn]:        # (21-10) toute la case suit le centre de l'écran réel
		_ancrer(n, ANCRE_CENTRE)
	return liseré

# Aperçu d'avatar dans une case d'accueil (dessine sur le Control `ctrl`, pendant SON draw → ctrl.draw_* est valide).
# Balle 57 : le VRAI perso CoccOs (coccinelle/abeille) — la MÊME image que le curseur → personnage joué = celui montré.
func _apercu_avatar(ctrl: Control, type: int) -> void:
	_dessiner_texture_fit(ctrl, _texture_avatar(type), ctrl.size * 0.5, ctrl.size.y * 0.46)

# Aperçu de curseur dans une case d'accueil (main/coccinelle/abeille — VRAIES images, balle 52).
func _apercu_curseur(ctrl: Control, type: int) -> void:
	_dessiner_texture_fit(ctrl, _texture_curseur_perso(type), ctrl.size * 0.5, ctrl.size.y * 0.46)

# Texture ENTIÈRE de l'AVATAR « bras le long » (balle 59) — 0 = coccinelle (défaut), 1 = abeille. Sert à l'APERÇU
# d'accueil et à l'AMI-récompense (b50). En JEU, _dessiner_avatar utilise les PIÈCES cutout (AV_CUTOUT), pas ceci.
func _texture_avatar(type: int) -> Texture2D:
	return TEX_AV_ABEILLE if type == 1 else TEX_AV_COCC

# Texture du CURSEUR : 0 = main gantée, 1 = coccinelle, 2 = abeille.
func _texture_curseur_perso(type: int) -> Texture2D:
	if type == 1:
		return TEX_COCCINELLE
	if type == 2:
		return TEX_ABEILLE
	return TEX_MAIN

# Dessine une texture CENTRÉE sur `centre`, mise à l'échelle pour tenir dans une boîte de demi-côté `demi`
# (côté = 2·demi) — ratio PRÉSERVÉ (ajustement par la plus grande dimension → jamais de débordement).
func _dessiner_texture_fit(canvas: CanvasItem, tex: Texture2D, centre: Vector2, demi: float) -> void:
	var t := Vector2(tex.get_size())
	var echelle := (2.0 * demi) / maxf(t.x, t.y)
	var dim := t * echelle
	canvas.draw_texture_rect(tex, Rect2(centre - dim * 0.5, dim), false)

# Choix de l'avatar : mémorise, sauve (disque), rafraîchit la surbrillance et le rendu (l'avatar en jeu suivra au réveil).
func _choisir_avatar(type: int) -> void:
	_avatar_type = clampi(type, 0, 1)
	_sauver_choix()
	_maj_surbrillance_accueil()
	queue_redraw()

# Choix du curseur (PC) : mémorise, sauve (disque), rafraîchit la surbrillance (le curseur réel est posé en quittant l'accueil).
func _choisir_curseur(type: int) -> void:
	_curseur_type = clampi(type, 0, 2)
	_sauver_choix()
	_maj_surbrillance_accueil()

# Montre le liseré doré UNIQUEMENT sur les cases choisies (avatar + curseur courants).
func _maj_surbrillance_accueil() -> void:
	for i in _surbrillance_avatar.size():
		if is_instance_valid(_surbrillance_avatar[i]):
			_surbrillance_avatar[i].visible = (i == _avatar_type)
	for i in _surbrillance_curseur.size():
		if is_instance_valid(_surbrillance_curseur[i]):
			_surbrillance_curseur[i].visible = (i == _curseur_type)

# « Jouer » (ou reprise après un clic « Accueil » côté planche) : retire l'overlay (et avec lui les fleurs), ré-affiche
# l'UI de jeu, POSE le curseur de jeu (PC : le curseur choisi ; tactile : pointeur système) et entre dans le jeu déjà
# chargé. Idempotent (sûr si l'accueil n'est pas affiché → utilisé par la planche).
func _quitter_accueil() -> void:
	_en_accueil = false
	if is_instance_valid(_couche_accueil):
		_couche_accueil.queue_free()
		_couche_accueil = null
	_calque_fleurs_accueil = null
	_lecteur_fleurs_accueil = null
	_surbrillance_avatar.clear()
	_surbrillance_curseur.clear()
	for c in _couches_jeu:
		if is_instance_valid(c):
			c.visible = true
	if _curseur_pc:
		_appliquer_curseur()
	else:
		_retirer_curseur_accueil()
	queue_redraw()                                     # l'avatar en jeu prend l'apparence choisie

# (08-10) Curseur COCCINELLE de l'ACCUEIL (deux plateformes, quel que soit le curseur choisi pour le jeu). Souris
# LIBRE : le confinement à la fenêtre ne suit que le curseur de jeu (PC).
func _poser_curseur_accueil() -> void:
	var donnees := _curseur_souris(1)
	Input.set_custom_mouse_cursor(donnees["tex"], Input.CURSOR_ARROW, donnees["hotspot"])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	curseur_pose = "accueil"

# (08-10) Mode tactile (Android) : « le curseur n'est pas utile » (Fabrice) → aucun curseur CoccOs en jeu, pointeur
# système, souris libre (les touches écran restent cliquables à la souris).
func _retirer_curseur_accueil() -> void:
	Input.set_custom_mouse_cursor(null)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	curseur_pose = "systeme"

# PC (08-10, rétabli depuis 079ed08) : pose le CURSEUR choisi comme curseur souris, et confine le pointeur à la FENÊTRE
# de jeu (GDD §2.3 « le pointeur reste confiné au tunnel »). ⚠ « au tunnel » STRICT est impossible tant que les boutons
# (D-pad, Agripper, ◄/►) vivent HORS du tunnel : les confiner au tunnel les rendrait inatteignables → on confine à la
# FENÊTRE (placeholder faithful), le confinement fin au couloir jouable = roadmap (à arbitrer avec le décor).
func _appliquer_curseur() -> void:
	var donnees := _curseur_souris(_curseur_type)
	Input.set_custom_mouse_cursor(donnees["tex"], Input.CURSOR_ARROW, donnees["hotspot"])
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED                              # pointeur gardé dans la fenêtre (cf. note ci-dessus)
	curseur_pose = "jeu:%d" % _curseur_type

# CURSEUR souris = la VRAIE image (balle 52), redimensionnée sous la limite matérielle Godot (≤ 256 px) et
# accompagnée de son HOTSPOT = le bout du DOIGT LEVÉ, en proportions mesurées sur les PNG sources : main = haut-centre,
# coccinelle/abeille = haut-gauche. Ratio préservé → le clic tombe là où le doigt pointe.
func _curseur_souris(type: int) -> Dictionary:
	var img := _texture_curseur_perso(type).get_image().duplicate()   # duplicate → ne mute pas l'image partagée de la texture
	var hauteur_cible := 128.0
	var echelle: float = hauteur_cible / img.get_height()
	var w := int(round(img.get_width() * echelle))
	var h := int(round(img.get_height() * echelle))
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var ratio := Vector2(0.69, 0.05)          # main : bout du doigt (haut-centre)
	if type == 1:
		ratio = Vector2(0.16, 0.12)           # coccinelle : bout du doigt levé (haut-gauche)
	elif type == 2:
		ratio = Vector2(0.14, 0.12)           # abeille : bout du doigt levé (haut-gauche)
	return {"tex": ImageTexture.create_from_image(img), "hotspot": Vector2(ratio.x * w, ratio.y * h)}

# (08-10) Un appui dans l'ACCUEIL = la ronde de fleurs + pop joyeux. Clic de souris ET doigt, mais jamais les deux
# pour le même geste : les événements ÉMULÉS (souris-depuis-doigt, doigt-depuis-souris) sont écartés, et une rafale
# de tapes ne fait qu'une ronde. Décoratif : n'arrête aucun geste (les boutons de l'accueil reçoivent leur clic).
func _fleurs_accueil_sur_appui(event: InputEvent) -> void:
	if not _en_accueil or not is_instance_valid(_calque_fleurs_accueil):
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var ou := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		ou = event.position
	elif event is InputEventScreenTouch and event.pressed:
		ou = event.position
	else:
		return
	var instant := Time.get_ticks_msec()
	if instant - _dernier_appui_fleurs < APPUI_FLEURS_INTERVALLE_MS:
		return
	_dernier_appui_fleurs = instant
	_lecteur_fleurs_accueil.play()
	fleurs_accueil_posees += 1
	for i in 4:   # bureau.gd:_animation_fleurs — 4 fleurs de 10-15 px à 30-50 px du clic
		var angle := TAU * float(i) / 4.0 + randf_range(-0.3, 0.3)
		var fleur: Node2D = FleurAccueil.new()
		fleur.position = ou + Vector2.from_angle(angle) * randf_range(30, 50)
		fleur.couleur = COULEURS_FLEURS.pick_random()
		fleur.rayon = randf_range(10, 15)
		fleur.delai = 0.05 * float(i)
		_calque_fleurs_accueil.add_child(fleur)

# Indice tutoriel N1 (GDD §2.3) : la flèche GAUCHE — celle qui résout le tuto — pulse
# DOUCEMENT (luminance qui « respire », jamais la couleur seule). Discret, réglable et
# effaçable (GDD §1 calme) : la pulsation s'arrête au premier geste (_arreter_guide).
func _lancer_guide() -> void:
	if _niveau_courant != 0:
		return                                         # guide « pousser » SPÉCIFIQUE au N1 (balle 7) — rien sur N2/N3
	if not is_instance_valid(_visuel_gauche):
		return
	if _guide_tween:
		_guide_tween.kill()                            # repartir propre si un guide tournait déjà
	_visuel_gauche.modulate.a = 1.0
	_guide_tween = create_tween().set_loops()          # boucle infinie (durées non nulles → sûr, doc Tween)
	_guide_tween.tween_property(_visuel_gauche, "modulate:a", 0.45, 0.7).set_trans(Tween.TRANS_SINE)
	_guide_tween.tween_property(_visuel_gauche, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

# Efface l'indice : arrête la pulsation et restaure la flèche à pleine opacité. Appelé
# au PREMIER geste (dans _tenter_deplacement) — pas de stimulus permanent (GDD §1).
func _arreter_guide() -> void:
	if _guide_tween:
		_guide_tween.kill()
		_guide_tween = null
	if is_instance_valid(_visuel_gauche):
		_visuel_gauche.modulate.a = 1.0

# Appelé après chaque déplacement RÉEL de l'avatar (marche, poussée, tirage). Note le premier
# geste (pour ne pas montrer le guide du tirer au tout départ) puis réévalue ce guide (N4).
func _apres_deplacement() -> void:
	_deja_deplace = true
	_maj_guide_tirer()

# Guide du TIRER (N4, GDD §2.3 étape 3) : réévalué à chaque déplacement. L'indice a lieu d'être
# quand — sur N4, partie en cours, après un 1ᵉʳ geste — l'avatar est directement SOUS une boule
# (une boule occupe la case au-dessus) : c'est l'instant où maintenir Agripper + flèche bas tire
# la boule vers le bas. Sinon (boule tirée, avatar ailleurs, victoire) l'indice s'efface.
func _maj_guide_tirer() -> void:
	if _guide_tirer_requis():
		_demarrer_guide_tirer()
	else:
		_arreter_guide_tirer()

func _guide_tirer_requis() -> bool:
	if _niveau_courant != 3 or _a_gagne or not _deja_deplace:
		return false
	return _index_boule(_avatar + Vector2i(0, -1)) != -1   # une boule juste au-dessus → opportunité de tirer

# Démarre (ou laisse tourner) la pulsation de l'Agripper ET de la flèche bas — luminance qui
# « respire », jamais la couleur seule (GDD §1, daltonien). Idempotent : si elle tourne déjà, on
# ne la relance pas (pas de saccade). Les deux visuels pulsent en parallèle, en boucle.
func _demarrer_guide_tirer() -> void:
	if _guide_tirer_tween and _guide_tirer_tween.is_valid():
		return                                             # déjà en cours → ne pas repartir (évite le clignotement)
	if not is_instance_valid(_visuel_agripper) or not is_instance_valid(_visuel_bas):
		return
	_visuel_agripper.modulate.a = 1.0
	_visuel_bas.modulate.a = 1.0
	_guide_tirer_tween = create_tween().set_loops()
	_guide_tirer_tween.tween_property(_visuel_agripper, "modulate:a", 0.4, 0.7).set_trans(Tween.TRANS_SINE)
	_guide_tirer_tween.parallel().tween_property(_visuel_bas, "modulate:a", 0.4, 0.7).set_trans(Tween.TRANS_SINE)
	_guide_tirer_tween.tween_property(_visuel_agripper, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	_guide_tirer_tween.parallel().tween_property(_visuel_bas, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

# Efface l'indice du tirer : arrête la pulsation et restaure les deux touches à pleine opacité.
func _arreter_guide_tirer() -> void:
	if _guide_tirer_tween:
		_guide_tirer_tween.kill()
		_guide_tirer_tween = null
	if is_instance_valid(_visuel_agripper):
		_visuel_agripper.modulate.a = 1.0
	if is_instance_valid(_visuel_bas):
		_visuel_bas.modulate.a = 1.0

# ---------------------------------------------------------------------------
# ANNONCE « NIVEAU DIFFICILE » (balle 11, GDD §2.3 — pic annoncé tous les 5 niveaux)
# ---------------------------------------------------------------------------

# Vrai si le niveau d'index donné est marqué « pic » (GÉNÉRIQUE via NIVEAUX_PIC — ici seul le N11).
func _est_pic(index: int) -> bool:
	return NIVEAUX_PIC.has(index)

# Réévalué à chaque entrée de niveau (_ready, _aller_a_niveau) : efface d'abord tout bandeau restant
# (utile quand on QUITTE un pic), puis affiche le bandeau si le niveau courant est un pic.
func _maj_annonce_pic() -> void:
	_effacer_annonce_pic()
	if _est_pic(_niveau_courant):
		_afficher_annonce_pic()

# Bandeau CALME « Niveau difficile » : panneau doré doux (luminance ↑, jamais la couleur seule ;
# ton chaud non anxiogène — pas de rouge d'alarme), libellé sombre bien contrasté (accessibilité,
# daltonien GDD §1). Placé en haut-centre, sous « Recommencer » (haut-gauche) et loin du D-pad (bas).
# MOUSE_FILTER_IGNORE → ne bloque aucun clic. S'efface tout seul en fondu après un court instant
# (GDD §2.3 « disparaît après un court instant ») — et aussi au 1ᵉʳ geste (voir _tenter_deplacement).
func _afficher_annonce_pic() -> void:
	_couche_pic = CanvasLayer.new()
	_couche_pic.name = "AnnoncePic"
	add_child(_couche_pic)
	var largeur := 640.0
	var hauteur := 100.0
	var panneau := ColorRect.new()
	panneau.name = "Bandeau"
	panneau.color = Color(0.98, 0.88, 0.25, 0.90)     # doré doux (chaud, calme), semi-opaque
	panneau.position = Vector2((_ecran.x - largeur) * 0.5, 120)   # haut-centre : sous Recommencer, au-dessus du D-pad
	panneau.size = Vector2(largeur, hauteur)
	panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE  # laisse passer tous les clics (Recommencer, flèches…)
	var etiquette := Label.new()
	etiquette.text = "Niveau difficile"
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiquette.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiquette.set_anchors_preset(Control.PRESET_FULL_RECT)
	etiquette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiquette.add_theme_font_size_override("font_size", 48)
	etiquette.add_theme_color_override("font_color", COL_TRAIT)          # texte sombre = fort contraste (luminance)
	etiquette.add_theme_color_override("font_outline_color", COL_TOUCHE) # liseré clair → lisible sur tout fond
	etiquette.add_theme_constant_override("outline_size", 6)
	panneau.add_child(etiquette)
	_couche_pic.add_child(panneau)
	# Auto-fondu après un court instant (calme, non intrusif — GDD §1). Le fondu porte sur le panneau
	# (modulate se propage à l'étiquette enfant). Durées non nulles → sûr (doc Tween).
	_pic_tween = create_tween()
	_pic_tween.tween_interval(2.2)
	_pic_tween.tween_property(panneau, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	_pic_tween.tween_callback(_effacer_annonce_pic)

# Efface le bandeau : arrête l'auto-fondu et retire le CanvasLayer. Idempotent (sûr si rien n'est affiché).
func _effacer_annonce_pic() -> void:
	if _pic_tween:
		_pic_tween.kill()
		_pic_tween = null
	if is_instance_valid(_couche_pic):
		_couche_pic.queue_free()
		_couche_pic = null

# ---------------------------------------------------------------------------
# RENDU — terrain statique, puis boules, puis avatar par-dessus (à leur case)
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Balle 69 — FOND ENTIÈREMENT EN TERRE (avant tout le reste, derrière le plateau) : on étale TEX_TERRE sur tout
	# le rectangle-MONDE actuellement visible par la caméra → plus jamais de default_clear_color brun vide. La fenêtre
	# visible = position caméra ± (ECRAN/2)/zoom ; on l'agrandit de FOND_MARGE pour qu'aucun liseré brun ne subsiste
	# aux bords. Une SEULE image étalée (pas de tuilage : terre.png n'est pas tuilable, balle 54) → aucune couture.
	# Assombrie par MOD_FOND_TERRE (luminance) → la galerie éclairée du premier plan ressort. Le plateau (sols +
	# murs + relief) se peint PAR-DESSUS, inchangé.
	var z_cam: float = _cam.zoom.x if _cam != null and _cam.zoom.x > 0.0 else 1.0
	var demi := _ecran * 0.5 / z_cam
	var centre_cam: Vector2 = _cam.position if _cam != null else Vector2.ZERO
	var vue := Rect2(centre_cam - demi - Vector2(FOND_MARGE, FOND_MARGE),
		_ecran / z_cam + Vector2(FOND_MARGE, FOND_MARGE) * 2.0)
	draw_texture_rect(TEX_TERRE, vue, false, MOD_FOND_TERRE)
	# Dimensions de la grille (en cases) : servent à ÉTALER les textures terre/sol sur tout le plateau
	# (une part de texture par case → pas de répétition ni de couture). cols = ligne la plus longue.
	var cols := 0
	for ligne_mesure: String in _terrain:
		cols = maxi(cols, ligne_mesure.length())
	var lignes := _terrain.size()
	# RELIEF 2.5D (balle 60) — DEUX passes, tri par y (peintre) :
	#   1) tous les SOLS (galeries, loges, croix, étiquettes) d'abord ;
	#   2) puis les MURS extrudés du HAUT vers le BAS → la face latérale d'un mur recouvre le haut de la rangée
	#      du dessous (paroi du tunnel creusé), et un mur plus bas recouvre à son tour la face du mur du dessus.
	for y in _terrain.size():
		var ligne: String = _terrain[y]
		for x in ligne.length():
			if ligne[x] != "#":
				_dessiner_sol(x, y, ligne[x], cols, lignes)
	for y in _terrain.size():
		var ligne_mur: String = _terrain[y]
		for x in ligne_mur.length():
			if ligne_mur[x] == "#":
				_dessiner_mur(x, y, cols, lignes)
	# COUCHE DÉCOR (balle 43) : peinte APRÈS le terrain (par-dessus le brun des murs) et AVANT les entités.
	# Purement cosmétique — voir DECORS / _dessiner_decor(). Ne s'exécute que sur les niveaux qui en déclarent un.
	_dessiner_decor()
	# boules par-dessus le terrain (une boule sur 'X' laisse voir la croix dessous → réussite lisible).
	# Balle 17 : chaque boule porte son étiquette (dessinée dessus) → appariement lisible.
	# Vue plongée (balle 55) : les boules et l'avatar sont des objets DEBOUT → dessinés À L'ENDROIT (non
	# écrasés), mais POSÉS sur le centre PLONGÉ de leur case (y comprimé par PLONGE_KY) → ils s'assoient sur le
	# sol incliné sans perdre en lisibilité. _centre_plonge unifie ce calcul (rendu ET repères).
	for i in _boules.size():
		var b: Vector2i = _boules[i]
		# balle 56 : la texture ROULE (angle = _boules_roule) ; l'étiquette FLOTTE (angle = _boules_flot, indépendant).
		var a_roule: float = _boules_roule[i] if i < _boules_roule.size() else 0.0
		var a_flot: float = _boules_flot[i] if i < _boules_flot.size() else 0.0
		_dessiner_pollen(_centre_plonge(b), _boules_etiquette[i], a_roule, a_flot)
	# avatar dessiné en dernier, à sa cellule courante (par-dessus le sol)
	_dessiner_avatar(_centre_plonge(_avatar))

# Centre ÉCRAN-monde PLONGÉ d'une case (balle 55) : x inchangé, y comprimé par PLONGE_KY (sol incliné 3/4).
# Sert de POSE aux objets debout (boules/avatar/étiquettes) ET de repère pour dessiner le sol. Un seul calcul.
func _centre_plonge(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL * 0.5, (cell.y * CELL + CELL * 0.5) * _plonge_ky)

# Vrai si la case (x, y) est un mur de terre ('#'). HORS grille → FAUX (le bord bas/latéral du plateau expose
# donc sa face latérale = falaise avant du terrier), ce qui donne du relief à la bordure sans masquer de jouable.
func _est_mur(x: int, y: int) -> bool:
	if y < 0 or y >= _terrain.size():
		return false
	var ligne: String = _terrain[y]
	if x < 0 or x >= ligne.length():
		return false
	return ligne[x] == "#"

# MUR DE TERRE EXTRUDÉ (balle 60, RELIEF 2.5D). Face latérale sombre tirée vers le BAS (vers la caméra) SI la
# case du dessous n'est pas elle-même un mur (sinon la face serait cachée par le bloc de devant) → paroi du
# tunnel creusé + liseré de fond sombre au pied. Puis face SUPÉRIEURE claire (terre pleine) + reflet d'arête.
func _dessiner_mur(x: int, y: int, cols: int, lignes: int) -> void:
	var origine := Vector2(x * CELL, y * CELL * _plonge_ky)
	var taille := Vector2(CELL, CELL * _plonge_ky)
	var rect := Rect2(origine, taille)
	if not _est_mur(x, y + 1):
		# Galerie en contrebas (sud) → on voit la PAROI. Balle 61 : elle est prise SUR LA TERRE (bande BASSE de
		# CETTE case du mur), jamais sur le sol du dessous → le tunnel garde toute sa largeur. Bornée < la case.
		var h := clampf(RELIEF_H, 0.0, 0.9) * taille.y
		var haut := Rect2(origine, Vector2(CELL, taille.y - h))                # dessus clair = reste HAUT de la terre
		var face := Rect2(Vector2(origine.x, origine.y + taille.y - h), Vector2(CELL, h))  # paroi sombre = BAS de la terre
		_texturer_case(TEX_TERRE, haut, x, y, cols, lignes, Color.WHITE)
		_texturer_case(TEX_TERRE, face, x, y, cols, lignes, COL_RELIEF_COTE)   # côté sombre (terre assombrie)
		# liseré de fond sombre au pied = le contact paroi / galerie (ombre de la crevasse), DANS la case du mur
		draw_rect(Rect2(Vector2(origine.x, origine.y + taille.y - RELIEF_LISERE), Vector2(CELL, RELIEF_LISERE)), COL_RELIEF_FOND)
	else:
		_texturer_case(TEX_TERRE, rect, x, y, cols, lignes, Color.WHITE)       # mur plein (terre sous lui aussi) : dessus clair
	if not _est_mur(x, y - 1):                                                # reflet SEULEMENT sur la crête (arête haute du relief)
		draw_rect(Rect2(origine, Vector2(CELL, RELIEF_REFLET_H)), COL_RELIEF_REFLET)  # lumière rasante sur le dessus (pas de ligne interne au bloc)
	draw_rect(rect, COL_TRAIT, false, 2.0)                                    # liseré : lisibilité du bloc sur le vide sombre

func _dessiner_sol(x: int, y: int, glyphe: String, cols: int = 1, lignes: int = 1) -> void:
	# Vue plongée (balle 55) : le SOL est incliné → chaque case fait CELL de large mais CELL·PLONGE_KY de HAUT
	# (foreshortening vertical). Les rangées se pavent sans couture (bas de la rangée y = haut de la rangée y+1).
	var origine := Vector2(x * CELL, y * CELL * _plonge_ky)
	var taille := Vector2(CELL, CELL * _plonge_ky)
	var rect := Rect2(origine, taille)
	var centre := origine + taille * 0.5
	# Sol : '.' (et 'X'/entités) = sol normal ; ':' = sol teinté (praticable, nuance CLAIRE — balle 27).
	# Les deux sont CLAIRS (luminance) donc lus « on passe » ; la teinte de ':' est un décor, jamais le seul repère.
	_texturer_case(TEX_SOL, rect, x, y, cols, lignes, MOD_SOL_TEINTE if glyphe == ":" else Color.WHITE)
	draw_rect(rect, COL_TRAIT, false, 2.0)  # liseré discret de case
	# Loge : peinte SAUF sous l'avatar → la croix centrale de N4 est cachée tant que l'avatar est
	# posé dessus, révélée dès qu'il se déplace (découverte, GDD §2.3). Une boule sur une loge, elle,
	# laisse voir la croix (réussite lisible) : seul l'avatar la masque.
	if glyphe == "X" and _avatar != Vector2i(x, y):
		_dessiner_croix(centre)           # loge ; croix APLATIE au sol (compressée), boules/avatar peints par-dessus
		# Balle 17 : loge étiquetée → son étiquette dessinée par-dessus la croix (appariement lisible ;
		# masquée si une boule/l'avatar la recouvre, ce qui est correct — on voit alors l'entité du dessus).
		var etiquette: String = _loges_etiquette.get(Vector2i(x, y), "")
		if etiquette != "":
			_dessiner_etiquette(centre, etiquette, true)   # sur_loge : caractère BLANC + liseré sombre (net sur le rouge)

# Peint une case avec sa PART de la texture (balle 54) : la texture entière est étalée sur toute la grille
# (cols × lignes cases), donc la case (x, y) reçoit le rectangle-source [x/cols .. (x+1)/cols] × [y/lignes ..].
# Résultat : image continue, sans répétition ni couture, quelle que soit la taille du plateau. `teinte` module
# la texture (Color.WHITE = neutre ; nuance claire pour le sol ':').
func _texturer_case(tex: Texture2D, rect: Rect2, x: int, y: int, cols: int, lignes: int, teinte: Color) -> void:
	var t := Vector2(tex.get_size())
	var pas := Vector2(t.x / float(maxi(cols, 1)), t.y / float(maxi(lignes, 1)))
	var src := Rect2(Vector2(x, y) * pas, pas)
	draw_texture_rect_region(tex, rect, src, teinte)

func _dessiner_croix(centre: Vector2) -> void:
	var r := CELL * 0.32
	var ry := r * _plonge_ky              # croix = marque AU SOL → branches verticales aplaties par la plongée (balle 55 ; b62 : _plonge_ky adaptatif)
	var e := 14.0
	draw_line(centre + Vector2(-r, -ry), centre + Vector2(r, ry), COL_LOGE, e)
	draw_line(centre + Vector2(-r, ry), centre + Vector2(r, -ry), COL_LOGE, e)

func _dessiner_pollen(centre: Vector2, etiquette: String = "", angle_roule: float = 0.0, angle_flot: float = 0.0) -> void:
	# Balle 54 : sprite pollen détouré (fluff doré) à la place du cercle. Ajusté à ~0,80 case (ratio préservé),
	# la fourrure déborde un peu du cercle d'origine sans toucher les cases voisines. Sa forme + sa teinte dorée
	# suffisent à le lire ; l'étiquette d'appariement reste peinte PAR-DESSUS (luminance, jamais la couleur seule).
	# Balle 56 : la TEXTURE tourne (angle_roule = roulement) ; l'ÉTIQUETTE tourne d'un angle SÉPARÉ (angle_flot =
	# flotteur), donc elle n'est PAS solidaire du roulement. Les deux rotations sont centrées sur la boule via
	# draw_set_transform (repère local translaté au centre, tourné), puis on rétablit l'identité (les autres tracés
	# du _draw — terrain, croix, avatar — restent en repère normal).
	# Balle 63 : demi-largeur PROPORTIONNELLE à _plonge_ky (remap PLONGE_KY→PLONGE_KY_MAX) → remplissage de case
	# ~constant quel que soit le foreshortening (petits tableaux inchangés, grands agrandis). Cf. BOULE_FRAC_*.
	var frac_b := clampf(remap(_plonge_ky, PLONGE_KY, PLONGE_KY_MAX, BOULE_FRAC_MIN, BOULE_FRAC_MAX), BOULE_FRAC_MIN, BOULE_FRAC_MAX)
	var demi := CELL * frac_b
	var t := Vector2(TEX_POLLEN.get_size())
	var echelle := (2.0 * demi) / maxf(t.x, t.y)
	var dim := t * echelle
	draw_set_transform(centre, angle_roule, Vector2.ONE)
	draw_texture_rect(TEX_POLLEN, Rect2(-dim * 0.5, dim), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if etiquette != "":
		draw_set_transform(centre, angle_flot, Vector2.ONE)
		_dessiner_etiquette(Vector2.ZERO, etiquette)   # centre local = origine (le transform la pose sur la boule)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Étiquette d'appariement (balle 17) : un gros caractère CENTRÉ → fort contraste de LUMINANCE, lisible sur
# tout fond (daltonien, GDD §1). Deux régimes (balle 27) :
#  • sur une BOULE (fond doré clair) : caractère SOMBRE + liseré clair (inchangé).
#  • sur une LOGE (croix rouge, fond sombre) : caractère BLANC + liseré sombre → net sur le rouge.
# Font par défaut du moteur (ThemeDB.fallback_font, toujours présente hors thème). Coordonnées locales du _draw().
func _dessiner_etiquette(centre: Vector2, texte: String, sur_loge: bool = false) -> void:
	var police := ThemeDB.fallback_font
	if police == null:
		return
	var taille_police := int(CELL * 0.44)
	var dim := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_police)
	# baseline : coin haut-gauche du texte = centre - dim/2 ; on descend de l'ascension pour poser la ligne de base.
	var pos := centre - dim * 0.5 + Vector2(0, police.get_ascent(taille_police))
	var col_texte := COL_ETIQ_LOGE if sur_loge else COL_TRAIT
	var col_liseré := COL_TRAIT if sur_loge else COL_TOUCHE
	draw_string_outline(police, pos, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_police, 8, col_liseré)
	draw_string(police, pos, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_police, col_texte)

# Avatar du joueur (balle 59) — le VRAI perso CoccOs « bras le long », ANIMÉ EN CUTOUT (5 pièces : core + brasG/D +
# jambeG/D, cf. en-tête). Le geste courant produit une impulsion `pulse` (0→1→0 sur AVATAR_DUREE_GESTE) qui tourne les
# membres autour de leur attache et décale légèrement le corps : REPOS = pièces à l'identité (image d'origine, bras le
# long, immobile) ; MARCHE = jambes alternées + bras à l'opposé + bob ; POUSSE = les 2 mains vers la boule (+dir) +
# corps penché vers elle + un pas ; TIRE = mains agrippées vers la boule (en -dir) + corps reculé (+dir) + pas inverse.
# Balle 63 : demi PROPORTIONNEL à _plonge_ky (cf. AVATAR_FRAC_*) → même remplissage de case que la boule, à
# tout foreshortening (petits tableaux inchangés, grands agrandis, léger débordement toléré ; objet non distordu).
func _demi_avatar() -> float:
	return CELL * clampf(remap(_plonge_ky, PLONGE_KY, PLONGE_KY_MAX, AVATAR_FRAC_MIN, AVATAR_FRAC_MAX), AVATAR_FRAC_MIN, AVATAR_FRAC_MAX)

# (21-10) Rectangle-monde que l'avatar peut couvrir, RELATIF au centre plongé de sa case (_centre_plonge) : enveloppe
# AV_ENV_* du sprite (remonté par l'ancrage pieds) élargie du penché du corps (AV_LEAN ≥ AV_BOB). Même géométrie que
# _dessiner_avatar (hauteur dessinée = 2·demi : la toile est plus haute que large).
func _enveloppe_avatar() -> Rect2:
	var h := 2.0 * _demi_avatar()
	var cy := -(AV_PIEDS_FRAC - 0.5) * h
	var r := Rect2(-AV_ENV_X * h, cy - AV_ENV_HAUT * h, 2.0 * AV_ENV_X * h, (AV_ENV_HAUT + AV_ENV_BAS) * h)
	return r.grow(AV_LEAN * CELL)

func _dessiner_avatar(centre: Vector2) -> void:
	var pieces: Dictionary = AV_CUTOUT[_avatar_type]
	var tex_core: Texture2D = pieces["core"]
	var ts := Vector2(tex_core.get_size())
	var demi := _demi_avatar()
	var dim := ts * ((2.0 * demi) / maxf(ts.x, ts.y))   # même fit que _dessiner_texture_fit → recalage identique aux aperçus
	var pulse := 0.0
	if _avatar_reste > 0.0:
		pulse = sin(PI * (1.0 - clampf(_avatar_reste / AVATAR_DUREE_GESTE, 0.0, 1.0)))
	var dir := Vector2(_avatar_geste_dir)
	var dirx := signf(dir.x)                            # composante horizontale du geste (le rig ne balance les mains qu'à l'horizontale)
	var a_bras_g := 0.0
	var a_bras_d := 0.0
	var a_jambe_g := 0.0
	var a_jambe_d := 0.0
	var corps := Vector2.ZERO
	match _avatar_etat:
		ETAT_MARCHE:
			corps = Vector2(0.0, -AV_BOB * CELL * pulse)
			var s := 1.0 if (_avatar_pas % 2 == 0) else -1.0
			a_jambe_g = JAMBE_SWING * pulse * s
			a_jambe_d = -JAMBE_SWING * pulse * s
			# balle 61 : le swing des BRAS vient désormais du pendule amorti (plus bas), pas d'un pulse qui claque.
		ETAT_POUSSE:
			corps = dir * (AV_LEAN * CELL * pulse)      # le corps penche VERS la boule (+dir)
			var rp := BRAS_REACH * pulse
			if dirx != 0.0:
				a_bras_g = rp * dirx
				a_bras_d = rp * dirx                    # les 2 mains partent vers la boule (horizontal)
			else:
				a_bras_g = 0.3 * rp
				a_bras_d = -0.3 * rp                    # boule au-dessus/dessous : grip symétrique (le penché du corps fait le vertical)
			a_jambe_g = JAMBE_SWING * 0.6 * pulse
			a_jambe_d = -JAMBE_SWING * 0.6 * pulse
		ETAT_TIRE:
			corps = dir * (AV_LEAN * CELL * pulse)      # +dir = à l'opposé de la boule (en -dir) → le corps recule
			var rt := BRAS_REACH * pulse
			if dirx != 0.0:
				a_bras_g = -rt * dirx                   # mains agrippées vers la boule (côté -dir)
				a_bras_d = -rt * dirx
			else:
				a_bras_g = 0.3 * rt
				a_bras_d = -0.3 * rt
			a_jambe_g = -JAMBE_SWING * 0.6 * pulse      # jambes qui reculent
			a_jambe_d = JAMBE_SWING * 0.6 * pulse
	# Balle 61 — PENDULE amorti des bras (balancement puis stabilisation, comme le flotteur b56), opposé entre les
	# deux bras (démarche naturelle). Alimenté par la MARCHE (impulsion dans _declencher_geste) ; en POUSSE/TIRE il
	# ne reste qu'un résidu qui s'éteint, la pose « mains vers la boule » restant nette. Angle 0 au repos = bras le long.
	a_bras_g += _bras_bal
	a_bras_d += -_bras_bal
	# Balle 61 — ANCRAGE PIEDS : ce sont les pieds (≈ AV_PIEDS_FRAC de la toile) qui se posent au centre de la case ;
	# on remonte donc le sprite → le corps/la tête débordent vers le HAUT, par-dessus le terrain (avatar dessiné en dernier).
	var c := centre + corps + Vector2(0.0, -(AV_PIEDS_FRAC - 0.5) * dim.y)
	# Ordre peintre : jambes DERRIÈRE le corps, core, puis bras DEVANT (mains visibles quand elles vont sur la boule).
	_dessiner_membre(pieces["jambeG"], c, dim, PIV_JAMBE_G, a_jambe_g)
	_dessiner_membre(pieces["jambeD"], c, dim, PIV_JAMBE_D, a_jambe_d)
	_dessiner_membre(tex_core, c, dim, Vector2(0.5, 0.5), 0.0)
	_dessiner_membre(pieces["brasG"], c, dim, PIV_BRAS_G, a_bras_g)
	_dessiner_membre(pieces["brasD"], c, dim, PIV_BRAS_D, a_bras_d)

# Balle 59 — dessine une PIÈCE cutout (pleine toile, même `dim` que le core) TOURNÉE d'`angle` autour de son point
# d'attache `pivot_frac` (fraction de l'image). À angle 0 et même centre, toutes les pièces se superposent EXACTEMENT
# au core (image d'origine reconstituée → 0 fantôme). Repère local rétabli après (les autres tracés du _draw restent normaux).
func _dessiner_membre(tex: Texture2D, centre: Vector2, dim: Vector2, pivot_frac: Vector2, angle: float) -> void:
	var pivot := centre + (pivot_frac - Vector2(0.5, 0.5)) * dim
	draw_set_transform(pivot, angle, Vector2.ONE)
	draw_texture_rect(tex, Rect2(-Vector2(pivot_frac.x * dim.x, pivot_frac.y * dim.y), dim), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ─────────────────────────────────────────────────────────────────────────────────────────────────────────────
# COUCHE DÉCOR (balle 43) — SYSTÈME RÉUTILISABLE
# ─────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Peint des formes COSMÉTIQUES dans la TERRE (murs/fond), à résolution SOUS-CASE, autour du tunnel jouable. C'est
# l'équivalent-mur du sol teinté ':' : dessiner un décor fin SANS toucher la logique (terrain, collision, solveurs,
# cadrage). Le décor est purement dessiné et ne modifie AUCUN état.
#
# FORMAT DE DONNÉES (réutilisable pour de futures figures : agneau, tête de chat, arbre, oiseau…) :
#   DECORS = { index_niveau : [ primitive, … ] }  (index 0 = N1). Un niveau sans entrée = aucun décor.
#   Chaque primitive est un Dictionary. TOUTES les coordonnées et tailles sont en UNITÉS DE CASE (1.0 = 1 case) :
#   elles sont multipliées par CELL au tracé → le décor SCALE avec la taille de case (responsive : 4:3, 16:9,
#   Android, iOS). Repère = grille brute : la case (cx,cy) va de (cx,cy) à (cx+1,cy+1) ; centre = (cx+0.5,cy+0.5).
#   Types :
#     {"t":"poly",   "p":[Vector2,…], "fond":Color, "trait":Color}   polygone plein + contour (silhouette)
#     {"t":"disque", "c":Vector2, "r":float, "fond":Color, "trait":Color}   cercle plein + contour
#     {"t":"trait",  "a":Vector2, "b":Vector2, "ep":float, "fond":Color, "trait":Color}   segment épais gainé de contour
#   "trait" (clé) est le contour ; l'omettre → pas de contour (ex. pupille). L'ORDRE du tableau = ordre de tracé
#   (peintre) : les premières primitives sont dessous. GARDE-FOU couleur : rester en gamme terre/foncée (< sol clair,
#   luminance) pour que le décor soit lu NON praticable — voir COL_DECOR_CORPS.
#
# DECORS est VIDE (balle 62). L'escargot de N8 (index 7) a été RETIRÉ sur retour test Fabrice : à cette échelle
# le décor n'était plus lisible (devenu un cadre ovale mangeant les coins) → « on laisse le tableau comme on le
# voit ». N8 s'affiche donc SANS décor ; la grille NIVEAU_8 (tunnel spirale) reste inchangée et jouable.
# Le MOTEUR de décor (format ci-dessus + _dessiner_decor + types poly/disque/trait/spirale + COL_DECOR_CORPS) est
# CONSERVÉ, prêt à re-servir pour une future figure : il suffit d'ajouter une entrée { index : [ primitives… ] }.
const DECOR_CONTOUR := 0.05          # épaisseur des contours du décor, en unités de case (silhouette daltonien-safe)
const DECORS := {}

# Peint le décor du niveau courant (s'il en a un). Voir DECORS pour le format. Aucun effet de bord : lecture seule.
func _dessiner_decor() -> void:
	var prims: Array = DECORS.get(_niveau_courant, [])
	if prims.is_empty():
		return
	# Vue plongée (balle 55) : le décor est peint SUR le sol → même foreshortening vertical que les cases.
	# On applique la compression via une transform locale (échelle Y = PLONGE_KY), rétablie à l'identité ensuite.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, _plonge_ky))
	var epc := DECOR_CONTOUR * CELL
	for p in prims:
		match p["t"]:
			"poly":
				var pts := PackedVector2Array()
				for v in p["p"]:
					pts.append((v as Vector2) * CELL)
				draw_colored_polygon(pts, p["fond"])
				if p.has("trait"):
					var bord := pts
					bord.append(pts[0])
					draw_polyline(bord, p["trait"], epc, true)
			"disque":
				var c: Vector2 = (p["c"] as Vector2) * CELL
				var r: float = float(p["r"]) * CELL
				draw_circle(c, r, p["fond"])
				if p.has("trait"):
					draw_arc(c, r, 0.0, TAU, 48, p["trait"], epc)
			"trait":
				var a: Vector2 = (p["a"] as Vector2) * CELL
				var b: Vector2 = (p["b"] as Vector2) * CELL
				var ep: float = float(p["ep"]) * CELL
				if p.has("trait"):
					draw_line(a, b, p["trait"], ep + 2.0 * epc)
				draw_line(a, b, p["fond"], ep)
			"spirale":
				# Bande épaisse suivant une SPIRALE (arc à rayon variable) : dessine l'arrondi
				# rond de la coquille dans la terre AUTOUR du tunnel carré, sans le recouvrir.
				# Angles a0/a1 en degrés (repère écran, y vers le bas). Casing sombre + chair.
				var cc: Vector2 = (p["c"] as Vector2) * CELL
				var pas: int = int(p.get("pas", 48))
				var pts2 := PackedVector2Array()
				for i in pas + 1:
					var t := float(i) / float(pas)
					var ang: float = deg_to_rad(lerp(float(p["a0"]), float(p["a1"]), t))
					var rr: float = float(lerp(float(p["r0"]), float(p["r1"]), t)) * CELL
					pts2.append(cc + Vector2(cos(ang), sin(ang)) * rr)
				var eps: float = float(p["ep"]) * CELL
				if p.has("trait"):
					draw_polyline(pts2, p["trait"], eps + 2.0 * epc, true)
				draw_polyline(pts2, p["fond"], eps, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)   # rétablit l'identité pour les entités debout (balle 55)


# ═══════════════ Habillage CoccOs (voir l'en-tête du fichier) ═══════════════

const CHEMIN_BUREAU := "res://scenes/bureau.tscn"
const Lancement := preload("res://scripts/lancement.gd")
const VoixCoccos := preload("res://scripts/voix.gd")
const CROIX_COCCOS_POS := Vector2(936, 16)
const CROIX_COCCOS_TAILLE := Vector2(72, 72)
const COULEUR_CROIX_COCCOS := Color(0.85, 0.35, 0.30)


## Croix de fermeture CoccOs — même bouton rond rouge que les autres applis,
## coin haut-droit (les ◄ N ► de Fabrice sont décalés de 100 px pour lui).
func _creer_bouton_quitter_coccos() -> void:
	var couche := CanvasLayer.new()
	couche.name = "CroixCoccOs"
	add_child(couche)
	var btn := Button.new()
	btn.custom_minimum_size = CROIX_COCCOS_TAILLE
	btn.position = CROIX_COCCOS_POS
	btn.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = COULEUR_CROIX_COCCOS
		if etat == "hover":
			style.bg_color = COULEUR_CROIX_COCCOS.lightened(0.15)
		elif etat == "pressed":
			style.bg_color = COULEUR_CROIX_COCCOS.darkened(0.15)
		style.set_corner_radius_all(36)
		btn.add_theme_stylebox_override(etat, style)
	var icone := _IconeCroixFermerCoccOs.new()
	icone.set_anchors_preset(Control.PRESET_FULL_RECT)
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icone)
	btn.pressed.connect(_quitter_coccos)
	couche.add_child(btn)
	_ancrer(btn, ANCRE_HD)                             # (21-10) croix au coin haut-droit RÉEL


## Retour au bureau CoccOs (ou fermeture en lancement direct --app).
func _quitter_coccos() -> void:
	VoixCoccos.arreter(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Lancement.app_directe() == "" and ResourceLoader.exists(CHEMIN_BUREAU):
		get_tree().change_scene_to_file(CHEMIN_BUREAU)
	else:
		get_tree().quit()


## Échap = quitter (réflexe universel CoccOs) — Fabrice n'utilise pas ui_cancel.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_quitter_coccos()
		return
	_fleurs_accueil_sur_appui(event)   # (08-10) fleurs au clic/touche, ACCUEIL seulement


## Bouton Retour d'Android (mode bureau) : même geste que la croix.
func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
		_quitter_coccos()


## Croix blanche du bouton Quitter — le dessin commun des applis CoccOs.
class _IconeCroixFermerCoccOs extends Control:
	func _draw() -> void:
		var centre := size / 2.0
		var u := minf(size.x, size.y) / 2.0
		var bras := u * 0.42
		var epaisseur := u * 0.24
		draw_line(centre + Vector2(-bras, -bras), centre + Vector2(bras, bras), Color.WHITE, epaisseur)
		draw_line(centre + Vector2(-bras, bras), centre + Vector2(bras, -bras), Color.WHITE, epaisseur)
		for coin: Vector2 in [Vector2(-bras, -bras), Vector2(bras, -bras), Vector2(-bras, bras), Vector2(bras, bras)]:
			draw_circle(centre + coin, epaisseur / 2.0, Color.WHITE)


# ============================================================================================================
# (21-10) ICÔNES DESSINÉES EN CODE — classe RECOPIÉE du jeu des 7 différences (`IconeDessinee`, sept_differences.gd),
# comme l'a fait le puzzle : la GÉOMÉTRIE est la même, point par point, pour que la fratrie CoccOs parle d'une voix.
#   • MAISON — un pignon large qui déborde le corps, et une PORTE ÉVIDÉE. C'est la porte qui fait la maison : sans
#     elle, un carré surmonté d'un triangle se lit aussi bien « tente » ou « flèche vers le haut ».
#   • FLÈCHE TOURNANTE — un arc de ~300° et non un cercle : un cercle fermé ne tourne pas. L'OUVERTURE dit qu'il y a
#     un début et une fin, la POINTE tangente dit dans quel sens. Les deux ensemble disent « recommence ».
# ⚠ TOUT EST TRACÉ EN `COL_SORTIE_TXT` (le sombre) SUR LE FOND CLAIR DU BOUTON : contraste de LUMINANCE, lisible sous
#   n'importe quel daltonisme. Et tout est en FRACTION de la taille du bouton (marge 16 %), jamais en pixels.
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

	# LA MAISON — dessinée dans le plus grand CARRÉ que la zone contienne : sur un bouton large (240 px), une maison
	# étirée à la largeur deviendrait un hangar.
	func _maison(z: Rect2) -> void:
		var c: float = minf(z.size.x, z.size.y)
		var o: Vector2 = z.get_center() - Vector2(c, c) * 0.5
		var sombre: Color = ov.COL_SORTIE_TXT
		draw_colored_polygon(PackedVector2Array([
			o + Vector2(c * 0.50, 0.0), o + Vector2(c, c * 0.46), o + Vector2(0.0, c * 0.46)]), sombre)
		draw_rect(Rect2(o + Vector2(c * 0.14, c * 0.44), Vector2(c * 0.72, c * 0.56)), sombre, true)
		# LA PORTE, ÉVIDÉE — on repeint le fond du bouton par-dessus le corps. `COL_SORTIE` est bien la teinte des
		# trois états (normal, survol, appuyé) de `_styler_bouton_icone`, donc l'évidement ne « clignote » pas au survol.
		draw_rect(Rect2(o + Vector2(c * 0.39, c * 0.64), Vector2(c * 0.22, c * 0.36)), ov.COL_SORTIE, true)

	# LA FLÈCHE TOURNANTE — l'arc, puis la pointe TANGENTE à son extrémité (c'est elle qui donne le sens).
	func _rejouer(z: Rect2) -> void:
		var sombre: Color = ov.COL_SORTIE_TXT
		var c: Vector2 = z.get_center()
		var r: float = minf(z.size.x, z.size.y) * 0.42
		draw_arc(c, r, deg_to_rad(-60.0), deg_to_rad(240.0), 48, sombre, r * 0.42)
		var a: float = deg_to_rad(240.0)
		var n := Vector2(cos(a), sin(a))          # radiale : du centre vers le bout de l'arc
		var t := Vector2(-sin(a), cos(a))         # tangente, dans le sens où l'arc a été tracé
		var p: Vector2 = c + n * r
		draw_colored_polygon(PackedVector2Array([
			p + t * (r * 0.66), p + n * (r * 0.58), p - n * (r * 0.58)]), sombre)

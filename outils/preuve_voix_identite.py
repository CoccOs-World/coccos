#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Preuve d'identité de voix — le mot synthétisé à la volée sonne-t-il comme son
clip embarqué ?

Compare, pour chaque mot qui existe des DEUX côtés :
  · la CRÊTE (la recette vise -4 dBFS) ;
  · la HAUTEUR moyenne, par autocorrélation — c'est elle qui dit « même voix » ;
  · la DURÉE, donc le débit.

Le modèle VITS a un prédicteur de durée STOCHASTIQUE (noise_w 0.8) : deux
rendus du même mot ne durent pas exactement pareil, y compris avec le binaire
Piper d'origine. La durée est donc jugée sur l'étendue mesurée du modèle
lui-même, pas sur une égalité stricte.

À lancer APRÈS outils/preuve_voix_piper.gd, qui écrit les rendus à la volée
dans /tmp/preuve_voix_piper/compare_<mot>.wav.
Code de sortie 0 = tout vert.
"""
import os
import sys
import wave

import numpy as np

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIPS = os.path.join(RACINE, "lang", "fr", "voix", "mots")
RENDUS = "/tmp/preuve_voix_piper"

TOLERANCE_CRETE_DB = 0.5     # la normalisation doit tomber pile
TOLERANCE_HAUTEUR = 0.10     # 10 % : au-delà, ce n'est plus la même voix
TOLERANCE_DUREE = 0.35       # couvre l'étendue propre au modèle (mesurée ~0,27 s)


def lire(chemin):
    with wave.open(chemin, "rb") as w:
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64)
        if w.getnchannels() == 2:
            x = x[::2]
        return x, w.getframerate()


def db(valeur):
    return 20 * np.log10(max(valeur, 1e-9) / 32767.0)


def hauteur(x, fr):
    """Hauteur moyenne (Hz) sur la tranche la plus énergique — 60 à 400 Hz."""
    fenetre = max(fr // 50, 1)
    if len(x) < fenetre * 2:
        return 0.0
    energie = np.convolve(x ** 2, np.ones(fenetre) / fenetre, "same")
    centre = int(np.argmax(energie))
    tranche = x[max(0, centre - fr // 20):min(len(x), centre + fr // 20)]
    tranche = tranche - tranche.mean()
    if tranche.std() < 1:
        return 0.0
    auto = np.correlate(tranche, tranche, "full")[len(tranche) - 1:]
    bas, haut = fr // 400, fr // 60
    if haut >= len(auto):
        return 0.0
    return fr / (bas + int(np.argmax(auto[bas:haut])))


def main():
    if not os.path.isdir(RENDUS):
        sys.exit("Rendus absents : lancer d'abord outils/preuve_voix_piper.gd")
    paires = sorted(f[len("compare_"):-len(".wav")]
                    for f in os.listdir(RENDUS)
                    if f.startswith("compare_") and f.endswith(".wav"))
    if not paires:
        sys.exit("Aucune paire compare_*.wav dans " + RENDUS)

    print("mot        source        durée   crête dB   hauteur")
    echecs = 0
    for mot in paires:
        clip = os.path.join(CLIPS, mot + ".wav")
        if not os.path.isfile(clip):
            print("  (pas de clip embarqué pour %s — ignoré)" % mot)
            continue
        mesures = {}
        for etiquette, chemin in (("clip", clip),
                                  ("à la volée", os.path.join(RENDUS, "compare_%s.wav" % mot))):
            x, fr = lire(chemin)
            mesures[etiquette] = (len(x) / fr, db(np.abs(x).max()), hauteur(x, fr))
            print("%-10s %-12s %5.2f s  %7.2f   %5.0f Hz"
                  % (mot if etiquette == "clip" else "", etiquette, *mesures[etiquette]))
        (da, ca, ha), (dn, cn, hn) = mesures["clip"], mesures["à la volée"]
        ok_crete = abs(cn - (-4.0)) < TOLERANCE_CRETE_DB
        ok_hauteur = abs(ha - hn) / max(ha, 1.0) < TOLERANCE_HAUTEUR
        ok_duree = abs(da - dn) < TOLERANCE_DUREE
        vert = ok_crete and ok_hauteur and ok_duree
        echecs += 0 if vert else 1
        print("           > %s crête %s · hauteur %s (%+.0f%%) · débit %s (%+.2f s)"
              % ("VERT " if vert else "ROUGE",
                 "=" if ok_crete else "≠",
                 "=" if ok_hauteur else "≠", 100 * (hn - ha) / max(ha, 1.0),
                 "=" if ok_duree else "≠", dn - da))
    print("ÉCHECS : %d" % echecs)
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())

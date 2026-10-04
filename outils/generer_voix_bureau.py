#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Voix du bureau — pré-génération des clips Piper (voix siwis FEMME).

Option 1 : le vocabulaire FIXE du bureau est rendu une fois pour toutes en WAV
et embarqué dans lang/fr/voix/<categorie>/<terme>.wav. Voix.dire() les trouve
AVANT de tomber sur la synthèse vocale du système — aucune modification du
moteur, aucune dépendance au moment de l'exécution.

Recette (identique à celle d'Odyssée, variante femme) :
  piper -m fr_FR-siwis-medium.onnx --length-scale 1.3
  puis peak-normalisation à ~-4 dB, resample 44100 Hz mono 16 bits.

Le NOM DE FICHIER est le terme EXACT passé à Voix.dire (casse et accents
compris) ; l'INPUT donné à Piper est un texte LISIBLE (les mots tout en
capitales sont mis en minuscules, sinon espeak les ÉPELLE ; une LETTRE SEULE
est remplacée par son nom écrit, sinon espeak lui colle un marqueur parasite —
voir NOMS_LETTRES).

Les termes sont LUS dans les sources du bureau (aucune liste recopiée à la
main) : voir enumerer_termes(). Idempotent : un WAV valide n'est pas refait.
Outil de génération — ni le modèle ni piper n'entrent dans le dépôt.
"""
import html
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELE = os.environ.get("MODELE_PIPER", os.path.expanduser(
    "~/Documents/Polytalents FFMB/DEV_CoccOs_Minijeux/sources_production/"
    "echantillons_voix/modeles/fr_FR-siwis-medium.onnx"))
SORTIE = os.path.join(RACINE, "lang", "fr", "voix")

LENGTH_SCALE = "1.3"
CIBLE_CRETE = -4.0      # dB
TAILLE_MIN = 1000       # octets : seuil de validité pour l'idempotence
WORKERS = 6
FORCE = os.environ.get("VOIX_FORCE") == "1"

# Le compteur du jeu des ballons n'a PAS de plafond dans le code : on couvre la
# plage réellement atteignable dans une partie d'enfant, au-delà = synthèse.
CHIFFRE_MAX = 200

_re_db = re.compile(r"max_volume:\s*(-?[0-9.]+)\s*dB")
_RE_CAPS = re.compile(r"[A-ZÀ-ÖØ-ÞŒŸ]{2,}")

# Le NOM ÉCRIT des 26 lettres. Une lettre SEULE envoyée au phonémiseur reçoit
# d'espeak un marqueur parasite — « _! » sur les 12 lettres à attaque vocalique
# (E F H I L M N O R S U X), « _| » sur Y — et l'enfant entend une attaque en
# trop (« le » pour E, « vi » pour U). Le nom écrit lève le marqueur.
# Pièges déjà réglés dans la table : « èmme » pour M (sinon la nasale « amme »),
# « ie grec » pour Y (sinon le marqueur revient sur le « i » isolé).
# Table JUMELLE de scripts/voix_piper.gd : les deux restent en phase.
NOMS_LETTRES = {
    "A": "a", "B": "bé", "C": "cé", "D": "dé", "E": "euh", "F": "effe",
    "G": "gé", "H": "ache", "I": "ie", "J": "ji", "K": "ka", "L": "elle",
    "M": "èmme", "N": "enne", "O": "eau", "P": "pé", "Q": "ku", "R": "erre",
    "S": "esse", "T": "té", "U": "ue", "V": "vé", "W": "doublevé",
    "X": "ixe", "Y": "ie grec", "Z": "zède",
}


def texte_pour_tts(texte):
    """Texte LISIBLE pour le phonémiseur : une lettre SEULE devient son nom
    écrit ; un mot tout en capitales est LU, pas épelé."""
    if len(texte) == 1:
        return NOMS_LETTRES.get(texte.upper(), texte)
    return _RE_CAPS.sub(lambda m: m.group(0).lower(), texte)


# --- Lecture des termes dans les sources du bureau --------------------------------

def _source(*bouts):
    with open(os.path.join(RACINE, *bouts), encoding="utf-8") as f:
        return f.read()


def _const_chaine(texte, nom):
    m = re.search(r'const %s := "([^"]*)"' % nom, texte)
    if not m:
        raise RuntimeError("constante introuvable : " + nom)
    return m.group(1)


def libelles_classeur():
    """Les libellés des planches TLAb embarquées, lus comme le fait planche_tlab.gd."""
    re_cellule = re.compile(
        r'<g [^>]*transform="translate\(([\d.]+), ([\d.]+)\)"[^>]*>(.*?)</g>')
    re_rect = re.compile(r'<rect [^>]*width="([\d.]+)" height="([\d.]+)" fill="([^"]*)"')
    re_texte = re.compile(r'<text[^>]*>([^<]*)</text>')
    dossier = os.path.join(RACINE, "classeur")
    libelles = []
    for fichier in sorted(os.listdir(dossier)):
        if os.path.splitext(fichier)[1].lower() not in (".tlab", ".svg"):
            continue
        with open(os.path.join(dossier, fichier), encoding="utf-8") as f:
            svg = f.read()
        for cellule in re_cellule.finditer(svg):
            contenu = cellule.group(3)
            if not re_rect.search(contenu):
                continue  # pas de cadre → la cellule est ignorée par le parseur
            lignes = [t.group(1).strip() for t in re_texte.finditer(contenu)]
            libelle = " ".join(l for l in lignes if l).strip()
            if libelle and libelle not in libelles:
                libelles.append(libelle)
    return libelles


def noms_caracteres_speciaux():
    """Les noms prononcés des touches spéciales : CLES_SPECIAUX → lang/fr/textes.xml."""
    lettres = _source("scripts", "clavier", "jeu_lettres.gd")
    bloc = re.search(r"const CLES_SPECIAUX := \{(.*?)\n\}", lettres, re.S).group(1)
    cles = re.findall(r':\s*"(car_[a-z_]+)"', bloc)
    textes = _source("lang", "fr", "textes.xml")
    noms = []
    for cle in cles:
        m = re.search(r'<texte cle="%s">([^<]*)</texte>' % cle, textes)
        if not m:
            raise RuntimeError("traduction absente pour " + cle)
        nom = html.unescape(m.group(1)).strip()
        if nom not in noms:
            noms.append(nom)
    return noms


def mot_tapable(mot):
    """Reprise de jeu_mots.gd::_mot_tapable (mode clavier : accents acceptés)."""
    if not 2 <= len(mot) <= 12:
        return False
    return all(c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" or c in "ÉÈÊËÀÂÄÎÏÔÖÙÛÜÇ" for c in mot)


def enumerer_termes():
    """{categorie: [termes]} — le vocabulaire FIXE dit par le bureau."""
    lettres_src = _source("scripts", "clavier", "jeu_lettres.gd")
    acceptes = _const_chaine(lettres_src, "CARACTERES_ACCEPTES")
    lettres = [c for c in acceptes if c not in "0123456789"]

    mots_src = _source("scripts", "clavier", "jeu_mots.gd")
    defaut = re.search(r"const MOTS_DEFAUT := \[(.*?)\]", mots_src).group(1)
    mots = re.findall(r'"([^"]+)"', defaut)
    libelles = libelles_classeur()
    for libelle in libelles:
        candidat = libelle.strip().upper()
        if mot_tapable(candidat) and candidat not in mots:
            mots.append(candidat)

    return {
        "chiffres": [str(n) for n in range(CHIFFRE_MAX + 1)],
        "lettres": lettres,
        "mots": mots,
        "phrases": libelles + [n for n in noms_caracteres_speciaux() if n not in libelles],
    }


# --- Rendu ------------------------------------------------------------------------

def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def peak_db(chemin):
    r = run(["ffmpeg", "-hide_banner", "-i", chemin, "-af", "volumedetect",
             "-f", "null", "/dev/null"])
    m = _re_db.search(r.stderr)
    if not m:
        raise RuntimeError("volumedetect sans max_volume : " + r.stderr[-300:])
    return float(m.group(1))


def valide(chemin):
    return os.path.isfile(chemin) and os.path.getsize(chemin) >= TAILLE_MIN


def generer(tache):
    categorie, terme = tache
    sortie = os.path.join(SORTIE, categorie, terme + ".wav")
    if not FORCE and valide(sortie):
        return (categorie, terme, True, None)
    with tempfile.TemporaryDirectory(prefix="voix_bureau_") as td:
        base = os.path.join(td, "base.wav")
        p = run(["piper", "-m", MODELE, "--length-scale", LENGTH_SCALE, "-f", base],
                input=texte_pour_tts(terme))
        if p.returncode != 0 or not valide(base):
            return (categorie, terme, False,
                    "piper: " + (p.stderr[-300:] or "sortie vide"))
        try:
            gain = CIBLE_CRETE - peak_db(base)
        except Exception as e:
            return (categorie, terme, False, str(e))
        r = run(["ffmpeg", "-hide_banner", "-y", "-i", base,
                 "-af", "volume=%.3fdB,aresample=44100" % gain,
                 "-ac", "1", "-c:a", "pcm_s16le", sortie])
        if r.returncode != 0 or not valide(sortie):
            return (categorie, terme, False, "ffmpeg: " + r.stderr[-300:])
    return (categorie, terme, True, None)


def main():
    if not os.path.isfile(MODELE):
        sys.exit("Modèle Piper introuvable : " + MODELE)
    termes = enumerer_termes()
    taches = []
    for categorie, liste in termes.items():
        os.makedirs(os.path.join(SORTIE, categorie), exist_ok=True)
        taches += [(categorie, t) for t in liste]
    print("Termes à rendre : " + ", ".join(
        "%s=%d" % (c, len(l)) for c, l in termes.items()), flush=True)

    echecs = []
    faits = 0
    with ThreadPoolExecutor(max_workers=WORKERS) as pool:
        futurs = [pool.submit(generer, t) for t in taches]
        for futur in as_completed(futurs):
            categorie, terme, ok, err = futur.result()
            faits += 1
            if not ok:
                echecs.append("%s/%s : %s" % (categorie, terme, err))
            if faits % 25 == 0:
                print("  %d/%d" % (faits, len(taches)), flush=True)
    print("Rendus : %d/%d" % (len(taches) - len(echecs), len(taches)))
    for e in echecs:
        print("  ÉCHEC " + e)
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())

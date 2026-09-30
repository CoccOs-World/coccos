#!/bin/bash
# Réduit espeak-ng-data (19 Mio, 113 langues) au strict nécessaire FRANÇAIS (0,75 Mio).
# Vérifié le 30-09-2026 : phonèmes et phoneme_ids IDENTIQUES au jeu complet.
# $1 = espeak-ng-data complet   $2 = dossier de sortie
SRC="$1"; DST="$2"; mkdir -p "$DST/lang/roa" "$DST/voices"
cp "$SRC"/phontab "$SRC"/phonindex "$SRC"/phondata "$SRC"/phondata-manifest "$SRC"/intonations "$SRC"/fr_dict "$DST/"
cp "$SRC"/lang/roa/fr "$DST/lang/roa/"
cp -r "$SRC"/voices/\!v "$DST/voices/"
du -sh "$DST"

# Identité Lucarne

Logo du produit, redessiné en vecteur le 12/11/2026 d'après l'esquisse de
Samih (but, ballon en pleine lucarne, traînée verte).

- `logo_clair.svg` : logo complet sur fond blanc (magasins d'applis, documents).
- `logo_sombre.svg` : logo complet sur le fond bleu nuit de l'appli.
- `logo_sombre_transparent.svg` : idem sans fond, exporté en
  `web/lucarne_logo.webp` (écran de démarrage) et
  `assets/images/lucarne_logo.webp` (écran de connexion).
- `icone.svg` : icône sans texte → `web/icons/Icon-192.png`, `Icon-512.png`,
  `web/favicon.svg`, `web/favicon.png`.
- `icone_maskable.svg` : marge de sécurité Android → `Icon-maskable-512.png`.
- `badge.svg` : silhouette blanche des notifications Android →
  `web/icons/notification-badge-96.png`.
- `gen2.py` : génère tous les SVG (police Oswald intégrée, vert `#2EE57A`).

## Licence de la police du logo

Le générateur `gen2.py` intègre la police **Oswald** dans le code. Les trois
logos SVG contenant le mot « LUCARNE » embarquent également cette police au
format `@font-face`. Leur redistribution est soumise à la licence libre
**SIL Open Font License 1.1 (OFL-1.1)**.

- Titulaire du droit : **Copyright 2016 The Oswald Project Authors**.
- Projet source : https://github.com/googlefonts/OswaldFont
- Texte de licence redistribué avec les fichiers : [OFL-Oswald.txt](OFL-Oswald.txt)
- Licence officielle de référence : https://github.com/google/fonts/blob/main/ofl/oswald/OFL.txt
- Oswald peut être utilisée dans un produit commercial sous réserve du
  respect de la licence, notamment de la conservation des notices lorsqu'une
  copie de la police est redistribuée.

Cette notice couvre **la police Oswald seulement** ; elle ne constitue pas
une vérification de disponibilité de la marque « Lucarne », des droits sur les
autres ressources graphiques, ni des usages particuliers du logo.

L'écusson neutre `assets/images/club_crest.webp` reste celui des clubs qui
n'ont pas envoyé de logo : ce n'est pas le logo du produit.

# Identité Petit Filet

Logo du produit fourni par Samih le 13/11/2026 : monogramme « PF » bleu
marine, ballon cerclé de blanc, traînée jaune, mots « Petit » (bleu) et
« Filet » (jaune) avec halo lumineux.

**Le logo n'est pas redessiné** (demande explicite de Samih) : toutes les
images de l'appli sont tirées de l'image d'origine `logo_original.png`
(1536 × 1024) par `tool/branding/petit_filet_assets.py`.

| Fichier de l'appli | Contenu |
| --- | --- |
| `web/icons/Icon-192.png`, `Icon-512.png`, `web/favicon.png`, `web/favicon.svg` | image d'origine entière (halo estompé au bord), posée sur un carré noir |
| `web/icons/Icon-maskable-512.png` | idem avec 10 % de marge (découpe ronde d'Android) |
| `web/petit_filet_logo.webp` (démarrage), `assets/images/petit_filet_logo.webp` (connexion) | image d'origine, noir rendu transparent de façon exacte, halo estompé sur les 60 px du bord pour ne pas laisser d'arête |
| `web/icons/notification-badge-96.png` | ballon du logo en silhouette blanche (Android n'utilise que la transparence) |

Pour régénérer après un changement de logo : remplacer `logo_original.png`
puis lancer `python3 tool/branding/petit_filet_assets.py`.

## Limites connues

- Le logo d'origine est une image en pixels, avec un flou volontaire : il ne
  peut pas être agrandi au-delà de sa taille sans perte.
- En icône carrée, le logo entier (texte compris) est petit ; à 32-64 px
  (onglet du navigateur) on ne distingue plus que le ballon et les couleurs.
- Le logo semble généré par une IA : les droits d'usage commercial et la
  disponibilité de la marque ne sont pas vérifiés ici.

L'écusson neutre `assets/images/club_crest.webp` reste celui des clubs qui
n'ont pas envoyé de logo : ce n'est pas le logo du produit.

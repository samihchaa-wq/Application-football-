# Identité Petit Filet

Logo du produit fourni par Samih le 13/11/2026 : monogramme « PF » bleu
marine avec ballon et filet, traînée jaune, mots « Petit » (bleu marine) et
« Filet » (jaune), sur fond transparent.

**Le logo n'est ni redessiné ni retouché** (demande explicite de Samih) :
toutes les images de l'appli sont tirées de l'image d'origine
`logo_original.png` (1536 × 1024, transparente) par
`tool/branding/petit_filet_assets.py`.

| Fichier de l'appli | Contenu |
| --- | --- |
| `web/icons/Icon-192.png`, `Icon-512.png`, `web/favicon.png`, `web/favicon.svg` | logo entier sur un carré blanc |
| `web/icons/Icon-maskable-512.png` | idem avec plus de marge (découpe ronde d'Android) |
| `web/petit_filet_logo.webp` (démarrage), `assets/images/petit_filet_logo.webp` (connexion) | image d'origine avec sa transparence, affichée sur une tuile blanche |
| `web/icons/notification-badge-96.png` | parties blanches du ballon, en silhouette (Android n'utilise que la transparence) |

Le logo est bleu marine : sur le fond bleu nuit de l'appli il serait
invisible, d'où la tuile blanche à l'écran de démarrage et de connexion.

Pour régénérer après un changement de logo : remplacer `logo_original.png`
puis lancer `python3 tool/branding/petit_filet_assets.py`.

## Limites connues

- En icône carrée, le logo entier (texte compris) est petit ; à 32-64 px
  (onglet du navigateur) le texte n'est plus lisible.
- Le logo semble généré par une IA : les droits d'usage commercial et la
  disponibilité de la marque ne sont pas vérifiés ici.

L'écusson neutre `assets/images/club_crest.webp` reste celui des clubs qui
n'ont pas envoyé de logo : ce n'est pas le logo du produit.

# Identité Petit Filet — rouge, anthracite et argent

Mise à jour du 15 novembre 2026, à la demande de Samih et à partir du nouveau
logo définitif transmis le même jour. La source actuelle est
`logo_final_clean.webp` (1536 × 1024). Le fond et les ouvertures du filet
ont été rendus transparents ; les contours blancs et argentés du logo final
rendent le monogramme sombre lisible sur l'anthracite sans tuile blanche. Le fichier
`logo_original.png` est conservé comme référence historique de l'ancien logo.

## Palette de l'application

| Usage | Couleur |
| --- | --- |
| Fond | `#101418` |
| Cartes | `#191F25` |
| Surfaces hautes / champs | `#242C34` |
| Boutons à texte blanc | `#D71932` |
| Liens et accents lisibles sur sombre | `#FF7585` |
| Texte principal | `#F5F7FA` |
| Texte secondaire | `#D7DDE4` |
| Texte discret | `#A9B4C0` |

Le rouge du logo conserve ses reflets d'origine. Les variantes de rouge de
l'interface sont choisies selon le contraste texte/fond, sans recolorer le
logo. Les couleurs personnalisées des clubs restent fonctionnelles ; les
maillots et logos des clubs restent indépendants de l'identité du produit.
Les couleurs sémantiques de disponibilité, succès, avertissement et récompense
restent différenciées.

## Déclinaisons

| Fichier | Contenu |
| --- | --- |
| `assets/images/petit_filet_logo.webp`, `web/petit_filet_logo.webp` | Logo complet, alpha transparent, sans tuile blanche à la connexion et au démarrage |
| `web/icons/Icon-192.png`, `Icon-512.png` | Monogramme PF/ballon/filet sur carré anthracite, sans texte minuscule |
| `web/icons/Icon-maskable-512.png` | Monogramme dans la zone sûre centrale de l'icône Android |
| `web/favicon.png`, `web/favicon.svg` | Monogramme adapté aux petites tailles |
| `web/icons/notification-badge-96.png` | Silhouette blanche du ballon avec coutures transparentes |

Régénération : `python3 tool/branding/petit_filet_assets.py` depuis `logo_final_clean.webp`. Les versions WebP de l’application proviennent de cette source corrigée.
`monogram_red_transparent.png` est l'extraction dédiée du symbole, sans le
nom ni le soulignement. Le script réalise uniquement les déclinaisons de ces
deux sources transparentes.
Le fond opaque des icônes d'installation est volontaire (découpe et lisibilité
sur iOS/Android) ; le logo utilisé dans les écrans reste transparent.

## Validation

Alpha, lisibilité sur fond sombre et clair, dimensions des déclinaisons,
zone sûre Android et contraste des textes : vérifications locales réussies. Les tests
Flutter existants sur le contraste, le contrat PWA, les écrans de connexion et
le bilan de saison couvrent les chemins concernés ; le test de contraste est
étendu aux paires du thème par défaut. Les résultats CI sur la PR constituent
la preuve d'analyse/tests/build sur le dernier SHA. Le formatage Dart a été
exécuté localement ; le SDK Flutter local est incomplet, donc l'analyse,
la suite Flutter et le build Web sont validés dans GitHub Actions.
La PR #139 porte ces changements et les résultats de validation.
Ce document n'affirme aucun déploiement.

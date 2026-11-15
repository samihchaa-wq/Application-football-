# Identité Petit Filet — rouge, anthracite et argent

Mise à jour du 15 novembre 2026, à la demande de Samih et à partir du nouveau
logo transmis. La source actuelle est `logo_red_transparent.png` (1536 × 1024).
Le fond blanc a été retiré ; un fin contour argenté rend le monogramme sombre
lisible sur l'anthracite sans tuile blanche ni halo. Le fichier
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

Régénération : `python3 tool/branding/petit_filet_assets.py`.
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
la preuve d'analyse/tests/build. Le SDK Flutter est absent dans cette session :
formatage Dart, analyse, tests Flutter et build Web ne sont pas exécutés
localement. Aucun résultat CI n'est disponible tant que la branche n'est pas
envoyée. Ce document n'affirme aucun déploiement.

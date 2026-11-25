# Évaluation UI/UX Pro Max — style, couleurs, typo, icônes, navigation, animations (25 novembre 2026)

Complète `docs/AUDIT_UX_ECRAN_PAR_ECRAN_20261125.md` (tailles d'écran, états, accessibilité, formulaires). Ici : grille du skill `ui-ux-pro-max` (règles UX, checklist app mobile, règles Flutter). Aucun code modifié.

## Méthode et limites

- Recherches dans la base du skill (contraste, zones à toucher, retour/navigation, mouvement réduit, palette « club de sport », typographie, thème Flutter) + lecture du thème (`app_theme.dart`) + comptages dans `lib/`.
- Contrastes calculés par formule (WCAG), pas mesurés à l'écran.
- **Rien vu à l'écran** (pas de Docker). Texte agrandi, mouvement réduit et clavier réel : non vérifiés (déjà notés « non vérifié » dans `docs/HANDOFF.md`).
- Le skill donne des repères génériques ; je ne les applique pas quand ils contredisent un choix de design assumé de l'app.

## Verdict

Identité visuelle cohérente et solide. Pas de défaut majeur sur ces axes. Quelques écarts de rigueur (jetons de design, emoji, durées d'animation), tous de gravité « détail ».

## Ce qui est bon

| Sujet | Constat |
|---|---|
| Style | Thème unique « Nuit » (fond #0B0F14, cartes en relief, rouge + ambre, titres Oswald condensée de stade). Cohérent avec un club de foot. Le skill propose pour le sport « Barlow Condensed » : Oswald joue déjà ce rôle, aucun changement utile. |
| Contraste du texte | Texte principal, secondaire et « faible » (#93A0AD) : 6,6:1 sur les cartes, 5,6:1 sur les cartes surélevées (seuil 4,5:1 respecté). Lien « texte » en rouge clair `primaryBright` : 6,4:1. Texte blanc sur bouton rouge : 5,15:1. Accent ambre sur fond sélectionné : 8,1:1. |
| Couleurs de club | Le thème ramène automatiquement les couleurs du club dans une plage lisible et vérifie le contraste (`applyClubColors`). Point rare et à garder. |
| Contour | Contour #6B7885 : 3,9:1 sur les cartes, 4,3:1 sur le fond (seuil 3:1 des éléments d'interface respecté pour les contours pleins). |
| Navigation | Deux onglets en bas (limite recommandée : 5), barre latérale au-delà de 840 px, retour avec repli vers le calendrier, routes déclaratives (`go_router`). Page d'erreur de navigation ajoutée aujourd'hui. |
| Icônes | 90 % en contour (496 sur ~554) : famille cohérente. Les 53 sans suffixe sont surtout des flèches/actions sans variante contour (`chevron_right`, `refresh`, `add`, `close`). |
| États | Boutons désactivés distincts (élévation 0, fond atténué), erreur en rouge avec fond propre, transition de page qui respecte « réduire les animations ». |

## Écarts (par gravité)

| # | Gravité | Écart | Détail |
|---|---|---|---|
| 1 | Détail | **Rouge principal utilisé comme couleur de texte ou d'icône** : `AppTheme.primary` (#D71932) fait 3,4:1 sur les cartes, sous les 4,5:1 d'un texte. Seulement 4 usages (profil L166, tuile de maillot L124, carte météo L75, composition L497), plusieurs en teinte transparente. Le reste utilise `primaryBright`. | Remplacer par `primaryBright` si c'est du texte ; sinon vérifier à l'écran. |
| 2 | Détail | **Emoji comme icônes** (24 lignes hors commentaires) : 👑 « Homme du match » (vote, composition), ⚽ pour les buts, ✏️ comme icône de bouton (dans du code non utilisé). Les 🏅 des badges sont de la donnée (prévu par le produit). La règle du skill : pas d'emoji pour des contrôles ou des marqueurs d'interface (rendu variable selon l'appareil, non thémable). | Remplacer 👑/⚽ par des icônes vectorielles ou garder volontairement (marqueurs de contenu). Décision à prendre. |
| 3 | Détail | **Famille d'icônes mélangée** : 5 icônes « arrondies » (`star_rounded` ×2, `check_circle_rounded`, 2 dans le détail de badge) au milieu de 496 contours. | Passer en contour ou assumer pour les badges. |
| 4 | Détail | **Tailles de texte écrites en dur** : 176 `fontSize:` contre 251 usages du thème de texte. Règle Flutter du skill : passer par `Theme.of(context).textTheme`. Déjà lié au constat des petits textes 10–11 px. | Migrer progressivement, surtout les 10–11 px. |
| 5 | Détail | **Couleurs hors thème** : 165 `Color(0x…)` et 58 `Colors.white` hors fichier de thème. Audit du 24/11 : la quasi-totalité sont des palettes voulues (maillots, badges, terrain). Non réexaminé. | Rien à faire sauf dérive nouvelle. |
| 6 | Détail | **Durées d'animation sans jetons** : une dizaine de valeurs (120, 140, 150, 160, 200, 250, 280, 350, 700, 900 ms…). Règle du skill : durées partagées, choisies selon la distance et le contexte. | Définir 3 durées (court, moyen, long) dans le thème. |
| 7 | À vérifier | **Contour des champs et des cartes en transparence** (opacité ~.5) : le calcul ci-dessus vaut pour le contour plein ; avec transparence il passe sous 3:1. Un relecteur a mesuré ~1,6:1 sur les champs. | Mesurer à l'écran. |
| 8 | À vérifier | **Thème sombre seul** : le skill recommande de respecter le réglage clair/sombre du système. Ici c'est un choix de produit (identité « Nuit »). | Décision produit, pas un défaut. |
| 9 | À vérifier | **Gestes sans alternative** : glisser-déposer de la composition (appui long) et glisser sur les cartes de l'effectif. Règle du skill : alternative bouton/clavier. Déjà dans l'audit écran par écran. | Voir lot « clavier sur la composition ». |

## Checklist de livraison du skill (app mobile)

| Point | Statut |
|---|---|
| Pas d'emoji comme icônes | **Presque** : écarts 👑/⚽ (écart 2) |
| Une seule famille d'icônes | **Presque** (écart 3) |
| Jetons de thème sémantiques | **Oui en grande partie** (écarts 4 et 5) |
| Retour d'appui sans décalage de mise en page | Non vérifié |
| Cibles ≥ 44 px | **Corrigé aujourd'hui** pour l'en-tête ; restent les +/− de la liste d'attente (34 px), cloches, boutons vidéo |
| Contraste ≥ 4,5:1 clair et sombre | **Oui** pour le texte (thème sombre seul) ; contours transparents à mesurer |
| Zones sûres, contenu non masqué par une barre fixe | Non vérifié à l'écran |
| Testé à 375 px et en paysage | Fait le 24/11 d'après `HANDOFF.md` (375, 1280, 812×375) ; pas refait ici |
| Mouvement réduit et texte agrandi | **Non vérifié** (aucun rendu) |
| Étiquettes, erreurs de champ, focus | Voir l'audit écran par écran |

## Propositions

1. Remplacer `primary` par `primaryBright` quand il sert de texte (4 endroits) : petit.
2. Décider du sort des emoji 👑 et ⚽ : icônes vectorielles ou garder : petit.
3. Poser 3 durées d'animation dans le thème et les utiliser : moyen.
4. Migrer les `fontSize` en dur vers le thème de texte, en commençant par les 10–11 px : moyen (à faire avec captures).
5. Mesurer le contour des champs et des cartes à l'écran : demande un environnement avec rendu.

## Ce qui reste à faire

- **Toi** : trancher 2 (emoji) et 8 (thème sombre seul = voulu ?).
- **Moi, après accord** : points 1 et 3 sont sûrs sans écran ; 4 et 5 demandent un rendu.

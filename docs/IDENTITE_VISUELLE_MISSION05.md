# Mission 05 — Audit d'identité visuelle et UX (avant toute création de marque)

**Date :** 12 novembre 2026  
**État :** audit de code et **inspection visuelle des fichiers image sources** documentés ; **interface applicative non validée en rendu réel**.  
**Périmètre :** dépôt commercial `samihchaa-wq/Application-football-`, branche `main` au début de l'étude ; original `AS-Grinta` consulté **en lecture seule** pour comparaison des ressources.  
**Coordination :** chef de projet fil 00, tableau [CHANTIER.md](CHANTIER.md) en PR [#29](https://github.com/samihchaa-wq/Application-football-/pull/29) ; décisions fonctionnelles fil 01 dans [PR #25](https://github.com/samihchaa-wq/Application-football-/pull/25). Ce document ne valide aucun nom, logo ni changement de thème.

## 1. Doctrine de la mission

Le produit commercial doit **conserver au maximum l'expérience d'AS Grinta** : hiérarchie des informations, navigation intuitive, surfaces denses, arrondis, jeu des contrastes, badges, trophées et animations footballistiques. Il ne faut **pas** réécrire un composant stable pour une simple préférence esthétique.

Séparer deux identités :
- **Marque du produit** (nom, symbole de l'application installée, favicon, identité avant connexion, mentions de plateforme) : commune à tous les clubs, **à définir et valider**.
- **Identité du club** (nom, nom court, écusson, couleurs, éventuellement maillots) : réglée par chaque administrateur et utilisée dans les écrans liés à son club.

Aucun changement de code, de données, de déploiement ou de ressources n'est demandé par ce document. Aucun coût engagé.

## 2. Sources et niveau de vérification

Lecture de :
- `lib/core/theme/app_theme.dart`, `app_spacing.dart`, `lib/app/shell/app_shell.dart`, `lib/core/widgets/grinta_*.dart`, `docs/ui-foundations.md` ;
- `lib/core/club/club_identity.dart`, `lib/features/club/presentation/club_identity_sync.dart`, `lib/features/admin/presentation/club_settings_page.dart` ;
- `lib/features/auth/presentation/auth_sign_in_page.dart`, `lib/features/matches/presentation/matches_page.dart`, `lib/features/badges/presentation/badge_emblem.dart` et `badge_descriptor.dart` ;
- `lib/features/season_wrapped/presentation/wrapped_theme.dart`, `wrapped_motion.dart`, `lib/features/sports_management/presentation/widgets/composition_presentation.dart` ;
- `web/index.html`, `web/manifest.json`, `web/favicon.svg`, répertoires `web/icons/`, `assets/`, `docs/branding/`, `pubspec.yaml`.

**Preuves acquises :** présence et branchement des composants dans les sources, valeurs des constantes, chemins des ressources, comparaison des SHA GitHub ; **visualisation directe des fichiers** `assets/images/club_crest.webp`, `web/club_crest.webp`, `web/favicon.png`, `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-512.png`, `assets/composition/stade.jpg`, des trois PNG de maillots et, en comparaison, de l'icône, du blason et de l'affiche de stade du dépôt original (lecture seule).  
**Non vérifié :** captures/rendu final de l'**application en fonctionnement**, facilité de navigation de vrais joueurs, contraste mesuré sur chaque couleur, performances sur mobiles, compatibilité PWA installée, licences et autorisations des vidéos/illustrations. Aucun `flutter test`, `flutter analyze` ni test navigateur n'a été exécuté pour cette étude documentaire.

## 3. Design existant à préserver : chiffres et principes

| Domaine | Constat vérifié dans le code | Orientation |
| --- | --- | --- |
| Fond sombre | `AppTheme.background = #041224`, surface `#091B33`, surface haute `#102A4A`, surface héro `#173D6E` | **Conserver** la structure sombre lors de la première adaptation |
| Couleurs par défaut | primaire `#1A4AC0`, primaire lumineuse `#6E93F6`, accent `#FBE80C` | **Conserver comme référence AS Grinta**, distinguer des couleurs finales de marque |
| Statuts | récompense `#FFD84A`, succès `#48C98B`, attention `#F0A34A`, erreur `#FF6F7D` | **Conserver** les fonctions sémantiques, ne pas les remplacer arbitrairement par les couleurs du club |
| Texte | principal `#F8FBFF`, secondaire `#DCE8F7`, atténué `#9FB4CC` | **Conserver**, puis vérifier la lisibilité réelle |
| Arrondis | `radiusSm = 12`, `radiusMd = 16`, `radiusLg = 22` | **Conserver** |
| Espacement | marges écran 8 px (Live 6), carte 12 (dense 10), section 8, contenu 6 | **Conserver**, surveiller les très petits appareils |
| Navigation | mobile : `NavigationBar` Calendrier / Statistiques ; ordinateur : `NavigationRail` à partir de 840 px, étendu à 1180 px | **Conserver** les parcours |
| Typographie | thème Material sur les écrans courants ; famille Oswald déclarée pour le bilan de saison | **Conserver**, vérifier les droits et rendus |
| Réduction des animations | `GrintaAnimatedCrest`, transitions et `wrapped_motion.dart` lisent la préférence système | **Conserver** et couvrir les autres animations lors des essais |

Le fond est historiquement bleu nuit, mais les couleurs primaire et secondaire de chaque club sont déjà répercutées sur une partie de l'UI par `AppTheme.applyClubColors`. Les valeurs de luminosité sont encadrées pour la lisibilité. Les couleurs d'état (succès, erreur, attente) doivent garder un sens stable.

## 4. Matrice : conserver exactement / adapter légèrement / remplacer impérativement

Le classement porte sur **l'expérience ou la ressource décrite**, pas nécessairement sur son nom technique interne.

| ID | Écran / élément | Classement | Preuve / raison | Action limitée proposée |
| --- | --- | --- | --- | --- |
| VIS-01 | Calendrier, cartes et retours dans l'historique | **Conserver exactement** | `app_shell.dart`, `matches_page.dart` ; recentrage et navigation déjà travaillés | Non-régression |
| VIS-02 | Barre supérieure, onglets, composants de formulaires, états d'erreur et vides | **Conserver exactement** | `grinta_app_bar.dart`, `grinta_secondary_tabs.dart`, `grinta_adaptive_form.dart`, `grinta_status_banner.dart`, `grinta_empty_state.dart` | Réutiliser les composants partagés |
| VIS-03 | Présentation de composition et stade animé | **Conserver exactement** pour la grammaire visuelle | `composition_presentation.dart`, vidéos et affiche de stade dans `assets/composition/` | Ne pas modifier les séquences sans besoin validé ; examiner les marques visuelles et droits média |
| VIS-04 | Mécanique badges, socles, étoiles et armoire | **Conserver exactement** | `badge_emblem.dart`, `badge_emblem_body.dart`, `armoire_page.dart` | Aucun nouveau style de badge sans comparaison visuelle |
| VIS-05 | Libellés de badges, trophées et récompenses | **Adapter légèrement** | `badge_descriptor.dart` comprend des critères et des libellés anciens dont `bet_against_grinta` / « TRAÎTRE » | Tester compatibilité avec tous clubs ; décider des libellés et conventions avec fil 01 |
| VIS-06 | Bilan de saison : scènes, typographie, rythme | **Conserver exactement** dans son principe | `wrapped_theme.dart`, `wrapped_motion.dart`, `wrapped_slides.dart` | Maintenir le spectacle, le son facultatif et la réduction des animations |
| VIS-07 | Couleurs du bilan de saison | **Adapter légèrement** | `wrapped_theme.dart` utilise `defaultAccent` et plusieurs bleus/jaunes fixes | Étudier un mode club lisible sans écraser les contrastes ; seulement après captures |
| VIS-08 | Nom, nom court, écusson et deux couleurs du club | **Conserver** la personnalisation, **adapter légèrement** ses limites | `ClubIdentity`, `club_identity_sync.dart`, `club_settings_page.dart` ; palette de 12 couleurs | Contraste, repli, retour aux valeurs par défaut, synchronisation et rendu |
| VIS-09 | Écran de connexion commun | **Adapter légèrement** | `GrintaAuthSurface` insère `Image.asset('assets/images/club_crest.webp')` en dur | Clarifier marque plateforme avant choix du club et écusson club après sélection |
| VIS-10 | Splash HTML pré-Flutter et chargement | **Adapter légèrement** | `web/index.html` référence `club_crest.webp`, conserve respiration/reflet/progression | Préserver animation et performances ; changer seulement le symbole une fois validé |
| VIS-11 | Trois maillots de match | **Adapter légèrement** | Visuels PNG inspectés : bleu à manches jaunes, orange à accents noirs, blanc à accents bleus | Préserver le dessin, mais vérifier si les combinaisons de clubs sont modifiables avec fil 01/02 |
| VIS-12 | Nom de produit visible (Flutter, navigateur, PWA) | **Remplacer impérativement avant lancement commercial** | `ClubIdentity.appName = 'Club'`, `web/manifest.json` name/short_name = `Club`, `web/index.html` title et titre iOS = `Club` | Unifier le **futur** nom commercial approuvé, avec tests PWA |
| VIS-13 | Sources SVG historiques de l'icône | **Examiner, puis remplacer si elles représentent AS Grinta** | `docs/branding/icone_app.svg` et `icone_app_android.svg` ont les **mêmes SHA** dans original et commercial | Aucun usage commercial sans vérification du graphisme et des droits |
| VIS-14 | Favicon et icônes PWA actuels | **Adapter au nom / logo final** | PNG 192, 512, maskable et favicon inspectés : écusson bleu générique au ballon blanc, **pas** l'icône historique « AS LA GRINTA » ; SVG du favicon également générique | Conserver le système de formats, contrôler cohérence, lisibilité et nom final |
| VIS-15 | Noms techniques internes `as_grinta`, `Grinta*`, identifiants JS | **Ne pas remplacer globalement** | Références code, imports, JS, service worker, tests ; non nécessairement visibles | Audit ciblé uniquement si nom visible, juridique ou conflit fonctionnel ; éviter régression |
| VIS-16 | Ressources audio du bilan | **Adapter seulement si besoin** | `assets/audio/README.md` décrit `wrapped.mp3` mais la piste n'est pas présente dans l'arbre lu | Ne pas promettre de musique ; examiner les droits avant ajout |
| VIS-17 | Police Oswald | **Conserver, sous réserve de conformité** | `assets/fonts/OFL-Oswald.txt` est présent (SIL OFL 1.1) | Conserver notice et conditions de distribution |
| VIS-18 | Logo générique de repli | **Conserver le mécanisme**, identité produit à confirmer | Fichier WebP inspecté : écu bleu vif, bord blanc et ballon stylisé blanc, sans inscription AS Grinta visible | Le visuel est neutre sur l'écrit ; décider s'il devient logo produit ou simple écusson par défaut |\n| VIS-19 | Décor de stade — drapeaux et tribunes | **Adapter légèrement** la ressource **si elle est censée être multiclub** | Affiche `stade.jpg` commerciale inspectée et comparée à l'original : fond de stade conservé avec nombreux drapeaux **bleu et jaune**, couleurs historiquement associées à AS Grinta | Évaluer avec fil 01/02 une version de décor neutre / déclinable **sans remplacer l'animation ni son rythme**, après validation de droits |

**Attention :** « remplacer impérativement » ici signifie *avant diffusion commerciale*, **pas** « changer immédiatement le code ». Aucune identité nouvelle n'a encore été choisie.

## 5. Écrans et cas UX à vérifier en rendu réel

| Famille / parcours | Vérifications minimales | Fil partenaire |
| --- | --- | --- |
| Splash → connexion → création/rejoindre club | marque distincte, logo cohérent, aucun écusson parasite, contraste, messages compréhensibles | 02 / 08 |
| Calendrier → fiche match → composition → retour | orientation, historique, lisibilité des deux équipes, navigation inchangée | 03 / 08 |
| Effectif → fiche joueur → statistiques | portraits, proportions, badges, tableaux, textes longs et photos manquantes | 03 / 08 |
| Admin → réglages club | import/suppression logo, aperçu 12 couleurs, couleur secondaire blanche, échecs réseau et retour couleur | 02 / 03 |
| Match en direct et banc | densité, statuts positifs/négatifs, tactique sur petit écran, couleur primaire proche du vert/rouge | 03 |
| Badges → armoire → bilan saison | cadrage, étoiles, recadrage d'images, lisibilité des palettes extrêmes, son absent et réduction mouvement | 03 / 07 |
| Installation PWA | icônes Android/iOS, masquer le titre provisoire, splash navigateur, notifications, cache d'icône après mise à jour | 02 / 03 |

Échantillon visuel proposé : écran mobile étroit (320–360 px), mobile classique (~390 px), grand mobile (~430 px), paysage, tablette (~768 px) et bureau (≥1180 px) ; textes agrandis ; navigation clavier et lecteur d'écran ; mouvement réduit. Tester avec trois identités **fictives** contrastées : rouge/blanc, vert/noir, jaune/blanc. **Aucun club fictif ni aucune donnée n'ont été créés**.

Mesurer les contrastes de texte normal (objectif WCAG AA 4,5:1), grands titres (3:1) et commandes essentielles (3:1), sans prétendre que ces seuils sont déjà atteints. Les statuts ne doivent jamais dépendre seulement d'une couleur.

## 6. Inventaire des médias et vérification des droits (fil 07)

| Ressource | Source | Situation constatée / contrôle |
| --- | --- | --- |
| SVG de l'icône historique | `docs/branding/icone_app*.svg` | Fichiers identiques à ceux du dépôt AS Grinta ; décider remplacement ou autorisation |
| Écusson par défaut / splash | `assets/images/club_crest.webp`, `web/club_crest.webp` | Usage codé ; image et origine à examiner |
| Icônes PWA/favicons | `web/icons/`, `web/favicon.*` | PNG commerciaux différents de l'original ; vérifier auteur, caractère distinctif |
| Stade vidéo et affiche | `assets/composition/stade*.mp4`, `stade.jpg` | Fichier JPG directement visualisé : drapeaux bleu/jaune hérités ; vidéo MP4 non inspectée ni droits établis |
| Icône chaussure de passe | `assets/images/icons/assist_boot.png` | Vérifier provenance et autorisation |
| Maillots | `docs/branding/maillots/*.svg`, `assets/images/jerseys/*.png` | README les qualifie de dessins originaux sans marque ; à corroborer si besoin |
| Badges, images utilisateurs, joueurs | Code et Storage prévus | Vérifier propriété des illustrations et droit à l'image des personnes avec fil 07 |
| Police Oswald | `assets/fonts/` | Fichier licence OFL présent ; conserver notice |
| Bande-son bilan | `assets/audio/README.md` | Piste synthétisée par le projet ajoutée le 13/11 (sans droits tiers) |

Aucune conclusion juridique définitive ne peut résulter de la seule présence d'un fichier dans GitHub.

## 7. Spécification provisoire pour le fil 02 — aucune mise en œuvre autorisée à ce stade

1. **Séparer** `ProductIdentity` (nom, icônes, marque avant connexion) et `ClubIdentity` (écusson, nom, couleurs après sélection). Le nom de type `ProductIdentity` est conceptuel, non une prescription de refactorisation.
2. Maintenir la palette sombre, la navigation, les dimensions, le rythme des animations et les composants partagés **par défaut**.
3. Garder le logo de chaque club au calendrier/en-têtes et ne pas le remplacer par le logo de la plateforme.
4. Dans splash/auth, afficher la **marque commerciale** jusqu'à ce qu'un club soit connu ; après connaissance du club, employer l'écusson approprié sans fuite d'identité au changement de compte.
5. Centraliser seulement les couleurs réellement paramétrables ; conserver les codes de statuts non ambigus. Ne pas coloriser les illustrations d'une manière qui détruit leur lisibilité.
6. Ne pas renommer massivement imports Dart, préfixes cache, API JS, clés de stockage ou classes `Grinta*` au simple motif du nom historique. Définir d'abord un inventaire de références *visibles*.
7. Toute PR de code doit préciser les captures avant/après, versions mobile/tablette, tests automatisés et comportement hors connexion/PWA. Aucun déploiement sans validation du fil 00 et vérification du fil 03/04.

Critères d'acceptation : un joueur d'un club fictif ne voit jamais l'écusson ou le nom d'un autre club ; deux clubs peuvent avoir des couleurs opposées sans rendre textes et commandes illisibles ; les parcours Calendrier/Stats/Match restent identiques ; le logo produit apparaît aux bons endroits avant authentification et l'écusson club aux bons endroits après ; les animations demeurent facultatives / compatibles avec les préférences d'accessibilité.

## 8. Décisions, blocages, coordination

**Terminé :**
- lecture de la documentation commune, de la PR #29 et de la PR #25 ;
- inspection **visuelle d'un échantillon d'images** commerciales/originales (icônes, écussons, affiche de stade, trois maillots) hors exécution de l'application ;
- première matrice sourcée conserver / adapter / remplacer ;
- repérage de l'identité provisoire, des couleurs fixes, des liens logo → splash/auth et des SVG de l'ancien produit ;
- registre des ressources à valider avec le fil 07.

**Non testé / à compléter :**
- aucun rendu ni navigation mobile réelle ; aucune capture ; aucun test Flutter ;
- pas de recherche nom/marque/domaine à ce stade (audit de l'existant demandé **avant** propositions) ;
- provenance et droits des ressources multimédias non établis ;
- pas de bibliothèque graphique commerciale finalisée.

**Décisions requises du propriétaire, à présenter par le fil 00 au bon moment :**
1. Approbation d'un nom commercial après recherche de disponibilité et examen fil 07.
2. Direction d'un logo et d'une icône de plateforme **distincts** des écussons clubs, tout en gardant le style de l'app.
3. Étendue autorisée de la personnalisation (couleurs et maillots) sans détruire le thème de base.
4. Validation du traitement des badges culturellement spécifiques à AS Grinta, selon fil 01.

**Vers les autres missions :**
- **00 :** inscrire ce document et sa PR dans CHANTIER, sans considérer l'audit comme une validation UX.
- **01 :** réutiliser les décisions N09, C02, C03, C04 du registre fonctionnel PR #25 ; clarifier badges/maillots.
- **02 :** aucune modification esthétique immédiate ; préparer un écart technique *après* validation nom et identité.
- **03 et 08 :** organiser une revue de captures réelles, de contrastes et de navigation pour 3 profils de clubs fictifs.
- **07 :** qualifier les droits des SVG d'icône, du stade animé, de l'icône chaussure, des badges, des photos et de la musique.
- **09 :** prévoir tests cache PWA/manifest/favicon et versionnement lors du futur changement de nom/icône.

**Statut final :** audit de code **et des visuels sources** documenté ; rendu de l'application en fonctionnement, validation juridique et validation commerciale **toujours non réalisés**. Aucune action demandée sur la base commerciale, aucune modification du dépôt original.

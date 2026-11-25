# Audit UX/UI — 4 axes (25 novembre 2026)

> **Correction (même jour)** : ce premier passage (comptages) est dépassé. Il affirmait « aucun bloquant » et des squelettes de chargement : faux. Lire `docs/AUDIT_UX_ECRAN_PAR_ECRAN_20261125.md`.


Suite de `docs/PLAN_AUDIT_UX_COMPLET.md`. Complète `docs/AUDIT_UX_UI_20261124.md` (boutons, couleurs, textes), sans le refaire.
Aucun code modifié. À valider avant toute correction.

## Ce qui a été fait, et ce qui ne l'a pas été

- **Fait** : comptages sur les 370 fichiers de `lib/` (motifs précis) + lecture ciblée des écrans où un comptage était suspect.
- **Pas fait** : aucun rendu à l'écran. Pas de base locale (Docker absent ici), donc pas de captures 360/768/1280 px. Tout ce qui dépend de l'œil (débordements, texte agrandi, contraste réel, ordre de tabulation) est marqué « à vérifier ».
- **Pas fait non plus** : lecture ligne à ligne des 175 écrans. Un motif absent de mes comptages peut exister.
- **Pas vérifié** : vrai téléphone, tablette, clavier réel, lecteur d'écran, mode PWA installé.

## Verdict global

L'app est en bon état sur ces 4 axes. **Aucun problème bloquant trouvé par lecture du code.** Les écarts sont des « gênants » et des « détails », concentrés sur 3 sujets : erreurs de formulaire regroupées en bas, blocs qui apparaissent d'un coup au chargement, quelques textes très petits.

## Les 8 constats qui comptent

| # | Gravité | Constat | Ce que ça change pour la personne |
|---|---|---|---|
| 1 | Gênant | **Erreurs de formulaire affichées en un seul message en bas** (15 écrans), pas sous le champ fautif. Aucun champ ne reçoit le curseur en cas d'erreur. | Sur un long formulaire, il faut deviner quel champ est faux. |
| 2 | Gênant | **Connexion et Profil affichent le texte brut de l'erreur** (`'$error'`, après retrait de « Bad state »). Le reste de l'app passe par une fonction de traduction (`humanizeError`). | Une erreur inattendue peut montrer un message technique en anglais sur l'écran de connexion. |
| 3 | Gênant | **7 blocs n'affichent rien pendant le chargement** puis apparaissent d'un coup : disponibilité du joueur, vote homme du match, composition publiée, tableau des disponibilités, stats de la fiche joueur, détail d'un badge, détail d'un match. | La page « saute » : le contenu est poussé vers le bas quand le bloc arrive. Risque de taper à côté. |
| 4 | Gênant | **Touche « Suivant » du clavier inactive** sur 79 champs sur ~98 (réglages du club : 0 sur 10, facturation, factures, fiche stade, historique…). | Sur téléphone, on doit retoucher chaque champ au lieu de passer au suivant. |
| 5 | Gênant | **Erreurs de chargement de 3 blocs sans bouton « Réessayer »** (disponibilité, vote homme du match : vu ; composition : à confirmer). « Momentanément indisponible » sans suite. | La personne ne peut qu'attendre ou quitter l'écran. |
| 6 | Détail | **Textes de 10–11 px** à 9 endroits (noms sur le terrain de composition, éditeur de buts, compteur de notifications qui ignore la taille de texte du système, bouton « Ma saison »). | Difficile à lire, surtout pour les personnes qui ont réglé un grand texte. |
| 7 | Détail | **Seulement 3 filtres de saisie** pour 12 champs numériques. | On peut coller des lettres dans un champ de nombre ; l'erreur n'arrive qu'à l'envoi. |
| 8 | À vérifier | **Texte agrandi (jusqu'à 160 %)** : plafond prévu par l'app, mais testé sur peu d'écrans (9 fichiers de test mentionnent la taille de texte, sur 175 écrans). | Risque de texte coupé ou de débordement sur les écrans denses (pastilles, tableaux, libellés à largeur fixe). |

## Axe 1 — Tailles d'écran

**Bon**
- Navigation adaptative : barre du bas sous 840 px, barre latérale au-delà, barre latérale aussi pour un téléphone couché court (`app_shell.dart`). Contenu limité en largeur sur grand écran.
- Orientation jamais verrouillée. Zones sûres utilisées (33 fichiers). 31 `LayoutBuilder`.

**À corriger**
- **Largeurs fixes** (4) : libellé à 112 px dans les profils admin (`admin_profiles_section_v2`, 45) ; tuile à 122 px dans le plan d'effectif (`admin_squad_plan_effectif_roster`, 225) ; sélecteur de saison 300 px et navigation de mois 320 px dans le calendrier (`calendar_matches_widgets`, 112–114). Les deux premiers coupent le texte si on agrandit la police. Gravité : détail.
- **`MediaQuery.of(context)`** (6) au lieu de `sizeOf`/`viewInsetsOf` : racine de l'app (`app.dart`, 181), armoire, 3 feuilles de saisie (badge admin ×2, détail badge, indisponibilité). L'effet : reconstruction de l'écran à chaque ouverture du clavier. Gravité : détail (lenteur possible, non mesurée).
- **Pas de deux colonnes** sur tablette/ordinateur (liste puis détail en page complète, dans une colonne centrale limitée). À décider : acceptable pour une app de club, ou à améliorer ? Gravité : détail, avis de la personne qui pilote.

**À vérifier à l'écran** : texte à 160 % sur le terrain de composition, le tableau Statistiques, les cartes de match ; téléphone couché sur les formulaires (clavier ouvert).

## Axe 2 — Chargement, vide, erreur

**Bon**
- États vides dédiés (`PfEmptyState`, 17 écrans), chargement animé (`PfLoader`), squelettes (`PfSkeleton`, 5 fichiers), « Réessayer » à 27 endroits, bandeau « Connexion perdue » global, zone annoncée aux lecteurs d'écran sur le chargeur et l'erreur d'incident.

**À corriger**
- **7 chargements vides** (constat 3) : `match_lineup_page` 379, `sport_motm_vote_page` 269, `match_availability_board_card` 36, `match_availability_selector` 55, `badge_detail_sheet` 292, `player_card_stats` 315, `match_details_page` 292. Proposition : un squelette de la bonne hauteur.
- **2 erreurs avalées** sans message : `player_card_stats` 316 (stats absentes sans explication), `match_details_page` 293 (la limite de vote disparaît sans le dire). Proposition : message discret ou journalisation.
- **Erreurs sans issue** (constat 5). Proposition : un lien « Réessayer » commun.
- **2 spinners bruts** au lieu du chargeur de l'app : `history_import_page` 142, `platform_control_page` 192. Détail.
- **Erreur brute** (constat 2) : `auth_sign_in_page` 220, `profile_page` 699, `stadium_video_web` 312.

**Non audité en détail** : les 75 fenêtres de confirmation et 141 messages (le vocabulaire a été traité hier). Reste à vérifier : fenêtre fermée en touchant à côté (traitée comme réponse ?), message affiché après une attente alors que l'écran est parti, retour de connexion.

## Axe 3 — Accessibilité et bonnes pratiques web

**Bon**
- **Tous les boutons-icônes ont un nom** (tooltip), vérifié sur les 74. Mon premier comptage en signalait 9 : c'était des faux positifs.
- `lang="fr"`, titre, couleur de thème, manifeste PWA, icônes Apple. 59 zones `Semantics`. Texte système respecté (plancher 110 %, plafond 160 %).
- Zones à toucher : boutons-icônes de l'en-tête à 40 px dans leur zone minimale ; boutons +/- de la liste d'attente 34×44.

**À corriger**
- **Zones à toucher sous 44 px** : boutons-icônes d'en-tête (cloche, trophée, roue, Ma saison) en `minWidth/minHeight: 40` ; +/- de la liste d'attente 34 px de large. Détail, mais en dessous du seuil recommandé.
- **Textes 10–11 px** (constat 6) : `composition_pitch` 632/673/731, `composition_presentation` 726, `composition_presentation_stage` 402/575, `formation_pitch_editor` 593, `match_goal_actions_editor` 428, `notification_inbox_button` 121 (taille système ignorée), `season_wrapped_button` 66. Les PDF de facture (9–10,5 pt) sont des documents imprimés : hors sujet.
- **Mouvement réduit** respecté à 3 endroits seulement (hub pronos, bilan de saison, transition de page). Les autres animations (blason animé, chargeur, etc.) : à vérifier.
- **Focus clavier visible** : le thème ne définit que le contour des champs ; boutons et cartes cliquables suivent le réglage par défaut de Flutter. À tester au clavier sur ordinateur.

**À vérifier** : contraste des couleurs en dur hors thème, sens porté par la couleur seule (Présent/Absent, V/N/D : l'audit d'hier le suspectait), zoom du navigateur, score Lighthouse, fonctionnement hors ligne.

## Axe 4 — Formulaires

**Bon**
- **Libellé visible sur tous les champs** (aucun champ à texte d'aide seul).
- **Anti double envoi** : drapeau « en cours » dans 39 fichiers, bouton « Enregistrement… ».
- **Contrôleurs libérés** dans tous les fichiers qui en créent. Clavier adapté (e-mail, téléphone, adresse, site, nombre : 27 réglages). Capitales (46), longueur max (34), afficher/masquer le mot de passe, saisie automatique sur la connexion et l'inscription. L'inscription a « Suivant » partout.

**À corriger**
- **Erreurs groupées en bas** (constat 1) : 15 fichiers avec une seule variable `_error`. Seulement 10 `TextFormField`, 3 `Form`, 6 validateurs. Proposition : `errorText` par champ + focus sur le premier champ fautif (1 seul `FocusNode` dans l'app).
- **Pas de validation à la saisie** (aucun `autovalidateMode`) : tout est contrôlé à l'envoi. Acceptable, mais on corrige tard.
- **« Suivant » absent** (constat 4). Réglages du club : 10 champs, 0 action de clavier.
- **Peu de filtres de saisie** (constat 7) : 3 pour 12 champs numériques.
- **Aucune erreur de champ** dans `club_settings_page` (10 champs), facturation plateforme, fiche stade (1 seule), choix du club : les erreurs passent par le message du bas ou un message général.

**À vérifier** : perte des données saisies (retour arrière, rotation, coupure réseau), champ caché par le clavier (4 feuilles utilisent la hauteur du clavier via `MediaQuery.of`), dates et heures au format français.

## Plan de corrections proposé

Ordre = effet sur la personne × effort. Chaque lot est testable seul.

| Lot | Contenu | Effort | Écrans touchés |
|---|---|---|---|
| A | Un composant commun d'erreur de champ + focus sur le premier champ fautif ; appliqué à connexion, inscription, profil, match, calendrier | Moyen | ~8 |
| B | Erreurs de connexion/profil/vidéo via `humanizeError` | Petit | 3 |
| C | Squelettes pour les 7 chargements vides ; message pour les 2 erreurs avalées ; « Réessayer » sur les 3 blocs | Moyen | 9 |
| D | « Suivant » sur tous les champs d'un formulaire (réglages du club, facturation, stade, historique) + filtres de saisie des nombres | Moyen | ~12 |
| E | Textes 10–11 px à 12 px ; compteur de notifications qui suit la taille système ; zones à toucher à 44 px | Petit/Moyen | 9 |
| F | Largeurs fixes (112, 122) en largeurs souples ; `MediaQuery.of` → `sizeOf`/`viewInsetsOf` | Petit | 8 |
| G | À décider : deux colonnes sur tablette/ordinateur ? | Gros | Calendrier/effectif |

Recommandation : A, B, C, D d'abord (gênants). E et F ensuite. G seulement si la tablette compte vraiment.

## Ce qu'il faut pour lever les « à vérifier »

Une base locale (Docker + Supabase local, voir `docs/HANDOFF.md`) pour des captures à 360/768/1280 px et à 160 % de texte. Elle manque dans cet environnement. Sans elle, ces points restent non vérifiés.

# Parité AS Grinta → Petit Filet et simplification des réglages — 13/11/2026

## Périmètre et méthode

- AS Grinta : **lecture seule** du dépôt `samihchaa-wq/AS-Grinta` (`main`). Aucune copie de données, photo, média personnel, nom de joueur ou migration historique.
- Petit Filet : comparaison des arborescences Git `main`, des classes Flutter et du référentiel **164 unités métier** dans `AUDIT_FONCTIONNALITES_DETAILLE.md`, puis refonte isolée de l'écran `club_settings_page.dart`.
- La comparaison d'arborescence ne prouve ni la parité comportementale, ni le cloisonnement serveur, ni la réussite de parcours réels.

## Résultat de l'inventaire

| Contrôle | Constat | Interprétation |
|---|---|---|
| Fichiers Flutter `lib/` présents chez AS Grinta mais absents chez Petit Filet | **0** | Aucune fonctionnalité Dart complète manquante **par absence de fichier** |
| Fichiers `lib/` communs aux deux dépôts | **290** | **188** blobs identiques et **102** fichiers adaptés ou divergents ; revoir les comportements avant de déclarer la parité totale |
| Tests `test/` de l'original absents du commercial | **1** | Replay d'une saison contenant des noms et UUID de joueurs réels : **ne pas recopier tel quel** dans le dépôt commercial public ; créer des scénarios synthétiques |
| Fonctionnalités inventoriées par M01 | **164** | Conserver **77**, conserver avec modifications **33**, rendre paramétrables **36**, rendre optionnelles **17**, retirer reliquat spécifique **1** |
| Fonctionnalités historiquement classées `G` dans l'audit du 12/11 | **25** | C'est une liste de **lacunes ou preuves insuffisantes à cette date**, pas 25 fonctions encore absentes après les PR récentes |

Les correctifs des PR #47, #48, #50, #57, #69, #72 et #73 modifient plusieurs constats anciens ; ils ne doivent pas être déclarés non livrés sur la seule base du rapport M01 daté.

## Matrice de décisions par domaine

| Domaine | Décision Petit Filet | Paramétrage/admin | Contrôle encore requis |
|---|---|---|---|
| Inscription, comptes, rôles, administration et effectif | **Conserver + adapter multiclub** | Invitation et gestion d'effectif distinctes | Homonymes, rôle admin, club suspendu, cloisonnement de tous les accès |
| Identité et visuels du club | **Paramétrer** | Nom, nom court, écusson, couleurs, maillots | Propagation joueurs/gardiens avant/pendant/après match, clips sans nom AS Grinta |
| Saisons, calendrier, historique | **Conserver** | Terrain domicile, matchs et historique | Saisons, saisies anciennes, types de compétitions non couverts |
| Disponibilités, convocations, liste d'attente | **Conserver + adapter + paramétrer** | Quota, ouverture, trois modes d'attente | **+1 uniquement manuels**, jamais d'automatisme, concurrence et changements de saison |
| Compositions, simulation, stade | **Conserver + adapter** | Maillots, formations et composition | Scénarios de simulation avec données fictives, droits média, affichage mobile |
| Live et météo | **Options de club** | Interrupteurs respectifs | Refus côté serveur des écritures live lorsque coupé ; affichage météo avec adresse absente |
| Pronostics, barèmes, rappels, votes | **Options + règles paramétrables** | Interrupteurs, fermeture, points, délais | Cohérence client/serveur, notification, fenêtres et annulations |
| Stats, badges, bilan de saison | **Options de club** | Interrupteurs et configuration badges par interface dédiée | Historique préservé lors d'une désactivation, absence de fuite club A → B |
| Notifications et PWA | **Conserver + sécuriser** | Préférences individuelles existantes | Livraison réelle push, coupure par module et suppression de doublons |
| Abonnement et stockage | **Conserver et dissocier** | Vue abonnement et quota de stockage | Paiement effectif et sauvegardes/restauration restent hors validation fonctionnelle |
| Contenus propres à AS Grinta et reliquats obsolètes | **Retirer du commercial seulement** | Aucun réglage exposé | Éviter noms réels/vidéos non licenciées et anciens réglages « +1 » devenus inopérants |

### Différences non considérées comme des fonctionnalités manquantes à reproduire automatiquement

- Les formats 5/7/8, la vidéo individuelle détourée, les fuseaux internationaux, la musique du bilan et le paiement en ligne ne sont pas des fonctionnalités opérationnelles d'AS Grinta qui peuvent simplement être copiées sans arbitrage.
- Le test original `composition_simulation_season_replay_test.dart` ne doit **pas** être copié à cause de ses données personnelles ; élaborer un test équivalent avec une équipe fictive.
- La configuration serveur, les migrations SQL, les cron, les Edge Functions et les historiques de données doivent être **contrôlés** avant une affirmation de parité complète.

## Réorganisation introduite dans cette branche

L'écran **Réglages du club** possède six sections repliables :

1. **Identité et maillots** — nom, nom court, logo, couleurs, tenues.
2. **Invitations** — code et lien d'invitation.
3. **Matchs et convocations** — terrain, quota, mode live, météo, règles d'ouverture, mode de liste d'attente et autres règles de match.
4. **Pronostics et votes** — pronostics, Étoile du match, barème et fenêtres.
5. **Statistiques et récompenses** — statistiques, badges, bilan de saison.
6. **Abonnement et stockage** — souscription et espace photo.

**Principes UX :**
- Un intitulé court et la valeur/le bouton associés, **sans sous-titre explicatif permanent**.
- Chaque option ou réglage nécessitant une explication expose un bouton **ⓘ** avec dialogue dédié ; fonctionnement aussi au toucher et avec infobulle d'accessibilité.
- Les catégories se replient pour limiter la longueur perçue ; identité ouverte au premier accès, autres rubriques repliées.
- Réutilisation des mêmes clés, composants, repositories, gardes serveur et callbacks ; **pas de changement de données, migration, règles métier ni valeurs par défaut**.
- Les heures de crédit automatique de la liste d'attente restent cachées : les **+1 sont exclusivement manuels**.
- Aucun historique n'est effacé lorsqu'une option est désactivée.

## État de vérification et suites

- **Code** : écran réorganisé sur branche GitHub dédiée, sans impact sur l'original.
- **Tests** : tests widget ajustés pour les sections repliables, ajout d'un test d'ouverture/fermeture de l'aide contextuelle.
- **Exécution** : Flutter/Dart **non disponibles dans l'environnement actuel** ; demander verdict CI sur le HEAD de la PR, puis corriger tout test en échec.
- **Non validé à ce stade** : rendu physique iPhone/Android, 164 parcours E2E, migration SQL / RLS / Edge, tests d'isolation entre deux clubs, performance.
- **À vérifier ensuite** : comportement des **102 fichiers Flutter divergents** et des règles serveur ; priorité P0 accès/permissions, liste d'attente, matchs et modules désactivés. Les fiches de preuve M01/M03/M04 font foi.
- **Pas de déploiement/fusion automatique** : revue propriétaire et CI requises.

Références : `docs/AUDIT_FONCTIONNALITES_DETAILLE.md`, `docs/CAHIER_DES_CHARGES_FIL_02.md`, `docs/AUDIT_ROUTES_ET_PARAMETRES.md` et `docs/HANDOFF.md`.

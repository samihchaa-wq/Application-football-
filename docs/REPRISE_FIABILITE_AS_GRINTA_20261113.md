# Reprise de la fiabilité AS Grinta → Petit Filet

Date : 13 novembre 2026. Source : comparaison **en lecture seule** des arbres GitHub `main` de `samihchaa-wq/AS-Grinta` et `samihchaa-wq/Application-football-`.

## 1. Constat vérifié sur les fichiers

| Catégorie commune aux deux dépôts | Contenu strictement identique | Contenu divergent |
| --- | ---: | ---: |
| Tests Flutter (`test/`) | 173 | 39 |
| Tests SQL (`supabase/tests/database/`) | 126 | 14 |
| Code Dart (`lib/`) | 188 | 102 |
| Fonctions Edge (`supabase/functions/`) | 12 | 6 |
| Workflows GitHub actifs de même nom | 0 | 6 |

Deux tests historiques présents uniquement dans l'original :
- `supabase/tests/database/admin_club_defaults.test.sql` : fonctions **monoclub** supprimées ou remplacées ; les contrôles d'accès utiles sont transposés aux RPC `admin_set_club_home_address` et `admin_set_club_usual_squad_size` dans le test multiclub existant.
- `test/features/sports_management/domain/composition_simulation_season_replay_test.dart` : des matchs et identités de joueurs historiques ; ne **pas** verser ces données dans le dépôt commercial. Régression fonctionnelle reconstruite sur des effectifs entièrement fictifs.

Les fichiers strictement identiques n'ont pas à être recopiés. Les différences ne sont **pas toutes des régressions** : plusieurs adaptations multiclub, sécurité et identité sont délibérées.

## 2. Correctif code + régressions de ce lot

1. **Historique des postes :** `kLivePositionHistoryStart` héritait de l'ancienne archive embarquée d'AS Grinta et ignorait les compositions antérieures à août 2026. Petit Filet utilise désormais toutes les saisons historiques, puisqu'il n'embarque plus cette archive. L'appel RPC continue de résoudre le club courant côté serveur.
2. **Simulations Flutter :** scénarios fictifs pour composition à 11, rotation des remplaçants, reproductibilité quel que soit l'ordre des joueurs, séparation des listes de deux clubs, absence de gardien, et profils historiques distincts.
3. **Droits SQL :** reprise de quatre assertions de privilèges de la version originale (anonyme vs authentifié) et contrôle d'un quota nul rejeté, dans `club_settings_admin.test.sql`. Les vérifications d'autorisation par rôle et d'isolation entre deux clubs déjà présentes sont conservées.

Les fichiers de production d'AS Grinta, son dépôt et ses données restent **intouchés**. Aucune migration ni écriture Supabase commerciale n'a été réalisée.

## 3. Priorités restantes (non couvertes par ce lot)

### P0 — séparation et sécurité

- Exécuter une matrice négative **admin/joueur/suspendu** pour **deux clubs fictifs** : tables, RPC `SECURITY DEFINER`, Storage, Edge Functions, notifications et abonnements.
- Comparer les 14 tests SQL divergents avec les évolutions de règles, plutôt que restaurer aveuglément les versions monoclub.
- Réviser les RPC privilégiées et les changements de statut club / membre ; vérifier l'absence d'accès interclubs à travers le rôle `service_role` et les tâches planifiées.
- Vérifier sécurité et restauration des sauvegardes **DB et Storage** sur un environnement isolé.

### P1 — stabilité, régressions et charge

- Examiner les 39 tests Flutter divergents et les 102 fichiers Dart divergents, par fonction métier, avec jeux de données de club fictifs et captures d'interface.
- Revoir les 12 workflows AS Grinta absents des workflows actifs commerciaux : leurs copies dans `.github/workflows-disabled/` portent potentiellement des identifiants ou chemins **du projet original**. **Ne pas les réactiver tels quels** ; réécrire leurs gardes projet, permissions et secrets avant intégration.
- Vérifier les performances sur plusieurs milliers d'utilisateurs simulés avec mesures p95/p99, limitation des requêtes et tests de concurrence, sans extrapoler à partir des anciens résultats d'AS Grinta.

## 4. Portée de la validation

Les tests de cette PR sont exécutables par la CI Flutter et la CI Supabase locales sur pull request. Leur réussite **ne prouvera pas** la sécurité de la base distante ni la capacité à recevoir des milliers de personnes. Aucune promotion sur `main`, fusion, publication ou déploiement ne fait partie de ce lot.

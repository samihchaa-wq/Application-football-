# Réemploi des protections et tests d’AS Grinta — état du 13/11/2026

## Périmètre et méthode

Comparaison **en lecture seule** des arbres GitHub de `samihchaa-wq/AS-Grinta` et `samihchaa-wq/Application-football-`, sur leurs branches `main` au moment de l’inventaire. Les comptes ci-dessous portent sur des **fichiers** et leurs SHA Git (égalité stricte des octets), pas sur le nombre de scénarios de test ni leur réussite en exécution. Ces nombres doivent être recalculés après d’autres fusions.

Le dépôt et la base d’AS Grinta restent **intouchés**. Aucun accès d’écriture, migration, secret ou déploiement Supabase ne résulte de ce chantier. Ne jamais transférer les données, identifiants ou historiques de joueurs de l’ancien club vers les tests publics du produit.

## État des fichiers homologues

| Périmètre | Strictement identiques | Même chemin, contenu modifié | AS Grinta uniquement | Petit Filet uniquement |
|---|---:|---:|---:|---:|
| `lib/` Flutter | 188 | 102 | 0 | 30 |
| `test/` Flutter | 173 | 39 | 1 | 21 |
| `supabase/tests/database/` | 126 | 14 | 1 | 23 |
| `supabase/functions/` | 12 | 6 | 0 | 12 |
| `.github/workflows/` actifs | 0 | 6 | 12 | 6 |
| `supabase/migrations/` | 0 | 0 | 647 | 40 |

**Note SQL** : les 32 fichiers de tests propres à Petit Filet sous `supabase/tests/` incluent 23 tests `database/` et 9 fichiers auxiliaires `load/`. Les **647 migrations** de l’application originale ne sont pas des corrections à importer en bloc : Petit Filet suit sa propre histoire de schéma et ses 40 migrations commerciales doivent rester immuables après application. Réutiliser des invariants ou tests, pas réappliquer un historique incompatible.

## Décisions de réemploi

1. **Conserver, ne pas recopier** : les 173 tests Flutter, 126 tests SQL et 12 fichiers Edge identiques déjà présents. Leur existence ne garantit pas qu’ils passent : suivre les CI sur le SHA exact.
2. **Adapter par club avant toute reprise** : les 102 fichiers Flutter, 6 fichiers Edge, 14 tests SQL et 39 tests Flutter divergents. L’authentification, les RPC, les autorisations administrateurs, le Storage, les notifications et le profil courant doivent toujours utiliser le club du contexte d’exécution. Une protection mono-club peut devenir dangereuse en multiclub.
3. **Remplacer par des scénarios synthétiques, ne pas copier tels quels** :
   - `supabase/tests/database/admin_club_defaults.test.sql` (AS Grinta uniquement) cible des réglages globaux ; dans Petit Filet, `club_settings_admin.test.sql` couvre déjà les réglages par club et deux clubs distincts.
   - `test/features/sports_management/domain/composition_simulation_season_replay_test.dart` (AS Grinta uniquement) rejoue des compositions avec des noms et identifiants du club d’origine. Reprendre les invariants (positions réalistes, promotion des anciens remplaçants, déterminisme, historique) avec des joueurs fictifs ; ne jamais republier ces données.
4. **Réévaluer les workflows désactivés** : 12 workflows de l’original ont été archivés sous `.github/workflows-disabled/` dans Petit Filet. Certains contiennent des références au projet Supabase original, à son environnement ou à des hypothèses mono-club. **Ne jamais les réactiver en bloc.**
5. **À écarter** : imports de migrations anciennes, variables du projet original, fixtures à données réelles, sauvegardes ou copies de données et logique globale ne connaissant pas `club_id`.

## Premier lot proposé par cette branche

Le workflow `auth_security_guard.yml` d’AS Grinta était désactivé dans Petit Filet et pointait encore sur le projet Supabase d’origine. Le premier réemploi remplace son contrôle sensible par un **garde local, sans accès réseau** :

- même longueur minimale/maximale de mot de passe dans le client Flutter et l’inscription Edge ;
- mêmes catégories de caractères requises ;
- présence de la validation côté inscription serveur, pas seulement côté interface ;
- contrôle que `config/production.json` vise le **projet Supabase commercial** et ne reprend pas l’ancien domaine utilisateur ;
- tests de non-régression pour divergences et ancienne configuration ;
- contrôle automatique à l’ouverture de PR portant sur ces fichiers et en exécution manuelle.

Cela **ne vérifie pas** la configuration Auth distante (qui exige une vérification distincte autorisée), ni le comportement en production. Les tests Flutter/Deno existants restent nécessaires.

## Suites prioritaires

**P0 — sécurité multiclub** : vérifier chaque RPC `SECURITY DEFINER`, privilège et stockage avec deux clubs fictifs (admin A, membre A, admin B, compte suspendu). Les tests SQL locaux présents servent de point de départ ; ne déclarer la sécurité validée qu’après la vérification effective. Aucune écriture sur Supabase distant sans autorisation distincte.

**P1 — non-régression fonctionnelle** : créer un rejeu de compositions avec profils anonymes et deux historiques de clubs ; comparer les modules désactivables côté serveur, les notifications, les maillots, les saisons, l’attente manuelle et l’administration. Examiner les divergences significatives, pas seulement les nombres de lignes.

**P1 — exploitation** : auditer individuellement les anciens workflows `auth_security_guard`, `full_schema_replay_diagnostic`, `function_definition_drift`, `backup_restore_drill`, `supabase_usage_guard` et `free_encrypted_backup` contre les pipelines commerciaux existants, puis n’activer que les contrôles compatibles et réellement utiles.

**P2 — charge** : mener les tests de charge sur environnement isolé, avec quotas et scénarios représentatifs de plusieurs milliers d’utilisateurs avant toute affirmation de capacité commerciale. Ne pas confondre benchmark local, CI et trafic réel.

## Condition de validation

La branche est un **projet de correctif**, pas une fusion ni un déploiement. Validation requise : tests unitaires du garde, CI GitHub sur le HEAD exact, revue des conséquences multiclub. Garder `main`, les deux bases et AS Grinta inchangés jusqu’aux accords et contrôles prévus.

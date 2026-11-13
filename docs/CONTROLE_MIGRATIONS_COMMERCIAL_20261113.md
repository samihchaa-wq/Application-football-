# Sécurité — Écart entre la base Supabase commerciale et GitHub

**Vérification en lecture seule : 13 novembre 2026, projet commercial `jvxkhgdopslctpcjrhzw`.**

Le registre Supabase contient **38 migrations appliquées** et la branche `main` contient **40 fichiers**. Deux fichiers manquent au registre :

| Migration GitHub existante mais non appliquée | Risque / effet |
|---|---|
| `20261113005335_active_club_admin_permissions.sql` | La fonction `private.is_admin()` de production vérifie actuellement le statut du compte mais **pas** le statut actif du club. Un administrateur d'un club suspendu peut conserver des autorisations par certaines RPC tant que cette correction n'est pas déployée |
| `20261115000000_waitlist_credits_admin_only.sql` | Désactivation SQL du `+1` automatique en attente : non active en base tant que la migration n'est pas appliquée |

La migration `20261113010000_journal_incidents_par_club.sql` est **déjà enregistrée**. Une fonction de lecture sans filtre explicite ne constitue donc pas, à elle seule, une preuve de fuite : la table possède une politique RLS restrictive `club_isolation` par `club_id`. Continuer les essais avec deux comptes clients différents avant de conclure.

## Garde ajoutée

`tool/check_commercial_migration_state.py` interroge uniquement `supabase_migrations.schema_migrations`, sans insertion ni déploiement :
- liste les fichiers en attente et signale les migrations rétrospectives ;
- échoue si un identifiant SQL appliqué n'existe plus dans GitHub, s'il est dupliqué ou si le manifeste est invalide ;
- refuse tout projet autre que le commercial ;
- est exécuté **avant** les opérations de mise en route dans le workflow manuel `commercial_supabase_setup.yml`.
- dispose de tests unitaires locaux sans réseau.

Les états ci-dessus sont un instantané : relancer l'audit à chaque préparation de mise en service. L'audit ne prouve ni la cohérence des contenus SQL déjà appliqués, ni la sécurité à deux clubs réels.

## Déploiement

**Aucun changement de base n'est exécuté dans cette PR.** Les deux migrations en attente doivent faire l'objet d'une exécution **autorisée distinctement**, après revue des effets, sauvegarde, CI verte et plan de retour arrière. Préserver AS Grinta original.

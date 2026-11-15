# Recette securite et concurrence — 15 novembre 2026

Périmètre : **Petit Filet** (projet Supabase commercial uniquement). **AS Grinta original et Club Test B sont exclus de toute modification**. La branche de recette ne contient ni migrations, ni secrets, ni mutations de production.

## Avertissements Supabase (état observé)

Linter de sécurité : 165 avertissements `authenticated_security_definer_function_executable`, 1 avertissement de protection des mots de passe compromis, 1 information sur une table RLS de journal interne sans politique (fermée par défaut).

- **0** fonction `SECURITY DEFINER` publique accessible à `anon`.
- **161** RPC accessibles à `authenticated` appartiennent à `club_scope`, rôle **sans BYPASSRLS, sans droits superutilisateur et sans login**. Les fonctions utilisateur et admin sont volontairement appelables depuis Flutter avec le JWT de l'utilisateur. Leur accès métier dépend des contrôles internes ET du cloisonnement RLS ; le linter ne comprend pas ce modèle.
- **4** autres RPC appartiennent à `postgres` : `get_my_club_access()` (lecture du statut du club propre à l'utilisateur) et `platform_health()`, `platform_list_clubs()`, `platform_update_club(...)` (vérification de `private.is_platform_operator()`). Elles requièrent une revue particulièrement attentive, mais ne sont pas des fuites démontrées.
- Toutes les fonctions `SECURITY DEFINER` du schéma `public` ont un `search_path` explicitement vide.
- **Ne pas révoquer globalement les droits `authenticated`** : cela interromprait les parcours Flutter utilisateurs/administrateurs. Un avertissement conservé après justification n'est pas équivalent à une faille ouverte.

La nouvelle recette `supabase/tests/database/security_definer_exposure.test.sql` met en échec une régression : octroi à `anon`, élévation de rôle hors liste contrôlée, suppression du `search_path`, retrait de RLS ou garde opérateur manquante.

## Vérifications sur la base commerciale en lecture et sous comptes fictifs

1. Test par JWT simulé d'un joueur : **8 fonctions réservées aux administrateurs/opérateurs ont refusé l'appel**, transactions forcées au rollback.
2. Tentatives de lecture d'une composition de Club A par un admin de Club B : refus ou réponse absente. La réponse `get_match_live_state` interclub ne contient que des champs neutres identiques à un identifiant de match inexistant (hors écho de l'identifiant fourni).
3. **7 pronostics** enregistrés par 7 profils différents via RPC authentifiée appelée en parallèle : **7 réussites**.
4. **6 appels simultanés identiques** d'enregistrement du même pronostic par un seul profil : **6 réussites, un seul enregistrement**, score fictif d'origine rétabli ensuite.
5. Test de 12 lectures concurrentes A/B : 11 contrôles SQL réussis ; 1 requête bloquée par les contrôles de l'outil avant d'atteindre Supabase. **Ce dernier cas n'est pas un défaut serveur ni un succès de charge démontré.**

**Limites** : les appels de connecteur ne mesurent pas une latence PostgREST réaliste ni la charge navigateur/PWA ou push. Les mesures de temps autour des outils comprennent leur orchestration.

## Correction de l'épreuve de charge

Le précédent `write.pgbench` ajoutait indéfiniment des buts au même Live, ce qui ne correspondait pas à une situation métier normale et pouvait saturer un score à 99. L'épreuve modifiée exécute, **dans chaque transaction commitée**, une addition puis une suppression de but (deux opérations idempotentes distinctes). Elle conserve les vrais verrous d'écriture, la logique Live et ses triggers, sans gonfler artificiellement les scores. Le nouveau `postcheck.sql` **fait échouer la CI** si les sessions, scores ou événements restent incohérents, ou si aucune commande n'a été effectivement écrite. Le script refuse toute base distante et cible uniquement la stack locale jetable.

La CI `Load test (hundreds of clubs)` doit publier son vrai rapport (transactions, échecs, débit, latence) pour que l'on puisse annoncer une capacité : **le résultat n'a pas encore été certifié au moment de l'ouverture de la PR**. Elle teste PostgreSQL et Supabase local, pas 6 000 téléphones réels en Wi-Fi/4G.

## Point de configuration Auth à terminer dans Supabase

Le projet Supabase est sur l'offre **Pro** ; la protection contre les mots de passe connus comme compromis y est disponible. Le linter signale qu'elle **n'est pas activée**. Cela se règle **dans le tableau de bord Supabase**, pas par une migration SQL PostgreSQL :

`Authentication → Settings → Password Security → Leaked password protection` (intitulé à adapter selon l'interface), activer et enregistrer, puis relancer l'advisor.

Il n'existe pas de commande de gestion des paramètres Auth dans les actions Supabase actuellement disponibles à l'agent. **Ne jamais affirmer que ce réglage a changé tant que l'advisor ne confirme pas la disparition du warning**. Vérifier aussi l'expérience de création/changement de mot de passe avec la règle renforcée.

Documentation : https://supabase.com/docs/guides/auth/password-security et https://supabase.com/docs/guides/observability/advisors?queryGroups=lint&lint=0029_authenticated_security_definer_function_executable

## Critères de sortie

- CI métier/RLS et CI de charge locales **vertes**, rapport disponible.
- Réglage de protection Auth activé et advisor réexécuté.
- Audit ciblé approfondi des RPC sensibles et des Edge Functions, en particulier opérateur/notification/inscription.
- Mesures de montée en charge **sur une infrastructure de préproduction autorisée et isolée** avant de revendiquer un seuil de clients simultanés.
- Vérification fonctionnelle Flutter iPhone/PWA, sauvegarde/restauration, protection contre les abus et logs.

Ne pas annoncer de certification « 100 % » : un audit et une épreuve de charge réduisent le risque, ils ne suppriment pas toutes les défaillances possibles.

# M04 — contrôle de suspension de l’agenda

16 novembre 2026. Base : main 5f404e70f70b4e99d754f7064b567d027d66fe03. Suite de #149 et #37.

Le test exécute le vrai gestionnaire TypeScript dans Node 24, avec client Supabase simulé et sans réseau. Avant correction : échec attendu, GET d’un club suspendu répond 200 au lieu de 404. Après correction : huit scénarios réussis, GET/HEAD × navigateur/calendrier × club actif/suspendu. Le club actif conserve son accès, le club suspendu ne déclenche ni lecture des matchs ni redirection.

Correction : jointure du statut du club et filtre clubs.status=active sur la recherche de l’abonnement avant toute réponse. La clé service contourne RLS : ce contrôle doit être explicite.

Exécution : `node tool/qa/test_calendar_suspension.mjs` avec Node 24.22.1 ; `python3 supabase/tests/edge/verify_edge_security_contract.py` OK ; `git diff --check` OK. Node stripTypeScriptTypes est expérimental. Le test ne s’exécute pas encore dans un workflow dédié.

Limites : client simulé, pas un test HTTP Supabase réel ; aucune validation de relation PostgREST ou de déploiement revendiquée. M03 doit retester sur stack isolée avec vrai token d’agenda, suspension et réactivation ; M02 vérifier compatibilité. Revue de cohérence profil/club et révocation des liens restent à faire. Le test ne démontre pas une fuite interclub.

Développé et testé localement sous simulation ; CI à vérifier, non déployé. Aucune migration ni modification commerciale. AS Grinta et Carte soirée intacts. Pas de fusion sans autorisation applicable.

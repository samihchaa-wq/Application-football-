# Vérification de charge — garde contre les résultats trompeurs

Date : 13 novembre 2026. **Aucun test ne touche la base de production.**

Le workflow Load test crée des **clubs fictifs dans une instance Supabase locale**, 200 clubs par défaut × 30 membres = **6 000 comptes simulés**, 20 matchs/club et 50 clients pgbench concurrents. Ce test est une simulation technique, **pas une certification pour 6 000 connexions simultanées**.

Le script existant transmettait bien les codes de retour non nuls de pgbench, mais pouvait valider une exécution sans transactions ou avec des transactions individuellement échouées si pgbench lui-même terminait avec code 0. Les nouvelles vérifications refusent :
- le rapport absent ou malformé ;
- zéro transaction réellement traitée ;
- des transactions échouées (erreurs de concurrence, sérialisation, interblocages) ;
- un débit nul ou absent.

Ce cliquet s'applique **séparément aux lectures et aux écritures**. Le test de cloisonnement SQL existant reste exigé.

## Prochaines validations

1. Exiger la CI Load test verte sur HEAD exact après changement de script.
2. Récupérer le rapport des mesures de débit/latence du runner dans les artefacts CI ; une machine GitHub n'est pas le dimensionnement exact de Supabase commercial.
3. Compléter par essais de téléphones/PWA, notifications, quotas, backups DB + Storage et tests A/B multi-identités dans un environnement autorisé.

**Aucun déploiement, fusion ni écriture dans AS Grinta ou Supabase commercial.**

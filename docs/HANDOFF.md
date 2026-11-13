# Relais entre assistants — Petit Filet (application commerciale)

**Actualisé le 13 novembre 2026.** Source de vérité opérationnelle : branche `main`, PR ouvertes et contrôles GitHub sur le dernier SHA ; les états ci-dessous peuvent évoluer.

## Règles impératives

1. **Écriture uniquement dans `samihchaa-wq/Application-football-`.** Ne jamais modifier les dépôts, données, sites ni bases Supabase d'AS Grinta original ou de Carte soirée. Le dépôt AS Grinta peut être consulté en lecture seule pour comparer ses fonctionnalités et son interface.
2. **Dépôt commercial PUBLIC maintenu** (choix explicite B). Ne pas modifier sa visibilité ni republier de données personnelles / secrets dans les PR et issues.
3. **Supabase commercial `jvxkhgdopslctpcjrhzw` : lecture seule par défaut.** Aucune migration, écriture, déploiement de fonctions, création de comptes tests distants, changement de secret, publication ou paiement sans accord distinct du propriétaire. Ne jamais lancer de commandes de suppression de schéma à l'aveugle, en particulier **`DROP SCHEMA install_tmp CASCADE`**, instruction obsolète et dangereuse.
4. Migrations déjà appliquées **immuables** ; chaque correction SQL doit être une nouvelle migration à identifiant unique, compatible avec le registre des migrations de la base commerciale.
5. Fusion de PR uniquement après revue des risques, absence de conflit et contrôles GitHub **verts sur le SHA exact**. Toute CI incomplète, échouée ou en cours bloque la fusion. Une fusion de code **ne déploie pas** automatiquement l'application : les workflows de publication Cloudflare et de configuration Supabase sont manuels.
6. Aucune dépense ou souscription sans annonce du prix et accord préalable. Réponses françaises, directes ; distinguer : documenté, développé, CI validée, testé réellement, déployé.

## Produit — décisions validées

Nom commercial **Petit Filet** (précédemment « Lucarne », changement intégré par PR #65). Application multiclub de football **à 11**, avec identité et maillots indépendants pour chaque club, « Étoile du match » et emojis de badges préservés, objectif mai 2027. Le tarif, les paiements et les opérations commerciales restent à arbitrer.

**Décisions prioritaires nouvelles du 13/11 :**

- Issue [#66](https://github.com/samihchaa-wq/Application-football-/issues/66) : rendre les fonctions optionnelles héritées d'AS Grinta réellement réglables/désactivables par club, avec application côté serveur et conservation de l'historique.
- Issue [#67](https://github.com/samihchaa-wq/Application-football-/issues/67) : choisir des couleurs distinctes **joueurs et gardiens** pour chaque tenue, et afficher correctement ces couleurs avant, pendant et après chaque match, y compris en vidéo et historique.
- Issue [#68](https://github.com/samihchaa-wq/Application-football-/issues/68), PR [#105](https://github.com/samihchaa-wq/Application-football-/pull/105) : **aucun +1 automatique en liste d'attente** ; seuls les administrateurs utilisent +/−. La migration `20261116000000` avait réactivé les crédits au coup d'envoi. La PR #105 prépare une **nouvelle migration corrective**, sans remise à zéro des compteurs. **Le cron reste actif sur Supabase commercial tant que la nouvelle migration n'est pas appliquée avec autorisation distincte**. Voir [le diagnostic](changes/waitlist-admin-only-correctif-20261113.md).
- Issue [#70](https://github.com/samihchaa-wq/Application-football-/issues/70), PR [#72](https://github.com/samihchaa-wq/Application-football-/pull/72) : retrouver **exactement** l'Administration récente d'AS Grinta sur Petit Filet, hors adaptations obligatoires de sécurité multiclub. La PR est en validation Flutter/QA.
- Issue [#71](https://github.com/samihchaa-wq/Application-football-/issues/71) : **supprimer toute inscription « AS Grinta » des tribunes/public** de la vidéo de composition, sans ajouter de texte remplaçant ; traiter `stade.mp4`, `stade-720.mp4` et le poster `stade.jpg`. Pas encore traité dans les médias.

## Intégrations vérifiées pendant le 13/11

Fusionnées : #65 (nom Petit Filet), #33 (tests de charge fiables), #44 (garde migrations et conventions), #62/#64 (journal et indicateurs agents), #26 (registre QA), #29 (tableau de pilotage), #34 (identité), #35 (stratégie). Elles rejoignent les PR métier #23–#25, #46–#52 et #55–#60 précédemment fusionnées. **Les noms/références présents dans des documents datés sont historiques et non un état de production.**

Restent à vérifier sur GitHub avant intégration : PR #69 (+1 manuel), #72 (écran Administration), #36 (juridique) ainsi que les documents historiques #30/#31/#41/#53. **Ne pas considérer cette liste exhaustive après cette date : interroger GitHub.**

## GO/NO-GO et coordination

- **P0** : séparation réelle des clubs A/B avec permissions admin/RPC/RLS/Storage/Edge, contrôle d'un admin suspendu, sécurité des sauvegardes, restauration DB + objets Storage, RGPD/consentement.
- **P1** : tests smartphone/PWA, fiabilité des notifications et des e-mails, cohérence maillots, compositions et gestion des saisons ; vérifier la désactivation serveur des modules.
- **P2** : pilote volontaires, documents juridiques relus (SIRET, identité de l'éditeur), disponibilité de la marque et du domaine, paiement, hébergement adapté sans dépenses non autorisées.
- Site de test GitHub Pages existant ; publication commerciale sur Cloudflare uniquement par workflow **manuel**. Vérifier tout changement de configuration avant usage.
- Les cinq automatisations de coordination couvrent les neuf missions M01–M09 ; utiliser `docs/CHANTIER.md` et les PR/issues pour communiquer. Ne pas déclarer « fait » sans résultat vérifiable.

**Ce document ne vaut ni autorisation de déploiement ni certification du lancement.**

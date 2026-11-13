# Contrôle qualité automatique — Application football

Date de création : 12 novembre 2026. **Statut : proposition en PR, non activée sur main tant qu'elle n'est pas fusionnée.**

Ce document complète [HANDOFF.md](HANDOFF.md) et [CHANTIER.md](CHANTIER.md) (PR #29). Il décrit les garanties à vérifier, pas des validations déjà obtenues.

## Constats vérifiés

- GitHub `samihchaa-wq/Application-football-` est **public**. Le contenu historique est signalé comme pouvant contenir des données de l'application originale : établir la nature exacte de l'exposition avec M04/M07 avant toute décision de confidentialité.
- La liste GitHub des **rulesets** est vide au moment du contrôle. L'accès de l'intégration à la protection spécifique de `main` renvoie 403 : **impossible de confirmer son état par ce canal**. Il faut le vérifier dans les paramètres GitHub du propriétaire.
- `Flutter CI` et `Runtime diagnostic` sont déclenchés sur toutes les PR vers `main`. `Supabase business and RLS tests`, `Load test` et d'autres workflows sont **conditionnels aux fichiers modifiés**. Le résultat d'un workflow absent n'est **pas** un succès.
- Les agents automatiques écrivent leurs modifications uniquement dans des branches/PR. Ils n'ont pas l'autorisation de fusionner, déployer, modifier Supabase commercial ou engager des dépenses sans accord.

## Contrôle ajouté dans la présente PR

- **`PR quality guard / migration-history`** : sur toute PR vers `main`, compare l'état Git de la base à celui proposé. Refuse la modification, le renommage, la suppression ou la copie d'une migration SQL déjà présente sur la branche de base ; accepte uniquement l'ajout d'une migration datée `YYYYMMDDHHMMSS_nom.sql`.
- **Neuf tests unitaires locaux** sans base ni réseau, exécutés dans ce nouveau contrôle.
- Un **modèle de PR** exige que les agents indiquent modifications, risques, tests réellement faits, preuves, dépendances, et décisions humaines requises.
- `AGENTS.md` ne peut plus confondre l'original AS Grinta, le dépôt commercial, la base commerciale et les workflows actifs.

**Limites :** ce garde-fou n'analyse pas la sécurité intrinsèque d'une nouvelle migration ; pgTAP, l'analyse SQL/RLS et l'approbation restent nécessaires. Une vérification CI verte ne prouve pas la sécurité de l'application ni son fonctionnement avec de vrais clubs.

## Processus minimal pour chaque livraison

1. **Définir** : GitHub Issue/PR, mission M01–M09, résultat vérifiable, risque P0/P1/P2, dépendances éventuelles.
2. **Développer** : branche propre, lot limité, aucune mutation d'environnement réel, migrations nouvelles uniquement.
3. **Tester** : tests unitaires, format, analyse Flutter, build Web si applicable, SQL/RLS/Edge selon périmètre. Une exécution manquante est notée `NON TESTÉ`.
4. **Faire relire** : M03 contrôle les preuves, M04 les changements d'autorisations et de données, M05 les écrans/identité, M07 les données et obligations légales. Un agent ne s'auto-certifie pas.
5. **Demander l'accord** : fusion, migration commerciale, diffusion aux utilisateurs, changement de secret/visibilité, hébergement payant, décision de marque/prix.
6. **Contrôler après livraison** : vérifier version réellement déployée, parcours essentiel, alarmes, régressions et procédures de retour arrière.

## Protection de main — action à confirmer par le propriétaire

Le connecteur GitHub disponible n'autorise pas la modification des règles de protection du dépôt. **Ne pas affirmer que main est protégée.**

Dans GitHub, ouvrir `Application-football-` → `Settings` → `Rules` → `Rulesets` ou `Branches`, puis définir pour `main` :
- fusion uniquement par PR et interdiction des force-push/suppressions ;
- contrôles requis actifs sur toutes les PR, en vérifiant leurs **noms précis dans les runs GitHub** (`Flutter CI / validate`, `Runtime diagnostic / web-runtime`, et après fusion du présent lot, `PR quality guard / migration-history`) ;
- au minimum une revue indépendante **si un deuxième compte de relecteur habilité existe**. Ne pas configurer aveuglément « 1 approbation » sur un dépôt géré par une seule personne, au risque de bloquer toutes les PR ;
- pas de bypass par les automatisations, pas de publication automatique sur la seule base d'une CI verte.

**Attention :** ne pas rendre globalement requis les tests SQL/charge conditionnels à certains chemins : une PR purement documentaire pourrait rester bloquée parce que ces workflows n'ont pas été déclenchés. M03/M04 doivent contrôler ces résultats pour les PR qui changent du SQL.

## Environnement de test isolé — étape suivante

Une base Supabase **locale** est déjà utilisée par les workflows SQL/pgTAP. En revanche, aucun test de parcours de deux clubs A et B sur un environnement distant isolé n'est ici certifié.

Préparer un espace de préproduction séparé (base, stockage, authentification, URL, secrets, utilisateurs **fictifs**) après validation du périmètre, des coûts éventuels et de la configuration de sécurité. Ne jamais recopier les données d'AS Grinta original. Ce chantier nécessite un accord distinct avant tout projet Supabase, ressource payante, donnée distante ou déploiement.

## Critères de refus (« NO GO »)

- Aucune preuve de séparation multiclub A/B sur les parcours pertinents.
- Une CI requise échoue ou manque, ou des tests sont annoncés sans avoir tourné.
- Une nouvelle RPC ou politique donne une portée interclubs, ou la revue sécurité n'a pas eu lieu.
- Une restauration DB **et Storage** n'est pas éprouvée avant l'ouverture réelle.
- Dépôt commercial public avec éventuelles données sensibles historiques non qualifiées.
- Hébergement non autorisé pour un SaaS commercial ; CGV, RGPD, identité et paiement non validés.

**Règle générale :** mieux vaut zéro modification qu'un faux succès automatique.

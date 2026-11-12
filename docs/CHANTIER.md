# Pilotage du chantier — Application football

> Première photographie du chantier : 12 novembre 2026.
> Référence de coordination opérationnelle : [HANDOFF.md](HANDOFF.md).
> Ce fichier est un **tableau d'avancement vérifiable**, pas une preuve que les conversations travaillent en arrière-plan.

## Règles de gouvernance

1. **Ne jamais modifier le dépôt ni les données d'AS Grinta original**, ni ceux de Carte soirée.
2. **Ne jamais modifier la base commerciale Supabase** `jvxkhgdopslctpcjrhzw` sans l'accord explicite de son propriétaire ; aucune création d'utilisateur, écriture ou migration implicite.
3. Les assistants peuvent préparer des branches et PR de documentation ou code commercial, mais **aucune PR n'est fusionnée sans contrôles requis réussis** et revue du propriétaire.
4. Toute nouvelle dépense nécessite une autorisation préalable.
5. **Ne pas confondre :** code présent, tests automatisés, validation en conditions réelles, déploiement effectif.
6. Chaque fil dépose ses travaux dans son périmètre, référence ses PR et signale les risques qui touchent les autres missions.
7. Si un fil n'a pas encore fourni de preuve GitHub ou de résultat vérifiable, son état reste **non confirmé**.

## État des 9 missions

| Fil | Responsable / objectif | État à date | Preuve / prochaine étape |
|---|---|---|---|
| 01 | Audit exhaustif des fonctionnalités | **Travail documenté, non validé** | PR [#25](https://github.com/samihchaa-wq/Application-football-/pull/25) ouverte : audit basé sur lecture du code ; compléter et confirmer les décisions |
| 02 | Adaptation multiclub | **Backlog confié, résultat attendu** | Issue [#38](https://github.com/samihchaa-wq/Application-football-/issues/38) : prioriser le cahier des charges de PR #25, lots isolés avec tests |
| 03 | Tests fonctionnels | **Registre QA rédigé, non validé** | PR [#26](https://github.com/samihchaa-wq/Application-football-/pull/26) ouverte (brouillon) : 34 scénarios, 8 risques ; tests réels à compléter |
| 04 | Sécurité et stabilité | **Audit prioritaire confié, validation non faite** | Issue [#37](https://github.com/samihchaa-wq/Application-football-/issues/37) : exposition des données et séparation entre clubs ; 157 alertes à qualifier |
| 05 | DA et identité | **Audit documentaire en relecture** | PR [#34](https://github.com/samihchaa-wq/Application-football-/pull/34) : identité visuelle existante, ressources à protéger et choix encore ouverts |
| 06 | Business et lancement | **Étude documentaire en relecture** | PR [#35](https://github.com/samihchaa-wq/Application-football-/pull/35) : prix hypothétiques, coûts et restriction d'hébergement à confirmer ; aucun paiement intégré |
| 07 | Juridique | **Audit prioritaire confié, résultat attendu** | Issue [#39](https://github.com/samihchaa-wq/Application-football-/issues/39) : protection du code et des médias, RGPD, clauses et contraintes hébergement |
| 08 | Clubs pilotes | **Plan documentaire en relecture ; aucun pilote exécuté** | PR [#30](https://github.com/samihchaa-wq/Application-football-/pull/30) : parcours du premier match, 18 scénarios, questionnaires, seuils GO/NO-GO ; tests terrain à venir |
| 09 | Exploitation et maintenance | **Diagnostic et correctif proposés, non déployés** | PR [#31](https://github.com/samihchaa-wq/Application-football-/pull/31) et [#32](https://github.com/samihchaa-wq/Application-football-/pull/32) : sonde/backup doivent échouer s'ils sont mal configurés ; restauration non prouvée |

Les statuts indiquent **l'état vérifiable du projet GitHub/Supabase**, pas l'activité des conversations ChatGPT elles-mêmes.

## Points d'attention immédiats (priorité descendante)

1. **Accès et confidentialité** : les dépôts GitHub sont publics ; la documentation signale que l'historique commercial contient d'anciennes données AS Grinta. Vérifier l'exposition avant toute ouverture commerciale. Envisager dépôt privé et remédiation historique, sans divulguer de données.
2. **Sécurité du cloisonnement** : contrôler avec deux clubs fictifs toutes les tables, RPC, Storage, invitations et notifications. Le linter Supabase remonte **157 avertissements** sur l'exécution de fonctions `SECURITY DEFINER` par des utilisateurs authentifiés : il faut analyser les contrôles internes, pas assimiler chaque avertissement à une faille avérée.
3. **Qualité et supervision** : risques QA-01 / QA-02 (issues [#27](https://github.com/samihchaa-wq/Application-football-/issues/27) et [#28](https://github.com/samihchaa-wq/Application-football-/issues/28)) ; correctifs proposés via PR [#33](https://github.com/samihchaa-wq/Application-football-/pull/33) (pgbench) et [#32](https://github.com/samihchaa-wq/Application-football-/pull/32) (watch/backup). **Non fusionnés, CI et tests réels à confirmer**.
4. **PR [#24](https://github.com/samihchaa-wq/Application-football-/pull/24)** ouverte : réactivation GitHub Pages de test. Ne fusionner qu'après vérification des prérequis, de la sécurité, de l'environnement cible et des contrôles CI.
5. **PR [#25](https://github.com/samihchaa-wq/Application-football-/pull/25)** ouverte : audit enrichi et cahier des charges du fil 02 ; **non fusionnable au dernier contrôle GitHub** (mergeable=false), vérifier et résoudre les conflits, notamment autour de HANDOFF, avant revue.
6. **PR [#30](https://github.com/samihchaa-wq/Application-football-/pull/30) et [#31](https://github.com/samihchaa-wq/Application-football-/pull/31)** : documents de pilotes et de maintenance en brouillon, sans tests réels ; plusieurs PR modifient simultanément `docs/HANDOFF.md` : réconcilier leurs mises à jour sans écrasement.
7. **Pré-lancement** : documentation commerciale PR [#35](https://github.com/samihchaa-wq/Application-football-/pull/35) et audit DA PR [#34](https://github.com/samihchaa-wq/Application-football-/pull/34) non validés. L'hébergement GitHub Pages pour SaaS commercial est **à vérifier** sur textes officiels avant fusion PR #24 ; M07 issue #39. Configuration Auth / emails, paiements, textes légaux, support, sauvegardes et restauration restent à valider.

## Ordres du chef de chantier — 12/11/2026

Les consignes opérationnelles sont désormais tracées **dans les issues et dans les commentaires des PR**, pas seulement dans cette conversation :

- **Fil 04 (P0)** : issue [#37](https://github.com/samihchaa-wq/Application-football-/issues/37) ; audit d'exposition et de cloisonnement (aucune écriture autorisée).
- **Fil 07 (P0)** : issue [#39](https://github.com/samihchaa-wq/Application-football-/issues/39) ; risques juridiques dont hébergement commercial et propriété des médias.
- **Fil 02 (P1)** : issue [#38](https://github.com/samihchaa-wq/Application-football-/issues/38) ; lotissement des adaptations à partir de PR #25.
- **Fil 03** : PR #26 → coordonner QA-01 et QA-02, correctifs #33 et #32 ; validation CI nécessaire.
- **Fil 01** : PR #25 → résoudre conflit avant intégration et faire valider les critères par fil 02.
- **Fil 05** : PR #34 → valider identité actuelle / origine des ressources avec fil 07.
- **Fil 06** : PR #35 → vérifier tarifs et faisabilité juridique/technique de l'hébergement avant décision.
- **Fil 08** : PR #30 → pilotes fictifs seulement après validations de sécurité / juridique.
- **Fil 09** : PR #31 et #32 → éviter les faux verts, prouver sauvegarde et restauration avant lancement.
- **Fil 00** : PR #29 (ce tableau) → consolider les informations des 9 missions ; aucune fusion sans CI verte et revue.

**Attention :** la publication de commentaires GitHub ne réveille pas automatiquement les discussions ChatGPT des fils. Ils consulteront ces consignes lorsqu'ils seront relancés. Le suivi programmé du fil 00 contrôle les preuves, pas le travail autonome en arrière-plan.

## Exécution automatisée des missions (mise à jour du 12/11/2026)

**Cinq tâches actives, horaires 24 h/24 et 7 j/7.** Quatre exécutants spécialisés couvrent les neuf missions ; l'agent M00 coordonne. Une exécution n'est pas une session persistante et peut être retardée, échouer ou ne rien produire d'utile ; ne pas compter les déclenchements comme des livrables.

| Agent actif | Missions couvertes | Déclenchement (Europe/Paris) | Périmètre |
|---|---|---|---|
| Exécutant Produit M01-M02 | 01, 02 | Chaque heure à **:05** | Inventaire, revue PR et petites adaptations multiclubs |
| Exécutant QA M03-M09 | 03, 09 | Chaque heure à **:17** | Tests, monitoring, sauvegarde et support |
| Exécutant Sécurité M04-M07 | 04, 07 | Chaque heure à **:29** | RLS, confidentialité, droits, RGPD et juridique |
| Exécutant Marché M05-M06-M08 | 05, 06, 08 | Chaque heure à **:41** | Identité, modèles commerciaux et parcours pilotes |
| Chef M00 — Chantier Application football | 00 | Chaque heure à **:53** | Contrôle, arbitrages, priorisation et distribution via GitHub |

### Rapports au propriétaire

- **Deux synthèses concises par jour**, aux passages vers **10 h 53** et **20 h 53** (heure de Paris), selon la disponibilité du service.
- Contenu : progression **prouvée** (liens vers PR/issues), blocages, étapes suivantes et décisions en attente.
- Pour chaque arbitrage important : **QCM A/B/C** en langage simple, conséquences et choix recommandé ; **aucune décision présumée**. L'absence de réponse vaut absence d'autorisation.
- En dehors des synthèses : pas de rapports horaires répétés ; notifier uniquement une urgence P0 véritablement nouvelle ou un blocage qui nécessite un arbitrage rapide.

### Contrat de travail automatisé

1. À chaque passage, consulter la documentation commune, les issues et PR de sa compétence, sélectionner une **action sûre et utile** sans créer artificiellement du travail.
2. Les livrables sont traçables sur GitHub : avis utile, branche + PR ciblée, tests non perturbateurs ou documentation. Le succès d'un déclenchement ne prouve pas qu'une correction est valide.
3. **Jamais de fusion**, de changement sur `main`, de production, de base commerciale, de dépenses ou de contact avec les clients sans accord explicite ; jamais de modification du dépôt original AS Grinta ni de Carte soirée.
4. Eviter les PR concurrentes sur les mêmes fichiers. `docs/CHANTIER.md` est piloté par M00 ; `docs/HANDOFF.md` exige réconciliation de branches.
5. M00 vérifie le statut GitHub, distribue les priorités via issues/commentaires et demande au propriétaire les décisions sensibles sous forme QCM.
6. Les tâches ChatGPT programmées sont distinctes des neuf conversations et **ne réveillent pas celles-ci**. Des limites d'exécution, de quota ou d'outillage peuvent interrompre le fonctionnement ; confirmer chaque résultat.
7. **Capacité théorique maximale : 120 déclenchements par jour**, pas 120 modifications garanties. Réduire la cadence si les passages se chevauchent ou produisent du bruit plutôt que des résultats.

## Renforcement transversal qualité — 12/11/2026

- **[PR #44 — garde qualité automatisée](https://github.com/samihchaa-wq/Application-football-/pull/44)** (brouillon) : script et CI qui refusent d'éditer/renommer/supprimer d'anciennes migrations, 9 tests unitaires locaux validés ; modèle de PR et consignes `AGENTS.md` propres au commercial. **CI GitHub à vérifier, non fusionné**.
- **[Issue #45 — protection de main](https://github.com/samihchaa-wq/Application-football-/issues/45)** : règles de branche nécessaires ; aucun ruleset visible, lecture de l'ancienne protection non autorisée par l'intégration ; seul le propriétaire peut confirmer et appliquer le réglage GitHub.
- **Revue croisée** : M03 examine tests et CI de #44 ; M04 examine l'étanchéité du périmètre commercial / Supabase et le protocole de migrations ; M09 examine effet sur les workflows ; M00 suit intégration et arbitrage.
- **Environnement isolé** : tests SQL locaux déjà présents, mais validation A/B réelle et restauration distante non prouvées. Tout nouvel environnement payant ou toute donnée à créer nécessitent l'accord du propriétaire.

## Décision B — dépôt public maintenu (12/11/2026)

**Décision explicite du propriétaire :** conserver `samihchaa-wq/Application-football-` en **public** et poursuivre l'audit de confidentialité. Ne pas modifier la visibilité, ne pas rouvrir la même question sans preuve nouvelle significative et ne jamais toucher à AS Grinta original.

- Consigne M04/M07 : continuer l'inventaire non public des données potentiellement personnelles dans le contenu et l'historique Git ; diffuser uniquement des constats anonymisés et des recommandations ciblées dans GitHub. [Issue #37](https://github.com/samihchaa-wq/Application-football-/issues/37#issuecomment-6820783856), [issue #39](https://github.com/samihchaa-wq/Application-football-/issues/39#issuecomment-6820784692).
- Le nettoyage des noms des fichiers actifs proposé par [PR #46](https://github.com/samihchaa-wq/Application-football-/pull/46) n'efface **pas** les anciens commits. Ne pas réécrire l'historique ni les migrations déjà appliquées sans nouvel accord explicite.
- M09/M04 : auditer l'accès aux sauvegardes chiffrées conservées comme artefacts GitHub d'un dépôt public et leur gestion des secrets **avant activation** ; prévoir aussi les objets Storage.
- M02/M03 : corriger les références inutiles aux identités de l'ancien club et tester la régression sans diffuser de données réelles.
- Si un secret ou une exposition de données à risque est démontré, signaler l'incident au propriétaire avec preuves non sensibles et préparer les mesures proportionnées (rotation/réécriture seulement après autorisation).

## Reprise des cinq automatisations — 12/11/2026, 11 h UTC

**Ordre explicite du propriétaire : « Relance tout le monde ».** Les cinq tâches M00, M01-M02, M03-M09, M04-M07 et M05-M06-M08 ont été réactivées (état `is_enabled=true` confirmé). Reprise des passages horaires et des synthèses deux fois par jour ; chaque résultat devra être vérifié, pas seulement le déclenchement.

**Nouveau relais opérationnel :** nom public **Lucarne**, cible de sortie **mai 2027**, foot à 11 exclusivement, conserver l'UX de l'application originale mais sans modifier AS Grinta, badges avec emojis, « Étoile du match », maillots et stade personnalisables par club. Prix et paiement non encore décidés. Dépôt commercial **public** sur décision B, non modifiable sans accord explicite ; tout coût doit être annoncé **avant** engagement.

**État GitHub vérifié** : PR #24 (publication Pages manuelle pour test), #25 (audit), #46 (assainissement), #48 (attente et matchs historiques), #49 (juridique) et #51 (identité Lucarne + stade) **fusionnées** ; #47, #50, #52 **ouvertes** ; #43 empilée sur #40 et sans CI de HEAD lors de la revue précédente. Vérifier les résultats CI sur chaque HEAD avant toute proposition de fusion. La liste plus ancienne dans les sections précédentes représente une photographie historique, non le statut présent.

**Actions prioritaires** : revue des PR #47/#50/#52 et gardes #44, vérification de la séparation A/B avec deux clubs fictifs (seulement dans un environnement et avec une autorisation appropriée), paramètres Auth/e-mails, confidentialités publiques et sauvegardes, conformité commerciale avant mai 2027. GitHub Pages ne doit pas devenir l'hébergement d'un SaaS payant. Ne pas fusionner, déployer, écrire dans Supabase ou engager des coûts sans accord exprès. La base originale et Carte soirée restent intouchables.

## Circuit de transmission entre les fils

- **01 → 02 :** décisions fonctionnelles, paramètres et critères d'acceptation.
- **02 → 03/04 :** PR et scénarios de tests métier/sécurité.
- **03/04 → 02 :** anomalies reproductibles et validations.
- **05 → 02/07 :** spécifications visuelles et vérification des droits.
- **06/07 → 02 :** obligations commerciales, paiement et conformité à implémenter.
- **08 → 02/03/05/09 :** retours des clubs pilotes, priorités et incidents.
- **09 → 00/02/04 :** exploitation, sauvegardes, coûts et risques récurrents.
- **00 (pilotage) :** consolide les informations vérifiées ; arbitre les priorités avec le propriétaire.

Pour chaque livraison : **fil**, **livrable/PR**, **statut**, **preuve**, **tests effectués**, **risque**, **prochaine action**, **décision propriétaire requise**.

## Feux rouges avant les premiers clubs

- Aucun accès croisé entre clubs démontré par les tests.
- Aucune clé secrète exposée ni donnée AS Grinta réutilisée.
- Inscription, création de club, gestion des rôles et flux essentiels validés en conditions réelles.
- Migrations, sauvegardes et possibilité de restauration contrôlées.
- Les conditions juridiques et commerciales nécessaires sont prêtes avant tout client payant.

## Limitations de la supervision

Les fils ChatGPT ne s'exécutent pas automatiquement en parallèle et ne reçoivent pas de consignes directes depuis ce document. Ils doivent chacun consulter ce fichier et publier des résultats traçables sur GitHub. Le fil 00 peut alors les auditer lors de ses contrôles.

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
| 02 | Adaptation multiclub | **Socle existant, validation incomplète** | Migrations multiclub présentes ; réaliser les écarts du fil 01 en PR isolées |
| 03 | Tests fonctionnels | **Registre QA rédigé, non validé** | PR [#26](https://github.com/samihchaa-wq/Application-football-/pull/26) ouverte (brouillon) : 34 scénarios, 8 risques ; tests réels à compléter |
| 04 | Sécurité et stabilité | **Audits prioritaires non terminés** | Vérifier la séparation A/B ; examiner les alertes RLS/RPC et fonctions privilégiées |
| 05 | DA et identité | **Livrable propre au fil non confirmé** | Auditer l'UI ; conserver l'ADN d'AS Grinta ; préparer identité neutre |
| 06 | Business et lancement | **Choix commerciaux ouverts** | Tarif indicatif non validé ; paiement en ligne absent |
| 07 | Juridique | **Validation juridique non confirmée** | Droits des médias, dépôts publics, RGPD, textes et contrats |
| 08 | Clubs pilotes | **Pas de pilote validé** | Préparer deux clubs fictifs et tests d'onboarding après validation sécurité |
| 09 | Exploitation et maintenance | **Socle à éprouver** | Vérifier alertes, backups, restauration et procédures |

Les statuts indiquent **l'état vérifiable du projet GitHub/Supabase**, pas l'activité des conversations ChatGPT elles-mêmes.

## Points d'attention immédiats (priorité descendante)

1. **Accès et confidentialité** : les dépôts GitHub sont publics ; la documentation signale que l'historique commercial contient d'anciennes données AS Grinta. Vérifier l'exposition avant toute ouverture commerciale. Envisager dépôt privé et remédiation historique, sans divulguer de données.
2. **Sécurité du cloisonnement** : contrôler avec deux clubs fictifs toutes les tables, RPC, Storage, invitations et notifications. Le linter Supabase remonte **157 avertissements** sur l'exécution de fonctions `SECURITY DEFINER` par des utilisateurs authentifiés : il faut analyser les contrôles internes, pas assimiler chaque avertissement à une faille avérée.
3. **Qualité et supervision** : PR [#26](https://github.com/samihchaa-wq/Application-football-/pull/26) signale que le script de charge masque les échecs de `pgbench` avec `|| true`, et qu'une sonde réelle n'a pas été exécutée malgré un monitoring vert. Investiguer avant de se fier à ces indicateurs.
4. **PR [#24](https://github.com/samihchaa-wq/Application-football-/pull/24)** ouverte : réactivation GitHub Pages de test. Ne fusionner qu'après vérification des prérequis, de la sécurité, de l'environnement cible et des contrôles CI.
5. **PR [#25](https://github.com/samihchaa-wq/Application-football-/pull/25)** ouverte : compléter le cahier des charges et confirmer la matrice conserver/adapter/paramétrer/supprimer.
6. **Pré-lancement** : configuration Auth / emails, identité commerciale, conditions légales, paiement, support, sauvegardes et restauration doivent être revus avant la vente.

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

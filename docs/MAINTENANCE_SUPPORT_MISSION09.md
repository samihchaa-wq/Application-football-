# Mission 09 — Exploitation, maintenance et support commercial

Date de constat : 12 novembre 2026. Périmètre EXCLUSIF : dépôt samihchaa-wq/Application-football-, base Supabase jvxkhgdopslctpcjrhzw. Aucun audit ni changement effectué sur AS Grinta original. Document de travail, pas une attestation de conformité ni de disponibilité.

## 0. Règles de preuve et de décision

- **Vérifié** = observation directe de l'état distant ou exécution réussie d'une étape identifiable. Un statut GitHub « success » ne prouve pas qu'une étape conditionnelle s'est exécutée.
- **Présent / non testé** = code ou configuration repéré sans essai de bout en bout.
- **Absent / désactivé** = aucun mécanisme actif identifiable ; confirmer après tout changement.
- Aucun nouveau secret, service, achat, migration, écriture SQL, déploiement, fusion ou modification de production sans accord explicite.
- Garder AS Grinta original totalement intact ; ne jamais utiliser son environnement ou ses données pour des tests.
- Les contrôles de sécurité sont arbitrés avec le fil 4 ; les traitements RGPD et documents contractuels avec le fil 7 ; les prix avec le fil 6.

## 1. Inventaire vérifié le 12/11/2026

| Contrôle | Observation | État |
| --- | --- | --- |
| Supabase commercial | Projet ACTIVE_HEALTHY, organisation Pro, PostgreSQL 17.11, région eu-west-3 | État distant vérifié ; disponibilité utilisateur non testée |
| Schéma | 19 migrations enregistrées, dernière 20261112050000_blocage_serveur_mode_live ; 19 fichiers de migration dans GitHub main | Inventaire vérifié ; restauration non testée |
| Données | 0 club et 0 compte Auth au moment de la lecture ; base ~21 Mo | Vérifié à l'instant de la lecture |
| Edge Functions | 8 fonctions déployées (account-email, calendar-feed, claim-account, claim-club, manage-user, register-account, send-prediction-reminders, send-push) | Déploiement vérifié, comportement non validé de bout en bout |
| pg_cron | 12 tâches actives ; 1 402 exécutions « succeeded » sur les deux heures interrogées, aucun échec dans cet échantillon | Exécution observée, résultats métier non testés |
| Vault | 4 entrées comptées sans lire leur valeur | Existence vérifiée ; fonctionnement et complétude à tester |
| Buckets | app-assets public, badge-images public, profile-photos privé | Configuration relevée ; sauvegarde des objets non démontrée |
| CI | Flutter CI, tests Supabase/RLS, contrôle des SHA d'Actions, diagnostic runtime, contrat de publication ; runs récents verts | Exécutions de CI constatées, pas une validation pilote |
| GitHub main | Branche non protégée ; dépôt public | Vérifié ; arbitrage avec fil 4 |
| Site Pages | deploy_pages.yml dans workflows-disabled ; PR #24 en attente de validation | Publication commerciale non démontrée |
| Supervision | production_watch.yml horaire : run 43133882260 « success », mais contrôle SQL « skipped » faute de DB_URL | **Non opérationnelle sur ce run** |
| Backup externe | production_backup.yml hebdomadaire, dump SQL chiffré et artefact à 90 jours si les secrets existent | Aucune archive utilisable/restauration prouvée ; run 43099917381 en échec sur un push ancien, sans job exploitable |
| Backup Supabase | Organisation Pro : documentation Supabase annonce sauvegarde quotidienne et conservation de 7 jours | Droit contractuel attendu, mais **existence et date des snapshots du projet non vérifiées** |
| Restore drill | backup_restore_drill.yml sous workflows-disabled ; procédures historiques documentées | Désactivé / restauration commerciale non testée |
| Dérive migrations et usage | migration_inventory.yml, function_definition_drift.yml et supabase_usage_guard.yml sous workflows-disabled | Inactifs pour ce dépôt |
| Mise à jour automatique | .github/dependabot.yml.disabled ; aucune configuration Dependabot active au chemin standard | Revue manuelle nécessaire |
| Observabilité applicative | docs/observability.md décrit log_client_incident et private.client_incident_log ; zéro incident au moment du constat | Infrastructure documentaire/code présente ; test d'une erreur réelle nécessaire |

Preuves :
- Workflow watch : https://github.com/samihchaa-wq/Application-football-/actions/runs/43133882260
- Workflow setup réussi : https://github.com/samihchaa-wq/Application-football-/actions/runs/43134233822
- Workflow backup en échec ancien : https://github.com/samihchaa-wq/Application-football-/actions/runs/43099917381
- Checklist existante : docs/COMMERCIAL_LAUNCH_CHECKLIST.md
- Documentation de référence Supabase : https://supabase.com/docs/guides/platform/backups

**Attention** : la liste des 8 fonctions et des 19 migrations contredit des passages de docs/HANDOFF.md et de docs/COMMERCIAL_LAUNCH_CHECKLIST.md écrits avant le dernier workflow de mise en route. Les documents anciens ne doivent pas être tenus pour des preuves d'état courant. docs/production-operations.md, docs/observability.md et docs/database-release-process.md contiennent des procédures héritées et/ou des références à des workflows aujourd'hui désactivés.

## 2. Priorités de lancement

### À rendre vérifiable avant un club pilote réel

1. Activer réellement le contrôle de santé ; **faire échouer** le workflow quand une configuration indispensable manque. Vérifier un essai en erreur simulée et la réception effective de l'alerte.
2. Vérifier dans Supabase Dashboard > Database > Backups la date du dernier snapshot, la fréquence, la rétention et les possibilités de restauration. Capturer une preuve non sensible.
3. Compléter le plan de sauvegarde avec les objets Storage des trois buckets ; confirmer chiffrement, accès restreint, rétention et coût réel avant toute activation. Le dump SQL actuel ne sauvegarde que le contenu de la base.
4. Effectuer une restauration sur un environnement **isolé**, sans restaurer dans la base commerciale ; ne créer aucun environnement payant sans autorisation. Tester schéma, comptes de test, fichiers, liens Storage et droits d'accès.
5. Faire le parcours authentification + création d'un club + deux clubs cloisonnés + notifications réelles sur appareils pilotes, avec les fils 3, 4 et 8.
6. Vérifier un contrôle HTTP externe du site déployé, une détection d'erreur Auth et un signal de dégradation Edge ; le moniteur actuel ne contrôle que les échecs cron/push.
7. Vérifier les destinataires des notifications GitHub : « fail » ne garantit pas qu'un e-mail sera lu ou même reçu.
8. Corriger les instructions du dépôt, figer une méthode manuelle de publication, interdire les changements directs sur main avec protection/permissions adaptées (fil 4).

### Avant le premier club payant

- Plan de support public, FAQ minimale et méthode de suivi des tickets.
- Export/suppression de compte et procédure de demande club conformes aux décisions du fil 7.
- Coûts et budget suivis sur le tableau de bord réel ; avertissements d'usage vérifiés.
- Première répétition documentée de retour arrière d'une version web et d'une correction SQL additive sur environnement isolé.
- Convention de version et registre des incidents/changements.

### Peut attendre la croissance

- Centre d'aide élaboré, outils de ticketing payants et centre d'astreinte 24/7.
- Pipelines d'observabilité externes, monitoring avancé et traces distribuées.
- Automatisation complète de la restauration d'un seul club, après définition des responsabilités et vérification de cohérence.
- Plateforme de préproduction permanente payante, uniquement si besoin démontré.

## 3. Maintenance préventive réaliste (une personne)

| Fréquence | Opération | Preuve/trace | Escalade |
| --- | --- | --- | --- |
| Chaque jour ouvré (5–10 min) | Examiner alertes critiques, derniers runs watch/backup, disponibilité du site, erreurs nouvelles | Journal d'exploitation | Créer ticket P0/P1 si panne réelle |
| Chaque semaine (20–30 min) | Examiner échecs cron/push/Auth, usage Supabase, coûts, dernier backup vérifié, tickets en cours, dépendances vulnérables | Registre et captures non sensibles | Fil 4 si sécurité ; fil 6 si coût |
| Chaque mois (45–90 min) | Analyser nouvelles versions Flutter/Supabase, lockfile, dépendances, bugs récurrents, dérives CI, performances et appareils pilotes | PR de maintenance dédiée | Fil 2 développe, fil 3 valide |
| Chaque trimestre | Exercice de restauration isolée (SQL et Storage), incident fictif, accès et secret rotation selon risque, revue de la simplicité et de la dette technique | Compte rendu d'exercice | Aucun restore de production sans autorisation |
| À chaque changement | Vérifier changelog officiel et rupture de compatibilité ; ne pas remplacer un composant sain pour suivre une mode | PR et notes de version | Sécurité et fonctionnel revus |

Pour la dette technique : enregistrer les problèmes, mesurer leur impact, ne refactorer que les composants touchés ou problématiques, conserver les contrats d'API/RLS et les données existantes. Une migration majeure = une seule PR, tests ciblés, pas de refonte simultanée.

## 4. Supervision et seuils proposés (à valider sur des données réelles)

Commencer avec GitHub Actions et l'observabilité intégrée Supabase. Aucun service payant supplémentaire engagé.

| Signal | Seuil initial proposé | Règle |
| --- | --- | --- |
| Site PWA | 2 vérifications HTTP consécutives en erreur, sur une vraie page publiée | Alerte P1 ; l'HTTP 200 seul ne prouve pas le parcours applicatif |
| Vérification automatique | Workflow inexécuté au-delà de deux cadences attendues ou étape critique skipped | Alerte P1 : surveillance aveugle |
| Cron | 1 échec de tâche critique répétée 3 fois, ou tout échec répété d'une tâche quotidienne | À affiner par type de job |
| Push | Plusieurs envois attendus mais aucun départ, ou taux d'échec > 50 % avec au moins 20 tentatives | Ne pas déclencher si aucun événement push attendu |
| Auth/Edge | 5 erreurs 5xx sur 10 minutes ou hausse persistante vs référence | Confirmer avec Logs et test utilisateur |
| Base / stockage | 70 % des limites : revue ; 85 % : action planifiée ; 95 % : P1 | Ne pas estimer les quotas sans Dashboard |
| Facture | 70 % du budget mensuel : revoir ; 90 % : décider ; dépassement prévu : avertir | Les seuils doivent être saisis dans l'outil qui permet réellement des alertes |
| Backups | Dernier backup vérifié plus ancien que la fréquence convenue, ou fichier illisible/absent | P1 ; ne jamais classer une sauvegarde comme réussie sur un run seul |

Test indispensable : provoquer **sans danger pour les clients** une panne de vérification en environnement de test, montrer que le run échoue, que l'alerte arrive au bon destinataire, et enregistrer la date de réussite. Les contrôles qui se terminent en succès après un skip de contrôle essentiel sont interdits pour l'exploitation.

## 5. Sauvegarde, conservation et reprise

Plan cible : snapshots Supabase quotidiens si effectivement disponibles, copie chiffrée indépendante hebdomadaire de la base ET des objets Storage, restauration isolée trimestrielle. Conserver l'historique et les mots de passe de déchiffrement hors du dépôt ; limiter strictement l'accès aux archives.

Le workflow actuel exporte roles.sql, schema.sql et data.sql, les chiffre avec GPG AES-256 et demande PRODUCTION_DB_URL et BACKUP_PASSPHRASE. Il n'exporte ni les objets Storage ni nécessairement tous les paramètres externes (secrets, e-mail, configuration OAuth). Son résultat ne peut pas être qualifié de reprise complète.

Ordre en cas d'incident :
1. Geler déploiements et opérations à risque.
2. Identifier la portée : un utilisateur, un club, tous les clubs, base, objets, Auth ou site.
3. Préserver les journaux et l'état actuel sans divulguer de données.
4. Déterminer un point de récupération validé et la perte possible de données depuis ce point ; prévenir des conséquences.
5. Faire valider par le propriétaire la restauration envisagée ; privilégier l'environnement isolé et l'extraction ciblée si un club est touché.
6. Vérifier intégrité, isolation entre clubs, permissions, fichiers, Auth et parcours vitaux avant la reprise.
7. Documenter le temps d'interruption et la quantité réelle de données restaurées/perdues.

**Objectifs internes proposés, non garantis contractuellement** : viser une perte maximale d'environ 24 h si seuls des snapshots quotidiens validés sont disponibles ; ce chiffre peut être dépassé si la dernière copie est ancienne ou illisible. Ne pas promettre de délai de reprise sans exercice. Une restauration complète du snapshot écrase aussi les données des autres clubs créées depuis cette date ; ne jamais la décider automatiquement.

La documentation officielle Supabase confirme : sauvegardes Pro quotidiennes avec sept jours d'historique ; les objets Storage eux-mêmes ne sont **pas** inclus. Aucune preuve directe de snapshot propre à ce projet n'a été obtenue lors de l'audit.

## 6. Gestion des incidents

Niveaux internes, sans promesse de délai contractuel :
- **P0 — Critique** : fuite de données, cross-club, compromission, perte/corruption active de données ; arrêter la modification et coordonner immédiatement avec le fil 4 et le responsable légal.
- **P1 — Majeur** : connexion ou application indisponible pour plusieurs clubs, notifications critiques en panne, sauvegarde indispensable absente.
- **P2 — Important** : fonctionnalité essentielle défaillante pour un club, contournement temporaire possible, erreur persistante.
- **P3 — Mineur** : gêne visuelle, documentation, amélioration sans blocage.

Ticket : date, source, référence ASG affichée, version, navigateur/appareil, club concerné par un identifiant pseudonymisé, portée, sévérité, étapes de reproduction, éléments observables sans données personnelles, responsable, lien PR/test, décision de communication, résultat et actions préventives.

Cycle : reçu → trié → reproduit / non reproduit → corrigé sur branche → testé → validé → livré avec autorisation → contrôlé → clôturé. P0/P1 : prévenir les clubs concernés au moyen d'une communication factuelle coordonnée selon le fil 7 si les données sont affectées.

## 7. Support client

Démarrage économique : **une adresse d'aide dédiée**, une FAQ web statique courte, et un registre privé GitHub Issues/outil interne sans données personnelles. Ne pas exposer de tickets contenant e-mail, noms, photos ou incidents sur le dépôt GitHub public.

FAQ initiale : installer la PWA ; inscription et invitation ; perte de mot de passe ; administrateur du club ; notifications Android/iPhone et permissions ; disponibilité et pronostics ; exporter ou supprimer son compte ; signaler un bug avec sa référence ASG.

Réception d'un signalement :
1. Vérifier les informations minimales (symptôme, heure, version, appareil, référence d'incident).
2. Vérifier l'état global avant de demander une manipulation locale.
3. Identifier connexion, permission, invite/club, notifications, problème de version PWA ou panne serveur.
4. Ne jamais demander mot de passe, jeton, code de récupération ou capture contenant des données privées.
5. Fournir une solution confirmée ou escalader au ticket technique.
6. Pour export, suppression ou violation : suivre la procédure validée par le fil 7, avec vérification du demandeur et conservation limitée du ticket.

Réponses types courtes :
- Réception : « Votre signalement a été reçu. Indiquez la référence affichée dans l'application et votre appareil, sans transmettre de mot de passe. »
- Incident général : « Nous avons identifié une perturbation touchant [fonction]. Un correctif est en cours de validation. Nous communiquerons après vérification. »
- Résolution : « Le correctif [version] a été publié et vérifié sur [parcours]. Merci de nous signaler si le problème persiste. »

## 8. Livraison et retour arrière

Une PR par changement cohérent. Fil 2 développe ; fil 3 exécute les tests fonctionnels ; fil 4 valide les points sensibles. Pas de fusion sans contrôles verts ni déploiement de production sans autorisation.

Pour chaque release : numéro/version, commit, notes de changement, migrations éventuelles, risques, preuve de tests, plan de vérification après livraison, plan de rollback Web et stratégie SQL réaliste.

Ordre : évaluer → branche → tests ciblés + CI → revue sécurité et compatibilité → approbation → déploiement autorisé → smoke tests PWA/auth/club → examen des logs et cron → journaliser la version.

Web : revenir à un commit/build antérieur si la publication le permet, puis contrôler les caches et service workers PWA. SQL : une migration destructrice n'est pas « annulée » par un rollback du site ; préparer des changements compatibles dans les deux sens (expand / migrate / contract), avec une nouvelle migration corrective plutôt qu'éditer l'historique. Aucune restauration SQL automatique.

## 9. Registre des problèmes et demandes / feuille de route

Un seul registre par objet : ID, type (bug, sécurité, support, coût, UX, fonctionnalité), criticité, clubs affectés, versions, preuve, coût approximatif, effort (S/M/L), risque, responsable (fil), statut, PR, test de résolution.

Ordre de traitement : P0 et sécurité démontrée ; fiabilité des sauvegardes/alertes ; blocages pilotes ; bugs récurrents ; demande validée par plusieurs clubs ; UX ; dette technique mesurée ; idées isolées. Ne pas accumuler des réglages demandés par un seul club si un paramètre existant suffit.

Backlog initial :
- M09-01 P1 — Le watch passe au vert alors que le contrôle SQL est skipped : sécuriser fail-closed, activer accès et tester l'alerte.
- M09-02 P1 — Vérifier snapshots Supabase, copie chiffrée hors fournisseur et restoration réelle.
- M09-03 P1 — Prévoir les objets Storage (trois buckets) dans les backups.
- M09-04 P1 — Ajouter un smoke test HTTP du site lorsque Pages sera déployé.
- M09-05 P2 — Corriger HANDOFF, AGENTS et docs héritées sur les workflows actifs ; supprimer les affirmations obsolètes sans supprimer le code.
- M09-06 P2 — Tester collecteur d'incident, contact support et procédure Auth.
- M09-07 P2 — Réactiver ou remplacer une vérification de versions/migrations en accord avec le fil 4.
- M09-08 P3 — Formaliser Dependabot ou revue mensuelle des dépendances, avec tests complets.
- M09-09 P2 — Suivi des dépenses et dépassements réels, avec fil 6.
- M09-10 P2 — Sécuriser main et revoir visibilité publique, avec fil 4.

## 10. Tableau des coûts techniques

Organisation Supabase vérifiée au niveau Pro, mais montant effectivement facturé, quotas restants, surcoûts et budget non inspectés. Ne pas confondre tarif public et facture réelle.

| Poste | Source de relevé | Seuil d'alerte initial | État |
| --- | --- | --- | --- |
| Supabase plan et compute | Billing et Usage de l'organisation | 70/90 % du budget mensuel décidé par le propriétaire | Plan Pro confirmé ; facture non relevée |
| Database taille/compute | Database / Reports | 70/85/95 % des quotas de l'offre | Taille SQL observée ~21 Mo |
| Storage objets/egress | Storage / Usage | 70/85/95 % des quotas | Trois buckets vus ; octets non relevés |
| Auth / Edge / Realtime | Supabase Usage et Logs | Écart anormal vs semaine précédente et seuil de quota | Seuils non activés |
| GitHub Actions et artefacts | GitHub Billing / Actions | Avertir avant quota payant | Coût réel non relevé |
| Fournisseur e-mail et autres | Portails de facturation | Usage à 70/90 % du forfait | À inventorier avant premier club |

Table de suivi mensuel à conserver : mois ; clubs actifs ; comptes ; taille BDD ; taille Storage ; egress ; invocations Edge ; connexions Realtime ; logs ; minutes GitHub ; facture Supabase ; autres factures ; budget ; anomalie ; décision. Aucune nouvelle option payante ou hausse de plan sans prix communiqué et accord préalable.

## 11. Coordination et preuve de réception

- Fil 2 : toute modification de code/CI et implémentation, sur PR séparée.
- Fil 3 : essais réels, cas limites, régressions et validation de correction.
- Fil 4 : secrets, sauvegardes, protections de branche, sécurité et restauration.
- Fil 6 : budget, marges, choix de prestataires et engagements de support.
- Fil 7 : obligations de notification d'incident, données personnelles, suppression/export.
- Fil 8 : tests pilotes, parcours et FAQ issue des demandes réelles.

Ce document est un **diagnostic initial**, pas une autorisation d'activation. À chaque livraison, mettre à jour les états et les preuves dans docs/HANDOFF.md ou un compte rendu d'exploitation dédié. Ne jamais conclure « opérationnel » sans test daté, résultats et destinataire de l'alerte.

## 12. Transmission formelle au fil 00 (pilotage)

Référence : [PR #29 — docs/CHANTIER.md](https://github.com/samihchaa-wq/Application-football-/pull/29) (document en attente de fusion au moment du constat). Le fil 00 consolide les arbitrages à partir des preuves publiées, pas à partir de conversations supposées synchrones.

| Élément à piloter | Mission | Statut vérifiable | Preuve / responsable |
| --- | --- | --- | --- |
| Diagnostic et neuf procédures M09 | 09 | Documentation proposée, non fusionnée | [PR #31](https://github.com/samihchaa-wq/Application-football-/pull/31) |
| Faux vert des workflows sans secrets | 09 | Correctif et tests de non-régression proposés, non fusionnés | [PR #32](https://github.com/samihchaa-wq/Application-football-/pull/32) ; contrôle réel non exécuté |
| Validation des contrôles CI | 09 / 03 | Attendre résultat du dernier SHA de chaque PR | GitHub Actions (ne pas confondre CI et test en production) |
| Mise en place des secrets nécessaires | Propriétaire / 04 | Bloqué : intervention autorisée requise | `PRODUCTION_DB_URL`, `BACKUP_PASSPHRASE` ; ne jamais divulguer leurs valeurs |
| Sauvegarde des objets Storage et exercice de restauration | 09 / 04 | Non testé, bloquant avant premiers clubs réels | Plan technique, accord du propriétaire si service/ressource supplémentaire |
| Parcours utilisateurs et notifications réelles | 03 / 08 | Non testé sur deux clubs réels fictifs | Attendre validations sécurité/accès et autorisation des écritures |

À signaler systématiquement au chef de projet : nouvelle PR, CI du SHA concerné, défaut réel, incidence sur clubs, coût annoncé avant achat, décision du propriétaire et validation de reprise. Une PR en brouillon ne change pas la production. Le correctif fail-closed prévu dans la PR #32 rend volontairement rouges les jobs planifiés tant que les secrets manquent : **prévoir la configuration autorisée et l'essai contrôlé de l'alerte avant fusion**.

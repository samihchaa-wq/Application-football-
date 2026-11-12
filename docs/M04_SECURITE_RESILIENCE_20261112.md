# MISSION 04 — Rapport initial de sécurité et résilience (lecture seule)

**Date :** 12 novembre 2026  
**Projet :** `samihchaa-wq/Application-football-` / Supabase commercial `jvxkhgdopslctpcjrhzw`  
**Statut :** audit statique et consultation des catalogues de production **effectués** ; corrections et tests d'attaque contrôlés **non effectués** ; **pas de feu vert pour accueillir des clubs réels**.  
**Coordination :** fil 00, [PR #29 — CHANTIER](https://github.com/samihchaa-wq/Application-football-/pull/29) ; transmission fil 02 (correctifs), fil 03 (tests), fil 07 (juridique), fil 09 (exploitation).

> Aucun fichier ni donnée d'AS Grinta original modifié. Aucun SQL d'écriture, migration, création de compte, appel applicatif perturbateur ou déploiement exécuté. Les consultations via Supabase sont des requêtes de catalogue et statistiques en lecture seule. Ce document peut être public : **aucun mot de passe, token de service, clé VAPID, contenu personnel ni procédure d'exploitation d'une faille n'y figure**.

## 1. Décision provisoire

- **Premiers clubs réels : NON (NO-GO)**, jusqu'à clôture des blocages sécurité ci-dessous et validation de deux clubs fictifs isolés. « Base saine » et « tests locaux verts » ne prouvent pas l'absence de fuites.
- **Deux clubs fictifs : autorisation de tests à obtenir** avant de créer des comptes/données dans la base commerciale. Les tests peuvent être préparés sur une base dédiée. Aucun changement de base sans accord.
- **Vulnérabilités critiques démontrées (P0) : aucune pour le moment.** Deux défauts de contrôle métier SQL sont démontrés par lecture du corps des fonctions, mais **aucune exploitation réelle sur comptes A/B n'a été menée**. Ne pas assimiler les avertissements automatiques à 157 failles.

## 2. Protections déjà présentes (preuves consultées)

| Contrôle | Constat en production | Réserve |
|---|---|---|
| Isolation base | Les **59 tables applicatives `public`** et **24 tables `private`** ont RLS activée. Politiques restrictives `club_isolation` sur les tables métier examinées. | Vérifier toutes les opérations avec deux identités réelles. |
| Identité du club | `private.current_club_id()` dérive le club du profil utilisateur en présence d'une identité ; la valeur d'en-tête pour `service_role` est réservée au chemin sans utilisateur. | Vérifier le traitement de tous les appels privilégiés et des utilisateurs suspendus. |
| Privilèges SQL | Le rôle `club_scope` utilisé pour de nombreuses RPC `SECURITY DEFINER` **ne possède pas `BYPASSRLS`**. Les fonctions `public` consultées verrouillent `search_path`. | Une fonction peut rester incorrecte même sans `BYPASSRLS`. |
| Exposition anonyme | Aucun droit `EXECUTE` `anon` sur les RPC applicatives `public`/`private` recensées. | Les Edge Functions publiques sont une surface distincte, volontaire. |
| Vues | Les **10 vues `public`** recensées ont `security_invoker=true` et ne sont pas lisibles par `anon`. | Valider leurs résultats entre clubs. |
| Profils | Les colonnes `email`, `contact_email`, `role`, `username`, `club_id` ne sont pas lisibles directement par le rôle `authenticated` dans `profiles`; lecture partielle des champs publics intentionnels. | Vérifier les RPC qui retournent un profil complet. |
| Fichiers | `profile-photos` est privé (limite 5 Mio) ; `badge-images` et `app-assets` sont publics (5 et 10 Mio). Des politiques Storage vérifient appartenance et/ou rôle. | Les buckets publics ne conviennent pas aux images à confidentialité garantie. |
| Sessions / services | `manage-user` revalide le jeton, contrôle le rôle admin actif et borne le destinataire au `club_id` du demandeur. `send-push` compare un jeton interne avant traitement ; les fonctions retirées `claim-account` et `send-prediction-reminders` retournent 410. | Pas de test live des secrets, de la récupération ni de l'invalidation de session. |
| Protection anti-abus | Les endpoints d'inscription/confirmation utilisent des compteurs de tentatives, des contrôles de taille et des jetons. | Examiner la fiabilité des en-têtes réseau servant à identifier l'origine ; pas de test d'abus réalisé. |
| Supply chain | `pubspec.lock` existe, et plusieurs workflows pinent les actions par SHA. | Analyse de CVE et licences **non exécutée**. |

**Observations catalogues (12/11/2026)** : projet Supabase `ACTIVE_HEALTHY`, PostgreSQL 17, organisation Pro, base ~21 Mo, 6 connexions sur `max_connections=60` au moment de la mesure, tables métier vides. **12 tâches cron actives** ; 1 452 exécutions réussies dans les données présentes pour les dernières 24 heures, aucun échec dans cet échantillon (la base est récente et cet échantillon n'équivaut pas à une journée de charge). Ceci **ne prouve aucune capacité en production avec de vrais clubs**.

## 3. Anomalies et risques classés par priorité

| ID | Priorité | Preuve / constat | Impact probable | Correction / propriétaire | État |
|---|---|---|---|---|---|
| **M04-01** | **P1 élevé** | `public.admin_recent_client_incidents` vérifie l'admin, puis lit le journal global `private.client_incident_log` sans filtre par club ; cette table ne porte pas de `club_id`. Fonction `SECURITY DEFINER` accordée à `authenticated`. | Un admin d'un club pourrait consulter des métadonnées d'incidents d'autres clubs, si des incidents existent. Aucune donnée de ce type actuellement observée. | Fil 02 : filtrer via jointure fiable profil-club ou réserver la consultation globale au seul éditeur ; traiter les incidents sans profil. Fil 03 : accès A/B négatif. | **Défaut de périmètre SQL confirmé**, effet externe à tester. |
| **M04-02** | **P1 élevé** | `private.is_active_profile()` tient compte de `clubs.status='active'`, mais `private.is_admin()` ne vérifie que le rôle et l'état du profil. Des RPC comme `admin_update_club_colors`, `admin_set_club_module` et `admin_regenerate_club_invite_code` se reposent sur `is_admin()`. | Un admin d'un club suspendu pourrait toujours modifier certains paramètres et codes ; l'étendue totale reste à inventorier. | Fil 02 : politique de suspension explicite pour toutes les RPC, privilégier une garde centrale cohérente ; fil 03 : tests avant/après suspension. | **Incohérence confirmée**, surface à compléter. |
| **M04-03** | **P1 avant commercialisation** | Le dépôt Git est **public** ; `docs/HANDOFF.md` et `docs/CHANTIER.md` mentionnent d'anciennes données AS Grinta dans l'historique. | Divulgation possible de données ou d'actifs du club original ; la sensibilité et les éventuelles copies ne sont **pas établies**. | Fil 00/07 : inventaire de l'historique, classification et décision de passer privé, rotation des secrets si découverts ; ne pas publier de secrets dans les rapports. | **Signal documentaire confirmé**, fuite effective non démontrée. |
| **M04-04** | **P1 blocage qualité** | Les tables sont vides ; aucun test distant avec deux clubs A/B distincts n'a été effectué dans ce fil. PR QA [#26](https://github.com/samihchaa-wq/Application-football-/pull/26) relève des défauts de fiabilité de tests de charge et de surveillance. | Les erreurs de filtre entre clubs, invitations, Storage, Realtime et notifications restent possibles malgré des tests locaux. | Fil 03 : matrice A/B par rôle, table, RPC, Storage et Edge ; reproduire seulement sur données fictives et avec accord. | **Non testé en conditions réelles**. |
| **M04-05** | **P1 décision d'hébergement** | `docs/exploitation.md` et PR [#24](https://github.com/samihchaa-wq/Application-football-/pull/24) prévoient GitHub Pages. Les conditions officielles GitHub Pages interdisent l'utilisation comme hébergement gratuit d'un service SaaS commercial : [limites GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits). | Risque contractuel et de disponibilité lors de la commercialisation ; ne préjuge pas d'un usage de démonstration isolé. | Fil 00/02/06/09 : choisir une destination compatible avec le SaaS et adapter URLs, CSP, PWA et pipeline après accord sur le coût. | **Contrainte officielle vérifiée** ; décision ouverte. |
| **M04-06** | **P1 continuité des données** | `.github/workflows/production_backup.yml` exporte `roles.sql`, `schema.sql`, `data.sql` dans une archive chiffrée. Les **fichiers Storage ne sont pas sauvegardés** par ce workflow ni par les sauvegardes DB Supabase ([documentation Supabase](https://supabase.com/docs/guides/platform/backups)). | Impossible de restaurer complètement les photos/écussons/médias en cas de suppression. | Fil 09 : copies indépendantes chiffrées des objets, rétention, vérification, test de restauration DB **et** objets sur environnement séparé. | **Lacune confirmée**, aucune restauration testée. |
| **M04-07** | **P2 surveillance/coûts** | `.github/workflows-disabled/supabase_usage_guard.yml` est désactivé et porte un identifiant de projet historique, pas celui du commercial. `production_watch.yml` et `production_backup.yml` se désactivent si leurs secrets manquent. | Boucle de requêtes non détectée / dépassement de budget, surveillance silencieusement inactive. | Fil 09 : adapter le contrôle au projet commercial avec garde d'identité, vérifier les secrets sans les afficher, alerter en cas de configuration absente, ajouter alertes sur débit, erreurs et usage. | **Workflow désactivé confirmé**, secrets non inspectés. |
| **M04-08** | **P2 confidentialité / puissance** | `send-push` utilise `service_role` avec `x-club-id`, protégé par secret d'appel. | Une erreur dans un appel privilégié peut contourner RLS et viser un autre club ; forte surface si un secret fuite. | Fil 02/03 : contrôler destinations, payloads, isolation lors de tous les types d'envoi, déduplication et quotas. Ne pas désactiver arbitrairement `verify_jwt=false` car le secret serveur est le mécanisme prévu. | **Architecture examinée**, pas de fuite démontrée. |
| **M04-09** | **P2 nettoyage** | Supabase signale `install_tmp.apply` sans `search_path` fixe ; `install_tmp` n'accorde toutefois pas `USAGE` à `anon`/`authenticated`. | Surface technique inutile, non démontrée accessible à l'application. | Fil 02/09 : examiner dépendances puis préparer suppression en migration/maintenance **uniquement après autorisation**. | Avertissement connu, **pas de vulnérabilité démontrée**. |
| **M04-10** | **P2 performance** | Conseiller Supabase : 190 index jamais utilisés et Auth configuré à 10 connexions maximales. La base est neuve et vide. | Les index ne peuvent pas être déclarés inutiles à ce stade ; une limite Auth peut devenir pertinente après montée en charge. | Fil 09 : mesurer sous charge, optimiser seulement sur preuve, tester pics de connexions/inscriptions. | **Information de diagnostic**, pas d'incident. |
| **M04-11** | **P2 limites et dépenses** | Le test de charge décrit dans `docs/exploitation.md` a été exécuté sur machine GitHub plus puissante que l'instance commerciale ; le rapport QA #26 conteste en outre la fiabilité du statut de certains tests. | Chiffres de débit non extrapolables aux premiers clubs sans test réel. | Fil 03/09 : instrumenter p95/p99, erreurs, CPU, mémoire, connexions, Storage et Realtime ; fixer plafonds et alertes de facturation. | **Capacity planning provisoire**. |

### Avertissements SECURITY DEFINER : ne pas traiter mécaniquement

Le conseiller sécurité Supabase renvoie **157 avertissements** `authenticated_security_definer_function_executable` dans `public`, plus **1** `function_search_path_mutable` pour `install_tmp.apply`. Vérification indépendante des privilèges : **157** fonctions privilégiées `public` exécutables par `authenticated`, **48** dans `private`, aucune pour `anon` dans ces deux schémas. La plupart des fonctions `public` concernées appartiennent à `club_scope` (153 sur 157), quatre à `postgres`. Plusieurs contrôles de rôle / club ont été lus et sont justifiés.

Il ne faut **ni retirer globalement EXECUTE, ni convertir toutes ces fonctions en SECURITY INVOKER** : cela pourrait casser l'application sans résoudre les contrôles métiers. Fil 02 : classer chaque RPC en (a) client autorisé et contrôlé, (b) interne à révoquer pour `authenticated`, (c) privilégié à corriger. Fil 03 : vérifier les refus côté SQL avec chaque rôle. Référence : [matrice existante](../supabase/SECURITY_RPC_MATRIX.md), [matrice métier](business-security-matrix.md), [conseiller](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

## 4. Capacité et reprise : ce que les chiffres ne démontrent pas

**Contexte mesuré :** 21 Mo de base, 6 connexions sur 60, douze crons actifs, **pas de clients**. L'organisation Supabase est Pro. Les quotas et surcoûts sont dépendants des offres actuelles : [facturation officielle](https://supabase.com/docs/guides/platform/billing-on-supabase) (notamment 8 Go DB, 100 Go Storage, 250 Go d'egress, 100 000 MAU et 500 connexions Realtime de pointe inclus dans le Pro à la date de consultation ; les dépassements sont payants). Ne pas confondre les 60 connexions Postgres directes avec les connexions Realtime.

**Contrôles à prouver avant lancement :** sauvegarde quotidienne effectivement disponible ; copie chiffrée restaurable hors du projet ; copie des objets Storage ; délai de retour arrière ; migration réversible ou compensatoire ; compatibilité cache/service worker PWA après rollback ; échecs et reprises des tâches cron ; gestion des erreurs réseaux ; budget d'egress, logs et requêtes, et seuils d'alerte. Une restauration qui écrase la base commerciale reste **interdite sans autorisation**.

Le contrat du déploiement de test inclut préflight et CSP ; la PR #24 est en attente. **Aucune mise en ligne n'a été faite par ce fil.**

## 5. Transmission explicite des scénarios et corrections

### Fil 02 — corrections à préparer, sans appliquer à la base
1. **M04-01 :** corriger le périmètre de `admin_recent_client_incidents` ; ne jamais donner à un admin de club une liste globale. Tester le cas `profile_id` absent.
2. **M04-02 :** appliquer une règle cohérente de suspension dans les RPC admin, y compris celles qui s'appuient sur `private.is_admin()`, et documenter les exceptions nécessaires à la réactivation.
3. **M04-08 :** auditer les chemins `service_role` des Edge Functions : appariement des IDs de club, notifications, calendriers et fichiers.
4. **M04-09 :** préparer nettoyage du schéma technique à autoriser ; **aucun DROP maintenant**.
5. **M04-05 :** préparer une configuration de destination d'hébergement interchangeable, sans déploiement ni coût engagé.

### Fil 03 — validations à exécuter après accord de test
- **SEC-A/B-01** : utilisateur actif A, administrateur A, joueur B, administrateur B, ancien membre, en attente, suspendu, JWT expiré ; lecture/écriture directe de chaque table exposée et de chaque RPC paramétrée par un ID de B.
- **SEC-A/B-02** : vérification spécifique de `admin_recent_client_incidents` avec incidents fictifs A/B ; aucun détail B visible depuis A.
- **SEC-SUSP-03** : suspension du club A ; toute opération métier admin, notamment couleurs, modules et invitations, doit refuser. Réactivation contrôlée.
- **SEC-FILES-04** : accès Storage aux photos d'un autre club, bucket privé, URLs signées, chemins et remplacement ; vérifier également la visibilité attendue des buckets publics.
- **SEC-EDGE-05** : inscription, reset, récupération, invitation, lien agenda et révocation ; aucun rattachement à B par modification d'en-tête/paramètre client.
- **SEC-PUSH-06** : cibles A/B, envois concurrents et rejeux, notification de match, service worker PWA ; pas d'envoi à un destinataire d'un autre club.
- **SEC-LOAD-07** : plan de charge contrôlée sur environnement dédié ; concurrence, p95/p99, erreurs, Realtime, 12 crons, quotas et logs ; la validation locale ne remplace pas un test d'infrastructure.
- **SEC-DR-08** : restaurer une copie SQL **et** les fichiers sur environnement distinct ; vérifier comptes, rôles, fichiers et données de deux clubs, puis scénario de retour arrière sans impacter le commercial.
- **SEC-CI-09** : faire échouer volontairement un test `pgbench` dans un environnement isolé et confirmer que le workflow échoue ; vérifier qu'une sonde distante non lancée n'est pas annoncée « verte ».

### Fil 07 / fil 09
- **Fil 07 :** examiner le dépôt public et son historique, droit à l'image / archives, politique de conservation, informations juridiques et contrats, limitation d'usage GitHub Pages.
- **Fil 09 :** sauvegardes DB + médias, restauration, supervision effective, secrets, coûts, facture/quotas, alarmes et documentation de runbooks. Aucun service payant sans accord.

## 6. Décisions réservées au propriétaire / fil 00

1. **Autoriser ou non** les tests avec comptes et deux clubs fictifs, sur une base de test distincte de préférence. Toute création de données dans la base commerciale nécessite accord explicite.
2. **Choisir la confidentialité du dépôt** commercial, après vérification de l'historique ; décider d'un éventuel nettoyage et de la rotation des secrets si des secrets sont prouvés exposés.
3. **Choisir l'hébergement commercial** compatible SaaS et approuver à l'avance tout coût ou nouveau projet.
4. **Approuver les migrations correctives proposées par le fil 02** après revue SQL ; ne pas modifier la base sans accord.
5. **Approuver la stratégie de sauvegarde des médias** et les coûts éventuels ; fixer les objectifs de restauration et le budget maximal.

## 7. État « terminé / testé / bloqué »

**Terminé (lecture seule) :** GitHub `main`, PR #24/#26/#29, `HANDOFF`, `CHANTIER`, matrices sécurité, configuration déploiement, principales Edge Functions et RPC, droits SQL, RLS, vues, Storage, conseillers sécurité/performance, métriques ponctuelles et historique cron.  
**Testé :** requêtes SQL de **lecture seule** des catalogues et statistiques ; aucune attaque ni écriture.  
**Non testé :** RLS fonctionnelle multi-identité A/B, Auth de bout en bout, e-mails, push réel, navigation PWA, restauration et test de charge réel.  
**Bloqué :** corrections et validations sur environnement réel tant que les approbations, secrets, configuration opérationnelle et procédures de test ne sont pas établis.  
**À recontrôler :** `docs/HANDOFF.md` mentionne encore les Edge Functions comme non installées, tandis que l'API Supabase renvoie aujourd'hui **8 fonctions ACTIVE**. Le fil 00 doit actualiser cette information, sans supposer que leurs secrets et leurs flux fonctionnent.

**Prochaine revue de lancement :** lorsque M04-01/M04-02 ont des correctifs testés, que les scénarios A/B et restaurations sont passés, que l'hébergement et la confidentialité sont validés, et que fil 00 a publié sa décision.

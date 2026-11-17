# M09 — Preuve de sauvegarde réelle et porte de restauration isolée

**17 novembre 2026 — issue #91 — Petit Filet commercial seulement.**  
**Verdict : NO-GO. La restauration commerciale complète n'a pas encore été réalisée.**

## Ce qui est réellement vérifié

- [Production backup #44137323933](https://github.com/samihchaa-wq/Application-football-/actions/runs/44137323933) : succès le 17/11/2026 à 17:31 UTC. Journal : **3 exports PostgreSQL** (rôles, structure, données) et **5 objets Storage** contrôlés dans l'archive chiffrée.
- Artefact chiffré **14353470674** : 800 546 octets ; expiration annoncée au 15 février 2027, 17:28 UTC.
- ZIP téléchargé sans déchiffrement : 2 entrées attendues, CRC valide ; SHA-256 ZIP **91a0f7cdbc732466ee927b59fa0dd094472327944a8803901782955f23066596** identique au digest GitHub.
- GPG : 799 805 octets, SHA-256 **5818f1492caa382b71b9f0b62ce4a30a897277f9f4b2f12de188221a4a0d55d7** identique au sidecar. Ce n'est pas une signature d'authenticité indépendante.
- SQL de production **SELECT uniquement**, à l'instant de la vérification (pas les valeurs du dump) : 2 équipes, 43 utilisateurs Auth, 42 profils, 2 saisons, 34 matchs, 602 pronostics, 3 buckets et 5 métadonnées Storage. **Ne pas assimiler ces nombres à ceux d'une restauration.**
- **7 tests unitaires fictifs** du garde de restauration réussis sur l'exécuteur local. Cet exécuteur a correctement **refusé** le prévol réel car une interface réseau non isolée existe.

## Nouveau garde fail-closed

Le fichier **tool/qa/restore_isolation_gate.py** fournit :

1. Un prévol refusant toute URL PostgreSQL/Storage hors des services strictement locaux (127.0.0.1:54322 et 127.0.0.1:54321), une machine non Linux, toute interface autre que loopback et la présence de secrets commerciaux/SMTP/push.
2. Un lecteur de cardinalités dans les blocs COPY du dump SQL, avec présence obligatoire des tables Auth et métier.
3. Un vérificateur **en lecture seule, après import par un opérateur isolé**, comparant les nombres de lignes restaurés aux nombres du dump, liens profils/Auth et absence de crons actifs. Il refuse les écarts et masque les erreurs SQL confidentielles.
4. Un résultat explicite **full_restore_proven = false** : ce garde ne réalise ni l'import, ni la vérification des octets Storage, ni les tests réels JWT/RLS/RPC.

Tests CI sans donnée réelle : **tool/qa/test_restore_isolation_gate.py**.

## Procédure nécessaire pour lever le NO-GO

1. Préparer **un exécuteur privé éphémère** (disque chiffré, accès restreint, aucun routage sortant, PostgreSQL/Supabase Auth/Storage compatible) ; les services doivent être joignables par 127.0.0.1 dans le même espace réseau. Toute restauration commerciale dans un runner à egress libre est interdite.
2. Précharger le ZIP chiffré et vérifier ses empreintes avant toute donnée claire. Injecter la phrase de déchiffrement depuis un coffre privé **sans la copier dans le chat, dans un log GitHub ou sur la ligne de commande**. Retirer toutes les clés commerciales de l'environnement avant les contrôles.
3. Exécuter le prévol. Déchiffrer et vérifier intégralement les trois SQL, inventaires et SHA de tous les objets avec **check_encrypted_backup.py** et **verify_commercial_backup_tar.py**.
4. Sur une pile Supabase locale vierge, compatible avec le schéma géré et sans SMTP/push/webhook/cron actifs, importer réellement **rôles, schéma, données Auth et métier** avec arrêt à la première erreur. Vérifier les extensions, séquences, contraintes, schémas non inclus et fonctions.
5. Restaurer les **octets Storage via le service local**, pas seulement la table de métadonnées ; contrôler chaque taille/SHA, nombre d'objets, bucket privé/public, chemins, propriétés et accès.
6. Créer deux équipes et comptes **strictement fictifs après la comparaison des cardinalités**, tester connexion Auth, accès autorisé A/A et B/B, refus croisés A/B, RPC admin/joueur et Storage privé (vrais JWT locaux). Ne jamais changer les mots de passe de comptes réels.
7. Mesurer RTO de bout en bout, établir le point cohérent DB/Storage pour le RPO, documenter les lacunes Auth/config/Edge Functions/secret Vault, puis **purger toutes les données en clair** et détruire la cible. RPO ≤24h / RTO ≤8h : objectifs non démontrés.

## Blocage actuel

L'environnement disponible ne possède **ni Docker, ni Podman, ni psql, ni Supabase CLI**, ni exécuteur privé attesté. La phrase de déchiffrement de l'archive commerciale n'est pas utilisable depuis cette session sans risque. **Aucune donnée réelle n'a été déchiffrée ou importée, aucune dépense ni instance payante créée.** La mise en place d'une cible privée et la validation juridique/sécurité des opérations réelles restent nécessaires. L'application AS Grinta originale et ses données n'ont jamais été modifiées.

**Ne pas fermer #91 ni déclarer une restauration validée avant la preuve complète DB + Auth + Storage + RLS/RPC + absence d'émission + RPO/RTO.**

## Constat supplémentaire — prévol réel du 17 novembre 2026

- **ZIP commercial téléchargé à nouveau** : 800 546 octets, 2 entrées, CRC ZIP OK, SHA-256 conforme au digest GitHub ; GPG 799 805 octets, SHA-256 conforme au sidecar. Pas de déchiffrement commercial.
- **Essai réel du garde** avec URLs locales de test : `REFUS : Interface réseau non isolée`. La machine possède `lo` et `eth0` ; `unshare -n` renvoie `Operation not permitted`. Aucun Docker/Podman/psql/Supabase CLI disponible. **Aucune restauration tentée sur cet hôte non isolé.**
- **Inventaire de risque, SQL SELECT uniquement sur la production commerciale** : 11 tâches `cron.job` actives ; 2 triggers de notification via réseau (`notify_admin_player_availability_change`, `on_profile_pending_signup`). 2 buckets publics (2 objets) et 1 privé (3 objets). Les sorties réseau/cron doivent être **physiquement interdites avant tout import**, et non seulement vérifiées une fois l'import terminé.
- **Plan de sauvegarde actuel** : hebdomadaire le lundi à 02:23 UTC (`23 2 * * 1`). La fréquence ne démontre pas l'objectif RPO ≤ 24 heures ; aucun engagement commercial de RPO/RTO avant exercice de récupération et ajustement de rétention/fréquence.
- **Cible Supabase disponible** : seule la production commerciale est inscrite sur ce compte ; aucune branche de développement isolée existante. Créer un projet ou une branche distante peut générer des frais et n'établit pas à lui seul l'absence d'e-mails ou push.
- **Attention** : l'audit de SQL/manifestes ne certifie pas les paramètres hébergés hors base (clés de chiffrement racines Vault, configuration Auth, fonctions Edge et réglages Supabase). La procédure de reprise devra documenter la remise en place et tester chacun des composants nécessaires.

## Validation CI de l'isolement de la pile complète (données fictives)

- Échec initial [run 44154120042](https://github.com/samihchaa-wq/Application-football-/actions/runs/44154120042) : Docker isolé ne savait pas déduire l'adresse `host-gateway` à cause de l'absence de pont réseau externe.
- Correctif : définition explicite `--host-gateway-ip=172.19.0.1` **dans le daemon isolé**, sans réintroduire de routage vers Internet.
- [Run 44155012153](https://github.com/samihchaa-wq/Application-football-/actions/runs/44155012153) : **SUCCESS** (job entier). Images Supabase factices préchargées, pile locale PostgreSQL/Auth/Storage démarrée **dans le namespace isolé** et vérification TCP loopback 54321/54322. Vérification des sorties vers 1.1.1.1:443 : refus, preuve de no-egress au niveau des interfaces et du test de connexion.
- **Pas de déchiffrement, pas d'import de la sauvegarde commerciale**. Les données Auth, SQL et fichiers réels ne sont pas encore comparés après restauration. Le succès ne clôt PAS l'issue #91.

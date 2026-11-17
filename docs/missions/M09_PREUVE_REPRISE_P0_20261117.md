# M09 — Preuve partielle de reprise, issue #91

Date : 17 novembre 2026 (Europe/Paris).
Référence main : `4ac75c14d077bc2bf8bc6e3278023d0db8948932`.
Périmètre exclusif Petit Filet ; équipes autonomes. AS Grinta original exclu.
**Verdict : NO-GO pour la preuve de restauration complète.**
Ce verdict ne signifie pas que la sauvegarde est corrompue : l'import et les contrôles après restauration ne sont pas exécutés.

## 1. Résultat réellement obtenu

Une vraie copie chiffrée commerciale a été téléchargée via l'artefact GitHub
14192169057 du run [43792652784](https://github.com/samihchaa-wq/Application-football-/actions/runs/43792652784).
Les octets ont été vérifiés en mémoire ; aucune extraction déchiffrée ou import n'a eu lieu.

- ZIP : **800 817 octets**, SHA-256 égal au digest publié par l'API GitHub.
- Archive ZIP lisible, contrôle CRC réussi ; exactement deux fichiers : archive .gpg et empreinte .gpg.sha256.
- GPG : **800 077 octets**, SHA-256 recalculé égal au fichier d'empreinte interne.
- Empreinte ZIP : `06d7493e844cb7021576cce4e4b9b46b1cba3d468d3312cd3a26bfb880327869`.
- Empreinte .gpg : `0a8f66594107588d9b248bab884fff8b7f32b7ac1c5c62b35a034f96e66b4a2c`.
- Vérification réseau + ZIP + SHA : **0.38 seconde**, mesure locale de cette exécution, **pas un RTO**.
- Artefact non expiré au relevé ; expiration annoncée : 14 février 2027 à 02:31:06 UTC.
- Création de l'artefact : 16 novembre 2026 à 02:32:56 UTC ; ce n'est pas la preuve du point transactionnel exact du dump.
- La présence d'une autre copie plus récente n'a pas été évaluée dans ce contrôle.

Le digest API lie les octets reçus à l'artefact sélectionné. Le sidecar détecte
les écarts de transport du .gpg ; il ne constitue pas une signature indépendante
de l'auteur. L'intégrité interne SQL/fichiers après déchiffrement n'a pas été
revérifiée ici. Aucun nom de personne, adresse, chemin d'objet privé ou secret
n'a été lu dans le contenu clair. Aucun fichier chiffré ou URL signée n'est ajouté au dépôt.

## 2. Classification des preuves

| Contrôle | Résultat | Nature |
| --- | --- | --- |
| ZIP commercial, CRC et hash publié par GitHub | Réussi dans ce lot | Archive réelle, chiffrée |
| Hash .gpg contre sidecar | Réussi dans ce lot | Archive réelle, sans déchiffrement |
| Déchiffrement réel de fixtures et tests négatifs | 5 tests réussis, run 44059219407 déjà audité | Données synthétiques, pas cette archive |
| Déchiffrement de cette archive commerciale | Non exécuté | Bloqué |
| Import PostgreSQL et Auth complets | Non exécuté | Bloqué |
| Comptes fictifs retrouvant leurs données | Non exécuté après import | Bloqué |
| Réimport Storage privé/public, métadonnées et SHA par objet | Non exécuté | Bloqué |
| RLS/RPC A/B après import | Non exécuté | Bloqué |
| Exercice de reprise de bout en bout et RTO | Non exécuté | Non mesuré |

## 3. Blocages précis constatés avant toute donnée claire

1. **Cible d'exécution absente** : ni Docker, ni Podman, ni psql, ni Supabase CLI
   dans l'environnement de ce lot. Un simple ajout de psql ne fournit pas les
   services Auth/Storage nécessaires à l'exercice.
2. **GPG non opérationnel ici** : l'essai local de gpg-agent échoue avec code 2 ;
   la création de socket est interdite (`Operation not permitted`).
   Le succès GPG de GitHub CI ne change pas les capacités de cet environnement.
3. **Moyen de déchiffrement indisponible au processus autorisé** : la phrase est
   conservée dans les secrets de sauvegarde ; les outils disponibles ne permettent
   pas de l'utiliser pour cet exercice isolé. Il ne faut ni la récupérer en clair
   via logs, ni la demander dans le chat.
4. **Aucun exécuteur de restauration complète prêt** n'est présent sur le main
   audité : le script livré contrôle l'archive ; le drill existant ne restaure que
   des fixtures. Les outils GitHub exposent la lecture et la relance de certains
   jobs mais pas le déclenchement d'un nouveau workflow arbitraire.
5. **Isolation et traitement des données réelles non attestés** pour une autre
   machine : disque chiffré, accès restreint, sorties réseau refusées, secrets,
   durée de conservation et purge doivent être établis avant déchiffrement.
   Aucun environnement tiers payant n'a été créé.

Ce sont des blocages techniques et d'accès, pas une demande de renouvellement
de l'autorisation de tester. La consigne de restauration isolée est reçue.
Aucune autorisation de dépense n'est déduite ; si un hébergement payant devient
nécessaire, présenter son fournisseur, son prix et sa durée avant création.

## 4. Exécution à organiser sur une cible privée compatible

- Choisir un exécuteur éphémère privé, PostgreSQL 17 et services Auth/Storage
  compatibles, disque chiffré et accès limité. Utiliser les secrets directement
  dans cet exécuteur, sans publication ni artefact de données claires.
- Avant import, prouver l'absence de sortie réseau vers la production et les
  fournisseurs mail/push ; arrêter les tâches cron et webhooks locaux. Ne pas
  se fier uniquement à l'absence de clés SMTP : les tâches importées peuvent
  contenir des destinations de production.
- Télécharger la copie choisie et répéter les deux SHA ci-dessus ; déchiffrer
  dans un espace privé temporaire et utiliser `verify_commercial_backup_tar.py`
  pour vérifier trois exports et chaque objet contre le manifeste.
- Préparer les schémas gérés, rôles et extensions compatibles ; importer SQL en
  arrêtant à la première erreur, sans accès à la base commerciale. Restaurer les
  personnalisations exclues des exports de structure, notamment les policies Storage.
- Réimporter les octets via Storage et vérifier cardinalité exacte, aucun objet
  supplémentaire/manquant, SHA-256, tailles, métadonnées utiles, liens, public/privé.
- Contrôler PK/FK, séquences, nombres par table, identités Auth et comptes fictifs
  autorisés. Ne pas modifier un mot de passe ou une identité réelle pour tester.
- Tester par de vrais JWT de test : A retrouve A, B retrouve B, A ne lit ni ne
  modifie B (REST/RPC/Storage), joueur refusé sur RPC admin, anon refusé sur privé.
  Une réponse vide seule ne prouve pas les tests positifs ; vérifier ceux-ci aussi.
- Reconstituer la configuration non incluse : Auth/redirects, secrets/Vault,
  fonctions, règles et paramètres externes. Aucun envoi utilisateur.
- Conserver uniquement un rapport agrégé et les hashes ; purger les copies
  déchiffrées et détruire l'exécuteur selon la procédure validée.

Le protocole est préparé ; ces étapes ne sont pas déclarées exécutées.

## 5. RPO/RTO et coûts

**RPO réel : non mesuré.** Le point de copie utilisé est daté, mais le point
cohérent DB/Storage et l'écart au dernier état métier ne sont pas établis.
Une copie antérieure ne prouve pas un RPO de 24 h. Rappel : une copie SQL
quotidienne ne récupère pas seule des photos supprimées.

**RTO réel : non mesuré.** Chronométrer depuis le début de prise en charge de
l'incident/exercice jusqu'à la validation du service : accès aux clés,
provisionnement, import DB, transfert fichiers, contrôles et validation métier.
Distinguer chaque phase et l'absence d'astreinte 24/7. Les 0,38 s ci-dessus
concernent seulement le contrôle chiffré.

Objectifs proposés antérieurement : RPO complet ≤ 24 h, RTO pilote ≤ 8 h ;
aucun engagement démontré par ce lot. La sauvegarde DB/Storage doit être cohérente
et les effacements applicables rejoués après restauration.

**Aucune dépense ni ressource payante créée par ce lot.** Facture et coût
marginal du téléchargement non lus ; ne pas annoncer un coût réel nul certifié.
Budget de la cible privée et temps d'exploitation non chiffrables sans cible.
La copie privée durable indépendante et la politique de rétention restent à valider.

## 6. Conditions GO

GO uniquement après succès documenté de l'import complet, Auth, données métier,
fichiers et métadonnées exacts, droits A/B et RPC, absence d'envois externes,
configuration complète et temps de reprise mesuré. Rapport revu par M03/M04 ;
M07 valide les conditions de traitement des données et de rétention.

État présent : **NO-GO ; #91 reste ouvert**. Aucun déchiffrement commercial,
aucun import de données personnelles, aucune modification de production,
aucune migration ou publication. Le contrôle du conteneur chiffré est la seule
nouvelle preuve réelle de ce lot.

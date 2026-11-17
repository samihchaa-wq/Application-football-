# M09 — Contrôler la copie chiffrée avant restauration

Lot du 17 novembre 2026. Base : main `0e5fa39`. Suite de #156 et #91.
Périmètre : Petit Filet uniquement ; équipes autonomes. Aucun changement de production.

## Livré

`tool/qa/check_encrypted_backup.py` prépare le contrôle hors réseau d'une vraie
copie chiffrée : copie temporaire stable, SHA-256 du fichier .gpg vérifié avant
GPG, phrase transmise par stdin, stderr privé masqué, contrôle existant des
exports SQL et octets Storage, suppression des fichiers temporaires après succès
ou erreur. Il n'extrait aucun SQL vers une base et ne restaure rien.

La valeur attendue est le SHA-256 indépendant du **.gpg**, pas le digest du ZIP
GitHub. Une empreinte obtenue avec le fichier détecte la corruption, mais son
origine doit être authentifiée séparément pour attester sa provenance.

Exécution sur une machine privée jetable autorisée, avec GPG et espace suffisant :

```bash
python3 tool/qa/check_encrypted_backup.py /chemin/prive/archive.tar.gz.gpg --sha256 EMPREINTE_DU_GPG
```

Fournir la phrase sur stdin par un gestionnaire de secrets, sans argument de
commande, trace shell, capture ni saisie dans GitHub/chat. Le dossier temporaire
est privé ; son effacement est une suppression logique, pas un effacement sécurisé
sur disque. Utiliser un disque chiffré et un exécuteur éphémère. Ne pas importer
ces données sur une machine partagée ou publier une archive claire.

## Exécution effectivement obtenue

- Suite QA : **41 tests réussis**, avec **une classe cryptographique ignorée**
  car cet environnement interdit les sockets locales de gpg-agent.
- Cinq nouveaux tests hors réseau vérifient : refus avant déchiffrement si hash
  différent, secret sur stdin uniquement, nettoyage après succès simulé, masquage
  du stderr, refus des liens et phrases multilignes.
- Cinq tests cryptographiques réels sont préparés : bonne phrase, mauvaise phrase,
  altération chiffrée, corruption d'objet déchiffré, nettoyage succès/échec. Ils
  restent non exécutés ici ; la CI devra prouver leur exécution sans skip.
- Aucune archive commerciale téléchargée, aucune phrase réelle lue, aucun compte
  créé, aucun workflow manuel lancé, aucune dépense ni restauration réalisée.

## Prochaine porte de sortie

Exécuter ce contrôle sur la vraie archive dans un exécuteur privé compatible,
puis implémenter/éprouver l'import complet DB/Auth/Storage et les contrôles de
droits. La stack doit être isolée des sorties vers production, SMTP, push et
crons avant tout import. Docker et psql ne sont pas installés dans l'environnement
actuel. Ne pas contourner ces limites en restaurant sur Supabase commercial.

#91 reste ouvert. La preuve de déchiffrement ne suffit pas à la preuve de reprise.
Aucune fusion demandée : main déclenche la chaîne de livraison. Les coûts et la
capacité sont désormais à exprimer en équipes autonomes ; les anciennes hypothèses
à plusieurs équipes par club du premier rapport sont des scénarios historiques.

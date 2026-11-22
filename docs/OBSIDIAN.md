# Lire et écrire les notes du projet avec Obsidian

Le dossier `docs/` est prêt à être ouvert comme coffre Obsidian. Les notes restent de simples fichiers Markdown dans le dépôt : Claude les lit, GitHub les affiche, Obsidian les édite.

## Installation (une seule fois, sur l'ordinateur)

1. Récupérer le dépôt sur l'ordinateur (GitHub Desktop ou `git clone`).
2. Obsidian → « Ouvrir un dossier comme coffre » → choisir le dossier `docs` du dépôt (pas la racine : elle contient tout le code).
3. Réglages → Extensions tierces → activer → Parcourir → installer **Git** (Vinzent / « Obsidian Git ») → Activer.
4. Dans les réglages de l'extension Git :
   - « Auto pull interval » : 10 minutes (récupère les notes écrites par Claude) ;
   - « Auto commit-and-sync interval » : 10 minutes (envoie tes notes) ;
   - « Pull on startup » : activé.

## Règles

- Liens : garder le format Markdown classique `[titre](NOTE.md)` (déjà réglé). Les liens `[[...]]` ne sont pas lus correctement par GitHub.
- Images collées : rangées automatiquement dans un sous-dossier `attachments`.
- Après ajout ou renommage d'une note, le sommaire `INDEX.md` se régénère avec `python3 tool/docs_index.py` (Claude le fait à son passage).
- Modifier les notes ne republie pas l'application : les changements limités à `docs/` sont ignorés par la publication automatique.

## Limites

- Sur iPhone/iPad, l'extension Git est lente et peu fiable sur un gros dépôt. Préférer l'ordinateur pour synchroniser.
- Si Claude et toi modifiez la même note en même temps, Git peut signaler un conflit à résoudre à la main.

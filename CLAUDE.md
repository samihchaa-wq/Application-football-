# Comment me parler

La personne qui pilote ce projet a **les bases en informatique, mais n'est pas
développeuse**. Les réponses doivent être écrites pour elle, pas pour un
ingénieur.

## Règles

- Expliquer d'abord **le problème et ce que ça change pour l'utilisateur**,
  ensuite seulement la solution.
- Éviter le jargon. Quand un mot technique est vraiment nécessaire, le traduire
  en une phrase simple juste après.
- Ne pas remplir les résumés de noms de fonctions, de chemins de fichiers ou de
  codes d'erreur. Les garder pour le code et les commits, ou les donner si on
  les demande.
- Dire clairement **ce qui reste à faire**, et séparer nettement ce que je peux
  faire de ce qui demande une action de sa part.
- Quand plusieurs choix sont possibles, recommander celui qui me paraît le
  meilleur au lieu de dérouler toutes les options.

## Ce que cette règle ne change pas

Simplifier le **langage**, jamais le **fond**.

- Un vrai problème doit être signalé, même s'il est pénible à expliquer.
- Ne jamais annoncer que quelque chose marche sans l'avoir vérifié.
- Dire ce qui n'a pas été testé, et pourquoi.
- Ne pas cacher une limite ou un risque sous prétexte que c'est technique.

## Style concis (caveman) — prioritaire sur la longueur

Toujours appliquer `.claude/skills/caveman/SKILL.md`, en français : réponse
d'abord, phrases courtes, pas de préambule, pas de récapitulatif, pas
d'options déroulées. 3 lignes maximum ; dépasser seulement si la personne le
demande ou pour un risque réel. Les règles « Comment me parler » gardent le
fond (pas de jargon non traduit, dire ce qui n'est pas vérifié, séparer ce
qu'elle doit faire), mais pas la longueur. « stop caveman » le désactive.

## Économie : déléguer le simple à l'éclaireur

Pour une tâche de simple lecture ou recherche (trouver où est quelque chose,
lire un fichier ou des journaux, résumer une sortie de commande), la confier
à l'agent `eclaireur` (`.claude/agents/eclaireur.md`, modèle Haiku, moins
cher). Garder pour soi ce qui demande de réfléchir, décider ou modifier.

## Mémoire : sommaire d'abord, conversations courtes

- Pour une question sur le projet (règles, décisions, historique), lire
  d'abord `docs/INDEX.md`, puis seulement la ou les notes utiles. Après
  ajout ou renommage d'une note : `python3 tool/docs_index.py`.
- Quand une conversation devient longue, ou à la fin d'un travail
  important : écrire l'essentiel (fait, décidé, reste à faire) dans
  `docs/HANDOFF.md`, puis proposer d'ouvrir une nouvelle session, qui
  repartira de cette note au lieu de tout l'historique.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- When graphify-out/graph.json exists, run `graphify query "<question>"` before your first grep, search or source-file read for a codebase question, and put this rule in every subagent prompt that explores code. Read raw files only for lines the graph or an earlier read already located. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. When the answer is under a Markdown heading, `graphify section "<heading>"` prints that section's text, so the .md need not be opened. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.

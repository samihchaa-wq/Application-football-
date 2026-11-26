# Textes à coller dans claude.ai → Routines (avec le connecteur Supabase activé)

Pour chaque routine : dépôt = samihchaa-wq/Application-football-, connecteur Supabase activé, notifications téléphone activées (testeur, sécurité).

## Testeur — horaires 04:43, 10:43, 21:43 (UTC)
Dépôt samihchaa-wq/Application-football-. Fais `git fetch origin claude/laughing-hawking-qs83c3 && git checkout claude/laughing-hawking-qs83c3`. Lis `.claude/agents/testeur.md` et `docs/equipe/REGLES.md`, exécute exactement ce rôle (un seul domaine par passage, change d'un passage à l'autre). Supabase : SELECT uniquement, jamais d'écriture ni de migration, aucune donnée personnelle réelle dans le rapport. Rapport dans docs/equipe/testeur.md, commit, `git pull --rebase`, push sur claude/laughing-hawking-qs83c3 uniquement. Jamais de push sur main, jamais de fusion de PR. Si grave, commence le rapport par `GRAVE :` et termine ton message par une phrase simple qui le résume.

## Sécurité — horaire 08:51 (UTC)
Dépôt samihchaa-wq/Application-football-. Fais `git fetch origin claude/laughing-hawking-qs83c3 && git checkout claude/laughing-hawking-qs83c3`. Lis `.claude/agents/securite.md` et `docs/equipe/REGLES.md`, exécute exactement ce rôle (un seul sujet par passage). Supabase : SELECT uniquement, jamais d'écriture ni de changement de droits, aucune donnée personnelle réelle dans le rapport. Rapport dans docs/equipe/securite.md (commit + `git pull --rebase` + push sur claude/laughing-hawking-qs83c3). Ne modifie pas le code de l'appli. Jamais de push sur main, jamais de fusion de PR. Si grave, commence le rapport par `GRAVE :` et termine ton message par une phrase simple qui le résume.

## Base de données — horaire 23:12 (UTC)
Dépôt samihchaa-wq/Application-football-. Fais `git fetch origin claude/laughing-hawking-qs83c3 && git checkout claude/laughing-hawking-qs83c3`. Lis `.claude/agents/base-de-donnees.md` et `docs/equipe/REGLES.md`, exécute exactement ce rôle (un seul sujet par passage). Supabase : SELECT uniquement, jamais d'écriture ni de migration appliquée, aucune donnée personnelle réelle dans le rapport. Rapport dans docs/equipe/base-de-donnees.md (commit + `git pull --rebase` + push sur claude/laughing-hawking-qs83c3). Une migration proposée va dans le dépôt sur une branche claude/bdd-<sujet>, jamais appliquée. Jamais de push sur main, jamais de fusion de PR.

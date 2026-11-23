# Journal Kyky Écrans

## 23/11/2026 13:20 — passage 1 (aucun code changé)
- Décision propriétaire (23/11/2026) : direction visuelle « Nuit ». Elle remplace l'attente de KYKY_QUESTIONS Q1.
- Bloqué : SDK Flutter absent de l'environnement, téléchargement refusé (storage.googleapis.com bloqué par le proxy). Donc : pas d'analyse, pas de tests, pas de build web, pas de capture Playwright. Écrire du code d'écran sans le vérifier = interdit.
- Bloqué : `.claude/agents/kyky.md` n'existe plus (Kyky supprimé, commit 48377f4). Règles de lot lues dans la consigne seulement.
- Bloqué : Graphify absent (pas de graphify-out/, commande introuvable).
- Branche claude/kyky-ecrans créée depuis main. Le thème Nuit existe déjà sur claude/gallant-babbage-2iz44v (interdit de la refaire). Main a encore Pelouse.
- Reste à faire (moi) : dès qu'un environnement avec Flutter existe, reprendre écran par écran, ordinateur 1440 px d'abord.
- Décisions/actions propriétaire : (1) autoriser storage.googleapis.com et github.com/flutter dans les domaines autorisés, ou brancher l'environnement cloud « Application-football » ; (2) dire comment récupérer Nuit sans refaire gallant-babbage (PR Nuit ? base de ma branche ?).

## 23/11/2026 14:40 — passage 2 (aucun code changé)
- Débloqué : storage.googleapis.com et pub.dev autorisés par la propriétaire. Flutter 3.50.1 (Dart 3.14) cloné dans /tmp/flutter, fonctionne.
- Nuit déjà sur main (PR #223 fusionnée). Ma branche = main + journal.
- Vérifié : analyze 0 erreur, 0 alerte (317 infos « déprécié », dues à Flutter plus récent que celui du projet). Tests : 1501 verts, 1 rouge.
- Hors périmètre : test « lettres accentuées restent autorisées » (test/core/security/password_policy_test.dart) échoue. Logique de mot de passe, voir Fonctions. Gravité : moyenne (cause non cherchée, peut venir de la version Dart).
- Bloqué : docker sans démon, Supabase CLI absente → pas d'appli avec données, donc pas de capture réelle des écrans.
- Reste à faire (moi) : monter les écrans avec de fausses données (build web + Playwright, réseau simulé) pour capturer ordinateur 1440 px. Non vérifiés en Nuit : direct, compositions en édition, légaux, connexion.
